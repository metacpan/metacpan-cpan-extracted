#!/usr/bin/perl

#
# Copyright (C) 2019 Joelle Maslak
# All Rights Reserved - See License
#

use Test2::Bundle::Extended;
use Range::Merge::Boilerplate 'script';

use Range::Merge qw(merge_discrete);

my (@tests) = (
    {
        input => [ ],
        output => [ ],
        name => 'empty',
    },
    {
        input => [ 1 ],
        output => [ [1, 1] ],
        name => 'singleton',
    },
    {
        input => [ 1, 3, 2, 1 ],
        output => [ [1, 3] ],
        name => 'overlap',
    },
    {
        input => [ 1, 3, -2, -11 ],
        output => [ [-11, -11], [-2, -2], [1, 1], [3, 3] ],
        name => 'unmergable',
    },
);

foreach my $test (@tests) {
    my $result = merge_discrete($test->{input});
    is($result, $test->{output}, $test->{name});
}

done_testing;

1;

