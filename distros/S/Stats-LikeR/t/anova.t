#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use Scalar::Util 'looks_like_number';
use Stats::LikeR;
use Test::Exception; # die_ok
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

# Custom helper for floating-point comparisons
sub is_approx {
	my ($got, $expected, $test_name, $epsilon) = @_;
	$epsilon = 1e-7 if not defined $epsilon;
	my $current_sub = ( split( /::/, ( caller(0) )[3] ) )[-1];
	my $i = 0;
	foreach my $arg ($got, $expected, $test_name) {
		next if defined $arg;
		die "\$arg[$i] (see subroutine signature for name) isn't defined in $current_sub";
		$i++;
	}
	my $diff = abs($got - $expected);
	if ($diff <= $epsilon) {
		pass("$test_name: within $epsilon");
		return 1;
	} else {
		fail($test_name);
		diag("         got: $got\n    expected: $expected; diff = $diff");
		return 0;
	}
}

#--------
# one-way: matches the documented aov() output exactly
#--------
{
	my $r = anova(
		{
			yield => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
			ctrl  => [1,     1,   1,   0,   0,   0],
		},
		'yield ~ ctrl');

	ok( exists $r->{ctrl},      'term hash keyed by predictor name' );
	ok( exists $r->{Residuals}, 'Residuals row present' );

	is( $r->{ctrl}{Df},        1, 'ctrl: Df = 1' );
	is( $r->{Residuals}{Df},   4, 'Residuals: Df = 4' );
	is_approx( $r->{ctrl}{'Sum Sq'},   1.70666666666667, 'ctrl: Sum Sq' );
	is_approx( $r->{ctrl}{'Mean Sq'},  1.70666666666667, 'ctrl: Mean Sq' );
	is_approx( $r->{ctrl}{'F value'},  25.6,             'ctrl: F value' );
	is_approx( $r->{ctrl}{'Pr(>F)'},   0.00718232855871859, 'ctrl: Pr(>F)', 1e-6 );
	is_approx( $r->{Residuals}{'Sum Sq'},  0.266666666666666, 'Residuals: Sum Sq' );
	is_approx( $r->{Residuals}{'Mean Sq'}, 0.0666666666666665, 'Residuals: Mean Sq' );

	# Residuals carries no F test (matches aov output shape)
	ok( !exists $r->{Residuals}{'F value'}, 'Residuals: no F value key' );
	ok( !exists $r->{Residuals}{'Pr(>F)'},  'Residuals: no Pr(>F) key' );
}

#--------
# two-way factorial with categorical interaction: y ~ A * B
# balanced 2x2; hand-computed SS_A=288, SS_B=18, SS_AB=2, RSS=52 (df 1,1,1,4)
#--------
{
	my %d = (
		y => [10, 12, 14, 16, 20, 24, 26, 30],
		A => [qw/a a a a b b b b/],
		B => [qw/p q p q p q p q/],
	);
	my $r = anova(\%d, 'y ~ A * B');

	ok( exists $r->{A} && exists $r->{B} && exists $r->{'A:B'},
		'* expands to main effects + interaction (A, B, A:B)' );

	is( $r->{A}{Df},   1, 'A: Df = levels-1 = 1' );
	is( $r->{B}{Df},   1, 'B: Df = 1' );
	is( $r->{'A:B'}{Df}, 1, 'A:B: Df = (la-1)*(lb-1) = 1' );
	is( $r->{Residuals}{Df}, 4, 'Residuals: Df = n - 4' );

	is_approx( $r->{A}{'Sum Sq'},   288, 'A: Sum Sq' );
	is_approx( $r->{B}{'Sum Sq'},    18, 'B: Sum Sq' );
	is_approx( $r->{'A:B'}{'Sum Sq'},  2, 'A:B: Sum Sq' );
	is_approx( $r->{Residuals}{'Sum Sq'}, 52, 'Residuals: Sum Sq' );

	# SS identity: term SS + residual SS == corrected total
	my $ybar = 0; $ybar += $_ for @{ $d{y} }; $ybar /= @{ $d{y} };
	my $sst  = 0; $sst  += ($_ - $ybar) ** 2 for @{ $d{y} };
	is_approx( $r->{A}{'Sum Sq'} + $r->{B}{'Sum Sq'}
	         + $r->{'A:B'}{'Sum Sq'} + $r->{Residuals}{'Sum Sq'},
	           $sst, 'SS_A + SS_B + SS_AB + RSS == corrected SST' );
}

