#!/usr/bin/env perl
#
# Regression guard for how sum(), min(), max(), mean(), sd(), var(),
# quantile(), cor() and cov() read their input.
#
# 0.302 stopped calling av_fetch() once per element in all nine and now walks
# AvARRAY() directly, which is only sound for an SV that already holds a
# number and carries neither magic nor a reference.  Everything else has to
# fall back to av_fetch(), and the two routes have to be the same function.
# They will not diverge loudly if they diverge: the fast path returns a
# plausible number computed over the wrong values.
#
# So the shape of this file is: build the same data as a plain array (which
# takes the AvARRAY() scan) and as something the scan must refuse, and require
# identical answers.  What the scan refuses is enumerated in section B and is
# meant to be exhaustive over the ways a perl array element can fail to be a
# plain number -- add to it rather than trusting that the list is complete.
#
# It also pins three specific defects fixed in 0.302:
#
#   * min() counted its arguments in an `unsigned short int`, so min(@x) on a
#     list of more than 65535 scalars wrapped the counter and looped forever
#     (section A).  power_t_test() had the same counter; it takes named pairs
#     so it was not reachable, and is checked here anyway.
#   * av_fetch() on a tied array returns a mortal PVLV that only acquires the
#     element's value once mg_get() has run on it, so testing SvOK() first
#     reported every element of every tied array as undef.  sum(\@tied)
#     croaked "undefined value at array ref index 0" (section C).
#   * cor() computed Pearson from raw cross-products, which cancels
#     catastrophically on an off-centre column: it returned NaN for a column
#     with mean 1e9 and spread 0.05 (section F, and the frozen R values in
#     t/var_sd_cov.R.t).
#
# There is no timing assertion here.  The performance work these changes were
# made for is not testable on a shared smoker; what is testable is that the
# faster route computes the same thing, which is all of the above.

require 5.010;
use strict;
use warnings FATAL => 'all';
use Test::More;
use Config;
use Stats::LikeR qw(sum min max mean sd var quantile cor cov);

# A. the argument counter.
#
# 70_000 is past 65_535 and nothing else; the values are 1..n so every answer
# is a closed form and a wrapped counter cannot accidentally produce it.
#
# A regression here is an infinite loop, not a wrong answer, so the calls run
# under alarm() where the platform has one.  Without that guard a smoker would
# hang instead of failing.
my $CAN_ALARM = $Config{d_alarm} && $^O ne 'MSWin32';

sub with_timeout {
	my ( $secs, $what, $code ) = @_;
	return $code->() unless $CAN_ALARM;
	my @r = eval {
		local $SIG{ALRM} = sub { die "TIMEOUT\n" };
		alarm $secs;
		my @v = $code->();
		alarm 0;
		@v;
	};
	my $err = $@;
	alarm 0;
	die "$what did not finish in ${secs}s -- the argument counter has wrapped again\n"
		if $err && $err eq "TIMEOUT\n";
	die $err if $err;
	return wantarray ? @r : $r[0];
}

{
	my $n = 70_000;
	my @a = ( 1 .. $n );
	my $exp_sum = $n * ( $n + 1 ) / 2;

	is( with_timeout( 30, 'min(@a)',  sub { min(@a) } ),  1,        'min over 70k stack arguments' );
	is( with_timeout( 30, 'max(@a)',  sub { max(@a) } ),  $n,       'max over 70k stack arguments' );
	is( with_timeout( 30, 'sum(@a)',  sub { sum(@a) } ),  $exp_sum, 'sum over 70k stack arguments' );
	is( with_timeout( 30, 'mean(@a)', sub { mean(@a) } ), ( $n + 1 ) / 2, 'mean over 70k stack arguments' );

	# sd of 1..n is sqrt(n(n+1)/12); check it agrees with the array-ref form
	# rather than re-deriving it, so this stays a test of the counter.
	my $sd_list = with_timeout( 30, 'sd(@a)',  sub { sd(@a) } );
	my $sd_ref  = sd( \@a );
	cmp_ok( abs( $sd_list - $sd_ref ), '<', 1e-9, 'sd over 70k stack arguments matches the array-ref form' );

	my $var_list = with_timeout( 30, 'var(@a)', sub { var(@a) } );
	cmp_ok( abs( $var_list - var( \@a ) ), '<', 1e-6, 'var over 70k stack arguments matches the array-ref form' );

	# power_t_test() carried the same counter.  It takes named pairs, so this
	# is a sanity call rather than a 65k-argument one.
	my $pt = with_timeout( 30, 'power_t_test', sub {
		Stats::LikeR::power_t_test( n => 30, delta => 0.5, sd => 1, 'sig_level' => 0.05 ) } );
	ok( ref $pt, 'power_t_test still returns after its counter was widened' );
}

