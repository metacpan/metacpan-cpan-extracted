#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 3;
use Numeric::Matrix;

my $a = Numeric::Matrix::from_array([1, 4, 9, 16], 2, 2);
my $b = $a->sqrt;

ok(ref($b) eq 'Numeric::Matrix', 'isa Numeric::Matrix');
is($b->get(0, 0), 1, 'sqrt(1)');
is($b->get(1, 1), 4, 'sqrt(16)');
