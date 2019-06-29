#!/usr/bin/env perl
use 5.006;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojolicious::Plugin::Validate::Tiny',
    AUTHOR           => q{Adrian Crisan <adrian.crisan88@gmail.com>},
    VERSION_FROM     => 'lib/Mojolicious/Plugin/Validate/Tiny.pm',
    ABSTRACT_FROM    => 'lib/Mojolicious/Plugin/Validate/Tiny.pm',
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
        'Mojolicious'    => 0,
        'Validate::Tiny' => 0.984
    },
    META_MERGE   => {
        no_index       => {directory => ['t']},
        resources => {
            bugtracker => {
                web => 'https://github.com/crlcu/Mojolicious-Plugin-Validate-Tiny/issues'
            },
            license    => ['https://opensource.org/licenses/MIT'],
            repository => {
                type => 'git',
                url  => 'https://github.com/crlcu/Mojolicious-Plugin-Validate-Tiny.git',
                web  => 'https://github.com/crlcu/Mojolicious-Plugin-Validate-Tiny',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mojolicious-Plugin-Validate-Tiny-*' },
    test => {TESTS => 't/*.t'},
);
