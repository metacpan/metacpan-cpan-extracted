use strict;
use Getopt::Long;
use ExtUtils::MakeMaker;

# path to turbovision headers, libs

#for example:
# perl Makefile.PL "--ldflags=-LC:\vad\tv\tvision.git\_build-2 -ltvision" --cflags=-IC:\vad\tv\tvision.git\include

GetOptions(
   "ldflags=s",   \ my $ldflags,
   "cflags=s",    \ my $cflags,
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
  [--library=...]      \ # Use this specific library
  [--include=...]      \ # Use this specific include path
  [--define=...]       \ # Use this specific set of defines
  [--help]             \ # --help
  [<makemaker opts>]     # e.g. LINKTYPE=STATIC

For compilation against tvision at given specific location
 perl Makefile.PL --library=-l/path/to/tvision.a          \
    --include=-I/path/to/tv/include                       \
    --define="-DDEFINE1=SMTH1 -DDEFINE2=SMTH2"
EOT
}

#?? -lstdc++ -lmingw32 -lgcc_s -lgcc -lmingwex -lmsvcrt -lkernel32 -lpthread -ladvapi32 -lshell32 -luser32

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
    BUILD_REQUIRES => {
	'Text::Template' => 0
    },
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

