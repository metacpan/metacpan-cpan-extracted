#!/usr/bin/env perl
# drop_cols, select_cols, rename_cols, csort, ljoin, rownames and the set
# functions intersection, get_union, Lonly, Ronly, is_equivalent, against the
# test suites and documented examples of pandas, R and NumPy.
#
# Provenance (the values are frozen; t/frame_ops_sets.R.pandas.py and
# t/frame_ops_sets.R.pandas.R, committed beside this file, printed them.
# Re-run with
#     python3 -I t/frame_ops_sets.R.pandas.py
#     Rscript t/frame_ops_sets.R.pandas.R
# This test never runs R or Python.):
#   pandas 3.0.4, pandas/tests/frame/methods/test_sort_values.py:
#         test_sort_values, test_sort_values_nan (GH#3917),
#         test_sort_values_stable_descending_sort (GH#6399),
#         test_sort_values_stable_multicolumn_sort (GH#38426).
#   pandas 3.0.4, pandas/tests/frame/methods/test_drop.py: test_drop_names,
#         test_drop (incl. GH 16398 empty list, errors="ignore").
#   pandas 3.0.4, pandas/tests/frame/methods/test_rename.py: test_rename,
#         test_rename_bug (GH 5344), test_rename_errors_raises.
#   pandas 3.0.4, pandas/tests/reshape/merge/test_merge.py: how="left" with
#         left_index/right_index (test_merge_arrow_string_index and
#         test_categorical_non_unique_monotonic, re-keyed on unique string
#         row labels so they have a HoH shape).
#   NumPy 2.4.6, numpy/lib/tests/test_arraysetops.py: test_intersect1d,
#         test_union1d, test_setdiff1d (same inputs; NumPy returns sorted
#         arrays, so those are compared as sets).
#   R 4.6.1, src/library/base/man/sets.Rd \examples (fixed vectors in place of
#         the sample() draws, no NA), the factor example, and
#         tests/reg-tests-1e.R "union() needed adaptation"; order() on ties,
#         decreasing, NA/NaN, character keys.  R 4.6.2 printed the values.
#
# Map of shapes: pandas DataFrame from a list of dicts is an AoH, dict of lists
# a HoA, dict of dicts (orient="index") a HoH, list of lists an AoA.  A frame
# is given an `id` column holding each row's 0-based input position so a sort
# is checked by the order of ids (pandas' index).  NaN in pandas is undef here.
#
# Tolerances: none; every value is an exactly representable integer or a string.
#
# Deliberate differences, kept so that changing one is a decision:
#   - csort has no na_position: undef/missing always sorts last, so pandas'
#     na_position="first" cases are checked as "NaN rows last, rest in
#     pandas' order".  pandas sorts descending with NaN last too, as csort.
#   - csort has no multi-column `by`; a multi-key sort is a comparator
#     (README, csort).  A comparator that reads a key which is undef in a row
#     sends that row to the end (README: "a row is treated as undef-keyed when
#     any key the comparator actually evaluates ... is undef"), so for the
#     NaN-in-B cases of GH#3917/GH#38426 the comparators below test definedness
#     themselves, which exempts them from the probe.  The plain `$a->{B}` form
#     is checked once, as the documented difference.
#   - drop_cols/select_cols die on a missing column (pandas' default
#     errors="raise" agrees; errors="ignore" has no equivalent here).
#   - drop_cols/select_cols with no column die ("at least one column is
#     required"); pandas drop([]) returns the frame unchanged (GH 16398).
#   - rename_cols dies when a target collides with a kept column; pandas lets
#     column labels repeat.
#   - ljoin adds only the columns i has; a left row with no match gets no
#     column at all, where pandas' merge(how="left") fills NaN.  A column
#     name in both frames takes i's value (as $h{r}{c} = $i{r}{c}); pandas
#     suffixes _x/_y.  ljoin also keeps every key of h and never adds i-only
#     rows, as how="left" does.
#   - Sets: undef in a list dies (README); R's NA is a value.  Order follows
#     R's guarantee, which the README promises; NumPy sorts, so NumPy cases
#     are compared as sets.  "3" and "3.0" differ (string equality), unlike R.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Stats::LikeR qw(:all);
use Test::Exception; # throws_ok / lives_and
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

