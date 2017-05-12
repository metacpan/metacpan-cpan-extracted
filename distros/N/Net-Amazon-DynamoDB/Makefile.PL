#!/usr/bin/env perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Net::Amazon::DynamoDB',
    VERSION_FROM     => 'lib/Net/Amazon/DynamoDB.pm',
    ABSTRACT         => 'Simple interface for Amazon DynamoDB',
    AUTHOR           => 'Ulrich Kautz <uk@fortrabbit.de>',
    MIN_PERL_VERSION => '5.10.0',
    BUILD_REQUIRES   => {
        'Test::More' => 0,
        'Cache' => 0,
        'Cache::Memory' => 0,
    },
    PREREQ_PM        => {
        'DateTime' => 0,
        'DateTime::Format::HTTP' => 0,
        'DateTime::Format::Strptime' => 0,
        'DateTime::TimeZone' => 0,
        'DateTime::TimeZone::Local' => 0,
        'Digest::SHA' => 0,
        'HTTP::Request' => 0,
        'JSON' => 0,
        'LWP::Protocol::https' => 0,
        'LWP::UserAgent' => 0,
        'LWP::ConnCache' => 0,
        'Moose' => 1.0,
        'Net::Amazon::AWSSign' => 0,
        'Time::HiRes' => 0,
        'XML::Simple' => 0,
    },
    test => {TESTS => 't/*.t t/*/*.t'}
);