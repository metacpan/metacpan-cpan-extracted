#!/usr/bin/env perl

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::LeakTrace;
use Stats::LikeR;

# --- size => N : last group holds the remainder -----------------------------
{
	my @g = chunk(['a' .. 'z'], size => 5);
	is(scalar @g, 6, 'size=>5 over 26 -> 6 groups');
	is_deeply([ map { scalar @$_ } @g ], [5, 5, 5, 5, 5, 1], 'size=>5 group sizes');
	is_deeply($g[0],  [qw/a b c d e/], 'first group');
	is_deeply($g[-1], ['z'],           'last group is the remainder');
}

# --- parts => K : remainder spread across the leading groups ----------------
{
	my @g = chunk(['a' .. 'z'], parts => 5);
	is(scalar @g, 5, 'parts=>5 -> 5 groups');
	is_deeply([ map { scalar @$_ } @g ], [5, 5, 5, 5, 6], 'parts=>5 group sizes');
	is_deeply($g[-1], [qw/u v w x y z/], 'last group holds the extra');
}

# --- size and parts agree when the split is even ----------------------------
{
	my @s = chunk([1 .. 10], size  => 2);
	my @p = chunk([1 .. 10], parts => 5);
	is(scalar @s, 5, 'size=>2 -> 5 groups');
	is_deeply(\@s, \@p, 'size=>2 and parts=>5 match when even');
}

# --- input order is preserved (chunk never sorts) ---------------------------
{
	my @g = chunk([3, 1, 2], size => 2);
	is_deeply(\@g, [[3, 1], [2]], 'input order preserved');
}

# --- more parts than elements: numpy.array_split parity ---------------------
{
	my @g = chunk([1, 2, 3], parts => 5);
	is(scalar @g, 5, 'parts > n still returns K groups');
	is_deeply([ map { @$_ } @g ], [1, 2, 3], 'no elements lost across empty groups');
}

# --- empty input -> empty list ----------------------------------------------
{
	my @g = chunk([], parts => 3);
	is(scalar @g, 0, 'empty input -> empty list');
}

# --- argument errors --------------------------------------------------------
{
	ok(!eval { chunk('x', size => 2); 1 },                'non-arrayref dies');
	ok(!eval { chunk([1, 2], size => 2, parts => 2); 1 }, 'size and parts together dies');
	ok(!eval { chunk([1, 2]); 1 },                        'neither size nor parts dies');
	ok(!eval { chunk([1, 2], size => 0); 1 },             'size 0 dies');
	ok(!eval { chunk([1, 2], parts => -1); 1 },           'negative parts dies');
}

# --- leak checks (assignments hoisted out for Devel::Cover) ------------------
unless ($INC{'Devel/Cover.pm'}) {
	my @data = 1 .. 500;
	no_leaks_ok { eval { my @g = chunk(\@data, size  => 7) } }  'chunk: no leaks (size)';
	no_leaks_ok { eval { my @g = chunk(\@data, parts => 13) } } 'chunk: no leaks (parts)';
	no_leaks_ok { eval { my @g = chunk(\@data, parts => 999) } } 'chunk: no leaks (parts > n)';
	no_leaks_ok { eval { my @g = chunk('x', size => 2) } }     'chunk: no leaks (error path)';
}

done_testing();
