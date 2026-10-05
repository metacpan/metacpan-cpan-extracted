#!/usr/bin/env perl
#
# Cross-validation of merge() against the two reference implementations, using
# their own test suites and documented examples rather than cases invented here.
# t/merge.t already covers the accepted call forms, a randomized plain-Perl
# reference join over every input/output shape, argument validation and leak
# checking; this file does not repeat those.
#
# Provenance of every expected value below:
#
#   * R 4.6.1 (2026-06-24) base::merge.data.frame -- the function merge() is
#     modelled on.  The frozen R table holds the examples in
#     src/library/base/man/merge.Rd (whose printed output is pinned in
#     tests/Examples/base-Ex.Rout.save) and R's own regression cases for merge:
#     tests/reg-tests-1a.R (PR#1510 by.x/by.y with multiple matches; the
#     Cartesian product that did not make column names unique in 2.3.0;
#     "merging when NA is a level"; the two character matrices that failed
#     pre-2.0.0; merge on zero-row data frames, not allowed <= 2.4.0),
#     tests/reg-tests-1b.R (the suffixes regressions from 2.15.0/2.15.1; the
#     SDMTools::compare.matrix two-column join; the zero-row `women` merges
#     that failed in 2.7.0), tests/reg-tests-1d.R (merge() names when by.y,
#     which gave a duplicated column in R <= 3.4.x) and tests/reg-tests-2.R
#     (the authors/books joins moved out of merge.Rd, and ggrothendieck's
#     all-columns-are-keys case that confused 1.4.1).
#   * pandas 2.2.3 DataFrame.merge -- the other implementation merge() follows.
#     The frozen pandas table holds cases from
#     pandas/tests/reshape/merge/test_merge.py (test_intelligently_handle_join_key
#     GH#733, test_merge_overlap, test_merge_different_column_key_names,
#     test_merge_same_order_left_right GH#35382, test_left_merge_empty_dataframe,
#     test_merge_empty GH#52777 in all ten parametrisations,
#     test_merge_on_ints_floats, test_merge_non_unique_index_many_to_many,
#     test_merge_suffix), test_merge_cross.py (all four cross-join tests, both
#     parametrisations of test_merge_cross) and test_multi.py
#     (test_merge_na_keys, test_merge_multiple_cols_with_mixed_cols_index
#     GH#29522).  Every one of those test functions is present unchanged in
#     pandas 3.0.4 as well, and the generator run against 3.0.4 prints a table
#     byte-identical to the 2.2.3 one, so nothing frozen here is specific to
#     either release.
#
# The two tables are generated, and the generators are committed next to this
# file: `Rscript t/merge.R.pandas.R` and `python3 t/merge.R.pandas.py` print the
# Perl literals to paste back over the BEGIN/END GENERATED blocks below.  The
# test itself never runs R or python and never needs either installed.
#
# Three things the generators normalise, so that a reference answer can be
# compared with a Stats::LikeR one at all -- each is explained where it happens
# in the generator, and each is checked here as a divergence at the end of the
# file rather than being hidden:
#
#   * A key cell that is undef.  Both references match NA to NA by default;
#     Stats::LikeR's rule is that such a row matches nothing, which is R's
#     `incomparables = NA` (merge.Rd: "DBMSes do not match NULL records").  The
#     frozen answers follow Stats::LikeR's rule; the references' default answers
#     are pinned in the divergence section.
#   * Two key columns vs one.  Under left_on/right_on pandas keeps both key
#     columns; R and Stats::LikeR keep one, under the left name, filled from
#     whichever side has the row.
#   * Suffixes.  pandas suffixes colliding non-key columns _x/_y, R and
#     Stats::LikeR .x/.y, so the pandas cases pass suffixes => ['_x','_y'].
#
# Every cell in both tables is an integer, a string or undef.  A non-integer
# double does not stringify the same on a double, a long-double and a
# __float128 perl (0.2 prints as "0.2" at 15 significant digits and
# "0.200000000000000011" at 18), merge() matches keys on the stringified cell,
# and this file compares cells as strings; the generators refuse to emit one.
# Double-valued keys are covered separately at the end, with dyadic literals,
# which every NV width represents exactly.
#
# There is no numeric tolerance anywhere in this file: a join either puts the
# same cells in the same rows as the reference or it does not.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;                  # dies_ok / throws_ok
use Stats::LikeR 'merge';

# Import no_leaks_ok at compile time so its (&;$) prototype is in scope for the
# block-style call at the end.  Absent module -> that one test is skipped.
my $HAVE_LEAKTRACE;
BEGIN {
	$HAVE_LEAKTRACE = eval {
		require Test::LeakTrace;
		Test::LeakTrace->import('no_leaks_ok');
		1;
	};
}

# ---------------------------------------------------------------- the harness

