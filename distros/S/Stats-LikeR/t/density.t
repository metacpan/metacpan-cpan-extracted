#!/usr/bin/env perl
#
# The Perl-side surface of density() and the five bw_* bandwidth selectors:
# every accepted call form, every returned field, every croak message, every
# warning, and the structural invariants R's documentation promises.  The
# numbers are in t/density.R.scipy.t, which pins them against R's own test
# suite and documented examples; this file is about the interface.
#
require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Stats::LikeR qw(density bw_nrd0 bw_nrd bw_ucv bw_bcv bw_sj);

# Test::LeakTrace is optional; without it the leak checks become skips.
my $HAVE_LEAKTRACE;
BEGIN {
	$HAVE_LEAKTRACE = eval { require Test::LeakTrace; Test::LeakTrace->import('no_leaks_ok'); 1 };
	unless ($HAVE_LEAKTRACE) {
		no strict 'refs';
		*no_leaks_ok = sub (&;$) { SKIP: { skip 'Test::LeakTrace not installed', 1 } };
	}
}

my $INF = 9**9**9;
my $NAN = $INF - $INF;

# A sample with a bit of everything: distinct values, no ties, easy IQR.
my @X = map { $_ / 8 } (-17, -11, -6, -3, -1, 0, 2, 3, 5, 9, 14, 21);

# Warnings are part of the contract here, so collect rather than print them.
my @W;
$SIG{__WARN__} = sub { push @W, $_[0] };
sub took { my @w = @W; @W = (); return @w }
sub warned_like {
	my ($re, $name) = @_;
	my @w = took();
	ok(scalar(grep { $_ =~ $re } @w), $name) or diag("warnings were: @w");
}
sub no_warning { my ($name) = @_; my @w = took(); is(scalar @w, 0, $name) or diag("warnings were: @w") }

# ------------------------------------------------------------ call forms

{
	my $a = density(\@X);
	my $b = density(x => \@X);
	is_deeply($a->{y}, $b->{y}, 'positional and named x agree');
	no_warning('plain call warns about nothing');

	my $c = density(\@X, kernel => 'epanechnikov', adjust => 2);
	my $d = density(x => \@X, adjust => 2, kernel => 'epanechnikov');
	is_deeply($c->{y}, $d->{y}, 'named arguments are order-independent');
	isnt("$c->{y}[256]", "$a->{y}[256]", 'kernel and adjust change the estimate');
}

# --------------------------------------------------------- returned fields

{
	my $d = density(\@X);
	is(ref $d, 'HASH', 'returns a hash reference');
	is_deeply([sort keys %$d],
	          [sort qw(x y bw n kernel old_coords has_na)],
	          'returns exactly the documented fields');
	is(ref $d->{x}, 'ARRAY', 'x is an array reference');
	is(ref $d->{y}, 'ARRAY', 'y is an array reference');
	is(scalar @{ $d->{x} }, 512, 'x has n = 512 points by default');
	is(scalar @{ $d->{y} }, 512, 'y has n = 512 points by default');
	is($d->{n}, scalar @X, 'n is the sample size');
	is($d->{kernel}, 'gaussian', 'kernel defaults to gaussian');
	is($d->{old_coords}, 0, 'old_coords is off by default');
	is($d->{has_na}, 0, 'has_na is always 0');
	cmp_ok($d->{bw}, '>', 0, 'bw is positive');

	# The grid is seq(from, to, length.out = n), from = min(x) - 3*bw.
	my $from = -17 / 8 - 3 * $d->{bw};
	my $to   =  21 / 8 + 3 * $d->{bw};
	cmp_ok(abs($d->{x}[0] - $from), '<', 1e-13, 'x starts at min(x) - cut*bw');
	cmp_ok(abs($d->{x}[511] - $to), '<', 1e-13, 'x ends at max(x) + cut*bw');
	my $mono = 1;
	for my $i (1 .. 511) { $mono = 0 if $d->{x}[$i] <= $d->{x}[$i - 1] }
	ok($mono, 'x is strictly increasing');
	is(scalar(grep { $_ < 0 } @{ $d->{y} }), 0, 'y is never negative');

	# A density integrates to 1 over a grid that runs 3 bandwidths past the
	# data on each side; the trapezoid rule gets within a fraction of a percent.
	my $h = $d->{x}[1] - $d->{x}[0];
	my $area = 0;
	$area += ($d->{y}[$_] + $d->{y}[$_ - 1]) / 2 * $h for 1 .. 511;
	cmp_ok(abs($area - 1), '<', 0.005, 'y integrates to about 1');
	no_warning('none of that warned');
}

