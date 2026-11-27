#!/usr/bin/env perl
# The distribution functions recycle vector parameters as R does: dnorm, pnorm,
# qnorm, pt, qt, pchisq, qchisq, pf, qf and pbinom.
#
# Provenance: every number in %R was printed by t/dist.recycle.R.R (committed
# next to this file) under R 4.6.2; re-run it with
#     Rscript --vanilla t/dist.recycle.R.R
# This test never runs R.  The cases taken from R's own sources (R 4.6.1):
#   TDist.Rd \examples         qt(.975, df = c(1:10,20,50,100,1000))
#   tests/d-p-q-r-tst-2.R      "pf() with large df1 or df2": pf(1, 1, nu) for
#                              nu <- 2^seq(25, 34, 0.5) is increasing, ends
#                              below pchisq(1, 1), and its first value is
#                              pchisq(1, 1) - 7.21129e-9 within 1e-11; R's
#                              own three assertions are repeated here
#   tests/reg-tests-1a.R       PR#8560: pbinom(c(-1,0,1,2), size = 0, p = 0.5)
#                              is c(0,1,1,1)
# The rest are calls written for R's recycling rule (src/main/arithmetic.c,
# math2() and math3()): the longest of x and the parameters sets the length,
# a shorter one is reused from its start with no warning even when its length
# does not divide the longest, any zero-length argument gives numeric(0), and
# NA in any argument is NA there.  R warns "NaNs produced" once for a call
# with a negative sd; here the warning is the module's own text, once.
#
# Up to 0.3430 a vector parameter died ("mean is not a number"), and dnorm()
# warned once per element for a negative sd.
#
# Tolerance: 1e-11 relative, t/distributions.R.scipy.t's tolerance for its
# familiar (non-extreme) cases, which was set from the worst disagreement with
# R across the double, long-double and __float128 builds.  On the double build
# (perl 5.44.0) on 2026-11-26 the worst here was 2.0e-15, qnorm(0.1, mean = 3,
# sd = 2), a value near 0.44 that is a difference of two larger terms.  An R
# NA or NaN (printed undef in %R) must be NaN here.
#
# Deliberate differences: lower and log (R's lower.tail and log.p) are single
# flags, as R uses only their first element; a parameter vector holding a word
# dies naming the parameter, where R would coerce it to NA with a warning.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # throws_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

my $TOL = 1e-11; # see header
sub near_list {
	my ($got, $exp, $name) = @_;
	unless (ref($got) eq 'ARRAY' && @$got == @$exp) {
		ok(0, "$name (not an array of " . scalar(@$exp) . ')');
		diag(ref $got eq 'ARRAY' ? 'length ' . scalar(@$got) : 'got ' . (defined $got ? $got : 'undef'));
		return;
	}
	my @bad;
	for my $i (0 .. $#$exp) {
		my ($g, $e) = ($got->[$i], $exp->[$i]);
		if (!defined $e) { push @bad, "[$i] got $g, want NaN" unless $g != $g; next }
		my $ok = $e == 0 ? $g == 0 : abs($g - $e) <= $TOL * abs($e);
		push @bad, sprintf('[%d] got %.17g want %.17g', $i, $g, $e) unless $ok;
	}
	ok(!@bad, $name) or diag(join "\n", @bad);
}

