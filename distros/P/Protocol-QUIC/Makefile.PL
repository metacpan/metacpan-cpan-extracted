#!/usr/bin/env perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Protocol::QUIC',
    AUTHOR           => 'Mohammad Sajid Anwar <mohammad.anwar@yahoo.com>',
    VERSION_FROM     => 'lib/Protocol/QUIC.pm',
    ABSTRACT_FROM    => 'lib/Protocol/QUIC.pm',
    LICENSE          => 'artistic_2',
    MIN_PERL_VERSION => '5.014000',
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => '6.64',
    },
    TEST_REQUIRES => {
        'Test::More' => '0.98',
    },
    PREREQ_PM => {
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Protocol-QUIC-*' },
    META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Protocol::QUIC' => {
                file    => 'lib/Protocol/QUIC.pm',
                version => MM->parse_version('lib/Protocol/QUIC.pm'),
            },
        },
    },
);
