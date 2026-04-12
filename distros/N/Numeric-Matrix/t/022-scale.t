#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 3;
use Numeric::Matrix;

my $a = Numeric::Matrix::from_array([1, 2, 3, 4], 2, 2);
my $b = $a->scale(3);

ok(ref($b) eq 'Numeric::Matrix', 'isa Numeric::Matrix');
is($b->get(0, 0), 3, 'scale [0,0]');
is($a->get(0, 0), 1, 'original unchanged');
