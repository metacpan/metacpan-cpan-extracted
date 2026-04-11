#!/usr/bin/perl
use strict;
use warnings;
use Test2::Bundle::Numerical qw(:all);
use Numeric::Vector;

# Test add_scalar_inplace
my $v = Numeric::Vector::new([1, 2, 3, 4, 5]);
$v->add_scalar_inplace(10);
is($v->get(0), 11, 'add_scalar_inplace: 1 + 10 = 11');
is($v->get(1), 12, 'add_scalar_inplace: 2 + 10 = 12');
is($v->get(2), 13, 'add_scalar_inplace: 3 + 10 = 13');
is($v->get(3), 14, 'add_scalar_inplace: 4 + 10 = 14');
is($v->get(4), 15, 'add_scalar_inplace: 5 + 10 = 15');

# Test with negative scalar
my $v2 = Numeric::Vector::new([10, 20, 30]);
$v2->add_scalar_inplace(-5);
is($v2->get(0), 5, 'add_scalar_inplace: 10 + (-5) = 5');
is($v2->get(1), 15, 'add_scalar_inplace: 20 + (-5) = 15');
is($v2->get(2), 25, 'add_scalar_inplace: 30 + (-5) = 25');

# Test with zero
my $v3 = Numeric::Vector::new([1, 2, 3]);
$v3->add_scalar_inplace(0);
is($v3->get(0), 1, 'add_scalar_inplace: 1 + 0 = 1');
is($v3->get(1), 2, 'add_scalar_inplace: 2 + 0 = 2');
is($v3->get(2), 3, 'add_scalar_inplace: 3 + 0 = 3');

done_testing();
