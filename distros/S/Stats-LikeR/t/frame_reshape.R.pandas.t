#!/usr/bin/env perl
# concat()/rbind(), melt(), pivot_table(), transpose() and assign(), against
# the cases of pandas' and R's own test suites.
#
# Provenance (each case's own test or example is named in its `src` field in
# the case tables below):
#   pandas 3.0.4 (NumPy 2.4.6, Python 3.14.2), pandas/tests/reshape/concat/
#         test_sort.py, test_empty.py, test_append.py, test_dataframe.py;
#         pandas/tests/reshape/test_melt.py; pandas/tests/reshape/test_pivot.py;
#         pandas/tests/frame/methods/test_transpose.py and test_assign.py;
#         the DataFrame.melt docstring.  The expected values are printed by
#         t/frame_reshape.R.pandas.py; re-run it with
#             python3 -I t/frame_reshape.R.pandas.py
#         and paste the output over the "pandas cases" block.  Where an
#         upstream test builds its frame from random normals, the frame here
#         uses dyadic values (exact in every NV width), and the test's
#         shape of call is kept.
#   R 4.6.2 (sources R 4.6.1): tests/reg-tests-2.R lines 60-76 (zero-row and
#         zero-column frames under rbind), 740 (PR#2266), 1853 (PR#8868
#         permuted columns); tests/reg-tests-1c.R line 1249 (row names);
#         src/library/base/man/cbind.Rd (rbind of data frames) and t.Rd.
#         Printed by t/frame_reshape.R.pandas.R; re-run with
#             Rscript --vanilla t/frame_reshape.R.pandas.R
#         This test never runs R or Python.
#
# Shapes: a pandas frame from a list of dicts is an AoH, from a dict of lists
# a HoA, a dict of dicts read with orient="index" a HoH, a numeric matrix an
# AoA.  Column labels are strings here (pandas' integer label 0 is '0').
# NaN in a pandas result is undef.
#
# Tolerance: numbers compare with a relative 1e-12 (about 4500 double
# epsilons).  With the tolerance at 0 every numeric cell, var and sd included,
# agrees with pandas on the double build (measured 2026-11-26, worst
# disagreement 0), so 1e-12 is headroom for the long double and quadmath
# builds, whose var/sd are the more accurate of the two, not a fitted bound.
#
# Deliberate differences, kept so that changing one is a decision (README.md
# section in parentheses):
#   - concat() makes a repeated HoH row name unique as name.1, name.2 (README
#     "Hash of Hashes"); R's rbind() writes name1, name2 (make.unique with
#     sep = ""), pandas keeps the duplicate label.  The test pins README's
#     form and, beside it, R's, which fails.
#   - concat() has no keys, join, sort or ignore_index (README "concat");
#     pandas' join="inner" case (test_inner_sort_columns) is not mapped.
#   - R's rbind.data.frame() stops on mismatched column names ("names do not
#     match previous names"); concat() takes the union of the columns and
#     pads with undef (README "Array of Hashes"/"Hash of Arrays").
#   - assign() changes its frame in place and returns it; pandas' assign()
#     returns a new frame (README "assign").  A column a coderef reads that
#     does not exist is undef; pandas raises AttributeError.
#   - transpose() takes an AoA or a HoH only (README "transpose"); R's t() and
#     pandas' .T also take a column-major frame.  A HoH with different inner
#     keys is not padded, where pandas pads with NaN.  R's t() on a data frame
#     coerces to one type (character if any column is); transpose() keeps each
#     cell as it was.
#   - pivot_table() requires columns (README "pivot_table"); pandas lets it be
#     omitted and puts the value columns in the index.  Without index the
#     value columns are spread over one 'all' row as '<value>.<column>'.
#   - A single function in an aggfunc list names the columns flat
#     (README "Generated column names"); pandas prefixes the function.
#   - pandas margins= and dropna=False's cartesian product of column keys have
#     no equivalent and are not mapped.
#   - pivot_table() has no dropna: it keeps an output column whose every cell
#     is NA, and a row whose index key is NA (sorted last), where pandas'
#     default dropna=True drops both; a row whose columns key is NA is
#     skipped, which neither pandas mode does (README "pivot_table"; the
#     GH 22159 and GH#61113 cases, pinned in %PIVOT_DIFF).
#
# Two undocumented disagreements this file found were bugs, fixed in 0.3431:
# melt() melted a repeated value_vars entry once per repeat, where pandas
# melts it once, and concat() read a hash of scalars as a HoA of absent
# columns, returning { a => [], b => [] } where pandas refuses it.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # throws_ok / lives_and
use Test::More;
use Test::LeakTrace 'no_leaks_ok';
use Scalar::Util 'looks_like_number';

my $TOL = 1e-12; # relative; see the header

sub same { # undef-aware scalar comparison, numeric within $TOL
	my ($g, $e) = @_;
	return 1 if !defined $g && !defined $e;
	return 0 if !defined $g || !defined $e;
	if (looks_like_number($g) && looks_like_number($e)) {
		my $d = abs($g - $e);
		return $d <= $TOL * (abs($e) > 1 ? abs($e) : 1);
	}
	return $g eq $e;
}
# Compare two frames of one shape; returns '' or a description of the first
# difference.  $strict makes a key that is absent from a row differ from one
# present as undef; otherwise a missing key reads as undef (the module's
# convention for concat and melt).
sub row_diff {
	my ($g, $e, $strict, $where) = @_;
	return "$where: got ", (defined $g ? ref($g) || 'scalar' : 'undef') unless ref $g eq 'HASH';
	my %k = map { $_ => 1 } keys %$e, ($strict ? () : keys %$g);
	if ($strict) {
		for my $k (sort keys %$g) { return "$where: unexpected key '$k'" unless exists $e->{$k} }
		for my $k (sort keys %$e) { return "$where: missing key '$k'" unless exists $g->{$k} }
	}
	for my $k (sort keys %k) {
		next if same($g->{$k}, $e->{$k});
		return "$where.$k: got " . (defined $g->{$k} ? "'$g->{$k}'" : 'undef') .
			', expected ' . (defined $e->{$k} ? "'$e->{$k}'" : 'undef');
	}
	return '';
}
sub frame_diff {
	my ($g, $e, $shape, $strict) = @_;
	if ($shape eq 'aoh') {
		return 'not an ARRAY' unless ref $g eq 'ARRAY';
		return 'got ' . @$g . ' rows, expected ' . @$e unless @$g == @$e;
		for my $i (0 .. $#$e) {
			my $d = row_diff($g->[$i], $e->[$i], $strict, "row $i");
			return $d if $d;
		}
	} elsif ($shape eq 'aoa') {
		return 'not an ARRAY' unless ref $g eq 'ARRAY';
		return 'got ' . @$g . ' rows, expected ' . @$e unless @$g == @$e;
		for my $i (0 .. $#$e) {
			return "row $i: got " . @{ $g->[$i] } . ' cells, expected ' . @{ $e->[$i] }
				unless @{ $g->[$i] } == @{ $e->[$i] };
			for my $j (0 .. $#{ $e->[$i] }) {
				return "cell [$i][$j]" unless same($g->[$i][$j], $e->[$i][$j]);
			}
		}
	} elsif ($shape eq 'hoa') {
		return 'not a HASH' unless ref $g eq 'HASH';
		for my $k (sort keys %$g) { return "unexpected column '$k'" unless exists $e->{$k} }
		for my $k (sort keys %$e) {
			return "missing column '$k'" unless ref $g->{$k} eq 'ARRAY';
			return "column '$k': got " . @{ $g->{$k} } . ' values, expected ' . @{ $e->{$k} }
				unless @{ $g->{$k} } == @{ $e->{$k} };
			for my $i (0 .. $#{ $e->{$k} }) {
				return "cell $k\[$i]: got " . (defined $g->{$k}[$i] ? "'$g->{$k}[$i]'" : 'undef') .
					', expected ' . (defined $e->{$k}[$i] ? "'$e->{$k}[$i]'" : 'undef')
					unless same($g->{$k}[$i], $e->{$k}[$i]);
			}
		}
	} elsif ($shape eq 'hoh') {
		return 'not a HASH' unless ref $g eq 'HASH';
		for my $k (sort keys %$g) { return "unexpected row '$k'" unless exists $e->{$k} }
		for my $k (sort keys %$e) {
			return "missing row '$k'" unless exists $g->{$k};
			my $d = row_diff($g->{$k}, $e->{$k}, $strict, "row $k");
			return $d if $d;
		}
	}
	return '';
}
sub clone { # deep copy of plain data
	my $x = shift;
	return [ map { clone($_) } @$x ] if ref $x eq 'ARRAY';
	return { map { $_ => clone($x->{$_}) } keys %$x } if ref $x eq 'HASH';
	return $x;
}

