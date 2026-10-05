#!/usr/bin/env perl

require 5.010;
use strict;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # dies_ok / lives_ok
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

# Data set from R's ?wilcox.test man page.
my @x = (1.83,  0.50,  1.62,  2.48, 1.68, 1.88, 1.55, 3.06, 1.30);
my @y = (0.878, 0.647, 0.598, 2.05, 1.06, 1.29, 1.06, 3.14, 1.29);

# wilcox_test: agreement with R
# Two-sample rank sum. The y values contain ties; since R 4.6.0 that is no
# longer a reason to give up on the exact test -- R conditions on the observed
# ranks (Streitberg-Roehmel) and so do we.
my $rs = wilcox_test(\@x, \@y);
is_approx( $rs->{statistic}, 58,                  'wilcox_test: two-sample W statistic = 58', 0 );
is_approx( $rs->{'p_value'},   0.1299053887289181,  'wilcox_test: two-sample p matches R', 1e-14 );
is( $rs->{method}, 'Wilcoxon rank sum exact test',
	'wilcox_test: two-sample method string' );
is( $rs->{alternative}, 'two.sided', 'wilcox_test: alternative echoed' );
is( $rs->{'statistic_name'}, 'W', 'wilcox_test: two-sample statistic is named W' );

# The normal approximation is still what exact => 0 asks for.
my $rs_approx = wilcox_test(\@x, \@y, exact => 0);
is_approx( $rs_approx->{'p_value'}, 0.13291945818531881,
	'wilcox_test: two-sample approximate p matches R', 1e-14 );
is( $rs_approx->{method}, 'Wilcoxon rank sum test with continuity correction',
	'wilcox_test: exact => 0 method string' );

# Two-sample exact (no ties, fully separated): p = 2/70.
my $ex = wilcox_test([1,2,3,4], [5,6,7,8]);
is_approx( $ex->{statistic}, 0,          'wilcox_test: separated exact W = 0', 0 );
is_approx( $ex->{'p_value'},   0.02857143, 'wilcox_test: separated exact p = 2/70', 1e-7 );
is( $ex->{method}, 'Wilcoxon rank sum exact test', 'wilcox_test: exact method selected' );

# Paired signed-rank, one-sided greater (exact): V = 40, p = 10/512.
my $pr = wilcox_test(\@x, \@y, paired => 1, alternative => 'greater');
is_approx( $pr->{statistic}, 40,         'wilcox_test: paired V statistic = 40', 0 );
is_approx( $pr->{'p_value'},   0.01953125, 'wilcox_test: paired exact p = 10/512', 1e-9 );
is( $pr->{method}, 'Wilcoxon signed rank exact test', 'wilcox_test: signed-rank exact method' );
is( $pr->{alternative}, 'greater', 'wilcox_test: paired alternative echoed' );

# One-sample location: shifting by mu equals testing the pre-shifted data.
my @shift = map { $_ - 6 } (1..11);
my $shifted_mu = wilcox_test([1..11], mu => 6);
my $shifted_in = wilcox_test(\@shift);
is_approx( $shifted_mu->{statistic}, $shifted_in->{statistic},
	'wilcox_test: mu shift matches pre-shifted data (V)', 0 );
is_approx( $shifted_mu->{'p_value'}, $shifted_in->{'p_value'},
	'wilcox_test: mu shift matches pre-shifted data (p)', 1e-12 );

#		wilcox_test: options
# Continuity correction changes the approximate p-value and the method label.
# (It only applies to the approximation, so exact => 0 has to be in play.)
my $corr_on  = wilcox_test(\@x, \@y, exact => 0, correct => 1);
my $corr_off = wilcox_test(\@x, \@y, exact => 0, correct => 0);
ok( abs($corr_on->{'p_value'} - $corr_off->{'p_value'}) > 1e-9,
	'wilcox_test: correct=>0 differs from correct=>1' );
is_approx( $corr_off->{'p_value'}, 0.12189099149676097,
	'wilcox_test: correct=>0 matches R', 1e-14 );
is( $corr_off->{method}, 'Wilcoxon rank sum test',
	'wilcox_test: correct=>0 drops continuity correction' );

# exact can be forced off ...
my $forced_off = wilcox_test([1,2,3,4], [5,6,7,8], exact => 0);
is( $forced_off->{method}, 'Wilcoxon rank sum test with continuity correction',
	'wilcox_test: exact=>0 forces the approximation' );

