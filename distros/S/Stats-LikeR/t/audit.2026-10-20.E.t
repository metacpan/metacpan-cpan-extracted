#!/usr/bin/env perl
# Regressions for oneway_test(), shapiro_test() and ks_test() from the
# 2026-10-20 audit, all fixed in 0.331.  Each block names what used to happen.
# ks_test()'s and the tie-conditional p-values' cross-validation against R
# lives in t/ks_test.R.scipy.t; this file holds the reading, croak and leak
# cases.
#
# Provenance of every expected number below that is not structural: R 4.6.1
# (2026-06-24) at options(digits = 17), from t/audit.2026-10-20.E.R, which is
# committed next to this file (re-run it with `Rscript
# t/audit.2026-10-20.E.R`).  It calls oneway.test(y ~ g, data.frame(...),
# var.equal = ...) for the oneway rows and shapiro.test() for the tied-array
# row; R's own NA handling (model.frame()'s na.omit) is what drops the NaN
# rows, NaN being NA to R.
#
# Tolerances, both relative.  Against those R values every statistic and df
# is within 2.5e-15 on perl-5.44.0 (double), and every p-value but one within
# 7.1e-14 (big.welch's, of 1.7e-6); $TOL = 1e-11 leaves 140 times that for the
# long-double and quadmath builds.  The one is big.pooled's p of 3.2e-123, 7.1e-13 from R: an
# F tail that deep is where the incomplete beta loses its last digits, and
# README's oneway_test accuracy section records 8e-11 against R at p = 2.4e-66
# over its randomised comparisons.  It gets $TOL_TAIL = 1e-9, 12 times that.
#
# The RSS checks catch what Test::LeakTrace cannot: it counts SVs, and the
# buffers these functions leaked were plain C allocations.  Linux only,
# because they read /proc/self/statm.  Before the fix, 2000 failing
# shapiro_test() calls on 5000 values grew RSS by 2000 * 5000 * 8 bytes = 80
# MB, and 1000 ks_test() calls on 2 x 3200 values whose $SIG{__WARN__} dies by
# 1000 * 6400 * 8 bytes = 51 MB; after it both grow by under 0.1 MB.  The limit
# of 20 MB sits a factor of 2.5 under the smaller leak and 200 over the noise.
require 5.010;
use strict;
use warnings FATAL => 'all';
use utf8;
use Test::More;
use Tie::Array;
use Tie::Hash;
use Stats::LikeR qw(ks_test oneway_test shapiro_test);

# Imported at compile time, because no_leaks_ok's block form needs its
# prototype visible when the file is parsed. Same shape as t/croak.leaks.t.
BEGIN {
	if (eval { require Test::LeakTrace; 1 }) {
		Test::LeakTrace->import('no_leaks_ok');
	} else {
		no strict 'refs';
		*{'main::no_leaks_ok'} = sub (&;$) { SKIP: { skip 'Test::LeakTrace not installed', 1 } };
	}
}

my $TOL = 1e-11;	# see the header
my $TOL_TAIL = 1e-9;	# see the header: big.pooled's p only
my $NAN = 9**9**9 / 9**9**9;
sub near {
	my ($got, $want, $name, $tol) = @_;
	$tol = $TOL unless defined $tol;
	my $err = $want == 0 ? abs($got) : abs($got - $want) / abs($want);
	ok($err <= $tol, $name) or diag(sprintf('got %.17g want %.17g (rel %.3g)', $got, $want, $err));
}
sub dies_like {
	my ($code, $re, $name) = @_;
	my $ok = eval { $code->(); 1 };
	ok(!$ok, "$name: dies") or return;
	like($@, $re, "$name: message");
}
# One R row: statistic, num df, denom df, p.
sub ow_ok {
	my ($r, $fac, $want, $name, $p_tol) = @_;
	near($r->{$fac}{'F value'},   $want->[0], "$name: F");
	near($r->{$fac}{Df},          $want->[1], "$name: num df");
	near($r->{Residuals}{Df},     $want->[2], "$name: denom df");
	near($r->{$fac}{'Pr(>F)'},    $want->[3], "$name: p", $p_tol);
}
my %R = (
	'ab.welch'   => [9.9999999999999964, 1, 3.4482758620689666, 0.041914517471454034],
	'ab.pooled'  => [9.9999999999999982, 1, 4, 0.034109423167409635],
	'nan.welch'  => [16.899999999999999, 1, 3.4482758620689666, 0.019855117523634842],
	'nan.pooled' => [16.899999999999995, 1, 4, 0.014720593813730028],
	'gone.welch' => [22.729729729729723, 1, 2.8942917547568712, 0.019006354089900746],
	'big.welch'  => [1.5097933783612845, 1099, 367.33393302385508, 1.6898032164419457e-06],
	'big.pooled' => [4.4060254962084784, 1099, 1100, 3.1901022860071894e-123],
);