my %R = (
	'qt(.975, df = c(1:10,20,50,100,1000))' => [12.706204736174694, 4.3026527297494619, 3.1824463052837078, 2.7764451051977934, 2.5705818356363137, 2.4469118511449688, 2.3646242515927844, 2.3060041352041658, 2.2621571627982049, 2.2281388519862739, 2.0859634472658648, 2.0085591121007607, 1.9839715185235516, 1.9623390808264076],
	'nu' => [33554432, 47453132.81212578, 67108864, 94906265.624251559, 134217728, 189812531.24850312, 268435456, 379625062.49700624, 536870912, 759250124.99401248, 1073741824, 1518500249.988025, 2147483648, 3037000499.9760499, 4294967296, 6074000999.9520998, 8589934592, 12148001999.9042, 17179869184],
	'pf(1, 1, nu)' => [0.68268948492579618, 0.68268948703793386, 0.68268948853144096, 0.68268948958750908, 0.68268949033426329, 0.68268949086229758, 0.68268949123567446, 0.6826894914996916, 0.68268949168637993, 0.68268949181838867, 0.682689491911733, 0.6826894919777371, 0.68268949202440921, 0.68268949205741136, 0.68268949208074736, 0.68268949209724905, 0.68268949210891661, 0.68268949211716712, 0.68268949212300112],
	'pchisq(1, 1)' => [0.68268949213708596],
	'pbinom(c(-1,0,1,2), size = 0, p = 0.5)' => [0, 1, 1, 1],
	'dnorm(c(0,1), mean = c(0,1), sd = c(1,2))' => [0.3989422804014327, 0.19947114020071635],
	'dnorm(1:3, mean = 1:2)' => [0.3989422804014327, 0.3989422804014327, 0.053990966513188063],
	'dnorm(0, sd = c(1,-1,2))' => [0.3989422804014327, undef, 0.19947114020071635],
	'dnorm(c(-1,0,2), mean = 1, sd = c(0.5,2), log = TRUE)' => [-8.2257913526447268, -1.7370857137646181, -2.2257913526447273],
	'pnorm(c(0,1), mean = c(0,1,2,3))' => [0.5, 0.5, 0.022750131948179212, 0.022750131948179212],
	'pnorm(1, sd = c(1,-1))' => [0.84134474606854293, undef],
	'pnorm(c(-2,2), mean = c(0,1), lower.tail = FALSE, log.p = TRUE)' => [-0.023012909328963493, -1.8410216450092636],
	'qnorm(c(0.1,0.9), mean = c(1,2,3), sd = 2)' => [-1.5631031310892016, 4.5631031310892016, 0.43689686891079837],
	'pt(2, df = c(1,NA,3))' => [0.85241638234956674, undef, 0.93033701572057836],
	'pt(c(-1,1), df = c(2,5,10,30))' => [0.21132486540518713, 0.81839126617543867, 0.17044656615103004, 0.83734569228698508],
	'qt(c(0.025,0.975), df = c(3,30))' => [-3.1824463052837091, 2.0422724563012378],
	'pchisq(3, df = c(1,2,5))' => [0.91673548333644939, 0.77686983985157021, 0.3000141641213725],
	'qchisq(c(0.5,0.95), df = c(1,10))' => [0.45493642311957283, 18.307038053275146],
	'pf(3, df1 = c(2,4), df2 = 10)' => [0.904632568359375, 0.92767677771185975],
	'qf(0.95, df1 = c(1,2,3), df2 = c(10,20))' => [4.9646027437307101, 3.4928284767356343, 3.7082648190468426],
	'pbinom(3, size = c(5,10), prob = c(0.25,0.5,0.75))' => [0.984375, 0.17187500000000006, 0.36718750000000011],
);

