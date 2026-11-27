#!/usr/bin/env perl
# summary(), against R's summary.default / summary.data.frame.
#
# Provenance (R 4.6.1 src/library/base/man/summary.Rd, \examples, run in R
# 4.6.2 on 2026-11-26 by t/median.dnorm.summary.R.R, committed beside this
# file; re-run it with
#     Rscript t/median.dnorm.summary.R.R
# This test never runs R):
#   summary(attenu, digits = 4)         the per-column summary of a data frame:
#       event, mag, dist and accel of the attenu data (182 rows; station is a
#       factor and is left out), as a HoA, an AoH and a HoH
#   summary(penguins$body_mass)         a vector with NAs (344 values, 2 NA)
#   summary(c(1, NA, 3, Inf))           the README's NaN/Inf case
#   plus summary(1:10), summary(c(2,4,4,4,5,5,7,9)) and two short vectors,
#   whose quartiles are summary.default's quantile type 7.
# summary.default reports Min., 1st Qu., Median, Mean, 3rd Qu., Max. and NA's
# (quantile type 7, mean over the non-NA values).  summary() here additionally
# prints "# values", the count of numeric non-NA values.
#
# Tolerance: summary() renders its numbers to four significant digits, as R
# prints them, so each cell is compared with the exact R value at relative
# 5.1e-4 (half a unit in the fourth digit is 5e-4 relative at worst, for a
# leading 1).  This is as tight as the rendering allows; counts are exact.
#
# Deliberate differences, kept so that changing one is a decision:
#   - summary() also reports "# values", and shows "undef" where R shows NA
#     for a variable with no numeric values.
#   - A NaN is R's NA: left out of every statistic and counted in NA's
#     (README), shown in a column that appears only when needed.
#   - quantile.type, digits and the summary of a factor or character vector
#     are not supported; only numeric columns are summarized.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # throws_ok / lives_and
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

my $INF = 9**9**9;

# summary()'s text -> { label => { column name => cell } }; the label is
# '' for a flat vector.  The header is split on runs of two spaces, since the
# column names contain single ones ("1st Qu.", "# values").
sub parse {
	my ($txt, $has_label) = @_;
	my @l = grep { length } split /\n/, $txt;
	shift @l; # the "# summary: ..." banner
	my $hdr = shift @l;
	$hdr =~ s/^\s+//;
	my @h = split /\s{2,}/, $hdr;
	my $label_name = $has_label ? shift @h : undef;
	my %out;
	for my $row (@l) {
		$row =~ s/^\s+//;
		my @c = split /\s+/, $row;
		my $label = $has_label ? shift @c : '';
		my %r;
		@r{@h} = @c;
		$out{$label} = \%r;
	}
	return \%out;
}

# exp: [ '# values', Min, 1st Qu., Median, Mean, 3rd Qu., Max, NA's or undef ]
my @COLS = ('# values', 'Min.', '1st Qu.', 'Median', 'Mean', '3rd Qu.', 'Max.');
sub check_row {
	my ($row, $exp, $name) = @_;
	if (!$row) { ok(0, "$name (no such row)"); return }
	is($row->{'# values'}, $exp->[0], "$name: # values");
	for my $i (1 .. 6) {
		my $e = $exp->[$i];
		my $got = $row->{ $COLS[$i] };
		if (!defined $got) { ok(0, "$name: $COLS[$i] (missing)"); next }
		# summary() prints the cell as perl stringifies it: Inf, but inf before 5.22
		if ($e == $INF) { is($got, "" . $INF, "$name: $COLS[$i]"); next }
		my $ok = abs($got - $e) <= 5.1e-4 * abs($e);
		ok($ok, "$name: $COLS[$i]") or diag("got $got, expected $e");
	}
	if (defined $exp->[7]) { is($row->{"NA's"}, $exp->[7], "$name: NA's") }
}
sub s_ { return summary(@_, return_only => 1, color => 0) }

