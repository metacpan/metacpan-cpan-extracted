TAP/Parser/SourceHandler/pgTAP version 3.36
===========================================

[![CPAN version](https://badge.fury.io/pl/TAP-Parser-SourceHandler-pgTAP.svg)](https://badge.fury.io/pl/TAP-Parser-SourceHandler-pgTAP)
[![Docker release](https://images.microbadger.com/badges/version/itheory/pg_prove.svg)](https://hub.docker.com/r/itheory/pg_prove/)
[![Test & Release Status](https://github.com/theory/tap-parser-sourcehandler-pgtap/workflows/CI/CD/badge.svg)](https://github.com/theory/tap-parser-sourcehandler-pgtap/actions)

This module adds support for executing [pgTAP](https://pgtap.org/) PostgreSQL
tests under Test::Harness and `prove. This is useful for executing your Perl
tests and your PostgreSQL tests together, and analyzing their results.

Most likely. you'll want to use it with `prove` to execute your Perl and
pgTAP tests:

    prove --source Perl \
          --ext .t --ext .pg \
          --source pgTAP --pgtap-option dbname=try \
                         --pgtap-option username=postgres \
                         --pgtap-option suffix=.pg

Or in `Build.PL` for your application with pgTAP tests in `t/*.pg`:

    Module::Build->new(
        module_name        => 'MyApp',
        test_file_exts     => [qw(.t .pg)],
        use_tap_harness    => 1,
        tap_harness_args   => {
            sources => {
                Perl  => undef,
                pgTAP => {
                    dbname   => 'try',
                    username => 'root',
                    suffix   => '.pg',
                },
            }
        },
        build_requires     => {
            'Module::Build'                     => '0.30',
            'TAP::Parser::SourceHandler::pgTAP' => '3.18',
        },
    )->create_build_script;

Installation
------------

To install this module, type the following:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

To run it from a [Docker image](https://hub.docker.com/r/itheory/pg_prove/):

    docker pull itheory/pg_prove
    curl -L https://git.io/JUdgg -o pg_prove && chmod +x pg_prove
    ./pg_prove --help

Dependencies
------------

TAP::Parser::SourceHandler::pgTAP requires TAP::Parser::SourceHandler.

Copyright and Licence
---------------------

Copyright (c) 2018-2022 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
