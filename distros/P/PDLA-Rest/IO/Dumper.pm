=head1 NAME

PDLA::IO::Dumper -- data dumping for structs with PDLAs

=head1 DESCRIPTION

This package allows you cleanly to save and restore complex data structures
which include PDLAs, as ASCII strings and/or transportable ASCII files.  It
exports four functions into your namespace: sdump, fdump, frestore, and
deep_copy.

PDLA::IO::Dumper traverses the same types of structure that Data::Dumper
knows about, because it uses a call to Data::Dumper.  Unlike Data::Dumper
it doesn't crash when accessing PDLAs.

The PDLA::IO::Dumper routines have a slightly different syntax than
Data::Dumper does: you may only dump a single scalar perl expression
rather than an arbitrary one.  Of course, the scalar may be a ref to
whatever humongous pile of spaghetti you want, so that's no big loss.

The output string is intended to be about as readable as Dumper's
output is for non-PDLA expressions. To that end, small PDLAs (up to 8
elements) are stored as inline perl expressions, midsized PDLAs (up to
200 elements) are stored as perl expressions above the main data
structure, and large PDLAs are stored as FITS files that are uuencoded
and included in the dump string. (You have to have access to either 
uuencode(1) or the CPAN module Convert::UU for this to work).

No attempt is made to shrink the output string -- for example, inlined
PDLA expressions all include explicit reshape() and typecast commands,
and uuencoding expands stuff by a factor of about 1.5.  So your data
structures will grow when you dump them. 

=head1 Bugs

It's still possible to break this code and cause it to dump core, for
the same reason that Data::Dumper crashes.  In particular, other
external-hook variables aren't recognized (for that a more universal
Dumper would be needed) and will still exercise the Data::Dumper crash.  
This is by choice:  (A) it's difficult to recognize which objects
are actually external, and (B) most everyday objects are quite safe.

Another shortfall of Data::Dumper is that it doesn't recognize tied objects.
This might be a Good Thing or a Bad Thing depending on your point of view, 
but it means that PDLA::IO::Dumper includes a kludge to handle the tied
Astro::FITS::Header objects associated with FITS headers (see the rfits 
documentation in PDLA::IO::Misc for details).

There's currently no reference recursion detection, so a non-treelike
reference topology will cause Dumper to buzz forever.  That will
likely be fixed in a future version.  Meanwhile a warning message finds
likely cases.


=head1 Author, copyright, no warranty

Copyright 2002, Craig DeForest.