# -------------------------------------------------------------- n handling

{
	for my $n (1, 2, 3, 17, 511, 512, 513, 1000, 1024) {
		my $d = density(\@X, n => $n);
		is(scalar @{ $d->{y} }, $n, "n => $n gives $n output points");
	}
	# n is rounded up to a power of two internally, but the output is
	# interpolated back to exactly the n asked for.
	my $a = density(\@X, n => 513);
	my $b = density(\@X, n => 1024);
	is(scalar @{ $a->{y} }, 513, 'n => 513 still returns 513 points');
	cmp_ok(abs($a->{y}[0] - $b->{y}[0]), '<', 1e-12,
	       'n => 513 and n => 1024 share the first grid point');
	no_warning('n handling warns about nothing');
}

# ---------------------------------------------------- kernels and windows

my @KERNELS = qw(gaussian epanechnikov rectangular triangular biweight
                 cosine optcosine);
for my $k (@KERNELS) {
	my $d = density(\@X, kernel => $k);
	is($d->{kernel}, $k, "kernel => '$k' is echoed back");
	is(scalar(grep { $_ < 0 } @{ $d->{y} }), 0, "kernel '$k' gives no negative y");
}
{
	# Abbreviations, as match.arg() accepts them, and case-insensitively.
	is(density(\@X, kernel => 'e')->{kernel}, 'epanechnikov', 'kernel => "e"');
	is(density(\@X, kernel => 'BIW')->{kernel}, 'biweight', 'kernel => "BIW"');
	is(density(\@X, kernel => 'Optcosine')->{kernel}, 'optcosine', 'kernel is case-insensitive');
	# window is an alias for kernel, and loses to an explicit kernel.
	is(density(\@X, window => 'cosine')->{kernel}, 'cosine', 'window sets the kernel');
	is(density(\@X, window => 'cosine', kernel => 'biweight')->{kernel}, 'biweight',
	   'an explicit kernel beats window');
	no_warning('kernel selection warns about nothing');
}

# ------------------------------------------------------------ bandwidth

{
	my $d = density(\@X);
	cmp_ok(abs($d->{bw} - bw_nrd0(\@X)), '<', 1e-15, 'bw defaults to bw_nrd0');

	for my $rule (qw(nrd0 nrd NRD0 SJ sj sj-ste SJ-DPI ucv bcv)) {
		my $r = density(\@X, bw => $rule);
		took();
		cmp_ok($r->{bw}, '>', 0, "bw => '$rule' produces a bandwidth");
	}

	# adjust multiplies whatever bw resolved to.
	my $h = density(\@X, adjust => 0.5);
	cmp_ok(abs($h->{bw} - $d->{bw} / 2), '<', 1e-15, 'adjust scales bw');

	# A numeric bw is taken as given.
	is(density(\@X, bw => 0.25)->{bw}, 0.25, 'a numeric bw is used as is');
	is(density(\@X, bw => 0.25, adjust => 4)->{bw}, 1, 'adjust scales a numeric bw');

	# S's `width` is the support length, so gaussian width = 4*bw ...
	is(density(\@X, width => 2)->{bw}, 0.5, 'width => 2 is bw = 0.5 for the gaussian');
	# ... and a character width names a rule, exactly as bw does.
	cmp_ok(abs(density(\@X, width => 'nrd')->{bw} - bw_nrd(\@X)), '<', 1e-15,
	       'a character width names a bandwidth rule');
	# width is only consulted when bw is silent.
	is(density(\@X, bw => 0.25, width => 2)->{bw}, 0.25, 'bw wins over width');
	no_warning('bandwidth selection warns about nothing here');
}

# ----------------------------------------------------------- from/to/cut/ext

{
	my $d = density(\@X, from => -5, to => 5);
	is($d->{x}[0], -5, 'from is honoured exactly');
	is($d->{x}[511], 5, 'to is honoured exactly');

	my $c0 = density(\@X, cut => 0);
	cmp_ok(abs($c0->{x}[0] + 17 / 8), '<', 1e-15, 'cut => 0 starts at min(x)');
	cmp_ok(abs($c0->{x}[511] - 21 / 8), '<', 1e-15, 'cut => 0 ends at max(x)');

	# ext only widens the FFT grid, so it moves the estimate a little without
	# moving the output grid at all.
	my $e1 = density(\@X, ext => 1);
	my $e4 = density(\@X);
	is_deeply($e1->{x}, $e4->{x}, 'ext does not move the output grid');
	no_warning('grid arguments warn about nothing');
}

# ------------------------------------------------------ give_rkern

