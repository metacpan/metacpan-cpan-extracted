#!/usr/bin/env perl

use v5.36;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'PAGI::FastAPI',
    AUTHOR           => 'Mohammad Sajid Anwar <mohammad.anwar@yahoo.com>',
    VERSION_FROM     => 'lib/PAGI/FastAPI.pm',
    ABSTRACT_FROM    => 'lib/PAGI/FastAPI.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.036',

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },

    PREREQ_PM => {
        'PAGI'               => '0.002001',
        'PAGI::WebSocket'    => '0.002002',
        'Future::AsyncAwait' => '0.60',
        'Type::Tiny'         => '2.000000',
        'JSON::PP'           => '4.00',
    },

    TEST_REQUIRES => {
        'Test::More' => '1.302',
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'PAGI::FastAPI' => {
                file    => 'lib/PAGI/FastAPI.pm',
                version => MM->parse_version('lib/PAGI/FastAPI.pm'),
            },
            'PAGI::FastAPI::Context' => {
                file    => 'lib/PAGI/FastAPI/Context.pm',
                version => MM->parse_version('lib/PAGI/FastAPI/Context.pm'),
            },
            'PAGI::FastAPI::Depends' => {
                file    => 'lib/PAGI/FastAPI/Depends.pm',
                version => MM->parse_version('lib/PAGI/FastAPI/Depends.pm'),
            },
        },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/PAGI-FastAPI.git',
                web  => 'https://github.com/manwar/PAGI-FastAPI',
            },
            bugtracker => {
                web => 'https://github.com/manwar/PAGI-FastAPI/issues',
            },
        },
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES    => 'PAGI-FastAPI-*' },
);