# attenu$event, $mag, $dist, $accel (182 rows) and penguins$body_mass (344, "undef" = NA)
my %ATT = (
	event => [ split(/,/, '1,2,2,2,2,2,2,2,2,2,2,3,4,4,4,4,4,4,4,4,4,5,5,5,5,5,5,5,5,5,5,5,6,7,8,8,8,8,8,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,10,11,11,11,12,13,13,14,14,14,14,15,15,15,15,16,16,16,17,17,17,18,18,18,18,18,18,18,18,18,18,18,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,19,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,21,21,21,21,21,21,21,22,22,22,22,22,22,22,22,22,22,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23,23') ],
	mag => [ split(/,/, '7,7.4,7.4,7.4,7.4,7.4,7.4,7.4,7.4,7.4,7.4,5.3,6.1,6.1,6.1,6.1,6.1,6.1,6.1,6.1,6.1,6.6,6.6,6.6,6.6,6.6,6.6,6.6,6.6,6.6,6.6,6.6,5.6,5.7,5.3,5.3,5.3,5.3,5.3,6.6,6.6,6.6,6.6,6.6,6.6,6.6,6.6,6.6,6.6,6.6,6.6,6.6,6.6,6.6,6.6,6.6,6.6,6.6,6.6,6.6,6.6,5.3,7.7,7.7,7.7,6.2,5.6,5.6,5.2,5.2,5.2,5.2,6,6,6,6,5.1,5.1,5.1,7.6,7.6,7.6,5.8,5.8,5.8,5.8,5.8,5.8,5.8,5.8,5.8,5.8,5.8,6.5,6.5,6.5,6.5,6.5,6.5,6.5,6.5,6.5,6.5,6.5,6.5,6.5,6.5,6.5,6.5,6.5,6.5,6.5,6.5,6.5,6.5,6.5,6.5,6.5,6.5,6.5,6.5,6.5,6.5,6.5,6.5,6.5,6.5,6.5,6.5,6.5,6.5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5.8,5.8,5.8,5.8,5.8,5.8,5.8,5.5,5.5,5.5,5.5,5.5,5.5,5.5,5.5,5.5,5.5,5.3,5.3,5.3,5.3,5.3,5.3,5.3,5.3,5.3,5.3,5.3,5.3,5.3,5.3,5.3,5.3,5.3,5.3') ],
	dist => [ split(/,/, '12,148,42,85,107,109,156,224,293,359,370,8,16.1,63.6,6.6,9.3,13,17.3,105,112,123,105,122,141,200,45,130,147,187,197,203,211,62,62,19,21,13,22,29,17,19.6,20.2,21.1,21.9,24.2,66,87,23.4,24.6,25.7,28.6,37.4,46.7,56.9,60.7,61.4,62,64,82,88,91,31,45,145,300,5,50,16,17,8,10,10,8,32,30,31,2.9,3.2,7.6,25.4,32.9,92.2,1.2,1.6,9.1,3.7,5.3,7.4,17.9,19.2,23.4,30,38.9,23.5,26,0.5,0.6,1.3,1.4,2.6,3.8,4,5.1,6.2,6.8,7.5,7.6,8.4,8.5,8.5,10.6,12.6,12.7,12.9,14,15,16,17.7,18,22,22,23,23.2,29,32,32.7,36,43.5,49,60,64,7.5,8.8,8.9,9.4,9.7,9.7,10.5,10.5,12,12.2,12.8,14.6,14.9,17.6,23.9,25,10.8,15.7,16.7,20.8,28.5,33.1,40.3,4,10.1,11.1,17.7,22.5,26.5,29,30.9,37.8,48.3,5.8,12,12.1,20.5,20.5,25.3,35.9,36.1,36.3,38.5,41.4,43.6,44.4,46.1,47.1,47.7,49.2,53.1') ],
	accel => [ split(/,/, '0.359,0.014,0.196,0.135,0.062,0.054,0.014,0.018,0.01,0.004,0.004,0.127,0.411,0.018,0.509,0.467,0.279,0.072,0.012,0.006,0.003,0.018,0.048,0.011,0.007,0.142,0.031,0.006,0.01,0.01,0.006,0.013,0.005,0.003,0.086,0.179,0.205,0.073,0.045,0.374,0.2,0.147,0.188,0.204,0.335,0.057,0.021,0.152,0.217,0.114,0.15,0.148,0.112,0.043,0.057,0.03,0.027,0.028,0.034,0.03,0.039,0.03,0.11,0.01,0.01,0.39,0.031,0.13,0.011,0.12,0.17,0.14,0.11,0.04,0.07,0.08,0.21,0.39,0.28,0.16,0.064,0.09,0.42,0.23,0.13,0.26,0.27,0.26,0.11,0.12,0.038,0.044,0.046,0.17,0.21,0.32,0.52,0.72,0.32,0.81,0.64,0.56,0.51,0.4,0.61,0.26,0.24,0.46,0.22,0.23,0.28,0.38,0.27,0.31,0.2,0.11,0.43,0.27,0.15,0.15,0.15,0.13,0.19,0.13,0.066,0.35,0.1,0.16,0.14,0.049,0.034,0.264,0.263,0.23,0.147,0.286,0.157,0.237,0.133,0.055,0.097,0.129,0.192,0.147,0.154,0.06,0.057,0.12,0.154,0.052,0.045,0.086,0.056,0.065,0.259,0.267,0.071,0.275,0.058,0.026,0.039,0.112,0.065,0.026,0.123,0.133,0.073,0.097,0.096,0.23,0.082,0.11,0.11,0.094,0.04,0.05,0.022,0.07,0.08,0.033,0.017,0.022') ],
);
my @BM = map { $_ eq 'undef' ? undef : $_ + 0 } split(/,/, '3750,3800,3250,undef,3450,3650,3625,4675,3475,4250,3300,3700,3200,3800,4400,3700,3450,4500,3325,4200,3400,3600,3800,3950,3800,3800,3550,3200,3150,3950,3250,3900,3300,3900,3325,4150,3950,3550,3300,4650,3150,3900,3100,4400,3000,4600,3425,2975,3450,4150,3500,4300,3450,4050,2900,3700,3550,3800,2850,3750,3150,4400,3600,4050,2850,3950,3350,4100,3050,4450,3600,3900,3550,4150,3700,4250,3700,3900,3550,4000,3200,4700,3800,4200,3350,3550,3800,3500,3950,3600,3550,4300,3400,4450,3300,4300,3700,4350,2900,4100,3725,4725,3075,4250,2925,3550,3750,3900,3175,4775,3825,4600,3200,4275,3900,4075,2900,3775,3350,3325,3150,3500,3450,3875,3050,4000,3275,4300,3050,4000,3325,3500,3500,4475,3425,3900,3175,3975,3400,4250,3400,3475,3050,3725,3000,3650,4250,3475,3450,3750,3700,4000,4500,5700,4450,5700,5400,4550,4800,5200,4400,5150,4650,5550,4650,5850,4200,5850,4150,6300,4800,5350,5700,5000,4400,5050,5000,5100,4100,5650,4600,5550,5250,4700,5050,6050,5150,5400,4950,5250,4350,5350,3950,5700,4300,4750,5550,4900,4200,5400,5100,5300,4850,5300,4400,5000,4900,5050,4300,5000,4450,5550,4200,5300,4400,5650,4700,5700,4650,5800,4700,5550,4750,5000,5100,5200,4700,5800,4600,6000,4750,5950,4625,5450,4725,5350,4750,5600,4600,5300,4875,5550,4950,5400,4750,5650,4850,5200,4925,4875,4625,5250,4850,5600,4975,5500,4725,5500,4700,5500,4575,5500,5000,5950,4650,5500,4375,5850,4875,6000,4925,undef,4850,5750,5200,5400,3500,3900,3650,3525,3725,3950,3250,3750,4150,3700,3800,3775,3700,4050,3575,4050,3300,3700,3450,4400,3600,3400,2900,3800,3300,4150,3400,3800,3700,4550,3200,4300,3350,4100,3600,3900,3850,4800,2700,4500,3950,3650,3550,3500,3675,4450,3400,4300,3250,3675,3325,3950,3600,4050,3350,3450,3250,4050,3800,3525,3950,3650,3650,4000,3400,3775,4100,3775');

