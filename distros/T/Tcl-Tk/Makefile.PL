sub _die ($) {
    # CPAN smokers report FAIL if Makefile.PL dies, it should exit with status 0
    my $err = shift;
    warn $err;
    exit 0;
}

use strict;
use Getopt::Long;
use ExtUtils::MakeMaker;

# Allow bypassing with --no-test-for-tk
my $test_for_tk = 1;

my $tclsh_default = 'tclsh';
# for FreeBSD users, try to guess their name for tclsh; see ticket 6086
if ($^O eq 'freebsd') {
    for my $ver (qw(9.0 9.1 8.6 8.5 8.4 8.3 8.2 8.1 8.0)) {
       system "which tclsh$ver >/dev/null 2>&1";
       if ($? == 0) {
	    $tclsh_default = "tclsh$ver"; # ok will use that as default
	    last;
	}
    }
}

GetOptions(
    "tclsh=s", \(my $tclsh=$tclsh_default),
    "help!",   \ my $help,
    "test-for-tk!", \$test_for_tk,
) || usage();
usage() if $help;
sub usage {
    _die <<'EOT';
Usage: perl Makefile.PL [--tclsh <path>] [--no-test-for-tk] [<makemaker opts>...]

--tclsh option is mostly for FreeBSD users, who have tclsh86 or alike;
however default autodetection should be fine with freebsd as well.
EOT
}


if ($test_for_tk) {
    my $res = `$tclsh test-for-tk.tcl`;

    unless ($res =~ /^ok1/m) {
        _die <<EOS;

Your Tcl installation ($tclsh) fails to find Tk package.
One of possible reasons is missing file 'pkgIndex.tcl' in ..../tk8.4/
directory; Please check if you can feed 'package require Tk' to tclsh
EOS
    }

    unless ($res =~ /^ok2/m) {
        warn <<EOS;

Your Tk installation fails to find 'snit' package.
Some old copy of snit1 will be used. The correct one is prefered.
EOS
    }

    unless ($res =~ /^ok3/m) {
        warn <<EOS;

Your Tcl/Tk installation lacks the 'tklib' package. This package is highly
recommended because it provides 'tooltip::tooltip' for widget hints. You
can ignore this warning if you either have tooltip::tooltip on your system
or do not plan to use this functionality.
EOS
    }
}

WriteMakefile(
    NAME => "Tcl::Tk",
    VERSION_FROM => 'lib/Tcl/Tk.pm',
    LICENSE => 'perl',
    MIN_PERL_VERSION => '5.006',
    ABSTRACT_FROM => 'lib/Tcl/Tk.pm',
    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources => {
            repository => {
                type => 'git',
                web => 'https://github.com/vadrerko/perl-tcl-tk',
                url => 'https://github.com/vadrerko/perl-tcl-tk.git',
            },
            MailingList => 'mailto:tcltk@perl.org',
        },
	no_index => {
	  directory=>[qw(demos tk-demos)]
	},
	keywords => [qw(Tk Tcl/Tk GUI)],
    },
    PREREQ_PM => {
	Tcl => 1.11, # this is required, otherwise $int->Eval(">500octets") silently misbehaves
    },
);