# B. the kinds of element the AvARRAY() scan must refuse.
#
# Each entry builds an array holding the values 1, 2, 3, 4 in some
# representation, so every function has the same right answer whichever route
# it took.  `plain` is the fast path; everything else has to reach the same
# numbers through av_fetch().
{
	package t::Tied::Array;
	require Tie::Array;
	our @ISA = ('Tie::StdArray');
}
{
	package t::Tied::Scalar;
	require Tie::Scalar;
	our @ISA = ('Tie::StdScalar');
}
{
	# 0+ overload: SvNV() on one of these has to run perl, which is exactly
	# why the scan refuses any SVf_ROK element.
	package t::Num;
	use overload '0+' => sub { $_[0]{v} }, fallback => 1;
	sub new { my ( $c, $v ) = @_; return bless { v => $v }, $c }
}

my @WANT = ( 1, 2, 3, 4 );

my %SHAPE = (
	plain_nv => sub { [ 1.0, 2.0, 3.0, 4.0 ] },
	plain_iv => sub { [ 1, 2, 3, 4 ] },
	# IVs above IV_MAX are stored as UVs (SVf_IVisUV), a separate branch of
	# the scan's value read.  Offset so the answers still come out 1..4.
	large_uv => sub {
		my $big = 18446744073709551610;    # > IV_MAX on a 64-bit perl
		return [ map { $big } 1 .. 4 ];
	},
	strings     => sub { [ '1', '2', '3', '4' ] },
	string_frac => sub { [ '1.0', '2.0', '3.0', '4.0' ] },
	negatives   => sub { [ -1, -2, -3, -4 ] },
	overloaded  => sub { [ map { t::Num->new($_) } @WANT ] },
	tied_elems  => sub {
		my @a = ( 0, 0, 0, 0 );
		for my $i ( 0 .. 3 ) { tie $a[$i], 't::Tied::Scalar'; $a[$i] = $WANT[$i] }
		return \@a;
	},
	# One magical element in the middle: the scan takes the prefix, stops,
	# and the fallback has to finish the rest correctly.
	magic_in_middle => sub {
		my @a = ( 1, 2, 0, 4 );
		tie $a[2], 't::Tied::Scalar';
		$a[2] = 3;
		return \@a;
	},
	# IV, NV and PV in one column: the scan takes the IV and NV elements from
	# their flags and has to hand the string to the fallback.
	mixed_widths => sub { [ 1, 2.0, '3', 4 ] },
);

sub tied_copy {
	my ($x) = @_;
	my @t;
	tie @t, 't::Tied::Array';
	@t = @$x;
	return \@t;
}