my %EXP = ( # from R's summary.default, see the header
	event => [182, 1, 9, 18, 14.741758241758241, 20, 23],
	mag   => [182, 5, 5.2999999999999998, 6.0999999999999996, 6.0840659340659338, 6.5999999999999996, 7.7000000000000002],
	dist  => [182, 0.5, 11.324999999999999, 23.399999999999999, 45.603296703296706, 47.550000000000004, 370],
	accel => [182, 0.0030000000000000001, 0.044249999999999998, 0.113, 0.15421978021978022, 0.21925, 0.81000000000000005],
);
is(scalar(@{ $ATT{$_} }), 182, "attenu\$$_ has 182 rows") for sort keys %ATT;
is(scalar(@BM), 344, 'penguins$body_mass has 344 values');

#--------
# flat vectors: summary.default
#--------
{
	my %v = (
		'summary(1:10)'                  => [ [1 .. 10],                   [10, 1, 3.25, 5.5, 5.5, 7.75, 10] ],
		'summary(c(1, 2, 3, 4))'         => [ [1, 2, 3, 4],               [4, 1, 1.75, 2.5, 2.5, 3.25, 4] ],
		'summary(c(5, 6))'               => [ [5, 6],                     [2, 5, 5.25, 5.5, 5.5, 5.75, 6] ],
		'summary(c(2,4,4,4,5,5,7,9))'    => [ [2, 4, 4, 4, 5, 5, 7, 9],   [8, 2, 4, 4.5, 5, 5.5, 9] ],
	);
	for my $n (sort keys %v) {
		check_row(parse(s_($v{$n}[0]), 0)->{''}, $v{$n}[1], "R $n (arrayref)");
		check_row(parse(s_(@{ $v{$n}[0] }), 0)->{''}, $v{$n}[1], "R $n (list)");
	}
}
check_row(parse(s_([1, 'NaN', 3, $INF]), 0)->{''}, [3, 1, 2, 3, $INF, $INF, $INF, 1],
	'R summary(c(1, NA, 3, Inf)), NaN as NA (README)');
