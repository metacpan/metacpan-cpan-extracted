use 5.006;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojolicious::Plugin::SQLMaker',
    AUTHOR           => q{Tatsuya Fukata <tatsuya.fukata@gmail.com>},
    VERSION_FROM     => 'lib/Mojolicious/Plugin/SQLMaker.pm',
    ABSTRACT_FROM    => 'lib/Mojolicious/Plugin/SQLMaker.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Mojolicious' => 3.63,
        'SQL::Maker'  => 1.07,
        'Carp'        => 1.26,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mojolicious-Plugin-SQLMaker-*' },
);
