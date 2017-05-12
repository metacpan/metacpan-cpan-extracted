#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 13;
use lib 'lib';
use Set::CartesianProduct::Lazy;

#empty set
#let A = @alpha, B = @empty
#A x B = empty set, B x A = empty set
#cardinality of the cartesian product = 0
my @empty = ();
my @alpha = ("A" .. "Z");
my $combo = Set::CartesianProduct::Lazy->new(\@alpha, \@empty);
my $size = $combo->count;
is($size, 0, "testing cardinality of A x B where B is the empty set");
$combo = Set::CartesianProduct::Lazy->new(\@empty, \@alpha);
$size = $combo->count;
is($size, 0, "testing cardinality of B x A where B is the empty set");


#product of 2 sets that are not the empty set
my @nums = qw(1 2 3 4 5);
$combo = Set::CartesianProduct::Lazy->new(\@alpha, \@nums);
$size = $combo->count;
is($size, ($#alpha + 1)*($#nums + 1), "testing cardinality with non empty sets");
is($combo->last_idx, $combo->count - 1, "does last_idx = count - 1?");

my @tuple = $combo->get(-1);
my @expected = $combo->get($#nums);
is_deeply(\@tuple, \@expected, "testing weirdness of index = -1");
@tuple = $combo->get($size);
@expected = $combo->get(0);
is_deeply(\@tuple, \@expected, "what if index = number of elements in the product");
@tuple = $combo->get($size * -1);
is_deeply(\@tuple, \@expected, "index = -size_of_product");
@tuple = $combo->get(1024);
@expected = $combo->get(1024 % $size);
is_deeply(\@tuple, \@expected, "figuring out the modulo for the index");


#Cartesian product of 3 sets
my @symbols = qw(+ ? ~);
$combo = Set::CartesianProduct::Lazy->new(\@alpha, \@nums, \@symbols);
$size = $combo->count;
is($size, ($#alpha + 1)*($#nums + 1)*($#symbols + 1), "testing cardinality with non empty sets");
is($combo->last_idx, $combo->count - 1, "does last_idx = count - 1?");

@tuple = $combo->get(-1);
@expected = $combo->get($#symbols);
is_deeply(\@tuple, \@expected, "case of index = -1 in Cartesian product A x B x C");
#the pattern I noticed that get(-1) = get(last index of your last argument in Set::CartesianProduct::Lazy->new())


#playing with the option of less_lazy
my @c = qw(foo bar);
$combo = Set::CartesianProduct::Lazy->new( { less_lazy => 1 }, \@alpha, \@nums, \@c);
$size = $combo->count;
is($size, ($#alpha + 1)*($#nums + 1)*($#c + 1), "testing cardinality with non empty sets");
@tuple = $combo->get($combo->last_idx);
@expected = $combo->get((26 * 5 * 2) - 1);
is_deeply(\@tuple, \@expected, "testing if it is the last index");
