#!/usr/bin/perl

#
# Copyright (C) 2018 Joelle Maslak
# All Rights Reserved - See License
#

use strict;
use warnings;

use Test2::V0 0.000111;

use Math::BigInt;
use Net::Netmask;

my (@tests) = (
    {
        input  => '0',
        output => '::',
    },
    {
        input  => '00010002000300040005000600070008',
        output => '1:2:3:4:5:6:7:8',
    },
    {
        input  => '00010002000300000000000600070008',
        output => '1:2:3::6:7:8',
    },
    {
        input  => '00000000000300040005000600070008',
        output => '::3:4:5:6:7:8',
    },
    {
        input  => '00010002000300040005000600000000',
        output => '1:2:3:4:5:6::',
    },
    {
        input  => '00000000000300040005000600000000',
        output => '::3:4:5:6:0:0',
    },
    {
        input  => '00000000000300040005000000000000',
        output => '0:0:3:4:5::',
    },
    {
        input  => '00010000000000000005000000000000',
        output => '1::5:0:0:0',
    },
    {
        output => '1::5f:0:0:0',
        input  => '0001000000000000005f000000000000',
    },
);

foreach my $test (@tests) {
    my $in = Math::BigInt->from_hex($test->{input});

    my $got = Net::Netmask::int2ascii( "$in", 'IPv6' );
    is( $got, $test->{output}, $test->{output} );

    $got = Net::Netmask::int2ascii( $in, 'IPv6' );
    is( $got, $test->{output}, "MBI Input " . $test->{output} );

    my $reverse = Net::Netmask::ascii2int( $test->{output}, 'IPv6' );
    is( $reverse, "$in", 'ascii2int for ' . $test->{output} );
}

done_testing;

1;

