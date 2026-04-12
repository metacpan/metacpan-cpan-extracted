#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 3;
use Numeric::Matrix;

my $m = Numeric::Matrix::from_array([1, 2, 3, 4, 5, 6], 2, 3);
my $v = $m->to_vector;

is(ref($v), 'ARRAY', 'returns arrayref');
is(scalar(@$v), 6, 'correct length');
is_deeply($v, [1, 2, 3, 4, 5, 6], 'values match row-major order');
