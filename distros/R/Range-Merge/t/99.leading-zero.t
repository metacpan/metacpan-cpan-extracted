#!/usr/bin/perl

#
# Copyright (C) 2016-2021 Joelle Maslak
# All Rights Reserved - See License
#

use Test2::Bundle::Extended;
use Range::Merge::Boilerplate 'script';

use Range::Merge qw(merge_ipv4);

MAIN: {
    like(
        dies { merge_ipv4( [ [ '10.0.0.0/16' ], [ '10.01.0.0/16' ] ] ) },
        qr/^Invalid IP address:/,
        "Exception thrown for leading zeros",
    );
    done_testing();
}

1;


