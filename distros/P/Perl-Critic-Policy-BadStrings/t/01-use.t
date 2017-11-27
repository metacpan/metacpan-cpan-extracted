#!/usr/bin/perl

#
# Copyright (C) 2017 Joelle Maslak
# All Rights Reserved - See License
#

use File::FindStrings::Boilerplate 'script';

use Test2::Bundle::Extended 0.000058;

MAIN: {
    require File::FindStrings;
    ok(1);
    done_testing;
}

1;


