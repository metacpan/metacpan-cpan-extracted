#!/usr/bin/env perl

use v5.38;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'PAGI::FastAPI',
    AUTHOR           => 'Mohammad Sajid Anwar <mohammad.anwar@yahoo.com>',
    VERSION_FROM     => 'lib/PAGI/FastAPI.pm',
    ABSTRACT_FROM    => 'lib/PAGI/FastAPI.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.038000',

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },

    PREREQ_PM => {
        'PAGI'                        => '0.002001',
        'PAGI::WebSocket'             => '0.002002',
        'PAGI::SSE'                   => '0.002002',
        'PAGI::Middleware::CORS'      => '0.002002',
        'PAGI::Middleware::RateLimit' => '0.002002',
        'Future::AsyncAwait'          => '0.60',
        'Type::Tiny'                  => '2.000000',
        'JSON::PP'                    => '4.00',
    },

    TEST_REQUIRES => {
        'Test::More'         => '1.302',
        'Test::Fatal'        => '0.017',
        'PAGI::Test::Client' => '0.002002',
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'PAGI::FastAPI' => {
                file    => 'lib/PAGI/FastAPI.pm',
                version => MM->parse_version('lib/PAGI/FastAPI.pm'),
            },
            'PAGI::FastAPI::BotProtection' => {
                file    => 'lib/PAGI/FastAPI/BotProtection.pm',
                version => MM->parse_version('lib/PAGI/FastAPI/BotProtection.pm'),
            },
            'PAGI::FastAPI::BotProtection::ProofOfWork' => {
                file    => 'lib/PAGI/FastAPI/BotProtection/ProofOfWork.pm',
                version => MM->parse_version('lib/PAGI/FastAPI/BotProtection/ProofOfWork.pm'),
            },
            'PAGI::FastAPI::Context' => {
                file    => 'lib/PAGI/FastAPI/Context.pm',
                version => MM->parse_version('lib/PAGI/FastAPI/Context.pm'),
            },
            'PAGI::FastAPI::Cookies' => {
                file    => 'lib/PAGI/FastAPI/Cookies.pm',
                version => MM->parse_version('lib/PAGI/FastAPI/Cookies.pm'),
            },
            'PAGI::FastAPI::Depends' => {
                file    => 'lib/PAGI/FastAPI/Depends.pm',
                version => MM->parse_version('lib/PAGI/FastAPI/Depends.pm'),
            },
            'PAGI::FastAPI::Middleware::BotProtection' => {
                file    => 'lib/PAGI/FastAPI/Middleware/BotProtection.pm',
                version => MM->parse_version('lib/PAGI/FastAPI/Middleware/BotProtection.pm'),
            },
            'PAGI::FastAPI::Middleware::ExceptionHandler' => {
                file    => 'lib/PAGI/FastAPI/Middleware/ExceptionHandler.pm',
                version => MM->parse_version('lib/PAGI/FastAPI/Middleware/ExceptionHandler.pm'),
            },
            'PAGI::FastAPI::Middleware::RateLimit' => {
                file    => 'lib/PAGI/FastAPI/Middleware/RateLimit.pm',
                version => MM->parse_version('lib/PAGI/FastAPI/Middleware/RateLimit.pm'),
            },
            'PAGI::FastAPI::Queue' => {
                file    => 'lib/PAGI/FastAPI/Queue.pm',
                version => MM->parse_version('lib/PAGI/FastAPI/Queue.pm'),
            },
            'PAGI::FastAPI::Queue::Driver' => {
                file    => 'lib/PAGI/FastAPI/Queue/Driver.pm',
                version => MM->parse_version('lib/PAGI/FastAPI/Queue/Driver.pm'),
            },
            'PAGI::FastAPI::Queue::Driver::Memory' => {
                file    => 'lib/PAGI/FastAPI/Queue/Driver/Memory.pm',
                version => MM->parse_version('lib/PAGI/FastAPI/Queue/Driver/Memory.pm'),
            },
            'PAGI::FastAPI::RateLimit::Driver' => {
                file    => 'lib/PAGI/FastAPI/RateLimit/Driver.pm',
                version => MM->parse_version('lib/PAGI/FastAPI/RateLimit/Driver.pm'),
            },
            'PAGI::FastAPI::RateLimit::Driver::Memory' => {
                file    => 'lib/PAGI/FastAPI/RateLimit/Driver/Memory.pm',
                version => MM->parse_version('lib/PAGI/FastAPI/RateLimit/Driver/Memory.pm'),
            },
            'PAGI::FastAPI::Response' => {
                file    => 'lib/PAGI/FastAPI/Response.pm',
                version => MM->parse_version('lib/PAGI/FastAPI/Response.pm'),
            },
            'PAGI::FastAPI::Response::File' => {
                file    => 'lib/PAGI/FastAPI/Response/File.pm',
                version => MM->parse_version('lib/PAGI/FastAPI/Response/File.pm'),
            },
            'PAGI::FastAPI::Response::HTML' => {
                file    => 'lib/PAGI/FastAPI/Response/HTML.pm',
                version => MM->parse_version('lib/PAGI/FastAPI/Response/HTML.pm'),
            },
            'PAGI::FastAPI::Response::Redirect' => {
                file    => 'lib/PAGI/FastAPI/Response/Redirect.pm',
                version => MM->parse_version('lib/PAGI/FastAPI/Response/Redirect.pm'),
            },
            'PAGI::FastAPI::Response::SSE' => {
                file    => 'lib/PAGI/FastAPI/Response/SSE.pm',
                version => MM->parse_version('lib/PAGI/FastAPI/Response/SSE.pm'),
            },
            'PAGI::FastAPI::ResponseModel' => {
                file    => 'lib/PAGI/FastAPI/ResponseModel.pm',
                version => MM->parse_version('lib/PAGI/FastAPI/ResponseModel.pm'),
            },
            'PAGI::FastAPI::TypedPath' => {
                file    => 'lib/PAGI/FastAPI/TypedPath.pm',
                version => MM->parse_version('lib/PAGI/FastAPI/TypedPath.pm'),
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
