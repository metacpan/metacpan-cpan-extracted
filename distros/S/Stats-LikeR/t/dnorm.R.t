#!/usr/bin/env perl
# dnorm(), against R's own cases.
#
# Provenance:
#   R 4.6.1, src/library/stats/man/Normal.Rd, \examples: dnorm(0) == 1/sqrt(2*pi),
#   dnorm(1) == exp(-1/2)/sqrt(2*pi), dnorm(1) == 1/sqrt(2*pi*exp(1)), the
#   log = TRUE curve over -60 .. 50, and tests/Examples/stats-Ex.Rout.save
#   integrate(dnorm, -1.96, 1.96) = 0.9500042.
#   R 4.6.1, tests/reg-tests-1d.R, "dnorm() etc border cases, notably sigma =
#   -Inf": dnorm(0:1, sd = -Inf) is NaN with a warning ("in R <= 3.6.2 ... 0").
#   R 4.6.1 src/nmath/dnorm.c (read for the border cases, run in R 4.6.2): sd =
#   0 gives Inf at the mean and 0 elsewhere (log: Inf and -Inf), sd = Inf gives
#   0 (log: -Inf), x = Inf gives 0 (log: -Inf), x = mean = Inf is NaN, a
#   negative sd is NaN, vector mean and sd recycle.
#   t/median.dnorm.summary.R.R (committed beside this file) printed every value
#   with 17 digits; re-run it with
#       Rscript t/median.dnorm.summary.R.R
#   (R 4.6.2, 2026-11-26).  This test never runs R.
#
# Tolerance: relative 4e-12 (about 18000 double epsilons); the XS and R agree
# to the last bit on this double build (worst observed 0), and
# the margin is for long-double and quadmath NV builds.  A density that
# underflows to a denormal in double is not tested here, since a wider NV does
# not underflow there; t/dnorm.nv_width.t covers that.
#
# Deliberate differences: none.  mean and sd recycle as vectors, as in R,
# since 0.3431 (t/dist.recycle.R.t covers the rule).

require 5.010;
use strict;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # throws_ok / lives_and
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

my $INF = 9**9**9;
my $TOL = 4e-12; # see header
sub near {
	my ($got, $exp, $name) = @_;
	unless (defined $got) { ok(0, "$name (got undef)"); return }
	if ($exp != $exp) { ok($got != $got, $name) or diag("got $got, expected NaN"); return }
	# numerically: a perl before 5.22 stringifies an infinity as inf, not Inf
	if ($exp == $INF || $exp == -$INF) { ok($got == $exp, $name) or diag("got $got, expected $exp"); return }
	my $scale = abs($exp); # relative; an expected 0 must match exactly
	my $ok = abs($got - $exp) <= $TOL * $scale;
	ok($ok, $name) or diag("got $got, expected $exp");
}
sub near_list {
	my ($got, $exp, $name) = @_;
	unless (ref($got) eq "ARRAY" && @$got == @$exp) { ok(0, "$name (not an array of the right length)"); return }
	near($got->[$_], $exp->[$_], "$name [$_]") for 0 .. $#$exp;
}

#--------
# Normal.Rd examples
#--------
near(dnorm(0), 1/sqrt(2*3.14159265358979323846264338327950288), 'R Normal.Rd: dnorm(0) == 1/sqrt(2*pi)');
near(dnorm(1), exp(-1/2)/sqrt(2*3.14159265358979323846264338327950288), 'R Normal.Rd: dnorm(1) == exp(-1/2)/sqrt(2*pi)');
near(dnorm(1), 1/sqrt(2*3.14159265358979323846264338327950288*exp(1)), 'R Normal.Rd: dnorm(1) == 1/sqrt(2*pi*exp(1))');
near_list(dnorm([-4 .. 4]), [0.00013383022576488537, 0.0044318484119380075, 0.053990966513188063, 0.24197072451914337,
	0.3989422804014327, 0.24197072451914337, 0.053990966513188063, 0.0044318484119380075, 0.00013383022576488537],
	'R: dnorm(-4:4)');
near_list(dnorm([-1, 0.5, 3], mean => 1, sd => 2), [0.12098536225957168, 0.19333405840142462, 0.12098536225957168],
	'R: dnorm(c(-1, .5, 3), 1, 2)');
