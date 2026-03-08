#!/usr/bin/env perl

use strict;
use warnings;
use ExtUtils::MakeMaker;
use File::ShareDir::Install;

install_share dist => 'share';

WriteMakefile(
    NAME          => 'OpenAPI::Linter',
    AUTHOR        => 'Mohammad Sajid Anwar <mohammad.anwar@yahoo.com>',
    VERSION_FROM  => 'lib/OpenAPI/Linter.pm',
    ABSTRACT_FROM => 'lib/OpenAPI/Linter.pm',
    LICENSE       => 'artistic_2',
    EXE_FILES     => ['script/openapi-linter'],
    PREREQ_PM     => {
        'JSON::Validator' => 0,
        'YAML::XS'        => 0,
        'JSON'            => 0,
        'File::Slurp'     => 0,
        'IO::Socket::SSL' => 2.009,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    test  => { TESTS    => 't/*.t' },
    clean => { FILES    => 'OpenAPI-Linter-*' },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (META_MERGE => {
        'meta-spec' => { version => 2 },
        provides    => {
            'OpenAPI::Linter' => {
                file    => 'lib/OpenAPI/Linter.pm',
                version => MM->parse_version('lib/OpenAPI/Linter.pm')
            },
            'OpenAPI::Linter::Location' => {
                file    => 'lib/OpenAPI/Linter/Location.pm',
                version => MM->parse_version('lib/OpenAPI/Linter/Location.pm')
            },
        },
        resources => {
            repository => {
                type   => 'git',
                url    => 'https://github.com/manwar/OpenAPI-Linter.git',
                web    => 'https://github.com/manwar/OpenAPI-Linter',
            },
            bugtracker => {
                web    => 'https://github.com/manwar/OpenAPI-Linter/issues'
            },
        }})
     : ()
    )
);

package MY;
use File::ShareDir::Install 'postamble';