# frame builders -------------------------------------------------------------
sub aoh_of { # rows [A,B], undef kept, id added
	my @r = @_; my @f;
	for my $i (0 .. $#r) { push @f, { id => $i, A => $r[$i][0], B => $r[$i][1] } }
	return \@f;
}
sub ids { # ids of a frame in any shape csort returns
	my $f = shift;
	if (ref $f eq 'ARRAY') {
		return [ map { ref $_ eq 'HASH' ? $_->{id} : $_->[0] } @$f ];
	}
	return $f->{id};
}
# compare two values, undef last whichever the direction (pandas na_position="last")
sub cmpk {
	my ($x, $y, $asc) = @_;
	return 0 if !defined $x && !defined $y;
	return 1 if !defined $x;
	return -1 if !defined $y;
	return $asc ? $x <=> $y : $y <=> $x;
}

#--------
# csort: pandas test_sort_values
#--------
{
	my $f = aoh_of([1,1], [3,1], [4,5]); # A,B of [[1,1,2],[3,1,0],[4,5,6]]
	$_->{C} = [2,0,6]->[$_->{id}] for @$f;
	is_deeply(ids(csort($f, 'A')), [0,1,2], 'pandas test_sort_values: by A');
	is_deeply(ids(csort($f, sub { $b->{A} <=> $a->{A} })), [2,1,0], 'pandas test_sort_values: by A descending');
	is_deeply(ids(csort($f, sub { $b->{A} <=> $a->{A} }, 'hoa')), [2,1,0], 'pandas test_sort_values: A descending, HoA out');
	is_deeply(ids(csort($f, sub { $a->{B} <=> $b->{B} or $a->{C} <=> $b->{C} })), [1,0,2], 'pandas test_sort_values: by [B, C]');
	is_deeply(ids(csort($f, sub { $b->{B} <=> $a->{B} or $b->{C} <=> $a->{C} })), [2,0,1], 'pandas test_sort_values: by [B, C] descending');
	is_deeply(ids(csort($f, sub { $a->{B} <=> $b->{B} or $b->{A} <=> $a->{A} })), [1,0,2], 'pandas test_sort_values: by [B asc, A desc]');
	# every shape, from the same frame
	my $hoa = { id => [0,1,2], A => [1,3,4] };
	my $s = csort($hoa, sub { $b->{A} <=> $a->{A} });
	is_deeply($s, { id => [2,1,0], A => [4,3,1] }, 'pandas test_sort_values: HoA in, HoA out');
	my $aoa = [ [0,1], [1,3], [2,4] ];
	is_deeply(csort($aoa, sub { $b->[1] <=> $a->[1] }), [ [2,4], [1,3], [0,1] ], 'pandas test_sort_values: AoA descending');
	is_deeply(csort($aoa, 1), $aoa, 'pandas test_sort_values: AoA by column index');
	my $hoh = { r0 => { A => 1 }, r1 => { A => 3 }, r2 => { A => 4 } };
	is_deeply(csort($hoh, 'A', 'aoh'), [ { A => 1, row_name => 'r0' }, { A => 3, row_name => 'r1' }, { A => 4, row_name => 'r2' } ],
		'pandas test_sort_values: HoH ascending, AoH out with row_name');
}

#--------
# csort: pandas test_sort_values_nan (GH#3917)
#--------
{
	my $n = aoh_of([1,9], [2,undef], [undef,5], [1,2], [6,5], [8,4], [4,5]);
	is_deeply(ids(csort($n, 'A')), [0,3,1,6,4,5,2], 'GH#3917: A, NaN last');
	is_deeply(ids(csort($n, sub { $b->{A} <=> $a->{A} })), [5,4,6,1,0,3,2], 'GH#3917: A descending, NaN last');
	# na_position="first" has no csort equivalent: NaN row 2 last, others as pandas
	is_deeply(ids(csort($n, 'A')), [0,3,1,6,4,5,2], 'GH#3917: A na_position first (pandas 2,0,3,1,6,4,5): NaN row last, rest in pandas order (header)');
	my $by_ab = sub { cmpk($a->{A}, $b->{A}, 1) || cmpk($a->{B}, $b->{B}, 1) };
	is_deeply(ids(csort($n, $by_ab)), [3,0,1,6,4,5,2], 'GH#3917: [A, B], NaN last');
	is_deeply(ids(csort($n, $by_ab)), [3,0,1,6,4,5,2], 'GH#3917: [A, B] na_position first (pandas 2,3,0,1,6,4,5): NaN-A row last, rest in pandas order');
	is_deeply(ids(csort($n, sub { cmpk($a->{A}, $b->{A}, 1) || cmpk($a->{B}, $b->{B}, 0) })), [0,3,1,6,4,5,2],
		'GH#3917: [A asc, B desc], na_position first (pandas 2,0,3,1,6,4,5), NaN row last, rest in pandas order');
	is_deeply(ids(csort($n, sub { cmpk($a->{A}, $b->{A}, 0) || cmpk($a->{B}, $b->{B}, 1) })), [5,4,6,1,3,0,2],
		'GH#3917: [A desc, B asc], NaN last');
	# the plain comparator reads B: row 1 (B is NaN) is undef-keyed and goes last (README)
	is_deeply(ids(csort($n, sub { $a->{A} <=> $b->{A} or $a->{B} <=> $b->{B} })), [3,0,6,4,5,1,2],
		'GH#3917: [A, B] with a plain comparator sends the NaN-B row last (documented; pandas keeps it at 1)');
	# a NaN (not undef) in a numeric column
	my $nan = 'NaN';
	my $nn = [ { id => 0, A => 3 }, { id => 1, A => $nan }, { id => 2, A => 1 }, { id => 3, A => undef }, { id => 4, A => 2 } ];
	is_deeply(ids(csort($nn, 'A')), [2,4,0,1,3], 'NaN sorts with undef, last, in original order (README, as R order())');
}

#--------
# csort: pandas stable sorts
#--------
{
	my $g = [ { id => 0, k => 2, o => 'first' }, { id => 1, k => 2, o => 'second' }, { id => 2, k => 1, o => 'a' }, { id => 3, k => 1, o => 'b' } ];
	is_deeply(ids(csort($g, sub { $b->{k} <=> $a->{k} })), [0,1,2,3], 'GH#6399: descending sort is stable');
	is_deeply(ids(csort($g, 'k')), [2,3,0,1], 'GH#6399: ascending sort is stable');
	# GH#38426
	my $m = aoh_of([1,9], [2,undef], [undef,5], [1,2], [1,2], [1,2], [6,5], [8,4], [4,5], [8,3], [8,4], [undef,undef], [undef,undef], [8,4], [8,4]);
	my %want = (
		'1,1' => [3,4,5,0,1,8,6,9,7,10,13,14,2,11,12],
		'1,0' => [0,3,4,5,1,8,6,7,10,13,14,9,2,11,12],
		'0,1' => [9,7,10,13,14,6,8,1,3,4,5,0,2,11,12],
		'0,0' => [7,10,13,14,9,6,8,1,0,3,4,5,2,11,12],
	);
	for my $k (sort keys %want) {
		my ($ascA, $ascB) = split /,/, $k;
		is_deeply(ids(csort($m, sub { cmpk($a->{A}, $b->{A}, $ascA) || cmpk($a->{B}, $b->{B}, $ascB) })), $want{$k},
			"GH#38426: [A asc=$ascA, B asc=$ascB], na_position last");
	}
	# pandas' na_position="first" lists the all-NaN-A rows 11,12,2 first; csort ends with them
	my %first = ( '1,1' => [3,4,5,0,1,8,6,9,7,10,13,14], '0,1' => [9,7,10,13,14,6,8,1,3,4,5,0] );
	for my $k (sort keys %first) {
		my ($ascA, $ascB) = split /,/, $k;
		my $got = ids(csort($m, sub { cmpk($a->{A}, $b->{A}, $ascA) || cmpk($a->{B}, $b->{B}, $ascB) }));
		is_deeply([ @$got[0 .. 11] ], $first{$k}, "GH#38426: [A asc=$ascA, B asc=$ascB], non-NaN rows as pandas na_position first");
	}
	# the multi-key sort by two stable column sorts agrees with the comparator
	is_deeply(ids(csort(csort($m, 'B'), 'A')), $want{'1,1'}, 'GH#38426: stable column sorts B then A equal [A, B]');
}

#--------
# csort: R order()
#--------
{
	my @v = (3, 1, undef, 2, 1, 'NaN', 3);
	my $f = [ map { { id => $_, v => $v[$_] } } 0 .. $#v ];
	is_deeply(ids(csort($f, 'v')), [1,4,3,0,6,2,5], 'R order(c(3,1,NA,2,1,NaN,3))');
	is_deeply(ids(csort($f, sub { $b->{v} <=> $a->{v} })), [0,6,3,1,4,2,5], 'R order(..., decreasing = TRUE): NA/NaN last, ties stable');
	my @s = ('b', 'a', 'C', 'a', undef, 'B');
	my $c = [ map { { id => $_, s => $s[$_] } } 0 .. $#s ];
	is_deeply(ids(csort($c, 's')), [5,2,1,3,0,4], 'R order(chr, method="radix"): C-locale order, NA last');
	is_deeply(ids(csort($c, sub { $b->{s} cmp $a->{s} })), [0,1,3,2,5,4], 'R order(chr, decreasing=TRUE, method="radix")');
	my @k1 = (2,1,2,1,2); my @k2 = (5,9,5,3,1);
	my $k = [ map { { id => $_, k1 => $k1[$_], k2 => $k2[$_] } } 0 .. 4 ];
	is_deeply(ids(csort($k, sub { $a->{k1} <=> $b->{k1} or $a->{k2} <=> $b->{k2} })), [3,1,4,0,2], 'R order(k1, k2)');
	is_deeply(ids(csort($k, sub { $a->{k1} <=> $b->{k1} or $b->{k2} <=> $a->{k2} })), [1,3,0,2,4], 'R order(k1, -k2)');
	is_deeply(ids(csort($k, sub { $b->{k1} <=> $a->{k1} or $a->{k2} <=> $b->{k2} })), [4,0,2,3,1], 'R order(-k1, k2)');
	# the input is never mutated
	my $copy = [ map { { %$_ } } @$k ];
	csort($k, 'k2');
	is_deeply($k, $copy, 'csort leaves its input alone');
	is_deeply(csort([], 'a'), [], 'csort of an empty AoH');
	is_deeply(csort([ { a => 1 } ], 'a'), [ { a => 1 } ], 'csort of one row');
	throws_ok { csort($k, 'nope') } qr/nope/, 'csort: a column no row has dies';
	my $cmp = sub { $a->{k2} <=> $b->{k2} };
	no_leaks_ok { my $x = csort($k, $cmp) } 'csort comparator does not leak' unless $INC{'Devel/Cover.pm'};
}

#--------
# drop_cols / select_cols: pandas test_drop_names, test_drop
#--------
{
	my $df = { a => { d => 1, e => 2, f => 3 }, b => { d => 3, e => 4, f => 5 }, c => { d => 5, e => 6, f => 7 } };
	is_deeply(drop_cols($df, 'e'), { a => { d => 1, f => 3 }, b => { d => 3, f => 5 }, c => { d => 5, f => 7 } },
		'pandas test_drop_names: drop("e", axis=1) on a HoH');
	is_deeply($df->{a}, { d => 1, e => 2, f => 3 }, 'pandas test_drop_names: the original is intact');
	is_deeply(select_cols($df, 'd', 'f'), { a => { d => 1, f => 3 }, b => { d => 3, f => 5 }, c => { d => 5, f => 7 } },
		'pandas df[["d","f"]] equals drop e');
	throws_ok { drop_cols($df, 'g') } qr/column 'g' not found/, 'pandas test_drop_names: drop(["g"], axis=1) raises KeyError';
	throws_ok { select_cols($df, 'g') } qr/column 'g' not found/, 'pandas df[["g"]] raises KeyError';
	throws_ok { drop_cols($df, 'd', 'g') } qr/column 'g' not found/, 'pandas test_drop: drop(["A","C"]) with C missing raises';
	is_deeply(eval { drop_cols($df, 'd', 'e', 'f') } // 'died', { a => {}, b => {}, c => {} }, 'pandas test_drop: drop every column keeps the rows');
	# GH 16398 and errors="ignore": documented differences
	throws_ok { drop_cols($df, []) } qr/at least one column is required/, 'GH 16398: drop([]) is a no-op in pandas; here it dies (header)';
	throws_ok { drop_cols($df, ['d', 'g']) } qr/column 'g' not found/, 'pandas errors="ignore": no equivalent, a missing column dies (header)';
	my $simple = { A => [1,2,3,4], B => [0,1,2,3] };
	is_deeply(drop_cols($simple, 'A'), { B => [0,1,2,3] }, 'pandas test_drop: drop("A", axis=1)');
	is_deeply(drop_cols($simple, ['A', 'B']), {}, 'pandas test_drop: drop(["A","B"]) on a HoA leaves no columns');
	is_deeply(drop_cols([ { A => 1, B => 0 }, { A => 2, B => 1 } ], ['A', 'B']), [ {}, {} ], 'drop every column of an AoH keeps the rows');
	is_deeply(drop_cols([ [1,0], [2,1] ], 0, 1), [ [], [] ], 'drop every column of an AoA keeps the rows');
	is_deeply(select_cols($simple, 'B', 'A'), { B => [0,1,2,3], A => [1,2,3,4] }, 'pandas simple[["B","A"]]');
	is_deeply(select_cols([ [1,2,3], [4,5,6] ], 2, 0), [ [3,1], [6,4] ], 'select an AoA by position, reordered');
	is_deeply(drop_cols([ [1,2,3], [4,5,6] ], 1), [ [1,3], [4,6] ], 'drop an AoA column by position');
	throws_ok { drop_cols([ [1,2,3] ], -1) } qr/non-negative integer/, 'drop_cols: a negative AoA position dies';
	throws_ok { drop_cols([ [1,2,3] ], "1\n") } qr/non-negative integer/, 'drop_cols: "1\\n" is not an AoA position (2026-11-26 audit)';
	throws_ok { drop_cols([ [1,2,3] ], 3) } qr/out of range/, 'drop_cols: an AoA position no row has dies';
	no_leaks_ok { my $x = drop_cols($simple, 'A'); my $y = select_cols($simple, 'B') } 'drop_cols/select_cols do not leak' unless $INC{'Devel/Cover.pm'};
}

#--------
# rename_cols: pandas test_rename, test_rename_bug, test_rename_errors_raises
#--------
{
	my $fr = { A => [1,5], B => [2,6], C => [3,7], D => [4,8] };
	is_deeply(rename_cols($fr, A => 'a', B => 'b', C => 'c', D => 'd'), { a => [1,5], b => [2,6], c => [3,7], d => [4,8] },
		'pandas test_rename: columns=mapping');
	is_deeply(rename_cols($fr, { A => 'a', B => 'b', C => 'c', D => 'd' }), { a => [1,5], b => [2,6], c => [3,7], d => [4,8] },
		'pandas test_rename: the hashref form');
	is_deeply(rename_cols($fr, C => 'foo', D => 'bar'), { A => [1,5], B => [2,6], foo => [3,7], bar => [4,8] },
		'pandas test_rename: partial columns');
	is_deeply($fr, { A => [1,5], B => [2,6], C => [3,7], D => [4,8] }, 'pandas test_rename: the source is not renamed in non-void context');
	is_deeply(rename_cols({ foo => [0], bar => [1] }, foo => 'bar', bar => 'foo'), { bar => [0], foo => [1] },
		'pandas test_rename: a swap of two labels');
	# test_rename_bug (GH 5344): successive renames
	my $b = { 0 => ['foo','bar'], 1 => ['bah','bas'], 2 => [1,2] };
	is_deeply(rename_cols(rename_cols($b, 0 => 'a'), 1 => 'b'), { a => ['foo','bar'], b => ['bah','bas'], 2 => [1,2] },
		'pandas test_rename_bug: successive renames');
	# the same on the other labelled shapes
	is_deeply(rename_cols([ { A => 1, B => 2 }, { A => 3, B => 4 } ], A => 'a'), [ { a => 1, B => 2 }, { a => 3, B => 4 } ], 'rename on an AoH');
	is_deeply(rename_cols({ r => { A => 1, B => 2 } }, A => 'a'), { r => { a => 1, B => 2 } }, 'rename on a HoH');
	# in place, void context
	my $v = { A => [1], B => [2] };
	rename_cols($v, A => 'x');
	is_deeply($v, { x => [1], B => [2] }, 'rename_cols in void context renames in place');
	# errors
	throws_ok { rename_cols($fr, A => 'a', E => 'e') } qr/E/, 'pandas test_rename_errors_raises: a missing column dies';
	is_deeply($fr, { A => [1,5], B => [2,6], C => [3,7], D => [4,8] }, '... and leaves the source alone');
	throws_ok { rename_cols($fr, A => 'B') } qr/./, 'a target that collides with a kept column dies (header; pandas allows repeats)';
	throws_ok { rename_cols([ [1,2] ], 0 => 'a') } qr/./, 'rename_cols of an AoA dies (no names)';
	throws_ok { rename_cols($fr, 'A') } qr/./, 'rename_cols with an odd list dies';
	no_leaks_ok { my $x = rename_cols($fr, A => 'z') } 'rename_cols does not leak' unless $INC{'Devel/Cover.pm'};
}

#--------
# rownames
#--------
{
	is_deeply([ rownames({ r2 => { x => 1 }, r1 => { x => 2 }, r3 => { x => 3 } }) ], [qw(r1 r2 r3)], 'rownames of a HoH, sorted (README)');
	is_deeply([ rownames([ { a => 1 }, { a => 2 } ]) ], [0, 1], 'rownames of an AoH (pandas RangeIndex)');
	is_deeply([ rownames({ a => [1,2,3], b => [4,5,6] }) ], [0,1,2], 'rownames of a HoA');
	is_deeply([ rownames([ [1,2], [3,4], [5,6] ]) ], [0,1,2], 'rownames of an AoA');
	is(scalar rownames({ a => [1,2,3] }), 3, 'rownames in scalar context counts');
	is_deeply([ rownames([]) ], [], 'rownames of an empty frame');
}

#--------
# ljoin: pandas merge(how="left") on the index
#--------
{
	# README's example
	my %h = ('Jack Smith' => { age => 30 });
	my %i = ('Jack Smith' => { dept => 'Engineering' }, 'Jane Doe' => { age => 25 });
	ljoin(\%h, \%i);
	is_deeply(\%h, { 'Jack Smith' => { age => 30, dept => 'Engineering' } }, 'README: i-only rows are not added');
	# pandas merge left: l = {a:{a:1}, b:{a:2}}, r = {a:{b:10}, c:{b:20}}
	my %l = (a => { a => 1 }, b => { a => 2 });
	ljoin(\%l, { a => { b => 10 }, c => { b => 20 } });
	is_deeply(\%l, { a => { a => 1, b => 10 }, b => { a => 2 } },
		'pandas merge how="left": matched row gains the column; unmatched row gets no column (pandas: NaN; header)');
	is_deeply([ sort keys %l ], [qw(a b)], 'pandas merge how="left": exactly the left rows survive');
	# overlapping column: pandas v_x/v_y, here i wins
	my %o = (x => { v => 1 }, y => { v => 2 });
	ljoin(\%o, { x => { v => 9 }, z => { v => 8 } });
	is_deeply(\%o, { x => { v => 9 }, y => { v => 2 } }, 'overlapping column: i overwrites (pandas suffixes; header)');
	# copy, not alias (README, 0.3218)
	my %src = (k => { c => 5 }); my %dst = (k => { d => 1 });
	ljoin(\%dst, \%src); $dst{k}{c} = 6;
	is($src{k}{c}, 5, 'README: ljoin copies the value');
	my %e; ljoin(\%e, { a => { q => 1 } });
	is_deeply(\%e, {}, 'ljoin onto an empty hash adds nothing');
	throws_ok { ljoin([], {}) } qr/first argument must be a hash reference/, 'ljoin: first argument must be a hash ref';
	my %lk = (a => { x => 1 }); my %rk = (a => { y => 2 });
	no_leaks_ok { ljoin(\%lk, \%rk) } 'ljoin does not leak' unless $INC{'Devel/Cover.pm'};
}

#--------
# set functions: R sets.Rd, NumPy test_arraysetops.py
#--------
{
	my @x = (2, 5, 9, 11, 14, 17, 19, 3, 5);
	my @y = (5, 7, 11, 12, 20, 22, 3, 9, 9);
	is_deeply([ get_union(\@x, \@y) ], [2,5,9,11,14,17,19,3,7,12,20,22], 'R union(x, y), same order');
	is_deeply([ intersection(\@x, \@y) ], [5,9,11,3], 'R intersect(x, y), same order');
	is_deeply([ Lonly(\@x, \@y) ], [2,14,17,19], 'R setdiff(x, y)');
	is_deeply([ Ronly(\@x, \@y) ], [7,12,20,22], 'R setdiff(y, x)');
	is(is_equivalent(\@x, \@y), 0, 'R setequal(x, y) is FALSE');
	is(is_equivalent(\@x, [ reverse @x ]), 1, 'R setequal(x, rev(x))');
	my @u = (get_union(\@x, \@y));
	is(is_equivalent(\@u, [ Lonly(\@x, \@y), intersection(\@x, \@y), Lonly(\@y, \@x) ]), 1,
		'sets.Rd: setequal(union, c(setdiff, intersect, setdiff)) is TRUE');
	is(scalar get_union(\@x, \@y), 12, 'scalar get_union counts');
	is(scalar intersection(\@x, \@y), 4, 'scalar intersection counts');
	# factor example, as strings
	is_deeply([ get_union([qw(A B A)], [qw(B b)]) ], [qw(A B b)], 'sets.Rd factors: union');
	is_deeply([ intersection([qw(A B A)], [qw(B b)]) ], ['B'], 'sets.Rd factors: intersect');
	is_deeply([ Lonly([qw(A B A)], [qw(B b)]) ], ['A'], 'sets.Rd factors: setdiff(x, y)');
	is_deeply([ Ronly([qw(A B A)], [qw(B b)]) ], ['b'], 'sets.Rd factors: setdiff(y, x)');
	is_deeply([ get_union([qw(a b a)], [qw(b c)]) ], [qw(a b c)], 'reg-tests-1e.R: union of factors');
	# three lists, R Reduce()
	my @a = (1..5); my @b = (3..7); my @c = (5..8);
	is_deeply([ Lonly(\@a, \@b, \@c) ], [1,2], 'Reduce(setdiff, list(a, b, c))');
	is_deeply([ Ronly(\@a, \@b, \@c) ], [8], 'Reduce(setdiff, list(c, b, a))');
	is_deeply([ get_union(\@a, \@b, \@c) ], [1..8], 'Reduce(union, ...)');
	is_deeply([ intersection(\@a, \@b, \@c) ], [5], 'Reduce(intersect, ...)');
	is(is_equivalent([1,1,2], [2,1]), 1, 'setequal(c(1,1,2), c(2,1))');
	is(is_equivalent([1,2,3], [1,2]), 0, 'setequal(c(1,2,3), c(1,2))');
	is(is_equivalent([], []), 1, 'setequal(c(), c())');
	is(is_equivalent([], [1]), 0, 'empty against non-empty');
	is(is_equivalent([1,2], [2,1], [1,2,3]), 0, 'three lists, the last has an extra');
	# NumPy, as sets
	my @ni = intersection([5,5,7,1,2], [2,1,4,3,3,1,5]);
	is_deeply([ sort { $a <=> $b } @ni ], [1,2,5], 'NumPy test_intersect1d (non-unique inputs)');
	is_deeply([ sort { $a <=> $b } get_union([5,4,7,1,2], [2,4,3,3,2,1,5]) ], [1,2,3,4,5,7], 'NumPy test_union1d');
	is_deeply([ sort { $a <=> $b } Lonly([6,5,4,7,1,2,7,4], [2,4,3,3,2,1,5]) ], [6,7], 'NumPy test_setdiff1d');
	is_deeply([ intersection([], []) ], [], 'NumPy intersect1d([], [])');
	is_deeply([ get_union([], []) ], [], 'NumPy union1d([], [])');
	is_deeply([ Lonly([], []) ], [], 'NumPy setdiff1d([], [])');
	# string identity: 3 vs 3.0 differ (README); R would coerce numbers
	is_deeply([ intersection([3, 4], ['3.0', 4]) ], [4], '"3" and "3.0" are distinct strings (header)');
	# validation
	throws_ok { intersection([1], 2) } qr/not an array ref/, 'intersection of a non-ref dies';
	throws_ok { get_union([1, undef]) } qr/undefined value/, 'get_union with undef dies (R keeps NA; header)';
	throws_ok { Lonly([1], [undef]) } qr/undefined value/, 'Lonly with undef dies';
	throws_ok { is_equivalent([1]) } qr/./, 'is_equivalent needs two lists';
	my @p = (1,2,3); my @q = (2,3,4);
	no_leaks_ok { my @r = (get_union(\@p, \@q), intersection(\@p, \@q), Lonly(\@p, \@q), Ronly(\@p, \@q)); is_equivalent(\@p, \@q) }
		'set functions do not leak' unless $INC{'Devel/Cover.pm'};
}

done_testing();
