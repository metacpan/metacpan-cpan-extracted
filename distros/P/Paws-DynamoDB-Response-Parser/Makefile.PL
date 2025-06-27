#!/usr/bin/perl

use v5.14;
use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME               => 'Paws::DynamoDB::Response::Parser',
    AUTHOR             => q{Mohammad Sajid Anwar <mohammad.anwar@yahoo.com>},
    VERSION_FROM       => 'lib/Paws/DynamoDB/Response/Parser.pm',
    ABSTRACT_FROM      => 'lib/Paws/DynamoDB/Response/Parser.pm',
    LICENSE            => 'artistic_2',
    MIN_PERL_VERSION   => 5.014,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More'       => 0,
        'Test::MockObject' => 0,
    },
    PREREQ_PM => {
        'Data::Dumper'     => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    test  => { TESTS => 't/*.t' },
    clean => { FILES => 'Paws-DynamoDB-Response-Parser-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'Paws::DynamoDB::Response::Parser' => { file => 'lib/Paws/DynamoDB/Response/Parser.pm', version => '0.06' },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/Paws-DynamoDB-Response-Parser.git',
                web  => 'https://github.com/manwar/Paws-DynamoDB-Response-Parser',
            },
        }})
     : ()
    ),
);