{
	my $r = density(kernel => 'gaussian', give_rkern => 1);
	ok(!ref $r, 'give_rkern returns a plain number, not a reference');
	cmp_ok(abs($r - 1 / (2 * sqrt(4 * atan2(1, 1)))), '<', 1e-15,
	       'give_rkern gaussian is 1/(2*sqrt(pi))');
	# and the dotted spelling R uses
	is(density(kernel => 'gaussian', 'give.Rkern' => 1), $r, 'give.Rkern is accepted too');
	# no x is needed, and any x is ignored
	is(density([1, 2, 3], kernel => 'gaussian', give_rkern => 1), $r, 'give_rkern ignores x');
	no_warning('give_rkern warns about nothing');
}

# ----------------------------------------------------- infinite observations

{
	# An infinite observation is a point mass off the grid: n counts it, but
	# it takes its share of the mass with it, leaving a sub-density.
	my $d = density([@X, $INF], bw => 0.5);
	is($d->{n}, scalar(@X) + 1, 'n counts an infinite observation');
	my $p = density(\@X, bw => 0.5);
	my $ratio = $d->{y}[256] / $p->{y}[256];
	cmp_ok(abs($ratio - 12 / 13), '<', 1e-9,
	       'an infinite observation removes its share of the mass');
	no_warning('an infinite observation warns about nothing');
}

# --------------------------------------------------------------- NA handling

{
	for my $bad (undef, $NAN) {
		my @x = (@X, $bad);
		ok(!defined eval { density(\@x); 1 }, 'a missing value is an error by default');
		like($@, qr/'x' contains missing values/, '... with R\'s message');
		my $d = density(\@x, na_rm => 1);
		is($d->{n}, scalar @X, 'na_rm drops it and reports the reduced n');
		is_deeply($d->{y}, density(\@X)->{y}, 'na_rm gives the same estimate');
	}
	# the dotted spelling
	my $d = density([@X, undef], 'na.rm' => 1);
	is($d->{n}, scalar @X, 'na.rm is accepted too');
	no_warning('NA handling warns about nothing');
}

# ------------------------------------------------------------------ weights

{
	my $n = scalar @X;
	my @flat = map { 1 / $n } 1 .. $n;
	my $d = density(\@X, weights => \@flat, bw => 0.5);
	no_warning('uniform weights summing to one do not warn');
	my $p = density(\@X, bw => 0.5);
	my $bad = 0;
	for my $i (0 .. 511) { $bad++ if abs($d->{y}[$i] - $p->{y}[$i]) > 1e-13 }
	is($bad, 0, 'uniform weights reproduce the unweighted estimate');

	# Weights that do not sum to one warn, unless a sub-density was asked for.
	density(\@X, weights => [map { 1 / (2 * $n) } 1 .. $n], bw => 0.5);
	warned_like(qr/sum\(weights\) != 1/, 'weights not summing to one warn');
	density(\@X, weights => [map { 1 / (2 * $n) } 1 .. $n], bw => 0.5, subdensity => 1);
	no_warning('subdensity => 1 silences that warning');

	# An automatic bandwidth ignores the weights, and says so -- unless the
	# weights do not vary, or warn_wbw says not to.
	density(\@X, weights => [map { $_ / 78 } 1 .. $n]);
	warned_like(qr{using 'weights'}, 'a varying weight vector warns about bw selection');
	density(\@X, weights => \@flat);
	no_warning('a constant weight vector does not');
	density(\@X, weights => [map { $_ / 78 } 1 .. $n], warn_wbw => 0);
	no_warning('warn_wbw => 0 silences it');
	density(\@X, weights => \@flat, warnWbw => 1);
	warned_like(qr{using 'weights'}, 'warnWbw => 1 forces it');

	# Doubling one observation's weight is the same as duplicating it.
	my @w = (map { 1 / ($n + 1) } 1 .. $n);
	$w[0] *= 2;
	my $wd = density(\@X, weights => \@w, bw => 0.5);
	my $dd = density([$X[0], @X], bw => 0.5, from => $wd->{x}[0], to => $wd->{x}[511]);
	took();
	my $off = 0;
	for my $i (0 .. 511) { $off = abs($wd->{y}[$i] - $dd->{y}[$i]) if abs($wd->{y}[$i] - $dd->{y}[$i]) > $off }
	cmp_ok($off, '<', 1e-13, 'a doubled weight equals a duplicated observation');
}

# ------------------------------------------------------------- old_coords

