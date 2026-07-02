require 5.010;
use strict;
use warnings;
use Test::More;
use Stats::LikeR;

# Prefer Test::LeakTrace; fall back to a no-op so the file is self-contained
# and runs where Test::LeakTrace is not installed.
BEGIN {
	unless (eval { require Test::LeakTrace; Test::LeakTrace->import('no_leaks_ok'); 1 }) {
		no warnings 'redefine';
		*no_leaks_ok = sub (&;$) { my (undef, $name) = @_; ok(1, ($name || 'no_leaks_ok (skipped)')); };
	}
}

# Compare two numbers within an absolute tolerance.
sub is_approx {
	my ($got, $exp, $tol, $name) = @_;
	$tol = 1e-6 unless defined $tol;
	my $ok = defined($got) && abs($got - $exp) <= $tol;
	ok($ok, $name)
		or diag(sprintf "got %.12g, expected %.12g (tol %.3g)",
			(defined $got ? $got : 'nan'), $exp, $tol);
	return $ok;
}

#
# qtukey / ptukey against R's studentized-range values.
#
is_approx(qtukey(0.95, 3, 27),  3.506426, 1e-3, 'qtukey(0.95, 3, 27)');
is_approx(qtukey(0.95, 4, 20),  3.958293, 1e-3, 'qtukey(0.95, 4, 20)');
is_approx(qtukey(0.95, 2, 1e9), 2.771808, 1e-3, 'qtukey(0.95, 2, Inf) == sqrt(2)*qnorm(.975)');

# ptukey is the inverse: P(range < qtukey(p)) == p
is_approx(ptukey(qtukey(0.95, 3, 27), 3, 27), 0.95, 1e-4, 'ptukey o qtukey round-trip');

# upper tail and lower_tail => complementary
is_approx(ptukey(3.5, 3, 27, 'lower.tail' => 0),
	1 - ptukey(3.5, 3, 27), 1e-12, 'ptukey upper tail == 1 - lower tail');
is_approx(qtukey(0.05, 3, 27, 'lower.tail' => 0),
	qtukey(0.95, 3, 27), 1e-9, 'qtukey upper tail matches complementary lower tail');

#
# TukeyHSD against R: TukeyHSD(aov(weight ~ group, PlantGrowth))
#
my %pg = (
	weight => [
		4.17,5.58,5.18,6.11,4.50,4.61,5.17,4.53,5.33,5.14,
		4.81,4.17,4.41,3.59,5.87,3.83,6.03,4.89,4.32,4.69,
		6.31,5.12,5.54,5.50,5.37,5.29,4.92,6.15,5.80,5.26,
	],
	group => [ (('ctrl') x 10), (('trt1') x 10), (('trt2') x 10) ],
);

# Reference: comparison => [diff, lwr, upr, p adj]
my %R = (
	'trt1-ctrl' => [-0.371, -1.0622161, 0.3202161, 0.3908711],
	'trt2-ctrl' => [ 0.494, -0.1972161, 1.1852161, 0.1979960],
	'trt2-trt1' => [ 0.865,  0.1737839, 1.5562161, 0.0120064],
);

my $fit = aov(\%pg, 'weight ~ group');
my $hsd = TukeyHSD($fit, data => \%pg, formula => 'weight ~ group');

is(scalar(@{ $hsd->{group} }), 3, 'aov: three pairwise comparisons');
is_approx($hsd->{'conf.level'}, 0.95, 1e-12, 'aov: conf.level attribute');
is($hsd->{ordered}, 0, 'aov: ordered attribute false by default');

for my $row (@{ $hsd->{group} }) {
	my $c = $row->{comparison};
	my $r = $R{$c} or do { fail("unexpected comparison '$c'"); next; };
	is_approx($row->{diff},    $r->[0], 1e-4, "aov $c: diff");
	is_approx($row->{lwr},     $r->[1], 1e-4, "aov $c: lwr");
	is_approx($row->{upr},     $r->[2], 1e-4, "aov $c: upr");
	is_approx($row->{'p adj'}, $r->[3], 1e-4, "aov $c: p adj");
}

