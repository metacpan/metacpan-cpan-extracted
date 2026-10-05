#!/usr/bin/env perl
require 5.010;
use strict;
use warnings FATAL => 'all';
use File::Temp 'tempdir';
use File::Spec;
use Stats::LikeR;
use Test::More;
use Test::LeakTrace 'no_leaks_ok';

# Every XS function that walks a hash it was handed leaves that hash's each()
# position where it was. Up to 0.3212 each walk called hv_iterinit(), which
# resets the one iterator that each(), keys() and values() share, so a caller
# part-way through `while (my ($k, $v) = each %$df)` started again and saw keys
# twice. iter_keep() in LikeR.xs now saves the position before a walk and puts
# it back after it, croaks included.
#
# Each case starts an each() on one hash -- the table, a row of it, or another
# hash argument such as a model's coefficients -- calls the function, then
# drains the each() and checks that every key came back exactly once. Behaviour
# was invented for these tests rather than taken from R or SciPy, which have no
# shared hash iterator to disturb.
#
# Functions wrapped in perl (agg, select_cols, drop_cols, rename_cols,
# drop_duplicates, assign) are not here: their perl side calls keys() itself,
# which resets the iterator as perl's own keys() always does.

my $dir = tempdir( CLEANUP => 1 );

# 6 rows, 14 columns: x1..x12 numeric, id unique, g a two-level group.
my @rows = map {
	my $r = $_;
	+{ ( map { ( "x$_" => ( $r * $_ ) % 7 + $r ) } 1 .. 12 ), 'id' => $r, 'g' => $r <= 3 ? 'a' : 'b' }
} 1 .. 6;
sub hoa_of { my %h; for my $row (@_) { push @{ $h{$_} }, $row->{$_} for keys %$row } \%h }
sub copy_rows { [ map { +{%$_} } @rows ] }
sub hoh_of { my $i = 0; +{ map { ( 'r' . ++$i => $_ ) } @{ copy_rows() } } }
sub numeric_only { my $h = shift; +{ map { ( $_ => $h->{$_} ) } grep { /^x/ } keys %$h } }

# drain an each() and report [keys seen, keys seen more than once, keys in hash]
sub resume {
	my ( $h, $call ) = @_;
	keys %$h;	# start from a reset iterator
	my %seen;
	my ($first) = each %$h;
	$seen{$first}++;
	$call->();
	while ( my ($k) = each %$h ) { $seen{$k}++ }
	return [ scalar( keys %seen ), scalar( grep { $_ > 1 } values %seen ), scalar( keys %$h ) ];
}
sub resumes_ok {
	my ( $name, $h, $call ) = @_;
	my $r = resume( $h, $call );
	is_deeply( $r, [ $r->[2], 0, $r->[2] ], "$name: each() resumes, every key once" );
}

my $groups = { map { ( "grp$_" => [ map { $_ * $_ + $_ } 1 .. 4 + $_ ] ) } 1 .. 8 };
my $pvals  = { map { ( "set$_" => [ map { $_ / 40 } 1 .. 5 ] ) } 1 .. 8 };
my $counts = { map { my $r = $_; ( "row$r" => { map { ( "c$_" => 10 * $r + $_ ) } 1 .. 4 } ) } 1 .. 6 };	# cells of 10 or more: no small-count warning