# BEGIN pandas cases (generated by t/frame_reshape.R.pandas.py)
my @PANDAS = (
	{ kind => 'concat', name => 'test_concat_sorts_columns HoA', src => 'concat/test_sort.py::test_concat_sorts_columns',
	  in => [{'a' => [1, 2], 'b' => [1, 2]}, {'a' => [3, 4], 'c' => [5, 6]}],
	  opt => {},
	  shape => 'hoa',
	  exp => {'a' => [1, 2, 3, 4], 'b' => [1, 2, undef, undef], 'c' => [undef, undef, 5, 6]} },
	{ kind => 'concat', name => 'test_concat_sorts_columns AoH', src => 'concat/test_sort.py::test_concat_sorts_columns',
	  in => [[{'a' => 1, 'b' => 1}, {'a' => 2, 'b' => 2}], [{'a' => 3, 'c' => 5}, {'a' => 4, 'c' => 6}]],
	  opt => {},
	  shape => 'aoh',
	  exp => [{'a' => 1, 'b' => 1, 'c' => undef}, {'a' => 2, 'b' => 2, 'c' => undef}, {'a' => 3, 'b' => undef, 'c' => 5}, {'a' => 4, 'b' => undef, 'c' => 6}] },
	{ kind => 'concat', name => 'test_concat_frame_with_sort_false HoA', src => 'concat/test_sort.py::test_concat_frame_with_sort_false',
	  in => [{'2' => [2]}, {'1' => [1]}],
	  opt => {},
	  shape => 'hoa',
	  exp => {'2' => [2, undef], '1' => [undef, 1]} },
	{ kind => 'concat', name => 'test_handle_empty_objects HoA', src => 'concat/test_empty.py::test_handle_empty_objects',
	  in => [{'a' => [0, 0.25, 0.5, 0.75, 1], 'b' => [0.25, 0.5, 0.75, 1, 1.25], 'c' => [0.5, 0.75, 1, 1.25, 1.5], 'd' => [0.75, 1, 1.25, 1.5, 1.75], 'foo' => ['bar', 'bar', 'bar', 'bar', 'bar']}, {'a' => [], 'b' => [], 'c' => [], 'd' => []}, {'a' => [], 'b' => [], 'c' => [], 'd' => []}, {'a' => [1.25, 1.5, 1.75, 2, 2.25], 'b' => [1.5, 1.75, 2, 2.25, 2.5], 'c' => [1.75, 2, 2.25, 2.5, 2.75], 'd' => [2, 2.25, 2.5, 2.75, 3]}],
	  opt => {},
	  shape => 'hoa',
	  exp => {'a' => [0, 0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.25], 'b' => [0.25, 0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5], 'c' => [0.5, 0.75, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75], 'd' => [0.75, 1, 1.25, 1.5, 1.75, 2, 2.25, 2.5, 2.75, 3], 'foo' => ['bar', 'bar', 'bar', 'bar', 'bar', undef, undef, undef, undef, undef]} },
	{ kind => 'concat', name => 'test_handle_empty_objects AoH', src => 'concat/test_empty.py::test_handle_empty_objects',
	  in => [[{'a' => 0, 'b' => 0.25, 'c' => 0.5, 'd' => 0.75, 'foo' => 'bar'}, {'a' => 0.25, 'b' => 0.5, 'c' => 0.75, 'd' => 1, 'foo' => 'bar'}, {'a' => 0.5, 'b' => 0.75, 'c' => 1, 'd' => 1.25, 'foo' => 'bar'}, {'a' => 0.75, 'b' => 1, 'c' => 1.25, 'd' => 1.5, 'foo' => 'bar'}, {'a' => 1, 'b' => 1.25, 'c' => 1.5, 'd' => 1.75, 'foo' => 'bar'}], [], [], [{'a' => 1.25, 'b' => 1.5, 'c' => 1.75, 'd' => 2}, {'a' => 1.5, 'b' => 1.75, 'c' => 2, 'd' => 2.25}, {'a' => 1.75, 'b' => 2, 'c' => 2.25, 'd' => 2.5}, {'a' => 2, 'b' => 2.25, 'c' => 2.5, 'd' => 2.75}, {'a' => 2.25, 'b' => 2.5, 'c' => 2.75, 'd' => 3}]],
	  opt => {},
	  shape => 'aoh',
	  exp => [{'a' => 0, 'b' => 0.25, 'c' => 0.5, 'd' => 0.75, 'foo' => 'bar'}, {'a' => 0.25, 'b' => 0.5, 'c' => 0.75, 'd' => 1, 'foo' => 'bar'}, {'a' => 0.5, 'b' => 0.75, 'c' => 1, 'd' => 1.25, 'foo' => 'bar'}, {'a' => 0.75, 'b' => 1, 'c' => 1.25, 'd' => 1.5, 'foo' => 'bar'}, {'a' => 1, 'b' => 1.25, 'c' => 1.5, 'd' => 1.75, 'foo' => 'bar'}, {'a' => 1.25, 'b' => 1.5, 'c' => 1.75, 'd' => 2, 'foo' => undef}, {'a' => 1.5, 'b' => 1.75, 'c' => 2, 'd' => 2.25, 'foo' => undef}, {'a' => 1.75, 'b' => 2, 'c' => 2.25, 'd' => 2.5, 'foo' => undef}, {'a' => 2, 'b' => 2.25, 'c' => 2.5, 'd' => 2.75, 'foo' => undef}, {'a' => 2.25, 'b' => 2.5, 'c' => 2.75, 'd' => 3, 'foo' => undef}] },
	{ kind => 'concat', name => 'test_empty_dtype_coerce AoH', src => 'concat/test_empty.py::test_empty_dtype_coerce',
	  in => [[{'a' => 1, 'b' => undef}, {'a' => 2, 'b' => undef}], [{'a' => 3, 'b' => undef}, {'a' => 4, 'b' => undef}]],
	  opt => {},
	  shape => 'aoh',
	  exp => [{'a' => 1, 'b' => undef}, {'a' => 2, 'b' => undef}, {'a' => 3, 'b' => undef}, {'a' => 4, 'b' => undef}] },
	{ kind => 'concat', name => 'test_empty_dtype_coerce HoA', src => 'concat/test_empty.py::test_empty_dtype_coerce',
	  in => [{'a' => [1, 2], 'b' => [undef, undef]}, {'a' => [3, 4], 'b' => [undef, undef]}],
	  opt => {},
	  shape => 'hoa',
	  exp => {'a' => [1, 2, 3, 4], 'b' => [undef, undef, undef, undef]} },
	{ kind => 'concat', name => 'test_concat_empty_dataframe a,b + b,c + a,b', src => 'concat/test_empty.py::test_concat_empty_dataframe',
	  in => [{'a' => [], 'b' => []}, {'b' => [], 'c' => []}, {'a' => [], 'b' => []}],
	  opt => {},
	  shape => 'hoa',
	  exp => {'a' => [], 'b' => [], 'c' => []} },
	{ kind => 'concat', name => 'test_concat_empty_dataframe a,b + b', src => 'concat/test_empty.py::test_concat_empty_dataframe',
	  in => [{'a' => [], 'b' => []}, {'b' => []}],
	  opt => {},
	  shape => 'hoa',
	  exp => {'a' => [], 'b' => []} },
	{ kind => 'concat', name => 'test_append partial HoA', src => 'concat/test_append.py::test_append',
	  in => [{'A' => [0, 0.25, 0.5], 'B' => [0.25, 0.5, 0.75], 'C' => [0.5, 0.75, 1], 'D' => [0.75, 1, 1.25]}, {'B' => [1, 1.25, 1.5], 'C' => [1.25, 1.5, 1.75], 'D' => [1.5, 1.75, 2]}],
	  opt => {},
	  shape => 'hoa',
	  exp => {'A' => [0, 0.25, 0.5, undef, undef, undef], 'B' => [0.25, 0.5, 0.75, 1, 1.25, 1.5], 'C' => [0.5, 0.75, 1, 1.25, 1.5, 1.75], 'D' => [0.75, 1, 1.25, 1.5, 1.75, 2]} },
	{ kind => 'concat', name => 'test_append partial reversed HoA', src => 'concat/test_append.py::test_append',
	  in => [{'B' => [1, 1.25, 1.5], 'C' => [1.25, 1.5, 1.75], 'D' => [1.5, 1.75, 2]}, {'A' => [0, 0.25, 0.5], 'B' => [0.25, 0.5, 0.75], 'C' => [0.5, 0.75, 1], 'D' => [0.75, 1, 1.25]}],
	  opt => {},
	  shape => 'hoa',
	  exp => {'B' => [1, 1.25, 1.5, 0.25, 0.5, 0.75], 'C' => [1.25, 1.5, 1.75, 0.5, 0.75, 1], 'D' => [1.5, 1.75, 2, 0.75, 1, 1.25], 'A' => [undef, undef, undef, 0, 0.25, 0.5]} },
	{ kind => 'concat', name => 'test_append mixed AoH', src => 'concat/test_append.py::test_append',
	  in => [[{'A' => 0, 'B' => 0.25, 'C' => 0.5, 'D' => 0.75, 'foo' => 'bar'}, {'A' => 0.25, 'B' => 0.5, 'C' => 0.75, 'D' => 1, 'foo' => 'bar'}, {'A' => 0.5, 'B' => 0.75, 'C' => 1, 'D' => 1.25, 'foo' => 'bar'}], [{'A' => 0.75, 'B' => 1, 'C' => 1.25, 'D' => 1.5}, {'A' => 1, 'B' => 1.25, 'C' => 1.5, 'D' => 1.75}, {'A' => 1.25, 'B' => 1.5, 'C' => 1.75, 'D' => 2}]],
	  opt => {},
	  shape => 'aoh',
	  exp => [{'A' => 0, 'B' => 0.25, 'C' => 0.5, 'D' => 0.75, 'foo' => 'bar'}, {'A' => 0.25, 'B' => 0.5, 'C' => 0.75, 'D' => 1, 'foo' => 'bar'}, {'A' => 0.5, 'B' => 0.75, 'C' => 1, 'D' => 1.25, 'foo' => 'bar'}, {'A' => 0.75, 'B' => 1, 'C' => 1.25, 'D' => 1.5, 'foo' => undef}, {'A' => 1, 'B' => 1.25, 'C' => 1.5, 'D' => 1.75, 'foo' => undef}, {'A' => 1.25, 'B' => 1.5, 'C' => 1.75, 'D' => 2, 'foo' => undef}] },
	{ kind => 'concat', name => 'test_outer_sort_columns AoH', src => 'concat/test_dataframe.py::test_outer_sort_columns',
	  in => [[{'A' => 0, 'B' => 1, '0' => 1}], [{'A' => 100}]],
	  opt => {},
	  shape => 'aoh',
	  exp => [{'0' => 1, 'A' => 0, 'B' => 1}, {'0' => undef, 'A' => 100, 'B' => undef}] },
	{ kind => 'concat', name => 'three frames, union HoA', src => 'concat/test_concat.py (union of columns)',
	  in => [{'x' => [1, 2]}, {'y' => [3]}, {'x' => [4], 'y' => [5]}],
	  opt => {},
	  shape => 'hoa',
	  exp => {'x' => [1, 2, undef, 4], 'y' => [undef, undef, 3, 5]} },
	{ kind => 'concat', name => 'distinct HoH row names kept (reg-tests-1c.R smart row names)', src => 'pandas concat axis=0 index',
	  in => [{'3' => {'x' => 3}, '4' => {'x' => 4}}, {'1' => {'x' => 1}, '2' => {'x' => 2}}],
	  opt => {},
	  shape => 'hoh',
	  exp => {'3' => {'x' => 3}, '4' => {'x' => 4}, '1' => {'x' => 1}, '2' => {'x' => 2}} },
	{ kind => 'concat', name => 'HoH union of columns', src => 'pandas concat axis=0',
	  in => [{'r' => {'v' => 1.5, 'w' => 2.5}}, {'s' => {'v' => 3.5}}],
	  opt => {},
	  shape => 'hoh',
	  exp => {'r' => {'v' => 1.5, 'w' => 2.5}, 's' => {'v' => 3.5, 'w' => undef}} },
	{ kind => 'melt', name => 'test_top_level_method / test_default_col_names', src => 'test_melt.py::test_default_col_names',
	  in => [[{'A' => 0.5, 'B' => -0.5, 'C' => 1, 'D' => 0.75, 'id1' => 1, 'id2' => 0}, {'A' => -1.25, 'B' => 0.25, 'C' => 0, 'D' => 1.25, 'id1' => 0, 'id2' => 1}, {'A' => 2, 'B' => 1.75, 'C' => -1, 'D' => -0.25, 'id1' => 1, 'id2' => 1}, {'A' => -0.75, 'B' => -2, 'C' => 2.5, 'D' => 0.5, 'id1' => 0, 'id2' => 0}, {'A' => 1.5, 'B' => 0.125, 'C' => 3.5, 'D' => -3, 'id1' => 1, 'id2' => 1}]],
	  opt => {},
	  shape => 'aoh',
	  exp => [{'variable' => 'A', 'value' => 0.5}, {'variable' => 'A', 'value' => -1.25}, {'variable' => 'A', 'value' => 2}, {'variable' => 'A', 'value' => -0.75}, {'variable' => 'A', 'value' => 1.5}, {'variable' => 'B', 'value' => -0.5}, {'variable' => 'B', 'value' => 0.25}, {'variable' => 'B', 'value' => 1.75}, {'variable' => 'B', 'value' => -2}, {'variable' => 'B', 'value' => 0.125}, {'variable' => 'C', 'value' => 1}, {'variable' => 'C', 'value' => 0}, {'variable' => 'C', 'value' => -1}, {'variable' => 'C', 'value' => 2.5}, {'variable' => 'C', 'value' => 3.5}, {'variable' => 'D', 'value' => 0.75}, {'variable' => 'D', 'value' => 1.25}, {'variable' => 'D', 'value' => -0.25}, {'variable' => 'D', 'value' => 0.5}, {'variable' => 'D', 'value' => -3}, {'variable' => 'id1', 'value' => 1}, {'variable' => 'id1', 'value' => 0}, {'variable' => 'id1', 'value' => 1}, {'variable' => 'id1', 'value' => 0}, {'variable' => 'id1', 'value' => 1}, {'variable' => 'id2', 'value' => 0}, {'variable' => 'id2', 'value' => 1}, {'variable' => 'id2', 'value' => 1}, {'variable' => 'id2', 'value' => 0}, {'variable' => 'id2', 'value' => 1}] },
	{ kind => 'melt', name => 'test_default_col_names id1', src => 'test_melt.py::test_default_col_names',
	  in => [[{'A' => 0.5, 'B' => -0.5, 'C' => 1, 'D' => 0.75, 'id1' => 1, 'id2' => 0}, {'A' => -1.25, 'B' => 0.25, 'C' => 0, 'D' => 1.25, 'id1' => 0, 'id2' => 1}, {'A' => 2, 'B' => 1.75, 'C' => -1, 'D' => -0.25, 'id1' => 1, 'id2' => 1}, {'A' => -0.75, 'B' => -2, 'C' => 2.5, 'D' => 0.5, 'id1' => 0, 'id2' => 0}, {'A' => 1.5, 'B' => 0.125, 'C' => 3.5, 'D' => -3, 'id1' => 1, 'id2' => 1}]],
	  opt => {'id_vars' => ['id1']},
	  shape => 'aoh',
	  exp => [{'id1' => 1, 'variable' => 'A', 'value' => 0.5}, {'id1' => 0, 'variable' => 'A', 'value' => -1.25}, {'id1' => 1, 'variable' => 'A', 'value' => 2}, {'id1' => 0, 'variable' => 'A', 'value' => -0.75}, {'id1' => 1, 'variable' => 'A', 'value' => 1.5}, {'id1' => 1, 'variable' => 'B', 'value' => -0.5}, {'id1' => 0, 'variable' => 'B', 'value' => 0.25}, {'id1' => 1, 'variable' => 'B', 'value' => 1.75}, {'id1' => 0, 'variable' => 'B', 'value' => -2}, {'id1' => 1, 'variable' => 'B', 'value' => 0.125}, {'id1' => 1, 'variable' => 'C', 'value' => 1}, {'id1' => 0, 'variable' => 'C', 'value' => 0}, {'id1' => 1, 'variable' => 'C', 'value' => -1}, {'id1' => 0, 'variable' => 'C', 'value' => 2.5}, {'id1' => 1, 'variable' => 'C', 'value' => 3.5}, {'id1' => 1, 'variable' => 'D', 'value' => 0.75}, {'id1' => 0, 'variable' => 'D', 'value' => 1.25}, {'id1' => 1, 'variable' => 'D', 'value' => -0.25}, {'id1' => 0, 'variable' => 'D', 'value' => 0.5}, {'id1' => 1, 'variable' => 'D', 'value' => -3}, {'id1' => 1, 'variable' => 'id2', 'value' => 0}, {'id1' => 0, 'variable' => 'id2', 'value' => 1}, {'id1' => 1, 'variable' => 'id2', 'value' => 1}, {'id1' => 0, 'variable' => 'id2', 'value' => 0}, {'id1' => 1, 'variable' => 'id2', 'value' => 1}] },
	{ kind => 'melt', name => 'test_default_col_names id1,id2', src => 'test_melt.py::test_default_col_names',
	  in => [{'A' => [0.5, -1.25, 2, -0.75, 1.5], 'B' => [-0.5, 0.25, 1.75, -2, 0.125], 'C' => [1, 0, -1, 2.5, 3.5], 'D' => [0.75, 1.25, -0.25, 0.5, -3], 'id1' => [1, 0, 1, 0, 1], 'id2' => [0, 1, 1, 0, 1]}],
	  opt => {'id_vars' => ['id1', 'id2']},
	  shape => 'hoa',
	  exp => {'id1' => [1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1], 'id2' => [0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1, 0, 1, 1, 0, 1], 'variable' => ['A', 'A', 'A', 'A', 'A', 'B', 'B', 'B', 'B', 'B', 'C', 'C', 'C', 'C', 'C', 'D', 'D', 'D', 'D', 'D'], 'value' => [0.5, -1.25, 2, -0.75, 1.5, -0.5, 0.25, 1.75, -2, 0.125, 1, 0, -1, 2.5, 3.5, 0.75, 1.25, -0.25, 0.5, -3]} },
	{ kind => 'melt', name => 'test_value_vars scalar', src => 'test_melt.py::test_value_vars',
	  in => [[{'A' => 0.5, 'B' => -0.5, 'C' => 1, 'D' => 0.75, 'id1' => 1, 'id2' => 0}, {'A' => -1.25, 'B' => 0.25, 'C' => 0, 'D' => 1.25, 'id1' => 0, 'id2' => 1}, {'A' => 2, 'B' => 1.75, 'C' => -1, 'D' => -0.25, 'id1' => 1, 'id2' => 1}, {'A' => -0.75, 'B' => -2, 'C' => 2.5, 'D' => 0.5, 'id1' => 0, 'id2' => 0}, {'A' => 1.5, 'B' => 0.125, 'C' => 3.5, 'D' => -3, 'id1' => 1, 'id2' => 1}]],
	  opt => {'id_vars' => ['id1', 'id2'], 'value_vars' => 'A'},
	  shape => 'aoh',
	  exp => [{'id1' => 1, 'id2' => 0, 'variable' => 'A', 'value' => 0.5}, {'id1' => 0, 'id2' => 1, 'variable' => 'A', 'value' => -1.25}, {'id1' => 1, 'id2' => 1, 'variable' => 'A', 'value' => 2}, {'id1' => 0, 'id2' => 0, 'variable' => 'A', 'value' => -0.75}, {'id1' => 1, 'id2' => 1, 'variable' => 'A', 'value' => 1.5}] },
	{ kind => 'melt', name => 'test_value_vars list', src => 'test_melt.py::test_value_vars',
	  in => [[{'A' => 0.5, 'B' => -0.5, 'C' => 1, 'D' => 0.75, 'id1' => 1, 'id2' => 0}, {'A' => -1.25, 'B' => 0.25, 'C' => 0, 'D' => 1.25, 'id1' => 0, 'id2' => 1}, {'A' => 2, 'B' => 1.75, 'C' => -1, 'D' => -0.25, 'id1' => 1, 'id2' => 1}, {'A' => -0.75, 'B' => -2, 'C' => 2.5, 'D' => 0.5, 'id1' => 0, 'id2' => 0}, {'A' => 1.5, 'B' => 0.125, 'C' => 3.5, 'D' => -3, 'id1' => 1, 'id2' => 1}]],
	  opt => {'id_vars' => ['id1', 'id2'], 'value_vars' => ['A', 'B']},
	  shape => 'aoh',
	  exp => [{'id1' => 1, 'id2' => 0, 'variable' => 'A', 'value' => 0.5}, {'id1' => 0, 'id2' => 1, 'variable' => 'A', 'value' => -1.25}, {'id1' => 1, 'id2' => 1, 'variable' => 'A', 'value' => 2}, {'id1' => 0, 'id2' => 0, 'variable' => 'A', 'value' => -0.75}, {'id1' => 1, 'id2' => 1, 'variable' => 'A', 'value' => 1.5}, {'id1' => 1, 'id2' => 0, 'variable' => 'B', 'value' => -0.5}, {'id1' => 0, 'id2' => 1, 'variable' => 'B', 'value' => 0.25}, {'id1' => 1, 'id2' => 1, 'variable' => 'B', 'value' => 1.75}, {'id1' => 0, 'id2' => 0, 'variable' => 'B', 'value' => -2}, {'id1' => 1, 'id2' => 1, 'variable' => 'B', 'value' => 0.125}] },
	{ kind => 'melt', name => 'test_value_vars_types list HoA', src => 'test_melt.py::test_value_vars_types',
	  in => [{'A' => [0.5, -1.25, 2, -0.75, 1.5], 'B' => [-0.5, 0.25, 1.75, -2, 0.125], 'C' => [1, 0, -1, 2.5, 3.5], 'D' => [0.75, 1.25, -0.25, 0.5, -3], 'id1' => [1, 0, 1, 0, 1], 'id2' => [0, 1, 1, 0, 1]}],
	  opt => {'id_vars' => ['id1', 'id2'], 'value_vars' => ['A', 'B']},
	  shape => 'hoa',
	  exp => {'id1' => [1, 0, 1, 0, 1, 1, 0, 1, 0, 1], 'id2' => [0, 1, 1, 0, 1, 0, 1, 1, 0, 1], 'variable' => ['A', 'A', 'A', 'A', 'A', 'B', 'B', 'B', 'B', 'B'], 'value' => [0.5, -1.25, 2, -0.75, 1.5, -0.5, 0.25, 1.75, -2, 0.125]} },
	{ kind => 'melt', name => 'test_custom_var_name', src => 'test_melt.py::test_custom_var_name',
	  in => [[{'A' => 0.5, 'B' => -0.5, 'C' => 1, 'D' => 0.75, 'id1' => 1, 'id2' => 0}, {'A' => -1.25, 'B' => 0.25, 'C' => 0, 'D' => 1.25, 'id1' => 0, 'id2' => 1}, {'A' => 2, 'B' => 1.75, 'C' => -1, 'D' => -0.25, 'id1' => 1, 'id2' => 1}, {'A' => -0.75, 'B' => -2, 'C' => 2.5, 'D' => 0.5, 'id1' => 0, 'id2' => 0}, {'A' => 1.5, 'B' => 0.125, 'C' => 3.5, 'D' => -3, 'id1' => 1, 'id2' => 1}]],
	  opt => {'id_vars' => ['id1', 'id2'], 'value_vars' => ['A', 'B'], 'var_name' => 'var'},
	  shape => 'aoh',
	  exp => [{'id1' => 1, 'id2' => 0, 'var' => 'A', 'value' => 0.5}, {'id1' => 0, 'id2' => 1, 'var' => 'A', 'value' => -1.25}, {'id1' => 1, 'id2' => 1, 'var' => 'A', 'value' => 2}, {'id1' => 0, 'id2' => 0, 'var' => 'A', 'value' => -0.75}, {'id1' => 1, 'id2' => 1, 'var' => 'A', 'value' => 1.5}, {'id1' => 1, 'id2' => 0, 'var' => 'B', 'value' => -0.5}, {'id1' => 0, 'id2' => 1, 'var' => 'B', 'value' => 0.25}, {'id1' => 1, 'id2' => 1, 'var' => 'B', 'value' => 1.75}, {'id1' => 0, 'id2' => 0, 'var' => 'B', 'value' => -2}, {'id1' => 1, 'id2' => 1, 'var' => 'B', 'value' => 0.125}] },
	{ kind => 'melt', name => 'test_custom_value_name', src => 'test_melt.py::test_custom_value_name',
	  in => [[{'A' => 0.5, 'B' => -0.5, 'C' => 1, 'D' => 0.75, 'id1' => 1, 'id2' => 0}, {'A' => -1.25, 'B' => 0.25, 'C' => 0, 'D' => 1.25, 'id1' => 0, 'id2' => 1}, {'A' => 2, 'B' => 1.75, 'C' => -1, 'D' => -0.25, 'id1' => 1, 'id2' => 1}, {'A' => -0.75, 'B' => -2, 'C' => 2.5, 'D' => 0.5, 'id1' => 0, 'id2' => 0}, {'A' => 1.5, 'B' => 0.125, 'C' => 3.5, 'D' => -3, 'id1' => 1, 'id2' => 1}]],
	  opt => {'id_vars' => ['id1', 'id2'], 'value_vars' => ['A', 'B'], 'value_name' => 'val'},
	  shape => 'aoh',
	  exp => [{'id1' => 1, 'id2' => 0, 'variable' => 'A', 'val' => 0.5}, {'id1' => 0, 'id2' => 1, 'variable' => 'A', 'val' => -1.25}, {'id1' => 1, 'id2' => 1, 'variable' => 'A', 'val' => 2}, {'id1' => 0, 'id2' => 0, 'variable' => 'A', 'val' => -0.75}, {'id1' => 1, 'id2' => 1, 'variable' => 'A', 'val' => 1.5}, {'id1' => 1, 'id2' => 0, 'variable' => 'B', 'val' => -0.5}, {'id1' => 0, 'id2' => 1, 'variable' => 'B', 'val' => 0.25}, {'id1' => 1, 'id2' => 1, 'variable' => 'B', 'val' => 1.75}, {'id1' => 0, 'id2' => 0, 'variable' => 'B', 'val' => -2}, {'id1' => 1, 'id2' => 1, 'variable' => 'B', 'val' => 0.125}] },
	{ kind => 'melt', name => 'test_custom_var_and_value_name', src => 'test_melt.py::test_custom_var_and_value_name',
	  in => [{'A' => [0.5, -1.25, 2, -0.75, 1.5], 'B' => [-0.5, 0.25, 1.75, -2, 0.125], 'C' => [1, 0, -1, 2.5, 3.5], 'D' => [0.75, 1.25, -0.25, 0.5, -3], 'id1' => [1, 0, 1, 0, 1], 'id2' => [0, 1, 1, 0, 1]}],
	  opt => {'id_vars' => ['id1', 'id2'], 'value_vars' => ['A', 'B'], 'var_name' => 'var', 'value_name' => 'val'},
	  shape => 'hoa',
	  exp => {'id1' => [1, 0, 1, 0, 1, 1, 0, 1, 0, 1], 'id2' => [0, 1, 1, 0, 1, 0, 1, 1, 0, 1], 'var' => ['A', 'A', 'A', 'A', 'A', 'B', 'B', 'B', 'B', 'B'], 'val' => [0.5, -1.25, 2, -0.75, 1.5, -0.5, 0.25, 1.75, -2, 0.125]} },
	{ kind => 'melt', name => 'no id_vars, value_vars subset', src => 'test_melt.py::test_method_signatures',
	  in => [[{'A' => 0.5, 'B' => -0.5, 'C' => 1, 'D' => 0.75, 'id1' => 1, 'id2' => 0}, {'A' => -1.25, 'B' => 0.25, 'C' => 0, 'D' => 1.25, 'id1' => 0, 'id2' => 1}, {'A' => 2, 'B' => 1.75, 'C' => -1, 'D' => -0.25, 'id1' => 1, 'id2' => 1}, {'A' => -0.75, 'B' => -2, 'C' => 2.5, 'D' => 0.5, 'id1' => 0, 'id2' => 0}, {'A' => 1.5, 'B' => 0.125, 'C' => 3.5, 'D' => -3, 'id1' => 1, 'id2' => 1}]],
	  opt => {'value_vars' => ['C', 'D']},
	  shape => 'aoh',
	  exp => [{'variable' => 'C', 'value' => 1}, {'variable' => 'C', 'value' => 0}, {'variable' => 'C', 'value' => -1}, {'variable' => 'C', 'value' => 2.5}, {'variable' => 'C', 'value' => 3.5}, {'variable' => 'D', 'value' => 0.75}, {'variable' => 'D', 'value' => 1.25}, {'variable' => 'D', 'value' => -0.25}, {'variable' => 'D', 'value' => 0.5}, {'variable' => 'D', 'value' => -3}] },
	{ kind => 'melt', name => 'value_vars in reverse order', src => 'test_melt.py::test_value_vars',
	  in => [[{'A' => 0.5, 'B' => -0.5, 'C' => 1, 'D' => 0.75, 'id1' => 1, 'id2' => 0}, {'A' => -1.25, 'B' => 0.25, 'C' => 0, 'D' => 1.25, 'id1' => 0, 'id2' => 1}, {'A' => 2, 'B' => 1.75, 'C' => -1, 'D' => -0.25, 'id1' => 1, 'id2' => 1}, {'A' => -0.75, 'B' => -2, 'C' => 2.5, 'D' => 0.5, 'id1' => 0, 'id2' => 0}, {'A' => 1.5, 'B' => 0.125, 'C' => 3.5, 'D' => -3, 'id1' => 1, 'id2' => 1}]],
	  opt => {'id_vars' => ['id1'], 'value_vars' => ['D', 'A']},
	  shape => 'aoh',
	  exp => [{'id1' => 1, 'variable' => 'D', 'value' => 0.75}, {'id1' => 0, 'variable' => 'D', 'value' => 1.25}, {'id1' => 1, 'variable' => 'D', 'value' => -0.25}, {'id1' => 0, 'variable' => 'D', 'value' => 0.5}, {'id1' => 1, 'variable' => 'D', 'value' => -3}, {'id1' => 1, 'variable' => 'A', 'value' => 0.5}, {'id1' => 0, 'variable' => 'A', 'value' => -1.25}, {'id1' => 1, 'variable' => 'A', 'value' => 2}, {'id1' => 0, 'variable' => 'A', 'value' => -0.75}, {'id1' => 1, 'variable' => 'A', 'value' => 1.5}] },
	{ kind => 'melt', name => 'test_melt_mixed_int_str_id_vars', src => 'test_melt.py::test_melt_mixed_int_str_id_vars',
	  in => [{'0' => ['foo'], 'a' => ['bar'], 'b' => [1], 'd' => [2]}],
	  opt => {'id_vars' => ['0', 'a'], 'value_vars' => ['b', 'd']},
	  shape => 'hoa',
	  exp => {'0' => ['foo', 'foo'], 'a' => ['bar', 'bar'], 'variable' => ['b', 'd'], 'value' => [1, 2]} },
	{ kind => 'melt', name => 'test_melt_mixed_int_str_value_vars', src => 'test_melt.py::test_melt_mixed_int_str_value_vars',
	  in => [{'0' => ['foo'], 'a' => ['bar']}],
	  opt => {'value_vars' => ['0', 'a']},
	  shape => 'hoa',
	  exp => {'variable' => [0, 'a'], 'value' => ['foo', 'bar']} },
	{ kind => 'melt', name => 'NA cells', src => 'DataFrame.melt',
	  in => [[{'id' => 'x', 'p' => 1.5, 'q' => undef}, {'id' => 'y', 'p' => undef, 'q' => 4.5}, {'id' => 'z', 'p' => 2.5, 'q' => 5.5}]],
	  opt => {'id_vars' => 'id'},
	  shape => 'aoh',
	  exp => [{'id' => 'x', 'variable' => 'p', 'value' => 1.5}, {'id' => 'y', 'variable' => 'p', 'value' => undef}, {'id' => 'z', 'variable' => 'p', 'value' => 2.5}, {'id' => 'x', 'variable' => 'q', 'value' => undef}, {'id' => 'y', 'variable' => 'q', 'value' => 4.5}, {'id' => 'z', 'variable' => 'q', 'value' => 5.5}] },
	{ kind => 'melt', name => 'DataFrame.melt docstring: id A, value B', src => 'pandas/core/frame.py DataFrame.melt Examples',
	  in => [{'A' => ['a', 'b', 'c'], 'B' => [1, 3, 5], 'C' => [2, 4, 6]}],
	  opt => {'id_vars' => ['A'], 'value_vars' => ['B']},
	  shape => 'hoa',
	  exp => {'A' => ['a', 'b', 'c'], 'variable' => ['B', 'B', 'B'], 'value' => [1, 3, 5]} },
	{ kind => 'melt', name => 'DataFrame.melt docstring: id A, value B,C', src => 'pandas/core/frame.py DataFrame.melt Examples',
	  in => [{'A' => ['a', 'b', 'c'], 'B' => [1, 3, 5], 'C' => [2, 4, 6]}],
	  opt => {'id_vars' => ['A'], 'value_vars' => ['B', 'C']},
	  shape => 'hoa',
	  exp => {'A' => ['a', 'b', 'c', 'a', 'b', 'c'], 'variable' => ['B', 'B', 'B', 'C', 'C', 'C'], 'value' => [1, 3, 5, 2, 4, 6]} },
	{ kind => 'melt', name => 'DataFrame.melt docstring: custom names', src => 'pandas/core/frame.py DataFrame.melt Examples',
	  in => [{'A' => ['a', 'b', 'c'], 'B' => [1, 3, 5], 'C' => [2, 4, 6]}],
	  opt => {'id_vars' => ['A'], 'value_vars' => ['B'], 'var_name' => 'myVarname', 'value_name' => 'myValname'},
	  shape => 'hoa',
	  exp => {'A' => ['a', 'b', 'c'], 'myVarname' => ['B', 'B', 'B'], 'myValname' => [1, 3, 5]} },
	{ kind => 'melt', name => 'HoH input, ignore_index', src => 'test_melt.py::test_ignore_index',
	  in => [{'r0' => {'A' => 'a', 'B' => 1, 'C' => 2}, 'r1' => {'A' => 'b', 'B' => 3, 'C' => 4}, 'r2' => {'A' => 'c', 'B' => 5, 'C' => 6}}],
	  opt => {'id_vars' => ['A']},
	  shape => 'aoh',
	  exp => [{'A' => 'a', 'variable' => 'B', 'value' => 1}, {'A' => 'b', 'variable' => 'B', 'value' => 3}, {'A' => 'c', 'variable' => 'B', 'value' => 5}, {'A' => 'a', 'variable' => 'C', 'value' => 2}, {'A' => 'b', 'variable' => 'C', 'value' => 4}, {'A' => 'c', 'variable' => 'C', 'value' => 6}] },
	{ kind => 'melt', name => 'value_vars repeated', src => 'DataFrame.melt (observed on pandas 3.0.4)',
	  in => [{'A' => ['a', 'b', 'c'], 'B' => [1, 3, 5], 'C' => [2, 4, 6]}],
	  opt => {'id_vars' => ['A'], 'value_vars' => ['B', 'B']},
	  shape => 'hoa',
	  exp => {'A' => ['a', 'b', 'c'], 'variable' => ['B', 'B', 'B'], 'value' => [1, 3, 5]} },
	{ kind => 'pivot', name => 'test_pivot_table_multiple: default mean', src => 'test_pivot.py::test_pivot_table_multiple',
	  in => [{'A' => ['foo', 'foo', 'foo', 'foo', 'foo', 'bar', 'bar', 'bar', 'bar', 'foo', 'foo'], 'B' => ['one', 'one', 'one', 'two', 'one', 'one', 'one', 'two', 'two', 'two', 'one'], 'C' => ['dull', 'dull', 'shiny', 'dull', 'dull', 'shiny', 'shiny', 'dull', 'shiny', 'shiny', 'shiny'], 'D' => [0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30], 'E' => [1, 4, 7, 10, 13, 16, 19, 22, 25, 28, 31], 'F' => [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32]}],
	  opt => {'index' => ['A', 'B'], 'columns' => 'C'},
	  shape => 'aoh',
	  exp => [{'A' => 'bar', 'B' => 'one', 'D.dull' => undef, 'D.shiny' => 16.5, 'E.dull' => undef, 'E.shiny' => 17.5, 'F.dull' => undef, 'F.shiny' => 18.5}, {'A' => 'bar', 'B' => 'two', 'D.dull' => 21, 'D.shiny' => 24, 'E.dull' => 22, 'E.shiny' => 25, 'F.dull' => 23, 'F.shiny' => 26}, {'A' => 'foo', 'B' => 'one', 'D.dull' => 5, 'D.shiny' => 18, 'E.dull' => 6, 'E.shiny' => 19, 'F.dull' => 7, 'F.shiny' => 20}, {'A' => 'foo', 'B' => 'two', 'D.dull' => 9, 'D.shiny' => 27, 'E.dull' => 10, 'E.shiny' => 28, 'F.dull' => 11, 'F.shiny' => 29}] },
	{ kind => 'pivot', name => 'test_margins_dtype (no margins): sum fill 0', src => 'test_pivot.py::test_margins_dtype',
	  in => [{'A' => ['foo', 'foo', 'foo', 'foo', 'foo', 'bar', 'bar', 'bar', 'bar', 'foo', 'foo'], 'B' => ['one', 'one', 'one', 'two', 'one', 'one', 'one', 'two', 'two', 'two', 'one'], 'C' => ['dull', 'dull', 'shiny', 'dull', 'dull', 'shiny', 'shiny', 'dull', 'shiny', 'shiny', 'shiny'], 'D' => [0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30], 'E' => [1, 4, 7, 10, 13, 16, 19, 22, 25, 28, 31], 'F' => [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32]}],
	  opt => {'values' => 'D', 'index' => ['A', 'B'], 'columns' => 'C', 'aggfunc' => 'sum', 'fill_value' => 0},
	  shape => 'aoh',
	  exp => [{'A' => 'bar', 'B' => 'one', 'dull' => 0, 'shiny' => 33}, {'A' => 'bar', 'B' => 'two', 'dull' => 21, 'shiny' => 24}, {'A' => 'foo', 'B' => 'one', 'dull' => 15, 'shiny' => 36}, {'A' => 'foo', 'B' => 'two', 'dull' => 9, 'shiny' => 27}] },
	{ kind => 'pivot', name => 'test_margins_dtype_len (no margins): count', src => 'test_pivot.py::test_margins_dtype_len',
	  in => [{'A' => ['foo', 'foo', 'foo', 'foo', 'foo', 'bar', 'bar', 'bar', 'bar', 'foo', 'foo'], 'B' => ['one', 'one', 'one', 'two', 'one', 'one', 'one', 'two', 'two', 'two', 'one'], 'C' => ['dull', 'dull', 'shiny', 'dull', 'dull', 'shiny', 'shiny', 'dull', 'shiny', 'shiny', 'shiny'], 'D' => [0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30], 'E' => [1, 4, 7, 10, 13, 16, 19, 22, 25, 28, 31], 'F' => [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32]}],
	  opt => {'values' => 'D', 'index' => ['A', 'B'], 'columns' => 'C', 'aggfunc' => 'count', 'fill_value' => 0},
	  shape => 'aoh',
	  exp => [{'A' => 'bar', 'B' => 'one', 'dull' => 0, 'shiny' => 2}, {'A' => 'bar', 'B' => 'two', 'dull' => 1, 'shiny' => 1}, {'A' => 'foo', 'B' => 'one', 'dull' => 3, 'shiny' => 2}, {'A' => 'foo', 'B' => 'two', 'dull' => 1, 'shiny' => 1}] },
	{ kind => 'pivot', name => 'test_pivot_multi_values', src => 'test_pivot.py::test_pivot_multi_values',
	  in => [{'A' => ['foo', 'foo', 'foo', 'foo', 'foo', 'bar', 'bar', 'bar', 'bar', 'foo', 'foo'], 'B' => ['one', 'one', 'one', 'two', 'one', 'one', 'one', 'two', 'two', 'two', 'one'], 'C' => ['dull', 'dull', 'shiny', 'dull', 'dull', 'shiny', 'shiny', 'dull', 'shiny', 'shiny', 'shiny'], 'D' => [0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30], 'E' => [1, 4, 7, 10, 13, 16, 19, 22, 25, 28, 31], 'F' => [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32]}],
	  opt => {'values' => ['D', 'E'], 'index' => 'A', 'columns' => ['B', 'C'], 'fill_value' => 0},
	  shape => 'aoh',
	  exp => [{'A' => 'bar', 'D.one.dull' => 0, 'D.one.shiny' => 16.5, 'D.two.dull' => 21, 'D.two.shiny' => 24, 'E.one.dull' => 0, 'E.one.shiny' => 17.5, 'E.two.dull' => 22, 'E.two.shiny' => 25}, {'A' => 'foo', 'D.one.dull' => 5, 'D.one.shiny' => 18, 'D.two.dull' => 9, 'D.two.shiny' => 27, 'E.one.dull' => 6, 'E.one.shiny' => 19, 'E.two.dull' => 10, 'E.two.shiny' => 28}] },
	{ kind => 'pivot', name => 'test_pivot_multi_values HoA input, default values', src => 'test_pivot.py::test_pivot_multi_values',
	  in => [{'A' => ['foo', 'foo', 'foo', 'foo', 'foo', 'bar', 'bar', 'bar', 'bar', 'foo', 'foo'], 'B' => ['one', 'one', 'one', 'two', 'one', 'one', 'one', 'two', 'two', 'two', 'one'], 'C' => ['dull', 'dull', 'shiny', 'dull', 'dull', 'shiny', 'shiny', 'dull', 'shiny', 'shiny', 'shiny'], 'D' => [0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30], 'E' => [1, 4, 7, 10, 13, 16, 19, 22, 25, 28, 31], 'F' => [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32]}],
	  opt => {'index' => 'A', 'columns' => ['B', 'C'], 'fill_value' => 0},
	  shape => 'hoa',
	  exp => {'A' => ['bar', 'foo'], 'D.one.dull' => [0, 5], 'D.one.shiny' => [16.5, 18], 'D.two.dull' => [21, 9], 'D.two.shiny' => [24, 27], 'E.one.dull' => [0, 6], 'E.one.shiny' => [17.5, 19], 'E.two.dull' => [22, 10], 'E.two.shiny' => [25, 28], 'F.one.dull' => [0, 7], 'F.one.shiny' => [18.5, 20], 'F.two.dull' => [23, 11], 'F.two.shiny' => [26, 29]} },
	{ kind => 'pivot', name => 'test_pivot_multi_functions mean,std', src => 'test_pivot.py::test_pivot_multi_functions',
	  in => [{'A' => ['foo', 'foo', 'foo', 'foo', 'foo', 'bar', 'bar', 'bar', 'bar', 'foo', 'foo'], 'B' => ['one', 'one', 'one', 'two', 'one', 'one', 'one', 'two', 'two', 'two', 'one'], 'C' => ['dull', 'dull', 'shiny', 'dull', 'dull', 'shiny', 'shiny', 'dull', 'shiny', 'shiny', 'shiny'], 'D' => [0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30], 'E' => [1, 4, 7, 10, 13, 16, 19, 22, 25, 28, 31], 'F' => [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32]}],
	  opt => {'values' => ['D', 'E'], 'index' => ['A', 'B'], 'columns' => 'C', 'aggfunc' => ['mean', 'sd']},
	  shape => 'aoh',
	  exp => [{'A' => 'bar', 'B' => 'one', 'mean.D.dull' => undef, 'mean.D.shiny' => 16.5, 'mean.E.dull' => undef, 'mean.E.shiny' => 17.5, 'sd.D.dull' => undef, 'sd.D.shiny' => 2.1213203435596424, 'sd.E.dull' => undef, 'sd.E.shiny' => 2.1213203435596424}, {'A' => 'bar', 'B' => 'two', 'mean.D.dull' => 21, 'mean.D.shiny' => 24, 'mean.E.dull' => 22, 'mean.E.shiny' => 25, 'sd.D.dull' => undef, 'sd.D.shiny' => undef, 'sd.E.dull' => undef, 'sd.E.shiny' => undef}, {'A' => 'foo', 'B' => 'one', 'mean.D.dull' => 5, 'mean.D.shiny' => 18, 'mean.E.dull' => 6, 'mean.E.shiny' => 19, 'sd.D.dull' => 6.244997998398398, 'sd.D.shiny' => 16.97056274847714, 'sd.E.dull' => 6.244997998398398, 'sd.E.shiny' => 16.97056274847714}, {'A' => 'foo', 'B' => 'two', 'mean.D.dull' => 9, 'mean.D.shiny' => 27, 'mean.E.dull' => 10, 'mean.E.shiny' => 28, 'sd.D.dull' => undef, 'sd.D.shiny' => undef, 'sd.E.dull' => undef, 'sd.E.shiny' => undef}] },
	{ kind => 'pivot', name => 'test_pivot_string_func_vs_func: min', src => 'test_pivot.py::test_pivot_string_func_vs_func',
	  in => [{'A' => ['foo', 'foo', 'foo', 'foo', 'foo', 'bar', 'bar', 'bar', 'bar', 'foo', 'foo'], 'B' => ['one', 'one', 'one', 'two', 'one', 'one', 'one', 'two', 'two', 'two', 'one'], 'C' => ['dull', 'dull', 'shiny', 'dull', 'dull', 'shiny', 'shiny', 'dull', 'shiny', 'shiny', 'shiny'], 'D' => [0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30], 'E' => [1, 4, 7, 10, 13, 16, 19, 22, 25, 28, 31], 'F' => [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32]}],
	  opt => {'values' => 'D', 'index' => 'A', 'columns' => 'C', 'aggfunc' => 'min'},
	  shape => 'aoh',
	  exp => [{'A' => 'bar', 'dull' => 21, 'shiny' => 15}, {'A' => 'foo', 'dull' => 0, 'shiny' => 6}] },
	{ kind => 'pivot', name => 'test_pivot_string_func_vs_func: max', src => 'test_pivot.py::test_pivot_string_func_vs_func',
	  in => [{'A' => ['foo', 'foo', 'foo', 'foo', 'foo', 'bar', 'bar', 'bar', 'bar', 'foo', 'foo'], 'B' => ['one', 'one', 'one', 'two', 'one', 'one', 'one', 'two', 'two', 'two', 'one'], 'C' => ['dull', 'dull', 'shiny', 'dull', 'dull', 'shiny', 'shiny', 'dull', 'shiny', 'shiny', 'shiny'], 'D' => [0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30], 'E' => [1, 4, 7, 10, 13, 16, 19, 22, 25, 28, 31], 'F' => [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32]}],
	  opt => {'values' => 'D', 'index' => 'A', 'columns' => 'C', 'aggfunc' => 'max'},
	  shape => 'aoh',
	  exp => [{'A' => 'bar', 'dull' => 21, 'shiny' => 24}, {'A' => 'foo', 'dull' => 12, 'shiny' => 30}] },
	{ kind => 'pivot', name => 'test_pivot_string_func_vs_func: median', src => 'test_pivot.py::test_pivot_string_func_vs_func',
	  in => [{'A' => ['foo', 'foo', 'foo', 'foo', 'foo', 'bar', 'bar', 'bar', 'bar', 'foo', 'foo'], 'B' => ['one', 'one', 'one', 'two', 'one', 'one', 'one', 'two', 'two', 'two', 'one'], 'C' => ['dull', 'dull', 'shiny', 'dull', 'dull', 'shiny', 'shiny', 'dull', 'shiny', 'shiny', 'shiny'], 'D' => [0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30], 'E' => [1, 4, 7, 10, 13, 16, 19, 22, 25, 28, 31], 'F' => [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32]}],
	  opt => {'values' => 'D', 'index' => 'A', 'columns' => 'C', 'aggfunc' => 'median'},
	  shape => 'aoh',
	  exp => [{'A' => 'bar', 'dull' => 21, 'shiny' => 18}, {'A' => 'foo', 'dull' => 6, 'shiny' => 27}] },
	{ kind => 'pivot', name => 'test_pivot_string_func_vs_func: first', src => 'test_pivot.py::test_pivot_string_func_vs_func',
	  in => [{'A' => ['foo', 'foo', 'foo', 'foo', 'foo', 'bar', 'bar', 'bar', 'bar', 'foo', 'foo'], 'B' => ['one', 'one', 'one', 'two', 'one', 'one', 'one', 'two', 'two', 'two', 'one'], 'C' => ['dull', 'dull', 'shiny', 'dull', 'dull', 'shiny', 'shiny', 'dull', 'shiny', 'shiny', 'shiny'], 'D' => [0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30], 'E' => [1, 4, 7, 10, 13, 16, 19, 22, 25, 28, 31], 'F' => [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32]}],
	  opt => {'values' => 'D', 'index' => 'A', 'columns' => 'C', 'aggfunc' => 'first'},
	  shape => 'aoh',
	  exp => [{'A' => 'bar', 'dull' => 21, 'shiny' => 15}, {'A' => 'foo', 'dull' => 0, 'shiny' => 6}] },
	{ kind => 'pivot', name => 'test_pivot_string_func_vs_func: last', src => 'test_pivot.py::test_pivot_string_func_vs_func',
	  in => [{'A' => ['foo', 'foo', 'foo', 'foo', 'foo', 'bar', 'bar', 'bar', 'bar', 'foo', 'foo'], 'B' => ['one', 'one', 'one', 'two', 'one', 'one', 'one', 'two', 'two', 'two', 'one'], 'C' => ['dull', 'dull', 'shiny', 'dull', 'dull', 'shiny', 'shiny', 'dull', 'shiny', 'shiny', 'shiny'], 'D' => [0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30], 'E' => [1, 4, 7, 10, 13, 16, 19, 22, 25, 28, 31], 'F' => [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32]}],
	  opt => {'values' => 'D', 'index' => 'A', 'columns' => 'C', 'aggfunc' => 'last'},
	  shape => 'aoh',
	  exp => [{'A' => 'bar', 'dull' => 21, 'shiny' => 24}, {'A' => 'foo', 'dull' => 12, 'shiny' => 30}] },
	{ kind => 'pivot', name => 'test_pivot_string_func_vs_func: nunique', src => 'test_pivot.py::test_pivot_string_func_vs_func',
	  in => [{'A' => ['foo', 'foo', 'foo', 'foo', 'foo', 'bar', 'bar', 'bar', 'bar', 'foo', 'foo'], 'B' => ['one', 'one', 'one', 'two', 'one', 'one', 'one', 'two', 'two', 'two', 'one'], 'C' => ['dull', 'dull', 'shiny', 'dull', 'dull', 'shiny', 'shiny', 'dull', 'shiny', 'shiny', 'shiny'], 'D' => [0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30], 'E' => [1, 4, 7, 10, 13, 16, 19, 22, 25, 28, 31], 'F' => [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32]}],
	  opt => {'values' => 'D', 'index' => 'A', 'columns' => 'C', 'aggfunc' => 'nunique'},
	  shape => 'aoh',
	  exp => [{'A' => 'bar', 'dull' => 1, 'shiny' => 3}, {'A' => 'foo', 'dull' => 4, 'shiny' => 3}] },
	{ kind => 'pivot', name => 'test_pivot_string_func_vs_func: var', src => 'test_pivot.py::test_pivot_string_func_vs_func',
	  in => [{'A' => ['foo', 'foo', 'foo', 'foo', 'foo', 'bar', 'bar', 'bar', 'bar', 'foo', 'foo'], 'B' => ['one', 'one', 'one', 'two', 'one', 'one', 'one', 'two', 'two', 'two', 'one'], 'C' => ['dull', 'dull', 'shiny', 'dull', 'dull', 'shiny', 'shiny', 'dull', 'shiny', 'shiny', 'shiny'], 'D' => [0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30], 'E' => [1, 4, 7, 10, 13, 16, 19, 22, 25, 28, 31], 'F' => [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32]}],
	  opt => {'values' => 'D', 'index' => 'A', 'columns' => 'C', 'aggfunc' => 'var'},
	  shape => 'aoh',
	  exp => [{'A' => 'bar', 'dull' => undef, 'shiny' => 21}, {'A' => 'foo', 'dull' => 30, 'shiny' => 171}] },
	{ kind => 'pivot', name => 'test_pivot_string_func_vs_func: sd', src => 'test_pivot.py::test_pivot_string_func_vs_func',
	  in => [{'A' => ['foo', 'foo', 'foo', 'foo', 'foo', 'bar', 'bar', 'bar', 'bar', 'foo', 'foo'], 'B' => ['one', 'one', 'one', 'two', 'one', 'one', 'one', 'two', 'two', 'two', 'one'], 'C' => ['dull', 'dull', 'shiny', 'dull', 'dull', 'shiny', 'shiny', 'dull', 'shiny', 'shiny', 'shiny'], 'D' => [0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30], 'E' => [1, 4, 7, 10, 13, 16, 19, 22, 25, 28, 31], 'F' => [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32]}],
	  opt => {'values' => 'D', 'index' => 'A', 'columns' => 'C', 'aggfunc' => 'sd'},
	  shape => 'aoh',
	  exp => [{'A' => 'bar', 'dull' => undef, 'shiny' => 4.58257569495584}, {'A' => 'foo', 'dull' => 5.477225575051661, 'shiny' => 13.076696830622021}] },
	{ kind => 'pivot', name => 'test_pivot_string_func_vs_func: sum', src => 'test_pivot.py::test_pivot_string_func_vs_func',
	  in => [{'A' => ['foo', 'foo', 'foo', 'foo', 'foo', 'bar', 'bar', 'bar', 'bar', 'foo', 'foo'], 'B' => ['one', 'one', 'one', 'two', 'one', 'one', 'one', 'two', 'two', 'two', 'one'], 'C' => ['dull', 'dull', 'shiny', 'dull', 'dull', 'shiny', 'shiny', 'dull', 'shiny', 'shiny', 'shiny'], 'D' => [0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30], 'E' => [1, 4, 7, 10, 13, 16, 19, 22, 25, 28, 31], 'F' => [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32]}],
	  opt => {'values' => 'D', 'index' => 'A', 'columns' => 'C', 'aggfunc' => 'sum'},
	  shape => 'aoh',
	  exp => [{'A' => 'bar', 'dull' => 21, 'shiny' => 57}, {'A' => 'foo', 'dull' => 24, 'shiny' => 63}] },
	{ kind => 'pivot', name => 'test_pivot_string_func_vs_func: mean', src => 'test_pivot.py::test_pivot_string_func_vs_func',
	  in => [{'A' => ['foo', 'foo', 'foo', 'foo', 'foo', 'bar', 'bar', 'bar', 'bar', 'foo', 'foo'], 'B' => ['one', 'one', 'one', 'two', 'one', 'one', 'one', 'two', 'two', 'two', 'one'], 'C' => ['dull', 'dull', 'shiny', 'dull', 'dull', 'shiny', 'shiny', 'dull', 'shiny', 'shiny', 'shiny'], 'D' => [0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30], 'E' => [1, 4, 7, 10, 13, 16, 19, 22, 25, 28, 31], 'F' => [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32]}],
	  opt => {'values' => 'D', 'index' => 'A', 'columns' => 'C', 'aggfunc' => 'mean'},
	  shape => 'aoh',
	  exp => [{'A' => 'bar', 'dull' => 21, 'shiny' => 19}, {'A' => 'foo', 'dull' => 6, 'shiny' => 21}] },
	{ kind => 'pivot', name => 'test_pivot_string_func_vs_func: count', src => 'test_pivot.py::test_pivot_string_func_vs_func',
	  in => [{'A' => ['foo', 'foo', 'foo', 'foo', 'foo', 'bar', 'bar', 'bar', 'bar', 'foo', 'foo'], 'B' => ['one', 'one', 'one', 'two', 'one', 'one', 'one', 'two', 'two', 'two', 'one'], 'C' => ['dull', 'dull', 'shiny', 'dull', 'dull', 'shiny', 'shiny', 'dull', 'shiny', 'shiny', 'shiny'], 'D' => [0, 3, 6, 9, 12, 15, 18, 21, 24, 27, 30], 'E' => [1, 4, 7, 10, 13, 16, 19, 22, 25, 28, 31], 'F' => [2, 5, 8, 11, 14, 17, 20, 23, 26, 29, 32]}],
	  opt => {'values' => 'D', 'index' => 'A', 'columns' => 'C', 'aggfunc' => 'count'},
	  shape => 'aoh',
	  exp => [{'A' => 'bar', 'dull' => 1, 'shiny' => 3}, {'A' => 'foo', 'dull' => 4, 'shiny' => 3}] },
	{ kind => 'pivot', name => 'AoH input', src => 'test_pivot.py::test_pivot_table',
	  in => [[{'A' => 'foo', 'B' => 'one', 'C' => 'dull', 'D' => 0, 'E' => 1, 'F' => 2}, {'A' => 'foo', 'B' => 'one', 'C' => 'dull', 'D' => 3, 'E' => 4, 'F' => 5}, {'A' => 'foo', 'B' => 'one', 'C' => 'shiny', 'D' => 6, 'E' => 7, 'F' => 8}, {'A' => 'foo', 'B' => 'two', 'C' => 'dull', 'D' => 9, 'E' => 10, 'F' => 11}, {'A' => 'foo', 'B' => 'one', 'C' => 'dull', 'D' => 12, 'E' => 13, 'F' => 14}, {'A' => 'bar', 'B' => 'one', 'C' => 'shiny', 'D' => 15, 'E' => 16, 'F' => 17}, {'A' => 'bar', 'B' => 'one', 'C' => 'shiny', 'D' => 18, 'E' => 19, 'F' => 20}, {'A' => 'bar', 'B' => 'two', 'C' => 'dull', 'D' => 21, 'E' => 22, 'F' => 23}, {'A' => 'bar', 'B' => 'two', 'C' => 'shiny', 'D' => 24, 'E' => 25, 'F' => 26}, {'A' => 'foo', 'B' => 'two', 'C' => 'shiny', 'D' => 27, 'E' => 28, 'F' => 29}, {'A' => 'foo', 'B' => 'one', 'C' => 'shiny', 'D' => 30, 'E' => 31, 'F' => 32}]],
	  opt => {'values' => 'D', 'index' => 'A', 'columns' => 'B', 'aggfunc' => 'sum', 'fill_value' => -1},
	  shape => 'aoh',
	  exp => [{'A' => 'bar', 'one' => 33, 'two' => 45}, {'A' => 'foo', 'one' => 51, 'two' => 36}] },
	{ kind => 'pivot', name => 'test_pivot_table_sort_false', src => 'test_pivot.py::test_pivot_table_sort_false',
	  in => [{'a' => ['d1', 'd4', 'd3'], 'col' => ['a', 'b', 'c'], 'num' => [23, 21, 34], 'year' => ['2018', '2018', '2019']}],
	  opt => {'index' => ['a', 'col'], 'columns' => 'year', 'values' => 'num', 'aggfunc' => 'sum', 'sort' => 0},
	  shape => 'aoh',
	  exp => [{'a' => 'd1', 'col' => 'a', '2018' => 23, '2019' => undef}, {'a' => 'd4', 'col' => 'b', '2018' => 21, '2019' => undef}, {'a' => 'd3', 'col' => 'c', '2018' => undef, '2019' => 34}] },
	{ kind => 'pivot', name => 'test_pivot_table_sort_false: sort=True', src => 'test_pivot.py::test_pivot_table_sort_false',
	  in => [{'a' => ['d1', 'd4', 'd3'], 'col' => ['a', 'b', 'c'], 'num' => [23, 21, 34], 'year' => ['2018', '2018', '2019']}],
	  opt => {'index' => ['a', 'col'], 'columns' => 'year', 'values' => 'num', 'aggfunc' => 'sum'},
	  shape => 'aoh',
	  exp => [{'a' => 'd1', 'col' => 'a', '2018' => 23, '2019' => undef}, {'a' => 'd3', 'col' => 'c', '2018' => undef, '2019' => 34}, {'a' => 'd4', 'col' => 'b', '2018' => 21, '2019' => undef}] },
	{ kind => 'pivot', name => 'test_pivot_table_dropna: columns customer,product', src => 'test_pivot.py::test_pivot_table_dropna',
	  in => [{'amount' => [60000, 100000, 50000, 30000], 'customer' => ['A', 'A', 'B', 'C'], 'month' => [201307, 201309, 201308, 201310], 'product' => ['a', 'b', 'c', 'd'], 'quantity' => [2000000, 500000, 1000000, 1000000]}],
	  opt => {'values' => 'quantity', 'index' => 'month', 'columns' => ['customer', 'product']},
	  shape => 'aoh',
	  exp => [{'month' => 201307, 'A.a' => 2000000, 'A.b' => undef, 'B.c' => undef, 'C.d' => undef}, {'month' => 201308, 'A.a' => undef, 'A.b' => undef, 'B.c' => 1000000, 'C.d' => undef}, {'month' => 201309, 'A.a' => undef, 'A.b' => 500000, 'B.c' => undef, 'C.d' => undef}, {'month' => 201310, 'A.a' => undef, 'A.b' => undef, 'B.c' => undef, 'C.d' => 1000000}] },
	{ kind => 'pivot_cells', name => 'test_pivot_table_aggfunc_scalar_dropna dropna=True', src => 'test_pivot.py::test_pivot_table_aggfunc_scalar_dropna',
	  in => [{'A' => ['one', 'two', 'one'], 'x' => [3, undef, 2], 'y' => [1, undef, undef]}],
	  opt => {'columns' => 'A', 'aggfunc' => 'mean'},
	  shape => 'aoh',
	  exp => [{'x.one' => 2.5, 'y.one' => 1}] },
	{ kind => 'pivot_cells', name => 'test_pivot_table_aggfunc_scalar_dropna dropna=False', src => 'test_pivot.py::test_pivot_table_aggfunc_scalar_dropna',
	  in => [{'A' => ['one', 'two', 'one'], 'x' => [3, undef, 2], 'y' => [1, undef, undef]}],
	  opt => {'columns' => 'A', 'aggfunc' => 'mean'},
	  shape => 'aoh',
	  exp => [{'x.one' => 2.5, 'x.two' => undef, 'y.one' => 1, 'y.two' => undef}] },
	{ kind => 'pivot_cells', name => 'test_pivot_table_aggfunc_dropna (sum)', src => 'test_pivot.py::test_pivot_table_aggfunc_dropna',
	  in => [{'fruit' => ['apple', 'peach', 'apple'], 'size' => [1, 1, 2], 'taste' => [7, 6, 6]}],
	  opt => {'columns' => 'fruit', 'aggfunc' => 'sum'},
	  shape => 'aoh',
	  exp => [{'size.apple' => 3, 'size.peach' => 1, 'taste.apple' => 13, 'taste.peach' => 6}] },
	{ kind => 'pivot_cells', name => 'test_pivot_table_nocols', src => 'test_pivot.py::test_pivot_table_nocols',
	  in => [{'cols' => ['x', 'y', 'z'], 'values' => [1, 2, 3]}],
	  opt => {'columns' => 'cols', 'aggfunc' => 'sum', 'values' => 'values'},
	  shape => 'aoh',
	  exp => [{'x' => 1, 'y' => 2, 'z' => 3}] },
	{ kind => 'pivot', name => 'test_pivot_table_index_and_column_keys_with_nan dropna=True', src => 'test_pivot.py::test_pivot_table_index_and_column_keys_with_nan',
	  in => [{'row' => [undef, 0, 1, 2, 3], 'col' => [0, 1, 2, 3, undef], 'val' => [0, 1, 2, 3, 4]}],
	  opt => {'values' => 'val', 'index' => 'row', 'columns' => 'col'},
	  shape => 'aoh',
	  exp => [{'row' => 0, '1' => 1, '2' => undef, '3' => undef}, {'row' => 1, '1' => undef, '2' => 2, '3' => undef}, {'row' => 2, '1' => undef, '2' => undef, '3' => 3}] },
	{ kind => 'pivot', name => 'test_pivot_table_index_and_column_keys_with_nan dropna=False', src => 'test_pivot.py::test_pivot_table_index_and_column_keys_with_nan',
	  in => [{'row' => [undef, 0, 1, 2, 3], 'col' => [0, 1, 2, 3, undef], 'val' => [0, 1, 2, 3, 4]}],
	  opt => {'values' => 'val', 'index' => 'row', 'columns' => 'col'},
	  shape => 'aoh',
	  exp => [{'row' => 0, '0' => undef, '1' => 1, '2' => undef, '3' => undef, 'undef' => undef}, {'row' => 1, '0' => undef, '1' => undef, '2' => 2, '3' => undef, 'undef' => undef}, {'row' => 2, '0' => undef, '1' => undef, '2' => undef, '3' => 3, 'undef' => undef}, {'row' => 3, '0' => undef, '1' => undef, '2' => undef, '3' => undef, 'undef' => 4}, {'row' => undef, '0' => 0, '1' => undef, '2' => undef, '3' => undef, 'undef' => undef}] },
	{ kind => 'pivot', name => 'test_pivot_table_aggfunc_nunique_with_different_values (flat names)', src => 'test_pivot.py::test_pivot_table_aggfunc_nunique_with_different_values',
	  in => [{'a' => [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], 'b' => [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], 'c' => [0, 1, 2, 3, 4, 5, 6, 7, 8, 9], 'd' => [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]}],
	  opt => {'index' => ['a'], 'columns' => ['b'], 'values' => ['c'], 'aggfunc' => ['nunique']},
	  shape => 'aoh',
	  exp => [{'a' => 0, '0' => 1, '1' => undef, '2' => undef, '3' => undef, '4' => undef, '5' => undef, '6' => undef, '7' => undef, '8' => undef, '9' => undef}, {'a' => 1, '0' => undef, '1' => 1, '2' => undef, '3' => undef, '4' => undef, '5' => undef, '6' => undef, '7' => undef, '8' => undef, '9' => undef}, {'a' => 2, '0' => undef, '1' => undef, '2' => 1, '3' => undef, '4' => undef, '5' => undef, '6' => undef, '7' => undef, '8' => undef, '9' => undef}, {'a' => 3, '0' => undef, '1' => undef, '2' => undef, '3' => 1, '4' => undef, '5' => undef, '6' => undef, '7' => undef, '8' => undef, '9' => undef}, {'a' => 4, '0' => undef, '1' => undef, '2' => undef, '3' => undef, '4' => 1, '5' => undef, '6' => undef, '7' => undef, '8' => undef, '9' => undef}, {'a' => 5, '0' => undef, '1' => undef, '2' => undef, '3' => undef, '4' => undef, '5' => 1, '6' => undef, '7' => undef, '8' => undef, '9' => undef}, {'a' => 6, '0' => undef, '1' => undef, '2' => undef, '3' => undef, '4' => undef, '5' => undef, '6' => 1, '7' => undef, '8' => undef, '9' => undef}, {'a' => 7, '0' => undef, '1' => undef, '2' => undef, '3' => undef, '4' => undef, '5' => undef, '6' => undef, '7' => 1, '8' => undef, '9' => undef}, {'a' => 8, '0' => undef, '1' => undef, '2' => undef, '3' => undef, '4' => undef, '5' => undef, '6' => undef, '7' => undef, '8' => 1, '9' => undef}, {'a' => 9, '0' => undef, '1' => undef, '2' => undef, '3' => undef, '4' => undef, '5' => undef, '6' => undef, '7' => undef, '8' => undef, '9' => 1}] },
	{ kind => 'pivot_aoa', name => 'test_pivot_table_with_margins_and_numeric_columns (AoA, no margins)', src => 'test_pivot.py::test_pivot_table_with_margins_and_numeric_columns',
	  in => [[['a', 'x', 1], ['a', 'y', 2], ['b', 'y', 3], ['b', 'z', 4]]],
	  opt => {'index' => 0, 'columns' => 1, 'values' => 2, 'aggfunc' => 'sum'},
	  shape => 'aoh',
	  exp => [{'10' => 'a', 'x' => 1, 'y' => 2, 'z' => undef}, {'10' => 'b', 'x' => undef, 'y' => 3, 'z' => 4}] },
);
my @TRANSPOSE = (
	{ name => 'test_transpose_mixed (HoH)', src => 'frame/methods/test_transpose.py::test_transpose_mixed', in => {'a' => {'A' => 0, 'B' => 0, 'C' => 'foo1'}, 'b' => {'A' => 1, 'B' => 1, 'C' => 'foo2'}, 'c' => {'A' => 2, 'B' => 0, 'C' => 'foo3'}, 'd' => {'A' => 3, 'B' => 1, 'C' => 'foo4'}, 'e' => {'A' => 4, 'B' => 0, 'C' => 'foo5'}}, exp => {'A' => {'a' => 0, 'b' => 1, 'c' => 2, 'd' => 3, 'e' => 4}, 'B' => {'a' => 0, 'b' => 1, 'c' => 0, 'd' => 1, 'e' => 0}, 'C' => {'a' => 'foo1', 'b' => 'foo2', 'c' => 'foo3', 'd' => 'foo4', 'e' => 'foo5'}} },
	{ name => 'test_transpose_float (HoH, NaN as undef)', src => 'frame/methods/test_transpose.py::test_transpose_float', in => {'x' => {'A' => 0.5, 'B' => undef}, 'y' => {'A' => undef, 'B' => 1.5}, 'z' => {'A' => 2.25, 'B' => 3.125}}, exp => {'A' => {'x' => 0.5, 'y' => undef, 'z' => 2.25}, 'B' => {'x' => undef, 'y' => 1.5, 'z' => 3.125}} },
	{ name => 'DataFrame([[1,2,3],[4,5,6]]).T (AoA)', src => 'DataFrame.T', in => [[1, 2, 3], [4, 5, 6]], exp => [[1, 4], [2, 5], [3, 6]] },
	{ name => '3x2 AoA with a missing cell', src => 'DataFrame.T', in => [[1, undef], [3, 4], [5, 6]], exp => [[1, 3, 5], [undef, 4, 6]] },
);
my @ASSIGN = (
	{ name => 'test_assign: C = B / A', src => 'frame/methods/test_assign.py::test_assign', expr => 'B/A', col => 'C', in => {'A' => [1, 2, 3], 'B' => [4, 5, 6]}, exp => {'A' => [1, 2, 3], 'B' => [4, 5, 6], 'C' => [4, 2.5, 2]} },
	{ name => 'test_assign: B = B / A (overwrite)', src => 'frame/methods/test_assign.py::test_assign', expr => 'B/A', col => 'B', in => {'A' => [1, 2, 3], 'B' => [4, 5, 6]}, exp => {'A' => [1, 2, 3], 'B' => [4, 2.5, 2]} },
	{ name => 'test_assign: A = A + B (overwrite)', src => 'frame/methods/test_assign.py::test_assign', expr => 'A+B', col => 'A', in => {'A' => [1, 2, 3], 'B' => [4, 5, 6]}, exp => {'A' => [5, 7, 9], 'B' => [4, 5, 6]} },
	{ name => 'test_assign: non-Series array-like', src => 'frame/methods/test_assign.py::test_assign', vals => [4, 2.5, 2], col => 'C', in => {'A' => [1, 2, 3], 'B' => [4, 5, 6]}, exp => {'A' => [1, 2, 3], 'B' => [4, 5, 6], 'C' => [4, 2.5, 2]} },
	{ name => 'test_assign_multiple (AoH)', src => 'frame/methods/test_assign.py::test_assign_multiple', multi => 1, in => [{'A' => 1, 'B' => 4}, {'A' => 2, 'B' => 5}, {'A' => 3, 'B' => 6}], exp => [{'A' => 1, 'B' => 4, 'C' => 7, 'D' => 1, 'E' => 4}, {'A' => 2, 'B' => 5, 'C' => 8, 'D' => 2, 'E' => 5}, {'A' => 3, 'B' => 6, 'C' => 9, 'D' => 3, 'E' => 6}] },
	{ name => 'test_assign_order (AoH)', src => 'frame/methods/test_assign.py::test_assign_order', order => 1, in => [{'A' => 1, 'B' => 2}, {'A' => 3, 'B' => 4}], exp => [{'A' => 1, 'B' => 2, 'D' => 3, 'C' => -1}, {'A' => 3, 'B' => 4, 'D' => 7, 'C' => -1}] },
	{ name => 'test_assign_dependent (HoA)', src => 'frame/methods/test_assign.py::test_assign_dependent', dep => 1, in => {'A' => [1, 2], 'B' => [3, 4]}, exp => {'A' => [1, 2], 'B' => [3, 4], 'C' => [1, 2], 'D' => [2, 4]} },
	{ name => 'test_assign_dependent (HoH)', src => 'frame/methods/test_assign.py::test_assign_dependent', dep => 1, in => {'r1' => {'A' => 1, 'B' => 3}, 'r2' => {'A' => 2, 'B' => 4}}, exp => {'r1' => {'A' => 1, 'B' => 3, 'C' => 1, 'D' => 2}, 'r2' => {'A' => 2, 'B' => 4, 'C' => 2, 'D' => 4}} },
);
# END pandas cases

