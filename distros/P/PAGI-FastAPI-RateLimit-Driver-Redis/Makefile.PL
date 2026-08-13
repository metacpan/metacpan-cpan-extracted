#!/usr/bin/env perl

use v5.36;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'PAGI::FastAPI::RateLimit::Driver::Redis',
    AUTHOR           => 'Mohammad Sajid Anwar <mohammad.anwar@yahoo.com>',
    VERSION_FROM     => 'lib/PAGI/FastAPI/RateLimit/Driver/Redis.pm',
    ABSTRACT_FROM    => 'lib/PAGI/FastAPI/RateLimit/Driver/Redis.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.036',

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },

    PREREQ_PM => {
        'PAGI::FastAPI' => '1.0.0',
    },

    TEST_REQUIRES => {
        'Test::More' => '1.302',
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'PAGI::FastAPI::RateLimit::Driver::Redis' => {
                file    => 'lib/PAGI/FastAPI/RateLimit/Driver/Redis.pm',
                version => MM->parse_version('lib/PAGI/FastAPI/RateLimit/Driver/Redis.pm'),
            },
        },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/PAGI-FastAPI-RateLimit-Driver-Redis.git',
                web  => 'https://github.com/manwar/PAGI-FastAPI-RateLimit-Driver-Redis',
            },
            bugtracker => {
                web => 'https://github.com/manwar/PAGI-FastAPI-RateLimit-Driver-Redis/issues',
            },
        },
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES    => 'PAGI-FastAPI-RateLimit-Driver-Redis-*' },
);
