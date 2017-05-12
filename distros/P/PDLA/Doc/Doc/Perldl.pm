=head1 NAME

PDLA::Doc::Perldl - commands for accessing PDLA doc database from 'perldl' shell

=head1 DESCRIPTION

This module provides a simple set of functions to
access the PDLA documentation of database, for use
from the I<perldl> or I<pdl2> shells as well as the
I<pdldoc> command-line program.

Autoload files are also matched, via a search of the PDLALIB autoloader
tree.  That behavior can be switched off with the variable 
C<$PERLDL::STRICT_DOCS> (true: don't search autoload tree; false: search
the autoload tree.)

Currently, multiple matches are not handled very well.

=head1 SYNOPSIS

 use PDLA::Doc::Perldl; # Load all documenation functions

=head1 BUGS

The description contains the misleading word "simple". 

=head1 FUNCTIONS

=cut

package PDLA::Doc::Perldl;

use Exporter;
use strict;
use vars qw(@ISA @EXPORT);

@ISA = qw(Exporter);

@EXPORT = qw( apropos aproposover usage help sig badinfo whatis );

use PDLA::Doc;
use Pod::Select;
use IO::File;
use Pod::PlainText;

$PDLA::onlinedoc = undef;
$PDLA::onlinedoc = PDLA::Doc->new(FindStdFile());

use PDLA::Config;
my $bvalflag = $PDLA::Config{WITH_BADVAL} || 0;

# Find std file

sub FindStdFile {
  my ($d,$f);
  for $d (@INC) {
      $f = $d."/PDLA/pdldoc.db";
      if (-f $f) {
         print "Found docs database $f\n" if $PDLA::verbose;
	 print "Type 'help' for online help\n" if $PDLA::verbose;
         return $f;
      }
  }
  warn "Unable to find PDLA/pdldoc.db in ".join(":",@INC)."\n";
}