for my $name ( sort keys %SHAPE ) {
	my $x = $SHAPE{$name}->();

	if ( $name eq 'large_uv' ) {
		# All four elements equal, so only the constant-column answers apply.
		# min() and max() are declared to return NV, so a UV this large comes
		# back rounded to the nearest NV -- compare numerically, not as a
		# string.  What is being checked here is the SVf_IVisUV branch of the
		# scan's value read: reading it as a signed IV would give -6.
		my $big = $x->[0];
		cmp_ok( abs( sum($x) - 4 * $big ), '<=', abs( 4 * $big ) * 1e-15, "$name: sum" );
		cmp_ok( abs( min($x) - $big ), '<=', abs($big) * 1e-15, "$name: min" );
		cmp_ok( abs( max($x) - $big ), '<=', abs($big) * 1e-15, "$name: max" );
		cmp_ok( min($x), '>', 0, "$name: min read the UV unsigned, not as a negative IV" );
		is( var($x), 0, "$name: var of a constant column is 0" );
		next;
	}

	my @w = $name eq 'negatives' ? map { -$_ } @WANT : @WANT;
	my $s = 0; $s += $_ for @w;

	cmp_ok( abs( sum($x) - $s ), '<', 1e-12, "$name: sum" );
	is( min($x), ( sort { $a <=> $b } @w )[0],  "$name: min" );
	is( max($x), ( sort { $a <=> $b } @w )[-1], "$name: max" );
	cmp_ok( abs( mean($x) - $s / 4 ), '<', 1e-12, "$name: mean" );
	# var(1,2,3,4) == var(-1,-2,-3,-4) == 5/3
	cmp_ok( abs( var($x) - 5 / 3 ), '<', 1e-12, "$name: var" );
	cmp_ok( abs( sd($x) - sqrt( 5 / 3 ) ), '<', 1e-12, "$name: sd" );

	my $q = quantile($x);
	cmp_ok( abs( $q->{'50%'} - ( $w[1] + $w[2] ) / 2 ), '<', 1e-12, "$name: quantile median" );

	# cor/cov against a plain partner: exercises av_extract_or_nan()'s
	# re-entry into the scan after each element it could not take.
	#
	# Overloaded objects are excluded, and are checked separately below.
	# cor() and cov() decide what is numeric with looks_like_number(), which
	# reports false for any reference -- an overloaded 0+ included -- so they
	# read a column of those as all-NA.  That predates 0.302 and is a
	# different question from how the column is walked; it is asserted rather
	# than quietly changed here.
	next if $name eq 'overloaded';
	my $y = [ 2, 4, 6, 9 ];
	cmp_ok( abs( cov( $x, $y ) - cov( [@w], $y ) ), '<', 1e-12, "$name: cov matches the plain column" );
	cmp_ok( abs( cor( $x, $y ) - cor( [@w], $y ) ), '<', 1e-12, "$name: cor matches the plain column" );
}

# cor()/cov() and overloaded objects: current behaviour, pinned so that
# changing it has to be deliberate.  looks_like_number() is false for a
# reference, so every element reads as NA, cov() has nothing left to pair and
# returns NaN, and cor() reaches its zero-variance croak.
{
	my $o = [ map { t::Num->new($_) } @WANT ];
	my $y = [ 2, 4, 6, 9 ];
	my $c = cov( $o, $y );
	ok( $c != $c, 'cov: a column of overloaded objects reads as all-NA (NaN)' );
	eval { cor( $o, $y ); 1 };
	like( $@, qr/standard deviation of x is 0/,
		'cor: a column of overloaded objects reaches the zero-variance croak' );

	# sum()/min()/max() do honour the overload, via SvNV().  The two families
	# genuinely disagree; this records which is which.
	is( sum($o), 10, 'sum: does honour a 0+ overload' );
}

# C. a wholly tied array.  Its elements do not exist until FETCH has run, so
#    the scan must not touch it at all and the fallback must apply get magic.
#    Every one of these croaked before 0.302.
{
	my $x = [ 1, 2, 3, 4, 5, 6, 7, 8 ];
	my $t = tied_copy($x);
	my $y = [ 3, 1, 4, 1, 5, 9, 2, 6 ];

	is( sum($t),  sum($x),  'tied array: sum' );
	is( min($t),  min($x),  'tied array: min' );
	is( max($t),  max($x),  'tied array: max' );
	is( mean($t), mean($x), 'tied array: mean' );
	is( var($t),  var($x),  'tied array: var' );
	is( sd($t),   sd($x),   'tied array: sd' );
	is_deeply( quantile($t), quantile($x), 'tied array: quantile' );
	is( cov( $t, $y ), cov( $x, $y ), 'tied array: cov' );
	is( cor( $t, $y ), cor( $x, $y ), 'tied array: cor' );
	is( cov( $t, tied_copy($y) ), cov( $x, $y ), 'tied array: cov with both sides tied' );
}

