#!/usr/bin/env perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'PAGI::FastAPI::Security',
    AUTHOR           => 'Mohammad Sajid Anwar <mohammad.anwar@yahoo.com>',
    VERSION_FROM     => 'lib/PAGI/FastAPI/Security.pm',
    ABSTRACT_FROM    => 'lib/PAGI/FastAPI/Security.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.036',

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },

    PREREQ_PM => {
        'PAGI::FastAPI'       => '1.2.2',
        'Future::AsyncAwait'  => '0.60',
        'MIME::Base64'        => '3.15',
    },

    TEST_REQUIRES => {
        'Test::More' => '1.302',
    },

    META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'PAGI::FastAPI::Security' => {
                file    => 'lib/PAGI/FastAPI/Security.pm',
                version => MM->parse_version('lib/PAGI/FastAPI/Security.pm'),
            },
            'PAGI::FastAPI::Security::Base' => {
                file    => 'lib/PAGI/FastAPI/Security/Base.pm',
                version => MM->parse_version('lib/PAGI/FastAPI/Security/Base.pm'),
            },
            'PAGI::FastAPI::Security::HTTPBearer' => {
                file    => 'lib/PAGI/FastAPI/Security/HTTPBearer.pm',
                version => MM->parse_version('lib/PAGI/FastAPI/Security/HTTPBearer.pm'),
            },
            'PAGI::FastAPI::Security::HTTPBasic' => {
                file    => 'lib/PAGI/FastAPI/Security/HTTPBasic.pm',
                version => MM->parse_version('lib/PAGI/FastAPI/Security/HTTPBasic.pm'),
            },
            'PAGI::FastAPI::Security::APIKey' => {
                file    => 'lib/PAGI/FastAPI/Security/APIKey.pm',
                version => MM->parse_version('lib/PAGI/FastAPI/Security/APIKey.pm'),
            },
            'PAGI::FastAPI::Security::OAuth2::PasswordBearer' => {
                file    => 'lib/PAGI/FastAPI/Security/OAuth2/PasswordBearer.pm',
                version => MM->parse_version('lib/PAGI/FastAPI/Security/OAuth2/PasswordBearer.pm'),
            },
        },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/PAGI-FastAPI-Security.git',
                web  => 'https://github.com/manwar/PAGI-FastAPI-Security',
            },
            bugtracker => {
                web => 'https://github.com/manwar/PAGI-FastAPI-Security/issues',
            },
        },
    },

    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean => { FILES    => 'PAGI-FastAPI-Security-*' },
);