#--------
# AoH input form matches HoA input form
#--------
{
	my %hoa = ( y => [2, 3, 5, 4], x => [1, 2, 3, 4] );
	my @aoh = map { { y => $hoa{y}[$_], x => $hoa{x}[$_] } } 0 .. 3;
	my $th = anova(\%hoa, 'y ~ x');
	my $ta = anova(\@aoh, 'y ~ x');
	is_approx( $ta->{x}{'Sum Sq'}, $th->{x}{'Sum Sq'}, 'AoH SS matches HoA SS' );
	is_approx( $ta->{Residuals}{'Sum Sq'}, $th->{Residuals}{'Sum Sq'},
	           'AoH RSS matches HoA RSS' );
}

#--------
# rank deficiency: a collinear predictor gets Df 0 and Sum Sq 0
#--------
{
	my %d = (
		yield => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
		ctrl  => [1,     1,   1,   0,   0,   0],
		dup   => [1,     1,   1,   0,   0,   0],   # identical to ctrl
	);
	my $r = anova(\%d, 'yield ~ ctrl + dup');
	is( $r->{ctrl}{Df}, 1, 'ctrl: Df = 1' );
	is( $r->{dup}{Df},  0, 'collinear dup: Df = 0' );
	is_approx( $r->{dup}{'Sum Sq'}, 0, 'collinear dup: Sum Sq = 0' );
	ok( !exists $r->{dup}{'F value'}, 'collinear dup: no F value' );
}

#--------
# listwise NA handling
#--------
{
	my %full = ( y => [2, 3, 5, 4],            x => [1, 2, 3, 4] );
	my %na   = ( y => [2, 3, 5, 4, undef, 9],  x => [1, 2, 3, 4, 5, undef] );
	my $tf = anova(\%full, 'y ~ x');
	my $tn = anova(\%na,   'y ~ x');
	is_approx( $tn->{x}{'Sum Sq'}, $tf->{x}{'Sum Sq'},
	           'rows with undef in y or x are dropped listwise' );
}

#--------
# error paths
#--------
dies_ok { anova({ a => [1,2], b => [3,4] }) }
	'dies with < 2 arguments';
dies_ok { anova('not a ref', 'y ~ x') }
	'dies when data is not a reference';
dies_ok { anova(\%{{ y => [1,2], x => [1,2] }}, 'no tilde here') }
	'dies on a formula without ~';
dies_ok { anova(\%{{ y => [1], x => [1] }}, 'y ~ x') }
	'dies with fewer than 2 complete observations';
dies_ok { anova(\%{{ y => [undef, undef], x => [1, 2] }}, 'y ~ x') }
	'dies when fewer than 2 complete observations remain';

# nested-model comparison: anova(\%d, f1, f2, ...) -> ArrayRef table.
#
# Strategy: rather than hard-code R numbers, cross-check the comparison
# table against the (already-tested) single-model Type-I table. For a chain
# m0, m1, ... where each model adds the next term(s), the largest model
# supplies the common scale, so each comparison row must reproduce the added
# block's row in the single-model table of the LARGEST model exactly:
# Df<->Df, "Sum of Sq"<->"Sum Sq", F<->"F value", Pr(>F)<->Pr(>F). The
# residual Df / RSS of each row must telescope through those same term SS.

