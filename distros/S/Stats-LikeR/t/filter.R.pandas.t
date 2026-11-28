#!/usr/bin/env perl
# filter(), against R's subset() and pandas' boolean indexing / query().
#
# Provenance:
#   R 4.6.2 (Rd from R 4.6.1): src/library/base/man/subset.Rd \examples on
#     datasets::airquality -- subset(airquality, Temp > 80, ...), Day == 1,
#     with(airquality, subset(Ozone, Temp > 80)) -- and further predicates on
#     the same frame under the other operators and &, |, !; the kept rows are
#     what subset() returns, with the Rd's rule that "missing values are taken
#     as false" (t/filter.R.pandas.R).
#   pandas 3.0.4 / NumPy 2.4.6 (t/filter.R.pandas.py):
#     pandas/tests/frame/test_query_eval.py::test_object_array_eq_ne and
#     ::test_query_with_string_columns (frame of string columns a, b and integer
#     columns c, d drawn as the tests draw them), ::test_inf (== inf, != inf),
#     with expected rows from the tests' own df[...] expressions; plus
#     comparison and &, |, ~ cases on that frame.
# Re-run:  Rscript t/filter.R.pandas.R ; python3 -I t/filter.R.pandas.py
# This test never runs R or Python.
#
# Every case is run on an AoH, a HoA and a HoH of the same rows (a "rid"
# column holds the 0-based row number, so the kept rows are identified
# whatever the shape), and the airquality cases on both a col() predicate and
# the equivalent code reference.
#
# Deliberate differences:
#   - pandas compares a column with a column ("a == b", "c < d") and tests
#     "a in b"; col() compares a column with a value only (README: such a
#     predicate dies), so those pandas cases use a code reference.
#   - A missing cell.  R's subset() takes an NA comparison as false, for != too;
#     pandas keeps a NaN row for !=.  filter() drops an undef cell under every
#     comparison, != included, as subset() does; the last cases pin that.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Stats::LikeR qw(:all);
use Test::Exception; # throws_ok / lives_and
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

my $INF = 9**9**9;

