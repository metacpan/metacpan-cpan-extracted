#!/usr/bin/env perl

use v5.38;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'PAGI::FastAPI::Queue::Driver::Redis',
    AUTHOR           => 'Mohammad Sajid Anwar <mohammad.anwar@yahoo.com>',
    VERSION_FROM     => 'lib/PAGI/FastAPI/Queue/Driver/Redis.pm',
    ABSTRACT_FROM    => 'lib/PAGI/FastAPI/Queue/Driver/Redis.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.038000',

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },

    PREREQ_PM => {
        'PAGI::FastAPI'       => '1.1.0',
        'Future'              => '0.50',
        'Future::AsyncAwait'  => '0.60',
        'JSON::PP'            => '4.00',
    },

    # Async::Redis is deliberately NOT a hard PREREQ_PM: the driver can
    # also be used with a caller-supplied `redis` client (see the `redis`
    # constructor option in the POD), so Async::Redis is only required at
    # runtime if you don't provide your own client. Install it yourself
    # if you rely on the driver's default auto-connect behaviour:
    #
    #   cpanm Async::Redis

    TEST_REQUIRES => {
        'Test::More'          => '1.302',
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'PAGI::FastAPI::Queue::Driver::Redis' => {
                file    => 'lib/PAGI/FastAPI/Queue/Driver/Redis.pm',
                version => MM->parse_version('lib/PAGI/FastAPI/Queue/Driver/Redis.pm'),
            },
        },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/PAGI-FastAPI-Queue-Driver-Redis.git',
                web  => 'https://github.com/manwar/PAGI-FastAPI-Queue-Driver-Redis',
            },
            bugtracker => {
                web => 'https://github.com/manwar/PAGI-FastAPI-Queue-Driver-Redis/issues',
            },
        },
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES    => 'PAGI-FastAPI-Queue-Driver-Redis-*' },
);
