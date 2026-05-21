use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Radamsa',
    VERSION_FROM      => 'lib/Radamsa.pm',
    ABSTRACT          => 'Perl 5 bindings for the Radamsa mutational fuzzer',
    AUTHOR            => 'Hugo T. R. Gouvea',
    LICENSE           => 'mit',
    MIN_PERL_VERSION  => '5.010',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    PREREQ_PM         => {
        'Carp'     => 0,
        'Exporter' => 0,
        'XSLoader' => 0,
    },
    TEST_REQUIRES     => {
        'Test::More' => 0,
    },
    XS                => { 'Radamsa.xs' => 'Radamsa.c' },
    XSOPT             => '-noprototypes',
    OBJECT            => '$(O_FILES) radamsa/c/libradamsa$(OBJ_EXT)',
    INC               => '-Iradamsa/c',
    PM                => {
        'lib/Radamsa.pm' => '$(INST_LIBDIR)/Radamsa.pm',
    },
    depend            => {
        '$(INST_DYNAMIC)' => 'radamsa/c/libradamsa$(OBJ_EXT)',
    },
    clean             => {
        FILES => join q{ },
            'radamsa/c/libradamsa$(OBJ_EXT)',
    },
);

sub MY::postamble {
    return <<'MAKE_FRAG';
RADAMSA_OBJ = radamsa/c/libradamsa$(OBJ_EXT)
RADAMSA_SRC = radamsa/c/libradamsa.c

$(RADAMSA_OBJ): $(RADAMSA_SRC) radamsa/c/radamsa.h
	$(CC) $(CCFLAGS) $(INC) -Iradamsa/c -fPIC -c $(RADAMSA_SRC) -o $(RADAMSA_OBJ)

MAKE_FRAG
}
