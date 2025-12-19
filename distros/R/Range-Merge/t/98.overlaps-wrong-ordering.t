#!/usr/bin/perl

#
# Copyright (C) 2025 Joelle Maslak
# All Rights Reserved - See License
#

use Test2::Bundle::Extended;
use Range::Merge::Boilerplate 'script';

use Range::Merge qw(merge);

MAIN: {
    my $indata = [
        [  5,   9, 1 ],
        [  5,   6, 2 ],
        [  7,   8, 3 ],
        [  8,   8, 4 ],
        [ 12, 100, 5 ],
    ];

    my $result = merge($indata);

    my $expected = [
        [  5,   6, 2 ],
        [  7,   7, 3 ],
        [  8,   8, 4 ],
        [  9,   9, 1 ],
        [ 12, 100, 5 ],
    ];
    is($result, $expected, 'Basic merge successful');

    done_testing;
}

1;


