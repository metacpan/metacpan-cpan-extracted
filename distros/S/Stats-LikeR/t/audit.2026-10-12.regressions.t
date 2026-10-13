#!/usr/bin/env perl
# Regressions for the bugs the 2026-10-12 audit of LikeR.xs recorded in
# TODO.md, all fixed in 0.3217.  Each block names the function and what used to
# happen; the cases that have an R equivalent compare against R.
#
# Provenance of every expected number below that is not structural:
#
#   * R 4.6.1 (2026-06-24) at options(digits = 17), printed with
#     sprintf("%.17g"):
#       mean(c(1e16,1,-1e16,1)) = 0.5          sum(c(1e16,1,-1e16,1)) = 2
#       mean(c(1e308,1e308))    = 1e308        median(c(1e308,1e308)) = 1e308
#       var(c(1e200,-1e200,3e199)) = Inf       var(c(1e308,1e308)) = 0
#       sd(c(1e308,1e308))      = 0
#       density(c(1,2,3), bw = 1, from = 5, to = 0, n = 4)$y
#         = NA, 0.18920466910630254, 0.28694629077060479, NA
#       x <- sin((1:60)*1.7)*3 + (1:60)*0.05
#       bw.SJ(x, upper = 0.05) = 1.0483967189448875
#       bw.SJ(x, lower = 2)    = 1.0405195368511189
#       z <- (50.5 - 150.5) / sqrt(200*201/12 * (1/100 + 1/100))
#         = -12.216944435630522, and 2*pnorm(-abs(z)) = 2.5239394239903431e-34
#         (Dunn's z for 1..200 split into two groups of 100: the groups' mean
#         ranks are 50.5 and 150.5, and there are no ties).  The p-value is
#         checked against mpmath 1.3.0 at mp.dps = 50 instead, where z is
#         -100/sqrt(67) and 2*ncdf(z) = 2.523939423990322660909899831944e-34:
#         R's own value is 8.1e-15 from it.
#       rbinom(2, 10, NaN), rbinom(1, 2.5, .5), runif(2, 0, Inf) and
#       rnorm(2, 0, Inf) are all NA, each with the warning "NAs produced";
#       rnorm(2, 3, 0) is 3, 3
#       var.test(c(1,2,3,4), c(5,5,5), alternative = a): F = Inf with p 0 for
#       "two.sided" and "greater", p 1 for "less"; conf.int [Inf, Inf],
#       [0, Inf], [Inf, Inf].  var.test(c(2,2,2), c(5,5,5), ...) is NaN, with
#       conf.int [NaN, NaN], [0, NaN] and [NaN, Inf].
#   * mode()'s and transpose()'s expectations are README's own examples.
#
# Tolerances: the R values are compared at 1e-14 relative, and every one of
# them matched to the last bit on perl-5.44.0 (double).  The Dunn p-value has
# its own, $TOL_DUNN, because it is a normal tail at |z| = 12.2, where erfc()
# multiplies any error in its argument by about 2z^2 = 300: against mpmath it
# was 1.8e-15 out on perl-5.44.0 (double).  var() of values whose squares
# overflow a double is Inf only where an NV is a double; a long double holds
# 1.03e400, and that is then the answer.
require 5.010;
use strict;
use warnings FATAL => 'all';
use Config;
use Test::More;
use Stats::LikeR qw(
	add_data bedroc bw_bcv bw_nrd bw_nrd0 bw_sj bw_ucv cmh_test density
	dunn_test epi_2x2 friedman_test get_union hist intersection is_equivalent
	kurtosis ljoin Lonly matrix mcnemar_test mean median mode prop_test rbinom
	rnorm Ronly runif sample sd skew sum transpose value_counts var var_test
);

my $INF = 9**9**9;
my $TOL = 1e-14;	# see the header
my $TOL_DUNN = 1e-13;	# see the header: 55 times the 1.8e-15 seen
sub near {
	my ($got, $want, $name, $tol) = @_;
	$tol = $TOL unless defined $tol;
	my $err = $want == 0 ? abs($got) : abs($got - $want) / abs($want);
	ok($err <= $tol, $name) or diag(sprintf('got %.17g, want %.17g', $got, $want));
}
sub is_nan { my $v = shift; return defined $v && $v != $v }
sub dies_like {
	my ($code, $re, $name) = @_;
	my $lived = eval { $code->(); 1 };
	ok(!$lived && $@ =~ $re, $name) or diag($lived ? 'lived' : "died: $@");
}
#Runs $code with warnings captured, and returns its result and the warnings.
sub with_warnings {
	my $code = shift;
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	my $r = $code->();
	return ($r, \@w);
}
#A guard against the hangs this file exists for: on a perl where alarm() can
#interrupt the loop, a regression fails instead of stalling the suite.
sub finishes {
	my ($code, $name) = @_;
	my $ok = eval {
		local $SIG{ALRM} = sub { die "timed out\n" };
		alarm 20;
		$code->();
		alarm 0;
		1;
	};
	alarm 0;
	ok($ok, $name) or diag($@);
}
{
	package TiedArr;	# a tied array whose elements exist only once FETCH runs
	require Tie::Array;
	our @ISA = ('Tie::StdArray');
}
sub tied_of {
	tie my @t, 'TiedArr';
	@t = @_;
	return \@t;
}