# D. holes and undef.
#
# sum() and friends croak on an undef element; quantile() drops it, and
# cor()/cov() treat it as NA and drop the pair.  Those are three different
# documented behaviours and the fast path must not change any of them.
{
	my @a = ( 1, 2, 3 );
	$a[5] = 6;    # leaves $a[3] and $a[4] as holes

	for my $fn ( [ 'sum', \&sum ], [ 'min', \&min ], [ 'max', \&max ],
		[ 'mean', \&mean ], [ 'sd', \&sd ], [ 'var', \&var ] ) {
		eval { $fn->[1]->( \@a ); 1 };
		like( $@, qr/undefined value at array ref index 3/,
			"$fn->[0]: croaks on a hole, naming its index" );
	}

	# undef written explicitly, not a hole
	my @u = ( 1, 2, undef, 4 );
	eval { sum( \@u ); 1 };
	like( $@, qr/undefined value at array ref index 2/, 'sum: croaks on an explicit undef' );

	# quantile drops them
	my $q = quantile( [ 1, 2, undef, 3, 4 ] );
	my $r = quantile( [ 1, 2, 3, 4 ] );
	is_deeply( $q, $r, 'quantile: drops undef and matches the compacted column' );

	# cor and cov propagate an incomplete pair, as R's do at their default
	# use = "everything". Verified against R 4.6.1:
	#     cov(c(1,2,NA,4), c(2,4,99,8))  ->  NA
	#     cor(c(1,2,NA,4), c(2,4,99,8))  ->  NA
	# cov() used to compact to the pairwise-complete observations here and
	# return 4.6666..., which is what this test asserted; it was the only one
	# of the three correlation entry points that did not match its R
	# counterpart. cor_test() still drops them, because R's cor.test() runs
	# complete.cases() -- that asymmetry is R's, not this module's.
	like( cov( [ 1, 2, undef, 4 ], [ 2, 4, 99, 8 ] ), qr/^-?nan$/i,
		'cov: an incomplete pair makes the answer NaN, as in R' );
	like( cor( [ 1, 2, undef, 4 ], [ 2, 4, 99, 8 ] ), qr/^-?nan$/i,
		'cor: an incomplete pair makes the answer NaN, as in R' );
	# and a complete column still gives the value it always did. R 4.6.1:
	#     cov(c(1,2,4), c(2,4,8))  ->  4.666666666666667
	ok( abs( cov( [ 1, 2, 4 ], [ 2, 4, 8 ] ) - 4.666666666666667 ) < 1e-12,
		'cov: a complete column is unaffected, and matches R' );
}

# E. an element whose get magic mutates the array it lives in.
#
# This is the hazard that makes the AvARRAY() walk conditional in the first
# place: perl running inside SvNV() may push to the array and realloc the very
# block being walked.  The scan refuses magical elements precisely so this
# cannot happen, and the loop bound is taken before any of it runs.
#
# The assertion is that the call completes with the answer for the array as it
# was on entry -- not that the mutation is visible, which it deliberately is
# not.
{
	package t::Grower;
	require Tie::Scalar;
	our @ISA = ('Tie::StdScalar');
	our $TARGET;
	sub FETCH {
		my ($self) = @_;
		push @$TARGET, 1000 .. 1200 if $TARGET;    # realloc the AvARRAY block
		return $$self;
	}
}

{
	my @a = ( 1, 2, 0, 4 );
	tie $a[2], 't::Grower';
	$a[2] = 3;
	local $t::Grower::TARGET = \@a;

	my $got = sum( \@a );
	# 1 + 2 + 3 + 4 over the four elements the array had on entry.
	is( $got, 10, 'sum: a get-magic element that grows the array does not corrupt the walk' );
	ok( scalar @a > 4, 'the growing element really did push onto the array' );
}