# BEGIN R cases (generated by t/frame_reshape.R.pandas.R)
my @RCASES = (
	{ name => 'PR#8868 permuted columns (HoA)', src => 'reg-tests-2.R:1853', shape => 'hoa',
	  in => [{'x' => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 'y' => ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j'], 'z' => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]}, {'y' => ['A', 'B', 'C', 'D', 'E'], 'z' => [5, 4, 3, 2, 1], 'x' => [7, 8, 9, 10, 11]}],
	  exp => {'x' => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 7, 8, 9, 10, 11], 'y' => ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'A', 'B', 'C', 'D', 'E'], 'z' => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 5, 4, 3, 2, 1]} },
	{ name => 'PR#8868 permuted columns (AoH)', src => 'reg-tests-2.R:1853', shape => 'aoh',
	  in => [[{'x' => 1, 'y' => 'a', 'z' => 1}, {'x' => 2, 'y' => 'b', 'z' => 2}, {'x' => 3, 'y' => 'c', 'z' => 3}, {'x' => 4, 'y' => 'd', 'z' => 4}, {'x' => 5, 'y' => 'e', 'z' => 5}, {'x' => 6, 'y' => 'f', 'z' => 6}, {'x' => 7, 'y' => 'g', 'z' => 7}, {'x' => 8, 'y' => 'h', 'z' => 8}, {'x' => 9, 'y' => 'i', 'z' => 9}, {'x' => 10, 'y' => 'j', 'z' => 10}], [{'y' => 'A', 'z' => 5, 'x' => 7}, {'y' => 'B', 'z' => 4, 'x' => 8}, {'y' => 'C', 'z' => 3, 'x' => 9}, {'y' => 'D', 'z' => 2, 'x' => 10}, {'y' => 'E', 'z' => 1, 'x' => 11}]],
	  exp => [{'x' => 1, 'y' => 'a', 'z' => 1}, {'x' => 2, 'y' => 'b', 'z' => 2}, {'x' => 3, 'y' => 'c', 'z' => 3}, {'x' => 4, 'y' => 'd', 'z' => 4}, {'x' => 5, 'y' => 'e', 'z' => 5}, {'x' => 6, 'y' => 'f', 'z' => 6}, {'x' => 7, 'y' => 'g', 'z' => 7}, {'x' => 8, 'y' => 'h', 'z' => 8}, {'x' => 9, 'y' => 'i', 'z' => 9}, {'x' => 10, 'y' => 'j', 'z' => 10}, {'x' => 7, 'y' => 'A', 'z' => 5}, {'x' => 8, 'y' => 'B', 'z' => 4}, {'x' => 9, 'y' => 'C', 'z' => 3}, {'x' => 10, 'y' => 'D', 'z' => 2}, {'x' => 11, 'y' => 'E', 'z' => 1}] },
	{ name => 'cbind.Rd rbind(df, new)', src => 'cbind.Rd examples', shape => 'hoa',
	  in => [{'a' => [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1], 'B' => ['a', 'a', 'a', 'a', 'b', 'b', 'b', 'b', 'c', 'c', 'c', 'c'], 'f' => ['1', '1', '1', '2', '2', '2', '3', '3', '3', '4', '4', '4']}, {'a' => [8], 'B' => ['B'], 'f' => ['1']}],
	  exp => {'a' => [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 8], 'B' => ['a', 'a', 'a', 'a', 'b', 'b', 'b', 'b', 'c', 'c', 'c', 'c', 'B'], 'f' => ['1', '1', '1', '2', '2', '2', '3', '3', '3', '4', '4', '4', '1']} },
	{ name => 'rbind(d, d.0) == d', src => 'reg-tests-2.R:73', shape => 'hoa',
	  in => [{'x' => [1, 1, 1, 1, 1], 'y' => [1, 2, 3, 4, 5], 'fac' => ['C', 'C', 'C', 'B', 'C']}, {'x' => [], 'y' => [], 'fac' => []}],
	  exp => {'x' => [1, 1, 1, 1, 1], 'y' => [1, 2, 3, 4, 5], 'fac' => ['C', 'C', 'C', 'B', 'C']} },
	{ name => 'rbind(d.0, d) == d', src => 'reg-tests-2.R:74', shape => 'hoa',
	  in => [{'x' => [], 'y' => [], 'fac' => []}, {'x' => [1, 1, 1, 1, 1], 'y' => [1, 2, 3, 4, 5], 'fac' => ['C', 'C', 'C', 'B', 'C']}],
	  exp => {'x' => [1, 1, 1, 1, 1], 'y' => [1, 2, 3, 4, 5], 'fac' => ['C', 'C', 'C', 'B', 'C']} },
	{ name => 'rbind(d00, d) == d (zero-column frame is {})', src => 'reg-tests-2.R:75', shape => 'hoa',
	  in => [[], {'x' => [1, 1, 1, 1, 1], 'y' => [1, 2, 3, 4, 5], 'fac' => ['C', 'C', 'C', 'B', 'C']}],
	  exp => {'x' => [1, 1, 1, 1, 1], 'y' => [1, 2, 3, 4, 5], 'fac' => ['C', 'C', 'C', 'B', 'C']} },
	{ name => 'rbind(d, d00) == d', src => 'reg-tests-2.R:76', shape => 'hoa',
	  in => [{'x' => [1, 1, 1, 1, 1], 'y' => [1, 2, 3, 4, 5], 'fac' => ['C', 'C', 'C', 'B', 'C']}, []],
	  exp => {'x' => [1, 1, 1, 1, 1], 'y' => [1, 2, 3, 4, 5], 'fac' => ['C', 'C', 'C', 'B', 'C']} },
	{ name => 'smart row names (HoH)', src => 'reg-tests-1c.R:1249', shape => 'hoh',
	  in => [{'3' => {'x' => 3}, '4' => {'x' => 4}}, {'1' => {'x' => 1}, '2' => {'x' => 2}}],
	  exp => {'3' => {'x' => 3}, '4' => {'x' => 4}, '1' => {'x' => 1}, '2' => {'x' => 2}} },
	{ name => 'repeated row name (R: r, r1)', src => 'rbind.data.frame; observed on R 4.6.2', shape => 'hoh',
	  in => [{'r' => {'v' => 1}}, {'r' => {'v' => 2}}],
	  exp => {'r' => {'v' => 1}, 'r1' => {'v' => 2}} },
	{ name => 'PR#2266 data frame + matrix (AoA)', src => 'reg-tests-2.R:740', shape => 'aoa',
	  in => [[[1, 6, 11, 16, 21], [2, 7, 12, 17, 22], [3, 8, 13, 18, 23], [4, 9, 14, 19, 24], [5, 10, 15, 20, 25]], [[-1, -3, -5, -7, -9], [-2, -4, -6, -8, -10]]],
	  exp => [[1, 6, 11, 16, 21], [2, 7, 12, 17, 22], [3, 8, 13, 18, 23], [4, 9, 14, 19, 24], [5, 10, 15, 20, 25], [-1, -3, -5, -7, -9], [-2, -4, -6, -8, -10]] },
);
my @RT = (
	{ name => 't.Rd matrix(1:30, 5, 6)', src => 't.Rd examples', in => [[1, 6, 11, 16, 21, 26], [2, 7, 12, 17, 22, 27], [3, 8, 13, 18, 23, 28], [4, 9, 14, 19, 24, 29], [5, 10, 15, 20, 25, 30]], exp => [[1, 2, 3, 4, 5], [6, 7, 8, 9, 10], [11, 12, 13, 14, 15], [16, 17, 18, 19, 20], [21, 22, 23, 24, 25], [26, 27, 28, 29, 30]] },
	{ name => 't(data.frame) with row names (HoH)', src => 't.data.frame', in => {'r1' => {'a' => 1, 'b' => 1.5}, 'r2' => {'a' => 2, 'b' => 2.5}}, exp => {'a' => {'r1' => 1, 'r2' => 2}, 'b' => {'r1' => 1.5, 'r2' => 2.5}} },
);
# END R cases

