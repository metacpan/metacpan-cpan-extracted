#!/usr/bin/env perl
use 5.006;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojolicious::Plugin::Minion::Tasks',
    AUTHOR           => q{Adrian Crisan <adrian.crisan88@gmail.com>},
    VERSION_FROM     => 'lib/Mojolicious/Plugin/Minion/Tasks.pm',
    ABSTRACT_FROM    => 'lib/Mojolicious/Plugin/Minion/Tasks.pm',
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
        'Mojolicious' => 0,
        'Module::Loader' => 0,
        'Try::Tiny' => 0,
        'Minion::Task' => 0,
    },
    META_MERGE   => {
        no_index       => {directory => ['t']},
        resources => {
            bugtracker => {
                web => 'https://github.com/crlcu/Mojolicious-Plugin-Minion-Tasks/issues'
            },
            license    => ['https://opensource.org/licenses/MIT'],
            repository => {
                type => 'git',
                url  => 'https://github.com/crlcu/Mojolicious-Plugin-Minion-Tasks.git',
                web  => 'https://github.com/crlcu/Mojolicious-Plugin-Minion-Tasks',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mojolicious-Plugin-Minion-Tasks-*' },
    test => {TESTS => 't/*.t'},
);