# ... and forcing it on with ties is answered exactly, in silence.
# R: wilcox.test(c(1,2,2,3), c(4,5,5,6), exact = TRUE) -> W = 0, p = 2/70
{
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	my $forced_on = wilcox_test([1,2,2,3], [4,5,5,6], exact => 1);
	is( scalar(@w), 0, 'wilcox_test: exact=>1 with ties no longer warns' );
	is_approx( $forced_on->{'p_value'}, 0.028571428571428571,
		'wilcox_test: exact=>1 with ties matches R', 1e-14 );
	is( $forced_on->{method}, 'Wilcoxon rank sum exact test',
		'wilcox_test: exact=>1 with ties stays exact' );
}

# Named x / y override the positional slots.
my $named = wilcox_test(x => \@x, 'y' => \@y);
is_approx( $named->{statistic}, $rs->{statistic},
	'wilcox_test: named form equals positional form', 0 );

# Non-numeric and undefined cells are dropped before ranking.
my $dirty = wilcox_test([1,2,undef,3,'NA',4], [5,'x',6,7,8,undef]);
is_approx( $dirty->{statistic}, $ex->{statistic}, 'wilcox_test: NA/undef dropped (W)', 0 );
is_approx( $dirty->{'p_value'},   $ex->{'p_value'},   'wilcox_test: NA/undef dropped (p)', 1e-12 );

# wilcox_test: regressions
# All values identical. The exact path handles this without a special case:
# R gives W = 4.5, p = 1 from the (degenerate) permutation distribution.
{
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	my $flat = wilcox_test([5,5,5], [5,5,5]);
	is_approx( $flat->{statistic}, 4.5, 'wilcox_test: identical samples give W = 4.5', 0 );
	is_approx( $flat->{'p_value'},   1,   'wilcox_test: identical samples give p = 1', 0 );
	is( scalar(@w), 0, 'wilcox_test: identical samples do not warn on the exact path' );
}
# The approximation still has nothing to divide by, and says so rather than
# dividing by zero. (R reports NaN here; we warn and report p = 1.)
{
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	my $flat = wilcox_test([5,5,5], [5,5,5], exact => 0);
	is_approx( $flat->{'p_value'}, 1, 'wilcox_test: zero variance gives p = 1 (not 0/NaN)', 0 );
	ok( $flat->{'p_value'} == $flat->{'p_value'}, 'wilcox_test: zero-variance p is not NaN' );
	ok( scalar(@w) >= 1, 'wilcox_test: zero-variance case warns' );
}

# Statistic exactly on its mean: two-sided correction must be 0 (R uses sign(z)*0.5).
my $at_mean = wilcox_test([1,4], [2,3], exact => 0);
is_approx( $at_mean->{'p_value'}, 1, 'wilcox_test: statistic at mean gives p = 1', 1e-12 );

# An invalid alternative is rejected instead of silently running two-sided.
eval { wilcox_test(\@x, \@y, alternative => 'twosided') };
like( $@, qr/alternative/, 'wilcox_test: invalid alternative dies' );
foreach my $alt (qw(two.sided less greater)) {
	lives_ok { wilcox_test(\@x, \@y, alternative => $alt) }
		"wilcox_test: alternative '$alt' accepted";
}

#	wilcox_test: argument validation
eval { wilcox_test(x => 42) };
like( $@, qr/ARRAY reference/, 'wilcox_test: non-arrayref x dies' );
dies_ok { wilcox_test() }                            'wilcox_test: missing x dies' ;
dies_ok { wilcox_test([]) }                          'wilcox_test: empty x dies' ;
dies_ok { wilcox_test(\@x, \@y, 'paired') }          'wilcox_test: odd trailing args die' ;
dies_ok { wilcox_test(\@x, 'bogus' => 1) }           'wilcox_test: unknown named arg dies' ;
dies_ok { wilcox_test([1,2,3], [1,2], paired => 1) } 'wilcox_test: paired length mismatch dies' ;

#		wilcox_test: output shape
my $shape = wilcox_test(\@x, \@y);
is( ref $shape, 'HASH', 'wilcox_test: returns a hashref' );
foreach my $k (qw(statistic statistic_name p_value method alternative
				  null_value null_value_name)) {
	ok( exists $shape->{$k}, "wilcox_test: output has '$k'" );
}