my $warned;
local $SIG{__WARN__} = sub { $warned .= $_[0] };

#--------
# concat / rbind: pandas and R cases
#--------
for my $c (grep { $_->{kind} eq 'concat' } @PANDAS) {
	my $r = eval { concat(map { clone($_) } @{ $c->{in} }) };
	is($@ ? "died: $@" : frame_diff($r, $c->{exp}, $c->{shape}, 0), '', "concat, pandas $c->{src}: $c->{name}");
	my $r2 = eval { rbind(map { clone($_) } @{ $c->{in} }) };
	is($@ ? "died: $@" : frame_diff($r2, $c->{exp}, $c->{shape}, 0), '', "rbind, pandas $c->{src}: $c->{name}");
}
for my $c (@RCASES) {
	my $name = $c->{name};
	if ($name =~ /repeated row name/) {
		# README pins name.1; R's rbind() gives name1 (a deliberate difference)
		my $r = concat(map { clone($_) } @{ $c->{in} });
		is_deeply([ sort keys %$r ], [ 'r', 'r.1' ], "concat, README: a repeated HoH row name becomes r.1");
		is($r->{'r.1'}{v}, 2, 'concat, README: the later row keeps its data under r.1');
		like(frame_diff($r, $c->{exp}, $c->{shape}, 0), qr/unexpected row 'r\.1'/,
			"concat, R $c->{src}: $name -- deliberate difference, R has r1");
		next;
	}
	my $r = eval { concat(map { clone($_) } @{ $c->{in} }) };
	is($@ ? "died: $@" : frame_diff($r, $c->{exp}, $c->{shape}, 0), '', "concat, R $c->{src}: $name");
	my $r2 = eval { rbind(map { clone($_) } @{ $c->{in} }) };
	is($@ ? "died: $@" : frame_diff($r2, $c->{exp}, $c->{shape}, 0), '', "rbind, R $c->{src}: $name");
}
ok(\&Stats::LikeR::rbind == \&Stats::LikeR::concat, 'README: rbind is the same code reference as concat');

