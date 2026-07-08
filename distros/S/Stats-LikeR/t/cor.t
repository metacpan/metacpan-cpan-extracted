#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
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

# The two arrays that exposed the size_t underflow in kendall_tau_b:
# C = 9 concordant, D = 19 discordant pairs.  Pre-fix, (NV)(C - D) was
# evaluated in unsigned arithmetic (9 - 19 wraps to ~1.8e19) before the
# cast, yielding ~6.6e17 instead of -10/28.  See kendall_tau_b().
my @dG   = (-7.765, -9.328, -10.326, -9.038, -9.608, -9.779, -9.975, -6.906);
my @rank = (154, 155, 161, 188, 76, 172, 173, 69);

#--------
# kendall tau-b — the regression case (discordant-dominant, negative tau)
#--------
my $tau = cor(\@dG, \@rank, 'kendall');
is_approx( $tau, -0.3571428571, 'kendall tau-b: discordant-dominant pair' );

# Explicit guard: the underflow bug produced ~6.6e17.  A correlation
# coefficient must always lie in [-1, 1]; assert it directly so any
# future regression is caught even if the magnitude drifts.
ok( $tau >= -1.0 && $tau <= 1.0, 'kendall tau-b: result stays in [-1, 1]' );
ok( $tau < 0, 'kendall tau-b: sign is negative when discordant pairs dominate' );

no_leaks_ok {
	eval {
		cor(\@dG, \@rank, 'kendall')
	}
} 'cor(kendall): no memory leaks' unless $INC{'Devel/Cover.pm'};

#--------
# pearson / spearman on the same arrays (compute_cor branch coverage)
#--------
is_approx( cor(\@dG, \@rank, 'pearson'),  -0.4889102301, 'pearson on same arrays' );
is_approx( cor(\@dG, \@rank, 'spearman'), -0.4761904762, 'spearman on same arrays' );
is_approx( cor(\@dG, \@rank),             -0.4889102301, 'default method is pearson' );

no_leaks_ok {
	eval {
		cor(\@dG, \@rank, 'pearson')
	}
} 'cor(pearson): no memory leaks' unless $INC{'Devel/Cover.pm'};
no_leaks_ok {
	eval {
		cor(\@dG, \@rank, 'spearman')
	}
} 'cor(spearman): no memory leaks' unless $INC{'Devel/Cover.pm'};

#--------
# kendall boundary cases: pure concordant (+1), pure discordant (-1),
# and self-correlation (+1) — exercises the C, D, and diagonal paths.
#--------
is_approx( cor([1,2,3,4], [10,20,30,40], 'kendall'),  1, 'kendall: perfectly concordant = +1' );
is_approx( cor([1,2,3,4], [40,30,20,10], 'kendall'), -1, 'kendall: perfectly discordant = -1' );
is_approx( cor(\@dG, \@dG, 'kendall'),                1, 'kendall: self-correlation = +1' );

# Ties: exercises tie_x / tie_y accumulation in the denominator.
# x has a tie on the first pair, y is strictly increasing.
is_approx( cor([1,1,2,3], [1,2,3,4], 'kendall'), 0.9128709292, 'kendall tau-b: with ties on x' );

no_leaks_ok {
	eval {
		cor([1,1,2,3], [1,2,3,4], 'kendall')
	}
} 'cor(kendall, ties): no memory leaks' unless $INC{'Devel/Cover.pm'};

#--------
# error paths
#--------
dies_ok { cor(\@dG, [1,2,3], 'kendall') } 'cor: length mismatch dies';
dies_ok { cor(\@dG, \@rank, 'bogus') }    'cor: unknown method dies';
dies_ok { cor([(5) x 8], \@rank, 'kendall') } 'cor: zero-variance x dies';

done_testing();
