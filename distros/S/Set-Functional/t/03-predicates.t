#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 106;
use Set::Functional qw{:all};

sub choice { $_[0] }

my @test_conditions = (
	[ [], [], 'both left and right are the empty set' ],
	[ [], [1 .. 5], 'only left is the empty set' ],
	[ [1 .. 5], [], 'only right is the empty set' ],
	[ [1 .. 5], [1 .. 3], 'left contains right' ],
	[ [1 .. 3], [1 .. 5], 'right contains left' ],
	[ [1 .. 5], [1 .. 5], 'left is the same as right' ],
	[ [1 .. 7], [4 .. 10], 'left overlaps with right' ],
	[ [1 .. 5], [6 .. 10], 'left does not overlap with right' ],
);

my @tests = (
	['is_disjoint',        \&is_disjoint,        qw{1 1 1 0 0 0 0 1}],
	['is_equal',           \&is_equal,           qw{1 0 0 0 0 1 0 0}],
	['is_proper_subset',   \&is_proper_subset,   qw{0 1 0 0 1 0 0 0}],
	['is_proper_superset', \&is_proper_superset, qw{0 0 1 1 0 0 0 0}],
	['is_subset',          \&is_subset,          qw{1 1 0 0 1 1 0 0}],
	['is_superset',        \&is_superset,        qw{1 0 1 1 0 1 0 0}],

	['is_disjoint_by',        sub { &is_disjoint_by(\&choice, @_) },        qw{1 1 1 0 0 0 0 1}],
	['is_equal_by',           sub { &is_equal_by(\&choice, @_) },           qw{1 0 0 0 0 1 0 0}],
	['is_proper_subset_by',   sub { &is_proper_subset_by(\&choice, @_) },   qw{0 1 0 0 1 0 0 0}],
	['is_proper_superset_by', sub { &is_proper_superset_by(\&choice, @_) }, qw{0 0 1 1 0 0 0 0}],
	['is_subset_by',          sub { &is_subset_by(\&choice, @_) },          qw{1 1 0 0 1 1 0 0}],
	['is_superset_by',        sub { &is_superset_by(\&choice, @_) },        qw{1 0 1 1 0 1 0 0}],
);

for (@tests) {
	my ($name, $predicate, @results) = @$_;
	die "Predicate [$name] did not enumerate results for all test conditions" if @results != @test_conditions;
	for my $idx (0 .. $#test_conditions) {
		my $result = $results[$idx];
		my ($left, $right, $label) = @{$test_conditions[$idx]};

		if ($result) {
			ok $predicate->($left, $right), "$name is true when $label";
		} else {
			ok ! $predicate->($left, $right), "$name is false when $label";
		}
	}
}

ok is_pairwise_disjoint([], [], []), 'is_pairwise_disjoint is true when all sets are the empty set';
ok is_pairwise_disjoint([1 .. 5], [6 .. 10], []), 'is_pairwise_disjoint is true when the only overlap is the empty set';
ok ! is_pairwise_disjoint([1 .. 5], [6 .. 10], [8 .. 12]), 'is_pairwise_disjoint is false when any 2 sets overlap';
ok ! is_pairwise_disjoint([1, 2], [2, 3], [1, 3]), 'is_pairwise_disjoint is false when every set overlaps';
ok is_pairwise_disjoint([1 .. 5], [6 .. 10], [11 .. 15]), 'is_pairwise_disjoint is true when no sets overlap';

ok is_pairwise_disjoint_by(\&choice, [], [], []), 'is_pairwise_disjoint_by is true when all sets are the empty set';
ok is_pairwise_disjoint_by(\&choice, [1 .. 5], [6 .. 10], []), 'is_pairwise_disjoint_by is true when the only overlap is the empty set';
ok ! is_pairwise_disjoint_by(\&choice, [1 .. 5], [6 .. 10], [8 .. 12]), 'is_pairwise_disjoint_by is false when any 2 sets overlap';
ok ! is_pairwise_disjoint_by(\&choice, [1, 2], [2, 3], [1, 3]), 'is_pairwise_disjoint_by is false when every set overlaps';
ok is_pairwise_disjoint_by(\&choice, [1 .. 5], [6 .. 10], [11 .. 15]), 'is_pairwise_disjoint_by is true when no sets overlap';
