require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Tie::Array;
use Tie::Scalar;
use Stats::LikeR 't_test';

# t_test() regressions found in 0.3212, checked against R and, where R is the
# one that is wrong, against exact arithmetic.
#
# PROVENANCE
# ----------
# The frozen table in __DATA__ is R 4.6.1 (2026-06-24) output, each double
# written exactly as m * 2^e, and regenerated with
#
#     Rscript t/t_test.tails.R.R
#
# which is never run by this test.  Its cases come from R's own material:
#
#   tests/d-p-q-r-tst-2.R:53    pt(-a, df = 1) == pcauchy(-a) to 1e-15, for a
#                               from 1e15 to 1e300
#   tests/reg-tests-1a.R:4117   the same on the log scale, annotated "failed at
#                               about 1e150 in 2.2.1"
#   src/library/stats/man/t.test.Rd   the sleep data: one-sample, Welch, and the
#                               paired wide-format test
#
# t.test() reaches pt() at those |t| when mu is far from the data, so each a is
# driven through t.test(c(1, 2), mu = 2^k), whose t is 3 - 2^(k+1); then the
# same at df = 2 and at a Welch df of 2.03, which are not the Cauchy case.  The
# mu are powers of two so that every perl parses them to the same NV (5.10.1's
# atof is several ulp out near the exponent extremes).
#
# WHAT THIS FILE PINS
# -------------------
# get_t_pvalue() squared t itself, so past |t| = sqrt(DBL_MAX) ~ 1.34e154 every
# p-value was exactly 0 where R's is a normal number: the df1 rows from k = 664
# up, the tiny rows (data of scale 1e-160 tested against mu = 1), and nothing at
# df 2 because there the tail underflows near the same |t|.  It now goes through
# pt_upper(), which has R's asymptotic branch.
#
# t_test_scan() and the paired loop read AvARRAY() with a length from av_len(),
# so a tied sample was read from the array's stale real storage: an empty one
# croaked "needs at least 2 elements", one with real slots left from before the
# tie segfaulted.  Nor was get magic run on an element or argument before
# SvOK()/SvROK(), so a tied element read as missing and a tied scalar holding
# the array reference was refused.  The sleep rows are run through each of those,
# and through a tied array whose FETCHSIZE grows between calls, which up to
# 0.3212 was written past the end of the buffer sized from the first.
#
# A NaN conf_level gave an interval of (-Inf, Inf) and a NaN mu a NaN t, both
# without an error; R stops on both (t.test.R: is.na(mu), !is.finite(conf.level)).
# An undef or reference mu or conf_level was read as 0 or as an address.
#
# The variance was Welford's, which loses digits R's two-pass form keeps and
# overflows where R's long double does not; the exact-arithmetic block pins
# the two-pass replacement, and the mean's low part that keeps t accurate past
# where R's is.  The pt() symmetry block is d-p-q-r-tests.R:249.
#
# TOLERANCES
# ----------
# Measured worst relative error, on every perl in the local matrix:
#
#                          double     long double / __float128
#   tail rows  statistic   1.6e-16    1.2e-16
#              df          2.2e-16    6.7e-17
#              p_value     1.14e-13   1.38e-14   (the Welch rows)
#   sleep rows             2.6e-15
#   exact rows statistic   2.5e-16
#              stderr      1.9e-16
#              p_value     1.5e-15
#
# The Welch tail p-values are the large ones because p ~ |t|^-df there: the
# relative error of p is ln|t| times the absolute error of df, and ln(2^500) is
# 347, so a df of 2.03 that is one ulp (4.4e-16) from R's moves p by 1.5e-13.
# That is R's df and this module's differing in the last bit.  The double build is the worst; 1e-12 leaves nine times
# its worst.  Do not widen it to make a failure go away.
my $TOL = 1e-12;

my $INF = 9**9**9;

# A table value m p e is m * 2**e, exact on every perl; see t/t_test.tails.R.R
# for why a decimal literal is not.  '-', 'Inf' and '-Inf' pass through.
my %R;
while (my $line = <DATA>) {
	chomp $line;
	next if $line eq '';
	my ($label, @v) = split /\t/, $line;
	for my $v (@v) {
		$v = $1 * 2**$2 if $v =~ /^(-?\d+)p(-?\d+)$/;
	}
	$R{$label} = \@v;
}

