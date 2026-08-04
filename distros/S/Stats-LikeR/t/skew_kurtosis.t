#!/usr/bin/env perl
require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Test::Exception;
use Test::LeakTrace;
use Stats::LikeR;

# skew() and kurtosis() accumulate the third and fourth central moments in one
# pass (Welford/Terriberry) instead of centering the sample in a second pass
# the way R does, so the two things worth covering are (a) that all three
# estimator conventions come out equal to R's, on data both languages parse to
# the same doubles, and (b) that the recurrence stays accurate on the shapes
# that break moment code: heavy ties, a mean far from zero, long samples.
#
# The reference numbers below are e1071::skewness / e1071::kurtosis, computed
# by reimplementing those two functions in base R (e1071 itself is not a
# dependency here).  Every dataset is written as decimal literals, so R and
# Perl hold bit-identical values and the comparison is meaningful to ~1e-15.

my %data = (
	wiki    => [2, 4, 4, 4, 5, 5, 7, 9],
	seq10   => [1 .. 10],
	three   => [1, 2, 4],
	four    => [1, 2, 3, 10],
	negs    => [-5, -1, -3, 2, 8, -9, 4],
	ties    => [1, 1, 1, 1, 1, 2],
	modular => [ map { ($_ * $_) % 97 } 1 .. 200 ],
	mpg     => [21.0, 21.0, 22.8, 21.4, 18.7, 18.1, 14.3, 24.4, 22.8, 19.2,
	            17.8, 16.4, 17.3, 15.2, 10.4, 10.4, 14.7, 32.4, 30.4, 33.9,
	            21.5, 15.5, 15.2, 13.3, 19.2, 27.3, 26.0, 30.4, 15.8, 19.7,
	            15.0, 21.4],
	wt      => [2.620, 2.875, 2.320, 3.215, 3.440, 3.460, 3.570, 3.190, 3.150,
	            3.440, 3.440, 4.070, 3.730, 3.780, 5.250, 5.424, 5.345, 2.200,
	            1.615, 1.835, 2.465, 3.520, 3.435, 3.840, 3.845, 1.935, 2.140,
	            1.513, 3.170, 2.770, 3.570, 2.780],
	right   => [1, 1, 1, 2, 2, 3, 4, 8, 16, 32, 64],
);

# 'set.type' => [ skewness, kurtosis ]; undef where R's own guard refuses
my %R = (
	'wiki.1'    => [ 0.65625,               -0.21875 ],
	'wiki.2'    => [ 0.81848755335679968,    0.94062500000000004 ],
	'wiki.3'    => [ 0.53713245689039979,   -0.87060546875 ],
	'seq10.1'   => [ 0,                     -1.2242424242424241 ],
	'seq10.2'   => [ 0,                     -1.1999999999999997 ],
	'seq10.3'   => [ 0,                     -1.5616363636363635 ],
	'three.1'   => [ 0.38180177416060579,   -1.5000000000000004 ],
	'three.2'   => [ 0.93521952958282328,    undef ],
	'three.3'   => [ 0.20782656212951633,   -2.3333333333333335 ],
	'four.1'    => [ 1.0182337649086284,    -0.76960000000000006 ],
	'four.2'    => [ 1.7636326148038881,     3.2279999999999998 ],
	'four.3'    => [ 0.66136223055145804,   -1.7454000000000001 ],
	'negs.1'    => [ 0.04020371727893314,   -0.9685526579571655 ],
	'negs.2'    => [ 0.052109973359373063,  -0.52452637909719724 ],
	'negs.3'    => [ 0.031904065322065141,  -1.5075080752338357 ],
	'ties.1'    => [ 1.7888543819998306,     1.1999999999999984 ],
	'ties.2'    => [ 2.4494897427831765,     5.9999999999999956 ],
	'ties.3'    => [ 1.3608276348795427,    -0.083333333333333925 ],
	'modular.1' => [ 0.051867237076798474,  -1.2983034823432069 ],
	'modular.2' => [ 0.052260006558087969,  -1.3007445262330395 ],
	'modular.3' => [ 0.05147871946004455,   -1.3152779051068333 ],
	'mpg.1'     => [ 0.64043986403188546,   -0.2005332097154966 ],
	'mpg.2'     => [ 0.67237713762908258,   -0.022006291424083932 ],
	'mpg.3'     => [ 0.61065501757328788,   -0.37276602982089102 ],
	'wt.1'      => [ 0.44378553550607763,    0.1724705401587352 ],
	'wt.2'      => [ 0.46591610679298712,    0.41659466963492653 ],
	'wt.3'      => [ 0.42314646417722462,   -0.022710752839311787 ],
	'right.1'   => [ 1.9384900166147079,     2.5430979821866027 ],
	'right.2'   => [ 2.2590060905722331,     5.071829970311005 ],
	'right.3'   => [ 1.6802524640619914,     1.5810727125509105 ],
);