my %AQ = (
	Ozone => [41, 36, 12, 18, undef, 28, 23, 19, 8, undef, 7, 16, 11, 14, 18, 14, 34, 6, 30, 11, 1, 11, 4, 32, undef, undef, undef, 23, 45, 115, 37, undef, undef, undef, undef, undef, undef, 29, undef, 71, 39, undef, undef, 23, undef, undef, 21, 37, 20, 12, 13, undef, undef, undef, undef, undef, undef, undef, undef, undef, undef, 135, 49, 32, undef, 64, 40, 77, 97, 97, 85, undef, 10, 27, undef, 7, 48, 35, 61, 79, 63, 16, undef, undef, 80, 108, 20, 52, 82, 50, 64, 59, 39, 9, 16, 78, 35, 66, 122, 89, 110, undef, undef, 44, 28, 65, undef, 22, 59, 23, 31, 44, 21, 9, undef, 45, 168, 73, undef, 76, 118, 84, 85, 96, 78, 73, 91, 47, 32, 20, 23, 21, 24, 44, 21, 28, 9, 13, 46, 18, 13, 24, 16, 13, 23, 36, 7, 14, 30, undef, 14, 18, 20],
	'Solar.R' => [190, 118, 149, 313, undef, undef, 299, 99, 19, 194, undef, 256, 290, 274, 65, 334, 307, 78, 322, 44, 8, 320, 25, 92, 66, 266, undef, 13, 252, 223, 279, 286, 287, 242, 186, 220, 264, 127, 273, 291, 323, 259, 250, 148, 332, 322, 191, 284, 37, 120, 137, 150, 59, 91, 250, 135, 127, 47, 98, 31, 138, 269, 248, 236, 101, 175, 314, 276, 267, 272, 175, 139, 264, 175, 291, 48, 260, 274, 285, 187, 220, 7, 258, 295, 294, 223, 81, 82, 213, 275, 253, 254, 83, 24, 77, undef, undef, undef, 255, 229, 207, 222, 137, 192, 273, 157, 64, 71, 51, 115, 244, 190, 259, 36, 255, 212, 238, 215, 153, 203, 225, 237, 188, 167, 197, 183, 189, 95, 92, 252, 220, 230, 259, 236, 259, 238, 24, 112, 237, 224, 27, 238, 201, 238, 14, 139, 49, 20, 193, 145, 191, 131, 223],
	Wind => [7.4000000000000004, 8.0000000000000000, 12.5999999999999996, 11.5000000000000000, 14.3000000000000007, 14.9000000000000004, 8.5999999999999996, 13.8000000000000007, 20.1000000000000014, 8.5999999999999996, 6.9000000000000004, 9.6999999999999993, 9.1999999999999993, 10.9000000000000004, 13.1999999999999993, 11.5000000000000000, 12.0000000000000000, 18.3999999999999986, 11.5000000000000000, 9.6999999999999993, 9.6999999999999993, 16.6000000000000014, 9.6999999999999993, 12.0000000000000000, 16.6000000000000014, 14.9000000000000004, 8.0000000000000000, 12.0000000000000000, 14.9000000000000004, 5.7000000000000002, 7.4000000000000004, 8.5999999999999996, 9.6999999999999993, 16.1000000000000014, 9.1999999999999993, 8.5999999999999996, 14.3000000000000007, 9.6999999999999993, 6.9000000000000004, 13.8000000000000007, 11.5000000000000000, 10.9000000000000004, 9.1999999999999993, 8.0000000000000000, 13.8000000000000007, 11.5000000000000000, 14.9000000000000004, 20.6999999999999993, 9.1999999999999993, 11.5000000000000000, 10.3000000000000007, 6.2999999999999998, 1.7000000000000000, 4.5999999999999996, 6.2999999999999998, 8.0000000000000000, 8.0000000000000000, 10.3000000000000007, 11.5000000000000000, 14.9000000000000004, 8.0000000000000000, 4.0999999999999996, 9.1999999999999993, 9.1999999999999993, 10.9000000000000004, 4.5999999999999996, 10.9000000000000004, 5.0999999999999996, 6.2999999999999998, 5.7000000000000002, 7.4000000000000004, 8.5999999999999996, 14.3000000000000007, 14.9000000000000004, 14.9000000000000004, 14.3000000000000007, 6.9000000000000004, 10.3000000000000007, 6.2999999999999998, 5.0999999999999996, 11.5000000000000000, 6.9000000000000004, 9.6999999999999993, 11.5000000000000000, 8.5999999999999996, 8.0000000000000000, 8.5999999999999996, 12.0000000000000000, 7.4000000000000004, 7.4000000000000004, 7.4000000000000004, 9.1999999999999993, 6.9000000000000004, 13.8000000000000007, 7.4000000000000004, 6.9000000000000004, 7.4000000000000004, 4.5999999999999996, 4.0000000000000000, 10.3000000000000007, 8.0000000000000000, 8.5999999999999996, 11.5000000000000000, 11.5000000000000000, 11.5000000000000000, 9.6999999999999993, 11.5000000000000000, 10.3000000000000007, 6.2999999999999998, 7.4000000000000004, 10.9000000000000004, 10.3000000000000007, 15.5000000000000000, 14.3000000000000007, 12.5999999999999996, 9.6999999999999993, 3.3999999999999999, 8.0000000000000000, 5.7000000000000002, 9.6999999999999993, 2.2999999999999998, 6.2999999999999998, 6.2999999999999998, 6.9000000000000004, 5.0999999999999996, 2.7999999999999998, 4.5999999999999996, 7.4000000000000004, 15.5000000000000000, 10.9000000000000004, 10.3000000000000007, 10.9000000000000004, 9.6999999999999993, 14.9000000000000004, 15.5000000000000000, 6.2999999999999998, 10.9000000000000004, 11.5000000000000000, 6.9000000000000004, 13.8000000000000007, 10.3000000000000007, 10.3000000000000007, 8.0000000000000000, 12.5999999999999996, 9.1999999999999993, 10.3000000000000007, 10.3000000000000007, 16.6000000000000014, 6.9000000000000004, 13.1999999999999993, 14.3000000000000007, 8.0000000000000000, 11.5000000000000000],
	Temp => [67, 72, 74, 62, 56, 66, 65, 59, 61, 69, 74, 69, 66, 68, 58, 64, 66, 57, 68, 62, 59, 73, 61, 61, 57, 58, 57, 67, 81, 79, 76, 78, 74, 67, 84, 85, 79, 82, 87, 90, 87, 93, 92, 82, 80, 79, 77, 72, 65, 73, 76, 77, 76, 76, 76, 75, 78, 73, 80, 77, 83, 84, 85, 81, 84, 83, 83, 88, 92, 92, 89, 82, 73, 81, 91, 80, 81, 82, 84, 87, 85, 74, 81, 82, 86, 85, 82, 86, 88, 86, 83, 81, 81, 81, 82, 86, 85, 87, 89, 90, 90, 92, 86, 86, 82, 80, 79, 77, 79, 76, 78, 78, 77, 72, 75, 79, 81, 86, 88, 97, 94, 96, 94, 91, 92, 93, 93, 87, 84, 80, 78, 75, 73, 81, 76, 77, 71, 71, 78, 67, 76, 68, 82, 64, 71, 81, 69, 63, 70, 77, 75, 76, 68],
	Month => [5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 5, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 6, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 7, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9, 9],
	Day => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30],
	q{Temp > 80} => [28, 34, 35, 37, 38, 39, 40, 41, 42, 43, 60, 61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 73, 74, 76, 77, 78, 79, 80, 82, 83, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 133, 142, 145],
	q{Day == 1} => [0, 31, 61, 92, 123],
	q{Temp > 80 & Month > 7} => [92, 93, 94, 95, 96, 97, 98, 99, 100, 101, 102, 103, 104, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 133, 142, 145],
	q{Temp >= 90 | Day == 31} => [30, 39, 41, 42, 68, 69, 74, 91, 99, 100, 101, 119, 120, 121, 122, 123, 124, 125, 126],
	q{!(Temp > 80)} => [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 29, 30, 31, 32, 33, 36, 44, 45, 46, 47, 48, 49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 72, 75, 81, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 129, 130, 131, 132, 134, 135, 136, 137, 138, 139, 140, 141, 143, 144, 146, 147, 148, 149, 150, 151, 152],
	q{Ozone > 100} => [29, 61, 85, 98, 100, 116, 120],
	q{Ozone <= 10} => [8, 10, 17, 20, 22, 72, 75, 93, 113, 136, 146],
	q{Ozone != 18} => [0, 1, 2, 5, 6, 7, 8, 10, 11, 12, 13, 15, 16, 17, 18, 19, 20, 21, 22, 23, 27, 28, 29, 30, 37, 39, 40, 43, 46, 47, 48, 49, 50, 61, 62, 63, 65, 66, 67, 68, 69, 70, 72, 73, 75, 76, 77, 78, 79, 80, 81, 84, 85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100, 103, 104, 105, 107, 108, 109, 110, 111, 112, 113, 115, 116, 117, 119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 140, 141, 142, 143, 144, 145, 146, 147, 148, 150, 152],
	q{Ozone == 18} => [3, 14, 139, 151],
	q{Ozone < 20 & Wind > 12} => [2, 7, 8, 14, 17, 21, 72, 75, 93, 113, 139, 143, 147, 150],
	q{Solar.R > 300 | Ozone > 100} => [3, 15, 16, 18, 21, 29, 40, 44, 45, 61, 66, 85, 98, 100, 116, 120],
);
my %F1 = (a => ['a', 'a', 'a', 'a', 'b', 'b', 'b', 'b', 'c', 'c', 'c', 'c'], b => ['a', 'a', 'b', 'b', 'c', 'c', 'd', 'd', 'e', 'e', 'f', 'f'], c => [4, 1, 0, 1, 2, 4, 2, 0, 1, 3, 4, 3], d => [7, 2, 0, 2, 3, 7, 4, 0, 3, 5, 7, 6]);
my %PD1 = (
	q{a == b} => [0, 1],
	q{a != b} => [2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
	q{a in b} => [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
	q{a in b and c < d} => [0, 1, 3, 4, 5, 6, 8, 9, 10, 11],
	q{c > 2} => [0, 5, 9, 10, 11],
	q{c >= 2} => [0, 4, 5, 6, 9, 10, 11],
	q{c == 2} => [4, 6],
	q{c != 2} => [0, 1, 2, 3, 5, 7, 8, 9, 10, 11],
	q{c < 2} => [1, 2, 3, 7, 8],
	q{c <= 2} => [1, 2, 3, 4, 6, 7, 8],
	q{c > 2 & d < 5} => [],
	q{c > 2 | d < 5} => [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
	q{~(c > 2)} => [1, 2, 3, 4, 6, 7, 8],
	q{a == 'b' & c > 1} => [4, 5, 6],
	q{a != 'a' | d == 0} => [2, 4, 5, 6, 7, 8, 9, 10, 11],
	q{a > 'a'} => [4, 5, 6, 7, 8, 9, 10, 11],
	q{a <= 'b'} => [0, 1, 2, 3, 4, 5, 6, 7],
);
my %INF = (a => [9**9**9, 0.5, -9**9**9, 2, 9**9**9, 0.25], k => [0, 1, 2, 3, 4, 5]);
my %PDINF = (
	q{a == inf} => [0, 4],
	q{a != inf} => [1, 2, 3, 5],
	q{a > 1} => [0, 3, 4],
	q{a < 1} => [1, 2, 5],
);
my %NAN = (x => [1.0, undef, 3.0, 0.0, undef, 2.0]);
my %PDNAN = (
	q{x > 1} => [2, 5],
	q{x >= 1} => [0, 2, 5],
	q{x < 2} => [0, 3],
	q{x == 1} => [0],
	q{x != 1 (pandas keeps NaN)} => [1, 2, 3, 4, 5],
);

# frame builders: HoA -> AoH, HoH (rows keyed by rid)
sub n_rows { my ($h) = @_; my ($c) = sort keys %$h; scalar @{ $h->{$c} } }
sub with_rid { my %h = %{ $_[0] }; $h{rid} = [0 .. n_rows(\%h) - 1]; \%h }
sub to_aoh { my ($h) = @_; [ map { my $i = $_; +{ map { ($_ => $h->{$_}[$i]) } keys %$h } } 0 .. n_rows($h) - 1 ] }
sub to_hoh { my ($h) = @_; +{ map { my $i = $_; ("r$i" => +{ map { ($_ => $h->{$_}[$i]) } keys %$h }) } 0 .. n_rows($h) - 1 } }
sub rids_hoa { [ @{ $_[0]{rid} } ] }
sub rids_aoh { [ map { $_->{rid} } @{ $_[0] } ] }
sub rids_hoh { [ sort { $a <=> $b } map { $_->{rid} } values %{ $_[0] } ] }

# run one case on all three shapes; $pred is a col() object or a code ref
sub check {
	my ($frame, $pred, $want, $tag) = @_;
	my $hoa = with_rid($frame);
	my $aoh = to_aoh($hoa);
	my $hoh = to_hoh($hoa);
	lives_and { is_deeply(rids_hoa(filter($hoa, $pred)), $want, "$tag [HoA]") } "$tag [HoA] lives";
	lives_and { is_deeply(rids_aoh(filter($aoh, $pred)), $want, "$tag [AoH]") } "$tag [AoH] lives";
	lives_and { is_deeply(rids_hoh(filter($hoh, $pred)), $want, "$tag [HoH]") } "$tag [HoH] lives";
}

# R subset() on airquality; the frame and the kept rows are in %AQ (cases are
# the keys with a space or an operator in them; columns are the plain names)
my @AQ_COLS = qw(Ozone Solar.R Wind Temp Month Day);
my %AQFRAME = map { $_ => delete $AQ{$_} } @AQ_COLS;
my %AQ_COL = (
	'Temp > 80'                   => sub { col('Temp') > 80 },
	'Day == 1'                    => sub { col('Day') == 1 },
	'Temp > 80 & Month > 7'       => sub { (col('Temp') > 80) & (col('Month') > 7) },
	'Temp >= 90 | Day == 31'      => sub { (col('Temp') >= 90) | (col('Day') == 31) },
	'!(Temp > 80)'                => sub { !(col('Temp') > 80) },
	'Ozone > 100'                 => sub { col('Ozone') > 100 },
	'Ozone <= 10'                 => sub { col('Ozone') <= 10 },
	'Ozone != 18'                 => sub { col('Ozone') != 18 },
	'Ozone == 18'                 => sub { col('Ozone') == 18 },
	'Ozone < 20 & Wind > 12'      => sub { (col('Ozone') < 20) & (col('Wind') > 12) },
	'Solar.R > 300 | Ozone > 100' => sub { (col('Solar.R') > 300) | (col('Ozone') > 100) },
);
my %AQ_SUB = (
	'Temp > 80'                   => sub { $_->{Temp} > 80 },
	'Day == 1'                    => sub { $_->{Day} == 1 },
	'Temp > 80 & Month > 7'       => sub { $_->{Temp} > 80 && $_->{Month} > 7 },
	'Temp >= 90 | Day == 31'      => sub { $_->{Temp} >= 90 || $_->{Day} == 31 },
	'!(Temp > 80)'                => sub { !($_->{Temp} > 80) },
	'Ozone > 100'                 => sub { defined $_->{Ozone} && $_->{Ozone} > 100 },
	'Ozone <= 10'                 => sub { defined $_->{Ozone} && $_->{Ozone} <= 10 },
	'Ozone != 18'                 => sub { defined $_->{Ozone} && $_->{Ozone} != 18 },
	'Ozone == 18'                 => sub { defined $_->{Ozone} && $_->{Ozone} == 18 },
	'Ozone < 20 & Wind > 12'      => sub { defined $_->{Ozone} && $_->{Ozone} < 20 && $_->{Wind} > 12 },
	'Solar.R > 300 | Ozone > 100' => sub { (defined $_->{'Solar.R'} && $_->{'Solar.R'} > 300) || (defined $_->{Ozone} && $_->{Ozone} > 100) },
);
for my $name (sort keys %AQ_COL) {
	check(\%AQFRAME, $AQ_COL{$name}->(), $AQ{$name}, "R subset(airquality, $name), col()");
	check(\%AQFRAME, $AQ_SUB{$name}, $AQ{$name}, "R subset(airquality, $name), code ref");
}
# the Rd's with(airquality, subset(Ozone, Temp > 80)) is the Ozone column of the kept rows
{
	my $kept = filter(\%AQFRAME, col('Temp') > 80);
	is(scalar @{ $kept->{Ozone} }, 68, 'R subset.Rd: subset(airquality, Temp > 80) has 68 rows');
	is_deeply($kept->{Temp}, [ @{ $AQFRAME{Temp} }[ @{ $AQ{'Temp > 80'} } ] ], 'R subset.Rd: the kept Temp column');
}

# pandas test_query_eval.py string/integer frame
my %PD1_COL = (
	'c > 2'              => sub { col('c') > 2 },
	'c >= 2'             => sub { col('c') >= 2 },
	'c == 2'             => sub { col('c') == 2 },
	'c != 2'             => sub { col('c') != 2 },
	'c < 2'              => sub { col('c') < 2 },
	'c <= 2'             => sub { col('c') <= 2 },
	'c > 2 & d < 5'      => sub { (col('c') > 2) & (col('d') < 5) },
	'c > 2 | d < 5'      => sub { (col('c') > 2) | (col('d') < 5) },
	'~(c > 2)'           => sub { !(col('c') > 2) },
	"a == 'b' & c > 1"   => sub { (col('a') eq 'b') & (col('c') > 1) },
	"a != 'a' | d == 0"  => sub { (col('a') ne 'a') | (col('d') == 0) },
	"a > 'a'"            => sub { col('a') gt 'a' },
	"a <= 'b'"           => sub { col('a') le 'b' },
);
my %b_set = map { $_ => 1 } @{ $F1{b} };
my %PD1_SUB = (
	'a == b'           => sub { $_->{a} eq $_->{b} },
	'a != b'           => sub { $_->{a} ne $_->{b} },
	'a in b'           => sub { $b_set{ $_->{a} } },
	'a in b and c < d' => sub { $b_set{ $_->{a} } && $_->{c} < $_->{d} },
);
for my $name (sort keys %PD1_COL) {
	check(\%F1, $PD1_COL{$name}->(), $PD1{$name}, "pandas $name, col()");
}
for my $name (sort keys %PD1_SUB) {
	check(\%F1, $PD1_SUB{$name}, $PD1{$name}, "pandas $name, code ref");
}
throws_ok { filter(with_rid(\%F1), col('c') < col('d')) } qr/./,
	'pandas "c < d": col() vs col() dies (README), use a code ref';

# pandas test_inf
my %INF_COL = (
	'a == inf' => sub { col('a') == $INF },
	'a != inf' => sub { col('a') != $INF },
	'a > 1'    => sub { col('a') > 1 },
	'a < 1'    => sub { col('a') < 1 },
);
for my $name (sort keys %INF_COL) {
	check(\%INF, $INF_COL{$name}->(), $PDINF{$name}, "pandas inf: $name");
}

# missing cells (NaN in pandas, undef here): ordered comparisons drop the row in
# pandas, R and here; pandas keeps a NaN row for != where R's subset() does not
my %NAN_COL = (
	'x > 1'  => sub { col('x') > 1 },
	'x >= 1' => sub { col('x') >= 1 },
	'x < 2'  => sub { col('x') < 2 },
	'x == 1' => sub { col('x') == 1 },
);
for my $name (sort keys %NAN_COL) {
	check(\%NAN, $NAN_COL{$name}->(), $PDNAN{$name}, "pandas NaN frame: $name, undef cell");
}
# R subset(): x != 1 drops the NA rows, so rows 2 3 5 only
check(\%NAN, col('x') != 1, [2, 3, 5], 'R subset semantics: x != 1 with undef cells drops them');

my $leak_frame = to_aoh(with_rid(\%F1)); my $leak_pred = col('c') > 2;
no_leaks_ok { filter($leak_frame, $leak_pred) } 'filter does not leak' unless $INC{'Devel/Cover.pm'};

done_testing();
