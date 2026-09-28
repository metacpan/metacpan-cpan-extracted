#!/usr/bin/env perl
require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception;
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

sub is_approx {
	my ($got, $expected, $name, $eps) = @_;
	$eps = 1e-7 if not defined $eps;
	if (abs($got - $expected) <= $eps) { pass("$name: within $eps"); return 1; }
	fail($name); diag("  got: $got\n  expected: $expected");
	return 0;
}

# Reference values from R's epitools::ageadjust.direct algorithm (Fay-Feuer
# gamma CI) replicated in base R with qgamma.
my @count  = (5, 20, 55, 60);
my @pop    = (1000, 3000, 4000, 2000);
my @stdpop = (2000, 3000, 3000, 2000);

# positional form
{
	my $r = age_standardize(\@count, \@pop, \@stdpop);
	is_approx($r->{crude_rate}, 0.0140000000, 'crude rate');
	is_approx($r->{adj_rate},   0.0131250000, 'directly standardized rate');
	is_approx($r->{'conf.int'}[0], 0.0109781852, 'gamma CI lower');
	is_approx($r->{'conf.int'}[1], 0.0156960916, 'gamma CI upper');
	is_approx($r->{'conf.level'}, 0.95, 'default conf.level', 1e-9);
}

# per-100,000 scaling
{
	my $r = age_standardize(\@count, \@pop, \@stdpop, per => 100_000);
	is_approx($r->{adj_rate},      1312.5000, 'adj rate per 100k', 1e-3);
	is_approx($r->{'conf.int'}[0], 1097.8185, 'CI lower per 100k', 1e-3);
	is_approx($r->{'conf.int'}[1], 1569.6092, 'CI upper per 100k', 1e-3);
}

# named-argument form and rate input give the same answer
{
	my $r = age_standardize(count => \@count, pop => \@pop, stdpop => \@stdpop);
	is_approx($r->{adj_rate}, 0.0131250000, 'named-arg form matches');

	my @rate = map { $count[$_] / $pop[$_] } 0 .. $#count;
	my $r2 = age_standardize(rate => \@rate, pop => \@pop, stdpop => \@stdpop);
	is_approx($r2->{adj_rate}, 0.0131250000, 'rate input matches count input');
}

