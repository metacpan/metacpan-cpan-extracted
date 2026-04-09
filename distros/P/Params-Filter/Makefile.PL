use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Params::Filter',
    VERSION_FROM     => 'lib/Params/Filter.pm',
    AUTHOR           => 'Bruce Van Allen <bva@cruzio.com>',
    ABSTRACT         => 'Field filtering for parameter construction in subroutines and methods',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.036',

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

    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/bwva/Params-Filter.git',
                web  => 'https://github.com/bwva/Params-Filter',
            },
            bugtracker => {
                web => 'https://github.com/bwva/Params-Filter/issues',
            },
        },
        provides => {
            'Params::Filter' => {
                file    => 'lib/Params/Filter.pm',
                version => '0.017001',
            },
        },
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Params-Filter-*' },
);