# lm path reproduces the same numbers for a one-way model.
my $lmfit = lm(formula => 'weight ~ group', data => \%pg);
my $hlm   = TukeyHSD($lmfit, data => \%pg, response => 'weight');
is_approx($hlm->{group}[2]{diff},    0.865,    1e-4, 'lm: trt2-trt1 diff');
is_approx($hlm->{group}[2]{'p adj'}, 0.012006, 1e-4, 'lm: trt2-trt1 p adj');

# glm gaussian path (deviance/df == MSE) reproduces it too.
my $glmfit = glm(formula => 'weight ~ group', data => \%pg, family => 'gaussian');
my $hglm   = TukeyHSD($glmfit, data => \%pg, response => 'weight');
is_approx($hglm->{group}[2]{diff},    0.865,    1e-4, 'glm(gaussian): trt2-trt1 diff');
is_approx($hglm->{group}[2]{'p adj'}, 0.012006, 1e-4, 'glm(gaussian): trt2-trt1 p adj');

# ordered => 1 sorts levels by mean; all diffs become positive.
my $hord = TukeyHSD($fit, data => \%pg, response => 'weight', ordered => 1);
is($hord->{ordered}, 1, 'ordered attribute set');
ok((!grep { $_->{diff} < 0 } @{ $hord->{group} }), 'ordered: every diff is non-negative');

# non-factor entries in which are dropped (with a warning), like R.
{
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	my $h = TukeyHSD($fit, data => \%pg, response => 'weight',
		which => ['group', 'weight']);
	ok(exists $h->{group},   'which: factor kept');
	ok(!exists $h->{weight}, 'which: non-factor dropped');
	ok(scalar(@w) >= 1,      'which: warning emitted for dropped non-factor');
}

# WIDE one-way layout: data = { level => [obs], ... }, no response/formula.
my %pw = (
	ctrl => [ @{ $pg{weight} }[ 0 ..  9] ],
	trt1 => [ @{ $pg{weight} }[10 .. 19] ],
	trt2 => [ @{ $pg{weight} }[20 .. 29] ],
);
my $wfit = aov(\%pw);                        # no formula -> auto-stack
my $hw   = TukeyHSD($wfit, data => \%pw);    # wide, no response/formula
ok(ref $hw->{group} eq 'ARRAY',   'wide: comparisons under Group key');
is(scalar @{ $hw->{group} }, 3,   'wide: three pairwise comparisons');
my ($w21) = grep { $_->{comparison} eq 'trt2-trt1' } @{ $hw->{group} };
is_approx($w21->{diff},    0.865,    1e-4, 'wide: trt2-trt1 diff matches R');
is_approx($w21->{'p adj'}, 0.012006, 1e-4, 'wide: trt2-trt1 p adj matches R');
my $hwl = TukeyHSD(aov(\%pw), data => \%pw, which => 'treatment');
ok(exists $hwl->{treatment}, 'wide: which relabels the result key');

# input validation
eval { TukeyHSD($fit, response => 'weight') };
like($@, qr/\bdata\b/, "croaks when 'data' missing");
eval { TukeyHSD($fit, data => \%pg) };
like($@, qr/response/, 'croaks when response/formula missing');

# ---------------------------------------------------------------------------
# Leak safety
# ---------------------------------------------------------------------------
no_leaks_ok {
	qtukey(0.95, 4, 25);
	ptukey(3.9, 4, 25);
} 'ptukey/qtukey: no memory leaks' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	my $f = aov(\%pg, 'weight ~ group');
	TukeyHSD($f, data => \%pg, response => 'weight');
} 'TukeyHSD: no memory leaks' unless $INC{'Devel/Cover.pm'};

done_testing();
