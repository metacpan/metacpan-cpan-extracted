#!/usr/bin/perl
use strict;
use warnings;
use Test2::Bundle::Numerical qw(:all);
use Numeric::Vector;

# Test clip function
my $v = Numeric::Vector::new([-5, -1, 0, 1, 5, 10, 15]);
my $clipped = $v->clip(0, 10);
is($clipped->get(0), 0, 'clip: -5 clamped to 0');
is($clipped->get(1), 0, 'clip: -1 clamped to 0');
is($clipped->get(2), 0, 'clip: 0 stays 0');
is($clipped->get(3), 1, 'clip: 1 stays 1');
is($clipped->get(4), 5, 'clip: 5 stays 5');
is($clipped->get(5), 10, 'clip: 10 stays 10');
is($clipped->get(6), 10, 'clip: 15 clamped to 10');

# Test clip with negative range
my $v2 = Numeric::Vector::new([-10, -5, 0, 5, 10]);
my $clipped2 = $v2->clip(-3, 3);
is($clipped2->get(0), -3, 'clip: -10 clamped to -3');
is($clipped2->get(1), -3, 'clip: -5 clamped to -3');
is($clipped2->get(2), 0, 'clip: 0 stays 0');
is($clipped2->get(3), 3, 'clip: 5 clamped to 3');
is($clipped2->get(4), 3, 'clip: 10 clamped to 3');

done_testing();