# used to find out how wide the screen should be
# for printmatch() - really should check for a 
# sensible lower limit (for printmatch >~ 40
# would be my guess)
#
# taken from Pod::Text (v1.0203), then hacked to get it
# to work (at least on my solaris and linux
# machines)
#
sub screen_width() {
    return $ENV{COLUMNS}
       || (($ENV{TERMCAP} =~ /co#(\d+)/) and $1)
       || ($^O ne 'MSWin32' and $^O ne 'dos' and 
	   (`stty -a 2>/dev/null` =~ /columns\s*=?\s*(\d+)/) and $1)
       || 72;
}

sub printmatch {
    my @match = @_;
    if (@match) {
	foreach my $t ( format_ref( @_ ) ) { print $t; }
    } else {
	print "no match\n\n";
    }
} # sub: print_match()

# return a string containing a formated version of the Ref string
# for the given matches
#
sub format_ref {
  my @match = @_;
  my @text = ();

  my $width = screen_width()-17;
  my $parser = new Pod::PlainText( width => $width, indent => 0, sentence => 0 );

  for my $m (@match) { 
    my $ref = $m->[1]{Ref} || 
      ( (defined $m->[1]{CustomFile})
        ? "[No ref avail. for `".$m->[1]{CustomFile}."']"
        : "[No reference available]"
     );

    $ref = $parser->interpolate( $ref );
    $ref = $parser->reformat( $ref );

    # remove last new lines (so substitution doesn't append spaces at end of text)
    $ref =~ s/\n*$//;
    $ref =~ s/\n/\n                /g;

    my $name = $m->[0];
    if ( length($name) > 15 ) { 
      push @text, sprintf "%s ...\n                %s\n", $name, $ref;
    } else {
      push @text, sprintf "%-15s %s\n", $name, $ref;
    }
  }
  return wantarray ? @text : $text[0];

} # sub: format_ref()

=head2 apropos

=for ref

Regex search PDLA documentation database

=for usage

 apropos 'text'

=for example

 pdl> apropos 'pic'
 rpic            Read images in many formats with automatic format detection.
 rpiccan         Test which image formats can be read/written
 wmpeg           Write an image sequence ((x,y,n) piddle) as an MPEG animation.
 wpic            Write images in many formats with automatic format selection.
 wpiccan         Test which image formats can be read/written

To find all the manuals that come with PDLA, try

  apropos 'manual:'

and to get quick info about PDLA modules say

  apropos 'module:'

You get more detailed info about a PDLA function/module/manual
with the C<help> function

=cut

sub aproposover {
    die "Usage: aproposover \$funcname\n" unless $#_>-1;
    die "no online doc database" unless defined $PDLA::onlinedoc;
    my $func = shift;
    $func =~ s:\/:\\\/:g;
    search_docs("m/$func/",['Name','Ref','Module'],1);
    
}

sub apropos  {
    die "Usage: apropos \$funcname\n" unless $#_>-1;
    die "no online doc database" unless defined $PDLA::onlinedoc;
    my $func = shift;
    printmatch aproposover $func;
}

=head2 PDLA::Doc::Perldl::search_docs

=for ref

Internal routine to search docs database and autoload files

=cut

sub search_docs {
    my ($func,$types,$sortflag,$exact) = @_;
    my @match;

    @match = $PDLA::onlinedoc->search($func,$types,$sortflag);
    push(@match,find_autodoc( $func, $exact ) );
    
    @match;
}



=head2 PDLA::Doc::Perldl::finddoc

=for ref 

Internal interface to the PDLA documentation searcher

=cut

sub finddoc  {
    local $SIG{PIPE}= sub {}; # Prevent crashing if user exits the pager

    die 'Usage: doc $topic' unless $#_>-1;
    die "no online doc database" unless defined $PDLA::onlinedoc;
    my $topic = shift;

    # See if it matches a PDLA function name

    my $subfield = $1
      if( $topic =~ s/\[(\d*)\]$// );

    (my $t2 = $topic) =~ s/([^a-zA-Z0-9_])/\\$1/g;  

    my @match = search_docs("m/^(PDLA::)?".$t2."\$/",['Name'],0);

    unless(@match) {
      
      print "No PDLA docs for '$topic'. Using 'whatis'. (Try 'apropos $topic'?)\n\n";
      whatis($topic);
      return;

    }

    # print out the matches

    my $out = IO::File->new( "| pod2text | $PDLA::Doc::pager" );
    
    if($subfield) {
      if($subfield <= @match) {
	@match = ($match[$subfield-1]);
	$subfield = 0;
      } else {
	print $out "\n\n=head1 PDLA HELP: Ignoring out-of-range selector $subfield\n\n=head1\n\n=head1 --------------------------------\n\n";
	$subfield = undef;
      }
    }
    
    my $num_pdl_pod_matches = scalar @match;
    my $pdl_pod_matchnum = 0;

    while (@match) {
       $pdl_pod_matchnum++;

       if (  @match > 1   and   !$subfield  ) {
          print $out "\n\n=head1 MULTIPLE MATCHES FOR HELP TOPIC '$topic':\n\n=head1\n\n=over 3\n\n";
          my $i=0;
          for my $m ( @match ) {
             printf $out "\n=item [%d]\t%-30s %s%s\n\n", ++$i, $m->[0], $m->[1]{Module} && "in ", $m->[1]{CustomFile} || $m->[1]{Module};
          }
          print $out "\n=back\n\n=head1\n\n To see item number \$n, use 'help ${topic}\[\$n\]'. \n\n=cut\n\n";
       }

       if (@match > 0 and $num_pdl_pod_matches > 1) {
          print $out "\n=head1 Displaying item $pdl_pod_matchnum:\n\n=head1 --------------------------------------\n\n=cut\n\n";
       }

       my $m = shift @match;

       my $Ref = $m->[1]{Ref};
       if ( $Ref =~ /^(Module|Manual|Script): / ) {
	   # We've got a file name and we have to open it.  With the relocatable db, we have to reconstitute the absolute pathname.
	   my $relfile = $m->[1]{File};
	   my $absfile = undef;
	   for my $dbf(@{$PDLA::onlinedoc->{Scanned}}) {
	       $dbf =~ s:\/[^\/]*$::; # Trim file name off the end of the database file to get just the directory
	       $dbf .= "/$relfile";
	       $absfile = $dbf if( -e $dbf );
	   }
	   unless ($absfile) {
	       die "Documentation error: couldn't find absolute path to $relfile\n";
	   }
	   my $in = IO::File->new("<$absfile");
	   print $out join("",<$in>);
       } else {
          if(defined $m->[1]{CustomFile}) {

             my $parser= Pod::Select->new;
             print $out "=head1 Autoload file \"".$m->[1]{CustomFile}."\"\n\n";
             $parser->parse_from_file($m->[1]{CustomFile},$out);
             print $out "\n\n=head2 Docs from\n\n".$m->[1]{CustomFile}."\n\n";

          } else {

             print $out "=head1 Module ",$m->[1]{Module}, "\n\n";
             $PDLA::onlinedoc->funcdocs($m->[0],$out);

          }

       }
    }
  }


=head2 find_autodoc

=for ref

Internal helper routine that finds and returns documentation in the autoloader
path, if it exists.  You feed in a topic and it searches for the file
"${topic}.pdl".  If that exists, then the filename gets returned in a 
match structure appropriate for the rest of finddoc.

=cut

# Yuck.  Sorry.  At least it works.  -CED

sub find_autodoc {
    my $topic = shift;
    my $exact = shift;
    my $matcher;
    # Fix up regexps and exact matches for the special case of 
    # searching the autoload dirs...
    if($exact) {
	$topic =~ s/\(\)$//;  # "func()" -> "func"
	$topic .= ".pdl" unless $topic =~ m/\.pdl$/;
    } else {

	$topic =~ s:([^\$])(.)$:$1\.\*\$$2:; # Include explicit ".*$" at end of
	                                   # vague matches -- so that we can
	                                   # make it a ".*\.pdl$" below.

	$topic =~ s:\$(.)$:\.pdl\$$1:; # Force ".pdl" at end of file match

	$matcher = eval "sub { ${topic}i && \$\_ };";  # Avoid multiple compiles
    }

    my @out;

    return unless(@main::PDLALIB);
    @main::PDLALIB_EXPANDED = PDLA::AutoLoader::expand_path(@main::PDLALIB)
	unless(@main::PDLALIB_EXPANDED);
    
    for my $dir(@main::PDLALIB_EXPANDED) {
	if($exact) {
	    my $file = $dir . "/" . "$topic";
	    push(@out,
	          [$file, {CustomFile => "$file", Module => "file '$file'"}]
		 )
		if(-e $file);
	} else {
	    opendir(FOO,$dir) || next;
	    my @dir = readdir(FOO);
	    closedir(FOO);
	    for my $file( grep( &$matcher, @dir ) ) {
		push(@out,
		     [$file, {CustomFile => "$dir/$file", Module => "file '$dir/$file'"}]
		     );
	    }

	}
    }
    @out;
}


=head2 usage

=for ref

Prints usage information for a PDLA function

=for usage

 Usage: usage 'func'

=for example

   pdl> usage 'inner'

   inner           inner prodcuct over one dimension
                   (Module PDLA::Primitive)

   Signature: inner(a(n); b(n); [o]c(); )


=cut

sub usage {
    die 'Usage: usage $funcname' unless $#_>-1;
    die "no online doc database" unless defined $PDLA::onlinedoc;
    print usage_string(@_);
}
sub usage_string{
    my $func = shift;
    my $str = "";
    my @match = search_docs("m/^(PDLA::)?$func\$/",['Name']);

    unless (@match) { $str = "\n  no match\n" } 
    else {
	$str .= "\n" . format_ref( $match[0] );
	my ($name,$hash) = @{$match[0]};
	$str .= sprintf ( (' 'x16)."(Module %s)\n\n", $hash->{Module} );
	die "No usage info found for $func\n"
	    if !defined $hash->{Example} && !defined $hash->{Sig} &&
		!defined $hash->{Usage};
	$str .= "  Signature: $name($hash->{Sig})\n\n" if defined $hash->{Sig};
	for (['Usage','Usage'],['Opt','Options'],['Example','Example']) {
	    $str .= "  $_->[1]:\n\n".&allindent($hash->{$_->[0]},10)."\n\n"
		if defined $hash->{$_->[0]};
	}
    }
    return $str;
}

=head2 sig

=for ref

prints signature of PDLA function

=for usage

 sig 'func'

The signature is the normal dimensionality of the
function's arguments.  Calling with different dimensions
doesn't break -- it causes threading.  See L<PDLA::PP|PDLA::PP> for details.

=for example

  pdl> sig 'outer'
    Signature: outer(a(n); b(m); [o]c(n,m); )


=cut

sub sig {
	die "Usage: sig \$funcname\n" unless $#_>-1;
	die "no online doc database" unless defined $PDLA::onlinedoc;
	my $func = shift;
	my @match = search_docs("m/^(PDLA::)?$func\$/",['Name']);
	unless (@match) { print "\n  no match\n" } else {
         my ($name,$hash) = @{$match[0]};
	 die "No signature info found for $func\n"
            if !defined $hash->{Sig};
         print "  Signature: $name($hash->{Sig})\n" if defined $hash->{Sig};
        }
}

sub allindent {
	my ($txt,$n) = @_;
	my ($ntxt,$tspc) = ($txt,' 'x8);
	$ntxt =~ s/^\s*$//mg;
	$ntxt =~ s/\t/$tspc/g;
	my $minspc = length $txt;
	for (split '\n', $txt) { if (/^(\s*)/)
          { $minspc = length $1 if length $1 < $minspc } }
	$n -= $minspc;
	$tspc = ' 'x abs($n);
	$ntxt =~ s/^/$tspc/mg if $n > 0;
	return $ntxt;
}


=head2 whatis

=for ref

Describe a perl and/or PDLA variable or expression.  Useful for
determining the type of an expression, identifying the keys in a hash
or a data structure, or examining WTF an unknown object is.

=for usage

 Usage: whatis $var
        whatis <expression>

=cut

sub whatis {
  my $topic;

  if(@_ > 1) {
    whatis_r('',0,[@_]);
  } else {
    whatis_r('',0,shift);
  }
}

$PDLA::Doc::Perldl::max_strlen = 55;
$PDLA::Doc::Perldl::max_arraylen = 1;
$PDLA::Doc::Perldl::max_keylen = 8;
$PDLA::Doc::Perldl::array_indent=5;
$PDLA::Doc::Perldl::hash_indent=3;

sub whatis_r {
  my $prefix = shift;
  my $indent = shift;
  my $a = shift;
  
  unless(defined $a) {
    print $prefix,"<undef>\n";
    return;
  }

  unless(ref $a) {
    print "${prefix}'".
      substr($a,0,$PDLA::Doc::Perldl::max_strlen).
      "'".((length $a > $PDLA::Doc::Perldl::max_strlen) && '...').
      "\n";
    return;
  }

  if(ref $a eq 'ARRAY') {
    print "${prefix}Array (".scalar(@$a)." elements):\n";

    my($el);
    for $el(0..$#$a) {
      my $pre = sprintf("%s  %2d: "," "x$indent,$el);
      whatis_r($pre,$indent + $PDLA::Doc::Perldl::array_indent, $a->[$el]);
      last if($el == $PDLA::Doc::Perldl::max_arraylen);
    } 
    printf "%s   ... \n"," " x $indent
      if($#$a > $PDLA::Doc::Perldl::max_arraylen);

    return;
  }
      
  if(ref $a eq 'HASH') {
    print "${prefix}Hash (".scalar(keys %$a)." elements)\n";
    my $key;
    for $key(sort keys %$a) {
      my $pre = " " x $indent .
	        " $key: " . 
		(" "x($PDLA::Doc::Perldl::max_keylen - length($key))) ;

      whatis_r($pre,$indent + $PDLA::Doc::Perldl::hash_indent, $a->{$key});
    }
    return;
  }

  if(ref $a eq 'CODE') {
    print "${prefix}Perl CODE ref\n";
    return;
  }

  if(ref $a eq 'SCALAR' | ref $a eq 'REF') {
    whatis_r($prefix." Ref -> ",$indent+8,$$a);
    return;
  }

  if(UNIVERSAL::can($a,'px')) {
    my $b;
    local $PDLA::debug = 1;

    $b = ( (UNIVERSAL::isa($a,'PDLA') && $a->nelem < 5 && $a->ndims < 2)
	   ? 
	   ": $a" :
	   ": *****"
	   );

    $a->px($prefix.(ref $a)." %7T (%D) ".$b);

  } else {

    print "${prefix}Object: ".ref($a)."\n";

  }
}

=head2 help

=for ref

print documentation about a PDLA function or module or show a PDLA manual

In the case of multiple matches, the first command found is printed out,
and the remaining commands listed, along with the names of their modules.


=for usage

 Usage: help 'func'

=for example

 pdl> help 'PDLA::Tutorials' # show the guide to PDLA tutorials
 pdl> help 'PDLA::Slices'    # show the docs in the PDLA::Slices module
 pdl> help 'slice'          # show docs on the 'slice' function

=cut

sub help_url {
    local $_;
    foreach(@INC) {
	my $a = "$_/PDLA/HtmlDocs/PDLA/Index.html";
	if(-e $a) {
	    return "file://$a";
	}
    }
}

sub help {
  if ($#_>-1) {
      require PDLA::Dbg;
      my $topic = shift;
      if (PDLA::Core::blessed($topic) && $topic->can('px')) {
	  local $PDLA::debug = 1;
	  $topic->px('This variable is');
      } else {
	  $topic = 'PDLA::Doc::Perldl' if $topic =~ /^\s*help\s*$/i;
	  if ($topic =~ /^\s*vars\s*$/i) {
	      PDLA->px((caller)[0]);
	  } elsif($topic =~ /^\s*url\s*/i) {
	      my $a = help_url();
	      if($a) {
		  print $a;
	      } else {
		  print "Hmmm. Curious: I couldn't find the HTML docs anywhere in \@INC...\n";
	      }
	  } elsif($topic =~ /^\s*www(:([^\s]+))?\s*/i) {
	      my $browser;
	      my $url = help_url();
	      if($2) {
		  $browser = $2;
	      } elsif($ENV{PERLDL_WWW}) {
		  $browser = $ENV{PERLDL_WWW};
	      } else {
		  $browser = 'mozilla';
	      }
	      chomp($browser = `which $browser`);
	      if(-e $browser && -x $browser) {
		  print "Spawning \"$browser $url\"...\n";
		  `$browser $url`;
	      }
	  } else {
	      finddoc($topic);
	  }
      }
  } else {
	print <<'EOH';

The following commands support online help in the perldl shell:

 help 'thing'   -- print docs on 'thing' (func, module, manual, autoload-file)
 help vars      -- print information about all current piddles
 help url       -- locate the HTML version of the documentation
 help www       -- View docs with default web browser (set by env: PERLDL_WWW)

 whatis <expr>  -- Describe the type and structure of an expression or piddle.
 apropos 'word' -- search for keywords/function names 
 usage          -- print usage information for a given PDLA function
 sig            -- print signature of PDLA function

 ('?' is an alias for 'help';  '??' is an alias for 'apropos'.)
EOH

print "  badinfo         -- information on the support for bad values\n"
   if $bvalflag;

print <<'EOH';

Quick start:
  apropos 'manual:' -- Find all the manual documents
  apropos 'module:' -- Quick summary of all PDLA modules
  help 'help'       -- details about PDLA help system
  help 'perldl'     -- help about this shell

EOH
  }
}

=head2 badinfo

=for ref

provides information on the bad-value support of a function

And has a horrible name.

=for usage

 badinfo 'func'

=cut

# need to get this to format the output - want a format_bad()
# subroutine that's like - but much simpler - than format_ref()
#
sub badinfo {
    my $func = shift;
    die "Usage: badinfo \$funcname\n" unless defined $func;

    die "PDLA has not been compiled with support for bad values.\n" .
	"Recompile with WITH_BADVAL set to 1 in config file!.\n"
	    unless $bvalflag;

    die "no online doc database" unless defined $PDLA::onlinedoc;

    local $SIG{PIPE}= sub {}; # Prevent crashing if user exits the pager

    my @match = search_docs("m/^(PDLA::)?$func\$/",['Name']);
    if ( @match ) {
	my ($name,$hash) = @{$match[0]};
	my $info = $hash->{Bad};

	if ( defined $info ) {
	    my $out = new IO::File "| pod2text | $PDLA::Doc::pager";
	    print $out "=head1 Bad value support for $name\n\n$info\n";
	} else {
	    print "\n  No information on bad-value support found for $func\n";
	}
    } else {
	print "\n  no match\n";
    }
} # sub: badinfo()

1; # OK
