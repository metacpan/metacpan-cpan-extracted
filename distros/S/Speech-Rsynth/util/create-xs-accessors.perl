#!/usr/local/bin/perl -w

use Getopt::Long;
use Pod::Usage;

$VERSION = 0.01;

use vars qw($mname $fname $otype $oname $rtype $rname $atype $aname $mget $mset);

# data structure: @xspec
#  + array of hash-refs, each of the form:
#    {
#     otype => $xs_obj_type,
#     oname => $xs_obj_name,
#     fname => $xs_fcn_suffix,
#     rtype => $xs_return_type,
#     rname => $xs_retval_name,
#     aname => $xs_set_arg_name,
#     atype => $xs_set_arg_type,
#     mname => $c_member_name,
#     mname => $c_member_type,
#    }
#  + defaults are drawn from @XSPEC_DEFAULTS
@XSPEC_DEFAULTS = (
		   mname => 'UNKNOWN_FIELD',
		   mtype => 'int',
		   fname => '$mname',
		   otype => "UNKNOWN_STRUCT",
		   oname => "obj",
		   rtype => '$mtype',
		   rname => "RETVAL",
		   atype => '$mtype',
		   aname => 'val',
		  );

@xspex = qw();

######################################################################
# Cmdline processing
######################################################################
GetOptions("help"=>\$help,
	   "man"=>\$man,
	   "version"=>\$version,
	   ## -- globals
	   "prefix:s"=>\$XSPREFIX,
	   "spex|specfile:s"=>\$SPECFILE,
	   ## -- files
	   "xsin:s"=>\$XSIN,
	   "xsout:s"=>\$XSOUT,
	   "pmin:s"=>\$PMIN,
	   "pmout:s"=>\$PMOUT,
	   ## -- replace-strings
	   "xs_macro:s"=>\$XS_ACCESSOR_SYMBOL,
	   "pm_macro_list:s"=>\$PM_ACCESSOR_LIST_SYMBOL,
	   "pm_macro_code:s"=>\$PM_ACCESSOR_CODE_SYMBOL,
	  );

#--------------------------------------------------------------
# Process Options: help
#--------------------------------------------------------------
if ($version) {
  print STDERR "C-struct accessor generator `$0' version $VERSION by Bryan Jurish\n";
  exit 0;
}

pod2usage({
	   -exitval => 1,
	   -verbose => 2,
	  }) if ($man);
pod2usage({
	   -exitval => 1,
	   verbose => 0,
	  }) if ($help);

#--------------------------------------------------------------
# Process Options: Specs
#--------------------------------------------------------------
if (defined($SPECFILE)) {
  do("$SPECFILE") or
    die("$0: couldn't source spec-file '$SPECFILE': $!");
}

#--------------------------------------------------------------
# Process Options: Files
#--------------------------------------------------------------
if (defined($XSIN)) {
  open(XSIN,"<$XSIN") or
    die("$0: open failed for XS input file '$XSIN': $!");
}
if (defined($XSOUT)) {
  open(XSOUT,">$XSOUT") or
    die("$0: open failed for XS output file '$XSOUT': $!");
}
if (defined($PMIN)) {
  open(PMIN,"<$PMIN") or
    die("$0: open failed for PM input file '$PMIN': $!");
}
if (defined($PMOUT)) {
  open(PMOUT,">$PMOUT") or
    die("$0: open failed for PM output file '$PMOUT': $!");
}

#--------------------------------------------------------------
# Process Options: Macro Symbols
#--------------------------------------------------------------
$XS_ACCESSOR_SYMBOL = '#XS_ACCESSOR_CODE#' unless (defined($XS_ACCESSOR_SYMBOL));
$PM_ACCESSOR_LIST_SYMBOL = '#PM_ACCESSOR_LIST#' unless (defined($PM_ACCESSOR_LIST_SYMBOL));
$PM_ACCESSOR_CODE_SYMBOL = '#PM_ACCESSOR_CODE#' unless (defined($PM_ACCESSOR_CODE_SYMBOL));


######################################################################
# Subs
######################################################################

# @clines = c2perl($ctype,$cname,$ptype,$pname)
#   + code to get C variable "$cname" of type "$ctype" into the
#     perl-argument variable "$pname" of type "$ptype"
#   + default is just '=' with typecast
sub c2perl {
  my ($ctype,$cname,$ptype,$pname) = @_;
  my (@clines);

  ## special handling code HERE
  # if ($ctype eq '') { ... }
  # else {
  @clines = ("$pname = ($ptype)$cname;");
  #}

  return @clines;
}


# @clines = perl2c($ptype,$pname,$ctype,$cname)
#   + code to set C variable "$cname" of type "$ctype" to the value of
#     the perl-argument variable "$pname" of type "$ptype"
#   + should be memory-safe
sub perl2c {
  my ($ptype,$pname,$ctype,$cname) = @_;
  my (@clines);

  ## special handling code HERE
  if ($ctype eq 'CharPtr') {
    @clines =
      (
       "if ($cname) { Safefree($cname); $cname = NULL; }",
       "if ($pname) { $cname = savepv($pname); }",
      );
  } else {
    ## default case
    @clines = ("$cname = ($ctype)$pname;");
  }

  return @clines;
}

