#!perl -w

use strict;
use Getopt::Long qw(GetOptions);
use ExtUtils::MakeMaker;

## The executable scripts to be installed
my @SCRIPTS   = qw( widgetTclpTk
               );

my $tclshArg;
my $tclsh = "tclsh";
if ($^O eq 'freebsd') {$tclsh.='8.4'}

GetOptions("tclsh=s", \$tclshArg,
	  )
    || die <<EOT;

Usage: perl Makefile.PL [--tclsh <path>] [<makemaker opts>...]

EOT

my %makeArgs = (
    NAME => "Tcl::pTk",
    VERSION_FROM => 'lib/Tcl/pTk.pm',
    EXE_FILES => \@SCRIPTS,
    META_MERGE => 
	{ no_index => { directory => [ qw! benchmarks TableMatrixDemos lib/Tcl/pTk/demos ! ] },
          keywords => [ qw/ Tk Tcl Tix GUI /],
          license  => 'perl',
        } ,
    PREREQ_PM => {
	Tcl => 0.90,
	'Class::ISA' => 0.36,
	'Sub::Name' => 0.05,
    }
);

# Remove META_MERGE parameter for older versions of ExtUtils::MakeMaker
my $MMversion = $ExtUtils::MakeMaker::VERSION;
#print "VERSION = $MMversion\n";
$MMversion =~ s/_\d+$//; # Get rid of underscores in the version for numeric compare
delete $makeArgs{META_MERGE} if( $MMversion < 6.45 );

WriteMakefile(
%makeArgs
);


# Allow the tclsh prog to be provided by env var or arg
if ($tclshArg) {
    $tclsh = $tclshArg;
} elsif (defined($ENV{'TCLSH_PROG'})) {
    $tclsh = $ENV{'TCLSH_PROG'};
}

open TCLSH, "$tclsh test-for-tk.tcl|";
my $res = join '', <TCLSH>;

unless ($res =~ /^ok1/m) {
  die <<EOS;

#####################  Error   ####################################
Your Tcl installation ($tclsh) doesn't appear to include the Tk package.
One of possible reasons is missing file 'pkgIndex.tcl' in ..../tk8.4/
directory; Please check if you can feed 'package require Tk' to tclsh
EOS
}

unless ($res =~ /^ok_Tix/m) {
  warn <<EOS;

##################### Warning ####################################
Your Tcl/Tk installation does not appear to include the Tix package.
Tix is needed for full compatibility with perl/tk.
Build can continue, but some functionality will be missing.

Information on Tix can be found at http://tix.sourceforge.net
EOS
}

my ($TclVersion) = ($res =~ /TclVersion\s+(\S+)/ );

if( $TclVersion < 8.4 ){
  die <<EOS;

##################### Error ####################################
Your Tcl/Tk installation version is less than 8.4. This is not
supported. Upgrade your Tcl/Tk installation.
Tcl/Tk information can be found at http://www.tcl.tk/
EOS

}

if( $TclVersion < 8.5 ){
  warn <<EOS;

##################### Warning ####################################
You have an older Tcl/Tk installation (Version 8.4).
Version 8.5 or higher is recommended for full functionality (including
the new Tile Widget support).
Build can continue, but some functionality will be missing.
Tcl/Tk information can be found at http://www.tcl.tk/
EOS

}





