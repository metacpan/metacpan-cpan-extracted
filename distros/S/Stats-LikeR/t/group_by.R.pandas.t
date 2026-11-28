#!/usr/bin/env perl
# group_by(), against R's split() and pandas' groupby(dropna=True).
#
# Provenance:
#   R 4.6.2 split(x, f) (Rd and tests from R 4.6.1), t/group_by.R.pandas.R:
#     tests/reg-tests-1c.R   "recycling in split()": split(1:6, 1:2)
#     tests/reg-tests-2.R    split(as.list(1:3), c(1,1,2)), and the split of
#                            charToRaw("A test string") by
#                            rep(1:5, times = c(1,1,4,1,6)), as characters
#     tests/reg-tests-1a.R   PR#6672: split(c(NA, 1, 2), as.factor(c(NA, 1, 2)))
#     src/library/base/man/split.Rd, datasets::airquality split by Month
#     README.md's own claim, split(mtcars$mpg, mtcars$cyl) (11, 7, 14 cars)
#   pandas 3.0.4 / NumPy 2.4.6, t/group_by.R.pandas.py, in
#     pandas/tests/groupby/test_groupby_dropna.py:
#     ::test_groupby_dropna_normal_index_dataframe (GH 3729),
#     ::test_groupby_dropna_series_by, ::test_groupby_nan_included (GH 35646,
#     the dropna=True groups).
# Re-run:  Rscript t/group_by.R.pandas.R ; python3 -I t/group_by.R.pandas.py
# This test never runs R or Python.
#
# group_by(DATA, VALUE, GROUP) is "VALUE split by GROUP", the argument order
# of split(x, f) (README).  Every case is run on an AoH, a HoA and a HoH; a
# HoH's value order is hash order, so those lists are compared sorted.
#
# Deliberate differences:
#   - split() and pandas keep a missing VALUE in its group; group_by() leaves
#     the row out (README).  The expectations drop NA/NaN values.
#   - Both split() and groupby(dropna=True) drop a missing GROUP key, as
#     group_by() does (README).  pandas' dropna=False NaN group has no
#     counterpart.
#   - split() on numbers names the groups with the factor levels
#     ("1", "2"); group_by() keys are the stringified GROUP values.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Stats::LikeR qw(:all);
use Test::Exception; # throws_ok / lives_and
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