#--------
# concat: documented edges
#--------
is_deeply(concat(undef, [], [ { n => 1 } ], [ { n => 2 } ]), [ { n => 1 }, { n => 2 } ], 'README: undef and empty frames are skipped');
is_deeply(concat([], []), [], 'README: all-empty arrayrefs give []');
is_deeply(concat({}, {}), {}, 'README: all-empty hashrefs give {}');
{
	my $one = [ { a => 1 } ];
	my $c = concat($one);
	is_deeply($c, $one, 'README: a single frame round-trips');
	isnt($c, $one, 'README: a single frame comes back as a new array');
}
is_deeply(concat([ [1, 2], [3, 4] ], [ [5, 6], [7] ]), [ [1, 2], [3, 4], [5, 6], [7] ], 'README: AoA keeps ragged rows');
is_deeply(concat({ g => ['a', 'a'], v => [1, 2] }, { g => ['b'], w => [9] }),
	{ g => ['a', 'a', 'b'], v => [1, 2, undef], w => [undef, undef, 9] }, 'README: HoA union, padded with undef');
is_deeply(concat({ a => [1, 2], b => [3] }, { a => [4] }),
	{ a => [1, 2, 4], b => [3, undef, undef] }, 'README: a short HoA column is padded to the row count');
throws_ok { concat([ { a => 1 } ], { a => [1] }) } qr/cannot mix a (?:AoH|HoA) frame with a (?:HoA|AoH) frame/, 'README: mixed shapes die';
throws_ok { concat() } qr/needs at least one data frame/, 'README: no frame dies';
throws_ok { concat([ { a => 1 } ], 5) } qr/./, 'README: a non-reference frame dies';
{
	my $a = [ { id => 1, x => 10 } ];
	my $b = [ { id => 2, x => 20, y => 99 } ];
	concat($a, $b);
	is_deeply($a, [ { id => 1, x => 10 } ], 'README: the original frames are not modified');
}
{
	# three frames: a real 'r.1' keeps its name whichever frame holds it
	local $SIG{__WARN__} = sub { };
	my $h = concat({ r => { v => 1 } }, { s => { v => 2 } }, { r => { v => 3 } }, { s => { v => 4 } }, { 'r.1' => { v => 5 } });
	is_deeply([ sort keys %$h ], [ qw(r r.1 r.2 s s.1) ], 'concat: HoH suffixes across five frames');
	is($h->{'r.1'}{v}, 5, 'concat: the real r.1 row keeps its data');
}
# pandas: DataFrame({'a': 1, 'b': 2}) raises "If using all scalar values, you must
# pass an index"; a hash of scalars is no frame, and must not become empty columns
throws_ok { concat({ a => 1, b => 2 }, { a => 3 }) } qr/\Aconcat: HoA column 'a' is not an ARRAY ref\n\z/, 'a hash of scalars is not a data frame (pandas ValueError); concat() returned {a=>[],b=>[]}';