{
	my $new = density(\@X);
	my $old = density(\@X, old_coords => 1);
	is($old->{old_coords}, 1, 'old_coords is echoed back');
	is_deeply($new->{x}, $old->{x}, 'old_coords does not move the grid');
	# pre-4.4.0 values are larger by about 1 + 1/(2n-2)
	my $r = $old->{y}[256] / $new->{y}[256];
	cmp_ok($r, '>', 1, 'old_coords gives larger values');
	cmp_ok(abs($r - (1 + 1 / (2 * 512 - 2))), '<', 5e-3,
	       'old_coords is larger by about 1 + 1/(2n-2)');
	is(density(\@X, 'old.coords' => 1)->{old_coords}, 1, 'old.coords is accepted too');
	no_warning('old_coords warns about nothing');
}

# --------------------------------------------------------- the bw_* functions

{
	for my $fn (\&bw_nrd0, \&bw_nrd, \&bw_ucv, \&bw_bcv, \&bw_sj) {
		my $v = $fn->(\@X);
		took();
		ok(!ref $v, 'a bandwidth selector returns a plain number');
		cmp_ok($v, '>', 0, '... and a positive one');
		my $named = $fn->(x => \@X);
		took();
		cmp_ok(abs($named - $v), '<', 1e-15, '... from either call form');
	}
	# bw_sj's two methods, and the fact that density(bw => 'sj') is the "ste" one
	my $ste = bw_sj(\@X, method => 'ste');
	my $dpi = bw_sj(\@X, method => 'dpi');
	cmp_ok(abs($ste - bw_sj(\@X)), '<', 1e-15, "bw_sj defaults to method => 'ste'");
	cmp_ok(abs($dpi - $ste), '>', 0, 'ste and dpi differ');
	cmp_ok(abs(density(\@X, bw => 'sj')->{bw} - $ste), '<', 1e-15, "bw => 'sj' is ste");
	cmp_ok(abs(density(\@X, bw => 'sj-dpi')->{bw} - $dpi), '<', 1e-15, "bw => 'sj-dpi' is dpi");
	# nb, lower, upper and tol are accepted by the three that search
	for my $fn (\&bw_ucv, \&bw_bcv, \&bw_sj) {
		ok($fn->(\@X, nb => 64) > 0, 'nb is accepted');
		ok($fn->(\@X, lower => 0.05, upper => 3) > 0, 'lower/upper are accepted');
		ok($fn->(\@X, tol => 1e-9) > 0, 'tol is accepted');
		took();
	}
	# bw.nrd0's documented fallback chain: zero IQR falls back to sd, zero sd
	# to |x[1]|, and a first element of zero to 1.
	my @iqr0 = (-20, (0) x 98, 20);
	cmp_ok(bw_nrd0(\@iqr0), '>', 0, 'bw_nrd0 survives a zero IQR');
	my @flat = (3) x 10;
	cmp_ok(abs(bw_nrd0(\@flat) - 0.9 * 3 * 10 ** -0.2), '<', 1e-15,
	       'a constant sample falls back to abs(x[1])');
	my @zero = (0) x 10;
	cmp_ok(abs(bw_nrd0(\@zero) - 0.9 * 10 ** -0.2), '<', 1e-15,
	       'an all-zero sample falls back to 1');
	took();
}

# ------------------------------------------------------------ croak paths

