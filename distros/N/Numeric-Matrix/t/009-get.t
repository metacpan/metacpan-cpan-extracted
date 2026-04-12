#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 4;
use Numeric::Matrix;

my $m = Numeric::Matrix::from_array([1, 2, 3, 4, 5, 6], 2, 3);
is($m->get(0, 0), 1, 'get(0,0)');
is($m->get(0, 2), 3, 'get(0,2)');
is($m->get(1, 0), 4, 'get(1,0)');
is($m->get(1, 2), 6, 'get(1,2)');