This code may be distributed under the same terms as Perl itself
(license available at L<http://ww.perl.org>).  Copying, reverse
engineering, distribution, and modification are explicitly allowed so
long as this notice is preserved intact and modified versions are
clearly marked as such.

This package comes with NO WARRANTY.

=head1 HISTORY

=over 3 

=item * 1.0: initial release

=item * 1.1 (26-Feb-2002): Shorter form for short PDLAs; more readability

=item * 1.2 (28-Feb-2002): Added deep_copy() -- exported convenience function
  for "eval sdump"

=item * 1.3 (15-May-2002): Added checking for tied objects in gethdr()
  [workaround for hole in Data::Dumper]

=item * 1.4 (15-Jan-2003): Added support for Convert::UU as well as
  command-line uu{en|de}code

=back

=head1 FUNCTIONS

=cut

# use PDLA::NiceSlice;

package PDLA::IO::Dumper;
use File::Temp;


BEGIN{
  use Exporter ();

  package PDLA::IO::Dumper;

  $PDLA::IO::Dumper::VERSION = '1.3.2';
  
  @PDLA::IO::Dumper::ISA = ( Exporter ) ;
  @PDLA::IO::Dumper::EXPORT_OK = qw( fdump sdump frestore deep_copy);
  @PDLA::IO::Dumper::EXPORT = @EXPORT_OK;
  %PDLA::IO::Dumper::EXPORT_TAGS = ( Func=>[@EXPORT_OK]);

  eval "use Convert::UU;";
  $PDLA::IO::Dumper::convert_ok = !$@;

  my $checkprog = sub {
      my($prog) = $_[0];
      my $pathsep = $^O =~ /win32/i ? ';' : ':';
      my $exe = $^O =~ /win32/i ? '.exe' : '';
      for(split $pathsep,$ENV{PATH}){return 1 if -x "$_/$prog$exe"}
      return 0;
  };
  # make sure not to use uuencode/uudecode
  # on MSWin32 systems (it doesn't work)
  # Force Convert::UU for BSD systems to see if that fixes uudecode problem
  if (($^O !~ /(MSWin32|bsd)$/) or ($^O eq 'gnukfreebsd')) {
     $PDLA::IO::Dumper::uudecode_ok = &$checkprog('uudecode') and &$checkprog('uuencode') and ($^O !~ /MSWin32/);
  }

  use PDLA;
  use PDLA::Exporter;
  use PDLA::Config;
  use Data::Dumper 2.121;
  use Carp;
  use IO::File;
}

######################################################################

=head2 sdump

=for ref

Dump a data structure to a string.

=for usage

  use PDLA::IO::Dumper;
  $s = sdump(<VAR>);
  ...
  <VAR> = eval $s;

=for description

sdump dumps a single complex data structure into a string.  You restore
the data structure by eval-ing the string.  Since eval is a builtin, no
convenience routine exists to use it.

=cut

sub PDLA::IO::Dumper::sdump {
# Make an initial dump...
  my($s) = Data::Dumper->Dump([@_]);
  my(%pdls);
# Find the bless(...,'PDLA') lines
  while($s =~ s/bless\( do\{\\\(my \$o \= '?(-?\d+)'?\)\}\, \'PDLA\' \)/sprintf('$PDLA_%u',$1)/e) {
    $pdls{$1}++;
  }

## Check for duplicates -- a weak proxy for recursion...
  my($v);
  my($dups);
  foreach $v(keys %pdls) {
    $dups++ if($pdls{$v} >1);
  }
  print STDERR "Warning: duplicated PDLA ref.  If sdump hangs, you have a circular reference.\n"  if($dups);

  # This next is broken into two parts to ensure $s is evaluated *after* the 
  # find_PDLAs call (which modifies $s using the s/// operator).

  my($s2) =  "{my(\$VAR1);\n".&PDLA::IO::Dumper::find_PDLAs(\$s,@_)."\n\n";
  return $s2.$s."\n}";

#
}

######################################################################

=head2 fdump

=for ref

Dump a data structure to a file

=for usage

  use PDLA::IO::Dumper;
  fdump(<VAR>,$filename);
  ...
  <VAR> = frestore($filename);

=for description

fdump dumps a single complex data structure to a file.  You restore the
data structure by eval-ing the perl code put in the file.  A convenience
routine (frestore) exists to do it for you.

I suggest using the extension '.pld' or (for non-broken OS's) '.pdld'
to distinguish Dumper files.  That way they are reminiscent of .pl
files for perl, while still looking a little different so you can pick
them out.  You can certainly feed a dump file straight into perl (for
syntax checking) but it will not do much for you, just build your data
structure and exit.

=cut

sub PDLA::IO::Dumper::fdump { 
  my($struct,$file) = @_;
  my $fh = IO::File->new( ">$file" );
  unless ( defined $fh ) {
      Carp::cluck ("fdump: couldn't open '$file'\n");
      return undef;
  }
  $fh->print( "####################\n## PDLA::IO::Dumper dump file -- eval this in perl/PDLA.\n\n" );
  $fh->print( sdump($struct) );
  $fh->close();
  return $struct;
}

######################################################################

=head2 frestore

=for ref

Restore a dumped file

=for usage

  use PDLA::IO::Dumper;
  fdump(<VAR>,$filename);
  ...
  <VAR> = frestore($filename);

=for description

frestore() is a convenience function that just reads in the named
file and executes it in an eval.  It's paired with fdump().

=cut

sub PDLA::IO::Dumper::frestore {
  local($_);
  my($fname) = shift;

  my $fh = IO::File->new( "<$fname" );
  unless ( defined $fh ) {
    Carp::cluck("frestore:  couldn't open '$file'\n");
    return undef;
  }

  my($file) = join("",<$fh>);
  
  $fh->close;

  return eval $file;
}

######################################################################

=head2 deep_copy

=for ref

Convenience function copies a complete perl data structure by the
brute force method of "eval sdump".

=cut

sub PDLA::IO::Dumper::deep_copy {
  return eval sdump @_;
}

######################################################################

=head2 PDLA::IO::Dumper::big_PDLA

=for ref

Identify whether a PDLA is ``big'' [Internal routine]

Internal routine takes a PDLA and returns a boolean indicating whether
it's small enough for direct insertion into the dump string.  If 0, 
it can be inserted.  Larger numbers yield larger scopes of PDLA.  
1 implies that it should be broken out but can be handled with a couple
of perl commands; 2 implies full uudecode treatment.

PDLAs with Astro::FITS::Header objects as headers are taken to be FITS
files and are always treated as huge, regardless of size.

=cut

$PDLA::IO::Dumper::small_thresh = 8;   # Smaller than this gets inlined
$PDLA::IO::Dumper::med_thresh   = 400; # Smaller than this gets eval'ed
                                      # Any bigger gets uuencoded

sub PDLA::IO::Dumper::big_PDLA {
  my($x) = shift;
  
  return 0 
    if($x->nelem <= $PDLA::IO::Dumper::small_thresh
       && !(keys %{$x->hdr()})
       );
  
  return 1
    if($x->nelem <= $PDLA::IO::Dumper::med_thresh
       && ( !( ( (tied %{$x->hdr()}) || '' ) =~ m/^Astro::FITS::Header\=/)  )
       );

  return 2;
}

######################################################################

=head2 PDLA::IO::Dumper::stringify_PDLA

=for ref

Turn a PDLA into a 1-part perl expr [Internal routine]

Internal routine that takes a PDLA and returns a perl string that evals to the
PDLA.  It should be used with care because it doesn't dump headers and 
it doesn't check number of elements.  The point here is that numbers are
dumped with the correct precision for their storage class.  Things we
don't know about get stringified element-by-element by their builtin class,
which is probably not a bad guess.

=cut

%PDLA::IO::Dumper::stringify_formats = (
   "byte"=>"%d",
   "short"=>"%d",
   "long"=>"%d",
   "float"=>"%.6g",
   "double"=>"%.16g"
  );


sub PDLA::IO::Dumper::stringify_PDLA{
  my($pdl) = shift;
  
  if(!ref $pdl) {
    confess "PDLA::IO::Dumper::stringify -- got a non-pdl value!\n";
    die;
  }

  ## Special case: empty PDLA
  if($pdl->nelem == 0) {
    return "which(pdl(0))";
  }

  ## Normal case:  Figure out how to dump each number and dump them 
  ## in sequence as ASCII strings...

  my($pdlflat) = $pdl->flat;
  my($t) = $pdl->type;

  my($s);
  my(@s);
  my($dmp_elt);

  if(defined $PDLA::IO::Dumper::stringify_formats{$t}) {
    $dmp_elt = eval "sub { sprintf '$PDLA::IO::Dumper::stringify_formats{$t}',shift }";
  } else {
    if(!$PDLA::IO::Dumper::stringify_warned) {
      print STDERR "PDLA::IO::Dumper:  Warning, stringifying a '$t' PDLA using default method\n\t(Will be silent after this)\n";
      $PDLA::IO::Dumper::stringify_warned = 1;
    }
    $dmp_elt = sub { my($x) = shift; "$x"; };
  }
  $i = 0;

  my($i);
  for($i = 0; $i < $pdl->nelem; $i++) {
    push(@s, &{$dmp_elt}( $pdlflat->slice("($i)") )  );
  }

 
  ## Assemble all the strings and bracket with a pdl() call.
  
  $s = ($PDLA::IO::Dumper::stringify_formats{$t}?$t:'pdl').
       "(" . join(   "," , @s  ) .   ")".
       (($_->getndims > 1) && ("->reshape(" . join(",",$pdl->dims) . ")"));

  return $s;
}


######################################################################

=head2 PDLA::IO::Dumper::uudecode_PDLA

=for ref

Recover a PDLA from a uuencoded string [Internal routine]

This routine encapsulates uudecoding of the dumped string for large piddles. 
It's separate to encapsulate the decision about which method of uudecoding
to try (both the built-in Convert::UU and the shell command uudecode(1) 
are supported).

=cut

# should we use OS/library-level routines for creating
# a temporary filename?
#
sub _make_tmpname () {
    # should we use File::Spec routines to create the file name?
    return File::Temp::tmpnam() . ".fits";
}

# For uudecode_PDLA:
#
# uudecode on OS-X needs the -s option otherwise it strips off the
# path of the data file - which messes things up. We could change the
# logic so that we explicitly tell uudecode where to create the output
# file, except that this is also OS-dependent (-o <filename> on OS-X/linux,
# -p on solaris/OS-X to write to stdout, any others?),
# so we go this way for now as it is less-likely to break things
#
my $uudecode_string = "|uudecode";
$uudecode_string .= " -s" if (($^O =~ m/darwin|((free|open)bsd)|dragonfly/) and ($^O ne 'gnukfreebsd'));

sub PDLA::IO::Dumper::uudecode_PDLA {
    my $lines = shift;
    my $out;
    my $fname = _make_tmpname();
    if($PDLA::IO::Dumper::uudecode_ok) {
        local $SIG{PIPE}= sub {}; # Prevent crashing if uudecode exits
	my $fh = IO::File->new( $uudecode_string );
	$lines =~ s/^[^\n]*\n/begin 664 $fname\n/o;
	$fh->print( $lines );
	$fh->close;
    }
    elsif($PDLA::IO::Dumper::convert_ok) {
	my $fh = IO::File->new(">$fname");
	my $fits = Convert::UU::uudecode($lines);
	$fh->print( $fits );
	$fh->close();
    } else {
      barf("Need either uudecode(1) or Convert::UU to decode dumped PDLA.\n");
  }

  $out = rfits($fname);
  unlink($fname);

  $out;
}
 
=head2 PDLA::IO::Dumper::dump_PDLA

=for ref

Generate 1- or 2-part expr for a PDLA [Internal routine]

Internal routine that produces commands defining a PDLA.  You supply
(<PDLA>, <name>) and get back two strings: a prepended command string and an
expr that evaluates to the final PDLA.  PDLA is the PDLA you want to dump.  
<inline> is a flag whether dump_PDLA is being called inline or before
the inline dump string (0 for before; 1 for in).  <name> is the
name of the variable to be assigned (for medium and large PDLAs,
which are defined before the dump string and assigned unique IDs).

=cut

sub PDLA::IO::Dumper::dump_PDLA {
  local($_) = shift;
  my($pdlid) = @_;
  my(@out);

  my($style) = &PDLA::IO::Dumper::big_PDLA($_);

  if($style==0) {
    @out = ("", "( ". &PDLA::IO::Dumper::stringify_PDLA($_). " )");
  }

  else {
    my(@s);

    ## midsized case
    if($style==1){
      @s = ("my(\$$pdlid) = (",
	    &PDLA::IO::Dumper::stringify_PDLA($_),
	    ");\n");
    }

    ## huge case
    else { 
      
      ##
      ## Write FITS file, uuencode it, snarf it up, and clean up the
      ## temporary directory
      ##
      my $fname = _make_tmpname();
      wfits($_,$fname);
      my(@uulines);

      if($PDLA::IO::Dumper::uudecode_ok) {
	  my $fh = IO::File->new( "uuencode $fname $fname |" );
	  @uulines = <$fh>;
	  $fh->close;
    } elsif($PDLA::IO::Dumper::convert_ok) {
	# Convert::UU::uuencode does not accept IO::File handles
        # (at least in version 0.52 of the module)
	#
	open(FITSFILE,"<$fname");
	@uulines = ( Convert::UU::uuencode(*FITSFILE) );
    } else {
	barf("dump_PDLA: Requires either uuencode or Convert:UU");
    }
      unlink $fname;
      
      ## 
      ## Generate commands to uudecode the FITS file and resnarf it
      ##
      @s = ("my(\$$pdlid) = PDLA::IO::Dumper::uudecode_PDLA(<<'DuMPERFILE'\n",
	    @uulines,
	    "\nDuMPERFILE\n);\n",
	    "\$$pdlid->hdrcpy(".$_->hdrcpy().");\n"
	    );

      ##
      ## Unfortunately, FITS format mangles headers (and gives us one
      ## even if we don't want it).  Delete the FITS header if we don't
      ## want one.  
      ##
      if( !scalar(keys %{$_->hdr()}) ) {
	push(@s,"\$$pdlid->sethdr(undef);\n");
      }
    }

    ## 
    ## Generate commands to reconstitute the header
    ## information in the PDLA -- common to midsized and huge case.
    ##
    ## We normally want to reconstitute, because FITS headers mangle
    ## arbitrary hashes and we can reconsitute efficiently with a private 
    ## sdump().  The one known exception to this is when there's a FITS
    ## header object (Astro::FITS::Header) tied to the original 
    ## PDLA's header.  Other types of tied object will get handled just
    ## like normal hashes.
    ##
    ## Ultimately, Data::Dumper will get fixed to handle tied objects, 
    ## and this kludge will go away.
    ## 

    if( scalar(keys %{$_->hdr()}) ) {
      if( ((tied %{$_->hdr()}) || '') =~ m/Astro::FITS::Header\=/) {
	push(@s,"# (Header restored from FITS file)\n");
      } else {
	push(@s,"\$$pdlid->sethdr( eval <<'EndOfHeader_${pdlid}'\n",
	     &PDLA::IO::Dumper::sdump($_->hdr()),
	     "\nEndOfHeader_${pdlid}\n);\n",
	     "\$$pdlid->hdrcpy(".$_->hdrcpy().");\n"
	     );
      }
    }
    
    @out = (join("",@s), undef);
  }

  return @out;
}
  
######################################################################

=head2 PDLA::IO::Dumper::find_PDLAs

=for ref

Walk a data structure and dump PDLAs [Internal routine]

Walks the original data structure and generates appropriate exprs
for each PDLA.  The exprs are inserted into the Data::Dumper output
string.  You shouldn't call this unless you know what you're doing.
(see sdump, above).

=cut

sub PDLA::IO::Dumper::find_PDLAs {
  local($_);
  my($out)="";
  my($sp) = shift;

  findpdl:foreach $_(@_) {
    next findpdl unless ref($_);

    if(UNIVERSAL::isa($_,'ARRAY')) {
      my($x);
      foreach $x(@{$_}) {
	$out .= find_PDLAs($sp,$x);
      }
    } 
    elsif(UNIVERSAL::isa($_,'HASH')) {
      my($x);
      foreach $x(values %{$_}) {
	$out .= find_PDLAs($sp,$x)
	}
    } elsif(UNIVERSAL::isa($_,'PDLA')) {

      # In addition to straight PDLAs, 
      # this gets subclasses of PDLA, but NOT magic-hash subclasses of
      # PDLA (because they'd be gotten by the previous clause).
      # So if you subclass PDLA but your actual data structure is still
      # just a straight PDLA (and not a hash with PDLA field), you end up here.
      #

      my($pdlid) = sprintf('PDLA_%u',$$_);
      my(@strings) = &PDLA::IO::Dumper::dump_PDLA($_,$pdlid);
      
      $out .= $strings[0];
      $$sp =~ s/\$$pdlid/$strings[1]/g if(defined($strings[1]));  
    }
    elsif(UNIVERSAL::isa($_,'SCALAR')) {
      # This gets other kinds of refs -- PDLAs have already been gotten.
      # Naked PDLAs are themselves SCALARs, so the SCALAR case has to come 
      # last to let the PDLA case run.
      $out .= find_PDLAs( $sp, ${$_} );
    }
  
  }
  return $out;
}
      
1;