{
	my @bad = (
		[ sub { density() },                       qr/'x' is required/,          'no x' ],
		[ sub { density(42) },                     qr/'x' is required/,          'x is not a reference' ],
		[ sub { density({}) },                     qr/'x' is required/,          'x is a hash reference' ],
		[ sub { density(\@X, 'kernel') },          qr/key => value pairs/,       'odd trailing argument' ],
		[ sub { density(\@X, nope => 1) },         qr/unknown argument 'nope'/,  'unknown argument' ],
		[ sub { density(\@X, kernel => 'nope') },  qr/kernel.*should be one of/, 'unknown kernel' ],
		[ sub { density(\@X, window => 'nope') },  qr/window.*should be one of/, 'unknown window' ],
		[ sub { density(\@X, bw => 'nope') },      qr/unknown bandwidth rule/,   'unknown bandwidth rule' ],
		[ sub { density(\@X, width => 'nope') },   qr/unknown bandwidth rule/,   'unknown width rule' ],
		[ sub { density(\@X, bw => 0) },           qr/'bw' is not positive/,     'zero bandwidth' ],
		[ sub { density(\@X, bw => -1) },          qr/'bw' is not positive/,     'negative bandwidth' ],
		[ sub { density(\@X, bw => $INF) },        qr/non-finite 'bw'/,          'infinite bandwidth' ],
		[ sub { density(\@X, adjust => 0) },       qr/'bw' is not positive/,     'zero adjust' ],
		[ sub { density(\@X, bw => 1, from => $INF) }, qr/non-finite 'from'/,    'infinite from' ],
		[ sub { density(\@X, bw => 1, to => $NAN) },   qr/non-finite 'to'/,      'NaN to' ],
		[ sub { density(['x'], bw => 1) },         qr/'x' must be numeric/,      'non-numeric x' ],
		[ sub { density([1], bw => 'nrd0') },      qr/at least 2 points/,        'one point, automatic bw' ],
		[ sub { density(\@X, n => 0) },            qr/'n' must be at least 1/,   'n = 0' ],
		[ sub { density(\@X, n => -1) },           qr/'n' must be at least 1/,   'n < 0' ],
		[ sub { density(\@X, n => 1 << 27) },      qr/'n' is too large/,         'n absurdly large' ],
		[ sub { density(\@X, nb => 0) },           qr/invalid 'nb'/,             'nb = 0' ],
		[ sub { density(\@X, weights => 42) },     qr/'weights' must be an array reference/, 'weights not a reference' ],
		[ sub { density(\@X, weights => [1, 2]) }, qr/unequal length/,           'weights of the wrong length' ],
		[ sub { density(\@X, weights => [(1 / 12) x 11, -1]) }, qr/must not be negative/, 'a negative weight' ],
		[ sub { density(\@X, weights => [(1 / 12) x 11, $INF]) }, qr/must all be finite/, 'an infinite weight' ],
		[ sub { density(\@X, weights => [(1 / 12) x 11, undef]) }, qr/must all be finite/, 'a missing weight' ],
		[ sub { bw_nrd0(42) },                     qr/must be an array reference/, 'bw_nrd0 without a reference' ],
		[ sub { bw_nrd0([1]) },                    qr/at least 2 data points/,   'bw_nrd0 on one point' ],
		[ sub { bw_nrd([1, undef]) },              qr/must be numeric/,          'bw_nrd on a missing value' ],
		[ sub { bw_ucv([1, 'x']) },                qr/must be numeric/,          'bw_ucv on a string' ],
		[ sub { bw_sj([1, 1, 1, 1]) },             qr/data are constant/,        'bw_sj on a constant sample' ],
		[ sub { bw_sj(\@X, method => 'nope') },    qr/'method' must be/,         'bw_sj with a bad method' ],
		# R only widens bw.SJ's search interval when it chose both ends itself;
		# a bracket the caller pinned that holds no root is an error.
		[ sub { bw_sj(\@X, lower => 10, upper => 20) },
		  qr/no solution in the specified range of bandwidths/, 'bw_sj with a bracket holding no root' ],
		[ sub { bw_sj(\@X, nope => 1) },           qr/unknown argument 'nope'/,  'bw_sj with an unknown argument' ],
		[ sub { bw_ucv(\@X, nb => 0) },            qr/invalid 'nb'/,             'bw_ucv with nb = 0' ],
	);
	for my $b (@bad) {
		my ($code, $re, $what) = @$b;
		ok(!defined eval { $code->(); 1 }, "croaks: $what");
		like($@, $re, "... with the right message: $what");
	}
	took();
}

# Every message names the function it came from, so a croak in a pipeline is
# traceable.
{
	ok(!defined eval { density(\@X, bw => 'nope'); 1 }, 'density croak');
	like($@, qr/^density: /, 'density croaks with its own name');
	ok(!defined eval { bw_sj([1]); 1 }, 'bw_sj croak');
	like($@, qr/^bw_sj: /, 'bw_sj croaks with its own name');
	took();
}

# ---------------------------------------------------------------- no leaks

SKIP: {
	skip 'leak checks are unreliable under Devel::Cover', 6 if $INC{'Devel/Cover.pm'};
	no_leaks_ok { density(\@X, n => 512) } 'no leaks: a plain density';
	no_leaks_ok { density(\@X, weights => [map { 1 / 12 } 1 .. 12], bw => 0.5) }
		'no leaks: a weighted density';
	no_leaks_ok { density([@X, undef, $INF], na_rm => 1, bw => 0.5) }
		'no leaks: NA and Inf removal';
	no_leaks_ok { density(\@X, bw => 'SJ') } 'no leaks: an automatic bandwidth';
	no_leaks_ok { eval { density(\@X, bw => 'nope') } } 'no leaks: the croak path';
	no_leaks_ok { eval { density(\@X, weights => [1, 2]) } }
		'no leaks: the croak path after allocation';
	took();
}

is(scalar @W, 0, 'nothing warned unexpectedly') or diag("warnings: @W");

done_testing();
