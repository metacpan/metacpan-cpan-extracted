#!/usr/bin/perl

#
# Copyright (C) 2018 Joelle Maslak
# All Rights Reserved - See License
#

use strict;
use warnings;

use Test2::V0 0.000111;
use Net::Netmask;

my (@tests) = (
    {
        input  => '::',
        output => '::',
    },
    {
        input  => ':0::',
        output => '::',
    },
    {
        input  => '::0:',
        output => '::',
    },
    {
        input  => '0:0:0:0:0:0:0:0',
        output => '::',
    },
    {
        input  => '1:2:3:4:5:6:7:8',
        output => '1:2:3:4:5:6:7:8',
    },
    {
        input  => '01:02:03:04:05:06:07:08',
        output => '1:2:3:4:5:6:7:8',
    },
    {
        input  => '1:2:3:0:0:6:7:8',
        output => '1:2:3::6:7:8',
    },
    {
        input  => '0:0:3:4:5:6:7:8',
        output => '::3:4:5:6:7:8',
    },
    {
        input  => '1:2:3:4:5:6:0:0',
        output => '1:2:3:4:5:6::',
    },
    {
        input  => '0:0:3:4:5:6:0:0',
        output => '::3:4:5:6:0:0',
    },
    {
        input  => '0:0:3:4:5:0:0:0',
        output => '0:0:3:4:5::',
    },
    {
        input  => '1:0:0:0:5:0:0:0',
        output => '1::5:0:0:0',
    },
    {
        input  => '1:0:0:0:5F:0:0:0',
        output => '1::5f:0:0:0',
    },
    {
        input  => '1:0:0:0:5F:0:1.2.3.4',
        output => '1::5f:0:102:304',
    },
    {
        input  => '1:0:0:0:5F:0:1.2.255.4',
        output => '1::5f:0:102:ff04',
    },
    {
        input  => '1:0:0:0:5F:0:0:0',
        output => '1::5f:0:0:0',
    },
    {
        input  => '1:0:0:0:5F:0:0:0',
        output => '1::5f:0:0:0',
    },
);

foreach my $test (@tests) {
    my $got = Net::Netmask::ipv6Cannonical($test->{input});

    is($got, $test->{output}, $test->{input} . ' -> ' . $test->{output});
}

done_testing;

1;


