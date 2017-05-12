use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Rose::DBx::RegistryConfig',
    AUTHOR              => 'Karl Erisman <karl.erisman@icainformatics.com>',
    VERSION_FROM        => 'lib/Rose/DBx/RegistryConfig.pm',
    ABSTRACT_FROM       => 'lib/Rose/DBx/RegistryConfig.pm',
    PREREQ_PM => {
        'Rose::DB'      => 0,
        'YAML'          => 0,
        'Carp'          => 0,
        'Test::More'    => 0,
        'Test::Deep'    => 0,
        'DBD::SQLite'   => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Rose-DBx-RegistryConfig-*' },
);
