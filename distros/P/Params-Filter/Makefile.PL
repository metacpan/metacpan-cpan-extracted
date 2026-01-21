use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Params::Filter',
    VERSION_FROM     => 'lib/Params/Filter.pm',
    AUTHOR           => 'Bruce Van Allen <bva@cruzio.com>',
    ABSTRACT         => 'Field filtering for parameter construction in subroutines and methods',
    LICENSE          => 'perl',
    MIN_PERL_VERSION => '5.036',
    INSTALL_BASE     => undef,

    PREREQ_PM => {
        'Exporter' => 0,
    },

    TEST_REQUIRES => {
        'Test2::V0' => 0,
    },

    EXE_FILES => [],

    PM => {
        'lib/Params/Filter.pm' => '$(INST_LIB)/Params/Filter.pm',
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Params-Filter-*' },
);