my %R = (
	recycle => {
		'1' => [1, 3, 5],
		'2' => [2, 4, 6],
	},
	list => {
		'1' => [1, 2],
		'2' => [3],
	},
	raw => {
		'1' => ['A'],
		'2' => [' '],
		'3' => ['t', 'e', 's', 't'],
		'4' => [' '],
		'5' => ['s', 't', 'r', 'i', 'n', 'g'],
	},
	pr6672 => {
		'1' => [1],
		'2' => [2],
	},
	airquality => {
		'5' => [41, 36, 12, 18, 28, 23, 19, 8, 7, 16, 11, 14, 18, 14, 34, 6, 30, 11, 1, 11, 4, 32, 23, 45, 115, 37],
		'6' => [29, 71, 39, 23, 21, 37, 20, 12, 13],
		'7' => [135, 49, 32, 64, 40, 77, 97, 97, 85, 10, 27, 7, 48, 35, 61, 79, 63, 16, 80, 108, 20, 52, 82, 50, 64, 59],
		'8' => [39, 9, 16, 78, 35, 66, 122, 89, 110, 44, 28, 65, 22, 59, 23, 31, 44, 21, 9, 45, 168, 73, 76, 118, 84, 85],
		'9' => [96, 78, 73, 91, 47, 32, 20, 23, 21, 24, 44, 21, 28, 9, 13, 46, 18, 13, 24, 16, 13, 23, 36, 7, 14, 30, 14, 18, 20],
	},
	mtcars => {
		'4' => [22.800000000000001, 24.399999999999999, 22.800000000000001, 32.399999999999999, 30.399999999999999, 33.899999999999999, 21.500000000000000, 27.300000000000001, 26.000000000000000, 30.399999999999999, 21.399999999999999],
		'6' => [21.000000000000000, 21.000000000000000, 21.399999999999999, 18.100000000000001, 19.199999999999999, 17.800000000000001, 19.699999999999999],
		'8' => [18.699999999999999, 14.300000000000001, 16.399999999999999, 17.300000000000001, 15.199999999999999, 10.400000000000000, 10.400000000000000, 14.699999999999999, 15.500000000000000, 15.199999999999999, 13.300000000000001, 19.199999999999999, 15.800000000000001, 15.000000000000000],
	},
);
my $OZONE = [41, 36, 12, 18, undef, 28, 23, 19, 8, undef, 7, 16, 11, 14, 18, 14, 34, 6, 30, 11, 1, 11, 4, 32, undef, undef, undef, 23, 45, 115, 37, undef, undef, undef, undef, undef, undef, 29, undef, 71, 39, undef, undef, 23, undef, undef, 21, 37, 20, 12, 13, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, 135, 49, 32, undef, 64, 40, 77, 97, 97, 85, undef, 10, 27, undef, 7, 48, 35, 61, 79, 63, 16, undef, undef, 80, 108, 20, 52, 82, 50, 64, 59, 39, 9, 16, 78, 35, 66, 122, 89, 110, undef, undef, 44, 28, 65, undef, 22, 59, 23, 31, 44, 21, 9, undef, 45, 168, 73, undef, 76, 118, 84, 85, 96, 78, 73, 91, 47, 32, 20, 23, 21, 24, 44, 21, 28, 9, 13, 46, 18, 13, 24, 16, 13, 23, 36, 7, 14, 30, undef, 14, 18, 20];
my $MONTH = [5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9];
my $MPG = [21.000000000000000, 21.000000000000000, 22.800000000000001, 21.399999999999999, 18.699999999999999, 18.100000000000001, 14.300000000000001, 24.399999999999999, 22.800000000000001, 19.199999999999999, 17.800000000000001, 16.399999999999999, 17.300000000000001, 15.199999999999999, 10.400000000000000, 10.400000000000000, 14.699999999999999, 32.399999999999999, 30.399999999999999, 33.899999999999999, 21.500000000000000, 15.500000000000000, 15.199999999999999, 13.300000000000001, 19.199999999999999, 27.300000000000001, 26.000000000000000, 30.399999999999999, 15.800000000000001, 19.699999999999999, 15.000000000000000, 21.399999999999999];
my $CYL = [6, 6, 4, 6, 8, 6, 8, 4, 4, 6, 6, 8, 8, 8, 8, 8, 8, 4, 4, 4, 4, 8, 8, 8, 8, 4, 4, 4, 8, 6, 8, 4];
my %PD = (
	gh3729 => {
		b => {
			'A' => [123.23],
			'B' => [12.0, 1.0],
		},
		c => {
			'A' => [123.0],
			'B' => [12.0, 1.0],
		},
		d => {
			'A' => [1.0],
			'B' => [12.0, 1.0],
		},
	},
	series_by => {
		v => {
			'a' => [390.0, 30.0],
			'b' => [350.0],
		},
	},
	nan_included => {
		B => {
			'g1' => [0, 2],
			'g2' => [3],
		},
	},
);
my %PDDATA = (
	gh3729 => { a => ['B', undef, 'A', 'B'], b => [12, 12.3, 123.23, 1], c => [12, 233, 123, 1], d => [12, 12, 1, 1] },
	series_by => { k => ['a', 'b', 'a', undef], v => [390, 350, 30, 20] },
	nan_included => { group => ['g1', undef, 'g1', 'g2', undef], B => [0, 1, 2, 3, 4] },
);

sub n_rows { my ($h) = @_; my ($c) = sort keys %$h; scalar @{ $h->{$c} } }
sub to_aoh { my ($h) = @_; [ map { my $i = $_; +{ map { ($_ => $h->{$_}[$i]) } keys %$h } } 0 .. n_rows($h) - 1 ] }
sub to_hoh { my ($h) = @_; +{ map { my $i = $_; ("r$i" => +{ map { ($_ => $h->{$_}[$i]) } keys %$h }) } 0 .. n_rows($h) - 1 } }
sub num_sort { [ sort { (($a =~ /^-?[\d.]+(?:e[-+]?\d+)?$/i) && ($b =~ /^-?[\d.]+(?:e[-+]?\d+)?$/i)) ? $a <=> $b : $a cmp $b } @{ $_[0] } ] }