#--------
# two numeric models, y ~ a  vs  y ~ a + b : shape + full cross-check
#--------
{
	my %d = (
		y => [5, 7, 6, 9, 8, 11, 10, 13],
		a => [1, 2, 3, 4, 5,  6,  7,  8],
		b => [2, 1, 4, 3, 6,  5,  8,  7],
	);
	my $cmp  = anova(\%d, 'y ~ a', 'y ~ a + b');
	my $full = anova(\%d, 'y ~ a + b');

	is( ref($cmp), 'ARRAY', 'model comparison returns an ArrayRef' );
	is( scalar(@$cmp), 2, 'one row per model' );

	# row 0 (base model) carries residuals only, no comparison stats
	ok(  exists $cmp->[0]{'Res.Df'}, 'row 0: has Res.Df' );
	ok(  exists $cmp->[0]{'RSS'},    'row 0: has RSS' );
	ok( !exists $cmp->[0]{'Df'},        'row 0: no Df' );
	ok( !exists $cmp->[0]{'Sum of Sq'}, 'row 0: no Sum of Sq' );
	ok( !exists $cmp->[0]{'F'},         'row 0: no F' );
	ok( !exists $cmp->[0]{'Pr(>F)'},    'row 0: no Pr(>F)' );

	# row 1 (adds b) carries the full comparison
	ok( exists $cmp->[1]{'Df'},        'row 1: has Df' );
	ok( exists $cmp->[1]{'Sum of Sq'}, 'row 1: has Sum of Sq' );
	ok( exists $cmp->[1]{'F'},         'row 1: has F' );
	ok( exists $cmp->[1]{'Pr(>F)'},    'row 1: has Pr(>F)' );
	ok( looks_like_number($cmp->[1]{'F'}), 'row 1: F is numeric' );

	# residual df telescopes through the term dfs of the full model
	is( $cmp->[1]{'Res.Df'}, $full->{Residuals}{Df},
		'row 1 Res.Df == full-model residual Df' );
	is( $cmp->[0]{'Res.Df'}, $full->{Residuals}{Df} + $full->{b}{Df},
		'row 0 Res.Df == residual Df + df(b)' );

	# RSS telescopes through the term SS of the full model
	is_approx( $cmp->[1]{'RSS'}, $full->{Residuals}{'Sum Sq'},
		'row 1 RSS == full-model residual SS' );
	is_approx( $cmp->[0]{'RSS'},
		$full->{Residuals}{'Sum Sq'} + $full->{b}{'Sum Sq'},
		'row 0 RSS == residual SS + SS(b)' );

	# the added block (row 1) reproduces the b row of the single-model table
	is( $cmp->[1]{'Df'}, $full->{b}{Df}, 'row 1 Df == df(b)' );
	is_approx( $cmp->[1]{'Sum of Sq'}, $full->{b}{'Sum Sq'},
		'row 1 Sum of Sq == SS(b)' );
	is_approx( $cmp->[1]{'F'}, $full->{b}{'F value'},
		'row 1 F == F value(b)' );
	is_approx( $cmp->[1]{'Pr(>F)'}, $full->{b}{'Pr(>F)'},
		'row 1 Pr(>F) == Pr(>F)(b)', 1e-6 );

	# "Sum of Sq" is exactly the drop in RSS between consecutive models
	is_approx( $cmp->[1]{'Sum of Sq'}, $cmp->[0]{'RSS'} - $cmp->[1]{'RSS'},
		'Sum of Sq == RSS[i-1] - RSS[i]' );

	# convenience: each row records its formula
	ok( defined $cmp->[0]{formula} && $cmp->[0]{formula} =~ /~/,
		'row 0: formula string present' );
	ok( defined $cmp->[1]{formula} && $cmp->[1]{formula} =~ /~/,
		'row 1: formula string present' );
}

