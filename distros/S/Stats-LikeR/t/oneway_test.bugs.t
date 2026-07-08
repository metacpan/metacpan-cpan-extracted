#!/usr/bin/env perl
# Regression tests for the bugs fixed in oneway_test:
#   * undef / non-numeric observations were silently coerced to 0.0
#   * error paths (bad ref, too few groups/observations) must croak cleanly
#     instead of leaking or running on garbage
#   * a clean run still returns the documented Welch statistics
require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception;
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

# The documented two-group example (hash of groups). These are the values from
# the POD, so the sanity check doubles as a guard against regressions.
my %ok_groups = (
	yield => [5.5, 5.4, 5.8, 4.5, 4.8, 4.2],
	ctrl  => [1,   1,   1,   0,   0,   0  ],
);

# BUG: undef / non-numeric observations were silently treated as 0.0, quietly
# corrupting the statistic. They must now make the call die.
#
{
	my %undef_hash = (yield => [5.5, undef, 5.8, 4.5], ctrl => [1, 1, 0, 0]);
	throws_ok { oneway_test(\%undef_hash) } qr/undefined|not defined|numeric/i,
		'hash group: undef observation dies (no silent 0.0)';

	my %str_hash = (yield => [5.5, 'oops', 5.8, 4.5], ctrl => [1, 1, 0, 0]);
	throws_ok { oneway_test(\%str_hash) } qr/numeric|undefined/i,
		'hash group: non-numeric observation dies';

	my $undef_aoa = [[5.5, 5.4, 5.8, undef], [1, 1, 0, 0]];
	throws_ok { oneway_test($undef_aoa) } qr/undefined|not defined|numeric/i,
		'array group: undef observation dies';
}

# ---------------------------------------------------------------------------
# BUG: shape/size validation. Empty input and under-sized groups must croak
# with a clear message, never run on out-of-range data.
# ---------------------------------------------------------------------------
{
	throws_ok { oneway_test([]) }       qr/2 groups/,
		'empty array: croaks "need at least 2 groups"';
	throws_ok { oneway_test([[1, 2]]) } qr/2 groups/,
		'single group: croaks "need at least 2 groups"';

	throws_ok { oneway_test([[1], [2, 3]]) } qr/2 observations/,
		'array: a group with <2 observations dies';
	throws_ok { oneway_test({a => [1], b => [2, 3]}) } qr/2 observations/,
		'hash: a group with <2 observations dies';

	throws_ok { oneway_test(42) } qr/hash or array reference/,
		'non-reference first argument dies';
	throws_ok { oneway_test({a => 1, b => 2}) } qr/array ref/,
		'hash whose values are not array refs dies';
}

#
# A clean run still produces the documented Welch one-way result.
#
{
	my $res = oneway_test(\%ok_groups);
	is ref($res), 'HASH', 'clean run returns a hash ref';

	is        $res->{Group}{Df},        1,                'factor Df is 1 (k-1)';
	is_approx $res->{Group}{'F value'}, 177.504798464491, 'Welch F value', 1e-4;
	is_approx $res->{Residuals}{Df},    9.81767348326473, 'residual Df is fractional (Welch)', 1e-3;
	ok        $res->{Group}{'Pr(>F)'} < 1e-3,             'p-value is tiny';

	is_approx $res->{group_stats}{mean}{yield}, 5.03333333333333, 'group mean (yield)';
	is_approx $res->{group_stats}{mean}{ctrl},  0.5,              'group mean (ctrl)';
	is $res->{group_stats}{size}{yield}, 6, 'group size (yield)';
	is $res->{group_stats}{size}{ctrl},  6, 'group size (ctrl)';
}

# Leak guards. Test::LeakTrace tracks Perl SV leaks; a successful call and a
# caught error must not leak scalars. (Raw C-buffer leaks on the croak paths
# are not visible here -- those need a C checker such as valgrind.)
#
unless ($INC{'Devel/Cover.pm'}) {
	no_leaks_ok { oneway_test(\%ok_groups) } 'no SV leak on a successful run';
	no_leaks_ok { eval { oneway_test([[1], [2, 3]]) } } 'no SV leak on a croak path';
}

done_testing;
