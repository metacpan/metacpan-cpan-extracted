#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 3;
use Numeric::Matrix;

my $m = Numeric::Matrix::from_array([1, 2, 3, 4, 5, 6], 2, 3);
$m->set_row(0, [10, 20, 30]);

is($m->get(0, 0), 10, 'first element');
is($m->get(0, 1), 20, 'second element');
is($m->get(0, 2), 30, 'third element');
