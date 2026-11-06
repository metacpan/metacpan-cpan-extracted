#!/usr/bin/env perl
# prop_test() with given null proportions, against R's prop.test().
#
# t/prop_test.t covers the call forms and the equality test; nothing ran
# prop_test() with 'p' as an array ref, and nothing provoked its "Chi-squared
# approximation may be incorrect" warning.
#
# PROVENANCE
# ----------
# The three R results are statsmodels 0.14.6's
# statsmodels/stats/tests/test_proportion.py, class TestProportion's setup,
# where they are recorded from R as res_prop_test, res_prop_test_val and
# res_prop_test_1 with the calls that produced them:
#   prop.test(smokers2, patients, correct=FALSE)
#   prop.test(smokers2, patients, p=rep(c(0.9), 4), correct=FALSE)
#   prop.test(smokers2[1], patients[1], p=0.9, correct=FALSE)
# with smokers2 = c(73, 90, 114, 75) and patients = c(86, 93, 136, 82).
#
# Which calls warn is R 4.6.1's prop.test(), checked by tryCatch() on each call
# below: R warns when any expected count n*p or n*(1 - p) is under 5, with p
# the pooled estimate when no 'p' is given.
#
# TOLERANCE
# ---------
# Relative 1e-13.  statsmodels records the R values to 15 or 16 significant
# digits, and the worst observed disagreement on perl-5.44.0 (double) is
# 1.3e-15, in the 4-sample equality p-value; 1e-13 leaves about 80x headroom.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Stats::LikeR qw(prop_test);
use Test::More;

my $TOL = 1e-13;	# relative; see TOLERANCE above

sub rel_ok {
	my ($got, $want, $name) = @_;
	if (!defined $got) { fail("$name (got undef)"); return }
	my $err = $want == 0 ? abs($got) : abs($got - $want) / abs($want);
	ok($err <= $TOL, $name)
		or diag(sprintf("     got: %.17g\nexpected: %.17g\n rel err: %.3g", $got, $want, $err));
}

#prop_test(@args), and the warnings it raised.
sub run {
	my @warn;
	local $SIG{__WARN__} = sub { push @warn, $_[0] };
	my $r = prop_test(@_);
	return ($r, \@warn);
}

my @smokers2 = (73, 90, 114, 75);
my @patients = (86, 93, 136, 82);
my @est = (0.848837209302326, 0.967741935483871, 0.838235294117647, 0.9146341463414634);

{
	my ($r, $w) = run(\@smokers2, \@patients, correct => 0);
	my $t = 'res_prop_test: 4-sample equality';
	rel_ok($r->{statistic}, 11.11938768628861,    "$t: statistic");
	is($r->{parameter}, 3,                         "$t: df");
	rel_ok($r->{p_value},   0.011097511366581344, "$t: p-value");
	rel_ok($r->{estimate}[$_], $est[$_], "$t: estimate $_") for 0 .. 3;
	ok(!exists $r->{conf_int}, "$t: no confidence interval, as in R");
	is($r->{method}, '4-sample test for equality of proportions without continuity correction', "$t: method");
	is(scalar @$w, 0, "$t: no warning");
}

{
	my ($r, $w) = run(\@smokers2, \@patients, p => [0.9, 0.9, 0.9, 0.9], correct => 0);
	my $t = 'res_prop_test_val: 4-sample, p = rep(0.9, 4)';
	rel_ok($r->{statistic}, 13.20305530710751, "$t: statistic");
	is($r->{parameter}, 4,                      "$t: df is k, not k - 1");
	rel_ok($r->{p_value},   0.010325090041836, "$t: p-value");
	rel_ok($r->{estimate}[$_], $est[$_], "$t: estimate $_") for 0 .. 3;
	ok(!exists $r->{conf_int}, "$t: no confidence interval, as in R");
	is($r->{method}, '4-sample test for given proportions without continuity correction', "$t: method");
	is(scalar @$w, 0, "$t: no warning");
}

{
	my ($r, $w) = run($smokers2[0], $patients[0], p => 0.9, correct => 0);
	my $t = 'res_prop_test_1: 1-sample, p = 0.9';
	rel_ok($r->{statistic},   2.501291989664086,  "$t: statistic");
	is($r->{parameter}, 1,                         "$t: df");
	rel_ok($r->{p_value},     0.113752943640092,  "$t: p-value");
	rel_ok($r->{estimate}[0], 0.848837209302326,  "$t: estimate");
	rel_ok($r->{conf_int}[0], 0.758364348004061,  "$t: lower confidence limit");
	rel_ok($r->{conf_int}[1], 0.9094787701686766, "$t: upper confidence limit");
	is($r->{method}, '1-sample proportions test without continuity correction', "$t: method");
	is(scalar @$w, 0, "$t: no warning");
}

#The warning, in the three ways an expected count can fall under 5.
for my $c (
	[ 'pooled estimate, n*p < 5',  [ [1, 2], [10, 10] ] ],
	[ 'given scalar p, n*p < 5',   [ 3, 10, p => 0.2 ] ],
	[ 'given p array, n*(1-p) < 5', [ [83, 90], [86, 93], p => [0.95, 0.9] ] ],
) {
	my ($name, $args) = @$c;
	my (undef, $w) = run(@$args);
	is(scalar @$w, 1, "$name: one warning");
	like($w->[0] // '', qr/^prop_test: Chi-squared approximation may be incorrect/, "$name: R's message");
}

#A __WARN__ handler that dies unwinds through prop_test()'s SAVEFREEPV()d
#buffers, and the exception has to reach the caller intact.
{
	local $SIG{__WARN__} = sub { die "promoted: $_[0]" };
	eval { prop_test([1, 2], [10, 10]) };
	like($@, qr/^promoted: prop_test: Chi-squared approximation may be incorrect/,
		'a dying __WARN__ handler propagates out of prop_test()');
}

done_testing();