# A frozen frame is a list of column names plus a list of row value lists.
# build() turns one into whichever perl shape the case is being run in: an
# array of row hashes (AoH), a hash of column arrays (HoA), or a hash of row
# hashes (HoH, whose outer key is a row name and never a join key).
sub build {
	my ($shape, $cols, $rows) = @_;
	if ($shape eq 'hoa') {
		my %h;
		for my $j (0 .. $#$cols) {
			$h{ $cols->[$j] } = [ map { $_->[$j] } @$rows ];
		}
		return \%h;
	}
	my @aoh = map {
		my $r = $_;
		+{ map { ( $cols->[$_] => $r->[$_] ) } 0 .. $#$cols };
	} @$rows;
	return \@aoh if $shape eq 'aoh';
	my %hoh;
	$hoh{ 'row' . $_ } = $aoh[$_] for 0 .. $#aoh;
	return \%hoh;
}

# Canonical, order-independent signature of a result frame (AoH or HoA): a
# sorted multiset of "col=val|col=val" strings, one per row.  Row order is not
# part of what the references pin -- R sorts on the key columns by default and
# pandas does not -- so it is compared separately, further down.
sub sig {
	my $df = shift;
	if (ref $df eq 'HASH') {                 # HoA -> AoH
		my @cols = keys %$df;
		my $n = @cols ? scalar @{ $df->{ $cols[0] } } : 0;
		$df = [ map { my $i = $_; +{ map { $_ => $df->{$_}[$i] } @cols } }
		        0 .. $n - 1 ];
	}
	my @rows;
	for my $r (@$df) {
		push @rows, join '|',
		            map { "$_=" . (defined $r->{$_} ? $r->{$_} : 'UNDEF') }
		            sort keys %$r;
	}
	return join "\n", sort @rows;
}

# One frozen case, run through every input/output shape combination it applies
# to.  Two tests each: the cells, and the output column names -- which the
# signature alone would not pin for a join whose answer has no rows, and an
# empty answer is exactly what several of the reference cases are about.  The
# HoA output shape always carries every output column, rows or not.
sub check_case {
	my ($frames, $c) = @_;
	my $L = $frames->{ $c->{left} }  or die "no such frame '$c->{left}'";
	my $R = $frames->{ $c->{right} } or die "no such frame '$c->{right}'";
	my $want = sig(build('aoh', $c->{want_cols}, $c->{want_rows}));

	# An empty AoH or HoH carries no column names at all -- its rows are where
	# the names live -- so a case with an empty frame runs as HoA only, and
	# what the AoH form does instead is pinned under "empty frames" below.
	my @shapes = (($c->{shapes} || '') eq 'hoa') ? ('hoa')
	                                             : ('aoh', 'hoa', 'hoh');
	my $bad = '';
	SHAPE: for my $ls (@shapes) {
		for my $rs (@shapes) {
			for my $os (qw(aoh hoa)) {
				my $got = eval {
					merge(build($ls, $L->{cols}, $L->{rows}),
					      build($rs, $R->{cols}, $R->{rows}),
					      @{ $c->{args} }, 'output_type' => $os);
				};
				if (!defined $got) {
					$bad = "$ls + $rs -> $os died: $@";
					last SHAPE;
				}
				next if sig($got) eq $want;
				$bad = "$ls + $rs -> $os\ngot:\n" . sig($got)
				     . "\nwant:\n$want";
				last SHAPE;
			}
		}
	}
	is $bad, '', $c->{name};

	my $hoa = merge(build($shapes[0], $L->{cols}, $L->{rows}),
	                build($shapes[0], $R->{cols}, $R->{rows}),
	                @{ $c->{args} }, 'output_type' => 'hoa');
	is_deeply [ sort keys %$hoa ], [ sort @{ $c->{want_cols} } ],
		"$c->{name}: output columns";
}

# ------------------------------------------------ the frozen reference tables

# BEGIN GENERATED (R) -- Rscript t/merge.R.pandas.R
# 28 frames and 83 cases, from R 4.6.1
my %R_FRAMES = (
	'authors' => {
		cols => ['surname', 'nationality', 'deceased'],
		rows => [ ['Tukey', 'US', 'yes'],
		          ['Venables', 'Australia', 'no'],
		          ['Tierney', 'US', 'no'],
		          ['Ripley', 'UK', 'no'],
		          ['McNeil', 'Australia', 'no'],
		        ],
	},
	'authorN' => {
		cols => ['nationality', 'deceased', 'name'],
		rows => [ ['US', 'yes', 'Tukey'],
		          ['Australia', 'no', 'Venables'],
		          ['US', 'no', 'Tierney'],
		          ['UK', 'no', 'Ripley'],
		          ['Australia', 'no', 'McNeil'],
		        ],
	},
	'books' => {
		cols => ['name', 'title', 'other.author'],
		rows => [ ['Tukey', 'Exploratory Data Analysis', undef],
		          ['Venables', 'Modern Applied Statistics ...', 'Ripley'],
		          ['Tierney', 'LISP-STAT', undef],
		          ['Ripley', 'Spatial Statistics', undef],
		          ['Ripley', 'Stochastic Simulation', undef],
		          ['McNeil', 'Interactive Data Analysis', undef],
		          ['R Core', 'An Introduction to R', 'Venables & Smith'],
		        ],
	},
	'm1' => {
		cols => ['surname', 'nationality', 'deceased', 'title', 'other.author'],
		rows => [ ['McNeil', 'Australia', 'no', 'Interactive Data Analysis', undef],
		          ['Ripley', 'UK', 'no', 'Spatial Statistics', undef],
		          ['Ripley', 'UK', 'no', 'Stochastic Simulation', undef],
		          ['Tierney', 'US', 'no', 'LISP-STAT', undef],
		          ['Tukey', 'US', 'yes', 'Exploratory Data Analysis', undef],
		          ['Venables', 'Australia', 'no', 'Modern Applied Statistics ...', 'Ripley'],
		        ],
	},
	'm2' => {
		cols => ['name', 'title', 'other.author', 'nationality', 'deceased'],
		rows => [ ['McNeil', 'Interactive Data Analysis', undef, 'Australia', 'no'],
		          ['Ripley', 'Spatial Statistics', undef, 'UK', 'no'],
		          ['Ripley', 'Stochastic Simulation', undef, 'UK', 'no'],
		          ['Tierney', 'LISP-STAT', undef, 'US', 'no'],
		          ['Tukey', 'Exploratory Data Analysis', undef, 'US', 'yes'],
		          ['Venables', 'Modern Applied Statistics ...', 'Ripley', 'Australia', 'no'],
		        ],
	},
	'b2' => {
		cols => ['surname', 'title', 'other.author'],
		rows => [ ['Tukey', 'Exploratory Data Analysis', undef],
		          ['Venables', 'Modern Applied Statistics ...', 'Ripley'],
		          ['Tierney', 'LISP-STAT', undef],
		          ['Ripley', 'Spatial Statistics', undef],
		          ['Ripley', 'Stochastic Simulation', undef],
		          ['McNeil', 'Interactive Data Analysis', undef],
		          ['R Core', 'An Introduction to R', 'Venables & Smith'],
		        ],
	},
	'b2_R7' => {
		cols => ['surname', 'title', 'other.author'],
		rows => [ ['R Core', 'An Introduction to R', 'Venables & Smith'],
		        ],
	},
	'parents' => {
		cols => ['name', 'sex', 'age'],
		rows => [ ['Sarah', 'F', 41],
		          ['Max', 'M', 43],
		          ['Qin', 'F', 36],
		          ['Lex', 'M', 51],
		        ],
	},
	'children' => {
		cols => ['parent', 'name', 'sex', 'age'],
		rows => [ ['Sarah', 'Oliver', 'M', 5],
		          ['Max', 'Sebastian', 'M', 8],
		          ['Qin', 'Kai-lee', 'F', 7],
		        ],
	},
	'd.df' => {
		cols => ['x', 'y', 'z'],
		rows => [ [1, 'A', 6],
		          [2, 'D', 9],
		          [3, 'E', 10],
		        ],
	},
	'd.df_R1' => {
		cols => ['x', 'y', 'z'],
		rows => [ [1, 'A', 6],
		        ],
	},
	'na_lvl_a' => {
		cols => ['x'],
		rows => [ [1],
		          [2],
		          [3],
		          [4],
		        ],
	},
	'na_lvl_b' => {
		cols => ['x', 'y'],
		rows => [ [1, 'NA'],
		          [2, 'a'],
		          [3, 'b'],
		        ],
	},
	'pr1510_df1' => {
		cols => ['z', 'm', 'w'],
		rows => [ [1, 'a', 101],
		          [1, 'a', 102],
		          [2, 'b', 103],
		          [3, 'c', 104],
		          [5, 'e', 105],
		        ],
	},
	'pr1510_df2' => {
		cols => ['x', 'y', 'n'],
		rows => [ [1, 201, 'a'],
		          [2, 202, 'b'],
		          [2, 203, 'b'],
		          [3, 204, 'c'],
		          [9, 205, 'z'],
		        ],
	},
	'DF' => {
		cols => ['col'],
		rows => [ [1],
		          [2],
		          [3],
		        ],
	},
	'sfx_d1' => {
		cols => ['a', 'b', 'b.x'],
		rows => [ [1, 1, 5],
		          [2, 2, 4],
		          [3, 3, 3],
		          [4, 4, 2],
		          [5, 5, 1],
		        ],
	},
	'sfx_d2' => {
		cols => ['a', 'b'],
		rows => [ [1, 101],
		          [2, 102],
		          [3, 103],
		          [4, 104],
		          [5, 105],
		        ],
	},
	'egrid' => {
		cols => ['x', 'y'],
		rows => [ [1, 1],
		          [2, 1],
		          [1, 2],
		          [2, 2],
		        ],
	},
	'egrid_z' => {
		cols => ['x', 'y', 'z'],
		rows => [ [1, 1, 5040],
		          [2, 1, 128],
		          [1, 2, 1123],
		          [2, 2, 3709],
		        ],
	},
	'matP' => {
		cols => ['P', 'V', '2'],
		rows => [ ['a', '2', 'O'],
		          ['b', '0.2-26', 'O'],
		        ],
	},
	'matQ' => {
		cols => ['P', 'V', '1'],
		rows => [ ['a', '2', 'O'],
		          ['b', '0.2-25', 'O'],
		        ],
	},
	'women' => {
		cols => ['height', 'weight'],
		rows => [ [58, 115],
		          [59, 117],
		          [60, 120],
		          [61, 123],
		          [62, 126],
		          [63, 129],
		          [64, 132],
		          [65, 135],
		          [66, 139],
		          [67, 142],
		          [68, 146],
		          [69, 150],
		          [70, 154],
		          [71, 159],
		          [72, 164],
		        ],
	},
	'women0' => {
		cols => ['height', 'weight'],
		rows => [],
	},
	'zr_d' => {
		cols => ['x', 'y', 'fac'],
		rows => [ [1, 1, 'B'],
		        ],
	},
	'zr_e' => {
		cols => ['x', 'y', 'fac'],
		rows => [],
	},
	'inc_x' => {
		cols => ['k1', 'k2', 'data'],
		rows => [ [undef, 1, 1],
		          [undef, undef, 2],
		          [3, undef, 3],
		          [4, 4, 4],
		          [5, 5, 5],
		        ],
	},
	'inc_y' => {
		cols => ['k1', 'k2', 'data'],
		rows => [ [undef, undef, 1],
		          [2, undef, 2],
		          [undef, 3, 3],
		          [4, 4, 4],
		          [5, 5, 5],
		        ],
	},
);

my @R_CASES = (
	{ name  => 'merge.Rd m0: merge(authorN, books) [inner]',
	  left  => 'authorN', right => 'books',
	  args  => [ 'how' => 'inner', 'on' => 'name' ],
	  want_cols => ['name', 'nationality', 'deceased', 'title', 'other.author'],
	  want_rows => [ ['McNeil', 'Australia', 'no', 'Interactive Data Analysis', undef],
	                 ['Ripley', 'UK', 'no', 'Spatial Statistics', undef],
	                 ['Ripley', 'UK', 'no', 'Stochastic Simulation', undef],
	                 ['Tierney', 'US', 'no', 'LISP-STAT', undef],
	                 ['Tukey', 'US', 'yes', 'Exploratory Data Analysis', undef],
	                 ['Venables', 'Australia', 'no', 'Modern Applied Statistics ...', 'Ripley'],
	               ],
	},
	{ name  => 'merge.Rd m0: merge(authorN, books) [left]',
	  left  => 'authorN', right => 'books',
	  args  => [ 'how' => 'left', 'on' => 'name' ],
	  want_cols => ['name', 'nationality', 'deceased', 'title', 'other.author'],
	  want_rows => [ ['McNeil', 'Australia', 'no', 'Interactive Data Analysis', undef],
	                 ['Ripley', 'UK', 'no', 'Spatial Statistics', undef],
	                 ['Ripley', 'UK', 'no', 'Stochastic Simulation', undef],
	                 ['Tierney', 'US', 'no', 'LISP-STAT', undef],
	                 ['Tukey', 'US', 'yes', 'Exploratory Data Analysis', undef],
	                 ['Venables', 'Australia', 'no', 'Modern Applied Statistics ...', 'Ripley'],
	               ],
	},
	{ name  => 'merge.Rd m0: merge(authorN, books) [right]',
	  left  => 'authorN', right => 'books',
	  args  => [ 'how' => 'right', 'on' => 'name' ],
	  want_cols => ['name', 'nationality', 'deceased', 'title', 'other.author'],
	  want_rows => [ ['McNeil', 'Australia', 'no', 'Interactive Data Analysis', undef],
	                 ['R Core', undef, undef, 'An Introduction to R', 'Venables & Smith'],
	                 ['Ripley', 'UK', 'no', 'Spatial Statistics', undef],
	                 ['Ripley', 'UK', 'no', 'Stochastic Simulation', undef],
	                 ['Tierney', 'US', 'no', 'LISP-STAT', undef],
	                 ['Tukey', 'US', 'yes', 'Exploratory Data Analysis', undef],
	                 ['Venables', 'Australia', 'no', 'Modern Applied Statistics ...', 'Ripley'],
	               ],
	},
	{ name  => 'merge.Rd m0: merge(authorN, books) [outer]',
	  left  => 'authorN', right => 'books',
	  args  => [ 'how' => 'outer', 'on' => 'name' ],
	  want_cols => ['name', 'nationality', 'deceased', 'title', 'other.author'],
	  want_rows => [ ['McNeil', 'Australia', 'no', 'Interactive Data Analysis', undef],
	                 ['R Core', undef, undef, 'An Introduction to R', 'Venables & Smith'],
	                 ['Ripley', 'UK', 'no', 'Spatial Statistics', undef],
	                 ['Ripley', 'UK', 'no', 'Stochastic Simulation', undef],
	                 ['Tierney', 'US', 'no', 'LISP-STAT', undef],
	                 ['Tukey', 'US', 'yes', 'Exploratory Data Analysis', undef],
	                 ['Venables', 'Australia', 'no', 'Modern Applied Statistics ...', 'Ripley'],
	               ],
	},
	{ name  => 'merge.Rd m0: natural join, the intersection is {name}',
	  left  => 'authorN', right => 'books',
	  args  => [ 'how' => 'inner' ],
	  want_cols => ['name', 'nationality', 'deceased', 'title', 'other.author'],
	  want_rows => [ ['McNeil', 'Australia', 'no', 'Interactive Data Analysis', undef],
	                 ['Ripley', 'UK', 'no', 'Spatial Statistics', undef],
	                 ['Ripley', 'UK', 'no', 'Stochastic Simulation', undef],
	                 ['Tierney', 'US', 'no', 'LISP-STAT', undef],
	                 ['Tukey', 'US', 'yes', 'Exploratory Data Analysis', undef],
	                 ['Venables', 'Australia', 'no', 'Modern Applied Statistics ...', 'Ripley'],
	               ],
	},
	{ name  => 'merge.Rd m1: merge(authors, books, by.x = \'surname\', by.y = \'name\') [inner]',
	  left  => 'authors', right => 'books',
	  args  => [ 'how' => 'inner', 'left_on' => 'surname', 'right_on' => 'name' ],
	  want_cols => ['surname', 'nationality', 'deceased', 'title', 'other.author'],
	  want_rows => [ ['McNeil', 'Australia', 'no', 'Interactive Data Analysis', undef],
	                 ['Ripley', 'UK', 'no', 'Spatial Statistics', undef],
	                 ['Ripley', 'UK', 'no', 'Stochastic Simulation', undef],
	                 ['Tierney', 'US', 'no', 'LISP-STAT', undef],
	                 ['Tukey', 'US', 'yes', 'Exploratory Data Analysis', undef],
	                 ['Venables', 'Australia', 'no', 'Modern Applied Statistics ...', 'Ripley'],
	               ],
	},
	{ name  => 'merge.Rd m1: merge(authors, books, by.x = \'surname\', by.y = \'name\') [left]',
	  left  => 'authors', right => 'books',
	  args  => [ 'how' => 'left', 'left_on' => 'surname', 'right_on' => 'name' ],
	  want_cols => ['surname', 'nationality', 'deceased', 'title', 'other.author'],
	  want_rows => [ ['McNeil', 'Australia', 'no', 'Interactive Data Analysis', undef],
	                 ['Ripley', 'UK', 'no', 'Spatial Statistics', undef],
	                 ['Ripley', 'UK', 'no', 'Stochastic Simulation', undef],
	                 ['Tierney', 'US', 'no', 'LISP-STAT', undef],
	                 ['Tukey', 'US', 'yes', 'Exploratory Data Analysis', undef],
	                 ['Venables', 'Australia', 'no', 'Modern Applied Statistics ...', 'Ripley'],
	               ],
	},
	{ name  => 'merge.Rd m1: merge(authors, books, by.x = \'surname\', by.y = \'name\') [right]',
	  left  => 'authors', right => 'books',
	  args  => [ 'how' => 'right', 'left_on' => 'surname', 'right_on' => 'name' ],
	  want_cols => ['surname', 'nationality', 'deceased', 'title', 'other.author'],
	  want_rows => [ ['McNeil', 'Australia', 'no', 'Interactive Data Analysis', undef],
	                 ['R Core', undef, undef, 'An Introduction to R', 'Venables & Smith'],
	                 ['Ripley', 'UK', 'no', 'Spatial Statistics', undef],
	                 ['Ripley', 'UK', 'no', 'Stochastic Simulation', undef],
	                 ['Tierney', 'US', 'no', 'LISP-STAT', undef],
	                 ['Tukey', 'US', 'yes', 'Exploratory Data Analysis', undef],
	                 ['Venables', 'Australia', 'no', 'Modern Applied Statistics ...', 'Ripley'],
	               ],
	},
	{ name  => 'merge.Rd m1: merge(authors, books, by.x = \'surname\', by.y = \'name\') [outer]',
	  left  => 'authors', right => 'books',
	  args  => [ 'how' => 'outer', 'left_on' => 'surname', 'right_on' => 'name' ],
	  want_cols => ['surname', 'nationality', 'deceased', 'title', 'other.author'],
	  want_rows => [ ['McNeil', 'Australia', 'no', 'Interactive Data Analysis', undef],
	                 ['R Core', undef, undef, 'An Introduction to R', 'Venables & Smith'],
	                 ['Ripley', 'UK', 'no', 'Spatial Statistics', undef],
	                 ['Ripley', 'UK', 'no', 'Stochastic Simulation', undef],
	                 ['Tierney', 'US', 'no', 'LISP-STAT', undef],
	                 ['Tukey', 'US', 'yes', 'Exploratory Data Analysis', undef],
	                 ['Venables', 'Australia', 'no', 'Modern Applied Statistics ...', 'Ripley'],
	               ],
	},
	{ name  => 'merge.Rd m2: merge(books, authors, by.x = \'name\', by.y = \'surname\') [inner]',
	  left  => 'books', right => 'authors',
	  args  => [ 'how' => 'inner', 'left_on' => 'name', 'right_on' => 'surname' ],
	  want_cols => ['name', 'title', 'other.author', 'nationality', 'deceased'],
	  want_rows => [ ['McNeil', 'Interactive Data Analysis', undef, 'Australia', 'no'],
	                 ['Ripley', 'Spatial Statistics', undef, 'UK', 'no'],
	                 ['Ripley', 'Stochastic Simulation', undef, 'UK', 'no'],
	                 ['Tierney', 'LISP-STAT', undef, 'US', 'no'],
	                 ['Tukey', 'Exploratory Data Analysis', undef, 'US', 'yes'],
	                 ['Venables', 'Modern Applied Statistics ...', 'Ripley', 'Australia', 'no'],
	               ],
	},
	{ name  => 'merge.Rd m2: merge(books, authors, by.x = \'name\', by.y = \'surname\') [left]',
	  left  => 'books', right => 'authors',
	  args  => [ 'how' => 'left', 'left_on' => 'name', 'right_on' => 'surname' ],
	  want_cols => ['name', 'title', 'other.author', 'nationality', 'deceased'],
	  want_rows => [ ['McNeil', 'Interactive Data Analysis', undef, 'Australia', 'no'],
	                 ['R Core', 'An Introduction to R', 'Venables & Smith', undef, undef],
	                 ['Ripley', 'Spatial Statistics', undef, 'UK', 'no'],
	                 ['Ripley', 'Stochastic Simulation', undef, 'UK', 'no'],
	                 ['Tierney', 'LISP-STAT', undef, 'US', 'no'],
	                 ['Tukey', 'Exploratory Data Analysis', undef, 'US', 'yes'],
	                 ['Venables', 'Modern Applied Statistics ...', 'Ripley', 'Australia', 'no'],
	               ],
	},
	{ name  => 'merge.Rd m2: merge(books, authors, by.x = \'name\', by.y = \'surname\') [right]',
	  left  => 'books', right => 'authors',
	  args  => [ 'how' => 'right', 'left_on' => 'name', 'right_on' => 'surname' ],
	  want_cols => ['name', 'title', 'other.author', 'nationality', 'deceased'],
	  want_rows => [ ['McNeil', 'Interactive Data Analysis', undef, 'Australia', 'no'],
	                 ['Ripley', 'Spatial Statistics', undef, 'UK', 'no'],
	                 ['Ripley', 'Stochastic Simulation', undef, 'UK', 'no'],
	                 ['Tierney', 'LISP-STAT', undef, 'US', 'no'],
	                 ['Tukey', 'Exploratory Data Analysis', undef, 'US', 'yes'],
	                 ['Venables', 'Modern Applied Statistics ...', 'Ripley', 'Australia', 'no'],
	               ],
	},
	{ name  => 'merge.Rd m2: merge(books, authors, by.x = \'name\', by.y = \'surname\') [outer]',
	  left  => 'books', right => 'authors',
	  args  => [ 'how' => 'outer', 'left_on' => 'name', 'right_on' => 'surname' ],
	  want_cols => ['name', 'title', 'other.author', 'nationality', 'deceased'],
	  want_rows => [ ['McNeil', 'Interactive Data Analysis', undef, 'Australia', 'no'],
	                 ['R Core', 'An Introduction to R', 'Venables & Smith', undef, undef],
	                 ['Ripley', 'Spatial Statistics', undef, 'UK', 'no'],
	                 ['Ripley', 'Stochastic Simulation', undef, 'UK', 'no'],
	                 ['Tierney', 'LISP-STAT', undef, 'US', 'no'],
	                 ['Tukey', 'Exploratory Data Analysis', undef, 'US', 'yes'],
	                 ['Venables', 'Modern Applied Statistics ...', 'Ripley', 'Australia', 'no'],
	               ],
	},
	{ name  => 'merge.Rd: merge(m1, m2, by = NULL) is the Cartesian product',
	  left  => 'm1', right => 'm2',
	  args  => [ 'how' => 'cross' ],
	  want_cols => ['surname', 'nationality.x', 'deceased.x', 'title.x', 'other.author.x', 'name', 'title.y', 'other.author.y', 'nationality.y', 'deceased.y'],
	  want_rows => [ ['McNeil', 'Australia', 'no', 'Interactive Data Analysis', undef, 'McNeil', 'Interactive Data Analysis', undef, 'Australia', 'no'],
	                 ['Ripley', 'UK', 'no', 'Spatial Statistics', undef, 'McNeil', 'Interactive Data Analysis', undef, 'Australia', 'no'],
	                 ['Ripley', 'UK', 'no', 'Stochastic Simulation', undef, 'McNeil', 'Interactive Data Analysis', undef, 'Australia', 'no'],
	                 ['Tierney', 'US', 'no', 'LISP-STAT', undef, 'McNeil', 'Interactive Data Analysis', undef, 'Australia', 'no'],
	                 ['Tukey', 'US', 'yes', 'Exploratory Data Analysis', undef, 'McNeil', 'Interactive Data Analysis', undef, 'Australia', 'no'],
	                 ['Venables', 'Australia', 'no', 'Modern Applied Statistics ...', 'Ripley', 'McNeil', 'Interactive Data Analysis', undef, 'Australia', 'no'],
	                 ['McNeil', 'Australia', 'no', 'Interactive Data Analysis', undef, 'Ripley', 'Spatial Statistics', undef, 'UK', 'no'],
	                 ['Ripley', 'UK', 'no', 'Spatial Statistics', undef, 'Ripley', 'Spatial Statistics', undef, 'UK', 'no'],
	                 ['Ripley', 'UK', 'no', 'Stochastic Simulation', undef, 'Ripley', 'Spatial Statistics', undef, 'UK', 'no'],
	                 ['Tierney', 'US', 'no', 'LISP-STAT', undef, 'Ripley', 'Spatial Statistics', undef, 'UK', 'no'],
	                 ['Tukey', 'US', 'yes', 'Exploratory Data Analysis', undef, 'Ripley', 'Spatial Statistics', undef, 'UK', 'no'],
	                 ['Venables', 'Australia', 'no', 'Modern Applied Statistics ...', 'Ripley', 'Ripley', 'Spatial Statistics', undef, 'UK', 'no'],
	                 ['McNeil', 'Australia', 'no', 'Interactive Data Analysis', undef, 'Ripley', 'Stochastic Simulation', undef, 'UK', 'no'],
	                 ['Ripley', 'UK', 'no', 'Spatial Statistics', undef, 'Ripley', 'Stochastic Simulation', undef, 'UK', 'no'],
	                 ['Ripley', 'UK', 'no', 'Stochastic Simulation', undef, 'Ripley', 'Stochastic Simulation', undef, 'UK', 'no'],
	                 ['Tierney', 'US', 'no', 'LISP-STAT', undef, 'Ripley', 'Stochastic Simulation', undef, 'UK', 'no'],
	                 ['Tukey', 'US', 'yes', 'Exploratory Data Analysis', undef, 'Ripley', 'Stochastic Simulation', undef, 'UK', 'no'],
	                 ['Venables', 'Australia', 'no', 'Modern Applied Statistics ...', 'Ripley', 'Ripley', 'Stochastic Simulation', undef, 'UK', 'no'],
	                 ['McNeil', 'Australia', 'no', 'Interactive Data Analysis', undef, 'Tierney', 'LISP-STAT', undef, 'US', 'no'],
	                 ['Ripley', 'UK', 'no', 'Spatial Statistics', undef, 'Tierney', 'LISP-STAT', undef, 'US', 'no'],
	                 ['Ripley', 'UK', 'no', 'Stochastic Simulation', undef, 'Tierney', 'LISP-STAT', undef, 'US', 'no'],
	                 ['Tierney', 'US', 'no', 'LISP-STAT', undef, 'Tierney', 'LISP-STAT', undef, 'US', 'no'],
	                 ['Tukey', 'US', 'yes', 'Exploratory Data Analysis', undef, 'Tierney', 'LISP-STAT', undef, 'US', 'no'],
	                 ['Venables', 'Australia', 'no', 'Modern Applied Statistics ...', 'Ripley', 'Tierney', 'LISP-STAT', undef, 'US', 'no'],
	                 ['McNeil', 'Australia', 'no', 'Interactive Data Analysis', undef, 'Tukey', 'Exploratory Data Analysis', undef, 'US', 'yes'],
	                 ['Ripley', 'UK', 'no', 'Spatial Statistics', undef, 'Tukey', 'Exploratory Data Analysis', undef, 'US', 'yes'],
	                 ['Ripley', 'UK', 'no', 'Stochastic Simulation', undef, 'Tukey', 'Exploratory Data Analysis', undef, 'US', 'yes'],
	                 ['Tierney', 'US', 'no', 'LISP-STAT', undef, 'Tukey', 'Exploratory Data Analysis', undef, 'US', 'yes'],
	                 ['Tukey', 'US', 'yes', 'Exploratory Data Analysis', undef, 'Tukey', 'Exploratory Data Analysis', undef, 'US', 'yes'],
	                 ['Venables', 'Australia', 'no', 'Modern Applied Statistics ...', 'Ripley', 'Tukey', 'Exploratory Data Analysis', undef, 'US', 'yes'],
	                 ['McNeil', 'Australia', 'no', 'Interactive Data Analysis', undef, 'Venables', 'Modern Applied Statistics ...', 'Ripley', 'Australia', 'no'],
	                 ['Ripley', 'UK', 'no', 'Spatial Statistics', undef, 'Venables', 'Modern Applied Statistics ...', 'Ripley', 'Australia', 'no'],
	                 ['Ripley', 'UK', 'no', 'Stochastic Simulation', undef, 'Venables', 'Modern Applied Statistics ...', 'Ripley', 'Australia', 'no'],
	                 ['Tierney', 'US', 'no', 'LISP-STAT', undef, 'Venables', 'Modern Applied Statistics ...', 'Ripley', 'Australia', 'no'],
	                 ['Tukey', 'US', 'yes', 'Exploratory Data Analysis', undef, 'Venables', 'Modern Applied Statistics ...', 'Ripley', 'Australia', 'no'],
	                 ['Venables', 'Australia', 'no', 'Modern Applied Statistics ...', 'Ripley', 'Venables', 'Modern Applied Statistics ...', 'Ripley', 'Australia', 'no'],
	               ],
	},
	{ name  => 'reg-tests-2.R: merge(authors, b2) [inner]',
	  left  => 'authors', right => 'b2',
	  args  => [ 'how' => 'inner', 'on' => 'surname' ],
	  want_cols => ['surname', 'nationality', 'deceased', 'title', 'other.author'],
	  want_rows => [ ['McNeil', 'Australia', 'no', 'Interactive Data Analysis', undef],
	                 ['Ripley', 'UK', 'no', 'Spatial Statistics', undef],
	                 ['Ripley', 'UK', 'no', 'Stochastic Simulation', undef],
	                 ['Tierney', 'US', 'no', 'LISP-STAT', undef],
	                 ['Tukey', 'US', 'yes', 'Exploratory Data Analysis', undef],
	                 ['Venables', 'Australia', 'no', 'Modern Applied Statistics ...', 'Ripley'],
	               ],
	},
	{ name  => 'reg-tests-2.R: merge(authors, b2) [left]',
	  left  => 'authors', right => 'b2',
	  args  => [ 'how' => 'left', 'on' => 'surname' ],
	  want_cols => ['surname', 'nationality', 'deceased', 'title', 'other.author'],
	  want_rows => [ ['McNeil', 'Australia', 'no', 'Interactive Data Analysis', undef],
	                 ['Ripley', 'UK', 'no', 'Spatial Statistics', undef],
	                 ['Ripley', 'UK', 'no', 'Stochastic Simulation', undef],
	                 ['Tierney', 'US', 'no', 'LISP-STAT', undef],
	                 ['Tukey', 'US', 'yes', 'Exploratory Data Analysis', undef],
	                 ['Venables', 'Australia', 'no', 'Modern Applied Statistics ...', 'Ripley'],
	               ],
	},
	{ name  => 'reg-tests-2.R: merge(authors, b2) [right]',
	  left  => 'authors', right => 'b2',
	  args  => [ 'how' => 'right', 'on' => 'surname' ],
	  want_cols => ['surname', 'nationality', 'deceased', 'title', 'other.author'],
	  want_rows => [ ['McNeil', 'Australia', 'no', 'Interactive Data Analysis', undef],
	                 ['R Core', undef, undef, 'An Introduction to R', 'Venables & Smith'],
	                 ['Ripley', 'UK', 'no', 'Spatial Statistics', undef],
	                 ['Ripley', 'UK', 'no', 'Stochastic Simulation', undef],
	                 ['Tierney', 'US', 'no', 'LISP-STAT', undef],
	                 ['Tukey', 'US', 'yes', 'Exploratory Data Analysis', undef],
	                 ['Venables', 'Australia', 'no', 'Modern Applied Statistics ...', 'Ripley'],
	               ],
	},
	{ name  => 'reg-tests-2.R: merge(authors, b2) [outer]',
	  left  => 'authors', right => 'b2',
	  args  => [ 'how' => 'outer', 'on' => 'surname' ],
	  want_cols => ['surname', 'nationality', 'deceased', 'title', 'other.author'],
	  want_rows => [ ['McNeil', 'Australia', 'no', 'Interactive Data Analysis', undef],
	                 ['R Core', undef, undef, 'An Introduction to R', 'Venables & Smith'],
	                 ['Ripley', 'UK', 'no', 'Spatial Statistics', undef],
	                 ['Ripley', 'UK', 'no', 'Stochastic Simulation', undef],
	                 ['Tierney', 'US', 'no', 'LISP-STAT', undef],
	                 ['Tukey', 'US', 'yes', 'Exploratory Data Analysis', undef],
	                 ['Venables', 'Australia', 'no', 'Modern Applied Statistics ...', 'Ripley'],
	               ],
	},
	{ name  => 'reg-tests-2.R: merge(authors, b2[7, ]), an empty inner join [inner]',
	  left  => 'authors', right => 'b2_R7',
	  args  => [ 'how' => 'inner', 'on' => 'surname' ],
	  want_cols => ['surname', 'nationality', 'deceased', 'title', 'other.author'],
	  want_rows => [],
	},
	{ name  => 'reg-tests-2.R: merge(authors, b2[7, ]), an empty inner join [left]',
	  left  => 'authors', right => 'b2_R7',
	  args  => [ 'how' => 'left', 'on' => 'surname' ],
	  want_cols => ['surname', 'nationality', 'deceased', 'title', 'other.author'],
	  want_rows => [ ['McNeil', 'Australia', 'no', undef, undef],
	                 ['Ripley', 'UK', 'no', undef, undef],
	                 ['Tierney', 'US', 'no', undef, undef],
	                 ['Tukey', 'US', 'yes', undef, undef],
	                 ['Venables', 'Australia', 'no', undef, undef],
	               ],
	},
	{ name  => 'reg-tests-2.R: merge(authors, b2[7, ]), an empty inner join [right]',
	  left  => 'authors', right => 'b2_R7',
	  args  => [ 'how' => 'right', 'on' => 'surname' ],
	  want_cols => ['surname', 'nationality', 'deceased', 'title', 'other.author'],
	  want_rows => [ ['R Core', undef, undef, 'An Introduction to R', 'Venables & Smith'],
	               ],
	},
	{ name  => 'reg-tests-2.R: merge(authors, b2[7, ]), an empty inner join [outer]',
	  left  => 'authors', right => 'b2_R7',
	  args  => [ 'how' => 'outer', 'on' => 'surname' ],
	  want_cols => ['surname', 'nationality', 'deceased', 'title', 'other.author'],
	  want_rows => [ ['McNeil', 'Australia', 'no', undef, undef],
	                 ['R Core', undef, undef, 'An Introduction to R', 'Venables & Smith'],
	                 ['Ripley', 'UK', 'no', undef, undef],
	                 ['Tierney', 'US', 'no', undef, undef],
	                 ['Tukey', 'US', 'yes', undef, undef],
	                 ['Venables', 'Australia', 'no', undef, undef],
	               ],
	},
	{ name  => 'reg-tests-1d.R: by.x = \'name\', by.y = \'parent\' (right \'name\' collides) [inner]',
	  left  => 'parents', right => 'children',
	  args  => [ 'how' => 'inner', 'left_on' => 'name', 'right_on' => 'parent' ],
	  want_cols => ['name', 'sex.x', 'age.x', 'name.y', 'sex.y', 'age.y'],
	  want_rows => [ ['Max', 'M', 43, 'Sebastian', 'M', 8],
	                 ['Qin', 'F', 36, 'Kai-lee', 'F', 7],
	                 ['Sarah', 'F', 41, 'Oliver', 'M', 5],
	               ],
	},
	{ name  => 'reg-tests-1d.R: by.x = \'name\', by.y = \'parent\' (right \'name\' collides) [left]',
	  left  => 'parents', right => 'children',
	  args  => [ 'how' => 'left', 'left_on' => 'name', 'right_on' => 'parent' ],
	  want_cols => ['name', 'sex.x', 'age.x', 'name.y', 'sex.y', 'age.y'],
	  want_rows => [ ['Lex', 'M', 51, undef, undef, undef],
	                 ['Max', 'M', 43, 'Sebastian', 'M', 8],
	                 ['Qin', 'F', 36, 'Kai-lee', 'F', 7],
	                 ['Sarah', 'F', 41, 'Oliver', 'M', 5],
	               ],
	},
	{ name  => 'reg-tests-1d.R: by.x = \'name\', by.y = \'parent\' (right \'name\' collides) [right]',
	  left  => 'parents', right => 'children',
	  args  => [ 'how' => 'right', 'left_on' => 'name', 'right_on' => 'parent' ],
	  want_cols => ['name', 'sex.x', 'age.x', 'name.y', 'sex.y', 'age.y'],
	  want_rows => [ ['Max', 'M', 43, 'Sebastian', 'M', 8],
	                 ['Qin', 'F', 36, 'Kai-lee', 'F', 7],
	                 ['Sarah', 'F', 41, 'Oliver', 'M', 5],
	               ],
	},
	{ name  => 'reg-tests-1d.R: by.x = \'name\', by.y = \'parent\' (right \'name\' collides) [outer]',
	  left  => 'parents', right => 'children',
	  args  => [ 'how' => 'outer', 'left_on' => 'name', 'right_on' => 'parent' ],
	  want_cols => ['name', 'sex.x', 'age.x', 'name.y', 'sex.y', 'age.y'],
	  want_rows => [ ['Lex', 'M', 51, undef, undef, undef],
	                 ['Max', 'M', 43, 'Sebastian', 'M', 8],
	                 ['Qin', 'F', 36, 'Kai-lee', 'F', 7],
	                 ['Sarah', 'F', 41, 'Oliver', 'M', 5],
	               ],
	},
	{ name  => 'reg-tests-2.R: merge(d.df[1, ], d.df), all three columns are keys [inner]',
	  left  => 'd.df_R1', right => 'd.df',
	  args  => [ 'how' => 'inner', 'on' => ['x', 'y', 'z'] ],
	  want_cols => ['x', 'y', 'z'],
	  want_rows => [ ['1', 'A', '6'],
	               ],
	},
	{ name  => 'reg-tests-2.R: merge(d.df[1, ], d.df), all three columns are keys [left]',
	  left  => 'd.df_R1', right => 'd.df',
	  args  => [ 'how' => 'left', 'on' => ['x', 'y', 'z'] ],
	  want_cols => ['x', 'y', 'z'],
	  want_rows => [ ['1', 'A', '6'],
	               ],
	},
	{ name  => 'reg-tests-2.R: merge(d.df[1, ], d.df), all three columns are keys [right]',
	  left  => 'd.df_R1', right => 'd.df',
	  args  => [ 'how' => 'right', 'on' => ['x', 'y', 'z'] ],
	  want_cols => ['x', 'y', 'z'],
	  want_rows => [ ['1', 'A', '6'],
	                 ['2', 'D', '9'],
	                 ['3', 'E', '10'],
	               ],
	},
	{ name  => 'reg-tests-2.R: merge(d.df[1, ], d.df), all three columns are keys [outer]',
	  left  => 'd.df_R1', right => 'd.df',
	  args  => [ 'how' => 'outer', 'on' => ['x', 'y', 'z'] ],
	  want_cols => ['x', 'y', 'z'],
	  want_rows => [ ['1', 'A', '6'],
	                 ['2', 'D', '9'],
	                 ['3', 'E', '10'],
	               ],
	},
	{ name  => 'reg-tests-1a.R: the string \'NA\' is not a missing value [inner]',
	  left  => 'na_lvl_a', right => 'na_lvl_b',
	  args  => [ 'how' => 'inner', 'on' => 'x' ],
	  want_cols => ['x', 'y'],
	  want_rows => [ ['1', 'NA'],
	                 ['2', 'a'],
	                 ['3', 'b'],
	               ],
	},
	{ name  => 'reg-tests-1a.R: the string \'NA\' is not a missing value [left]',
	  left  => 'na_lvl_a', right => 'na_lvl_b',
	  args  => [ 'how' => 'left', 'on' => 'x' ],
	  want_cols => ['x', 'y'],
	  want_rows => [ ['1', 'NA'],
	                 ['2', 'a'],
	                 ['3', 'b'],
	                 ['4', undef],
	               ],
	},
	{ name  => 'reg-tests-1a.R: the string \'NA\' is not a missing value [right]',
	  left  => 'na_lvl_a', right => 'na_lvl_b',
	  args  => [ 'how' => 'right', 'on' => 'x' ],
	  want_cols => ['x', 'y'],
	  want_rows => [ ['1', 'NA'],
	                 ['2', 'a'],
	                 ['3', 'b'],
	               ],
	},
	{ name  => 'reg-tests-1a.R: the string \'NA\' is not a missing value [outer]',
	  left  => 'na_lvl_a', right => 'na_lvl_b',
	  args  => [ 'how' => 'outer', 'on' => 'x' ],
	  want_cols => ['x', 'y'],
	  want_rows => [ ['1', 'NA'],
	                 ['2', 'a'],
	                 ['3', 'b'],
	                 ['4', undef],
	               ],
	},
	{ name  => 'reg-tests-1a.R PR#1510: by.x = c(\'x\',\'n\'), by.y = c(\'z\',\'m\') [inner]',
	  left  => 'pr1510_df2', right => 'pr1510_df1',
	  args  => [ 'how' => 'inner', 'left_on' => ['x', 'n'], 'right_on' => ['z', 'm'] ],
	  want_cols => ['x', 'n', 'y', 'w'],
	  want_rows => [ ['1', 'a', 201, 101],
	                 ['1', 'a', 201, 102],
	                 ['2', 'b', 202, 103],
	                 ['2', 'b', 203, 103],
	                 ['3', 'c', 204, 104],
	               ],
	},
	{ name  => 'reg-tests-1a.R PR#1510: by.x = c(\'x\',\'n\'), by.y = c(\'z\',\'m\') [left]',
	  left  => 'pr1510_df2', right => 'pr1510_df1',
	  args  => [ 'how' => 'left', 'left_on' => ['x', 'n'], 'right_on' => ['z', 'm'] ],
	  want_cols => ['x', 'n', 'y', 'w'],
	  want_rows => [ ['1', 'a', 201, 101],
	                 ['1', 'a', 201, 102],
	                 ['2', 'b', 202, 103],
	                 ['2', 'b', 203, 103],
	                 ['3', 'c', 204, 104],
	                 ['9', 'z', 205, undef],
	               ],
	},
	{ name  => 'reg-tests-1a.R PR#1510: by.x = c(\'x\',\'n\'), by.y = c(\'z\',\'m\') [right]',
	  left  => 'pr1510_df2', right => 'pr1510_df1',
	  args  => [ 'how' => 'right', 'left_on' => ['x', 'n'], 'right_on' => ['z', 'm'] ],
	  want_cols => ['x', 'n', 'y', 'w'],
	  want_rows => [ ['1', 'a', 201, 101],
	                 ['1', 'a', 201, 102],
	                 ['2', 'b', 202, 103],
	                 ['2', 'b', 203, 103],
	                 ['3', 'c', 204, 104],
	                 ['5', 'e', undef, 105],
	               ],
	},
	{ name  => 'reg-tests-1a.R PR#1510: by.x = c(\'x\',\'n\'), by.y = c(\'z\',\'m\') [outer]',
	  left  => 'pr1510_df2', right => 'pr1510_df1',
	  args  => [ 'how' => 'outer', 'left_on' => ['x', 'n'], 'right_on' => ['z', 'm'] ],
	  want_cols => ['x', 'n', 'y', 'w'],
	  want_rows => [ ['1', 'a', 201, 101],
	                 ['1', 'a', 201, 102],
	                 ['2', 'b', 202, 103],
	                 ['2', 'b', 203, 103],
	                 ['3', 'c', 204, 104],
	                 ['5', 'e', undef, 105],
	                 ['9', 'z', 205, undef],
	               ],
	},
	{ name  => 'reg-tests-1a.R: cross join suffixes the colliding column',
	  left  => 'DF', right => 'DF',
	  args  => [ 'how' => 'cross' ],
	  want_cols => ['col.x', 'col.y'],
	  want_rows => [ [1, 1],
	                 [2, 1],
	                 [3, 1],
	                 [1, 2],
	                 [2, 2],
	                 [3, 2],
	                 [1, 3],
	                 [2, 3],
	                 [3, 3],
	               ],
	},
	{ name  => 'reg-tests-1b.R: suffixes = c(\'\', \'.y\') [inner]',
	  left  => 'sfx_d1', right => 'sfx_d2',
	  args  => [ 'how' => 'inner', 'on' => 'a', 'suffixes' => ['', '.y'] ],
	  want_cols => ['a', 'b', 'b.x', 'b.y'],
	  want_rows => [ [1, 1, 5, 101],
	                 [2, 2, 4, 102],
	                 [3, 3, 3, 103],
	                 [4, 4, 2, 104],
	                 [5, 5, 1, 105],
	               ],
	},
	{ name  => 'reg-tests-1b.R: suffixes = c(\'\', \'.y\') [left]',
	  left  => 'sfx_d1', right => 'sfx_d2',
	  args  => [ 'how' => 'left', 'on' => 'a', 'suffixes' => ['', '.y'] ],
	  want_cols => ['a', 'b', 'b.x', 'b.y'],
	  want_rows => [ [1, 1, 5, 101],
	                 [2, 2, 4, 102],
	                 [3, 3, 3, 103],
	                 [4, 4, 2, 104],
	                 [5, 5, 1, 105],
	               ],
	},
	{ name  => 'reg-tests-1b.R: suffixes = c(\'\', \'.y\') [right]',
	  left  => 'sfx_d1', right => 'sfx_d2',
	  args  => [ 'how' => 'right', 'on' => 'a', 'suffixes' => ['', '.y'] ],
	  want_cols => ['a', 'b', 'b.x', 'b.y'],
	  want_rows => [ [1, 1, 5, 101],
	                 [2, 2, 4, 102],
	                 [3, 3, 3, 103],
	                 [4, 4, 2, 104],
	                 [5, 5, 1, 105],
	               ],
	},
	{ name  => 'reg-tests-1b.R: suffixes = c(\'\', \'.y\') [outer]',
	  left  => 'sfx_d1', right => 'sfx_d2',
	  args  => [ 'how' => 'outer', 'on' => 'a', 'suffixes' => ['', '.y'] ],
	  want_cols => ['a', 'b', 'b.x', 'b.y'],
	  want_rows => [ [1, 1, 5, 101],
	                 [2, 2, 4, 102],
	                 [3, 3, 3, 103],
	                 [4, 4, 2, 104],
	                 [5, 5, 1, 105],
	               ],
	},
	{ name  => 'reg-tests-1b.R: two-column natural join, x is all key [inner]',
	  left  => 'egrid', right => 'egrid_z',
	  args  => [ 'how' => 'inner', 'on' => ['x', 'y'] ],
	  want_cols => ['x', 'y', 'z'],
	  want_rows => [ ['1', '1', 5040],
	                 ['1', '2', 1123],
	                 ['2', '1', 128],
	                 ['2', '2', 3709],
	               ],
	},
	{ name  => 'reg-tests-1b.R: two-column natural join, x is all key [left]',
	  left  => 'egrid', right => 'egrid_z',
	  args  => [ 'how' => 'left', 'on' => ['x', 'y'] ],
	  want_cols => ['x', 'y', 'z'],
	  want_rows => [ ['1', '1', 5040],
	                 ['1', '2', 1123],
	                 ['2', '1', 128],
	                 ['2', '2', 3709],
	               ],
	},
	{ name  => 'reg-tests-1b.R: two-column natural join, x is all key [right]',
	  left  => 'egrid', right => 'egrid_z',
	  args  => [ 'how' => 'right', 'on' => ['x', 'y'] ],
	  want_cols => ['x', 'y', 'z'],
	  want_rows => [ ['1', '1', 5040],
	                 ['1', '2', 1123],
	                 ['2', '1', 128],
	                 ['2', '2', 3709],
	               ],
	},
	{ name  => 'reg-tests-1b.R: two-column natural join, x is all key [outer]',
	  left  => 'egrid', right => 'egrid_z',
	  args  => [ 'how' => 'outer', 'on' => ['x', 'y'] ],
	  want_cols => ['x', 'y', 'z'],
	  want_rows => [ ['1', '1', 5040],
	                 ['1', '2', 1123],
	                 ['2', '1', 128],
	                 ['2', '2', 3709],
	               ],
	},
	{ name  => 'reg-tests-1a.R: matrices sharing {P, V}, columns named \'2\' and \'1\' [inner]',
	  left  => 'matP', right => 'matQ',
	  args  => [ 'how' => 'inner', 'on' => ['P', 'V'] ],
	  want_cols => ['P', 'V', '2', '1'],
	  want_rows => [ ['a', '2', 'O', 'O'],
	               ],
	},
	{ name  => 'reg-tests-1a.R: matrices sharing {P, V}, columns named \'2\' and \'1\' [left]',
	  left  => 'matP', right => 'matQ',
	  args  => [ 'how' => 'left', 'on' => ['P', 'V'] ],
	  want_cols => ['P', 'V', '2', '1'],
	  want_rows => [ ['a', '2', 'O', 'O'],
	                 ['b', '0.2-26', 'O', undef],
	               ],
	},
	{ name  => 'reg-tests-1a.R: matrices sharing {P, V}, columns named \'2\' and \'1\' [right]',
	  left  => 'matP', right => 'matQ',
	  args  => [ 'how' => 'right', 'on' => ['P', 'V'] ],
	  want_cols => ['P', 'V', '2', '1'],
	  want_rows => [ ['a', '2', 'O', 'O'],
	                 ['b', '0.2-25', undef, 'O'],
	               ],
	},
	{ name  => 'reg-tests-1a.R: matrices sharing {P, V}, columns named \'2\' and \'1\' [outer]',
	  left  => 'matP', right => 'matQ',
	  args  => [ 'how' => 'outer', 'on' => ['P', 'V'] ],
	  want_cols => ['P', 'V', '2', '1'],
	  want_rows => [ ['a', '2', 'O', 'O'],
	                 ['b', '0.2-25', undef, 'O'],
	                 ['b', '0.2-26', 'O', undef],
	               ],
	},
	{ name  => 'reg-tests-1b.R: merge(women[FALSE, ], women) [inner]',
	  left  => 'women0', right => 'women',
	  args  => [ 'how' => 'inner', 'on' => ['height', 'weight'] ],
	  shapes => 'hoa',
	  want_cols => ['height', 'weight'],
	  want_rows => [],
	},
	{ name  => 'reg-tests-1b.R: merge(women[FALSE, ], women) [left]',
	  left  => 'women0', right => 'women',
	  args  => [ 'how' => 'left', 'on' => ['height', 'weight'] ],
	  shapes => 'hoa',
	  want_cols => ['height', 'weight'],
	  want_rows => [],
	},
	{ name  => 'reg-tests-1b.R: merge(women[FALSE, ], women) [right]',
	  left  => 'women0', right => 'women',
	  args  => [ 'how' => 'right', 'on' => ['height', 'weight'] ],
	  shapes => 'hoa',
	  want_cols => ['height', 'weight'],
	  want_rows => [ ['58', '115'],
	                 ['59', '117'],
	                 ['60', '120'],
	                 ['61', '123'],
	                 ['62', '126'],
	                 ['63', '129'],
	                 ['64', '132'],
	                 ['65', '135'],
	                 ['66', '139'],
	                 ['67', '142'],
	                 ['68', '146'],
	                 ['69', '150'],
	                 ['70', '154'],
	                 ['71', '159'],
	                 ['72', '164'],
	               ],
	},
	{ name  => 'reg-tests-1b.R: merge(women[FALSE, ], women) [outer]',
	  left  => 'women0', right => 'women',
	  args  => [ 'how' => 'outer', 'on' => ['height', 'weight'] ],
	  shapes => 'hoa',
	  want_cols => ['height', 'weight'],
	  want_rows => [ ['58', '115'],
	                 ['59', '117'],
	                 ['60', '120'],
	                 ['61', '123'],
	                 ['62', '126'],
	                 ['63', '129'],
	                 ['64', '132'],
	                 ['65', '135'],
	                 ['66', '139'],
	                 ['67', '142'],
	                 ['68', '146'],
	                 ['69', '150'],
	                 ['70', '154'],
	                 ['71', '159'],
	                 ['72', '164'],
	               ],
	},
	{ name  => 'reg-tests-1b.R: merge(women, women[FALSE, ]) [inner]',
	  left  => 'women', right => 'women0',
	  args  => [ 'how' => 'inner', 'on' => ['height', 'weight'] ],
	  shapes => 'hoa',
	  want_cols => ['height', 'weight'],
	  want_rows => [],
	},
	{ name  => 'reg-tests-1b.R: merge(women, women[FALSE, ]) [left]',
	  left  => 'women', right => 'women0',
	  args  => [ 'how' => 'left', 'on' => ['height', 'weight'] ],
	  shapes => 'hoa',
	  want_cols => ['height', 'weight'],
	  want_rows => [ ['58', '115'],
	                 ['59', '117'],
	                 ['60', '120'],
	                 ['61', '123'],
	                 ['62', '126'],
	                 ['63', '129'],
	                 ['64', '132'],
	                 ['65', '135'],
	                 ['66', '139'],
	                 ['67', '142'],
	                 ['68', '146'],
	                 ['69', '150'],
	                 ['70', '154'],
	                 ['71', '159'],
	                 ['72', '164'],
	               ],
	},
	{ name  => 'reg-tests-1b.R: merge(women, women[FALSE, ]) [right]',
	  left  => 'women', right => 'women0',
	  args  => [ 'how' => 'right', 'on' => ['height', 'weight'] ],
	  shapes => 'hoa',
	  want_cols => ['height', 'weight'],
	  want_rows => [],
	},
	{ name  => 'reg-tests-1b.R: merge(women, women[FALSE, ]) [outer]',
	  left  => 'women', right => 'women0',
	  args  => [ 'how' => 'outer', 'on' => ['height', 'weight'] ],
	  shapes => 'hoa',
	  want_cols => ['height', 'weight'],
	  want_rows => [ ['58', '115'],
	                 ['59', '117'],
	                 ['60', '120'],
	                 ['61', '123'],
	                 ['62', '126'],
	                 ['63', '129'],
	                 ['64', '132'],
	                 ['65', '135'],
	                 ['66', '139'],
	                 ['67', '142'],
	                 ['68', '146'],
	                 ['69', '150'],
	                 ['70', '154'],
	                 ['71', '159'],
	                 ['72', '164'],
	               ],
	},
	{ name  => 'reg-tests-1a.R: merge on a zero-row right frame, by.x = by.y = \'x\' [inner]',
	  left  => 'zr_d', right => 'zr_e',
	  args  => [ 'how' => 'inner', 'left_on' => 'x', 'right_on' => 'x' ],
	  shapes => 'hoa',
	  want_cols => ['x', 'y.x', 'fac.x', 'y.y', 'fac.y'],
	  want_rows => [],
	},
	{ name  => 'reg-tests-1a.R: merge on a zero-row right frame, by.x = by.y = \'x\' [left]',
	  left  => 'zr_d', right => 'zr_e',
	  args  => [ 'how' => 'left', 'left_on' => 'x', 'right_on' => 'x' ],
	  shapes => 'hoa',
	  want_cols => ['x', 'y.x', 'fac.x', 'y.y', 'fac.y'],
	  want_rows => [ ['1', 1, 'B', undef, undef],
	               ],
	},
	{ name  => 'reg-tests-1a.R: merge on a zero-row right frame, by.x = by.y = \'x\' [right]',
	  left  => 'zr_d', right => 'zr_e',
	  args  => [ 'how' => 'right', 'left_on' => 'x', 'right_on' => 'x' ],
	  shapes => 'hoa',
	  want_cols => ['x', 'y.x', 'fac.x', 'y.y', 'fac.y'],
	  want_rows => [],
	},
	{ name  => 'reg-tests-1a.R: merge on a zero-row right frame, by.x = by.y = \'x\' [outer]',
	  left  => 'zr_d', right => 'zr_e',
	  args  => [ 'how' => 'outer', 'left_on' => 'x', 'right_on' => 'x' ],
	  shapes => 'hoa',
	  want_cols => ['x', 'y.x', 'fac.x', 'y.y', 'fac.y'],
	  want_rows => [ ['1', 1, 'B', undef, undef],
	               ],
	},
	{ name  => 'merge.Rd incomparables: by = c(\'k1\',\'k2\'), NA matches nothing [inner]',
	  left  => 'inc_x', right => 'inc_y',
	  args  => [ 'how' => 'inner', 'on' => ['k1', 'k2'] ],
	  want_cols => ['k1', 'k2', 'data.x', 'data.y'],
	  want_rows => [ ['4', '4', 4, 4],
	                 ['5', '5', 5, 5],
	               ],
	},
	{ name  => 'merge.Rd incomparables: by = c(\'k1\',\'k2\'), NA matches nothing [left]',
	  left  => 'inc_x', right => 'inc_y',
	  args  => [ 'how' => 'left', 'on' => ['k1', 'k2'] ],
	  want_cols => ['k1', 'k2', 'data.x', 'data.y'],
	  want_rows => [ ['3', undef, 3, undef],
	                 ['4', '4', 4, 4],
	                 ['5', '5', 5, 5],
	                 [undef, '1', 1, undef],
	                 [undef, undef, 2, undef],
	               ],
	},
	{ name  => 'merge.Rd incomparables: by = c(\'k1\',\'k2\'), NA matches nothing [right]',
	  left  => 'inc_x', right => 'inc_y',
	  args  => [ 'how' => 'right', 'on' => ['k1', 'k2'] ],
	  want_cols => ['k1', 'k2', 'data.x', 'data.y'],
	  want_rows => [ ['2', undef, undef, 2],
	                 ['4', '4', 4, 4],
	                 ['5', '5', 5, 5],
	                 [undef, undef, undef, 1],
	                 [undef, '3', undef, 3],
	               ],
	},
	{ name  => 'merge.Rd incomparables: by = c(\'k1\',\'k2\'), NA matches nothing [outer]',
	  left  => 'inc_x', right => 'inc_y',
	  args  => [ 'how' => 'outer', 'on' => ['k1', 'k2'] ],
	  want_cols => ['k1', 'k2', 'data.x', 'data.y'],
	  want_rows => [ ['2', undef, undef, 2],
	                 ['3', undef, 3, undef],
	                 ['4', '4', 4, 4],
	                 ['5', '5', 5, 5],
	                 [undef, '1', 1, undef],
	                 [undef, undef, 2, undef],
	                 [undef, undef, undef, 1],
	                 [undef, '3', undef, 3],
	               ],
	},
	{ name  => 'merge.Rd incomparables: by = \'k1\', NA matches nothing [inner]',
	  left  => 'inc_x', right => 'inc_y',
	  args  => [ 'how' => 'inner', 'on' => 'k1' ],
	  want_cols => ['k1', 'k2.x', 'data.x', 'k2.y', 'data.y'],
	  want_rows => [ ['4', 4, 4, 4, 4],
	                 ['5', 5, 5, 5, 5],
	               ],
	},
	{ name  => 'merge.Rd incomparables: by = \'k1\', NA matches nothing [left]',
	  left  => 'inc_x', right => 'inc_y',
	  args  => [ 'how' => 'left', 'on' => 'k1' ],
	  want_cols => ['k1', 'k2.x', 'data.x', 'k2.y', 'data.y'],
	  want_rows => [ ['3', undef, 3, undef, undef],
	                 ['4', 4, 4, 4, 4],
	                 ['5', 5, 5, 5, 5],
	                 [undef, 1, 1, undef, undef],
	                 [undef, undef, 2, undef, undef],
	               ],
	},
	{ name  => 'merge.Rd incomparables: by = \'k1\', NA matches nothing [right]',
	  left  => 'inc_x', right => 'inc_y',
	  args  => [ 'how' => 'right', 'on' => 'k1' ],
	  want_cols => ['k1', 'k2.x', 'data.x', 'k2.y', 'data.y'],
	  want_rows => [ ['2', undef, undef, undef, 2],
	                 ['4', 4, 4, 4, 4],
	                 ['5', 5, 5, 5, 5],
	                 [undef, undef, undef, undef, 1],
	                 [undef, undef, undef, 3, 3],
	               ],
	},
	{ name  => 'merge.Rd incomparables: by = \'k1\', NA matches nothing [outer]',
	  left  => 'inc_x', right => 'inc_y',
	  args  => [ 'how' => 'outer', 'on' => 'k1' ],
	  want_cols => ['k1', 'k2.x', 'data.x', 'k2.y', 'data.y'],
	  want_rows => [ ['2', undef, undef, undef, 2],
	                 ['3', undef, 3, undef, undef],
	                 ['4', 4, 4, 4, 4],
	                 ['5', 5, 5, 5, 5],
	                 [undef, 1, 1, undef, undef],
	                 [undef, undef, 2, undef, undef],
	                 [undef, undef, undef, undef, 1],
	                 [undef, undef, undef, 3, 3],
	               ],
	},
	{ name  => 'merge.Rd incomparables: by = \'k2\', NA matches nothing [inner]',
	  left  => 'inc_x', right => 'inc_y',
	  args  => [ 'how' => 'inner', 'on' => 'k2' ],
	  want_cols => ['k2', 'k1.x', 'data.x', 'k1.y', 'data.y'],
	  want_rows => [ ['4', 4, 4, 4, 4],
	                 ['5', 5, 5, 5, 5],
	               ],
	},
	{ name  => 'merge.Rd incomparables: by = \'k2\', NA matches nothing [left]',
	  left  => 'inc_x', right => 'inc_y',
	  args  => [ 'how' => 'left', 'on' => 'k2' ],
	  want_cols => ['k2', 'k1.x', 'data.x', 'k1.y', 'data.y'],
	  want_rows => [ ['1', undef, 1, undef, undef],
	                 ['4', 4, 4, 4, 4],
	                 ['5', 5, 5, 5, 5],
	                 [undef, undef, 2, undef, undef],
	                 [undef, 3, 3, undef, undef],
	               ],
	},
	{ name  => 'merge.Rd incomparables: by = \'k2\', NA matches nothing [right]',
	  left  => 'inc_x', right => 'inc_y',
	  args  => [ 'how' => 'right', 'on' => 'k2' ],
	  want_cols => ['k2', 'k1.x', 'data.x', 'k1.y', 'data.y'],
	  want_rows => [ ['3', undef, undef, undef, 3],
	                 ['4', 4, 4, 4, 4],
	                 ['5', 5, 5, 5, 5],
	                 [undef, undef, undef, undef, 1],
	                 [undef, undef, undef, 2, 2],
	               ],
	},
	{ name  => 'merge.Rd incomparables: by = \'k2\', NA matches nothing [outer]',
	  left  => 'inc_x', right => 'inc_y',
	  args  => [ 'how' => 'outer', 'on' => 'k2' ],
	  want_cols => ['k2', 'k1.x', 'data.x', 'k1.y', 'data.y'],
	  want_rows => [ ['1', undef, 1, undef, undef],
	                 ['3', undef, undef, undef, 3],
	                 ['4', 4, 4, 4, 4],
	                 ['5', 5, 5, 5, 5],
	                 [undef, undef, 2, undef, undef],
	                 [undef, 3, 3, undef, undef],
	                 [undef, undef, undef, undef, 1],
	                 [undef, undef, undef, 2, 2],
	               ],
	},
	{ name  => 'merge.Rd: R\'s own incomparables = NA, by = \'k1\' [inner]',
	  left  => 'inc_x', right => 'inc_y',
	  args  => [ 'how' => 'inner', 'on' => 'k1' ],
	  want_cols => ['k1', 'k2.x', 'data.x', 'k2.y', 'data.y'],
	  want_rows => [ [4, 4, 4, 4, 4],
	                 [5, 5, 5, 5, 5],
	               ],
	},
	{ name  => 'merge.Rd: R\'s own incomparables = NA, by = \'k1\' [left]',
	  left  => 'inc_x', right => 'inc_y',
	  args  => [ 'how' => 'left', 'on' => 'k1' ],
	  want_cols => ['k1', 'k2.x', 'data.x', 'k2.y', 'data.y'],
	  want_rows => [ [3, undef, 3, undef, undef],
	                 [4, 4, 4, 4, 4],
	                 [5, 5, 5, 5, 5],
	                 [undef, 1, 1, undef, undef],
	                 [undef, undef, 2, undef, undef],
	               ],
	},
	{ name  => 'merge.Rd: R\'s own incomparables = NA, by = \'k1\' [right]',
	  left  => 'inc_x', right => 'inc_y',
	  args  => [ 'how' => 'right', 'on' => 'k1' ],
	  want_cols => ['k1', 'k2.x', 'data.x', 'k2.y', 'data.y'],
	  want_rows => [ [2, undef, undef, undef, 2],
	                 [4, 4, 4, 4, 4],
	                 [5, 5, 5, 5, 5],
	                 [undef, undef, undef, undef, 1],
	                 [undef, undef, undef, 3, 3],
	               ],
	},
	{ name  => 'merge.Rd: R\'s own incomparables = NA, by = \'k1\' [outer]',
	  left  => 'inc_x', right => 'inc_y',
	  args  => [ 'how' => 'outer', 'on' => 'k1' ],
	  want_cols => ['k1', 'k2.x', 'data.x', 'k2.y', 'data.y'],
	  want_rows => [ [2, undef, undef, undef, 2],
	                 [3, undef, 3, undef, undef],
	                 [4, 4, 4, 4, 4],
	                 [5, 5, 5, 5, 5],
	                 [undef, 1, 1, undef, undef],
	                 [undef, undef, 2, undef, undef],
	                 [undef, undef, undef, undef, 1],
	                 [undef, undef, undef, 3, 3],
	               ],
	},
	{ name  => 'merge.Rd: R\'s own incomparables = NA, by = \'k2\' [inner]',
	  left  => 'inc_x', right => 'inc_y',
	  args  => [ 'how' => 'inner', 'on' => 'k2' ],
	  want_cols => ['k2', 'k1.x', 'data.x', 'k1.y', 'data.y'],
	  want_rows => [ [4, 4, 4, 4, 4],
	                 [5, 5, 5, 5, 5],
	               ],
	},
	{ name  => 'merge.Rd: R\'s own incomparables = NA, by = \'k2\' [left]',
	  left  => 'inc_x', right => 'inc_y',
	  args  => [ 'how' => 'left', 'on' => 'k2' ],
	  want_cols => ['k2', 'k1.x', 'data.x', 'k1.y', 'data.y'],
	  want_rows => [ [1, undef, 1, undef, undef],
	                 [4, 4, 4, 4, 4],
	                 [5, 5, 5, 5, 5],
	                 [undef, undef, 2, undef, undef],
	                 [undef, 3, 3, undef, undef],
	               ],
	},
	{ name  => 'merge.Rd: R\'s own incomparables = NA, by = \'k2\' [right]',
	  left  => 'inc_x', right => 'inc_y',
	  args  => [ 'how' => 'right', 'on' => 'k2' ],
	  want_cols => ['k2', 'k1.x', 'data.x', 'k1.y', 'data.y'],
	  want_rows => [ [3, undef, undef, undef, 3],
	                 [4, 4, 4, 4, 4],
	                 [5, 5, 5, 5, 5],
	                 [undef, undef, undef, undef, 1],
	                 [undef, undef, undef, 2, 2],
	               ],
	},
	{ name  => 'merge.Rd: R\'s own incomparables = NA, by = \'k2\' [outer]',
	  left  => 'inc_x', right => 'inc_y',
	  args  => [ 'how' => 'outer', 'on' => 'k2' ],
	  want_cols => ['k2', 'k1.x', 'data.x', 'k1.y', 'data.y'],
	  want_rows => [ [1, undef, 1, undef, undef],
	                 [3, undef, undef, undef, 3],
	                 [4, 4, 4, 4, 4],
	                 [5, 5, 5, 5, 5],
	                 [undef, undef, 2, undef, undef],
	                 [undef, 3, 3, undef, undef],
	                 [undef, undef, undef, undef, 1],
	                 [undef, undef, undef, 2, 2],
	               ],
	},
);
# END GENERATED (R)

# BEGIN GENERATED (pandas) -- python3 t/merge.R.pandas.py
# 31 frames and 60 cases, from pandas 2.2.3
my %PD_FRAMES = (
	'cross_a' => {
		cols => ['a'],
		rows => [ [1],
		          [3],
		        ],
	},
	'cross_b' => {
		cols => ['b'],
		rows => [ [3],
		          [4],
		        ],
	},
	'cross_a2' => {
		cols => ['a'],
		rows => [ [3],
		          [4],
		        ],
	},
	'cross_A' => {
		cols => ['A'],
		rows => [ ['a'],
		          ['b'],
		          ['c'],
		        ],
	},
	'cross_B' => {
		cols => ['B'],
		rows => [ [0],
		          [1],
		        ],
	},
	'cross_AB' => {
		cols => ['A', 'B'],
		rows => [ ['a', 2],
		          ['b', 1],
		        ],
	},
	'cross_CD' => {
		cols => ['C', 'D'],
		rows => [ [0, 4],
		          [1, 5],
		        ],
	},
	'cross_null_l' => {
		cols => ['a'],
		rows => [ [1],
		          [undef],
		        ],
	},
	'cross_null_r' => {
		cols => ['b', 'c'],
		rows => [ ['a', 1],
		          ['b', 2],
		        ],
	},
	'ihjk_l' => {
		cols => ['value', 'key'],
		rows => [ [0, 1],
		          [1, 1],
		          [2, 2],
		          [3, 2],
		          [4, 3],
		        ],
	},
	'ihjk_r' => {
		cols => ['key', 'rvalue'],
		rows => [ [1, 0],
		          [1, 1],
		          [2, 2],
		          [3, 3],
		          [4, 4],
		          [5, 5],
		        ],
	},
	'overlap' => {
		cols => ['key', 'v1'],
		rows => [ ['a', 10],
		          ['b', 20],
		          ['c', 30],
		          ['d', 40],
		          ['e', 50],
		          ['e', 60],
		          ['a', 70],
		        ],
	},
	'dckn_l' => {
		cols => ['lkey', 'value'],
		rows => [ ['foo', 1],
		          ['bar', 2],
		          ['baz', 3],
		          ['foo', 4],
		        ],
	},
	'dckn_r' => {
		cols => ['rkey', 'value'],
		rows => [ ['foo', 5],
		          ['bar', 6],
		          ['qux', 7],
		          ['foo', 8],
		        ],
	},
	'order_a' => {
		cols => ['a'],
		rows => [ [1],
		          [0],
		          [1],
		        ],
	},
	'lmed_l' => {
		cols => ['key', 'value'],
		rows => [ [1, 2],
		        ],
	},
	'lmed_r' => {
		cols => ['key'],
		rows => [],
	},
	'me_left' => {
		cols => ['A', 'B'],
		rows => [ [2, 3],
		          [1, 4],
		        ],
	},
	'me_right' => {
		cols => ['A', 'C'],
		rows => [ [1, 5],
		        ],
	},
	'me_left0' => {
		cols => ['A', 'B'],
		rows => [],
	},
	'me_right0' => {
		cols => ['A', 'C'],
		rows => [],
	},
	'intkey' => {
		cols => ['X'],
		rows => [ [1],
		          [2],
		          [3],
		        ],
	},
	'floatkey' => {
		cols => ['X', 'Y'],
		rows => [ [1, 1],
		          [2, 2],
		          [3, 3],
		        ],
	},
	'nak_frame' => {
		cols => ['year', 'panel', 'data'],
		rows => [ [1950, 'A', 1],
		          [1950, 'B', 1],
		          [1955, 'B', 1],
		          [1960, 'B', undef],
		          [1970, 'B', 4],
		          [1950, 'C', 4],
		          [1960, 'C', undef],
		          [1965, 'C', 3],
		          [1970, 'C', 4],
		        ],
	},
	'nak_other' => {
		cols => ['year', 'panel', 'data'],
		rows => [ [1960, 'A', undef],
		          [1970, 'A', undef],
		          [1955, 'A', undef],
		          [1965, 'A', undef],
		          [1965, 'B', undef],
		          [1955, 'C', undef],
		        ],
	},
	'mixed_df' => {
		cols => ['lev1', 'lev2', 'col'],
		rows => [ ['A', 1, 0],
		          ['A', 2, 0],
		          ['A', 3, 0],
		          ['B', 1, 0],
		          ['B', 2, 0],
		          ['B', 3, 0],
		        ],
	},
	'mixed_s' => {
		cols => ['lev1', 'lev2', 'Amount'],
		rows => [ ['A', 1, 0],
		          ['A', 2, 1],
		          ['A', 3, 2],
		          ['B', 1, 3],
		          ['B', 2, 4],
		          ['B', 3, 5],
		        ],
	},
	'm2m_l' => {
		cols => ['k', 'x'],
		rows => [ ['2012-05-02', 'a'],
		          ['2012-05-02', 'b'],
		          ['2012-05-01', 'c'],
		          ['2012-05-01', 'd'],
		        ],
	},
	'm2m_r' => {
		cols => ['k', 'y'],
		rows => [ ['2012-05-02', 'e'],
		          ['2012-05-02', 'f'],
		          ['2012-05-03', 'g'],
		          ['2012-05-01', ' h'],
		          ['2012-05-01', 'i'],
		        ],
	},
	'sfx_l' => {
		cols => ['k', 'b'],
		rows => [ [1, 1],
		          [2, 2],
		          [3, 3],
		        ],
	},
	'sfx_r' => {
		cols => ['k', 'b'],
		rows => [ [1, 4],
		          [2, 5],
		          [3, 6],
		        ],
	},
);

my @PD_CASES = (
	{ name  => 'test_merge_cross: cross_b',
	  left  => 'cross_a', right => 'cross_b',
	  args  => [ 'how' => 'cross', 'suffixes' => ['_x','_y'] ],
	  want_cols => ['a', 'b'],
	  want_rows => [ [1, 3],
	                 [1, 4],
	                 [3, 3],
	                 [3, 4],
	               ],
	},
	{ name  => 'test_merge_cross: cross_a2',
	  left  => 'cross_a', right => 'cross_a2',
	  args  => [ 'how' => 'cross', 'suffixes' => ['_x','_y'] ],
	  want_cols => ['a_x', 'a_y'],
	  want_rows => [ [1, 3],
	                 [1, 4],
	                 [3, 3],
	                 [3, 4],
	               ],
	},
	{ name  => 'test_merge_cross_mixed_dtypes',
	  left  => 'cross_A', right => 'cross_B',
	  args  => [ 'how' => 'cross' ],
	  want_cols => ['A', 'B'],
	  want_rows => [ ['a', 0],
	                 ['a', 1],
	                 ['b', 0],
	                 ['b', 1],
	                 ['c', 0],
	                 ['c', 1],
	               ],
	},
	{ name  => 'test_merge_cross_more_than_one_column',
	  left  => 'cross_AB', right => 'cross_CD',
	  args  => [ 'how' => 'cross' ],
	  want_cols => ['A', 'B', 'C', 'D'],
	  want_rows => [ ['a', 2, 0, 4],
	                 ['a', 2, 1, 5],
	                 ['b', 1, 0, 4],
	                 ['b', 1, 1, 5],
	               ],
	},
	{ name  => 'test_merge_cross_null_values',
	  left  => 'cross_null_l', right => 'cross_null_r',
	  args  => [ 'how' => 'cross' ],
	  want_cols => ['a', 'b', 'c'],
	  want_rows => [ [1, 'a', 1],
	                 [1, 'b', 2],
	                 [undef, 'a', 1],
	                 [undef, 'b', 2],
	               ],
	},
	{ name  => 'test_intelligently_handle_join_key [inner]',
	  left  => 'ihjk_l', right => 'ihjk_r',
	  args  => [ 'how' => 'inner', 'on' => 'key', 'suffixes' => ['_x','_y'] ],
	  want_cols => ['value', 'key', 'rvalue'],
	  want_rows => [ [0, 1, 0],
	                 [0, 1, 1],
	                 [1, 1, 0],
	                 [1, 1, 1],
	                 [2, 2, 2],
	                 [3, 2, 2],
	                 [4, 3, 3],
	               ],
	},
	{ name  => 'test_intelligently_handle_join_key [left]',
	  left  => 'ihjk_l', right => 'ihjk_r',
	  args  => [ 'how' => 'left', 'on' => 'key', 'suffixes' => ['_x','_y'] ],
	  want_cols => ['value', 'key', 'rvalue'],
	  want_rows => [ [0, 1, 0],
	                 [0, 1, 1],
	                 [1, 1, 0],
	                 [1, 1, 1],
	                 [2, 2, 2],
	                 [3, 2, 2],
	                 [4, 3, 3],
	               ],
	},
	{ name  => 'test_intelligently_handle_join_key [right]',
	  left  => 'ihjk_l', right => 'ihjk_r',
	  args  => [ 'how' => 'right', 'on' => 'key', 'suffixes' => ['_x','_y'] ],
	  want_cols => ['value', 'key', 'rvalue'],
	  want_rows => [ [0, 1, 0],
	                 [1, 1, 0],
	                 [0, 1, 1],
	                 [1, 1, 1],
	                 [2, 2, 2],
	                 [3, 2, 2],
	                 [4, 3, 3],
	                 [undef, 4, 4],
	                 [undef, 5, 5],
	               ],
	},
	{ name  => 'test_intelligently_handle_join_key [outer]',
	  left  => 'ihjk_l', right => 'ihjk_r',
	  args  => [ 'how' => 'outer', 'on' => 'key', 'suffixes' => ['_x','_y'] ],
	  want_cols => ['value', 'key', 'rvalue'],
	  want_rows => [ [0, 1, 0],
	                 [0, 1, 1],
	                 [1, 1, 0],
	                 [1, 1, 1],
	                 [2, 2, 2],
	                 [3, 2, 2],
	                 [4, 3, 3],
	                 [undef, 4, 4],
	                 [undef, 5, 5],
	               ],
	},
	{ name  => 'test_merge_overlap: self-join, every non-key column collides [inner]',
	  left  => 'overlap', right => 'overlap',
	  args  => [ 'how' => 'inner', 'on' => 'key', 'suffixes' => ['_x','_y'] ],
	  want_cols => ['key', 'v1_x', 'v1_y'],
	  want_rows => [ ['a', 10, 10],
	                 ['a', 10, 70],
	                 ['b', 20, 20],
	                 ['c', 30, 30],
	                 ['d', 40, 40],
	                 ['e', 50, 50],
	                 ['e', 50, 60],
	                 ['e', 60, 50],
	                 ['e', 60, 60],
	                 ['a', 70, 10],
	                 ['a', 70, 70],
	               ],
	},
	{ name  => 'test_merge_overlap: self-join, every non-key column collides [left]',
	  left  => 'overlap', right => 'overlap',
	  args  => [ 'how' => 'left', 'on' => 'key', 'suffixes' => ['_x','_y'] ],
	  want_cols => ['key', 'v1_x', 'v1_y'],
	  want_rows => [ ['a', 10, 10],
	                 ['a', 10, 70],
	                 ['b', 20, 20],
	                 ['c', 30, 30],
	                 ['d', 40, 40],
	                 ['e', 50, 50],
	                 ['e', 50, 60],
	                 ['e', 60, 50],
	                 ['e', 60, 60],
	                 ['a', 70, 10],
	                 ['a', 70, 70],
	               ],
	},
	{ name  => 'test_merge_overlap: self-join, every non-key column collides [right]',
	  left  => 'overlap', right => 'overlap',
	  args  => [ 'how' => 'right', 'on' => 'key', 'suffixes' => ['_x','_y'] ],
	  want_cols => ['key', 'v1_x', 'v1_y'],
	  want_rows => [ ['a', 10, 10],
	                 ['a', 70, 10],
	                 ['b', 20, 20],
	                 ['c', 30, 30],
	                 ['d', 40, 40],
	                 ['e', 50, 50],
	                 ['e', 60, 50],
	                 ['e', 50, 60],
	                 ['e', 60, 60],
	                 ['a', 10, 70],
	                 ['a', 70, 70],
	               ],
	},
	{ name  => 'test_merge_overlap: self-join, every non-key column collides [outer]',
	  left  => 'overlap', right => 'overlap',
	  args  => [ 'how' => 'outer', 'on' => 'key', 'suffixes' => ['_x','_y'] ],
	  want_cols => ['key', 'v1_x', 'v1_y'],
	  want_rows => [ ['a', 10, 10],
	                 ['a', 10, 70],
	                 ['a', 70, 10],
	                 ['a', 70, 70],
	                 ['b', 20, 20],
	                 ['c', 30, 30],
	                 ['d', 40, 40],
	                 ['e', 50, 50],
	                 ['e', 50, 60],
	                 ['e', 60, 50],
	                 ['e', 60, 60],
	               ],
	},
	{ name  => 'test_merge_different_column_key_names [inner]',
	  left  => 'dckn_l', right => 'dckn_r',
	  args  => [ 'how' => 'inner', 'left_on' => 'lkey', 'right_on' => 'rkey', 'suffixes' => ['_x','_y'] ],
	  want_cols => ['lkey', 'value_x', 'value_y'],
	  want_rows => [ ['foo', 1, 5],
	                 ['foo', 1, 8],
	                 ['bar', 2, 6],
	                 ['foo', 4, 5],
	                 ['foo', 4, 8],
	               ],
	},
	{ name  => 'test_merge_different_column_key_names [left]',
	  left  => 'dckn_l', right => 'dckn_r',
	  args  => [ 'how' => 'left', 'left_on' => 'lkey', 'right_on' => 'rkey', 'suffixes' => ['_x','_y'] ],
	  want_cols => ['lkey', 'value_x', 'value_y'],
	  want_rows => [ ['foo', 1, 5],
	                 ['foo', 1, 8],
	                 ['bar', 2, 6],
	                 ['baz', 3, undef],
	                 ['foo', 4, 5],
	                 ['foo', 4, 8],
	               ],
	},
	{ name  => 'test_merge_different_column_key_names [right]',
	  left  => 'dckn_l', right => 'dckn_r',
	  args  => [ 'how' => 'right', 'left_on' => 'lkey', 'right_on' => 'rkey', 'suffixes' => ['_x','_y'] ],
	  want_cols => ['lkey', 'value_x', 'value_y'],
	  want_rows => [ ['foo', 1, 5],
	                 ['foo', 4, 5],
	                 ['bar', 2, 6],
	                 ['qux', undef, 7],
	                 ['foo', 1, 8],
	                 ['foo', 4, 8],
	               ],
	},
	{ name  => 'test_merge_different_column_key_names [outer]',
	  left  => 'dckn_l', right => 'dckn_r',
	  args  => [ 'how' => 'outer', 'left_on' => 'lkey', 'right_on' => 'rkey', 'suffixes' => ['_x','_y'] ],
	  want_cols => ['lkey', 'value_x', 'value_y'],
	  want_rows => [ ['bar', 2, 6],
	                 ['baz', 3, undef],
	                 ['foo', 1, 5],
	                 ['foo', 1, 8],
	                 ['foo', 4, 5],
	                 ['foo', 4, 8],
	                 ['qux', undef, 7],
	               ],
	},
	{ name  => 'test_merge_same_order_left_right [inner]',
	  left  => 'order_a', right => 'order_a',
	  args  => [ 'how' => 'inner', 'on' => 'a', 'suffixes' => ['_x','_y'] ],
	  want_cols => ['a'],
	  want_rows => [ [1],
	                 [1],
	                 [0],
	                 [1],
	                 [1],
	               ],
	},
	{ name  => 'test_merge_same_order_left_right [left]',
	  left  => 'order_a', right => 'order_a',
	  args  => [ 'how' => 'left', 'on' => 'a', 'suffixes' => ['_x','_y'] ],
	  want_cols => ['a'],
	  want_rows => [ [1],
	                 [1],
	                 [0],
	                 [1],
	                 [1],
	               ],
	},
	{ name  => 'test_merge_same_order_left_right [right]',
	  left  => 'order_a', right => 'order_a',
	  args  => [ 'how' => 'right', 'on' => 'a', 'suffixes' => ['_x','_y'] ],
	  want_cols => ['a'],
	  want_rows => [ [1],
	                 [1],
	                 [0],
	                 [1],
	                 [1],
	               ],
	},
	{ name  => 'test_merge_same_order_left_right [outer]',
	  left  => 'order_a', right => 'order_a',
	  args  => [ 'how' => 'outer', 'on' => 'a', 'suffixes' => ['_x','_y'] ],
	  want_cols => ['a'],
	  want_rows => [ [0],
	                 [1],
	                 [1],
	                 [1],
	                 [1],
	               ],
	},
	{ name  => 'test_left_merge_empty_dataframe [inner]',
	  left  => 'lmed_l', right => 'lmed_r',
	  args  => [ 'how' => 'inner', 'on' => 'key', 'suffixes' => ['_x','_y'] ],
	  shapes => 'hoa',
	  want_cols => ['key', 'value'],
	  want_rows => [],
	},
	{ name  => 'test_left_merge_empty_dataframe [left]',
	  left  => 'lmed_l', right => 'lmed_r',
	  args  => [ 'how' => 'left', 'on' => 'key', 'suffixes' => ['_x','_y'] ],
	  shapes => 'hoa',
	  want_cols => ['key', 'value'],
	  want_rows => [ [1, 2],
	               ],
	},
	{ name  => 'test_left_merge_empty_dataframe [right]',
	  left  => 'lmed_l', right => 'lmed_r',
	  args  => [ 'how' => 'right', 'on' => 'key', 'suffixes' => ['_x','_y'] ],
	  shapes => 'hoa',
	  want_cols => ['key', 'value'],
	  want_rows => [],
	},
	{ name  => 'test_left_merge_empty_dataframe [outer]',
	  left  => 'lmed_l', right => 'lmed_r',
	  args  => [ 'how' => 'outer', 'on' => 'key', 'suffixes' => ['_x','_y'] ],
	  shapes => 'hoa',
	  want_cols => ['key', 'value'],
	  want_rows => [ [1, 2],
	               ],
	},
	{ name  => 'test_left_merge_empty_dataframe, reversed [inner]',
	  left  => 'lmed_r', right => 'lmed_l',
	  args  => [ 'how' => 'inner', 'on' => 'key', 'suffixes' => ['_x','_y'] ],
	  shapes => 'hoa',
	  want_cols => ['key', 'value'],
	  want_rows => [],
	},
	{ name  => 'test_left_merge_empty_dataframe, reversed [left]',
	  left  => 'lmed_r', right => 'lmed_l',
	  args  => [ 'how' => 'left', 'on' => 'key', 'suffixes' => ['_x','_y'] ],
	  shapes => 'hoa',
	  want_cols => ['key', 'value'],
	  want_rows => [],
	},
	{ name  => 'test_left_merge_empty_dataframe, reversed [right]',
	  left  => 'lmed_r', right => 'lmed_l',
	  args  => [ 'how' => 'right', 'on' => 'key', 'suffixes' => ['_x','_y'] ],
	  shapes => 'hoa',
	  want_cols => ['key', 'value'],
	  want_rows => [ [1, 2],
	               ],
	},
	{ name  => 'test_left_merge_empty_dataframe, reversed [outer]',
	  left  => 'lmed_r', right => 'lmed_l',
	  args  => [ 'how' => 'outer', 'on' => 'key', 'suffixes' => ['_x','_y'] ],
	  shapes => 'hoa',
	  want_cols => ['key', 'value'],
	  want_rows => [ [1, 2],
	               ],
	},
	{ name  => 'test_merge_empty: right empty [inner]',
	  left  => 'me_left', right => 'me_right0',
	  args  => [ 'how' => 'inner', 'on' => 'A', 'suffixes' => ['_x','_y'] ],
	  shapes => 'hoa',
	  want_cols => ['A', 'B', 'C'],
	  want_rows => [],
	},
	{ name  => 'test_merge_empty: right empty [left]',
	  left  => 'me_left', right => 'me_right0',
	  args  => [ 'how' => 'left', 'on' => 'A', 'suffixes' => ['_x','_y'] ],
	  shapes => 'hoa',
	  want_cols => ['A', 'B', 'C'],
	  want_rows => [ [2, 3, undef],
	                 [1, 4, undef],
	               ],
	},
	{ name  => 'test_merge_empty: right empty [right]',
	  left  => 'me_left', right => 'me_right0',
	  args  => [ 'how' => 'right', 'on' => 'A', 'suffixes' => ['_x','_y'] ],
	  shapes => 'hoa',
	  want_cols => ['A', 'B', 'C'],
	  want_rows => [],
	},
	{ name  => 'test_merge_empty: right empty [outer]',
	  left  => 'me_left', right => 'me_right0',
	  args  => [ 'how' => 'outer', 'on' => 'A', 'suffixes' => ['_x','_y'] ],
	  shapes => 'hoa',
	  want_cols => ['A', 'B', 'C'],
	  want_rows => [ [1, 4, undef],
	                 [2, 3, undef],
	               ],
	},
	{ name  => 'test_merge_empty: right empty [cross]',
	  left  => 'me_left', right => 'me_right0',
	  args  => [ 'how' => 'cross', 'suffixes' => ['_x','_y'] ],
	  shapes => 'hoa',
	  want_cols => ['A_x', 'B', 'A_y', 'C'],
	  want_rows => [],
	},
	{ name  => 'test_merge_empty: left empty [inner]',
	  left  => 'me_left0', right => 'me_right',
	  args  => [ 'how' => 'inner', 'on' => 'A', 'suffixes' => ['_x','_y'] ],
	  shapes => 'hoa',
	  want_cols => ['A', 'B', 'C'],
	  want_rows => [],
	},
	{ name  => 'test_merge_empty: left empty [left]',
	  left  => 'me_left0', right => 'me_right',
	  args  => [ 'how' => 'left', 'on' => 'A', 'suffixes' => ['_x','_y'] ],
	  shapes => 'hoa',
	  want_cols => ['A', 'B', 'C'],
	  want_rows => [],
	},
	{ name  => 'test_merge_empty: left empty [right]',
	  left  => 'me_left0', right => 'me_right',
	  args  => [ 'how' => 'right', 'on' => 'A', 'suffixes' => ['_x','_y'] ],
	  shapes => 'hoa',
	  want_cols => ['A', 'B', 'C'],
	  want_rows => [ [1, undef, 5],
	               ],
	},
	{ name  => 'test_merge_empty: left empty [outer]',
	  left  => 'me_left0', right => 'me_right',
	  args  => [ 'how' => 'outer', 'on' => 'A', 'suffixes' => ['_x','_y'] ],
	  shapes => 'hoa',
	  want_cols => ['A', 'B', 'C'],
	  want_rows => [ [1, undef, 5],
	               ],
	},
	{ name  => 'test_merge_empty: left empty [cross]',
	  left  => 'me_left0', right => 'me_right',
	  args  => [ 'how' => 'cross', 'suffixes' => ['_x','_y'] ],
	  shapes => 'hoa',
	  want_cols => ['A_x', 'B', 'A_y', 'C'],
	  want_rows => [],
	},
	{ name  => 'test_merge_on_ints_floats [inner]',
	  left  => 'intkey', right => 'floatkey',
	  args  => [ 'how' => 'inner', 'on' => 'X', 'suffixes' => ['_x','_y'] ],
	  want_cols => ['X', 'Y'],
	  want_rows => [ [1, 1],
	                 [2, 2],
	                 [3, 3],
	               ],
	},
	{ name  => 'test_merge_on_ints_floats [left]',
	  left  => 'intkey', right => 'floatkey',
	  args  => [ 'how' => 'left', 'on' => 'X', 'suffixes' => ['_x','_y'] ],
	  want_cols => ['X', 'Y'],
	  want_rows => [ [1, 1],
	                 [2, 2],
	                 [3, 3],
	               ],
	},
	{ name  => 'test_merge_on_ints_floats [right]',
	  left  => 'intkey', right => 'floatkey',
	  args  => [ 'how' => 'right', 'on' => 'X', 'suffixes' => ['_x','_y'] ],
	  want_cols => ['X', 'Y'],
	  want_rows => [ [1, 1],
	                 [2, 2],
	                 [3, 3],
	               ],
	},
	{ name  => 'test_merge_on_ints_floats [outer]',
	  left  => 'intkey', right => 'floatkey',
	  args  => [ 'how' => 'outer', 'on' => 'X', 'suffixes' => ['_x','_y'] ],
	  want_cols => ['X', 'Y'],
	  want_rows => [ [1, 1],
	                 [2, 2],
	                 [3, 3],
	               ],
	},
	{ name  => 'test_merge_na_keys: three key columns, one of them NaN [inner]',
	  left  => 'nak_frame', right => 'nak_other',
	  args  => [ 'how' => 'inner', 'on' => ['year', 'panel', 'data'], 'suffixes' => ['_x','_y'] ],
	  want_cols => ['year', 'panel', 'data'],
	  want_rows => [],
	},
	{ name  => 'test_merge_na_keys: three key columns, one of them NaN [left]',
	  left  => 'nak_frame', right => 'nak_other',
	  args  => [ 'how' => 'left', 'on' => ['year', 'panel', 'data'], 'suffixes' => ['_x','_y'] ],
	  want_cols => ['year', 'panel', 'data'],
	  want_rows => [ [1950, 'A', 1],
	                 [1950, 'B', 1],
	                 [1955, 'B', 1],
	                 [1960, 'B', undef],
	                 [1970, 'B', 4],
	                 [1950, 'C', 4],
	                 [1960, 'C', undef],
	                 [1965, 'C', 3],
	                 [1970, 'C', 4],
	               ],
	},
	{ name  => 'test_merge_na_keys: three key columns, one of them NaN [right]',
	  left  => 'nak_frame', right => 'nak_other',
	  args  => [ 'how' => 'right', 'on' => ['year', 'panel', 'data'], 'suffixes' => ['_x','_y'] ],
	  want_cols => ['year', 'panel', 'data'],
	  want_rows => [ [1960, 'A', undef],
	                 [1970, 'A', undef],
	                 [1955, 'A', undef],
	                 [1965, 'A', undef],
	                 [1965, 'B', undef],
	                 [1955, 'C', undef],
	               ],
	},
	{ name  => 'test_merge_na_keys: three key columns, one of them NaN [outer]',
	  left  => 'nak_frame', right => 'nak_other',
	  args  => [ 'how' => 'outer', 'on' => ['year', 'panel', 'data'], 'suffixes' => ['_x','_y'] ],
	  want_cols => ['year', 'panel', 'data'],
	  want_rows => [ [1950, 'A', 1],
	                 [1950, 'B', 1],
	                 [1950, 'C', 4],
	                 [1955, 'A', undef],
	                 [1955, 'B', 1],
	                 [1955, 'C', undef],
	                 [1960, 'A', undef],
	                 [1960, 'B', undef],
	                 [1960, 'C', undef],
	                 [1965, 'A', undef],
	                 [1965, 'B', undef],
	                 [1965, 'C', 3],
	                 [1970, 'A', undef],
	                 [1970, 'B', 4],
	                 [1970, 'C', 4],
	               ],
	},
	{ name  => 'test_merge_multiple_cols_with_mixed_cols_index [inner]',
	  left  => 'mixed_df', right => 'mixed_s',
	  args  => [ 'how' => 'inner', 'on' => ['lev1', 'lev2'], 'suffixes' => ['_x','_y'] ],
	  want_cols => ['lev1', 'lev2', 'col', 'Amount'],
	  want_rows => [ ['A', 1, 0, 0],
	                 ['A', 2, 0, 1],
	                 ['A', 3, 0, 2],
	                 ['B', 1, 0, 3],
	                 ['B', 2, 0, 4],
	                 ['B', 3, 0, 5],
	               ],
	},
	{ name  => 'test_merge_multiple_cols_with_mixed_cols_index [left]',
	  left  => 'mixed_df', right => 'mixed_s',
	  args  => [ 'how' => 'left', 'on' => ['lev1', 'lev2'], 'suffixes' => ['_x','_y'] ],
	  want_cols => ['lev1', 'lev2', 'col', 'Amount'],
	  want_rows => [ ['A', 1, 0, 0],
	                 ['A', 2, 0, 1],
	                 ['A', 3, 0, 2],
	                 ['B', 1, 0, 3],
	                 ['B', 2, 0, 4],
	                 ['B', 3, 0, 5],
	               ],
	},
	{ name  => 'test_merge_multiple_cols_with_mixed_cols_index [right]',
	  left  => 'mixed_df', right => 'mixed_s',
	  args  => [ 'how' => 'right', 'on' => ['lev1', 'lev2'], 'suffixes' => ['_x','_y'] ],
	  want_cols => ['lev1', 'lev2', 'col', 'Amount'],
	  want_rows => [ ['A', 1, 0, 0],
	                 ['A', 2, 0, 1],
	                 ['A', 3, 0, 2],
	                 ['B', 1, 0, 3],
	                 ['B', 2, 0, 4],
	                 ['B', 3, 0, 5],
	               ],
	},
	{ name  => 'test_merge_multiple_cols_with_mixed_cols_index [outer]',
	  left  => 'mixed_df', right => 'mixed_s',
	  args  => [ 'how' => 'outer', 'on' => ['lev1', 'lev2'], 'suffixes' => ['_x','_y'] ],
	  want_cols => ['lev1', 'lev2', 'col', 'Amount'],
	  want_rows => [ ['A', 1, 0, 0],
	                 ['A', 2, 0, 1],
	                 ['A', 3, 0, 2],
	                 ['B', 1, 0, 3],
	                 ['B', 2, 0, 4],
	                 ['B', 3, 0, 5],
	               ],
	},
	{ name  => 'test_merge_non_unique_index_many_to_many [inner]',
	  left  => 'm2m_l', right => 'm2m_r',
	  args  => [ 'how' => 'inner', 'on' => 'k', 'suffixes' => ['_x','_y'] ],
	  want_cols => ['k', 'x', 'y'],
	  want_rows => [ ['2012-05-02', 'a', 'e'],
	                 ['2012-05-02', 'a', 'f'],
	                 ['2012-05-02', 'b', 'e'],
	                 ['2012-05-02', 'b', 'f'],
	                 ['2012-05-01', 'c', ' h'],
	                 ['2012-05-01', 'c', 'i'],
	                 ['2012-05-01', 'd', ' h'],
	                 ['2012-05-01', 'd', 'i'],
	               ],
	},
	{ name  => 'test_merge_non_unique_index_many_to_many [left]',
	  left  => 'm2m_l', right => 'm2m_r',
	  args  => [ 'how' => 'left', 'on' => 'k', 'suffixes' => ['_x','_y'] ],
	  want_cols => ['k', 'x', 'y'],
	  want_rows => [ ['2012-05-02', 'a', 'e'],
	                 ['2012-05-02', 'a', 'f'],
	                 ['2012-05-02', 'b', 'e'],
	                 ['2012-05-02', 'b', 'f'],
	                 ['2012-05-01', 'c', ' h'],
	                 ['2012-05-01', 'c', 'i'],
	                 ['2012-05-01', 'd', ' h'],
	                 ['2012-05-01', 'd', 'i'],
	               ],
	},
	{ name  => 'test_merge_non_unique_index_many_to_many [right]',
	  left  => 'm2m_l', right => 'm2m_r',
	  args  => [ 'how' => 'right', 'on' => 'k', 'suffixes' => ['_x','_y'] ],
	  want_cols => ['k', 'x', 'y'],
	  want_rows => [ ['2012-05-02', 'a', 'e'],
	                 ['2012-05-02', 'b', 'e'],
	                 ['2012-05-02', 'a', 'f'],
	                 ['2012-05-02', 'b', 'f'],
	                 ['2012-05-03', undef, 'g'],
	                 ['2012-05-01', 'c', ' h'],
	                 ['2012-05-01', 'd', ' h'],
	                 ['2012-05-01', 'c', 'i'],
	                 ['2012-05-01', 'd', 'i'],
	               ],
	},
	{ name  => 'test_merge_non_unique_index_many_to_many [outer]',
	  left  => 'm2m_l', right => 'm2m_r',
	  args  => [ 'how' => 'outer', 'on' => 'k', 'suffixes' => ['_x','_y'] ],
	  want_cols => ['k', 'x', 'y'],
	  want_rows => [ ['2012-05-01', 'c', ' h'],
	                 ['2012-05-01', 'c', 'i'],
	                 ['2012-05-01', 'd', ' h'],
	                 ['2012-05-01', 'd', 'i'],
	                 ['2012-05-02', 'a', 'e'],
	                 ['2012-05-02', 'a', 'f'],
	                 ['2012-05-02', 'b', 'e'],
	                 ['2012-05-02', 'b', 'f'],
	                 ['2012-05-03', undef, 'g'],
	               ],
	},
	{ name  => 'test_merge_suffix: suffixes = (\'\', \'_dup\')',
	  left  => 'sfx_l', right => 'sfx_r',
	  args  => [ 'how' => 'inner', 'on' => 'k', 'suffixes' => ['', '_dup'] ],
	  want_cols => ['k', 'b', 'b_dup'],
	  want_rows => [ [1, 1, 4],
	                 [2, 2, 5],
	                 [3, 3, 6],
	               ],
	},
	{ name  => 'test_merge_suffix: suffixes = (\'_x\', \'_y\')',
	  left  => 'sfx_l', right => 'sfx_r',
	  args  => [ 'how' => 'inner', 'on' => 'k', 'suffixes' => ['_x','_y'] ],
	  want_cols => ['k', 'b_x', 'b_y'],
	  want_rows => [ [1, 1, 4],
	                 [2, 2, 5],
	                 [3, 3, 6],
	               ],
	},
	{ name  => 'test_merge_suffix: suffixes = (None, \'_y\')',
	  left  => 'sfx_l', right => 'sfx_r',
	  args  => [ 'how' => 'inner', 'on' => 'k', 'suffixes' => ['', '_y'] ],
	  want_cols => ['k', 'b', 'b_y'],
	  want_rows => [ [1, 1, 4],
	                 [2, 2, 5],
	                 [3, 3, 6],
	               ],
	},
	{ name  => 'test_merge_suffix: suffixes = (\'_x\', None)',
	  left  => 'sfx_l', right => 'sfx_r',
	  args  => [ 'how' => 'inner', 'on' => 'k', 'suffixes' => ['_x',''] ],
	  want_cols => ['k', 'b_x', 'b'],
	  want_rows => [ [1, 1, 4],
	                 [2, 2, 5],
	                 [3, 3, 6],
	               ],
	},
	{ name  => 'test_merge_suffix: suffixes = (\'_a\', None)',
	  left  => 'sfx_l', right => 'sfx_r',
	  args  => [ 'how' => 'inner', 'on' => 'k', 'suffixes' => ['_a',''] ],
	  want_cols => ['k', 'b_a', 'b'],
	  want_rows => [ [1, 1, 4],
	                 [2, 2, 5],
	                 [3, 3, 6],
	               ],
	},
);
# END GENERATED (pandas)

# ------------------------------------------------------- the two frozen tables

check_case(\%R_FRAMES,  $_) for @R_CASES;
check_case(\%PD_FRAMES, $_) for @PD_CASES;

# --------------------------------------------------- R's own argument spelling
#
# The same joins written the way R names the arguments: `by`, `by_x` and
# `by_y` (R's by, by.x and by.y, with the dot made an underscore as everywhere
# in this module) are documented synonyms for `on`, `left_on` and `right_on`,
# pandas' names, so a case taken from either reference suite has to give the
# same answer through either spelling.  The dotted spellings are refused.
{
	my %R_SPELLING = ('on' => 'by', 'left_on' => 'by_x', 'right_on' => 'by_y');
	for my $s ([ 'R (by/by_x/by_y)', \%R_SPELLING ]) {
		my ($who, $alias) = @$s;
		my $bad  = '';
		my $seen = 0;
		for my $c (@R_CASES) {
			my @args = @{ $c->{args} };
			my $any  = 0;
			for (my $i = 0; $i < @args; $i += 2) {
				next unless exists $alias->{ $args[$i] };
				$args[$i] = $alias->{ $args[$i] };
				$any = 1;
			}
			next unless $any;
			$seen++;
			my $L = $R_FRAMES{ $c->{left} };
			my $R = $R_FRAMES{ $c->{right} };
			my $shape = (($c->{shapes} || '') eq 'hoa') ? 'hoa' : 'aoh';
			my $one = merge(build($shape, $L->{cols}, $L->{rows}),
			                build($shape, $R->{cols}, $R->{rows}),
			                @{ $c->{args} });
			my $two = merge(build($shape, $L->{cols}, $L->{rows}),
			                build($shape, $R->{cols}, $R->{rows}), @args);
			next if sig($one) eq sig($two);
			$bad = $c->{name};
			last;
		}
		is $bad, '', "the $who spelling names the same call ($seen cases)";
	}
	# and the output_type spellings, which have two accepted forms
	my $L = { a => [ 1, 2 ], v => [ 'x', 'y' ] };
	my $R = { a => [ 2, 3 ], w => [ 'p', 'q' ] };
	for my $spelling (qw(output_type out)) {
		is ref merge($L, $R, on => 'a', $spelling => 'hoa'), 'HASH',
			"$spelling => 'hoa' asks for a hash of arrays";
	}
	# R's dotted spellings are refused rather than taken as synonyms
	for my $dotted (qw(left.on right.on by.x by.y output.type)) {
		ok !eval { merge($L, $R, on => 'a', $dotted => 'a'); 1 }
			&& $@ =~ /unknown option '\Q$dotted\E'/, "the dotted '$dotted' is refused";
	}
	# `full` is documented as an alias for `outer`, which is R's all = TRUE
	is sig(merge($L, $R, how => 'full',  on => 'a')),
	   sig(merge($L, $R, how => 'outer', on => 'a')),
	   "how => 'full' is how => 'outer'";
}

# ------------------------------------------------------------------ row order
#
# The frozen comparisons above are order-independent on purpose: R sorts its
# answer on the key columns (sort = TRUE by default) and pandas does not, so
# there is no single reference order to pin.  What merge() actually does is
# pandas' sort = False for the inner and left joins -- left rows in left order,
# each one's matches in right order -- and this pins it, because nothing else
# in the suite does.  Checked against
# pandas.DataFrame.merge(..., sort=False) 2.2.3 on this data:
#   inner [(2,'a','X'), (2,'a','Z'), (2,'c','X'), (2,'c','Z')]
#   left  [(2,'a','X'), (2,'a','Z'), (1,'b',nan), (2,'c','X'), (2,'c','Z')]
# For the right and outer joins pandas' own order differs from merge()'s
# (pandas walks the right frame for a right join, and sorts an outer join even
# with sort = False), so those two are pinned as merge()'s own behaviour:
# matched pairs first, in left order, then the unmatched right rows in right
# order.
{
	my $L = [ { k => 2, v => 'a' }, { k => 1, v => 'b' }, { k => 2, v => 'c' } ];
	my $R = [ { k => 2, w => 'X' }, { k => 3, w => 'Y' }, { k => 2, w => 'Z' } ];
	my $flat = sub {
		join ' ', map {
			join '/', map { defined $_ ? $_ : '-' } @{$_}{ qw(k v w) }
		} @{ $_[0] };
	};
	is $flat->(merge($L, $R, how => 'inner', on => 'k')),
	   '2/a/X 2/a/Z 2/c/X 2/c/Z', 'inner join row order is pandas sort=False';
	is $flat->(merge($L, $R, how => 'left', on => 'k')),
	   '2/a/X 2/a/Z 1/b/- 2/c/X 2/c/Z', 'left join row order is pandas sort=False';
	is $flat->(merge($L, $R, how => 'right', on => 'k')),
	   '2/a/X 2/a/Z 2/c/X 2/c/Z 3/-/Y',
	   'right join: matches in left order, then unmatched right rows';
	is $flat->(merge($L, $R, how => 'outer', on => 'k')),
	   '2/a/X 2/a/Z 1/b/- 2/c/X 2/c/Z 3/-/Y',
	   'outer join: the left join, then unmatched right rows';
	# and the cross join is left-major, which is both references' order
	my $cross = merge([ { a => 1 }, { a => 3 } ], [ { b => 3 }, { b => 4 } ],
	                  how => 'cross');
	is join(' ', map { "$_->{a}:$_->{b}" } @$cross), '1:3 1:4 3:3 3:4',
	   'cross join is left-major (test_merge_cross GH#5401)';
}

# ---------------------------------------------------------------- empty frames
#
# R's merge(women[FALSE, ], women) and pandas' test_left_merge_empty_dataframe
# both keep the empty frame's column names, because a zero-row data frame in
# both still has columns.  A zero-row perl AoH does not: its rows are where the
# column names live, so there is nothing left to read.  The frozen cases above
# therefore run those joins as HoA on both sides; this is what the AoH form
# does instead, which is a shape limitation rather than a join result, and is
# pinned here so a change to it is deliberate.
{
	throws_ok { merge([], [ { a => 1 } ], on => 'a', how => 'right') }
		qr/left frame has no join column 'a'/,
		'an empty AoH has no columns, so a named key is missing (left)';
	throws_ok { merge([ { a => 1 } ], [], on => 'a', how => 'left') }
		qr/right frame has no join column 'a'/,
		'an empty AoH has no columns, so a named key is missing (right)';
	throws_ok { merge([], [ { a => 1 } ]) }
		qr/no common columns/,
		'an empty AoH has no columns, so a natural join has no keys';
	# an empty HoA keeps them, so the same joins go through
	is_deeply merge({ a => [], v => [] }, [ { a => 1, w => 2 } ],
	                on => 'a', how => 'right', 'output_type' => 'hoa'),
		{ a => [1], v => [undef], w => [2] },
		'an empty HoA keeps its columns, and a right join keeps the right row';
	# a cross join reads no keys at all, so an empty AoH is simply no rows
	is_deeply merge([], [ { a => 1 } ], how => 'cross', 'output_type' => 'hoa'),
		{ a => [] }, 'cross join with an empty AoH is empty (test_merge_empty)';
}

# ------------------------------------------------- error paths, from the suites
#
# Every case here is a call one of the references documents as an error, or as a
# warning it promotes to an error.  merge() croaks on all of them.
{
	# tests/reg-tests-1b.R: d1 already has a column named b.x, so the default
	# suffixes cannot make the names unique.  R warns (the test runs it under
	# options(warn = 2), so it is an error there); merge() croaks.  The
	# suffixes = c("", ".y") form that R's test then shows working is in the
	# frozen table above.
	my $d1 = [ map { { a => $_, b => $_, 'b.x' => 6 - $_ } } 1 .. 5 ];
	my $d2 = [ map { { a => $_, b => 100 + $_ } } 1 .. 5 ];
	throws_ok { merge($d1, $d2, on => 'a') }
		qr/output column 'b\.x' collides/,
		"reg-tests-1b.R: a pre-existing b.x makes the default suffixes unusable";
	throws_ok { merge($d1, $d2, on => 'a', suffixes => ['.z', '.z']) }
		qr/output column 'b\.z' collides/,
		"reg-tests-1b.R: suffixes = c('.z','.z') cannot make names unique";

	# tests/reg-tests-1c.R, similar to PR#15618: X carries Settle, Settle.x and
	# Settle.y, so suffixing Settle collides with a column already there.
	# Failed silently in R < 3.1.0; R now warns, merge() croaks.
	my $X = [ { Date => '1967-02-01', 'Settle.x' => undef,
	            'Settle.y' => undef, Settle => 35 } ];
	my $Y = [ { Date => '1967-02-01', Settle => 16 } ];
	throws_ok { merge($X, $Y, on => 'Date', how => 'outer') }
		qr/output column 'Settle\.x' collides/,
		'reg-tests-1c.R PR#15618: duplicated column names after suffixing';

	# pandas test_merge.py::test_merge_suffixes_produce_dup_columns_raises
	# (GH#22818, enforced in pandas 2.0): the same shape with pandas' suffixes.
	throws_ok {
		merge([ { a => 1, b => 1, b_x => 2 } ], [ { a => 1, b => 2 } ],
		      on => 'a', suffixes => ['_x', '_y'])
	} qr/output column 'b_x' collides/,
		'test_merge_suffixes_produce_dup_columns_raises';

	# pandas test_merge.py::test_merge_suffix_error: a suffix pair that renames
	# nothing leaves the two copies of a column on top of each other.  pandas
	# raises "columns overlap but no suffix specified".
	throws_ok {
		merge([ { a => 1, b => 1 } ], [ { a => 1, b => 2 } ],
		      on => 'a', suffixes => ['', ''])
	} qr/output column 'b' collides/,
		'test_merge_suffix_error: two empty suffixes cannot separate the copies';

	# pandas test_merge.py::test_merge_suffix_length_error: a suffix list that
	# is not a pair.
	for my $s ([ 'a', 'b', 'c' ], [ 'a' ], []) {
		throws_ok { merge([ { a => 1 } ], [ { a => 1 } ], on => 'a', suffixes => $s) }
			qr/suffixes must be a two-element array-ref/,
			'test_merge_suffix_length_error: ' . scalar(@$s) . ' suffixes';
	}

	# pandas test_merge_cross.py::test_merge_cross_error_reporting: a cross join
	# takes no keys, under any of the spellings.
	throws_ok { merge([ { a => 1 } ], [ { b => 1 } ], how => 'cross', on => 'a') }
		qr/cross join takes no join keys/, 'test_merge_cross_error_reporting: on';
	throws_ok {
		merge([ { a => 1 } ], [ { b => 1 } ], how => 'cross',
		      'left_on' => 'a', 'right_on' => 'b')
	} qr/cross join takes no join keys/,
		'test_merge_cross_error_reporting: left_on/right_on';

	# pandas test_merge.py::test_merge_join_cols_error_reporting_duplicates and
	# _missing: half a key specification, and a key the frame does not have.
	throws_ok { merge([ { a => 1 } ], [ { a => 1 } ], 'left_on' => 'a') }
		qr/'left_on' and 'right_on' must be given together/,
		'test_merge_join_cols_error_reporting: left_on without right_on';
	throws_ok {
		merge([ { a => 1, b => 1 } ], [ { c => 1 } ],
		      'left_on' => [ 'a', 'b' ], 'right_on' => ['c'])
	} qr/must name the same number of columns/,
		'left_on and right_on must be the same length';
	throws_ok { merge([ { a => 1 } ], [ { a => 1 } ], on => [ 'a', 'a' ]) }
		qr/duplicate join column 'a'/, 'a key named twice is refused';
}

# -------------------------------------------------------------- divergences
#
# Places where merge() deliberately does not do what a reference does.  Each is
# asserted, so that changing one is a deliberate act rather than a test that
# quietly starts failing.

# 1. An undef key cell matches nothing.
#
# Both references match a missing key to a missing key by default.  On
# merge.Rd's own `incomparables` example -- x with k1 = (NA,NA,3,4,5),
# k2 = (1,NA,NA,4,5) and y with k1 = (NA,2,NA,4,5), k2 = (NA,NA,3,4,5) -- R
# 4.6.1 and pandas 2.2.3 agree with each other exactly:
#
#   R      merge(x, y, by = c("k1","k2"))        3 rows: (4,4), (5,5), (NA,NA)
#   pandas x.merge(y, on = ["k1","k2"])          3 rows, the same three
#   R      merge(x, y, by = "k1")                6 rows
#   pandas x.merge(y, on = "k1")                 6 rows
#
# merge() gives 2 rows and 2 rows: the (NA, NA) pair is not a match, which is
# what R's own `incomparables = NA` does (2 rows, and merge.Rd runs exactly
# that line: `merge(x, y, by = "k2", incomparables = NA) # 2 rows`).  The
# frozen table above holds both routes for the single-column joins, so the
# rule itself is checked there; what is recorded here is the difference from
# the references' default.
{
	my $kx = { k1 => [undef, undef, 3, 4, 5], k2 => [1, undef, undef, 4, 5],
	           data => [1 .. 5] };
	my $ky = { k1 => [undef, 2, undef, 4, 5], k2 => [undef, undef, 3, 4, 5],
	           data => [1 .. 5] };
	my $two = merge($kx, $ky, on => [ 'k1', 'k2' ], 'output_type' => 'hoa');
	is scalar @{ $two->{k1} }, 2,
		'undef keys do not match: 2 rows where R and pandas give 3';
	is_deeply [ sort @{ $two->{k1} } ], [ 4, 5 ],
		'the surviving rows are the two with no undef in either key';
	my $one = merge($kx, $ky, on => 'k1', 'output_type' => 'hoa');
	is scalar @{ $one->{k1} }, 2,
		'single-column key: 2 rows where R and pandas give 6';
	# an undef key row is still a row: it comes out of a left join unmatched
	my $left = merge($kx, $ky, on => [ 'k1', 'k2' ], how => 'left',
	                 'output_type' => 'hoa');
	is scalar @{ $left->{'data.x'} }, 5,
		'a left join keeps all five left rows, matched or not';
}

# 2. Under left_on/right_on there is one key column, not two.
#
# pandas keeps both: test_merge_different_column_key_names ends with a frame
# carrying lkey *and* rkey.  R keeps one, under the by.x name, and so does
# merge(); the frozen pandas cases have the right key column dropped and the
# left one filled from it, which is what coalesce_keys() in the generator does.
{
	my $L = [ { lkey => 'foo', value => 1 }, { lkey => 'baz', value => 3 } ];
	my $R = [ { rkey => 'foo', value => 5 }, { rkey => 'qux', value => 7 } ];
	my $got = merge($L, $R, how => 'outer', 'left_on' => 'lkey',
	                'right_on' => 'rkey', suffixes => ['_x', '_y'],
	                'output_type' => 'hoa');
	is_deeply [ sort keys %$got ], [ 'lkey', 'value_x', 'value_y' ],
		'one key column under the left name, where pandas keeps lkey and rkey';
	is_deeply [ sort map { defined $_ ? $_ : 'UNDEF' } @{ $got->{lkey} } ],
		[ 'baz', 'foo', 'qux' ],
		'the single key column is filled from whichever side has the row';
}

# 3. A natural join with no shared columns is an error, not a cross join.
#
# R makes it the Cartesian product: reg-tests-1a.R's PR#4299 case does
# merge(data.frame(x = 1:5, y = letters[1:5]), data.frame(z = 1:2)) and expects
# names c("x","y","z") -- ten rows.  pandas raises
# MergeError("No common columns to perform merge on").  merge() follows pandas,
# and a cross join has to be asked for by name.
{
	throws_ok {
		merge([ { x => 1, y => 'a' } ], [ { z => 1 } ])
	} qr/no common columns to join on/,
		'reg-tests-1a.R PR#4299: no shared columns croaks, as in pandas';
	is scalar @{ merge([ { x => 1, y => 'a' }, { x => 2, y => 'b' } ],
	                   [ { z => 1 }, { z => 2 } ], how => 'cross') }, 4,
		"...and how => 'cross' is how you ask for R's answer";
}

# 4. Two output columns may not share a name.
#
# pandas allows it: test_merge_duplicate_suffix passes suffixes = ("_x","_x")
# and ends with two columns both called B_x.  A perl frame is a hash of
# columns, so there is no such frame to return; R refuses this too (the
# reg-tests-1b.R suffixes = c(".z",".z") case above).
{
	throws_ok {
		merge([ { A => 100, B => 60 } ], [ { A => 100, B => 600 } ],
		      on => 'A', suffixes => ['_x', '_x'])
	} qr/output column 'B_x' collides/,
		'test_merge_duplicate_suffix: two columns of one name are refused';
}

# ------------------------------------------------------- double-valued keys
#
# The frozen tables hold no non-integer doubles, because their stringification
# is NV-width dependent (see the header).  Keys that are doubles still have to
# work, so here they are with dyadic literals -- exactly representable on a
# double, a long double and a __float128 alike, and printing the same on all
# three.  The rule under test is pandas'
# test_merge.py::TestMergeDtypes::test_merge_on_ints_floats: a key column of
# one type joins against a key column of another holding the same values,
# because the comparison is on the value, not the type.  In merge() that
# comparison is the stringified cell, so 1 and 1.0 and "1" are one key and
# 0.5 and "0.5" are one key, while 1 and "1.0" are two.
{
	my $nums = { k => [ 0.5, 0.25, 2.5, -1.5, 3 ],   v => [ 1 .. 5 ] };
	my $strs = { k => [ '0.5', '0.25', '2.5', '-1.5', '3' ], w => [ 1 .. 5 ] };
	my $got = merge($nums, $strs, on => 'k', how => 'inner',
	                'output_type' => 'hoa');
	is scalar @{ $got->{k} }, 5,
		'dyadic double keys match the same values written as strings';
	is_deeply [ map { $got->{v}[$_] . ':' . $got->{w}[$_] } 0 .. 4 ],
		[ '1:1', '2:2', '3:3', '4:4', '5:5' ],
		'...each to its own row, in left order';

	# test_merge_on_ints_floats: an integer key column against a float one
	is scalar @{ merge({ X => [ 1, 2, 3 ] },
	                   { X => [ 1.0, 2.0, 3.0 ], Y => [ 1, 2, 3 ] },
	                   on => 'X', 'output_type' => 'hoa')->{X} }, 3,
		'test_merge_on_ints_floats: 1 and 1.0 are the same key';
	# ...but 1 and "1.0" are not: the stringified cells differ.  This is the
	# documented rule and the same one drop_duplicates() and value_counts()
	# use, so it is checked rather than assumed.
	is scalar @{ merge({ X => [ 1, 2, 3 ] }, { X => [ '1.0', '2.0', '3.0' ] },
	                   on => 'X', 'output_type' => 'hoa')->{X} }, 0,
		'1 and "1.0" are different keys, as documented';
}

# ---------------------------------------------------------------- leak check
#
# t/merge.t checks the five join types for leaks on a small AoH.  What this
# adds is the paths the reference corpus reaches and that one does not: undef
# key cells, custom suffixes, keys named differently on each side, HoA and HoH
# inputs, and a join whose answer has no rows.
if ($INC{'Devel/Cover.pm'}) { done_testing(); exit 0 }
SKIP: {
	skip 'Test::LeakTrace not installed', 1 unless $HAVE_LEAKTRACE;
	my $L = { k1 => [ 1, undef, 3 ], k2 => [ 'a', 'b', undef ], v => [ 1, 2, 3 ] };
	my $R = { j1 => [ 1, 3, undef ], j2 => [ 'a', undef, 'b' ], v => [ 4, 5, 6 ] };
	my $H = { r1 => { k1 => 1, k2 => 'a', v => 9 } };
	no_leaks_ok {
		for my $how (qw(inner left right outer)) {
			merge($L, $R, how => $how, 'left_on' => [ 'k1', 'k2' ],
			      'right_on' => [ 'j1', 'j2' ], suffixes => [ '_l', '_r' ]);
			merge($H, $R, how => $how, 'left_on' => 'k1', 'right_on' => 'j1',
			      'output_type' => 'hoa');
			merge($L, { j1 => [], v => [] }, how => $how,
			      'left_on' => 'k1', 'right_on' => 'j1');
		}
	} 'no leaks over undef keys, custom suffixes, HoH input and empty answers';
}

done_testing();
