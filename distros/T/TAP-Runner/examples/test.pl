#!/usr/bin/perl
use strict;
use warnings;

use TAP::Runner;
use TAP::Formatter::HTML;

TAP::Runner->new(
    {
        # harness_class => 'TAP::Harness::JUnit',
        # harness_formatter => TAP::Formatter::HTML->new,
        harness_args => {
            jobs  => 2,
        },
        tests => [
            {
                file    => 't/examples/test.t',
                alias   => 'Test alias',
                args    => [
                    '--option', 'option_value_1'
                ],
                options => [
                    {
                        name   => '--server',
                        values => [
                            'first.local',
                            'second.local',
                        ],
                        multiple => 0,
                        parallel => 0,
                    },
                    {
                        name   => '--browser',
                        values => [
                            'firefox',
                            'chrome',
                        ],
                        multiple => 1,
                        parallel => 1,
                    },
                ],
            },
            {
                file    => 't/examples/test.t',
                alias   => 'Test alias 2',
                args    => [
                    '--option', 'option_value_1'
                ],
            },
            {
                file    => 't/examples/test.t',
                alias   => 'Test alias 22',
                args    => [
                    '--option', 'option_value_2'
                ],
            },
        ],
    }
)->run;