# the table itself, as a HoA
{
	my $hoa = hoa_of(@rows);
	resumes_ok( 'filter HoA', $hoa, sub { filter( $hoa, col('x1') > 2 ) } );
	resumes_ok( 'hoa2aoh', $hoa, sub { hoa2aoh($hoa) } );
	resumes_ok( 'hoa2hoh', $hoa, sub { hoa2hoh( $hoa, 'id' ) } );
	resumes_ok( 'vals HoA', $hoa, sub { vals( $hoa, 'x1' ) } );
	resumes_ok( 'avals HoA', $hoa, sub { my @v = avals( $hoa, 'x1' ) } );
	resumes_ok( 'csort HoA', $hoa, sub { csort( $hoa, 'x1' ) } );
	resumes_ok( 'value_counts HoA', $hoa, sub { value_counts( $hoa, 'g' ) } );
	resumes_ok( 'group_by HoA', $hoa, sub { group_by( $hoa, 'x1', 'g' ) } );
	resumes_ok( 'col2col HoA', $hoa, sub { col2col( $hoa, 'sum', [ 'x1', 'x2' ] ) } );
	resumes_ok( 'lm HoA', $hoa, sub { lm( 'formula' => 'x1 ~ x2 + x3', 'data' => $hoa ) } );
	resumes_ok( 'merge HoA', $hoa, sub { merge( $hoa, { 'id' => [ 1, 2 ], 'z' => [ 5, 6 ] }, 'on' => 'id' ) } );
	resumes_ok( 'write_table HoA', $hoa, sub { write_table( $hoa, File::Spec->catfile( $dir, 'hoa.tsv' ), 'quiet' => 1 ) } );
	my $num = numeric_only($hoa);	# built here: numeric_only() calls keys(), which resets the iterator
	resumes_ok( 'prcomp HoA', $num, sub { prcomp($num) } );
	resumes_ok( 'lm HoA with y ~ .', $num, sub { lm( 'formula' => 'x1 ~ .', 'data' => $num ) } );
}
# the table as a HoH: the outer hash, and one of its rows
{
	my $hoh = hoh_of();
	for my $target ( [ 'table', $hoh ], [ 'row', $hoh->{'r3'} ] ) {
		my ( $what, $h ) = @$target;
		resumes_ok( "hoh2hoa ($what)", $h, sub { hoh2hoa($hoh) } );
		resumes_ok( "transpose ($what)", $h, sub { transpose($hoh) } );
		resumes_ok( "filter HoH ($what)", $h, sub { filter( $hoh, col('x1') > 2 ) } );
		resumes_ok( "csort HoH ($what)", $h, sub { csort( $hoh, 'x1' ) } );
		resumes_ok( "vals HoH ($what)", $h, sub { vals( $hoh, 'x1' ) } );
		resumes_ok( "value_counts HoH ($what)", $h, sub { value_counts($hoh) } );
		resumes_ok( "group_by HoH ($what)", $h, sub { group_by( $hoh, 'x1', 'g' ) } );
		resumes_ok( "col2col HoH ($what)", $h, sub { col2col( $hoh, 'sum', [ 'x1', 'x2' ] ) } );
		resumes_ok( "lm HoH ($what)", $h, sub { lm( 'formula' => 'x1 ~ x2', 'data' => $hoh ) } );
		resumes_ok( "merge HoH ($what)", $h, sub { merge( $hoh, $hoh, 'on' => 'id' ) } );
		resumes_ok( "write_table HoH ($what)", $h, sub { write_table( $hoh, File::Spec->catfile( $dir, 'hoh.tsv' ), 'quiet' => 1, 'row_names' => 'row' ) } );
	}
}
# the rows of an AoH
{
	my $aoh = copy_rows();
	my $row = $aoh->[2];
	resumes_ok( 'aoh2hoa (row)', $row, sub { aoh2hoa($aoh) } );
	resumes_ok( 'filter AoH (row)', $row, sub { filter( $aoh, col('x1') > 2 ) } );
	resumes_ok( 'csort AoH to AoA (row)', $row, sub { csort( $aoh, 'x1', 'aoa' ) } );
	resumes_ok( 'merge AoH (row)', $row, sub { merge( $aoh, $aoh, 'on' => 'id' ) } );
	resumes_ok( 'lm AoH (row)', $row, sub { lm( 'formula' => 'x1 ~ x2', 'data' => $aoh ) } );
	resumes_ok( 'write_table AoH (row)', $row, sub { write_table( $aoh, File::Spec->catfile( $dir, 'aoh.tsv' ), 'quiet' => 1 ) } );
	my $num = [ map { numeric_only($_) } @$aoh ];
	resumes_ok( 'prcomp AoH (row)', $num->[0], sub { prcomp($num) } );
	my $p = [ map { +{ 'a' => $_ / 10, 'b' => $_ / 20 } } 1 .. 5 ];
	resumes_ok( 'p_adjust AoH (row)', $p->[1], sub { my @q = p_adjust( $p, 'BH' ) } );
}
# other hash arguments
resumes_ok( 'oneway_test', $groups, sub { oneway_test($groups) } );
resumes_ok( 'kruskal_test', $groups, sub { kruskal_test($groups) } );
resumes_ok( 'aov (groups)', $groups, sub { aov($groups) } );
resumes_ok( 'p_adjust HoA', $pvals, sub { my @q = p_adjust( $pvals, 'BH' ) } );
resumes_ok( 'chisq_test (table)', $counts, sub { chisq_test($counts) } );
resumes_ok( 'chisq_test (first row)', $counts->{'row1'}, sub { chisq_test($counts) } );
resumes_ok( 'sample', $groups, sub { sample( $groups, 3 ) } );
{
	my $two = { 'x' => { 'a' => 3, 'b' => 1 }, 'y' => { 'a' => 1, 'b' => 3 } };
	resumes_ok( 'fisher_test', $two, sub { fisher_test($two) } );
}
{
	my $h = hoh_of();
	my $i = { 'r1' => { 'new' => 1, 'more' => 2 }, 'r2' => { 'new' => 3 } };
	resumes_ok( 'ljoin (second table row)', $i->{'r1'}, sub { ljoin( $h, $i ) } );
	resumes_ok( 'add_data (second table)', $i, sub { add_data( $h, $i ) } );
}
{
	my $fit = lm( 'formula' => 'x1 ~ x2 + x3', 'data' => hoa_of(@rows) );
	my $new = hoa_of( @rows[ 0 .. 2 ] );
	resumes_ok( 'predict (newdata)', $new, sub { predict( $fit, $new ) } );
	resumes_ok( 'predict (coefficients)', $fit->{'coefficients'}, sub { predict( $fit, $new ) } ) if ref $fit->{'coefficients'} eq 'HASH';
}
# a croak in mid-walk restores the iterator too
{
	my $bad = { ( map { ( "k$_" => [ 1, 2 ] ) } 1 .. 10 ), 'odd' => 'scalar' };
	my $r = resume( $bad, sub { eval { hoa2aoh($bad) } } );
	is_deeply( $r, [ $r->[2], 0, $r->[2] ], 'hoa2aoh croaking on a scalar column: each() resumes' );
}

# iter_keep() holds a reference to each hash it saves; none may be left behind.
if ( $INC{'Devel/Cover.pm'} ) { done_testing(); exit 0 }
{
	my $hoa = hoa_of(@rows);
	my $hoh = hoh_of();
	my ($k) = each %$hoa;
	($k) = each %{ $hoh->{'r2'} };
	no_leaks_ok { hoa2aoh($hoa); vals( $hoa, 'x1' ); csort( $hoa, 'x1' ) } 'no leaks: HoA functions mid-each';
	no_leaks_ok { hoh2hoa($hoh); transpose($hoh); filter( $hoh, col('x1') > 2 ) } 'no leaks: HoH functions mid-each on a row';
	no_leaks_ok { eval { hoa2aoh( { 'a' => [1], 'b' => 'x' } ) } } 'no leaks: croak inside a walk';
}
done_testing();