sub rel_ok {
	my ($got, $exp, $name) = @_;
	if ($exp eq '-') { return }
	if ($exp eq 'Inf' || $exp eq '-Inf') {
		my $want = $exp eq 'Inf' ? $INF : -$INF;
		return ok(defined $got && $got == $want, "$name is $exp");
	}
	my $err = $exp == 0 ? abs($got) : abs($got - $exp) / abs($exp);
	ok($err <= $TOL, $name)
		or diag(sprintf 'got %.17g, expected %s, rel err %.3g', $got, $exp, $err);
}

sub cmp_r {
	my ($label, $r, $tag) = @_;
	my $exp = $R{$label} or die "no R row '$label'";
	my $name = defined $tag ? "$label ($tag)" : $label;
	rel_ok($r->{statistic},      $exp->[0], "$name: statistic");
	rel_ok($r->{df},             $exp->[1], "$name: df");
	rel_ok($r->{'p_value'},      $exp->[2], "$name: p_value");
	rel_ok($r->{'conf_int'}[0],  $exp->[3], "$name: conf_int[0]");
	rel_ok($r->{'conf_int'}[1],  $exp->[4], "$name: conf_int[1]");
}

my @ALT = qw(two.sided less greater);

# far tails: pt(-a, df = 1) == pcauchy(-a), d-p-q-r-tst-2.R
for my $k (50, 66, 83, 166, 332, 664, 996) {
	for my $alt (@ALT) {
		cmp_r("df1|$k|$alt", t_test([1, 2], mu => 2**$k, alternative => $alt));
	}
}
for my $k (83, 166, 332, 500) {
	for my $alt (@ALT) {
		cmp_r("df2|$k|$alt", t_test([1, 2, 3], mu => 2**$k, alternative => $alt));
		cmp_r("welch|$k|$alt",
			t_test([1, 2], [0, 10, 20], mu => 2**$k, alternative => $alt));
	}
}
for my $alt (@ALT) {
	cmp_r("tiny|$alt", t_test([2**-532, 2**-531], mu => 1, alternative => $alt));
}
# the cliff itself: every p-value of a two-sided df-1 test is positive
ok(t_test([1, 2], mu => 2**1000)->{'p_value'} > 0,
	'df 1, |t| = 2^1001: p_value is not 0');

# t.test.Rd's sleep data, as plain arrays and then through every kind of magic
my @S1 = (0.7, -1.6, -0.2, -1.2, -0.1, 3.4, 3.7, 0.8, 0, 2);
my @S2 = (1.9, 0.8, 1.1, 0.1, -0.1, 4.4, 5.5, 1.6, 4.6, 3.4);

sub sleep_cases {
	my ($x, $y, $tag) = @_;
	cmp_r('sleep|1s',     t_test($x),                  $tag);
	cmp_r('sleep|welch',  t_test($x, $y),              $tag);
	cmp_r('sleep|paired', t_test($x, $y, paired => 1), $tag);
	cmp_r('sleep|paired', t_test(x => $x, y => $y, paired => 1), "$tag, named");
}

sleep_cases(\@S1, \@S2, 'plain arrays');

{
	tie my @x, 'Tie::StdArray';
	tie my @y, 'Tie::StdArray';
	@x = @S1;
	@y = @S2;
	sleep_cases(\@x, \@y, 'tied arrays');
}

{
	# real slots left in the AV from before the tie, then many more through
	# it: this is the shape that read past the old block and segfaulted
	my @x = (10, 20);
	my @y = (10, 20);
	tie @x, 'Tie::StdArray';
	tie @y, 'Tie::StdArray';
	push @x, @S1;
	push @y, @S2;
	sleep_cases(\@x, \@y, 'tied over a real block');
}

{
	my @x = @S1;
	my @y = @S2;
	for my $i (0, 4, 9) {
		my ($xv, $yv) = ($x[$i], $y[$i]);
		$x[$i] = undef;
		$y[$i] = undef;
		tie $x[$i], 'Tie::StdScalar';
		tie $y[$i], 'Tie::StdScalar';
		${ tied $x[$i] } = $xv;
		${ tied $y[$i] } = $yv;
	}
	sleep_cases(\@x, \@y, 'tied elements');
}

{
	tie my $xs, 'Tie::StdScalar';
	tie my $ys, 'Tie::StdScalar';
	${ tied $xs } = [@S1];
	${ tied $ys } = [@S2];
	sleep_cases($xs, $ys, 'tied scalars holding the refs');
}