sub close_to {
	my ($got, $want, $tol, $name) = @_;
	my $scale = abs($want) > 1e-12 ? abs($want) : 1;
	my $rel   = abs($got - $want) / $scale;
	ok($rel <= $tol, $name) or diag("got $got, want $want, relative error $rel");
}

# --- every dataset, every type, against R
for my $set (sort keys %data) {
	for my $type (1, 2, 3) {
		my ($rsk, $rku) = @{ $R{"$set.$type"} };
		close_to(skew($data{$set}, type => $type), $rsk, 1e-12,
		         "skew: $set type $type matches R");
		if (defined $rku) {
			close_to(kurtosis($data{$set}, type => $type), $rku, 1e-12,
			         "kurtosis: $set type $type matches R");
		} else {
			throws_ok { kurtosis($data{$set}, type => $type) }
				qr/type 2 needs >= 4 elements/,
				"kurtosis: $set type 2 refuses n < 4, as R does";
		}
	}
}

# --- type 2 is the default (G1/G2: SAS, SPSS, Stata, Excel, scipy unbiased)
is(skew($data{wiki}),     skew($data{wiki}, type => 2),     'skew: default is type 2');
is(kurtosis($data{wiki}), kurtosis($data{wiki}, type => 2), 'kurtosis: default is type 2');

# --- argument shapes, all of which must reach the same accumulator
my @w = @{ $data{wiki} };
my $want_sk = skew(\@w);
is(skew(@w),                        $want_sk, 'skew: bare list');
is(skew(x => \@w),                  $want_sk, 'skew: x => arrayref');
is(skew(\@w, 'type', 2),            $want_sk, 'skew: key/value without a fat comma');
is(skew(type => 2, x => \@w),       $want_sk, 'skew: named args in either order');
is(skew(@w[0 .. 3], [@w[4 .. 7]]),  $want_sk, 'skew: scalars and array refs mixed');
is(skew([@w[0 .. 1]], [@w[2 .. 7]]),$want_sk, 'skew: several array refs concatenate');
is(skew(map { "$_" } @w),           $want_sk, 'skew: numeric strings are data, not option names');
my $want_ku = kurtosis(\@w);
is(kurtosis(@w),                    $want_ku, 'kurtosis: bare list');
is(kurtosis(x => \@w, type => 2),   $want_ku, 'kurtosis: x => arrayref with type');

# --- a tied array: only av_fetch sees its elements
{
	package Tie::CountUp;
	require Tie::Array;
	our @ISA = ('Tie::StdArray');
}
{
	my @tied;
	tie @tied, 'Tie::CountUp';
	@tied = @w;
	close_to(skew(\@tied),     $want_sk, 1e-15, 'skew: reads a tied array');
	close_to(kurtosis(\@tied), $want_ku, 1e-15, 'kurtosis: reads a tied array');
}

# --- shape properties -----------------------------------------------------
# skewness is zero for a symmetric sample, and flips sign when the sample is
# reflected; kurtosis is blind to reflection
my @sym = (-4, -2, -1, 0, 1, 2, 4);
for my $type (1, 2, 3) {
	close_to(skew(\@sym, type => $type), 0, 1e-14, "skew: symmetric sample is 0 (type $type)");
	close_to(skew([ map { -$_ } @w ], type => $type), -skew(\@w, type => $type), 1e-14,
	         "skew: reflection flips the sign (type $type)");
	close_to(kurtosis([ map { -$_ } @w ], type => $type), kurtosis(\@w, type => $type), 1e-14,
	         "kurtosis: reflection leaves it alone (type $type)");
}