#--------
# three-model numeric chain: y ~ a, y ~ a + b, y ~ a + b + c
# every added block reproduces the corresponding term of the full model
#--------
{
	my %d = (
		y => [5, 7, 6, 9, 8, 11, 10, 13],
		a => [1, 2, 3, 4, 5,  6,  7,  8],
		b => [2, 1, 4, 3, 6,  5,  8,  7],
		c => [1, 3, 2, 5, 4,  6,  8,  7],
	);
	my $cmp  = anova(\%d, 'y ~ a', 'y ~ a + b', 'y ~ a + b + c');
	my $full = anova(\%d, 'y ~ a + b + c');

	is( scalar(@$cmp), 3, 'three models -> three rows' );

	# monotone non-increasing RSS and non-increasing residual Df down the chain
	ok( $cmp->[0]{'RSS'} >= $cmp->[1]{'RSS'} - 1e-9
	 && $cmp->[1]{'RSS'} >= $cmp->[2]{'RSS'} - 1e-9, 'RSS is non-increasing' );
	ok( $cmp->[0]{'Res.Df'} > $cmp->[1]{'Res.Df'}
	 && $cmp->[1]{'Res.Df'} > $cmp->[2]{'Res.Df'}, 'Res.Df is decreasing' );

	# row 1 <-> term b, row 2 <-> term c of the full (largest) model
	is( $cmp->[1]{'Df'}, $full->{b}{Df}, 'row 1 Df == df(b)' );
	is_approx( $cmp->[1]{'Sum of Sq'}, $full->{b}{'Sum Sq'},  'row 1 Sum of Sq == SS(b)' );
	is_approx( $cmp->[1]{'F'},         $full->{b}{'F value'}, 'row 1 F == F value(b)' );
	is_approx( $cmp->[1]{'Pr(>F)'},    $full->{b}{'Pr(>F)'},  'row 1 Pr(>F) == Pr(>F)(b)', 1e-6 );

	is( $cmp->[2]{'Df'}, $full->{c}{Df}, 'row 2 Df == df(c)' );
	is_approx( $cmp->[2]{'Sum of Sq'}, $full->{c}{'Sum Sq'},  'row 2 Sum of Sq == SS(c)' );
	is_approx( $cmp->[2]{'F'},         $full->{c}{'F value'}, 'row 2 F == F value(c)' );
	is_approx( $cmp->[2]{'Pr(>F)'},    $full->{c}{'Pr(>F)'},  'row 2 Pr(>F) == Pr(>F)(c)', 1e-6 );

	# last row's residuals match the full model exactly
	is( $cmp->[2]{'Res.Df'}, $full->{Residuals}{Df}, 'last row Res.Df == full residual Df' );
	is_approx( $cmp->[2]{'RSS'}, $full->{Residuals}{'Sum Sq'}, 'last row RSS == full residual SS' );
}

#--------
# categorical chain with an interaction: y ~ A, y ~ A + B, y ~ A + B + A:B
#--------
{
	my %d = (
		y => [10, 12, 14, 16, 20, 24, 26, 30],
		A => [qw/a a a a b b b b/],
		B => [qw/p q p q p q p q/],
	);
	my $cmp  = anova(\%d, 'y ~ A', 'y ~ A + B', 'y ~ A + B + A:B');
	my $full = anova(\%d, 'y ~ A + B + A:B');

	is( scalar(@$cmp), 3, 'factor chain -> three rows' );

	# adding B (row 1) reproduces the B term of the full model
	is( $cmp->[1]{'Df'}, $full->{B}{Df}, 'row 1 Df == df(B)' );
	is_approx( $cmp->[1]{'Sum of Sq'}, $full->{B}{'Sum Sq'},  'row 1 Sum of Sq == SS(B)' );
	is_approx( $cmp->[1]{'F'},         $full->{B}{'F value'}, 'row 1 F == F value(B)' );

	# adding A:B (row 2) reproduces the interaction term of the full model
	is( $cmp->[2]{'Df'}, $full->{'A:B'}{Df}, 'row 2 Df == df(A:B)' );
	is_approx( $cmp->[2]{'Sum of Sq'}, $full->{'A:B'}{'Sum Sq'},  'row 2 Sum of Sq == SS(A:B)' );
	is_approx( $cmp->[2]{'F'},         $full->{'A:B'}{'F value'}, 'row 2 F == F value(A:B)' );

	is_approx( $cmp->[2]{'RSS'}, $full->{Residuals}{'Sum Sq'},
		'last row RSS == full residual SS (52)' );
	is_approx( $cmp->[2]{'RSS'}, 52, 'sanity: full residual SS is 52' );
}

