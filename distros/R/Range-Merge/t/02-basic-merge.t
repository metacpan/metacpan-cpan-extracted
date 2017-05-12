#!/usr/bin/perl

#
# Copyright (C) 2016 Joel C. Maslak
# All Rights Reserved - See License
#

use Test2::Bundle::Extended;
use Range::Merge::Boilerplate 'script';

use Range::Merge qw(merge);

MAIN: {
    my $indata = [
        [  5,   9 ],
        [  7,   8 ],
        [  8,   8 ],
        [ 12, 100 ],
    ];

    my $result = merge($indata);
    # pretty_diag($result);

    my $expected = [
        [  5,   9 ],
        [ 12, 100 ],
    ];
    is($result, $expected, 'Basic merge successful');

    done_testing;
}

sub pretty_diag($ranges) {
    diag "Values:";
    diag join "\n", map  { "  [" . join(",", $_->@*) . "]" } $ranges->@*;
}

1;