# ---- Hangs ----
{
	my ($r, $w) = with_warnings(sub { rbinom(n => 3, size => 10, prob => 'nan') });
	ok(@$r == 3 && !grep({ !is_nan($_) } @$r), 'rbinom: prob NaN gives NaN for every draw, as R does');
	ok(@$w == 1 && $w->[0] =~ /NAs produced/, 'rbinom: and warns "NAs produced", as R does');
	dies_like(sub { rbinom(n => 3, size => 10, prob => 'abc') }, qr/prob must be a number/,
		"rbinom: prob 'abc' croaks; it used to be read as 0");
	($r, $w) = with_warnings(sub { rbinom(n => 2, size => 2.5, prob => 0.5) });
	ok(@$r == 2 && is_nan($r->[0]) && is_nan($r->[1]), 'rbinom: a fractional size gives NaN, as R does; it drew from size 2');
	dies_like(sub { rbinom(size => 10, prob => 0.5) }, qr/'n' is a required argument/,
		'rbinom: n omitted croaks; it used to return []');
	finishes(sub { rbinom(n => 1, size => 1, prob => 0.5, map { (n => 1) } 1 .. 35000) },
		'rbinom: more than 65535 arguments no longer wrap the loop counter');
	finishes(sub { hist([1 .. 10], ('x') x 70001) },
		'hist: more than 65535 arguments no longer wrap the loop counter');
	my $b;
	finishes(sub { $b = bedroc([1, 'nan', 3, 4], [0, 0, 1, 1]) }, 'bedroc: a NaN score no longer hangs');
	is($b->{n}, 3, 'bedroc: and its case is dropped');
	near($b->{bedroc}, bedroc([1, 3, 4], [0, 1, 1])->{bedroc}, 'bedroc: the answer is that of the other three');
}

