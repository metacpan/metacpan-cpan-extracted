#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::FailWarnings;

use_ok('Protocol::DBus::Address');

my @tests = (
    [
        'unix:path=/tmp/dbus-test;unix:path=/tmp/dbus-test2',
        [
            all(
                Isa('Protocol::DBus::Address'),
                methods(
                    transport => 'unix',
                    [ attribute => 'path' ] => '/tmp/dbus-test',
                    to_string => 'unix:path=/tmp/dbus-test',
                ),
            ),
            all(
                Isa('Protocol::DBus::Address'),
                methods(
                    transport => 'unix',
                    [ attribute => 'path' ] => '/tmp/dbus-test2',
                    to_string => 'unix:path=/tmp/dbus-test2',
                ),
            ),
        ],
    ],
    [
        'unix:path=/tmp/dbus-XNYkn7CovF,guid=fff528e7416a38184c876a3a5c076340',
        [
            all(
                Isa('Protocol::DBus::Address'),
                methods(
                    transport => 'unix',
                    [ attribute => 'path' ] => '/tmp/dbus-XNYkn7CovF',
                    [ attribute => 'guid' ] => 'fff528e7416a38184c876a3a5c076340',
                    to_string => 'unix:path=/tmp/dbus-XNYkn7CovF,guid=fff528e7416a38184c876a3a5c076340',
                ),
            ),
        ],
    ],
);

for my $t (@tests) {
    my @out = Protocol::DBus::Address::parse( $t->[0] );

    cmp_deeply(
        \@out,
        $t->[1],
        $t->[0],
    ) or diag explain \@out;
}

done_testing();
