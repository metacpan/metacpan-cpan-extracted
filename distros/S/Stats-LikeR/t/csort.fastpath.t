#!/usr/bin/env perl
# Regression tests for csort()'s numeric-column fast path (cs_numeric_sort()),
# the HoA/AoH -> AoA column-name ordering (cs_sort_names()) and the key-union
# passes (cs_saw_he()).
#
# Provenance: the NaN/undef-last case is R 4.6.1's order(c(3, NA, NaN, 1, NaN,
# NA)), which is 4 1 2 3 5 6 (1-based), as quoted in the comment above
# cs_col_cmp() in LikeR.xs.  The other expected orders were frozen from the
# merge-sort implementation of 0.3413, which cs_numeric_sort() must reproduce
# exactly: a 3000-trial randomized sweep (ties, undef, NaN, -0.0, Inf, numeric
# strings, AoH/HoA/AoA) gave byte-identical permutations before and after.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR;

my $nan = 9**9**9 / 9**9**9;
my $inf = 9**9**9;

sub ids { return join ',', map { $_->{id} } @{ $_[0] } }
sub rows { my $i = 0; return [ map { +{ id => $i++, v => $_ } } @_ ] }

# R's order(c(3, NA, NaN, 1, NaN, NA)): non-missing ascending, then NA/NaN in original order
is(ids(Stats::LikeR::csort(rows(3, undef, $nan, 1, $nan, undef), 'v')), '3,0,1,2,4,5',
	'NaN and undef last in original order (R order())');

# -0.0 and 0 tie and keep original order; infinities at the ends; numeric strings; ties by row
is(ids(Stats::LikeR::csort(rows(3, undef, 'nan', 1, -0.0, 0, 'Inf', '-Inf', '1e0', ' 2 '), 'v')),
	'7,4,5,3,8,9,0,6,1,2', 'zeros tie, +-Inf at the ends, numeric strings, string nan last');
is(ids(Stats::LikeR::csort(rows($inf, -$inf, $inf, -$inf, 0), 'v')), '1,3,4,0,2', 'ties among infinities keep row order');

# a missing key is last, as undef is
{
	my @r = ({ id => 0, v => 2 }, { id => 1 }, { id => 2, v => 1 });
	is(ids(Stats::LikeR::csort(\@r, 'v')), '2,0,1', 'missing key sorts last');
}

# a column holding any non-number is a string column: the old comparator
is(ids(Stats::LikeR::csort(rows('b', 10, 'a', 9, undef), 'v')), '1,3,2,0,4', 'string column uses cmp: "10" before "9" before "a"');

# n beyond the insertion-sort cutoff, with many ties: equals a sort with row-index tie-break
{
	my @v = map { (($_ * 7) % 13) / 2 } 0 .. 999;
	$v[$_] = undef for (5, 500, 999);
	$v[$_] = $nan for (6, 501);
	my @want = sort { $v[$a] <=> $v[$b] || $a <=> $b } grep { defined $v[$_] && $v[$_] == $v[$_] } 0 .. 999;
	push @want, grep { !defined $v[$_] || $v[$_] != $v[$_] } 0 .. 999;
	is(ids(Stats::LikeR::csort(rows(@v), 'v')), join(',', @want), '1000 rows, heavy ties');
	my @rev = reverse 0 .. 999;
	is(ids(Stats::LikeR::csort(rows(map { int($_ / 10) } @rev), 'v')),
		join(',', sort { int($rev[$a] / 10) <=> int($rev[$b] / 10) || $a <=> $b } 0 .. 999), 'descending runs with ties');
}

# HoA and AoA share the fast path
{
	my %h = (id => [0 .. 5], v => [3, undef, $nan, 1, $nan, undef]);
	is(join(',', @{ Stats::LikeR::csort(\%h, 'v', 'hoa')->{id} }), '3,0,1,2,4,5', 'HoA');
	my @a = map { [$_, $h{v}[$_]] } 0 .. 5;
	is(join(',', map { $_->[0] } @{ Stats::LikeR::csort(\@a, 1) }), '3,0,1,2,4,5', 'AoA');
}

# positional output orders columns by name, bytewise, shorter first on a common prefix
{
	my %h = (b => [1, 2], a => [3, 4], ab => [5, 6], B => [7, 8], '' => [9, 10]);
	my $r = Stats::LikeR::csort(\%h, 'a', 'aoa');
	is(join(',', @{ $r->[0] }), '9,7,3,5,1', 'HoA -> AoA column order');
	my @aoh = ({ z => 1, a => 2, m => 3 }, { k => 4, a => 5 }, { zz => 6, Z => 7 });
	$r = Stats::LikeR::csort(\@aoh, 'a', 'aoa');
	my @cols = sort keys %{ { map { $_ => 1 } map { keys %$_ } @aoh } };
	my @want = map { my $row = $_; [ map { $row->{$_} } @cols ] } sort { ($a->{a} // 1e9) <=> ($b->{a} // 1e9) } @aoh;
	$r = Stats::LikeR::csort(\@aoh, 'a', 'aoa');
	is_deeply($r, \@want, 'AoH -> AoA: union of keys in name order');
	my $hr = Stats::LikeR::csort(\@aoh, 'a', 'hoa');
	is_deeply([ sort keys %$hr ], \@cols, 'AoH -> HoA: union of keys');
	is_deeply($hr->{a}, [2, 5, undef], 'AoH -> HoA: column a');
}

done_testing;
