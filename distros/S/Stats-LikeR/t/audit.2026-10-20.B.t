#!/usr/bin/env perl
# Regressions for the distribution-function bugs the 2026-10-20 audit of
# LikeR.xs recorded against 0.33, all fixed in 0.331: dnorm(..., log) at its
# zero-density edges, ptukey() on NaN, qtukey() on a p outside [0, 1], undef
# and the half-built result in pnorm()/dnorm() and the rest of the family,
# pbinom()'s integer test, and qchisq() at a huge df. The numerics of the
# fixes (incomplete gamma and beta, infinite df, log_p) are cross-validated in
# t/distributions.limits.R.t; this file holds the structural cases.
#
# Provenance of every expected number that is not structural: R 4.6.1
# (2026-06-24), options(digits = 17), printed with sprintf("%.17g"):
#
#   dnorm(Inf, log = TRUE), dnorm(1e200, log = TRUE),
#   dnorm(1, sd = 0, log = TRUE), dnorm(0, sd = Inf, log = TRUE)   all -Inf
#   dnorm(Inf), dnorm(1, sd = 0)                                    both 0
#   ptukey(NaN, 3, 10)                                              NaN
#   ptukey(3.5, 3, 10, lower.tail = FALSE, log.p = TRUE)  -2.5626090571991673
#   qtukey(c(-0.1, 1.1, NaN), 3, 10)                      NaN NaN NaN (warns)
#   qtukey(-0.05, 3, 10, lower.tail = FALSE, log.p = TRUE) 0.42700299783029899
#   pnorm(NA), dnorm(NA)                                  NA
#   pbinom(3, 10 + 1e-10, 0.5)                            0.17187500000000006
#   pbinom(-1e-8, 10, 0.5)                                0
#   pbinom(3, 10 + 1e-7, 0.5)                             NaN (non-integer n)
#   qchisq(0.5, 1e10)                                     9999999999.333334
#   pchisq(1e15, 1e15)                                    0.50000000594708038
#
# Tolerances: the R values are asserted at 1e-14 relative except qtukey's,
# which is a secant iteration stopped at R's own absolute 1e-4 (eps in
# qtukey.c), so this port and R agree only as well as their last secant
# steps do: 1.2e-16 apart here, asserted at 1e-12. ptukey's log upper tail
# matched R to the last bit.
#
# The leak checks need Test::LeakTrace, which is optional; they skip without
# it, as the sibling suites do.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR qw(dnorm pnorm qnorm pt qt pchisq qchisq pf qf pbinom ptukey qtukey);

my $HAVE_LEAKTRACE;
BEGIN {
	if ( eval { require Test::LeakTrace; 1 } ) {
		Test::LeakTrace->import('no_leaks_ok');
		$HAVE_LEAKTRACE = 1;
	}
	else {
		*no_leaks_ok = sub (&;$) { SKIP: { skip 'Test::LeakTrace not installed', 1 } };
		$HAVE_LEAKTRACE = 0;
	}
}

my $INF = 9**9**9;
sub is_nan { my ($v) = @_; return defined $v && $v != $v }
sub rel { my ($g, $w) = @_; return abs($g - $w) / abs($w) }

# 1. dnorm(log => 1) at its zero-density edges. Each of these returned 0 --
#    log density 0, density 1 -- where R returns -Inf.
is( dnorm($INF,  log => 1), -$INF, 'dnorm(Inf, log) is -Inf' );
is( dnorm(-$INF, log => 1), -$INF, 'dnorm(-Inf, log) is -Inf' );
# R's 2 sqrt(DBL_MAX) cut-off, where x * x overflows, is the NV's own here: on a
# double 1e200 is past it, on a long double or __float128 it is not, and the
# log density is the finite -x^2/2 - log(sqrt(2 pi)).
my $BIG = 1e200;
my $past = ($BIG * $BIG == $INF);
if ($past) {
	is( dnorm($BIG, log => 1), -$INF, 'dnorm(1e200, log) is -Inf (x*x overflows, as in R)' );
} else {
	ok( abs(dnorm($BIG, log => 1) / (-0.5 * $BIG * $BIG) - 1) < 1e-15, 'dnorm(1e200, log) is -x^2/2 on this wider NV' );
}
is( dnorm(1, sd => 0, log => 1), -$INF, 'dnorm(1, sd = 0, log) is -Inf' );
is( dnorm(0, sd => $INF, log => 1), -$INF, 'dnorm(0, sd = Inf, log) is -Inf' );
is( dnorm(0, sd => 0, log => 1), $INF, 'dnorm(0, sd = 0, log) is still +Inf' );
is( dnorm($INF), 0, 'dnorm(Inf) is still 0 on the linear scale' );
is_deeply( dnorm([$INF, -$INF], log => 1), [-$INF, -$INF], '...and through an array reference' );

