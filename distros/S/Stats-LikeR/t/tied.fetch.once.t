#!/usr/bin/env perl
require 5.010;
use strict;
use warnings FATAL => 'all';
use File::Spec;
use File::Temp 'tempdir';
use Scalar::Util 'refaddr';
use Stats::LikeR;
use Test::More;

# Imported at compile time for no_leaks_ok's (&;$) prototype, as t/tied.frames.t
# does. Absent module -> the leak check is skipped; everything else still runs.
my $HAVE_LEAKTRACE;
BEGIN {
	$HAVE_LEAKTRACE = eval {
		require Test::LeakTrace;
		Test::LeakTrace->import('no_leaks_ok');
		1;
	};
}

# A tied value is FETCHed at most once per call.
#
# t/tied.hashes.t and t/tied.frames.t check that a tied frame gives the same
# answer as the plain data it holds; this file checks what that answer costs.
# Up to 0.3212 most functions FETCHed a tied value more than once: every pass
# over a tied frame -- a shape probe (_df_shape, or the XS's look at the first
# value), a key count, a key union, the read itself -- FETCHed each row or
# column again, and a function that reads a tied column once to match or test
# on it and again to copy it out FETCHed every cell twice. drop_duplicates()
# on a HoA of tied columns fetched every cell twice, lm() and glm() fetched a
# tied frame's column once per row of the fit, and select_cols(), drop_cols(),
# hoh2hoa() and group_by() fetched each row of a tied HoH three times. The
# answers were right; a tie that does real work in FETCH (a database, a file)
# paid for it.
#
# Each case below ties the frame and every row or column it holds to a class
# that counts its FETCHes per key, makes one call, and requires that no key of
# any tied container was fetched twice. A key that is never fetched is fine:
# sample() reads only what it draws, vals() only its column. Where a function
# still refuses tied columns (lm, kruskal_test, aov, oneway_test and hoa2hoh;
# see t/tied.frames.t for the functions that take them) the frame is tied and
# its columns are plain.
#
# rename_cols() in void context renames the frame it is given, so it must work
# on the tied frame itself and is the one call not held to this; in any other
# context it is.
#
# Values invented for the test; R and SciPy have no tied containers.

my %N;	# refaddr of a tie object => { key => FETCH count }
{	package CountHash;
	require Tie::Hash;
	our @ISA = ('Tie::StdHash');
	sub FETCH { $N{ Scalar::Util::refaddr( $_[0] ) }{ $_[1] }++; return $_[0]->SUPER::FETCH( $_[1] ) }
}
{	package CountArray;
	require Tie::Array;
	our @ISA = ('Tie::StdArray');
	sub FETCH { $N{ Scalar::Util::refaddr( $_[0] ) }{ $_[1] }++; return $_[0]->SUPER::FETCH( $_[1] ) }
}
sub th { my %t; tie %t, 'CountHash'; %t = %{ $_[0] }; return \%t }
sub ta { my @t; tie @t, 'CountArray'; @t = @_; return \@t }

my $dir = tempdir( CLEANUP => 1 );
my %hoa = (
	'x'  => [ 1, 2, 3, 5, 4, 6 ],
	'y'  => [ 2, 1, 4, 3, 6, 5 ],
	'g'  => [qw(a a a b b b)],
	'id' => [ 1 .. 6 ],
);
my %hoh = map {
	my $i = $_;
	( "r$i" => { map { ( $_ => $hoa{$_}[ $i - 1 ] ) } keys %hoa } )
} 1 .. 6;
my @aoh    = map { $hoh{"r$_"} } 1 .. 6;
my %groups = ( 'a' => [ 1, 2, 3 ], 'b' => [ 4, 5, 7 ], 'c' => [ 9, 8, 11 ] );
my %counts = ( 'r1' => { 'a' => 10, 'b' => 20 }, 'r2' => { 'a' => 30, 'b' => 15 } );

