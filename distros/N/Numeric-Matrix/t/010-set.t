#!/usr/bin/env perl
use strict;
use warnings;
use Test2::Bundle::Numerical;
plan tests => 3;
use Numeric::Matrix;

my $m = Numeric::Matrix::zeros(2, 2);
$m->set(0, 0, 5);
$m->set(1, 1, 10);

is($m->get(0, 0), 5, 'set(0,0)');
is($m->get(1, 1), 10, 'set(1,1)');
is($m->get(0, 1), 0, 'unchanged element');