# 2. ptukey on NaN: used to be 1 (0 for the upper tail)
ok( is_nan(ptukey('NaN' + 0, 3, 10)), 'ptukey(NaN, 3, 10) is NaN' );
ok( is_nan(ptukey('NaN' + 0, 3, 10, lower_tail => 0)), '...and its upper tail' );
ok( is_nan(ptukey(3, 'NaN' + 0, 10)), 'ptukey(3, NaN, 10) is NaN' );
ok( is_nan(ptukey(3, 3, 'NaN' + 0)), 'ptukey(3, 3, NaN) is NaN' );
ok( rel(ptukey(3.5, 3, 10, lower_tail => 0, log_p => 1), -2.5626090571991673) < 1e-14,
	'ptukey(3.5, 3, 10, upper, log) is R\'s log1p(-p)' );

# 3. qtukey on a p outside [0, 1] is NaN, as every other q* here returns it
#    (and as R does, with a warning). It used to be Inf above 1 and 0 below 0.
ok( is_nan(qtukey(1.5, 3, 10)),  'qtukey(1.5, 3, 10) is NaN' );
ok( is_nan(qtukey(-0.1, 3, 10)), 'qtukey(-0.1, 3, 10) is NaN' );
ok( is_nan(qtukey(0.5, 3, 10, log_p => 1)), 'qtukey(log p = 0.5 > 0) is NaN' );
ok( is_nan(qtukey('NaN' + 0, 3, 10)), 'qtukey(NaN, 3, 10) is NaN' );
is( qtukey(0, 3, 10), 0,    'qtukey(0, ...) is still 0' );
is( qtukey(1, 3, 10), $INF, 'qtukey(1, ...) is still Inf' );
ok( rel(qtukey(-0.05, 3, 10, lower_tail => 0, log_p => 1), 0.42700299783029899) < 1e-12,
	'qtukey(-0.05, upper, log) takes -expm1(log p) as R does' );

# 4. undef is NaN -- R's NA -- in pnorm and dnorm, as the README has always said
#    and as the rest of the family reads it. pnorm([undef]) was 0.5.
ok( is_nan(pnorm([undef])->[0]), 'pnorm([undef]) is [NaN]' );
ok( is_nan(dnorm([undef])->[0]), 'dnorm([undef]) is [NaN]' );
{
	no warnings 'uninitialized';
	ok( is_nan(pnorm(undef)), 'pnorm(undef) is NaN' );
	ok( is_nan(dnorm(undef)), 'dnorm(undef) is NaN' );
}
ok( is_nan(qnorm([undef])->[0]) && is_nan(pt([undef], 3)->[0]), 'qnorm and pt keep reading undef as NaN' );
{
	my @a = (1);
	$#a = 2;   # holes at 1 and 2
	my $r = pnorm(\@a);
	ok( @$r == 3 && !is_nan($r->[0]) && is_nan($r->[1]) && is_nan($r->[2]), 'pnorm: holes are NaN' );
}