near_list(dnorm([-1, 0.5, 3], mean => 1, sd => 2, log => 1), [-2.1120857137646181, -1.6433357137646181, -2.1120857137646181],
	'R: dnorm(c(-1, .5, 3), 1, 2, log = TRUE)');
near_list(dnorm([-60, -30, 0, 30, 50], log => 1), [-1800.9189385332047, -450.91893853320465, -0.91893853320467278,
	-450.91893853320465, -1250.9189385332047], 'R Normal.Rd: dnorm(x, log = TRUE) over -60 .. 50');
near(dnorm(30), 1.4736461348785476e-196, 'R: dnorm(30), a small but normal density');
near(dnorm(0, mean => 1e-5, sd => 1e-5), 24197.072451914333, 'R: dnorm(0, 1e-5, 1e-5)');
near(dnorm(1e-300), 0.3989422804014327, 'R: dnorm(1e-300)');
{
	# integrate(dnorm, -1.96, 1.96) = 0.95000420970355914: Simpson's rule on the
	# XS density, 4000 panels, against R's quadrature value
	my ($a, $b, $n) = (-1.96, 1.96, 4000);
	my $h = ($b - $a) / $n;
	my $d = dnorm([ map { $a + $h * $_ } 0 .. $n ]);
	my $s = $d->[0] + $d->[$n];
	$s += ($_ % 2 ? 4 : 2) * $d->[$_] for 1 .. $n - 1;
	my $int = $s * $h / 3;
	ok(abs($int - 0.95000420970355914) < 1e-10, 'R stats-Ex: integrate(dnorm, -1.96, 1.96) is 0.9500042097')
		or diag("got $int");
}

#--------
# border cases
#--------
near_list(dnorm([0, 1], sd => 0), [$INF, 0], 'R: dnorm(c(0, 1), 0, 0)');
near_list(dnorm([0, 1], sd => 0, log => 1), [$INF, -$INF], 'R: dnorm(c(0, 1), 0, 0, log = TRUE) (README: -Inf)');
near(dnorm(0, sd => $INF), 0, 'R: dnorm(0, sd = Inf)');
near(dnorm(0, sd => $INF, log => 1), -$INF, 'R: dnorm(0, sd = Inf, log = TRUE) is -Inf (README)');
near_list(dnorm([-$INF, $INF]), [0, 0], 'R: dnorm(c(-Inf, Inf))');
near(dnorm($INF, log => 1), -$INF, 'R: dnorm(Inf, log = TRUE) is -Inf (README)');
near(dnorm($INF, mean => $INF), 'NaN' + 0, 'R: dnorm(Inf, mean = Inf) is NaN');
near(dnorm(0, mean => $INF), 0, 'R: dnorm(0, mean = Inf)');
{
	my @w;
	local $SIG{__WARN__} = sub { push @w, @_ };
	near_list(dnorm([0, 1], sd => -$INF), ['NaN' + 0, 'NaN' + 0], 'R reg-tests-1d: dnorm(0:1, sd = -Inf) is NaN');
	is(scalar(@w), 1, 'R reg-tests-1d: and warns once for the call, as R does (up to 0.3430, once per element)');
}
near(dnorm('NaN'), 'NaN' + 0, 'R: dnorm(NaN) is NaN');
near(dnorm(undef), 'NaN' + 0, 'R: dnorm(NA) is NA; undef is NaN (README)');
near_list(dnorm([1, undef]), [0.24197072451914337, 'NaN' + 0], 'R: an NA element is NA; undef element is NaN (README)');

#--------
# negative sd, and the vector mean and sd that R recycles
#--------
{
	my @w;
	local $SIG{__WARN__} = sub { push @w, @_ };
	near(dnorm(0, sd => -1), 'NaN' + 0, 'R: dnorm(0, sd = -1) is NaN');
	is(scalar(@w), 1, 'R: dnorm(0, sd = -1) warns once');
}
# R recycles a vector mean and sd (more in t/dist.recycle.R.t)
near_list(dnorm([0, 1], mean => [0, 1], sd => [1, 2]), [0.3989422804014327, 0.19947114020071635],
	'R: dnorm(c(0, 1), mean = c(0, 1), sd = c(1, 2)) recycles');

#--------
# leaks
#--------
{
	my @x = (-1, 0.5, 3);
	no_leaks_ok { my $d = dnorm(\@x, mean => 1, sd => 2, log => 1) } 'dnorm no leaks' unless $INC{'Devel/Cover.pm'};
}

done_testing();
