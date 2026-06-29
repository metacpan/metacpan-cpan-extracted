#!/usr/bin/env perl
require 5.010;
use warnings FATAL => 'all';
use Scalar::Util 'looks_like_number';
use Stats::LikeR;
use Test::Exception; # dies_ok
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

# a NaN we can rely on for the listwise-deletion path
my $nan;
{
	no warnings;
	$nan = 9 ** 9 ** 9;
	$nan = $nan - $nan;
}

#--------
# one-way ANOVA, HoA input (groups A/B/C, exact group means 2/5/8)
#--------
my %oneway = (
	y => [1, 2, 3, 4, 5, 6, 7, 8, 9],
	g => [qw(A A A B B B C C C)],
);
{
	my $r = aov(\%oneway, 'y~g');
	is(ref $r, 'HASH', 'aov returns hashref');

	ok(exists $r->{g},          'table has term g');
	ok(exists $r->{Residuals},  'table has Residuals');
	ok(!exists $r->{Intercept}, 'Intercept is not an ANOVA row');

	is($r->{g}{Df}, 2, 'g Df = 2');
	is_approx($r->{g}{'Sum Sq'},  54, 'g Sum Sq');
	is_approx($r->{g}{'Mean Sq'}, 27, 'g Mean Sq');
	is_approx($r->{g}{'F value'}, 27, 'g F value');
	ok(looks_like_number($r->{g}{'Pr(>F)'}), 'g Pr(>F) is numeric');
	ok($r->{g}{'Pr(>F)'} > 0 && $r->{g}{'Pr(>F)'} < 0.01, 'g Pr(>F) small and in (0,1)');

	is($r->{Residuals}{Df}, 6, 'Residuals Df = 6');
	is_approx($r->{Residuals}{'Sum Sq'},  6, 'Residuals Sum Sq');
	is_approx($r->{Residuals}{'Mean Sq'}, 1, 'Residuals Mean Sq');
	is_approx($r->{g}{'Sum Sq'} + $r->{Residuals}{'Sum Sq'}, 60, 'SS decomposition sums to total');

	# predict-compatible output
	is($r->{family}, 'gaussian', 'family = gaussian');

	is(ref $r->{coefficients}, 'HASH', 'coefficients is a hashref');
	is_approx($r->{coefficients}{Intercept}, 2, 'Intercept = mean(A)');
	is_approx($r->{coefficients}{gB},         3, 'gB = mean(B)-mean(A)');
	is_approx($r->{coefficients}{gC},         6, 'gC = mean(C)-mean(A)');

	is(ref $r->{'fitted.values'}, 'HASH', 'fitted.values is a hashref');
	is(scalar keys %{$r->{'fitted.values'}}, 9, 'fitted.values has one entry per obs');
	is_approx($r->{'fitted.values'}{1}, 2, 'fitted[1] = group A mean');
	is_approx($r->{'fitted.values'}{4}, 5, 'fitted[4] = group B mean');
	is_approx($r->{'fitted.values'}{7}, 8, 'fitted[7] = group C mean');

	is(ref $r->{xlevels}, 'HASH', 'xlevels is a hashref');
	is_deeply($r->{xlevels}{g}, [qw(A B C)], 'xlevels{g} sorted, reference first');

	is(ref $r->{group_stats}, 'HASH', 'group_stats present');
	is_approx($r->{group_stats}{mean}{y}, 5, 'group_stats mean of y');
	is($r->{group_stats}{size}{y}, 9, 'group_stats size of y');
}

#--------
# same data via HoH and AoH -> identical table & coefficients
#--------
{
	my %hoh = map { ("r$_" => { y => $oneway{y}[$_ - 1], g => $oneway{g}[$_ - 1] }) } 1 .. 9;
	my $r = aov(\%hoh, 'y~g');
	is($r->{g}{Df}, 2, 'HoH: g Df = 2');
	is_approx($r->{g}{'Sum Sq'}, 54, 'HoH: g Sum Sq');
	is_approx($r->{coefficients}{gB}, 3, 'HoH: gB');
	is_approx($r->{coefficients}{gC}, 6, 'HoH: gC');
}
{
	my @aoh = map { { y => $oneway{y}[$_], g => $oneway{g}[$_] } } 0 .. 8;
	my $r = aov(\@aoh, 'y~g');
	is($r->{g}{Df}, 2, 'AoH: g Df = 2');
	is_approx($r->{g}{'Sum Sq'}, 54, 'AoH: g Sum Sq');
	is_approx($r->{coefficients}{Intercept}, 2, 'AoH: Intercept');
}

#--------
# stacked input (no formula) -> auto Value~Group
#--------
{
	my %grp = (A => [1, 2, 3], B => [4, 5, 6], C => [7, 8, 9]);
	my $r = aov(\%grp);
	ok(exists $r->{Group}, 'stacked: term Group present');
	is($r->{Group}{Df}, 2, 'stacked: Group Df = 2');
	is_approx($r->{Group}{'Sum Sq'}, 54, 'stacked: Group Sum Sq');
	is_deeply($r->{xlevels}{Group}, [qw(A B C)], 'stacked: xlevels Group');
}