# ---- Wrong results ----
{
	near(mean([1e16, 1, -1e16, 1]), 0.5, 'mean: compensated, as R is in long double; was 0');
	near(sum([1e16, 1, -1e16, 1]), 2, 'sum: likewise');
	near(mean([1e308, 1e308]), 1e308, 'mean: a sum that overflows is rescaled; was Inf');
	near(median([1e308, 1e308]), 1e308, 'median: the pair is halved first; was Inf');
	if ($Config{nvsize} == 8) {
		is(var([1e200, -1e200, 3e199]), $INF, 'var: overflow is Inf, as in R; was NaN');
	} else {	# the squares fit: (9e199^2 + 1.1e200^2 + 2e199^2) / 2
		near(var([1e200, -1e200, 3e199]), 1.03 * 1e200 * 1e200, 'var: a wide NV holds 1.03e400', 1e-12);
	}
	is(var([1e308, 1e308]), 0, 'var: 0 for equal values that overflow a sum, as in R; was NaN');
	is(sd([1e308, 1e308]), 0, 'sd: likewise');
	is(mean([1e308, 'inf']), $INF, 'mean: a real Inf is still Inf');

	my ($r, $w) = with_warnings(sub { runif(2, 0, $INF) });
	ok(is_nan($r->[0]) && is_nan($r->[1]) && @$w == 1, 'runif: an infinite bound gives NaN with a warning, as R; was Inf');
	($r, $w) = with_warnings(sub { rnorm(n => 2, sd => $INF) });
	ok(is_nan($r->[0]) && is_nan($r->[1]) && @$w == 1, 'rnorm: sd => Inf gives NaN with a warning, as R; was +-Inf');
	is_deeply(rnorm(n => 2, mean => 3, sd => 0), [3, 3], 'rnorm: sd => 0 gives the mean, as R');

	my $d = density([1, 2, 3], bw => 1, from => 5, to => 0, n => 4);
	ok(is_nan($d->{y}[0]) && is_nan($d->{y}[3]), 'density: from > to leaves NaN outside the grid, as R leaves NA');
	near($d->{y}[1], 0.18920466910630254, 'density: from > to, y[1] as R');
	near($d->{y}[2], 0.28694629077060479, 'density: from > to, y[2] as R');
	dies_like(sub { density([], bw => 1, from => 0, to => 1) }, qr/no non-missing values/,
		'density: empty x croaks, as R errors; it returned zeros');

	my @x = map { sin($_ * 1.7) * 3 + $_ * 0.05 } 1 .. 60;
	near(bw_sj(\@x, upper => 0.05), 1.0483967189448875, 'bw_sj: one bound given still widens the interval, as R; it croaked');
	near(bw_sj(\@x, lower => 2), 1.0405195368511189, 'bw_sj: likewise with only lower');

	my $dn = dunn_test([1 .. 200], [('a') x 100, ('b') x 100]);
	near($dn->[0]{Z}, -12.216944435630522, 'dunn_test: Z');
	near($dn->[0]{p_value}, 2.523939423990322660909899831944e-34, 'dunn_test: p from pnorm(-|z|), as R; was 0', $TOL_DUNN);
	for my $m (qw(holm hs bonferroni bh)) {
		my $c = dunn_test([(5) x 9], [qw(a a a b b b c c c)], method => $m);
		ok(!grep({ !is_nan($_->{p_adjust}) } @$c), "dunn_test: a NaN p stays NaN under $m, as p.adjust() keeps NA; holm and hs gave 0");
	}

	for my $alt (qw(two.sided less greater)) {
		my $v = var_test([1, 2, 3, 4], [5, 5, 5], alternative => $alt);
		is($v->{statistic}, $INF, "var_test $alt: zero variance in y gives F = Inf, as R; it croaked");
		is($v->{p_value}, $alt eq 'less' ? 1 : 0, "var_test $alt: p as R");
		is_deeply($v->{conf_int}, $alt eq 'less' ? [0, $INF] : [$INF, $INF], "var_test $alt: interval as R");
		my $z = var_test([2, 2, 2], [5, 5, 5], alternative => $alt);
		ok(is_nan($z->{statistic}) && is_nan($z->{p_value}), "var_test $alt: both variances zero gives NaN, as R");
	}
	dies_like(sub { var_test([1, 2, 3], [1, 2, 4], alternative => 'bogus') }, qr/'alternative' must be/,
		"var_test: alternative 'bogus' croaks; it ran a two-sided test");

	is_deeply([mode('a', 'a', 'c', 'c', 'z')], ['a', 'c'], 'mode: ties in first-seen order, as README promises');
	my @many = map { ($_, $_) } reverse 'a' .. 't';
	is_deeply([mode(@many)], [reverse 'a' .. 't'], 'mode: twenty ties, in first-seen order rather than hash order');

	my $t = bedroc([5, 5, 5, 5], [1, 0, 0, 0], top => 0.25)->{enrichment};
	my $u = bedroc([5, 5, 5, 5], [0, 0, 0, 1], top => 0.25)->{enrichment};
	is($t->{active_count}, 0.25, 'bedroc: a tie straddling the top cut counts its actives in proportion');
	is($u->{active_count}, 0.25, 'bedroc: whatever the input order; it was 1 and 0');

	my @truth = (0.9, 0.1, 'nan', 0.8, 0.2, 0.7, 0.3, 0.6, 0.4);
	my @score = (9, 1, 5, 8, 2, 7, 3, 6, 4);
	my $want = bedroc(\@score, \@truth, active_frac => 0.3)->{bedroc};
	my $same = 1;
	for my $k (1 .. 30) {	# a fixed sequence of rotations, so the order varies but the run does not
		my @i = map { ($_ + $k) % 9 } 0 .. 8;
		my $got = bedroc([@score[@i]], [@truth[@i]], active_frac => 0.3)->{bedroc};
		$same &&= abs($got - $want) < 1e-12;
	}
	ok($same, 'bedroc: a NaN truth value is dropped, so active_frac no longer depends on input order');
	is(bedroc(\@score, \@truth, cutoff => 0.5)->{n}, 8, 'bedroc: and under cutoff it is dropped rather than inactive');

	my $f = friedman_test([[1, 2, 3], [1, undef, 3], [2, 3, 1]]);
	is($f->{n}, 2, 'friedman_test: incomplete blocks still dropped');
	dies_like(sub { friedman_test([[1, 2, 3], [1, undef, 3]]) }, qr/not enough blocks/,
		'friedman_test: one complete block croaks, as R errors');
}

