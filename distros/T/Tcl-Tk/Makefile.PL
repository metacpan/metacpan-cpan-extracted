#!perl -w
sub _die ($) {
    # some wisdom from tcl.pm, to workaround bogus FAIL reports:
    # "now CPAN smokers report FAIL if Makefile.PL dies, it should exit with status 0"
    my $err = shift;
    warn $err;
    exit 0;
}

use Getopt::Long;
use ExtUtils::MakeMaker;

my $tclshArg;
my $tclsh = "tclsh";
if ($^O eq 'freebsd') {$tclsh.='8.4'}

GetOptions("tclsh=s", \$tclshArg) || _die <<'EOT';
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
  _die <<EOS;

Your Tcl installation ($tclsh) fails to find Tk package.
One of possible reasons is missing file 'pkgIndex.tcl' in ..../tk8.4/
directory; Please check if you can feed 'package require Tk' to tclsh
EOS
}

unless ($res =~ /^ok2/m) {
  warn <<EOS;

Your Tk installation fails to find 'snit' package. For full functionality
this package is required. Make sure that it is installed within your Tcl/Tk.
EOS
}

unless ($res =~ /^ok3/m) {
  warn <<EOS;

Your Tk installation fails to find 'tklib' package. For full functionality
this package is required. Make sure that it is installed within your Tcl/Tk.
EOS
}

WriteMakefile(
    NAME => "Tcl::Tk",
    VERSION_FROM => 'lib/Tcl/Tk.pm',
    LICENSE => 'perl',
    MIN_PERL_VERSION => '5.006',
    ABSTRACT_FROM => 'lib/Tcl/Tk.pm',
    META_MERGE => {
        resources => {
            repository => 'http://github.com/vadrer/perl-tcl-tk',
            MailingList => 'mailto:tcltk@perl.org',
        },
	no_index => {
	  directory=>[qw(demos tk-demos)]
	},
	keywords => [qw(Tk Tcl/Tk/Tix GUI)],
	auto_regenerate => 0,
	distribution_type => 'module',
    },
    PREREQ_PM => {
	Tcl => 0.98,
    },
);

