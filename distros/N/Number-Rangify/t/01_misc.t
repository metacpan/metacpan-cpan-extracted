#!/usr/bin/env perl
use warnings;
use strict;
use Number::Rangify 'rangify';
use Test::More tests => 32;

sub ranges_ok {
    my ($got, $name, @expected_ranges) = @_;
    is(scalar(@$got), scalar(@expected_ranges), "$name: same number of ranges");
    for my $got_range (@$got) {
        isa_ok($got_range, 'Set::IntRange');
        my ($lower, $upper) = $got_range->Size;
        my $expected_range = shift @expected_ranges;
        is($lower, $expected_range->[0], "$name: lower bound $lower");
        is($upper, $expected_range->[1], "$name: upper bound $upper");
    }
}

# some elements occur twice...
my @list = (1, 2, 3, 5, 7, 9, 10, 11, 15, 9, 10, 11, 2);
my @ranges = rangify(@list);
ranges_ok(
    \@ranges, 'list context',
    [ 1,  3 ],
    [ 5,  5 ],
    [ 7,  7 ],
    [ 9,  11 ],
    [ 15, 15 ]
);
my $ranges = rangify(@list);
ranges_ok(
    $ranges,
    'scalar context',
    [ 1,  3 ],
    [ 5,  5 ],
    [ 7,  7 ],
    [ 9,  11 ],
    [ 15, 15 ]
);
