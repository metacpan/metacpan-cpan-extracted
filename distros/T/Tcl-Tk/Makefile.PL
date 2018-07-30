#!perl -w
sub _die ($) {
    # CPAN smokers report FAIL if Makefile.PL dies, it should exit with status 0
    my $err = shift;
    warn $err;
    exit 0;
}

use strict;
use Getopt::Long;
use ExtUtils::MakeMaker;

my $tclsh_default = 'tclsh';
# for FreeBSD users, try to guess their name for tclsh; see ticket 6086
if ($^O eq 'freebsd') {
    for my $ver (qw(8.9 8.8 8.7 8.6 8.5 8.4 8.3 8.2 8.1 8.0)) {
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
) || usage();
usage() if $help;
sub usage {
    _die <<'EOT';
Usage: perl Makefile.PL [--tclsh <path>] [<makemaker opts>...]

--tclsh option is mostly for FreeBSD users, who have tclsh86 or alike;
however default autodetection should be fine with freebsd as well.
EOT
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

Your Tk installation fails to find 'snit' package.
Some old copy of snit1 will be used. The correct one is prefered.
EOS
}

unless ($res =~ /^ok3/m) {
  warn <<EOS;

Your Tk installation fails to find 'tklib' package. This package is recommended,
otherwise we'll substitute some older version.
Be informed on this and better have this package installed within your Tcl/Tk.
EOS
}

unless ($res =~ /^ok4/m) {
  warn <<EOS;

Your Tk installation fails to find 'tile' package. This package is highly 
recommended, otherwise no 'scrolled_text' and 'scrolled_canvas' widgets will be
available. Probably it will be in some future, but you'll better ensure than
you have 'tile' package installed. (ttk widgets)
EOS
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
                web => 'https://github.com/vadrer/perl-tcl-tk',
                url => 'https://github.com/vadrer/perl-tcl-tk.git',
            },
            MailingList => 'mailto:tcltk@perl.org',
        },
	no_index => {
	  directory=>[qw(demos tk-demos)]
	},
	keywords => [qw(Tk Tcl/Tk/Tix GUI)],
    },
    PREREQ_PM => {
	Tcl => 1.11, # this is required, otherwise $int->Eval(">500octets") silently misbehaves
    },
);