# ---- oneway_test: arguments ----
{
	my %ab = (a => [1, 2, 3], b => [4, 5, 7]);
	# README promises the dotted var.equal is refused; up to 0.33 it was
	# skipped, so var.equal => 1 ran Welch's test and reported F = 10, p = 0.0419.
	dies_like(sub { oneway_test(\%ab, 'var.equal' => 1) }, qr/oneway_test: error: unknown argument 'var\.equal'/,
		"oneway_test: R's dotted var.equal");
	dies_like(sub { oneway_test(\%ab, equal_var => 1) }, qr/unknown argument 'equal_var'/,
		'oneway_test: any other unknown key');
	dies_like(sub { oneway_test(\%ab, 'var_equal') }, qr/name => value pairs/,
		'oneway_test: a key with no value');
	ow_ok(oneway_test(\%ab), 'Group', $R{'ab.welch'}, 'oneway_test: Welch by default');
	ow_ok(oneway_test(\%ab, var_equal => 1), 'Group', $R{'ab.pooled'}, 'oneway_test: var_equal => 1 is the pooled F');
}

# ---- oneway_test: UTF-8 group names keep their flag ----
{
	# Up to 0.33 the keys of group_stats came back as their UTF-8 bytes, so
	# "α" was the two-character "\xce\xb1", and a formula naming a UTF-8
	# column croaked that it was not in the hash.
	my $r = oneway_test({ 'α' => [1, 2, 3], 'β' => [4, 5, 7] });
	is_deeply([sort keys %{ $r->{group_stats}{mean} }], ['α', 'β'], 'oneway_test hash: UTF-8 group names');
	is($r->{group_stats}{size}{'β'}, 3, 'oneway_test hash: and the sizes are keyed by them');
	my $f = oneway_test({ y => [1, 2, 3, 4, 5, 7], 'γ' => [qw(α α α β β β)] }, formula => 'y ~ γ');
	ok(exists $f->{'γ'}, 'oneway_test formula: a UTF-8 factor column is found and names the row');
	is_deeply([sort keys %{ $f->{group_stats}{mean} }], ['α', 'β'], 'oneway_test formula: UTF-8 labels');
	ow_ok($f, 'γ', $R{'ab.welch'}, 'oneway_test formula: UTF-8 names, same answer');
	# A label and its UTF-8-upgraded copy are the same string to perl.
	my $e = "\x{e9}";
	my $eu = $e; utf8::upgrade($eu);
	my $m = oneway_test({ y => [1, 2, 3, 4, 5, 7], g => [$e, $eu, $e, 'n', 'n', 'n'] }, formula => 'y ~ g');
	is($m->{group_stats}{size}{$e}, 3, 'oneway_test formula: byte and UTF-8 spellings of one label are one group');
}