check_row(parse(s_(\@BM), 0)->{''}, [342, 2700, 3550, 4050, 4201.7543859649122, 4750, 6300],
	'R summary(penguins$body_mass), NAs as undef');
{
	my @bm_nan = map { defined $_ ? $_ : 'NaN' } @BM;
	check_row(parse(s_(\@bm_nan), 0)->{''}, [342, 2700, 3550, 4050, 4201.7543859649122, 4750, 6300, 2],
		'R summary(penguins$body_mass), NAs as NaN: NA\'s is 2');
}
{
	my $r = parse(s_(\@BM), 0)->{''};
	ok(!exists $r->{"NA's"}, 'undef is ignored, not counted in NA\'s (README; R counts NA)');
}

#--------
# summary.data.frame (attenu): HoA, AoH, HoH
#--------
{
	my $t = parse(s_(\%ATT), 1);
	check_row($t->{$_}, $EXP{$_}, "R summary(attenu), HoA: $_") for sort keys %EXP;
}
{
	my @aoh = map { my $i = $_; +{ map { $_ => $ATT{$_}[$i] } keys %ATT } } 0 .. 181;
	my $t = parse(s_(\@aoh), 1);
	check_row($t->{$_}, $EXP{$_}, "R summary(attenu), AoH: $_") for sort keys %EXP;
	my %hoh = map { ("r$_" => $aoh[$_]) } 0 .. 181;
	$t = parse(s_(\%hoh), 1);
	check_row($t->{$_}, $EXP{$_}, "R summary(attenu), HoH: $_") for sort keys %EXP;
}
{
	my $t = parse(s_([ map { $ATT{$_} } qw(event mag) ]), 1);
	check_row($t->{0}, $EXP{event}, 'AoA, row 0 (event)');
	check_row($t->{1}, $EXP{mag}, 'AoA, row 1 (mag)');
}

#--------
# a column of text, and a missing value in a data frame
#--------
{
	my $t = parse(s_({ a => ['x', 'y'], b => [1, 2, 3, 4] }), 1);
	is($t->{a}{'# values'}, 0, 'a non-numeric column has 0 values (README)');
	check_row($t->{b}, [4, 1, 1.75, 2.5, 2.5, 3.25, 4], 'numeric column beside a text one');
}

#--------
# leaks
#--------
no_leaks_ok { my $s = summary(\@BM, return_only => 1, color => 0) } 'summary no leaks' unless $INC{'Devel/Cover.pm'};

done_testing();