#--------
# simple regression  y = 1 + 2x
#--------
{
	my %d = (y => [1, 3, 5], x => [0, 1, 2]);
	my $r = aov(\%d, 'y~x');
	is_approx($r->{coefficients}{Intercept}, 1, 'reg Intercept');
	is_approx($r->{coefficients}{x},         2, 'reg slope x');
	is_approx($r->{'fitted.values'}{1}, 1, 'reg fitted[1]');
	is_approx($r->{'fitted.values'}{3}, 5, 'reg fitted[3]');
	is($r->{x}{Df}, 1, 'reg x Df = 1');
}

#--------
# dot expansion  y ~ .  ==  y ~ x + z
#--------
{
	my %d = (y => [1, 3, 4, 6], x => [0, 1, 0, 1], z => [0, 0, 1, 1]);
	my $r = aov(\%d, 'y~.');
	is_approx($r->{coefficients}{Intercept}, 1, 'dot: Intercept');
	is_approx($r->{coefficients}{x},         2, 'dot: x');
	is_approx($r->{coefficients}{z},         3, 'dot: z');
	ok(exists $r->{x} && exists $r->{z}, 'dot: both x and z are table rows');
}

#--------
# intercept removal  y ~ x - 1
#--------
{
	my %d = (y => [2, 4, 6], x => [1, 2, 3]); # y = 2x through the origin
	my $r = aov(\%d, 'y~x-1');
	ok(!exists $r->{coefficients}{Intercept}, 'no-intercept: Intercept absent');
	is_approx($r->{coefficients}{x}, 2, 'no-intercept: slope x');
	is_approx($r->{'fitted.values'}{2}, 4, 'no-intercept: fitted[2]');
}

#--------
# two-way with interaction  y ~ A*B (balanced, zero residual)
#--------
my %twoway = (
	A => [qw(a1 a1 a1 a1 a2 a2 a2 a2)],
	B => [qw(b1 b1 b2 b2 b1 b1 b2 b2)],
	y => [10, 10, 12, 12, 20, 20, 30, 30],
);
{
	my $r = aov(\%twoway, 'y~A*B');
	ok(exists $r->{A} && exists $r->{B} && exists $r->{'A:B'}, 'two-way: A, B, A:B present');
	is($r->{A}{Df},         1, 'A Df = 1');
	is($r->{B}{Df},         1, 'B Df = 1');
	is($r->{'A:B'}{Df},     1, 'A:B Df = 1');
	is($r->{Residuals}{Df}, 4, 'Residuals Df = 4');

	is_approx($r->{A}{'Sum Sq'},     392, 'A Sum Sq',   1e-6);
	is_approx($r->{B}{'Sum Sq'},      72, 'B Sum Sq',   1e-6);
	is_approx($r->{'A:B'}{'Sum Sq'},  32, 'A:B Sum Sq', 1e-6);
	is_approx($r->{Residuals}{'Sum Sq'}, 0, 'Residuals Sum Sq ~ 0', 1e-6);

	is_approx($r->{coefficients}{Intercept}, 10, 'two-way Intercept');
	is_approx($r->{coefficients}{Aa2},       10, 'two-way Aa2');
	is_approx($r->{coefficients}{Bb2},        2, 'two-way Bb2');
	is_approx($r->{coefficients}{'Aa2:Bb2'},  8, 'two-way Aa2:Bb2', 1e-6);

	is_deeply($r->{xlevels}{A}, [qw(a1 a2)], 'xlevels A');
	is_deeply($r->{xlevels}{B}, [qw(b1 b2)], 'xlevels B');
}

#--------
# listwise deletion of a NaN response row
#--------
{
	my %d = (y => [1, 2, $nan, 4], g => [qw(A A B B)]);
	my $r = aov(\%d, 'y~g');
	is(scalar keys %{$r->{'fitted.values'}}, 3, 'NaN row dropped -> 3 fitted values');
	is($r->{Residuals}{Df}, 1, 'NaN: Residuals Df = 1');
	is_approx($r->{coefficients}{Intercept}, 1.5, 'NaN: Intercept = mean(A)');
	is_approx($r->{coefficients}{gB},        2.5, 'NaN: gB = 4 - 1.5');
}

#--------
# error handling
#--------
throws_ok { aov(5, 'y~x') } qr/must be a reference/, 'non-ref data croaks';
throws_ok { aov({}, 'y~x') } qr/empty/i, 'empty data hash croaks';
throws_ok { aov({ y => [1, 2], x => [3, 4] }, 'y x') } qr/missing '~'/, 'formula without ~ croaks';
throws_ok { aov([1, 2, 3], 'y~x') } qr/HashRefs/, 'AoH of non-hashrefs croaks';
throws_ok { aov({ a => 1 }) } qr/ArrayRefs/, 'no-formula non-HoA croaks';
throws_ok {
	aov({ y => [1, 2, 3, 4], a => [qw(p q p q)], b => [qw(r r s s)] }, 'y~a:b');
} qr/main effects/, 'interaction without main effects croaks';
throws_ok { aov({ y => [1, 2], g => [qw(A B)] }, 'y~g') } qr/degrees of freedom/, '0 df croaks';

#--------
# leak checks
#--------
no_leaks_ok {
	eval { aov(\%oneway, 'y~g') }
} 'aov one-way: no leaks' unless $INC{'Devel/Cover.pm'};
no_leaks_ok {
	eval { aov(\%twoway, 'y~A*B') }
} 'aov two-way interaction: no leaks' unless $INC{'Devel/Cover.pm'};
no_leaks_ok {
	eval { aov({}, 'y~x') }
} 'aov croak path: no leaks' unless $INC{'Devel/Cover.pm'};

done_testing();
