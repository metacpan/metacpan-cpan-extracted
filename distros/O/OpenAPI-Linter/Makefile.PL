#!/usr/bin/env perl

use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'OpenAPI::Linter',
    VERSION_FROM => 'lib/OpenAPI/Linter.pm',
    ABSTRACT     => 'Lint and validate OpenAPI specification files',
    AUTHOR       => 'Mohammad Sajid Anwar <mohammad.anwar@yahoo.com>',
    LICENSE      => 'artistic_2',
    EXE_FILES    => ['script/openapi-linter'],
    PREREQ_PM    => {
        'JSON::Validator' => 0,
        'YAML::XS'        => 0,
        'JSON'            => 0,
        'File::Slurp'     => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    test  => { TESTS => 't/*.t' },
    clean => { FILES => 'OpenAPI-Linter-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'OpenAPI::Linter' => {
                file    => 'lib/OpenAPI/Linter.pm',
                version => '0.14'
            },
            'OpenAPI::Linter::Location' => {
                file    => 'lib/OpenAPI/Linter/Location.pm',
                version => '0.14'
            },
        },
        resources => {
            repository => {
                type => 'git',
                url  => 'https://github.com/manwar/OpenAPI-Linter.git',
                web  => 'https://github.com/manwar/OpenAPI-Linter',
            },
        }})
     : ()
    )
);