# wilcox_test: tied arrays.  An element of a tied array has no value until its
# FETCH runs, which is get magic; the element loops used to test SvOK() first,
# so every element read as undef and a tied x croaked that it was empty.  Each
# element is FETCHed exactly once, and every path gives what the plain arrays
# give.
{
	package CountingArray;
	require Tie::Array;
	our @ISA = ('Tie::StdArray');
	our $fetches = 0;
	sub FETCH { $fetches++; my $self = shift; return $self->SUPER::FETCH(@_) }
}
{
	tie my @tx, 'CountingArray'; @tx = @x;
	tie my @ty, 'CountingArray'; @ty = @y;
	foreach my $c (
		[ 'two-sample',            [],                         2 * @x ],
		[ 'two-sample, interval',  [ conf_int => 1 ],          undef ],
		[ 'paired',                [ paired => 1 ],            2 * @x ],
		[ 'asymptotic, interval',  [ exact => 0, conf_int => 1 ], undef ] ) {
		my ($what, $opts, $want_fetches) = @$c;
		local $CountingArray::fetches = 0;
		my $t = wilcox_test(\@tx, \@ty, @$opts);
		my $got_fetches = $CountingArray::fetches;
		is_deeply( $t, wilcox_test(\@x, \@y, @$opts), "wilcox_test: tied arrays, $what: same result as plain ones" );
		is( $got_fetches, $want_fetches, "wilcox_test: tied arrays, $what: one FETCH per element" )
			if defined $want_fetches;
	}
	is_deeply( wilcox_test(\@tx, conf_int => 1), wilcox_test(\@x, conf_int => 1),
		'wilcox_test: tied array, one-sample interval: same result as a plain one' );
}

# The messages that did not say which function they came from now do.
throws_ok { wilcox_test([undef, 'a']) } qr/^wilcox_test: not enough \(non-missing\) 'x' observations/,
	'wilcox_test: an all-missing x names the function';
throws_ok { wilcox_test([1, 2], [undef]) } qr/^wilcox_test: not enough 'y' observations/,
	'wilcox_test: an all-missing y names the function';
throws_ok { wilcox_test([1, 2, 3], [1, 2], paired => 1) } qr/^wilcox_test: 'x' and 'y' must have the same length/,
	'wilcox_test: a paired length mismatch names the function';

# A difference of two like-signed infinities is NaN, which R's sort() drops
# from the differences an exact interval is read from.  When every difference
# is one, there is nothing left to read; R itself stops earlier, in the
# p-value.  The interval is NaN, at level 0, with a warning.
{
	my $inf = 9 ** 9 ** 9;
	my @w;
	local $SIG{__WARN__} = sub { push @w, $_[0] };
	my $r = wilcox_test([$inf, $inf], [$inf], conf_int => 1);
	ok( scalar(grep { /every difference is Inf - Inf/ } @w), 'wilcox_test: all-NaN differences warn' );
	ok( $r->{'conf_int'}[0] != $r->{'conf_int'}[0] && $r->{'conf_int'}[1] != $r->{'conf_int'}[1],
		'wilcox_test: all-NaN differences give a NaN interval' );
	is( $r->{'conf_level'}, 0, 'wilcox_test: all-NaN differences give level 0' );
	ok( $r->{estimate} != $r->{estimate}, 'wilcox_test: all-NaN differences give a NaN estimate' );
}

# wilcox_test: memory
no_leaks_ok {
	eval { wilcox_test(\@x, \@y) }
} 'wilcox_test(): no memory leaks (two-sample approximation)' unless $INC{'Devel/Cover.pm'};
no_leaks_ok {
	eval { wilcox_test([1,2,3,4], [5,6,7,8]) }
} 'wilcox_test(): no memory leaks (two-sample exact)' unless $INC{'Devel/Cover.pm'};
no_leaks_ok {
	eval { wilcox_test(\@x, \@y, paired => 1, alternative => 'greater') }
} 'wilcox_test(): no memory leaks (paired exact)' unless $INC{'Devel/Cover.pm'};

# The interval paths allocate scratch on the save stack, and the exact scans
# keep one permutation table between trial shifts that is freed by hand.
my @tied_x = (1, 2, 2, 3, 3, 3, 4, 5);
my @tied_y = (2, 3, 3, 4, 4, 5, 6, 6, 7);
no_leaks_ok {
	eval { wilcox_test(\@tied_x, \@tied_y, conf_int => 1) }
} 'wilcox_test(): no memory leaks (two-sample exact interval with ties)' unless $INC{'Devel/Cover.pm'};
no_leaks_ok {
	eval { wilcox_test(\@tied_x, conf_int => 1, mu => 3) }
} 'wilcox_test(): no memory leaks (one-sample exact interval with ties and zeroes)' unless $INC{'Devel/Cover.pm'};
no_leaks_ok {
	eval { wilcox_test(\@x, \@y, conf_int => 1) }
} 'wilcox_test(): no memory leaks (two-sample exact interval)' unless $INC{'Devel/Cover.pm'};
no_leaks_ok {
	eval { wilcox_test(\@x, \@y, exact => 0, conf_int => 1, digits_rank => 2) }
} 'wilcox_test(): no memory leaks (two-sample asymptotic interval)' unless $INC{'Devel/Cover.pm'};
no_leaks_ok {
	eval { wilcox_test(\@x, exact => 0, conf_int => 1) }
} 'wilcox_test(): no memory leaks (one-sample asymptotic interval)' unless $INC{'Devel/Cover.pm'};

done_testing();