# 5. tied arrays: each element is FETCHed once and read as what FETCH returned
{
	package Count::Array;
	sub TIEARRAY  { my ($c, @v) = @_; return bless { v => [@v], n => 0 }, $c }
	sub FETCH     { my ($s, $i) = @_; $s->{n}++; return $s->{v}[$i] }
	sub FETCHSIZE { return scalar @{ $_[0]{v} } }
	package Die::Array;
	sub TIEARRAY  { return bless {}, $_[0] }
	sub FETCH     { die "FETCH died\n" if $_[1] == 2; return 0.5 }
	sub FETCHSIZE { return 4 }
}
for my $c ( [ pnorm => \&pnorm ], [ dnorm => \&dnorm ], [ qnorm => \&qnorm ],
            [ pchisq => sub { pchisq($_[0], 3) } ] ) {
	my ($name, $f) = @$c;
	tie my @t, 'Count::Array', 0.25, undef, 0.75;
	my $r = $f->(\@t);
	is( tied(@t)->{n}, 3, "$name: one FETCH per tied element" );
	ok( !is_nan($r->[0]) && is_nan($r->[1]) && !is_nan($r->[2]), "$name: a tied undef is NaN, the rest are read" );
}

# 6. a dying FETCH or a numification warning made fatal, mid-array, leaks
#    nothing: the result array is mortal before the first element is read.
#    Up to 0.331 pnorm's, dnorm's and dist_apply()'s were plain newAV()s.
my @croakers = (
	[ 'pnorm, dying FETCH',  sub { tie my @t, 'Die::Array'; pnorm(\@t) } ],
	[ 'dnorm, dying FETCH',  sub { tie my @t, 'Die::Array'; dnorm(\@t) } ],
	[ 'qnorm, dying FETCH',  sub { tie my @t, 'Die::Array'; qnorm(\@t) } ],
	[ 'pf, dying FETCH',     sub { tie my @t, 'Die::Array'; pf(\@t, 2, 3) } ],
	[ 'pnorm, fatal warning', sub { pnorm([1, 'abc', 2]) } ],
	[ 'dnorm, fatal warning', sub { dnorm([1, 'abc', 2]) } ],
	[ 'qt, fatal warning',    sub { qt([0.5, 'abc'], 3) } ],
);
for my $c (@croakers) {
	my ($label, $cb) = @$c;
	ok( !eval { $cb->(); 1 }, "$label: dies" );
}
for my $c (@croakers) {
	my ($label, $cb) = @$c;
	no_leaks_ok { eval { $cb->() } } "$label: no SV leak";
}
no_leaks_ok { my $r = pnorm([0.5, undef, 2]); my $s = dnorm([1, 2]); my $q = qf([0.5], 2, 3) }
	'the ordinary array paths do not leak either';

# 7. pbinom's integer test is R's R_nonint(): within 1e-9 * max(1, |n|) of an
#    integer is that integer. 10 + 1e-10 used to be NaN.
ok( rel(pbinom(3, 10 + 1e-10, 0.5), 0.17187500000000006) < 1e-14, 'pbinom(3, 10 + 1e-10, 0.5) is R\'s' );
ok( rel(pbinom(3, 10 - 1e-10, 0.5), 0.17187500000000006) < 1e-14, '...and 10 - 1e-10' );
ok( is_nan(pbinom(3, 10 + 1e-7, 0.5)), 'pbinom(3, 10 + 1e-7, 0.5) is still NaN' );
ok( is_nan(pbinom(3, $INF, 0.5)), 'pbinom(3, Inf, 0.5) is NaN, as in R' );
is( pbinom(-1e-8, 10, 0.5), 0, 'pbinom(-1e-8, 10, 0.5) is 0: x < 0 is tested before the 1e-7 fudge' );
is( pbinom(-1e-8, 10, 0.5, lower => 0), 1, '...and its upper tail 1' );

# 8. the incomplete gamma at a huge shape, and qchisq there
ok( rel(pchisq(1e15, 1e15), 0.50000000594708038) < 1e-14, 'pchisq(1e15, 1e15) is R\'s 0.50000000594708038 (was 0.379)' );
ok( rel(qchisq(0.5, 1e10), 9999999999.333334) < 1e-14, 'qchisq(0.5, 1e10) is R\'s 9999999999.333334 (was ...0.877)' );

done_testing();