# ---- 32-bit size_t and products that overflow ----
{
	# each dimension fits a 32-bit size_t, so it is the product that is refused
	dies_like(sub { matrix([1], 2**30, 2**30) }, qr/too many cells/,
		'matrix: a product of dimensions past 2^48 croaks; it could wrap');
	dies_like(sub { rnorm(n => 2**49) }, qr/too large/, 'rnorm: n past 2^48 croaks');
	if ($Config{sizesize} == 4) {	# where size_t is 32 bits, 2**32 + 2 used to wrap to 2
		dies_like(sub { rnorm(n => 2**32 + 2) }, qr/too large/, 'rnorm: n past SIZE_MAX croaks on a 32-bit size_t');
		dies_like(sub { sample([1 .. 5], 2**32 + 1) }, qr/too large/, 'sample: n past SIZE_MAX croaks on a 32-bit size_t');
	}
}

# ---- Tied arrays: every element used to read as undef ----
{
	my $t = tied_of(1, 2, 3, 4, 5, 7, 9);
	my @p = (1, 2, 3, 4, 5, 7, 9);
	is_deeply(hist($t), hist(\@p), 'hist: a tied array is read');
	is_deeply(density($t, bw => 1), density(\@p, bw => 1), 'density: a tied array is read');
	for my $f ([bw_nrd0 => \&bw_nrd0], [bw_nrd => \&bw_nrd], [bw_ucv => \&bw_ucv], [bw_bcv => \&bw_bcv], [bw_sj => \&bw_sj]) {
		my ($name, $code) = @$f;
		my ($g, $want);
		{
			local $SIG{__WARN__} = sub {};	# bw_ucv and bw_bcv warn on so small a sample
			$g    = $code->(tied_of(@p));
			$want = $code->(\@p);
		}
		is($g, $want, "$name: a tied array is read");
	}
	is_deeply(var_test(tied_of(1, 2, 3, 5), [2, 4, 7, 8]), var_test([1, 2, 3, 5], [2, 4, 7, 8]), 'var_test: a tied array is read');
	is_deeply([get_union(tied_of(1, 2, 3), [3, 4])], [1, 2, 3, 4], 'get_union: a tied array is read');
	is_deeply([intersection(tied_of(1, 2, 3), [3, 2, 9])], [2, 3], 'intersection: a tied array is read');
	is_deeply([Lonly(tied_of(1, 2, 3), [3])], [1, 2], 'Lonly: a tied array is read');
	is_deeply([Ronly([1], tied_of(1, 2, 3))], [2, 3], 'Ronly: a tied array is read');
	is(is_equivalent(tied_of(1, 2, 3), [3, 2, 1]), 1, 'is_equivalent: a tied array is read');
	is_deeply(value_counts(tied_of({ k => 1 }, { k => 2 }, { k => 1 }), 'k'), { 1 => 2, 2 => 1 },
		'value_counts: a tied array of hashes is read');
}

# ---- Aliasing: results are copies ----
{
	my $m = [[1, 2], [3, 4]];
	transpose($m)->[0][1] = 99;
	is_deeply($m, [[1, 2], [3, 4]], 'transpose AoA: writing the result leaves the input alone');
	my $h = { a => { x => 1 } };
	transpose($h)->{x}{a} = 5;
	is($h->{a}{x}, 1, 'transpose HoH: likewise');
	my @hole = ([1]);
	$#{ $hole[0] } = 1;	# row 0 is [1, hole]
	my $th = transpose(\@hole);
	ok(eval { $th->[1][0] = 'w'; 1 }, 'transpose: a hole becomes a writable undef, not the read-only &PL_sv_undef');

	my %h = (r1 => { a => 1 });
	my %i = (r1 => { b => 2 });
	ljoin(\%h, \%i);
	$h{r1}{b} = 'X';
	is($i{r1}{b}, 2, 'ljoin: the joined value is a copy');
	my %ad = (r1 => { a => 1 });
	add_data(\%ad, { r1 => { b => 2 } });
	is($ad{r1}{b}, 2, 'add_data: still adds');

	my @a = (1 .. 10);
	$_ += 1000 for @{ sample(\@a, 3) };
	is_deeply(\@a, [1 .. 10], 'sample array: the drawn values are copies');
	my %sh = (a => 1, b => 2, c => 3);
	$_ += 1000 for values %{ sample(\%sh, 2) };
	is_deeply(\%sh, { a => 1, b => 2, c => 3 }, 'sample hash: likewise');
}