#--------
# melt: pandas
#--------
for my $c (grep { $_->{kind} eq 'melt' } @PANDAS) {
	my %opt = %{ clone($c->{opt}) };
	$opt{output_type} = $c->{shape};
	my $r = eval { melt(clone($c->{in}[0]), %opt) };
	is($@ ? "died: $@" : frame_diff($r, $c->{exp}, $c->{shape}, 0), '', "melt, pandas $c->{src}: $c->{name}");
}
{
	my $df = [ { A => 'a', B => 1, C => 2 }, { A => 'b', B => 3, C => 4 } ];
	my $r = melt($df, id_vars => 'A');
	is_deeply($r, [ { A => 'a', variable => 'B', value => 1 }, { A => 'b', variable => 'B', value => 3 },
		{ A => 'a', variable => 'C', value => 2 }, { A => 'b', variable => 'C', value => 4 } ], 'README: melt is column-major');
	is_deeply($df, [ { A => 'a', B => 1, C => 2 }, { A => 'b', B => 3, C => 4 } ], 'README: melt does not change its input');
	my $h = melt($df, id_vars => 'A', output_type => 'hoh');
	is_deeply([ sort { $a <=> $b } keys %$h ], [0 .. 3], 'README: HoH melt output is labelled 0..N-1');
	is_deeply(melt([ ['a', 1, 2], ['b', 3, 4] ], id_vars => 0), [ ['a', 1, 1], ['b', 1, 3], ['a', 2, 2], ['b', 2, 4] ],
		'README: AoA melt names columns by position');
}
# test_melt_missing_columns_raises (GH-23575): KeyError for an absent column
{
	my $df = [ { a => 1, b => 2, c => 3, d => 4 } ];
	throws_ok { melt($df, id_vars => ['a', 'b'], value_vars => ['C', 'd']) } qr/column 'C' not found/, 'pandas test_melt_missing_columns_raises: bad value_vars';
	throws_ok { melt($df, id_vars => ['A', 'b'], value_vars => ['c', 'd']) } qr/column 'A' not found/, 'pandas test_melt_missing_columns_raises: bad id_vars';
	throws_ok { melt($df, id_vars => ['a', 'b', 'not_here', 'or_there'], value_vars => ['c', 'd']) } qr/not found/, 'pandas test_melt_missing_columns_raises: several absent';
	throws_ok { melt($df, id_vars => 'a', var_name => 'x', value_name => 'x') } qr/var_name and value_name must differ/, 'README: var_name equal to value_name dies (pandas keeps both)';
	throws_ok { melt($df, id_vars => 'a', var_name => 'a') } qr/collides with an id_vars column/, 'README: var_name colliding with an id var dies (pandas keeps both)';
	throws_ok { melt(undef) } qr/./, 'README: undefined data dies';
}