# F. the correlation cancellation, as a property rather than a frozen value.
#
# cor() is invariant under an affine change of location: adding a constant to
# every element of a column must not change it.  The raw cross-product form
# this replaced failed that badly enough to return NaN.  The frozen R values
# for the same column are in t/var_sd_cov.R.t.
{
	my @base = map { $_ / 1024 } 0 .. 99;
	my @y    = map { ( $_ % 13 ) / 8 } 0 .. 99;
	my $r0   = cor( \@base, \@y );

	for my $shift ( 1e3, 1e6, 1e9 ) {
		my @shifted = map { $shift + $_ } @base;
		my $r = cor( \@shifted, \@y );
		ok( $r == $r, "cor is not NaN with a location shift of $shift" );
		cmp_ok( abs( $r - $r0 ), '<', 1e-9,
			"cor is invariant under a location shift of $shift" );
	}

	# cov shifts the same way, and its scale is unchanged too.
	my $c0 = cov( \@base, \@y );
	for my $shift ( 1e3, 1e6, 1e9 ) {
		my @shifted = map { $shift + $_ } @base;
		cmp_ok( abs( cov( \@shifted, \@y ) - $c0 ), '<', abs($c0) * 1e-9,
			"cov is invariant under a location shift of $shift" );
	}

	# The same invariance for var/sd, which is what the two-pass form buys.
	my $v0 = var( \@base );
	for my $shift ( 1e3, 1e6, 1e9 ) {
		my @shifted = map { $shift + $_ } @base;
		cmp_ok( abs( var( \@shifted ) - $v0 ), '<', abs($v0) * 1e-9,
			"var is invariant under a location shift of $shift" );
	}
}

# G. quantile's partial sort.
#
# quantile() no longer orders the whole column; it places only the order
# statistics its probs actually read.  A partial sort that places the wrong
# element returns a number from the right column and the wrong rank, so the
# check is against a fully sorted copy, at every rank, on a column with ties.
{
	# Dyadic values with deliberate ties: ties are what decide where an order
	# statistic lands, and a mispartitioning select loses them first.
	my @x = map { ( ( $_ * 37 ) % 101 ) / 16 } 0 .. 500;
	my @sorted = sort { $a <=> $b } @x;
	my $n = scalar @x;

	# R reg-tests-1a.R: quantile(x, probs = ((1:n)-1)/(n-1)) == sort(x).
	my $probs = [ map { $_ / ( $n - 1 ) } 0 .. $n - 1 ];
	my $q = quantile( \@x, probs => $probs );
	my $bad = 0;
	for my $i ( 0 .. $n - 1 ) {
		my $p   = $i / ( $n - 1 );
		my $pct = $p * 100;
		my $key = ( abs( $pct - sprintf( '%.0f', $pct ) ) < 1e-9 )
			? sprintf( '%.0f%%', $pct )
			: sprintf( '%.1f%%', $pct );
		next unless exists $q->{$key};
		$bad++ if abs( $q->{$key} - $sorted[$i] ) > 1e-12;
	}
	is( $bad, 0, 'quantile: every requested rank matches a full sort (R reg-tests-1a.R)' );

	# A single extreme prob must still place the true min and max.
	my $q0 = quantile( \@x, probs => [0] );
	my $q1 = quantile( \@x, probs => [1] );
	is( $q0->{'0%'},   $sorted[0],  'quantile: p=0 places the true minimum' );
	is( $q1->{'100%'}, $sorted[-1], 'quantile: p=1 places the true maximum' );

	# All-identical column: 602 copies is R PR#16672's case and is also what
	# makes a naive quicksort go quadratic.
	my $flat = quantile( [ (-0.00090419678460984) x 602 ] );
	for my $k ( sort keys %$flat ) {
		is( $flat->{$k}, -0.00090419678460984, "quantile: constant column, $k" );
	}
}

done_testing();
