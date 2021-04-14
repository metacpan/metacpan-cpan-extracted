#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Deep;

use TOML::XS;

my $doc = <<END;
# This is a TOML document

[owner]
dob = 1979-05-27T07:32:00.123-08:00
END

my $struct = TOML::XS::from_toml($doc)->to_struct();

my $the_timestamp_cmp = all(
    Isa('TOML::XS::Timestamp'),
    methods(
        to_string => '1979-05-27T07:32:00.123-08:00',
        year => 1979,
        month => 5,
        day => 27,
        date => 27,
        hour => 7,
        hours => 7,
        minute => 32,
        second => 0,
        millisecond => 123,
        milliseconds => 123,
        timezone => '-08:00',
    ),
);

cmp_deeply(
    $struct,
    {
        'owner' => {
            'dob'  => $the_timestamp_cmp,
        },
    },
    'struct as expected',
) or diag explain $struct;

done_testing;