#--------
# pivot_table: pandas
#--------
# The pandas cases whose answer pivot_table() deliberately does not give (see
# the header): each maps to the frame the README promises instead, which is
# pinned, and the pandas frame is checked to still differ from it.
my %PIVOT_DIFF = (
	'test_pivot_table_aggfunc_scalar_dropna dropna=True' => [
		[ { 'x.one' => 2.5, 'x.two' => undef, 'y.one' => 1, 'y.two' => undef } ],
		'an all-NA output column is kept as undef cells' ],
	'test_pivot_table_index_and_column_keys_with_nan dropna=True' => [
		[ { row => 0,     0 => undef, 1 => 1,     2 => undef, 3 => undef },
		  { row => 1,     0 => undef, 1 => undef, 2 => 2,     3 => undef },
		  { row => 2,     0 => undef, 1 => undef, 2 => undef, 3 => 3     },
		  { row => undef, 0 => 0,     1 => undef, 2 => undef, 3 => undef } ],
		'an NA index key is a row, sorted last; an NA columns key is skipped' ],
);
$PIVOT_DIFF{'test_pivot_table_index_and_column_keys_with_nan dropna=False'}
	= $PIVOT_DIFF{'test_pivot_table_index_and_column_keys_with_nan dropna=True'};
for my $c (grep { $_->{kind} =~ /^pivot/ } @PANDAS) {
	my %opt = %{ clone($c->{opt}) };
	$opt{output_type} = 'aoh';
	$opt{output_type} = $c->{shape} if $c->{shape} eq 'hoa';
	my $strict = 1;
	my $exp = clone($c->{exp});
	if ($c->{kind} eq 'pivot_aoa') { # AoA positions: the pandas label 10 is column 0
		for my $row (@$exp) { $row->{0} = delete $row->{10} if exists $row->{10} }
	}
	my $r = eval { pivot_table(clone($c->{in}[0]), %opt) };
	if (my $d = $PIVOT_DIFF{$c->{name}}) {
		is($@ ? "died: $@" : frame_diff($r, $d->[0], $opt{output_type}, $strict), '',
			"pivot_table, pandas $c->{src}: $c->{name} -- README: $d->[1]");
		isnt($@ ? "died: $@" : frame_diff($r, $exp, $opt{output_type}, $strict), '',
			"pivot_table, pandas $c->{src}: $c->{name} -- still differs from pandas");
		next;
	}
	is($@ ? "died: $@" : frame_diff($r, $exp, $opt{output_type}, $strict), '', "pivot_table, pandas $c->{src}: $c->{name}");
}
# test_pivot_table_no_column_raises (GH 10326): KeyError for an absent values column
throws_ok { pivot_table({ X => [0, 0, 1, 1], Y => [0, 1, 0, 1], Z => [10, 20, 30, 40] }, index => 'X', columns => 'Y', values => 'notpresent') }
	qr/notpresent/, 'pandas test_pivot_table_no_column_raises: absent values column';