# both are dimensionless: shifting and positively scaling the sample must not
# move them.  The shift by 1e6 is also the accuracy check the one-pass
# recurrence exists for -- the raw-moment form loses every digit here.
for my $type (1, 2, 3) {
	for my $shift (10, 1e6) {
		close_to(skew([ map { $_ + $shift } @w ], type => $type),
		         skew(\@w, type => $type), 1e-6,
		         "skew: unchanged by a shift of $shift (type $type)");
		close_to(kurtosis([ map { $_ + $shift } @w ], type => $type),
		         kurtosis(\@w, type => $type), 1e-6,
		         "kurtosis: unchanged by a shift of $shift (type $type)");
	}
	close_to(skew([ map { $_ * 1000 } @w ], type => $type),
	         skew(\@w, type => $type), 1e-12,
	         "skew: unchanged by a positive scaling (type $type)");
	close_to(kurtosis([ map { $_ * 1000 } @w ], type => $type),
	         kurtosis(\@w, type => $type), 1e-12,
	         "kurtosis: unchanged by a positive scaling (type $type)");
}

# --- long samples, against a plain two-pass reference ---------------------
# the recurrence is the only thing under test here, so the reference is the
# textbook centered form written out in Perl
sub two_pass {
	my ($x, $type) = @_;
	my $n = @$x;
	my $m = 0; $m += $_ for @$x; $m /= $n;
	my ($s2, $s3, $s4) = (0, 0, 0);
	for (@$x) {
		my $d  = $_ - $m;
		my $d2 = $d * $d;
		$s2 += $d2; $s3 += $d2 * $d; $s4 += $d2 * $d2;
	}
	my ($m2, $m3, $m4) = ($s2 / $n, $s3 / $n, $s4 / $n);
	my $g1 = $m3 / $m2 ** 1.5;
	my $r  = $m4 / ($m2 * $m2);
	my $sk = $type == 1 ? $g1
	       : $type == 2 ? $g1 * sqrt($n * ($n - 1)) / ($n - 2)
	       :              $g1 * (($n - 1) / $n) ** 1.5;
	my $ku = $type == 1 ? $r - 3
	       : $type == 2 ? (($n + 1) * ($r - 3) + 6) * ($n - 1) / (($n - 2) * ($n - 3))
	       :              $r * (1 - 1 / $n) ** 2 - 3;
	return ($sk, $ku);
}

srand 20260803;
my %generator = (
	'uniform'      => sub { rand(1) },
	'right skewed' => sub { -log(rand() || 1e-12) },        # exponential
	'heavy tailed' => sub { my $u = rand(); ($u < 0.02 ? 50 : 1) * (rand() - 0.5) },
	'two spikes'   => sub { rand() < 0.5 ? rand(0.1) : 10 + rand(0.1) },
);
for my $name (sort keys %generator) {
	my $worst = 0;
	for my $n (4, 5, 17, 250, 1000, 5000) {
		my $x = [ map { $generator{$name}->() } 1 .. $n ];
		for my $type (1, 2, 3) {
			my ($rsk, $rku) = two_pass($x, $type);
			for my $pair ([ skew($x, type => $type), $rsk ],
			              [ kurtosis($x, type => $type), $rku ]) {
				my ($got, $want) = @$pair;
				my $scale = abs($want) > 1e-9 ? abs($want) : 1;
				my $rel   = abs($got - $want) / $scale;
				$worst = $rel if $rel > $worst;
			}
		}
	}
	# 1e-8, not machine epsilon: the two forms round differently, and for the
	# near-symmetric generators the skewness is itself close to zero, which
	# inflates the relative gap.  A mistake in the recurrence shows up at
	# 1e-2 or worse, so this still has all the resolution it needs.
	ok($worst < 1e-8, "'$name' samples agree with a two-pass reference (worst $worst)");
}

# --- the caller's data is left alone
my @orig = (5, 3, 9, 1, 7, 2);
my @snap = @orig;
skew(\@orig); kurtosis(\@orig);
is_deeply(\@orig, \@snap, 'skew/kurtosis: do not touch the array they were given');

