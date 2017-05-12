#!/usr/bin/perl

use strict;
use warnings;
use Test::Exception;
use Test::More tests => 28;

use Scalar::Compare qw(scalar_compare);

my @tests = (
    [ 1,   '==', 2,   '' ],
    [ 1,   '==', 1,   1 ],
    [ 0,   '==', 0,   1 ],
    [ 0,   '==', 9,   '' ],
    [ 1,   'eq', '1', 1 ],
    [ 'z', 'eq', 'z', 1 ],
    [ 'z', 'eq', 'q', '' ],
    [ 4,   '!=', 7,   1 ],
    [ 7,   '!=', 7,   '' ],
    [ 'z', 'ne', 'p', 1 ],
    [ 'p', 'ne', 'p', '' ],
    [ 7,   '<',  4,   '' ],
    [ 9,   '<',  9,   '' ],
    [ 4,   '<',  9,   1 ],
    [ 4,   '<=', 4,   1 ],
    [ 4,   '<=', 5,   1 ],
    [ 4,   '<=', 2,   '' ],
    [ 7,   '>',  4,   1 ],
    [ 4,   '>',  7,   '' ],
    [ 4,   '>',  4,   '' ],
    [ 4,   '>=', 4,   1 ],
    [ 4,   '>=', 8,   '' ],
    [ 4,   '>=', 2,   1 ],
    [ 'abracadabra', '=~', 'bracada',  1 ],
    [ 'abracadabra', '!~', 'broccoli', 1 ],
    [ 'abracadabra', '=~', 'broccoli', '' ],
    [ 'abracadabra', '!~', 'bracada', '' ],
    [ 'abracadabra', '=~', '^abracadabra$', 1 ],
);

for my $test (@tests) {
    my ($our, $cmp, $target, $result) = @$test;
    is( scalar_compare( $our, $cmp, $target ), $result, "$our $cmp $target" );
}