throws_ok { pivot_table({ X => [0, 1] }, index => 'X') } qr/./, 'README: columns is required';
# test_pivot_table_empty_aggfunc (GH 9186): an all-NA columns key leaves no column
{
	my $r = pivot_table({ A => [2, 2, 3, 3, 2], id => [5 .. 9], C => [qw(p q q p q)], D => [(undef) x 5] },
		index => 'A', columns => 'D', values => 'id', aggfunc => 'count');
	is_deeply($r, { A => [] }, 'pandas test_pivot_table_empty_aggfunc: no columns, no rows');
}
# README example
{
	my $df = [ { city => 'NY', year => 2020, temp => 10 }, { city => 'NY', year => 2020, temp => 20 },
		{ city => 'NY', year => 2021, temp => 30 }, { city => 'LA', year => 2020, temp => 40 } ];
	is_deeply(pivot_table($df, index => 'city', columns => 'year', values => 'temp'),
		[ { city => 'LA', 2020 => 40, 2021 => undef }, { city => 'NY', 2020 => 15, 2021 => 30 } ], 'README pivot_table example');
	my $r = pivot_table($df, index => 'city', columns => 'year', values => 'temp', aggfunc => ['count', 'sum']);
	is_deeply([ sort keys %{ $r->[0] } ], [ sort qw(city count.2020 count.2021 sum.2020 sum.2021) ], 'README: aggfunc-major generated names');
}
# HoH input (the outer key is a row name, not a column)
is_deeply(pivot_table({ r => { a => 1, b => 'x', v => 3 }, s => { a => 1, b => 'y', v => 4 } }, index => 'a', columns => 'b', values => 'v', output_type => 'aoh'),
	[ { a => 1, x => 3, y => 4 } ], 'pivot_table: HoH input');

#--------
# transpose
#--------
for my $c (grep { $_->{kind} eq 'transpose' } @PANDAS) { } # (none; see @TRANSPOSE)
for my $c (@TRANSPOSE, @RT) {
	my $shape = ref $c->{in} eq 'ARRAY' ? 'aoa' : 'hoh';
	my $r = eval { transpose(clone($c->{in})) };
	is($@ ? "died: $@" : frame_diff($r, $c->{exp}, $shape, 1), '', "transpose, $c->{src}: $c->{name}");
	my $back = eval { transpose(transpose(clone($c->{in}))) };
	is($@ ? "died: $@" : frame_diff($back, $c->{in}, $shape, 1), '', "transpose twice returns the frame, $c->{name}");
}
is_deeply(transpose([ [1, undef], [3, 4] ]), [ [1, 3], [undef, 4] ], 'README: undef is preserved');
is_deeply(transpose([]), [], 'README: an empty outer array gives []');
is_deeply(transpose([ [], [] ]), [], 'README: an array of empty rows gives []');
is_deeply(transpose({}), {}, 'README: an empty hash gives {}');
is_deeply(transpose({ a => {}, b => {} }), {}, 'README: a HoH of empty rows gives {}');
is_deeply(transpose([ [1, 2, 3] ]), [ [1], [2], [3] ], 'transpose: 1 x 3');
is_deeply(transpose([ [1], [2], [3] ]), [ [1, 2, 3] ], 'transpose: 3 x 1');
is_deeply(transpose({ a => { x => 1, y => 2 }, b => { x => 3, z => 4 } }),
	{ x => { a => 1, b => 3 }, y => { a => 2 }, z => { b => 4 } }, 'README: a sparse HoH is not padded (pandas pads with NaN)');
throws_ok { transpose([ [1, 2], [3] ]) } qr/ragged/, 'README: a ragged AoA dies';
throws_ok { transpose([ 1, 2 ]) } qr/not an array ref/, 'README: a non-array row dies';
throws_ok { transpose({ a => [1, 2], b => [3, 4] }) } qr/not a hash ref/, 'README: a HoA is refused (R and pandas transpose it)';
{
	my $in = [ [1, 2], [3, 4] ];
	my $t = transpose($in);
	$t->[0][0] = 99;
	is($in->[0][0], 1, 'README: every cell of the result is a copy');
}

#--------
# assign
#--------
my %EXPR = (
	'B/A' => sub { $_->{B} / $_->{A} },
	'A+B' => sub { $_->{A} + $_->{B} },
);
for my $c (@ASSIGN) {
	my $df = clone($c->{in});
	my $shape = ref $df eq 'ARRAY' ? 'aoh' : (ref((values %$df)[0]) eq 'HASH' ? 'hoh' : 'hoa');
	if ($c->{expr}) {
		assign($df, $c->{col} => $EXPR{ $c->{expr} });
		is(frame_diff($df, $c->{exp}, $shape, 0), '', "assign, pandas $c->{src}: $c->{name} (coderef)");
		my $df2 = clone($c->{in});
		my @col = map { $c->{exp}{ $c->{col} }[$_] } 0 .. $#{ $c->{exp}{ $c->{col} } };
		assign($df2, $c->{col} => [@col]);
		is(frame_diff($df2, $c->{exp}, $shape, 0), '', "assign, pandas $c->{src}: $c->{name} (ready-made column)");
	} elsif ($c->{vals}) {
		assign($df, $c->{col} => [ @{ $c->{vals} } ]);
		is(frame_diff($df, $c->{exp}, $shape, 0), '', "assign, pandas $c->{src}: $c->{name}");
	} elsif ($c->{multi}) {
		assign($df, C => [7, 8, 9], D => sub { $_->{A} }, E => sub { $_->{B} });
		is(frame_diff($df, $c->{exp}, $shape, 0), '', "assign, pandas $c->{src}: $c->{name}");
	} elsif ($c->{order}) {
		assign($df, D => sub { $_->{A} + $_->{B} }, C => sub { $_->{A} - $_->{B} });
		is(frame_diff($df, $c->{exp}, $shape, 0), '', "assign, pandas $c->{src}: $c->{name}");
	} elsif ($c->{dep}) {
		assign($df, C => sub { $_->{A} }, D => sub { $_->{A} + $_->{C} });
		is(frame_diff($df, $c->{exp}, $shape, 0), '', "assign, pandas $c->{src}: $c->{name}");
	}
}
{
	# test_assign: "original is unmodified" holds for a copy only; assign() works in place
	my $df = { A => [1, 2, 3], B => [4, 5, 6] };
	my $r = assign($df, C => sub { $_->{B} / $_->{A} });
	is($r, $df, 'README: assign returns the frame it changed');
	ok(exists $df->{C}, 'README: assign changes its frame in place (pandas returns a new one)');
	my $orig = { A => [1, 2, 3], B => [4, 5, 6] };
	my $copy = clone($orig);
	assign($copy, C => [4, 2.5, 2]);
	is_deeply($orig, { A => [1, 2, 3], B => [4, 5, 6] }, 'test_assign: a copy leaves the original unmodified');
}
# test_assign_bad: a length mismatch dies (pandas ValueError)
throws_ok { assign({ A => [1, 2, 3] }, C => [1, 2]) } qr/has 2 values but data frame has 3 rows/, 'pandas length mismatch: arrayref of the wrong length dies';
# a coderef reading a column that does not exist
is_deeply(assign({ A => [1, 2] }, D => sub { $_->{Z} }), { A => [1, 2], D => [undef, undef] }, 'a column that does not exist reads as undef (pandas: AttributeError)');
# HoH: the arrayref is distributed in sorted key order (README)
is_deeply(assign({ r2 => { A => 2 }, r1 => { A => 1 } }, C => [10, 20]), { r1 => { A => 1, C => 10 }, r2 => { A => 2, C => 20 } }, 'README: HoH arrayref values follow sorted key order');

#--------
# leaks
#--------
{
	my $a = [ { id => 1, x => 10 } ];
	my $b = [ { id => 2, x => 20, y => 99 } ];
	no_leaks_ok { my $c = concat($a, $b) } 'concat(): AoH, no memory leaks' unless $INC{'Devel/Cover.pm'};
	my $m = [ { A => 'a', B => 1, C => 2 }, { A => 'b', B => 3, C => 4 } ];
	no_leaks_ok { my $c = melt($m, id_vars => 'A') } 'melt(): no memory leaks' unless $INC{'Devel/Cover.pm'};
	my $p = [ { c => 'NY', y => 2020, t => 10 }, { c => 'LA', y => 2021, t => 20 } ];
	no_leaks_ok { my $c = pivot_table($p, index => 'c', columns => 'y', values => 't') } 'pivot_table(): no memory leaks' unless $INC{'Devel/Cover.pm'};
	my $t = [ [1, 2, 3], [4, 5, 6] ];
	no_leaks_ok { my $c = transpose($t) } 'transpose(): no memory leaks' unless $INC{'Devel/Cover.pm'};
	no_leaks_ok { my $d = { A => [1, 2], B => [3, 4] }; assign($d, C => sub { $_->{A} + $_->{B} }) } 'assign(): no memory leaks' unless $INC{'Devel/Cover.pm'};
}

done_testing();