# $ccode_string = clines2string($indent,@clines);
sub clines2string {
  my ($indent,@clines) = @_;
  return
    join('',
	 map {
	   (($_ =~ /^\#/)
	    ? "$_\n"
	    : "$indent$_\n")
	 } @clines);
}


######################################################################
# MAIN (Generation)
######################################################################

%XSPEC_DEFAULTS = @XSPEC_DEFAULTS;
$XSPREFIX = '' unless (defined($XSPREFIX));

@XSCODE = qw(); # XS accessor code to print (contains all neccessary newlines!)
@PMLIST = qw(); # list of accessible fields (one field per element)
@PMCODE = qw(); # PM accessor code to print (contains all neccessary newlines!)

foreach $spec (@xspex) {

  ## clear variables
  foreach $key (keys(%XSPEC_DEFAULTS)) {
    $$key = undef;
  }

  ## instantiate defaults
  %$spec = (%XSPEC_DEFAULTS, %$spec);

  ## instantiate spec variables
  @def = @XSPEC_DEFAULTS;
  while (($key,$_) = splice(@def,0,2)) {
    eval
    #print
      "\$$key = qq($spec->{$key});\n";
    warn($@) if ($@);
  }

  ## add to the perl accessor list
  push(@PMLIST,$fname);

  ## add the perl accessor
  push(@PMCODE,
       "sub $fname { return \$#_ > 0 ? \$_[0]->set_$fname(\$_[1]) : \$_[0]->get_$fname(); }\n",
      );

  ## add to the list of XSubs
  push(@XSCODE,
       ##--- get_*
       "$rtype\n",
       "${XSPREFIX}get_$fname ( $oname )\n",
       "\t INPUT:\n",
       "\t   $otype $oname\n",
       "\t CODE:\n",
       clines2string("\t   ", c2perl($mtype, "$oname->$mname", $rtype, $rname)),
       "\t OUTPUT:\n",
       "\t   $rname\n",
       "\n",

       ##--- set_*
       "$rtype\n",
       "${XSPREFIX}set_$fname ( $oname, $aname )\n",
       "\t INPUT:\n",
       "\t   $otype $oname\n",
       "\t   $atype $aname\n",
       "\t CODE:\n",
       clines2string("\t   ", perl2c($atype, $aname, $mtype, "$oname->$mname")),
       clines2string("\t   ", c2perl($mtype, "$oname->$mname", $rtype, $rname)),
       "\t OUTPUT:\n",
       "\t   $rname\n",
       "\n",
      );
}

######################################################################
# MAIN (Replacement)
######################################################################

## do XS substitution
if (defined($XSIN) && defined($XSOUT)) {
  $XSCODE = join('',@XSCODE);
  while (<XSIN>) {
    s/$XS_ACCESSOR_SYMBOL/$XSCODE/;
    print XSOUT $_;
  }
} else {
  print STDERR "$0 Warning: XS file(s) not specified: XS accessors will not be generated\n";
}
close(XSIN);
close(XSOUT);

## do PM substitution
if (defined($PMIN) && defined($PMOUT)) {
  $PMLIST = "qw(\n\t".join("\n\t",@PMLIST)."\n\t)";
  $PMCODE = join('',@PMCODE);
  while (<PMIN>) {
    s/$PM_ACCESSOR_LIST_SYMBOL/$PMLIST/;
    s/$PM_ACCESSOR_CODE_SYMBOL/$PMCODE/;
    print PMOUT $_;
  }
} else {
  print STDERR "$0 Warning: PM file(s) not specified: Perl accessors will not be generated\n";
}
close(PMIN);
close(PMOUT);

__END__

###############################################################
# Program Usage
###############################################################
=pod

=head1 NAME

create-xs-accessors.perl --
create XSub and PM wrappers for C-struct access.

=head1 SYNOPSIS

 create-xs-accessors.perl [options]

  General Options:
    -help
    -man
    -version

  Generation Options:
    -xsprefix PREFIX
    -specfile SPECFILE

  File Options:
    -xsin  XS_INPUT_FILE
    -xsout XS_OUTPUT_FILE
    -pmin  PM_INPUT_FILE
    -pmout PM_OUTPUT_FILE

  Replacement Options:
    -xsmacro XS_ACCESSOR_SYMBOL  [=#XS_ACCESSOR_CODE#]
    -pmmacro_list PM_LIST_SYMBOL [=#XS_ACCESSOR_LIST#]
    -pmmacro_code PM_CODE_SYMBOL [=#PM_ACCESSOR_CODE#]

=cut


###############################################################
# Description
###############################################################
=pod

=head1 OPTIONS AND ARGUMENTS

=cut

###############################################################
# General Options
###############################################################
=pod

=head2 General Options

=over 4

=item * C<-help>

Display a brief help message.

=item * C<-man>

Display a longer help message.

=item * C<-version>

Display version information.


=back

=cut

###############################################################
# Options
###############################################################
=pod

... the rest of this section is not yet written.  sorry.

=cut

###############################################################
# Footer
###############################################################
=pod

=head1 ACKNOWLEDGEMENTS

perl by Larry Wall.

=head1 AUTHOR

Bryan Jurish E<lt>moocow@ling.uni-potsdam.deE<gt>

=head1 SEE ALSO

perl(1).
h2xs(1).

=cut