# $frame is a HoA of the columns; check VALUE split by GROUP on every shape
sub check {
	my ($frame, $value, $group, $want, $tag) = @_;
	my %sorted = map { $_ => num_sort($want->{$_}) } keys %$want;
	my $hoa = $frame; my $aoh = to_aoh($frame); my $hoh = to_hoh($frame);
	lives_and {
		my $r = group_by($hoa, $value, $group);
		is_deeply($r, $want, "$tag [HoA]");
	} "$tag [HoA] lives";
	lives_and {
		my $r = group_by($aoh, $value, $group);
		is_deeply($r, $want, "$tag [AoH]");
	} "$tag [AoH] lives";
	lives_and {
		my $r = group_by($hoh, $value, $group);
		is_deeply({ map { $_ => num_sort($r->{$_}) } keys %$r }, \%sorted, "$tag [HoH, values sorted]");
	} "$tag [HoH] lives";
}

# R split()
check({ x => [1 .. 6], f => [1, 2, 1, 2, 1, 2] }, 'x', 'f', $R{recycle}, 'R reg-tests-1c.R: split(1:6, 1:2)');
check({ x => [1 .. 3], f => [1, 1, 2] }, 'x', 'f', $R{list}, 'R reg-tests-2.R: split(as.list(1:3), c(1,1,2))');
{
	my @chars = split //, 'A test string';
	my @f = map { ($_ + 1) x (1, 1, 4, 1, 6)[$_] } 0 .. 4;
	check({ ch => \@chars, f => \@f }, 'ch', 'f', $R{raw}, 'R reg-tests-2.R: split(charToRaw("A test string"), ...)');
}
check({ x => [undef, 1, 2], f => [undef, 1, 2] }, 'x', 'f', $R{pr6672}, 'R reg-tests-1a.R PR#6672: an NA level is dropped');
check({ Ozone => $OZONE, Month => $MONTH }, 'Ozone', 'Month', $R{airquality},
	'R split.Rd: split(airquality$Ozone, airquality$Month), NA values left out (README)');
check({ mpg => $MPG, cyl => $CYL }, 'mpg', 'cyl', $R{mtcars}, 'README: split(mtcars$mpg, mtcars$cyl)');
is(scalar @{ group_by({ mpg => $MPG, cyl => $CYL }, 'mpg', 'cyl')->{4} }, 11, 'README: 11 four-cylinder cars');
is(scalar @{ group_by({ mpg => $MPG, cyl => $CYL }, 'mpg', 'cyl')->{6} }, 7,  'README: 7 six-cylinder cars');
is(scalar @{ group_by({ mpg => $MPG, cyl => $CYL }, 'mpg', 'cyl')->{8} }, 14, 'README: 14 eight-cylinder cars');

# pandas groupby(dropna=True)
for my $case (sort keys %PD) {
	for my $val (sort keys %{ $PD{$case} }) {
		my $group = (grep { $_ ne $val } keys %{ $PDDATA{$case} })[0];
		$group = 'a' if $case eq 'gh3729';
		check($PDDATA{$case}, $val, $group, $PD{$case}{$val}, "pandas $case: $val by $group");
	}
}
# the pandas tests' sums and means follow from the groups
{
	my $r = group_by($PDDATA{gh3729}, 'b', 'a');
	is(sum($r->{B}), 13, 'pandas GH 3729: sum of b for B is 13.0');
	is(sum($r->{A}), 123.23, 'pandas GH 3729: sum of b for A is 123.23');
	my $m = group_by($PDDATA{series_by}, 'v', 'k');
	is(mean($m->{a}), 210, 'pandas test_groupby_dropna_series_by: mean for a is 210');
	is(mean($m->{b}), 350, 'pandas test_groupby_dropna_series_by: mean for b is 350');
}

# missing target column is fatal (README)
throws_ok { group_by({ x => [1], g => [1] }, 'nope', 'g') } qr/not present in the dataset/, 'absent value column dies';
throws_ok { group_by({ x => [1], g => [1] }, 'x', 'nope') } qr/not present in the dataset/, 'absent group column dies';

my $leak = { mpg => $MPG, cyl => $CYL };
no_leaks_ok { group_by($leak, 'mpg', 'cyl') } 'group_by does not leak' unless $INC{'Devel/Cover.pm'};

done_testing();