#--------
# R's own cases
#--------
near_list(qt(0.975, df => [1 .. 10, 20, 50, 100, 1000]), $R{'qt(.975, df = c(1:10,20,50,100,1000))'},
	'R TDist.Rd: qt(.975, df = c(1:10,20,50,100,1000))');
{
	my $y = pf(1, 1, $R{nu});
	near_list($y, $R{'pf(1, 1, nu)'}, 'R d-p-q-r-tst-2.R: pf(1, 1, nu), a vector df2');
	my $target = pchisq(1, 1);
	my @c = (@$y, $target);
	ok(!grep({ $c[$_ + 1] - $c[$_] <= 0 } 0 .. $#c - 1),
		'R d-p-q-r-tst-2.R: diff(c(y, target)) > 0, pf(1, 1, *) increasing');
	ok(abs($y->[0] - ($target - 7.21129e-9)) < 1e-11,
		'R d-p-q-r-tst-2.R: abs(y[1] - (target - 7.21129e-9)) < 1e-11');
}
near_list(pbinom([-1, 0, 1, 2], size => 0, prob => 0.5), $R{'pbinom(c(-1,0,1,2), size = 0, p = 0.5)'},
	'R reg-tests-1a.R PR#8560: pbinom(c(-1,0,1,2), size = 0, p = 0.5)');

#--------
# R's recycling rule, over every function that recycles
#--------
near_list(dnorm([0, 1], mean => [0, 1], sd => [1, 2]), $R{'dnorm(c(0,1), mean = c(0,1), sd = c(1,2))'},
	'dnorm: x, mean and sd all vectors');
{
	my @w;
	local $SIG{__WARN__} = sub { push @w, @_ };
	near_list(dnorm([1, 2, 3], mean => [1, 2]), $R{'dnorm(1:3, mean = 1:2)'},
		'dnorm: a length that does not divide the longest is reused from its start');
	is(scalar(@w), 0, 'dnorm: and, as in R, without a warning');
}
{
	my @w;
	local $SIG{__WARN__} = sub { push @w, @_ };
	near_list(dnorm(0, sd => [1, -1, 2]), $R{'dnorm(0, sd = c(1,-1,2))'},
		'dnorm: a number x with a vector sd; a negative sd is NaN');
	is(scalar(@w), 1, 'dnorm: one warning for the call');
	like($w[0] // '', qr/\Adnorm: standard deviation must be non-negative/, 'dnorm: the warning names the function');
	@w = ();
	my $r = dnorm(0, sd => [-1, -2, 1]);
	is(scalar(@w), 1, 'dnorm: two negative sds are still one warning, as R gives one');
}
near_list(dnorm([-1, 0, 2], mean => 1, sd => [0.5, 2], log => 1),
	$R{'dnorm(c(-1,0,2), mean = 1, sd = c(0.5,2), log = TRUE)'}, 'dnorm: log with a vector sd');
near_list(pnorm([0, 1], mean => [0, 1, 2, 3]), $R{'pnorm(c(0,1), mean = c(0,1,2,3))'},
	'pnorm: x recycled against a longer mean');
{
	my @w;
	local $SIG{__WARN__} = sub { push @w, @_ };
	near_list(pnorm(1, sd => [1, -1]), $R{'pnorm(1, sd = c(1,-1))'}, 'pnorm: a negative sd in a vector is NaN');
	is(scalar(@w), 1, 'pnorm: one warning for the call');
}
near_list(pnorm([-2, 2], mean => [0, 1], lower => 0, log => 1),
	$R{'pnorm(c(-2,2), mean = c(0,1), lower.tail = FALSE, log.p = TRUE)'}, 'pnorm: upper tail and log with a vector mean');
near_list(qnorm([0.1, 0.9], mean => [1, 2, 3], sd => 2), $R{'qnorm(c(0.1,0.9), mean = c(1,2,3), sd = 2)'},
	'qnorm: a vector mean');
near_list(pt(2, df => [1, undef, 3]), $R{'pt(2, df = c(1,NA,3))'}, 'pt: an undef df is NA there');
near_list(pt([-1, 1], df => [2, 5, 10, 30]), $R{'pt(c(-1,1), df = c(2,5,10,30))'}, 'pt: x recycled against df');
near_list(pt([-1, 1], [2, 5, 10, 30]), $R{'pt(c(-1,1), df = c(2,5,10,30))'}, 'pt: a positional vector df');
near_list(qt([0.025, 0.975], df => [3, 30]), $R{'qt(c(0.025,0.975), df = c(3,30))'}, 'qt: x and df of one length');
near_list(pchisq(3, df => [1, 2, 5]), $R{'pchisq(3, df = c(1,2,5))'}, 'pchisq: a vector df');
near_list(qchisq([0.5, 0.95], df => [1, 10]), $R{'qchisq(c(0.5,0.95), df = c(1,10))'}, 'qchisq: a vector df');
near_list(pf(3, df1 => [2, 4], df2 => 10), $R{'pf(3, df1 = c(2,4), df2 = 10)'}, 'pf: a vector df1');
near_list(qf(0.95, df1 => [1, 2, 3], df2 => [10, 20]), $R{'qf(0.95, df1 = c(1,2,3), df2 = c(10,20))'},
	'qf: two vector parameters of different lengths');
near_list(pbinom(3, size => [5, 10], prob => [0.25, 0.5, 0.75]),
	$R{'pbinom(3, size = c(5,10), prob = c(0.25,0.5,0.75))'}, 'pbinom: vector size and prob');

# a zero-length argument gives an empty answer, as R's numeric(0)
is_deeply(dnorm([], mean => [1, 2]), [], 'R: length(dnorm(numeric(0), mean = 1:2)) is 0');
is_deeply(dnorm(1, mean => []), [], 'R: length(dnorm(1, mean = numeric(0))) is 0');
is_deeply(pt(2, df => []), [], 'pt: an empty df is an empty answer');

# the shape of the answer: a number only when every argument is one
is(ref(dnorm(1)), '', 'dnorm(1) is still a number');
is(ref(dnorm(1, mean => [0])), 'ARRAY', 'a one-element vector parameter gives an array reference');
is(ref(qnorm(0.5, mean => 1, sd => [2])), 'ARRAY', 'qnorm: likewise');

# a word in a parameter vector dies naming it
throws_ok { dnorm(0, mean => [0, 'abc']) } qr/dnorm: error: mean is not a number/, 'dnorm: a word in mean dies naming mean';
throws_ok { pt(1, df => [1, 'abc']) } qr/pt: error: df is not a number/, 'pt: a word in df dies naming df';

no_leaks_ok {
	my $a = dnorm([0, 1], mean => [0, 1], sd => [1, 2]);
	my $b = pt([-1, 1], df => [2, 5, 10]);
	my $c = qf(0.95, df1 => [1, 2], df2 => [10, 20, 30]);
	my $d = dnorm(1, mean => []);
} 'recycling: no memory leaks' unless $INC{'Devel/Cover.pm'};
{
	local $SIG{__WARN__} = sub { };
	no_leaks_ok { my $a = pnorm(1, sd => [1, -1]) } 'recycling: the warning path, no memory leaks' unless $INC{'Devel/Cover.pm'};
}
{
	no_leaks_ok { eval { my $a = dnorm(0, mean => [0, 'abc']) } } 'recycling: the croak path, no memory leaks' unless $INC{'Devel/Cover.pm'};
}

done_testing();
