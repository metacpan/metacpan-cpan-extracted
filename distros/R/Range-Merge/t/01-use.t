#!/usr/bin/perl

#
# Copyright (C) 2016 Joelle Maslak
# All Rights Reserved - See License
#

use Range::Merge::Boilerplate 'script';

use Test2::Bundle::Extended 0.000058;

MAIN: {
    require Range::Merge;
    ok(1);
    done_testing;
}

1;