# ---- oneway_test: NaN is dropped, as R drops NA ----
{
	# Up to 0.33 a NaN cell was kept and every statistic came back NaN.
	ow_ok(oneway_test({ a => [1, 2, 3], b => [$NAN, 5, 6, 8] }), 'Group', $R{'nan.welch'}, 'oneway_test hash: NaN dropped');
	ow_ok(oneway_test([[1, 2, 3], [5, 'NaN', 6, 8]], var_equal => 1), 'Group', $R{'nan.pooled'}, 'oneway_test AoA: NaN dropped');
	my $f = oneway_test({ y => [1, 2, 3, $NAN, 5, 6, 8], g => [qw(a a a b b b b)] }, formula => 'y ~ g');
	ow_ok($f, 'g', $R{'nan.welch'}, 'oneway_test formula: NaN row dropped');
	is($f->{group_stats}{size}{b}, 3, 'oneway_test formula: the size counts what was used');
	my $gone = oneway_test({ y => [1, 2, $NAN, $NAN, 5, 6, 8], g => [qw(a a b b c c c)] }, formula => 'y ~ g');
	ow_ok($gone, 'g', $R{'gone.welch'}, 'oneway_test formula: an all-NaN group is gone, as an unused level');
	ok(!exists $gone->{group_stats}{size}{b}, 'oneway_test formula: and is not reported');
	dies_like(sub { oneway_test({ a => [1, $NAN, 3], b => [$NAN, 4] }) }, qr/group 'b' has fewer than 2 observations/,
		'oneway_test hash: a group NaN leaves with one value');
	dies_like(sub { oneway_test({ a => [1, undef, 3], b => [3, 4] }) }, qr/undefined or non-numeric/,
		'oneway_test hash: undef still croaks, as documented');
}

# ---- oneway_test: more than 1024 formula groups ----
{
	# Up to 0.33 the 1025th distinct label croaked "too many distinct groups
	# (max 1024)", leaking the 1024 label strings already copied.  R has no
	# limit.
	my (@y, @g);
	for my $i (0 .. 2199) {
		my $g = int($i / 2);
		push @g, $g;
		push @y, (($i * 7) % 13) / 4 + 2 * ($g % 3);
	}
	my %d = (y => \@y, g => \@g);
	ow_ok(oneway_test(\%d, formula => 'y ~ g'), 'g', $R{'big.welch'}, 'oneway_test formula: 1100 groups');
	ow_ok(oneway_test(\%d, formula => 'y ~ g', var_equal => 1), 'g', $R{'big.pooled'}, 'oneway_test formula: 1100 groups, pooled', $TOL_TAIL);
	my %short = (y => [@y, 1], g => [@g, 'lone']);
	dies_like(sub { oneway_test(\%short, formula => 'y ~ g') }, qr/group 'lone' has only 1 observation/,
		'oneway_test formula: a one-row group among 1101');
	unless ($INC{'Devel/Cover.pm'}) {
		no_leaks_ok { oneway_test(\%d, formula => 'y ~ g') } 'oneway_test formula: 1100 groups, no SV leak';
		no_leaks_ok { eval { oneway_test(\%short, formula => 'y ~ g') } } 'oneway_test formula: the croak, no SV leak';
		no_leaks_ok { eval { oneway_test({ a => [1, 2], b => [3, 'x'] }) } } 'oneway_test hash: a bad cell, no SV leak';
		no_leaks_ok { eval { oneway_test({ 'α' => [1, 2, 3], 'β' => [4, 5, 7] }) } } 'oneway_test hash: UTF-8 names, no SV leak';
	}
}

# ---- shapiro_test ----
{
	my @v = (2.1, 3.4, 1.2, 5.5, 4.4, 0.3, 2.2);
	tie my @t, 'Tie::StdArray';
	@t = @v;
	# Up to 0.33 SvOK() ran before the FETCH, so every element was missing and
	# a tied array croaked "Sample size must be between 3 and 5000".
	my $r = shapiro_test(\@t);
	near($r->{W},       0.97311087818296915, 'shapiro_test: a tied array is read (W)');
	near($r->{p_value}, 0.9199121689970492,  'shapiro_test: a tied array is read (p)');
	# R: shapiro.test(c("a", ...)) stops with "is.numeric(x) is not TRUE";
	# up to 0.33 the string was read as 0.
	dies_like(sub { shapiro_test([1, 2, 'abc', 4, 5.5]) }, qr/^shapiro_test: x at index 2 is not a number/,
		'shapiro_test: a non-numeric string');
	near(shapiro_test([undef, @v, 'NaN'])->{W}, 0.97311087818296915, 'shapiro_test: undef and NaN still dropped');
	unless ($INC{'Devel/Cover.pm'}) {
		no_leaks_ok { shapiro_test(\@t) } 'shapiro_test: tied, no SV leak';
		no_leaks_ok { eval { shapiro_test([1, 2, 'abc', 4]) } } 'shapiro_test: the croak, no SV leak';
	}
}

