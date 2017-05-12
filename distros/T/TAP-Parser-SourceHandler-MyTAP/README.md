TAP/Parser/SourceHandler/MyTAP version 3.27
===========================================

This module adds support for executing [MyTAP](https://github.com/theory/mytap)
MySQL tests under Test::Harness and C<prove>. This is useful for executing
your Perl tests and your MySQL tests together, and analysing their results.

Most likely. you'll want to use it with C<prove> to execute your Perl and
MyTAP tests:

    prove --source Perl \
          --ext .t --ext .my \
          --source MyTAP --mytap-option database=try \
                         --mytap-option user=root \
                         --mytap-option suffix=.my

Or in F<Build.PL> for your application with MyTAP tests in F<t/*.my>:

    Module::Build->new(
        module_name        => 'MyApp',
        test_file_exts     => [qw(.t .my)],
        use_tap_harness    => 1,
        tap_harness_args   => {
            sources => {
                Perl  => undef,
                MyTAP => {
                    database => 'try',
                    user     => 'root',
                    suffix   => '.my',
                },
            }
        },
        build_requires     => {
            'Module::Build'                     => '0.30',
            'TAP::Parser::SourceHandler::MyTAP' => '3.22',
        },
    )->create_build_script;

Installation
------------

To install this module, type the following:

    perl Build.PL
    ./Build
    ./Build test
    ./Build install

Dependencies
------------

TAP::Parser::SourceHandler::MyTAP requires TAP::Parser::SourceHandler.

Copyright and Licence
---------------------

Copyright (c) 2010-2016 David E. Wheeler. Some Rights Reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.