# The gamma quantile at a small tail probability.
#
# _qgamma() bisects against the lower incomplete gamma, and used to form it as
# `1 - _igamc($shape, $x)`.  That subtraction is the cancellation igam() exists
# to avoid: below a lower tail of about NV_EPSILON the difference can only be a
# multiple of NV_EPSILON, so every candidate the bisection tried compared equal
# and it converged on noise.  age_standardize() asks for the alpha/2 quantile,
# so it is the LOWER limit at a high conf.level that was affected -- at
# conf.level => 1-1e-8 the tail is 5e-9, thirty million times smaller than the
# 0.025 the default asks for.
#
# Reference values from R 4.6.1 at options(digits=17), computed the way
# epitools::ageadjust.direct does and the way this function does:
#     lo <- qgamma(a/2,   shape = dsr^2/v,            scale = v/dsr)
#     hi <- qgamma(1-a/2, shape = (dsr+wm)^2/(v+wm^2), scale = (v+wm^2)/(dsr+wm))
# with dsr, v and wm built from the same @count / @pop / @stdpop above.
#
# 1e-9 relative: _qgamma stops when the bracket is inside 1e-12 of where it
# sits, and R's qgamma is a different algorithm (AS 91 plus Newton), so the two
# agree to about 1e-12 -- worst observed over these four rows is 2.6e-13.
{
	my @CL = (
		[ 0.95,     0.010978185249693982, 0.015696091617338891 ],
		[ 0.999,    0.0096830764442113974, 0.017481811766449144 ],
		[ 0.99999,  0.0086715041485398471, 0.019093377932066967 ],
		[ 1 - 1e-8, 0.0075871208326928697, 0.021089994260874965 ],
	);
	for my $c (@CL) {
		my ($cl, $lo, $hi) = @$c;
		my $r = age_standardize(\@count, \@pop, \@stdpop, conf_level => $cl);
		is_approx($r->{'conf.int'}[0], $lo, "conf.level $cl: gamma CI lower matches R",
		          1e-9 * $lo);
		is_approx($r->{'conf.int'}[1], $hi, "conf.level $cl: gamma CI upper matches R",
		          1e-9 * $hi);
	}
	# and the limits widen monotonically with the confidence level
	my @lo = map { age_standardize(\@count, \@pop, \@stdpop,
	                               conf_level => $_)->{'conf.int'}[0] }
	         map { $_->[0] } @CL;
	my $mono = 1;
	for my $i (1 .. $#lo) { $mono = 0 if $lo[$i] >= $lo[$i - 1] }
	ok($mono, 'the lower limit falls as the confidence level rises')
		or diag("limits: @lo");
}

# The primitive the fix turns on, checked directly: `conf.level` cannot reach
# far enough into the tail to separate the two forms on its own, because
# 1 - 2e-17 is already 1 in a double, so the rows above pass either way.  What
# distinguishes them is the lower incomplete gamma itself.
#
# _pgamma_lower is the XS igam(), which computes P(a, x) directly.  The
# expression it replaced, 1 - _igamc(a, x), is a subtraction from 1: below a
# lower tail of about NV_EPSILON every candidate value collapses to the same
# multiple of NV_EPSILON, and below ~1e-16 to exactly 0, so a bisection against
# it has nothing to bisect on.
#
# Reference values from R 4.6.1 pgamma(x, shape) at options(digits=17).
{
	my @PG = (
		[ 1,   1e-20, 9.9999999999999995e-21  ],
		[ 1,   1e-12, 9.9999999999949996e-13  ],
		[ 2,   1e-10, 4.9999999996666686e-21  ],
		[ 0.5, 1e-18, 1.1283791670955127e-09  ],
		[ 3,   1e-8,  1.6666666541666667e-25  ],
		[ 2,   1,     0.26424111765711528     ],
		[ 5,   3,     0.18473675547622787     ],
	);
	for my $g (@PG) {
		my ($a, $x, $want) = @$g;
		my $got = Stats::LikeR::_pgamma_lower($a, $x);
		# 1e-12 relative: igam()'s series stops on a term cutoff that scales
		# with the build's NV_EPSILON, and R's pgamma is a different algorithm;
		# worst observed over these rows on a double build is 1.1e-16.
		is_approx($got, $want, "pgamma($x, shape=$a) matches R", 1e-12 * abs $want);
	}
	# and the form it replaced really does lose the small ones entirely.
	#
	# WHERE it starts losing them is a property of the build, not a constant:
	# 1 - igamc(a, x) is a subtraction from 1, so it collapses below this
	# perl's own epsilon -- 2.2e-16 on a double, 1.9e-34 on __float128.  Ask
	# the perl rather than assume a double: the first draft of this test
	# asserted a literal 1e-20 and passed everywhere except the quadmath
	# build, where 1e-20 is still fourteen orders of magnitude above the point
	# the subtraction fails at.
	my $eps = 1.0;
	$eps /= 2 while 1 + $eps / 2 != 1;
	my $x = $eps * $eps;                   # far below it at every NV width
	cmp_ok(Stats::LikeR::_pgamma_lower(1, $x), '>', 0,
	       "the lower tail at $x is a number");
	is(1 - Stats::LikeR::_igamc(1, $x), 0,
	   '... which 1 - igamc() cannot represent at all');
	# P(1, x) = 1 - exp(-x), which is x to within x^2/2 out here
	my $got = Stats::LikeR::_pgamma_lower(1, $x);
	cmp_ok(abs($got / $x - 1), '<', 1e-9,
	       'and the value it does give is right');
}

# error handling
throws_ok { age_standardize(\@count, [1,2,3], \@stdpop) } qr/length/, 'pop length mismatch rejected';
throws_ok { age_standardize(pop => \@pop, stdpop => \@stdpop) } qr/count.*or.*rate/, 'needs count or rate';
throws_ok { age_standardize(\@count, \@pop, \@stdpop, conf_level => 1.5) } qr/conf.level/, 'bad conf.level rejected';

# Devel::Cover's own per-line counters are allocated inside whatever block is
# running and are reported as leaks, so the check is skipped under it.
no_leaks_ok {
	age_standardize(\@count, \@pop, \@stdpop);
	age_standardize(\@count, \@pop, \@stdpop, per => 100_000, conf_level => 0.9);
} 'age_standardize does not leak' unless $INC{'Devel/Cover.pm'};

done_testing();
