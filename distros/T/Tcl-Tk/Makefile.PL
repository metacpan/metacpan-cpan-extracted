#!perl -w

use strict;
use Getopt::Long qw(GetOptions);
use ExtUtils::MakeMaker;

my $tclshArg;
my $tclsh = "tclsh";
if ($^O eq 'freebsd') {$tclsh.='8.4'}

GetOptions("tclsh=s", \$tclshArg,
	  )
    || die <<EOT;

Usage: perl Makefile.PL [--tclsh <path>] [<makemaker opts>...]

EOT

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

Your Tcl installation ($tclsh) fails to find Tk package.
One of possible reasons is missing file 'pkgIndex.tcl' in ..../tk8.4/
directory; Please check if you can feed 'package require Tk' to tclsh
EOS
}

unless ($res =~ /^ok2/m) {
  die <<EOS;

Your Tk installation fails to find 'snit' package.
Make sure that it is installed within your Tcl/Tk.
EOS
}

WriteMakefile(
    NAME => "Tcl::Tk",
    VERSION_FROM => 'lib/Tcl/Tk.pm',
    NO_META => 1,
    PREREQ_PM => {
	Tcl => 0.98,
    },
);