# ---- ks_test ----
{
	my @x = (0.61, -1.2, 0.33, 1.9, -0.4, 0.05, 2.2, -0.9);
	my @y = (1.4, 2.6, 0.8, 3.1, 1.7, 2.2, 0.2);
	tie my @tx, 'Tie::StdArray';
	tie my @ty, 'Tie::StdArray';
	@tx = @x;
	@ty = @y;
	# Up to 0.33 a tied x read as all missing ("Not enough non-missing 'x'
	# observations"), and a tied y likewise.
	is_deeply(ks_test(\@tx, \@ty), ks_test(\@x, \@y), 'ks_test: tied x and y read as plain ones (two-sample)');
	is_deeply(ks_test(\@tx, 'pnorm'), ks_test(\@x, 'pnorm'), 'ks_test: tied x read as a plain one (one-sample)');
	unless ($INC{'Devel/Cover.pm'}) {
		no_leaks_ok { ks_test(\@tx, \@ty) } 'ks_test: tied, no SV leak';
		no_leaks_ok {
			local $SIG{__WARN__} = sub { die "warning refused\n" };
			eval { ks_test([1, 2, 2, 3], [2, 3, 3, 4], exact => 0) };
		} 'ks_test: a dying __WARN__ handler, no SV leak';
	}
	my $err;
	{
		local $SIG{__WARN__} = sub { die "warning refused\n" };
		eval { ks_test([1, 2, 2, 3], [2, 3, 3, 4], exact => 0) };
		$err = $@;
	}
	is($err, "warning refused\n", 'ks_test: the ties warning reaches $SIG{__WARN__}');
}

# ---- the C buffers: RSS over many failing calls (see the header) ----
SKIP: {
	skip 'reads /proc/self/statm (Linux)', 2 unless $^O eq 'linux' && -r '/proc/self/statm';
	skip 'Devel::Cover slows this past usefulness', 2 if $INC{'Devel/Cover.pm'};
	require POSIX;
	my $page = POSIX::sysconf(POSIX::_SC_PAGESIZE()) || 4096;
	my $rss = sub {
		open my $fh, '<', '/proc/self/statm' or return 0;
		my (undef, $res) = split ' ', scalar <$fh>;
		return $res * $page;
	};
	my @bad = ((map { $_ / 7 } 1 .. 4999), 'abc');
	eval { shapiro_test(\@bad) } for 1 .. 50;	# warm the allocator
	my $before = $rss->();
	eval { shapiro_test(\@bad) } for 1 .. 2000;
	my $grew = $rss->() - $before;
	cmp_ok($grew, '<', 20e6, sprintf('shapiro_test: 2000 croaks on 5000 values grow RSS by %.1f MB', $grew / 1e6));

	# 3200 x 3200 is past KS_EXACT_MAX_PRODUCT, so a forced exact run warns
	# once both buffers are filled
	my @kx = map { $_ * 1.0 } 1 .. 3200;
	my @ky = map { $_ + 0.5 } 1 .. 3200;
	my $call = sub {
		local $SIG{__WARN__} = sub { die "warning refused\n" };
		eval { ks_test(\@kx, \@ky, exact => 1) };
	};
	$call->() for 1 .. 50;
	$before = $rss->();
	$call->() for 1 .. 1000;
	$grew = $rss->() - $before;
	cmp_ok($grew, '<', 20e6, sprintf('ks_test: 1000 dying warnings on 2 x 3200 values grow RSS by %.1f MB', $grew / 1e6));
}

done_testing();
