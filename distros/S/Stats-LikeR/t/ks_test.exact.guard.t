#!/usr/bin/env perl
#
# ks_test(): the one-sample exact p-value, and the cost cap on asking for it.
#
# K2x() builds an m x m matrix, m = 2*floor(n*D) + 1, and raises it to the n-th
# power -- O(m^3 log n) time and O(m^2) memory, with nothing but the statistic
# bounding m.  The default route can never reach a large m, because it only
# takes the exact branch below n = 100; `exact => 1` could, and had no guard at
# all, while the two-sample branch has refused an over-large forced exact run
# since it acquired KS_EXACT_MAX_PRODUCT.  A sample of 800 whose D is 1 -- any
# badly-fitting reference distribution -- took 52 seconds and 69 MB before
# 0.316, 3200 would have taken most of an hour, and past n ~ 23000 the cell
# count overflowed the int it was computed in and went to calloc() wrapped.
#
# 0.316 caps m at KS_EXACT_MAX_M (500) and warns, exactly as the two-sample
# branch does, and computes the matrix order in size_t.
#
# Provenance:
#
#   * R 4.6.1 stats::ks.test(x, "pnorm", exact = TRUE) and exact = FALSE, at
#     options(digits=17), on the deterministic samples
#         x <- qnorm((1:n)/(n+1)) + 0.35
#     for n in 5, 10, 25, 60, 99.  Both tables are here because the point of
#     the cap is that a refused exact run falls back to the asymptotic p-value
#     -- so the test has to know both numbers to tell which one it got.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR qw(ks_test qnorm);

# the same deterministic sample R was given
sub sample_of { my ($n) = @_; return [ map { qnorm($_ / ($n + 1)) + 0.35 } 1 .. $n ] }

# R 4.6.1: [ n, statistic, exact p, asymptotic p ]
my @R = (
	[  5, 0.26847835041369617, 0.7831383762582188,  0.86383777042084897  ],
	[ 10, 0.20049640553984699, 0.74616724602367623, 0.81628926434728177  ],
	[ 25, 0.16257555803970247, 0.47434427785795508, 0.52333966562385204  ],
	[ 60, 0.14856367847710439, 0.1276620431887221,  0.1414587562992709   ],
	[ 99, 0.14472923420682426, 0.02839942412453822, 0.031610247847356443 ],
);

# The statistic is a max of exact differences of ratios: a couple of ulp.  The
# p-values come out of a matrix power and a series, both of which R computes the
# same way, so 1e-10 relative is generous; worst observed on a double build is
# 4e-16 for the statistic and 2e-12 for the exact p at n = 99.
my $TOL = 1e-10;
sub near {
	my ($got, $exp, $label) = @_;
	return ok(0, "$label (got undef)") unless defined $got;
	ok(abs($got - $exp) <= $TOL * (1 + abs $exp), $label)
		|| diag("got $got, expected $exp");
}

for my $r (@R) {
	my ($n, $d, $pe, $pa) = @$r;
	my $x = sample_of($n);
	my $ex = ks_test($x, 'pnorm', exact => 1);
	my $as = ks_test($x, 'pnorm', exact => 0);
	near($ex->{statistic}, $d,  "n=$n: statistic matches R");
	near($ex->{'p.value'}, $pe, "n=$n: exact p matches R");
	near($as->{'p.value'}, $pa, "n=$n: asymptotic p matches R");
	like($ex->{method}, qr/exact/,     "n=$n: exact => 1 took the exact branch");
	unlike($as->{method}, qr/exact/,   "n=$n: exact => 0 took the asymptotic branch");
}

# the default: exact below n = 100, asymptotic at or above it
{
	like(ks_test(sample_of(99), 'pnorm')->{method}, qr/exact/,
	     'default at n = 99 is exact');
	unlike(ks_test(sample_of(100), 'pnorm')->{method}, qr/exact/,
	       'default at n = 100 is asymptotic');
}

# ---------------------------------------------------------------- the cap
#
# D = 1 by construction: every observation is far above anything the standard
# normal puts mass on, so m = 2n + 1 and the matrix is the largest it can be.
# Before 0.316 this ran the exact algorithm however big n was.
{
	my $n = 3000;                    # m would be 6001: 288 MB and ~an hour
	my @x = map { 50 + $_ / 1e6 } 1 .. $n;
	my @warnings;
	my $r;
	{
		local $SIG{__WARN__} = sub { push @warnings, $_[0] };
		$r = ks_test(\@x, 'pnorm', exact => 1);
	}
	is($r->{statistic}, 1, 'the forced case really does have D = 1');
	ok(scalar(grep { /too large for an exact p-value/ } @warnings),
	   'a forced exact run that is too large warns') or diag("warnings: @warnings");
	unlike($r->{method}, qr/exact/,
	       'and falls back to the asymptotic branch, as the two-sample one does');
	ok(defined $r->{'p.value'} && $r->{'p.value'} >= 0 && $r->{'p.value'} <= 1,
	   'the fallback still returns a probability');
}

# Just under the cap the exact branch still runs, so the guard is a ceiling and
# not a quiet disabling of the feature.  m = 2*floor(n*D) + 1 = 401 here.
{
	my $n = 200;
	my @x = map { 50 + $_ / 1e6 } 1 .. $n;     # D = 1 again, so m = 401 <= 500
	my @warnings;
	my $r;
	{
		local $SIG{__WARN__} = sub { push @warnings, $_[0] };
		$r = ks_test(\@x, 'pnorm', exact => 1);
	}
	like($r->{method}, qr/exact/, 'just under the cap the exact branch still runs');
	is(scalar(grep { /too large/ } @warnings), 0, 'and says nothing about size');
}

# The two-sample cap, unchanged, is asserted here too so the two guards stay
# recognisably the same thing.
{
	my @warnings;
	my ($a, $b) = ([ map { $_ } 1 .. 4000 ], [ map { $_ + 0.5 } 1 .. 4000 ]);
	my $r;
	{
		local $SIG{__WARN__} = sub { push @warnings, $_[0] };
		$r = ks_test($a, $b, exact => 1);
	}
	ok(scalar(grep { /too large for an exact p-value/ } @warnings),
	   'the two-sample forced exact run warns the same way');
	unlike($r->{method}, qr/exact/, 'and falls back the same way');
}

done_testing();