# --- minimum sample sizes -------------------------------------------------
lives_ok { skew([1, 2], type => 1) }     'skew: type 1 accepts n = 2';
lives_ok { skew([1, 2], type => 3) }     'skew: type 3 accepts n = 2';
lives_ok { skew([1, 2, 4], type => 2) }  'skew: type 2 accepts n = 3';
lives_ok { kurtosis([1, 2], type => 1) } 'kurtosis: type 1 accepts n = 2';
lives_ok { kurtosis([1, 2, 3, 10], type => 2) } 'kurtosis: type 2 accepts n = 4';
throws_ok { skew([1, 2], type => 2) } qr/\Qskew: type 2 needs >= 3 elements\E/,
	'skew: type 2 needs three points to divide by n - 2';
throws_ok { kurtosis([1, 2, 4], type => 2) } qr/\Qkurtosis: type 2 needs >= 4 elements\E/,
	'kurtosis: type 2 needs four points to divide by n - 3';
throws_ok { skew(1) }     qr/\Qskew needs >= 2 elements\E/,     'skew: one point is not a sample';
throws_ok { kurtosis(1) } qr/\Qkurtosis needs >= 2 elements\E/, 'kurtosis: one point is not a sample';
throws_ok { skew() }      qr/\Qskew needs >= 2 elements\E/,     'skew: dies with no arguments';
throws_ok { kurtosis([]) } qr/\Qkurtosis needs >= 2 elements\E/,'kurtosis: dies on an empty array ref';

# --- a constant sample has no shape at all
throws_ok { skew([7, 7, 7, 7]) } qr/\Qskew: zero variance (all 4 values are equal)\E/,
	'skew: names the sample size when the variance is zero';
throws_ok { kurtosis([7, 7, 7, 7]) } qr/\Qkurtosis: zero variance (all 4 values are equal)\E/,
	'kurtosis: names the sample size when the variance is zero';

# --- bad arguments --------------------------------------------------------
throws_ok { skew(1, undef, 3) } qr/\Qskew: undefined value at argument index 1\E/,
	'skew: names the argument index of an undef scalar';
throws_ok { kurtosis([1, 2, undef]) }
	qr/\Qkurtosis: undefined value at array ref index 2 (argument 0)\E/,
	'kurtosis: names the element and argument of an undef inside an array ref';
throws_ok { skew(\@w, type => 0) } qr/\Qskew: type must be 1, 2 or 3, not 0\E/,
	'skew: rejects type 0';
throws_ok { skew(\@w, type => 4) } qr/\Qskew: type must be 1, 2 or 3, not 4\E/,
	'skew: rejects type 4';
throws_ok { skew(\@w, type => 'g1') } qr/\Qskew: type must be 1, 2 or 3\E/,
	'skew: rejects a non-numeric type';
throws_ok { skew(\@w, 'type') } qr/\Qskew: 'type' needs a value\E/,
	'skew: reports a trailing option name with no value';
throws_ok { skew(\@w, 'x') } qr/\Qskew: 'x' needs a value\E/,
	'skew: reports a trailing x with no value';
throws_ok { skew(x => 5) } qr/\Qskew: 'x' must be an array reference\E/,
	"skew: 'x' has to be an array ref";
throws_ok { kurtosis(\@w, types => 2) } qr/\Qkurtosis: unknown argument 'types'\E/,
	'kurtosis: a misspelled option is an error, not silently averaged in';

# --- leaks, on the data paths and the croak paths
unless ($INC{'Devel/Cover.pm'}) {
	my $big = [ map { $_ * 1.5 } 1 .. 2000 ];
	no_leaks_ok { eval { my $s = skew(\@w) } }                 'skew no leaks: array ref';
	no_leaks_ok { eval { my $s = skew(@w) } }                  'skew no leaks: bare list';
	no_leaks_ok { eval { my $s = skew(x => $big, type => 1) } }'skew no leaks: named args';
	no_leaks_ok { eval { my $s = skew(1, undef) } }            'skew no leaks: croak path';
	no_leaks_ok { eval { my $s = skew([7, 7, 7]) } }           'skew no leaks: zero-variance croak';
	no_leaks_ok { eval { my $k = kurtosis(\@w) } }             'kurtosis no leaks: array ref';
	no_leaks_ok { eval { my $k = kurtosis($big, type => 3) } } 'kurtosis no leaks: named args';
	no_leaks_ok { eval { my $k = kurtosis(\@w, bad => 1) } }   'kurtosis no leaks: unknown-argument croak';
}

done_testing();
