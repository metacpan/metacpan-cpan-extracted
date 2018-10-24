use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Struct::Diff',
    AUTHOR           => 'Michael Samoglyadov <mixas@cpan.org>',
    VERSION_FROM     => 'lib/Struct/Diff.pm',
    ABSTRACT_FROM    => 'lib/Struct/Diff.pm',
    LICENSE          => 'Perl_5',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.008,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Clone'           => 0,
        'Data::Dumper'    => 0,
        'Test::More'      => 0,
    },
    META_MERGE => {
        resources => {
            repository  => 'https://github.com/mr-mixas/Struct-Diff.pm',
        },
    },
    PREREQ_PM => {
        'Algorithm::Diff' => 1.19,
        'Carp'            => 0,
        'Exporter'        => 0,
        'Scalar::Util'    => 0,
        'Storable'        => 2.05,
        'parent'          => 0,
        'strict'          => 0,
        'warnings'        => 0,
    },
    dist  => {
        COMPRESS => 'gzip -9f',
        SUFFIX   => 'gz',
    },
    clean => { FILES => 'Struct-Diff-*' },
);
