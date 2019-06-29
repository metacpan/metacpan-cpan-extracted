#!/usr/bin/env perl
use 5.006;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Mojolicious::Plugin::GetSentry',
    AUTHOR           => q{Adrian Crisan <adrian.crisan88@gmail.com>},
    VERSION_FROM     => 'lib/Mojolicious/Plugin/GetSentry.pm',
    ABSTRACT_FROM    => 'lib/Mojolicious/Plugin/GetSentry.pm',
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
        'Data::Dump' => 0,
        'Mojolicious' => 0,
        'Devel::StackTrace::Extract' => 0,
        'Mojo::IOLoop' => 0,
        'Sentry::Raven' => 0,
    },
    META_MERGE   => {
        no_index       => {directory => ['t']},
        resources => {
            bugtracker => {
                web => 'https://github.com/crlcu/Mojolicious-Plugin-GetSentry/issues'
            },
            license    => ['https://opensource.org/licenses/MIT'],
            repository => {
                type => 'git',
                url  => 'https://github.com/crlcu/Mojolicious-Plugin-GetSentry.git',
                web  => 'https://github.com/crlcu/Mojolicious-Plugin-GetSentry',
            },
        },
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mojolicious-Plugin-GetSentry-*' },
    test => {TESTS => 't/*.t'},
);