{
	# FETCHSIZE is perl code and need not answer the same twice.  t_test()
	# sized its buffer from one call and t_test_collect() read up to a second,
	# so an array that grew in between -- with defined values past the old
	# end, as here -- was written past the buffer and segfaulted.  The length
	# t_test() sized from is the one read, so the answers are the sleep rows'.
	package Growing;
	sub TIEARRAY  { my ($c, @v) = @_; bless { v => [@v], calls => 0 }, $c }
	sub FETCHSIZE { my $s = shift; scalar(@{ $s->{v} }) + ($s->{calls}++ ? 100000 : 0) }
	sub FETCH     { my ($s, $i) = @_; $i < @{ $s->{v} } ? $s->{v}[$i] : $i }
	package main;
	my $grown = sub { tie my @a, 'Growing', @_; \@a };	# fresh, so each call's first FETCHSIZE is the real one
	cmp_r('sleep|1s',     t_test($grown->(@S1)),                         'FETCHSIZE grows');
	cmp_r('sleep|welch',  t_test($grown->(@S1), $grown->(@S2)),          'FETCHSIZE grows');
	cmp_r('sleep|paired', t_test($grown->(@S1), $grown->(@S2), paired => 1), 'FETCHSIZE grows');
}

# tests/d-p-q-r-tests.R:249 -- pt(z, df) == 1 - pt(-z, df) to 1e-15 for df in
# 1:10, over rt(1000, df = 2) and +-Inf.  t_test()'s 'less' is pt(t) and its
# 'greater' pt(-t), so the two must sum to 1 at R's own tolerance.  The data are
# 1 .. df + 1, and mu sweeps t across [-40, 40] (where rt(.., 2) puts nearly all
# of its draws) and out to +-Inf.
for my $df (1 .. 10) {
	my @x = (1 .. $df + 1);
	my $worst = 0;
	for my $mu ((map { 1 + $df / 2 + $_ / 4 } -160 .. 160), $INF, -$INF) {
		my $lt = t_test(\@x, mu => $mu, alternative => 'less')->{'p_value'};
		my $gt = t_test(\@x, mu => $mu, alternative => 'greater')->{'p_value'};
		my $err = abs($lt + $gt - 1);
		$worst = $err if $err > $worst;
	}
	ok($worst <= 1e-15, "df $df: P(T < t) + P(T > t) == 1 (worst $worst)");
}

# The variance and the mean difference on data R's own arithmetic cannot
# resolve.  R is not the reference here, because it is the one that is wrong:
# each expected value is exact rational arithmetic on the input doubles
# (Python's fractions.Fraction), with the p-value from mpmath 1.3.0's
# regularized betainc at mp.dps = 60, I_{df/(df+t^2)}(df/2, 1/2).  R 4.6.1's
# answer is recorded beside each, so that moving towards it is a deliberate act.
#
# The data are dyadic, so every NV width reads the same doubles.
#
#   ill-conditioned: seven values 2^33 + (0,1,2,4,5,9,10) * 2^-13, and five at
#   2^33 + (3,7,8,12,13) * 2^-13 -- a spread of 64 to 104 ulps of the mean.
#   R's two-pass variance is good there, but no double holds the mean, and
#   mean - mu cancels to its last bits: R's t is 1.5e-3 out (one-sample
#   3.0255166349294687, Welch -1.7959425214259144).  Welford here was worse
#   than both, as 0.3212's t_test(1e10 + (0..3) * 1e-4) showed.
#
#   overflowing: c(2^511, -2^511, 2^509) and c(2^512, -2^509, 2^510), whose
#   squares are past DBL_MAX.  R's Welch df is written in stderr^4 and comes out
#   NaN, so its p-value is NaN; its pooled variance overflows to Inf and gives
#   t = -0, p = 1.  Its one-sample test survives on long-double accumulation.
#   t_test() returned t = -0 and df = NaN on the Welch case until this fix.
my @ILL_X = map { 2**33 + $_ * 2**-13 } 0, 1, 2, 4, 5, 9, 10;
my @ILL_Y = map { 2**33 + $_ * 2**-13 } 3, 7, 8, 12, 13;
my @BIG_X = (2**511, -2**511, 2**509);
my @BIG_Y = (2**512, -2**509, 2**510);
my @EXACT = (
	# name, call, statistic, df, p_value, stderr
	['ill 1s', sub { t_test(\@ILL_X, mu => 2**33) },
		3.0301037378974968298, 6, 0.023094835525958571617, 0.00017840877573036186901],
	['ill Welch', sub { t_test(\@ILL_X, \@ILL_Y) },
		-1.7957532077704248405, 8.5204508934796146604, 0.10797820075354189341,
		0.00028356212149994561222],
	['ill pooled', sub { t_test(\@ILL_X, \@ILL_Y, var_equal => 1) },
		-1.810016259310846606, 10, 0.10039963237144799446, 0.00028132763264767145163],
	['big 1s', sub { t_test(\@BIG_X) },
		1 / 7, 2, 0.89949621847407879245, 3.9106106462332574874e+153],
	['big Welch', sub { t_test(\@BIG_X, \@BIG_Y) },
		-0.75592894601845445443, 256 / 65, 0.49238333068982682199, 5.9122875681913067771e+153],
	['big pooled', sub { t_test(\@BIG_X, \@BIG_Y, var_equal => 1) },
		-0.75592894601845445443, 4, 0.49176700102216896684, 5.9122875681913067771e+153],
);
for my $c (@EXACT) {
	my ($name, $call, @want) = @$c;
	my $r = $call->();
	my @what = qw(statistic df p_value stderr);
	rel_ok($r->{ $what[$_] }, $want[$_], "exact $name: $what[$_]") for 0 .. 3;
}

