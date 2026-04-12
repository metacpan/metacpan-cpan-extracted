#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 3;
use Numeric::Matrix;

my $a = Numeric::Matrix::from_array([10, 20, 30, 40], 2, 2);
my $b = Numeric::Matrix::from_array([2, 4, 5, 8], 2, 2);
my $c = $a->div($b);

ok(ref($c) eq 'Numeric::Matrix', 'isa Numeric::Matrix');
is($c->get(0, 0), 5, 'div [0,0]');
is($c->get(1, 1), 5, 'div [1,1]');