# ---- sample() draws the same values for a seed whether n is small or not ----
{
	my @a = (1 .. 400);
	srand(7); my $small = sample(\@a, 10);	# below count/4: the sparse table
	srand(7); my $full  = sample(\@a, 400);	# the whole index array
	is_deeply($small, [@{$full}[0 .. 9]], 'sample: the sparse draw is the same shuffle, step for step');
}

# ---- Input validation ----
{
	is(scalar @{ rnorm(1e3) },   1000, 'rnorm: rnorm(1e3) works; it croaked with the usage message');
	is(scalar @{ rnorm('5') },   5,    'rnorm: a numeric string works');
	is(scalar @{ rnorm(2.5*2) }, 5,    'rnorm: an expression works');
	is(scalar @{ rnorm(10, 0, 1) }, 10, "rnorm: R's positional rnorm(10, 0, 1) works");
	dies_like(sub { rnorm(n => 2, mean => 'abc') }, qr/'mean' must be a number/, 'rnorm: a mean that is not a number croaks');

	dies_like(sub { prop_test(5, 10, 'conf_level') }, qr/key => value pairs/, 'prop_test: a dangling key croaks');
	is_deeply(prop_test([83, undef, 90], [100, 100, 100])->{estimate}, [0.83, 0.9], 'prop_test: an undef case is dropped, as R');
	my @hx; $hx[0] = 83; $hx[2] = 90;
	is_deeply(prop_test(\@hx, [100, 100, 100])->{estimate}, [0.83, 0.9], 'prop_test: a hole likewise');

	dies_like(sub { epi_2x2('abc', 1, 2, 3) }, qr/cell at index 0 is not a number/, 'epi_2x2: the scalar form checks cells as the array form does');
	dies_like(sub { epi_2x2([$INF, 1, 2, 3]) }, qr/must be finite/, 'epi_2x2: an Inf cell croaks');
	dies_like(sub { epi_2x2(['nan', 1, 2, 3]) }, qr/must not be NaN/, 'epi_2x2: a NaN cell croaks');
	dies_like(sub { cmh_test([[5, 'nan', 3, 4]]) }, qr/must not be NaN/, "cmh_test: a NaN cell croaks, as R's \"NAs are not allowed\"");

	dies_like(sub { mcnemar_test([[1, $INF], [2, 3]]) }, qr/nonnegative and finite/, 'mcnemar_test: Inf croaks, as its message says');
	dies_like(sub { mcnemar_test([[1, undef], [2, 3]]) }, qr/nonnegative and finite/, 'mcnemar_test: undef croaks; it was 0');
	dies_like(sub { mcnemar_test([[1, 'abc'], [2, 3]]) }, qr/nonnegative and finite/, "mcnemar_test: 'abc' croaks; it was 0");
	dies_like(sub { mcnemar_test([[1, 2.5], [3.7, 4]], exact => 1) }, qr/whole-number counts/,
		'mcnemar_test: the exact test refuses fractional counts; it truncated them');

	my $L1 = 'x' x 200;
	my $L2 = 'y' x 200;
	is(length dunn_test([1 .. 6], [($L1) x 3, ($L2) x 3])->[0]{comparison}, 403,
		'dunn_test: the comparison string is not truncated at 255 bytes');

	dies_like(sub { density([1, 2, 3], weights => [0.5, 0.5, 'abc'], bw => 1) }, qr/'weights' must be numeric/,
		"density: a weight that is not a number croaks; it was 0");

	ok(is_nan(skew(['nan', 1, 2, 3])), 'skew: NaN in gives NaN; it croaked about zero variance');
	ok(is_nan(kurtosis([1, 2, 3, 'inf', 5])), 'kurtosis: Inf in gives NaN');

	is_deeply(value_counts(undef, 'a'), { a => 1 }, 'value_counts: an undef first is skipped as anywhere else');

	dies_like(sub { bedroc([1, 2, 3, 4], [0, 0, 1, 1], direction => 'up') }, qr/direction must be/,
		"bedroc: a direction other than '>' or '<' croaks");
	dies_like(sub { bedroc([1, 2, 3, 4], [0, 0, 1, 1], 'alpha') }, qr/key => value pairs/,
		'bedroc: a dangling key croaks');
	is(bedroc([1, undef, 3, 4, 2], [0, 1, 1, 1, undef])->{n}, 3, 'bedroc: an undef score or label drops its case');
	my $e8 = "\x{e9}";
	my $e8u = $e8;
	utf8::upgrade($e8u);
	is(bedroc([4, 3, 2, 1], [$e8, 'n', $e8u, 'n'], positive => $e8)->{n_active}, 2,
		'bedroc: labels compare as eq does, across UTF-8 and byte strings');
}

done_testing();