# t.test()'s stderr component, R >= 3.6.0 (doc/NEWS.3.Rd:615), on the sleep rows
{
	my $r = t_test(\@S1, \@S2, paired => 1);
	rel_ok($r->{stderr}, ($r->{estimate} - 0) / $r->{statistic}, 'stderr is estimate / statistic');
}

# R stops on both; these used to return (-Inf, Inf) and a NaN t
for my $nan ('NaN', 9**9**9 / 9**9**9) {
	eval { t_test([1, 2, 3], conf_level => $nan) };
	like($@, qr/'conf_level' must be between 0 and 1/, "conf_level => $nan croaks");
	eval { t_test([1, 2, 3], mu => $nan) };
	like($@, qr/'mu' must be a single number/, "mu => $nan croaks");
}
# t.test.R: length(mu) != 1 and length(conf.level) != 1 are errors, and undef
# is R's NULL.  A reference is not a number either; SvNV() on one used to be
# its address.
for my $bad (['undef', undef], ['an array ref', [1]], ['a hash ref', {}]) {
	my ($what, $v) = @$bad;
	eval { t_test([1, 2, 3], mu => $v) };
	like($@, qr/'mu' must be a single number/, "mu => $what croaks");
	eval { t_test([1, 2, 3], conf_level => $v) };
	like($@, qr/'conf_level' must be a single number/, "conf_level => $what croaks");
}
{
	package Two;	# an object that numifies is a number
	use overload '0+' => sub { 2 }, fallback => 1;
}
is(t_test([1, 2, 3], mu => bless({}, 'Two'))->{statistic}, 0,
	'an object overloading 0+ is accepted as mu');

done_testing();

