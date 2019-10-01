#!/usr/bin/env perl
use 5.006;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojolicious-Command-scaffold',
    AUTHOR           => q{Adrian Crisan <adrian.crisan88@gmail.com>},
    VERSION_FROM     => 'lib/Mojolicious/Command/scaffold.pm',
    ABSTRACT_FROM    => 'lib/Mojolicious/Command/scaffold.pm',
    LICENSE          => 'MIT',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
    },
    PREREQ_PM => {
        'Mojo::Console' => 0,
        'Test::More' => 0,
    },
    META_MERGE   => {
        no_index       => {directory => ['t']},
        resources => {
            bugtracker => {
                web => 'https://github.com/crlcu/Mojolicious-Command-scaffold/issues'
            },
            license    => ['https://opensource.org/licenses/MIT'],
            repository => {
                type => 'git',
                url  => 'https://github.com/crlcu/Mojolicious-Command-scaffold.git',
                web  => 'https://github.com/crlcu/Mojolicious-Command-scaffold',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mojolicious-Command-scaffold-*' },
    test      => {TESTS => 't/*.t'},
);