#--------
# comparison form accepts AoH just like the single-model form
#--------
{
	my %hoa = (
		y => [5, 7, 6, 9, 8, 11, 10, 13],
		a => [1, 2, 3, 4, 5,  6,  7,  8],
		b => [2, 1, 4, 3, 6,  5,  8,  7],
	);
	my @aoh = map { { y => $hoa{y}[$_], a => $hoa{a}[$_], b => $hoa{b}[$_] } } 0 .. 7;
	my $ch = anova(\%hoa, 'y ~ a', 'y ~ a + b');
	my $ca = anova(\@aoh, 'y ~ a', 'y ~ a + b');
	is_approx( $ca->[1]{'Sum of Sq'}, $ch->[1]{'Sum of Sq'},
		'AoH comparison Sum of Sq matches HoA' );
	is_approx( $ca->[1]{'F'}, $ch->[1]{'F'},
		'AoH comparison F matches HoA' );
	is( $ca->[1]{'Res.Df'}, $ch->[1]{'Res.Df'},
		'AoH comparison Res.Df matches HoA' );
}

#--------
# union NA handling: all models are fit on ONE shared complete-case set,
# so a NA in a predictor used by only one model drops that row from every fit.
#--------
{
	# row 4 has b => undef; that row must be dropped from BOTH models, so the
	# comparison equals what you'd get from the fully-complete rows only.
	my %na = (
		y => [5, 7, 6, 9, 8,     11, 10, 13],
		a => [1, 2, 3, 4, 5,      6,  7,  8],
		b => [2, 1, 4, 3, undef,  5,  8,  7],
	);
	my %clean = (
		y => [5, 7, 6, 9, 11, 10, 13],
		a => [1, 2, 3, 4,  6,  7,  8],
		b => [2, 1, 4, 3,  5,  8,  7],
	);
	my $cn = anova(\%na,    'y ~ a', 'y ~ a + b');
	my $cc = anova(\%clean, 'y ~ a', 'y ~ a + b');

	is( $cn->[0]{'Res.Df'}, $cc->[0]{'Res.Df'},
		'union listwise: base-model Res.Df matches the pre-cleaned data' );
	is_approx( $cn->[1]{'Sum of Sq'}, $cc->[1]{'Sum of Sq'},
		'union listwise: Sum of Sq matches the pre-cleaned data' );
	is_approx( $cn->[1]{'F'}, $cc->[1]{'F'},
		'union listwise: F matches the pre-cleaned data' );
}

#--------
# comparison-form error paths
#--------
dies_ok { anova('not a ref', 'y ~ a', 'y ~ a + b') }
	'comparison: dies when data is not a reference';
dies_ok { anova({ y => [1,2,3,4], a => [1,2,3,4] }, 'y ~ a', 'no tilde here') }
	'comparison: dies on a malformed later formula';
dies_ok { anova({ y => [1, undef], a => [undef, 2], b => [1, 2] }, 'y ~ a', 'y ~ a + b') }
	'comparison: dies with fewer than 2 shared complete observations';

#--------
# memory safety
#--------
no_leaks_ok {
	eval { anova({ yield => [5.5,5.4,5.8,4.5,4.8,4.2], ctrl => [1,1,1,0,0,0] },
	             'yield ~ ctrl') }
} 'anova() one-way: no memory leaks' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	eval { anova({ y => [10,12,14,16,20,24,26,30],
	               A => [qw/a a a a b b b b/],
	               B => [qw/p q p q p q p q/] }, 'y ~ A * B') }
} 'anova() two-way factorial: no memory leaks' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	eval { anova('bad', 'y ~ x') }
} 'anova() error path: no memory leaks' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	eval { anova({ y => [5,7,6,9,8,11,10,13],
	               a => [1,2,3,4,5,6,7,8],
	               b => [2,1,4,3,6,5,8,7] }, 'y ~ a', 'y ~ a + b') }
} 'anova() 2-model comparison: no memory leaks' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	eval { anova({ y => [10,12,14,16,20,24,26,30],
	               A => [qw/a a a a b b b b/],
	               B => [qw/p q p q p q p q/] },
	             'y ~ A', 'y ~ A + B', 'y ~ A + B + A:B') }
} 'anova() 3-model factor comparison: no memory leaks' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	eval { anova('bad', 'y ~ a', 'y ~ a + b') }
} 'anova() comparison error path: no memory leaks' unless $INC{'Devel/Cover.pm'};

done_testing();
