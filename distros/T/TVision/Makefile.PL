use strict;
use Getopt::Long;
use ExtUtils::MakeMaker;

#use Devel::CheckLib;
#check_lib_or_exit( lib => 'tvision', header => 'tvision/tv.h' );

# path to turbovision headers, libs
#for example:
# perl Makefile.PL "--ldflags=-LC:\vad\tv\tvision.git\_build-2 -ltvision" --cflags=-IC:\vad\tv\tvision.git\include

GetOptions(
   "ldflags=s",   \ my $ldflags,
   "cflags=s",    \ my $cflags,
   "skip!",       \ my $skip,
   "help!",       \ my $help,
) || usage();
usage() if $help;

sub _die ($) {
    # CPAN smokers report FAIL if Makefile.PL dies, it should exit with status 0
    my $err = shift;
    warn $err;
    exit 0;
}

sub usage {
    _die <<'EOT';
Most common usage:
 perl Makefile.PL

Customised usage:
 perl Makefile.PL      \
  [--ldflags=...]      \ # Use this specific library
  [--cflags=...]      \ # Use this specific include path
  [--define=...]       \ # Use this specific set of defines
  [--help]             \ # --help
  [<makemaker opts>]     # e.g. LINKTYPE=STATIC

For compilation against tvision at given specific location
 perl Makefile.PL --library=-l/path/to/tvision.a          \
    --include=-I/path/to/tv/include                       \
    --define="-DDEFINE1=SMTH1 -DDEFINE2=SMTH2"
EOT
}

$|=1;
if (!$ldflags and !$cflags) {
    # user haven't specified where include and libraries.
    # This means OS has these include and libs.
    # Do we beleive system has it? NO.
    # therefore build the one provided with us.
    if ($^O eq 'MSWin32') {
	# assume strawberry perl with cmake/gmake
	mkdir 'tv-build';
	chdir 'tv-build';
	if (`gcc --version` =~ /^\S+ +\(.*?\) +(\d+)\.(\d+)\.(\d+)$/m) {
	    my $gccver = sprintf "%02d.%03d%03d", $1, $2, $3;
	    if ($gccver>11) {
		print "GCC version $gccver OK, do cmake\n";
		`cmake -S ../tvision.git -B . -G "MinGW Makefiles"
		    2>&1 > cmake-out.txt`;
		print "do gmake\n";
		`gmake 2>&1 > gmake-out.txt`;
		$cflags = "-Itvision.git/include";
		$ldflags = "-ltv-build/libtvision.a";
	    } else {
		print "warning: your GCC version $gccver is <10. continue, but...\n";
	    }
	} else {
	    print "warning: can't see version of your gcc. continue, but...\n" . ("it is ".`gcc --version`);
	}
	chdir '..';
    }
    elsif ($skip) {
    } elsif ($^O eq 'linux' or $^O eq 'cygwin') {
	# assume normal gcc/cmake/make
	mkdir 'tv-build';
	chdir 'tv-build';
	if (`gcc --version` =~ /^\S+ +\(.*?\) +(\d+)\.(\d+)\.(\d+)(?: \d*)?$/m) {
	    my $gccver = sprintf "%02d.%03d%03d", $1, $2, $3;
	    if ($gccver>=12) {
		print "GCC version $gccver OK, do cmake\n";
		`cmake -S ../tvision.git -B .  2>&1 > cmake-out.txt`;
		print "do make\n";
		`make 2>&1 > make-out.txt`;
		$cflags = "-Itvision.git/include";
		$ldflags = "-Ltv-build -ltvision -lncurses -lncursesw";
	    } else {
		print "warning: your GCC version $gccver is less than 12.0. continue, but...\n";
	    }
	} else {
	    print "warning: can't see version of your gcc. continue, but...\n" . ("it is ".`gcc --version`);
	}
	chdir '..';
    }
}

WriteMakefile(
    NAME          => 'TVision',
    VERSION_FROM  => 'TVision.pm', # finds $VERSION
    ABSTRACT_FROM => 'TVision.pm', # retrieve abstract from module
    AUTHOR        => 'Vadim Konovalov <vkon@cpan.org>',
    META_MERGE => {
        "meta-spec" => { version => 2 },
        resources => {
            bugtracker => {
                web => 'https://github.com/vadrerko/perl-tvision/issues',
            },
            repository => {
                type => 'git',
                web => 'https://github.com/vadrerko/perl-tvision',
                url => 'https://github.com/vadrerko/perl-tvision.git',
            },
        }
    },
    LIBS          => ["$ldflags"],
    # DEFINE        => TODO
    INC           => "$cflags", # e.g., '-I. -I/usr/include/other'
    OBJECT  => 'TVision.o TVision-methods.o',
    XS      => { 'TVision.xs' => 'TVision.cpp', 'TVision-methods.xs' => 'TVision-methods.cpp' },
);

sub MY::xs_c {
    return '
.xs.cpp:
	$(PERL) -I$(PERL_ARCHLIB) -I$(PERL_LIB) $(XSUBPP) $(XSPROTOARG) $(XSUBPPARGS) $*.xs >xstmp.c && $(MV) xstmp.c $*.cpp
';
}

sub MY::postamble {
    return <<'EOS';
TVision-methods.xs: TVision-methods.xs.in
	$(PERL) -MText::Template -we "Text::Template::fill_in_file('TVision-methods.xs.in', DELIMITERS=>['{{{','}}}'],OUTPUT => \*STDOUT)" > TVision-methods.xs

typemap: typemap.in
	$(PERL) -MText::Template -we "Text::Template::fill_in_file('typemap.in', DELIMITERS=>['{{{','}}}'],OUTPUT => \*STDOUT)" > typemap

EOS
}