# the frame and everything in it tied, or (the *_f forms) only the frame
sub t_hoa   { th( { map { ( $_ => ta( @{ $hoa{$_} } ) ) } keys %hoa } ) }
sub t_hoa_f { th( { map { ( $_ => [ @{ $hoa{$_} } ] ) } keys %hoa } ) }
sub t_hoh   { th( { map { ( $_ => th( $hoh{$_} ) ) } keys %hoh } ) }
sub t_aoh   { ta( map { th($_) } @aoh ) }
sub t_grp   { th( { map { ( $_ => ta( @{ $groups{$_} } ) ) } keys %groups } ) }
sub t_grp_f { th( { map { ( $_ => [ @{ $groups{$_} } ] ) } keys %groups } ) }
sub t_cnt   { th( { map { ( $_ => th( $counts{$_} ) ) } keys %counts } ) }

my $fit = lm( 'formula' => 'x ~ y', 'data' => \%hoa );
my $wt  = 0;
my @cases = (
	[ 'csort HoA',           sub { csort( t_hoa(), 'x' ) } ],
	[ 'csort HoH',           sub { csort( t_hoh(), 'x' ) } ],
	[ 'value_counts HoA',    sub { value_counts( t_hoa(), 'g' ) } ],
	[ 'value_counts HoH',    sub { value_counts( t_hoh() ) } ],
	[ 'kruskal_test',        sub { kruskal_test( t_grp_f() ) } ],
	[ 'merge HoA',           sub { merge( t_hoa(), { 'id' => [ 1, 2 ], 'z' => [ 5, 6 ] }, 'on' => 'id' ) } ],
	[ 'merge HoH',           sub { merge( t_hoh(), { 'id' => [ 1, 2 ], 'z' => [ 5, 6 ] }, 'on' => 'id' ) } ],
	[ 'merge AoH',           sub { merge( t_aoh(), { 'id' => [ 1, 2 ], 'z' => [ 5, 6 ] }, 'on' => 'id' ) } ],
	[ 'agg HoA',             sub { agg( t_hoa(), 'by' => ['g'], 'agg' => { 'x' => 'mean' } ) } ],
	[ 'drop_duplicates HoA', sub { drop_duplicates( t_hoa() ) } ],
	[ 'drop_duplicates AoH', sub { drop_duplicates( t_aoh() ) } ],
	[ 'hoa2aoh',             sub { hoa2aoh( t_hoa() ) } ],
	[ 'hoa2hoh',             sub { hoa2hoh( t_hoa_f(), 'id' ) } ],
	[ 'hoh2hoa',             sub { hoh2hoa( t_hoh() ) } ],
	[ 'col2col HoA',         sub { col2col( t_hoa(), 'cor', [ 'x', 'y' ] ) } ],
	[ 'col2col HoH',         sub { col2col( t_hoh(), 'cor', [ 'x', 'y' ] ) } ],
	[ 'col2col AoH',         sub { col2col( t_aoh(), 'cor', [ 'x', 'y' ] ) } ],
	[ 'lm HoA',              sub { lm( 'formula' => 'x ~ y', 'data' => t_hoa_f() ) } ],
	[ 'lm HoH',              sub { lm( 'formula' => 'x ~ y', 'data' => t_hoh() ) } ],
	[ 'lm AoH',              sub { lm( 'formula' => 'x ~ y', 'data' => t_aoh() ) } ],
	[ 'glm HoA',             sub { glm( 'formula' => 'x ~ y', 'data' => t_hoa_f() ) } ],
	[ 'predict HoA',         sub { predict( $fit, th( { 'y' => ta( 1, 2, 3 ) } ) ) } ],
	[ 'predict HoH',         sub { predict( $fit, th( { 'p' => th( { 'y' => 1 } ), 'q' => th( { 'y' => 2 } ) } ) ) } ],
	[ 'aov',                 sub { aov( t_grp_f() ) } ],
	[ 'oneway_test',         sub { oneway_test( t_grp_f() ) } ],
	[ 'p_adjust',            sub { p_adjust( th( { 'a' => ta( 0.01, 0.04, 0.03 ), 'b' => ta( 0.2, 0.5, 0.001 ) } ), 'BH' ) } ],
	[ 'chisq_test',          sub { chisq_test( t_cnt() ) } ],
	[ 'fisher_test',         sub { fisher_test( t_cnt() ) } ],
	[ 'sample hash',         sub { sample( t_grp(), 3 ) } ],
	[ 'sample array',        sub { sample( ta( 1 .. 6 ), 6 ) } ],
	[ 'group_by HoA',        sub { group_by( t_hoa(), 'x', 'g' ) } ],
	[ 'group_by HoH',        sub { group_by( t_hoh(), 'x', 'g' ) } ],
	[ 'filter HoA',          sub { filter( t_hoa(), col('x') > 2 ) } ],
	[ 'filter HoH',          sub { filter( t_hoh(), col('x') > 2 ) } ],
	[ 'filter AoH',          sub { filter( t_aoh(), col('x') > 2 ) } ],
	[ 'cfilter HoA',         sub { cfilter( t_hoa(), 'keep' => ['x'] ) } ],
	[ 'transpose',           sub { transpose( t_hoh() ) } ],
	[ 'vals HoA',            sub { vals( t_hoa(), 'x' ) } ],
	[ 'vals HoH',            sub { vals( t_hoh(), 'x' ) } ],
	[ 'vals AoH',            sub { vals( t_aoh(), 'x' ) } ],
	[ 'avals HoA',           sub { [ avals( t_hoa(), 'x' ) ] } ],
	[ 'avals HoH',           sub { [ avals( t_hoh(), 'x' ) ] } ],
	[ 'select_cols HoA',     sub { select_cols( t_hoa(), 'x' ) } ],
	[ 'select_cols HoH',     sub { select_cols( t_hoh(), 'x' ) } ],
	[ 'drop_cols HoH',       sub { drop_cols( t_hoh(), 'x' ) } ],
	[ 'rename_cols HoH',     sub { my $r = rename_cols( t_hoh(), 'x' => 'xx' ); $r } ],
	[ 'prcomp HoA',          sub { prcomp( th( { 'x' => ta( @{ $hoa{'x'} } ), 'y' => ta( @{ $hoa{'y'} } ) } ) ) } ],
	[ 'ljoin',               sub { my $h = { map { ( $_ => { %{ $hoh{$_} } } ) } keys %hoh }; ljoin( $h, th( { 'r1' => th( { 'new' => 1 } ) } ) ); $h } ],
	[ 'add_data',            sub { my $h = { map { ( $_ => { %{ $hoh{$_} } } ) } keys %hoh }; add_data( $h, th( { 'r1' => th( { 'new' => 1 } ) } ) ); $h } ],
	[ 'write_table HoA',     sub { write_table( t_hoa(), File::Spec->catfile( $dir, 'wt' . $wt++ . '.tsv' ), 'quiet' => 1, 'row_names' => 0 ); 1 } ],
);
for my $c (@cases) {
	my ( $name, $call ) = @$c;
	%N = ();
	my $ok = eval { $call->(); 1 };
	my @twice;
	for my $obj ( values %N ) {
		push @twice, map { "$_ x$obj->{$_}" } grep { $obj->{$_} > 1 } sort keys %$obj;
	}
	ok( $ok && !@twice, "$name: no tied value is FETCHed twice" )
		or diag( $ok ? "fetched more than once: @twice" : "died: $@" );
}

# The copies a call makes of a tied frame, and of its tied rows and columns,
# are mortal: nothing outlives the call, whether it returns or dies.
SKIP: {
	skip 'Test::LeakTrace not installed', 1 unless $HAVE_LEAKTRACE;
	skip 'Devel::Cover perturbs refcounts', 1 if $INC{'Devel/Cover.pm'};
	my ( $ta, $th, $to, $tg ) = ( t_hoa(), t_hoh(), t_aoh(), t_grp_f() );
	no_leaks_ok {
		merge( $ta, { 'id' => [ 1, 2 ], 'z' => [ 5, 6 ] }, 'on' => 'id' );
		merge( $to, $th, 'on' => 'id' );
		filter( $ta, col('x') > 2 );
		drop_duplicates($ta);
		agg( $ta, 'by' => ['g'], 'agg' => { 'x' => 'mean' } );
		lm( 'formula' => 'x ~ y', 'data' => $to );
		csort( $th, 'x' );
		select_cols( $th, 'x' );
		kruskal_test($tg);
		vals( $th, 'x' );
		eval { merge( $ta, $th, 'on' => 'nope' ) };	# dies after the copies are made
	} 'no leaks from copying a tied frame';
}

done_testing();
