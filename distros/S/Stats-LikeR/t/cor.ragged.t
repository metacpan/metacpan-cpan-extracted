#!/usr/bin/env perl
# cor() on a matrix with rows of unequal length croaks.
#
# PROVENANCE
#
# R has no ragged matrix (a matrix is rectangular by construction), so there
# is no R case; the rule is the one prcomp() and scale() already apply to an
# array of arrays ("rows have unequal lengths", pinned by t/prcomp*.t). Up to
# 0.3419 cor([[1,2,3],[2,3],[3,5,1]]) took the width from row 0, read the
# short row's missing cell as NaN and ignored a long row's extra cells, so it
# returned NaN cells instead of an error. Cases are invented around that rule.
# cov() has no matrix form, so nothing to do there.
require 5.010; use strict; use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR ();
my $HAVE_LEAKTRACE;
BEGIN {
	if (eval { require Test::LeakTrace; 1 }) { Test::LeakTrace->import("no_leaks_ok"); $HAVE_LEAKTRACE = 1 }
	else { *no_leaks_ok = sub (&;$) { SKIP: { skip "Test::LeakTrace not installed", 1 } }; $HAVE_LEAKTRACE = 0 }
}

my @bad = (
	['short x row', sub { Stats::LikeR::cor([[1, 2, 3], [2, 3], [3, 5, 1]]) }, qr/cor: x rows have unequal lengths \(row 1 has 2, expected 3\)/],
	['long x row', sub { Stats::LikeR::cor([[1, 2], [2, 3], [3, 5, 1]]) }, qr/cor: x rows have unequal lengths \(row 2 has 3, expected 2\)/],
	['empty x row', sub { Stats::LikeR::cor([[1, 2], [], [3, 5]]) }, qr/cor: x rows have unequal lengths \(row 1 has 0, expected 2\)/],
	['short y row', sub { Stats::LikeR::cor([[1, 2], [2, 3], [3, 5]], [[1], [3], []]) }, qr/cor: y rows have unequal lengths \(row 2 has 0, expected 1\)/],
	['long y row', sub { Stats::LikeR::cor([[1, 2], [2, 3], [3, 5]], [[1], [3, 4], [2]]) }, qr/cor: y rows have unequal lengths \(row 1 has 2, expected 1\)/],
);
for my $c (@bad) {
	my ($name, $code, $re) = @$c;
	eval { $code->() };
	like($@, $re, $name);
	no_leaks_ok { eval { $code->() } } "$name: refusal does not leak";
}
# rectangular input is unaffected, including a y with a different width
my $r = Stats::LikeR::cor([[1, 2], [2, 3], [3, 5], [4, 4]], [[1], [3], [2], [5]]);
is(scalar(@$r), 2, 'cross matrix has x-width rows');
is(scalar(@{$r->[0]}), 1, 'cross matrix has y-width columns');
done_testing;
