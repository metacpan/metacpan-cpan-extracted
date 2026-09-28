#!/usr/bin/env perl
#
# dnorm(): the density is computed at the build's own NV width.
#
# c_dnorm() decides where the density has underflowed from the exponent range
# of the floating-point type, and up to 0.315 it asked <float.h> about a
# *double* -- DBL_MAX, DBL_MIN_EXP, DBL_MANT_DIG -- whatever perl's NV was.  On
# a long-double or __float128 build that cut the tail off at |x| ~ 38.57, where
# a double's subnormals run out, and returned a flat 0 beyond it: dnorm(-100) is
# 1.4e-2174, perfectly representable on a quadmath NV and four thousand orders
# of magnitude inside its range, and came back 0.  The file's own rule is that
# floating point is NV and the constants are the NV_* ones; these three were
# the exception.
#
# Provenance:
#
#   * R 4.6.1 stats::dnorm() at options(digits=17), for @R_DNORM, @R_DNORM_LOG
#     and @R_DNORM_ARGS below.  R computes in double, so those values pin the
#     double build exactly -- including the zeros past its underflow boundary,
#     which are correct there and which this module must keep producing.
#   * The width-dependent section takes no reference value.  It asserts the
#     identity dnorm(x) == exp(-x^2/2) / sqrt(2*pi), evaluated by perl's own
#     NV arithmetic, which is true at every width: on a double build both sides
#     underflow to 0 together, and on a wider one both sides are the same
#     non-zero number.  That is exactly the property the DBL_ constants broke,
#     and it needs no knowledge of which perl is running it.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Config;
use Stats::LikeR qw(dnorm);

# R 4.6.1: [ x, dnorm(x) ]
#
# The table stops at |x| = 29, where the density is 9.55e-184.  Not because
# anything goes wrong further out, but because perl-5.10.1 -- the oldest perl
# this module supports, and one in the local matrix -- cannot READ a decimal
# literal out there: its atof gives 1.999999999999999e-298 for
# 2.1200065515246056e-298, six percent wrong, and a flat 0 for anything below
# about 1e-308.  A table of R's values past that point would be testing perl's
# number parser, and failing.  The far tail is covered by the identity below
# instead, which is computed rather than parsed and so is exact on every perl.
my @R_DNORM = (
	[ 0,    0.3989422804014327      ],
	[ 0.5,  0.35206532676429952     ],
	[ 1,    0.24197072451914337     ],
	[ 2,    0.053990966513188063    ],
	[ 3,    0.0044318484119380075   ],
	[ 5,    1.4867195147342977e-06  ],
	[ 8,    5.0522710835368927e-15  ],
	[ 10,   7.6945986267064199e-23  ],
	[ 15,   5.5307095498444164e-50  ],
	[ 20,   5.5209483621597635e-88  ],
	[ 25,   7.6539297364193932e-137 ],
	[ 29,   9.551694541948838e-184  ],
	[ -1,   0.24197072451914337     ],
	[ -5,   1.4867195147342977e-06  ],
	[ -20,  5.5209483621597635e-88  ],
	[ -29,  9.551694541948838e-184  ],
);
# R 4.6.1: [ x, dnorm(x, log = TRUE) ] -- log_p carries all the way out, at
# every width, and so is the same on every build.
my @R_DNORM_LOG = (
	[ -200, -20000.918938533203  ],
	[ -100, -5000.9189385332047  ],
	[ -40,  -800.91893853320471  ],
	[ -5,   -13.418938533204672  ],
	[ 0,    -0.91893853320467278 ],
	[ 5,    -13.418938533204672  ],
	[ 40,   -800.91893853320471  ],
	[ 100,  -5000.9189385332047  ],
	[ 200,  -20000.918938533203  ],
);
# R 4.6.1: [ x, mean, sd, dnorm(x, mean, sd) ]
my @R_DNORM_ARGS = (
	[ 3,    1,    2,     0.12098536225957168     ],
	[ 1e5,  1e5,  0.001, 398.9422804014327       ],
	[ 0,    0,    1,     0.3989422804014327      ],
	[ -7,   2,    0.5,   3.5174990851902079e-71  ],
);

# 8 ulp of a double.  The density is one exp() and one multiply, so two or
# three ulp is the whole budget; the rest is headroom for perl-5.10.1, whose
# atof is already one to two ulp out on the smallest literals in the table
# (5.1409092665391496e-136 reads back as ...78e-136 there).  Worst relative
# disagreement observed: 1.4e-16 on 5.44.0, 4.0e-16 on 5.10.1.
my $TOL = 8 * 2.220446049250313e-16;

sub rel_ok {
	my ($got, $exp, $label) = @_;
	if ($exp == 0) { return is($got, 0, $label) }
	return ok(abs($got - $exp) <= $TOL * abs($exp), $label)
		|| diag("got $got, expected $exp");
}

rel_ok(dnorm($_->[0]), $_->[1], "dnorm($_->[0]) matches R") for @R_DNORM;
rel_ok(dnorm($_->[0], 'log' => 1), $_->[1], "dnorm($_->[0], log) matches R")
	for @R_DNORM_LOG;
rel_ok(dnorm($_->[0], mean => $_->[1], sd => $_->[2]), $_->[3],
       "dnorm($_->[0], $_->[1], $_->[2]) matches R") for @R_DNORM_ARGS;

# --------------------------------------------------------------- the tail
#
# The identity, at whatever width this perl carries.  `exp(-x*x/2)` underflows
# to 0 on a double exactly where dnorm must, and does not on a wider NV exactly
# where dnorm must not, so one assertion covers every build in the matrix.
{
	my $inv_sqrt_2pi = 1 / sqrt(8 * atan2(1, 1));   # 1/sqrt(2*pi) at NV width
	for my $x (30, 38, 38.5, 38.6, 39, 45, 60, 100, 150) {
		my $want = exp(-$x * $x / 2) * $inv_sqrt_2pi;
		my $got  = dnorm(-$x);
		if ($want == 0) {
			is($got, 0, "dnorm(-$x) is 0, as exp(-x^2/2) is at this NV width");
		} else {
			ok($got != 0, "dnorm(-$x) is not flattened to 0 (exp(-x^2/2) = $want)")
				or next;
			ok(abs($got - $want) <= 1e-9 * $want,
			   "dnorm(-$x) agrees with exp(-x^2/2)/sqrt(2*pi)")
				or diag("got $got, wanted $want");
		}
	}
	# Say which side of the matrix this run exercised, so a smoker report is
	# readable: on a double NV the loop above checks zeros past x ~ 38.57, and
	# on a wider one it checks live values there instead.
	diag(sprintf 'NV is %s (nvsize %d): dnorm(-100) = %s',
	     $Config{nvtype}, $Config{nvsize}, dnorm(-100));
}

# The symmetric and degenerate cases, unchanged by any of this.
is(dnorm(3), dnorm(-3), 'dnorm is symmetric');
is(dnorm(0, mean => 0, sd => 0), 9**9**9, 'sd = 0 at the mean is Inf');
is(dnorm(1, mean => 0, sd => 0), 0,       'sd = 0 away from the mean is 0');
is(dnorm(1, mean => 0, sd => 9**9**9), 0, 'an infinite sd gives 0');

done_testing();