__DATA__
df1|50|two.sided	-4503599627370490p-1	4503599627370496p-52	5734161139222666p-104	-	-
df1|50|less	-4503599627370490p-1	4503599627370496p-52	5734161139222666p-105	-	-
df1|50|greater	-4503599627370490p-1	4503599627370496p-52	9007199254740990p-53	-	-
df1|66|two.sided	-4503599627370496p15	4503599627370496p-52	5734161139222658p-120	-	-
df1|66|less	-4503599627370496p15	4503599627370496p-52	5734161139222658p-121	-	-
df1|66|greater	-4503599627370496p15	4503599627370496p-52	4503599627370496p-52	-	-
df1|83|two.sided	-4503599627370496p32	4503599627370496p-52	5734161139222658p-137	-	-
df1|83|less	-4503599627370496p32	4503599627370496p-52	5734161139222658p-138	-	-
df1|83|greater	-4503599627370496p32	4503599627370496p-52	4503599627370496p-52	-	-
df1|166|two.sided	-4503599627370496p115	4503599627370496p-52	5734161139222673p-220	-	-
df1|166|less	-4503599627370496p115	4503599627370496p-52	5734161139222673p-221	-	-
df1|166|greater	-4503599627370496p115	4503599627370496p-52	4503599627370496p-52	-	-
df1|332|two.sided	-4503599627370496p281	4503599627370496p-52	5734161139222773p-386	-	-
df1|332|less	-4503599627370496p281	4503599627370496p-52	5734161139222773p-387	-	-
df1|332|greater	-4503599627370496p281	4503599627370496p-52	4503599627370496p-52	-	-
df1|664|two.sided	-4503599627370496p613	4503599627370496p-52	5734161139222646p-718	-	-
df1|664|less	-4503599627370496p613	4503599627370496p-52	5734161139222646p-719	-	-
df1|664|greater	-4503599627370496p613	4503599627370496p-52	4503599627370496p-52	-	-
df1|996|two.sided	-4503599627370496p945	4503599627370496p-52	5734161139222357p-1050	-	-
df1|996|less	-4503599627370496p945	4503599627370496p-52	5734161139222357p-1051	-	-
df1|996|greater	-4503599627370496p945	4503599627370496p-52	4503599627370496p-52	-	-
df2|83|two.sided	-7800463371553963p31	4503599627370496p-51	6004799503160660p-220	-	-
df2|83|less	-7800463371553963p31	4503599627370496p-51	6004799503160660p-221	-	-
df2|83|greater	-7800463371553963p31	4503599627370496p-51	4503599627370496p-52	-	-
df2|166|two.sided	-7800463371553963p114	4503599627370496p-51	6004799503160714p-386	-	-
df2|166|less	-7800463371553963p114	4503599627370496p-51	6004799503160714p-387	-	-
df2|166|greater	-7800463371553963p114	4503599627370496p-51	4503599627370496p-52	-	-
df2|332|two.sided	-7800463371553963p280	4503599627370496p-51	6004799503160752p-718	-	-
df2|332|less	-7800463371553963p280	4503599627370496p-51	6004799503160752p-719	-	-
df2|332|greater	-7800463371553963p280	4503599627370496p-51	4503599627370496p-52	-	-
df2|500|two.sided	-7800463371553963p448	4503599627370496p-51	6004799503160745p-1054	-	-
df2|500|less	-7800463371553963p448	4503599627370496p-51	6004799503160745p-1055	-	-
df2|500|greater	-7800463371553963p448	4503599627370496p-51	4503599627370496p-52	-	-
welch|83|two.sided	-6217100122605589p28	4570892723828662p-51	7282825559853146p-216	-	-
welch|83|less	-6217100122605589p28	4570892723828662p-51	7282825559853146p-217	-	-
welch|83|greater	-6217100122605589p28	4570892723828662p-51	4503599627370496p-52	-	-
welch|166|two.sided	-6217100122605589p111	4570892723828662p-51	5220235284561774p-384	-	-
welch|166|less	-6217100122605589p111	4570892723828662p-51	5220235284561774p-385	-	-
welch|166|greater	-6217100122605589p111	4570892723828662p-51	4503599627370496p-52	-	-
welch|332|two.sided	-6217100122605589p277	4570892723828662p-51	5364143822935083p-721	-	-
welch|332|less	-6217100122605589p277	4570892723828662p-51	5364143822935083p-722	-	-
welch|332|greater	-6217100122605589p277	4570892723828662p-51	4503599627370496p-52	-	-
welch|500|two.sided	-6217100122605589p445	4570892723828662p-51	5288331918253126p-1062	-	-
welch|500|less	-6217100122605589p445	4570892723828662p-51	5288331918253126p-1063	-	-
welch|500|greater	-6217100122605589p445	4570892723828662p-51	4503599627370496p-52	-	-
tiny|two.sided	-4503599627370496p481	4503599627370496p-52	5734161139222428p-586	-	-
tiny|less	-4503599627370496p481	4503599627370496p-52	5734161139222428p-587	-	-
tiny|greater	-4503599627370496p481	4503599627370496p-52	4503599627370496p-52	-	-
sleep|1s	5970467695720053p-52	5066549580791808p-49	7839786249863309p-55	-4771837745889853p-53	4570659157000335p-51
sleep|welch	-8380358838779792p-52	5003632468963936p-48	5720950722610995p-56	-7578394511877456p-51	7403313610113149p-55
sleep|paired	-4573549180302679p-50	5066549580791808p-49	6532200057508521p-61	-5539170303434103p-51	-6306068431245122p-53
