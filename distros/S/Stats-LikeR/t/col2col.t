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
# The two columns arrive in the block as @_ = ($col_a, $col_b); no globals.
# The same five rows in all three shapes col2col accepts.
my %hoa = ( 'x' => [ 1, 2, 3, 4, 5 ], 'y' => [ 2, 4, 6, 8, 10 ], 'z' => [ 5, 4, 3, 2, 1 ] );
my @aoh = map { { 'x' => $hoa{'x'}[$_], 'y' => $hoa{'y'}[$_], 'z' => $hoa{'z'}[$_] } } 0 .. 4;
my %hoh = map { ( "r$_" => { 'x' => $hoa{'x'}[$_], 'y' => $hoa{'y'}[$_], 'z' => $hoa{'z'}[$_] } ) } 0 .. 4;
# 1. col2col exists and returns a hash of hashes.
ok( defined &Stats::LikeR::col2col, 'col2col is defined in Stats::LikeR' );
my $cor = col2col( \%hoa, sub { cor( $_[0], $_[1] ) } );
is( ref $cor, 'HASH', 'col2col returns a hash ref' );
is( ref $cor->{'x'}, 'HASH', 'each column maps to an inner hash ref' );
# 2. Known Pearson coefficients, computed by a block reading the two columns.
is_approx( $cor->{'x'}{'y'}, 1, 'cor(x,y) ==  1' );
is_approx( $cor->{'x'}{'z'}, -1, 'cor(x,z) == -1' );
is_approx( $cor->{'y'}{'z'}, -1, 'cor(y,z) == -1' );
is_approx( $cor->{'y'}{'x'}, 1, 'cor is symmetric: (y,x) == (x,y)' );
# 3. The diagonal is skipped and the topology is complete.
ok( !exists $cor->{'x'}{'x'}, 'no self-comparison on the diagonal (x,x)' );
is_deeply( [ sort keys %$cor ], [ 'x', 'y', 'z' ], 'outer keys = every column' );
is_deeply( [ sort keys %{ $cor->{'x'} } ], [ 'y', 'z' ], 'inner keys for x = every other column' );
# 4. All three input shapes give identical results.
is_deeply( col2col( \@aoh, sub { cor( $_[0], $_[1] ) } ), $cor, 'array-of-hashes matches hash-of-arrays' );
is_deeply( col2col( \%hoh, sub { cor( $_[0], $_[1] ) } ), $cor, 'hash-of-hashes matches hash-of-arrays' );
# 5. The block receives the two columns as @_ array refs.
my $refs = col2col( \%hoa, sub { return ref( $_[0] ) . ',' . ref( $_[1] ) } );
is( $refs->{'x'}{'y'}, 'ARRAY,ARRAY', '@_ holds the two columns as array refs' );
# 6. Unpacking @_ into local lexicals reads just like a direct call.
my $sp1 = col2col( \%hoa, sub { my ( $a, $b ) = @_; return scalar(@$a) . ',' . scalar(@$b) } );
is( $sp1->{'x'}{'y'}, '5,5', 'my ($a,$b) = @_ unpacks the two columns' );
# 7. Pairwise complete cases: a gap drops that row, so both columns stay equal length.
my %gap = ( 'a' => [ 1, 2, 3, 4, 5 ], 'b' => [ 2, undef, 6, 8, 10 ] );
my $lens = col2col( \%gap, sub { return scalar( @{ $_[0] } ) . ',' . scalar( @{ $_[1] } ) } );
is( $lens->{'a'}{'b'}, '4,4', 'undef row dropped pairwise, keeping equal length' );
is_approx( col2col( \%gap, sub { cor( $_[0], $_[1] ) } )->{'a'}{'b'}, 1, 'cor on the 4 complete pairs == 1' );
# 8. Any custom analysis can run in the block.
my $sums = col2col( \%hoa, sub { my $s = 0; $s += $_ for @{ $_[0] }; return $s } );
is( $sums->{'x'}{'y'}, 15, 'block sees full x column (sum 1..5 = 15)' );
is( $sums->{'y'}{'x'}, 30, 'block sees full y column (sum 2..10 = 30)' );
# 9. Arguments read just like an ordinary call: cor($_[0], $_[1], 'spearman').
my %mono = ( 'x' => [ 1, 2, 3, 4, 5 ], 'y' => [ 1, 4, 9, 16, 25 ] );
my $sp = col2col( \%mono, sub { cor( $_[0], $_[1], 'spearman' ) } );
ok( looks_like_number( $sp->{'x'}{'y'} ), q{sub { cor($_[0], $_[1], 'spearman') } dispatches and returns a number} );
# 10. A bare function name is shorthand for fn($col_a, $col_b).
is_approx( col2col( \%hoa, 'cor' )->{'x'}{'y'}, 1, q{bare 'cor' is shorthand for cor($col_a, $col_b)} );
# 11. No package globals: a caller's own $c1/$c2 are never touched.
our ( $c1, $c2 ) = ( 'MINE', 'OURS' );
my $safe = col2col( \%hoa, sub { cor( $_[0], $_[1] ) } );
is_approx( $safe->{'x'}{'y'}, 1, 'col2col still works alongside a caller-defined $c1/$c2' );
is( $c1, 'MINE', q{caller's own $c1 is left untouched} );
is( $c2, 'OURS', q{caller's own $c2 is left untouched} );
# 12. Two-sample tests dispatch (distinct values keep ks_test off its ties path).
my %distinct = ( 'x' => [ 1.1, 2.4, 3.6, 4.8, 5.2 ], 'y' => [ 10.3, 11.7, 12.1, 13.9, 14.5 ], 'z' => [ 21.2, 22.8, 23.4, 24.6, 25.1 ] );
for my $name ( 't_test', 'ks_test' ) {
	my $res = col2col( \%distinct, sub { $name eq 't_test' ? t_test( $_[0], $_[1] ) : ks_test( $_[0], $_[1] ) } );
	is( ref $res, 'HASH', "$name: returns a hash of hashes" );
	ok( !exists $res->{'x'}{'x'}, "$name: skips the diagonal" );
	is_deeply( [ sort keys %{ $res->{'x'} } ], [ 'y', 'z' ], "$name: x compared against every other column" );
	ok( defined $res->{'x'}{'y'}, "$name: produced a result for (x,y)" );
}
# 13. An optional third argument restricts the OUTER columns (the "from" side):
#     only those columns are compared against every other column, which means
#     fewer calls and a smaller result. Omitting it is unchanged (sections above).
my $full = col2col( \%hoa, sub { cor( $_[0], $_[1] ) } );
my $one = col2col( \%hoa, sub { cor( $_[0], $_[1] ) }, 'x' );
is_deeply( [ sort keys %$one ], [ 'x' ], 'single column: only that column is an outer key' );
is_deeply( [ sort keys %{ $one->{'x'} } ], [ 'y', 'z' ], 'single column: still compared against every other column' );
is_deeply( $one->{'x'}, $full->{'x'}, 'single column: its row matches the unrestricted run' );
my $two = col2col( \%hoa, sub { cor( $_[0], $_[1] ) }, [ 'x', 'y' ] );
is_deeply( [ sort keys %$two ], [ 'x', 'y' ], 'column list: only those columns are outer keys' );
is_deeply( [ sort keys %{ $two->{'y'} } ], [ 'x', 'z' ], 'column list: y still compared against every other column' );
ok( !exists $two->{'z'}, 'column list: an excluded column is not an outer key' );
is_deeply( $two, { 'x' => $full->{'x'}, 'y' => $full->{'y'} }, 'restricted result is exactly the kept slice of the full result' );
dies_ok { col2col( \%hoa, sub { cor( $_[0], $_[1] ) }, 'nope' ) } 'unknown single column dies';
dies_ok { col2col( \%hoa, sub { cor( $_[0], $_[1] ) }, [ 'x', 'nope' ] ) } 'unknown column in a list dies';
dies_ok { col2col( \%hoa, sub { cor( $_[0], $_[1] ) }, { 'x' => 1 } ) } 'bad cols type (hash ref) dies';
# 14. Bad inputs die rather than returning garbage.
dies_ok { col2col( 42, sub { cor( $_[0], $_[1] ) } ) } 'non-reference data dies';
dies_ok { col2col( [ 1, 2, 3 ], sub { cor( $_[0], $_[1] ) } ) } 'array of plain scalars (no columns) dies';
dies_ok { col2col( \%hoa, 'no_such_function' ) } 'unknown function name dies';
dies_ok { col2col( \%hoa, undef ) } 'undef command dies';
dies_ok { col2col( \%hoa, { 'a' => 1 } ) } 'hash-ref command dies';
# 15. No memory leaks across the block, function-name, and column-subset paths.
no_leaks_ok { col2col( \%hoa, sub { cor( $_[0], $_[1] ) } ) } 'no leaks: code block';
no_leaks_ok { col2col( \%hoa, 'cor' ) } 'no leaks: function-name shorthand';
no_leaks_ok { col2col( \@aoh, sub { cor( $_[0], $_[1] ) } ) } 'no leaks: array-of-hashes input';
no_leaks_ok { col2col( \%hoh, sub { cor( $_[0], $_[1] ) } ) } 'no leaks: hash-of-hashes input';
no_leaks_ok { col2col( \%hoa, sub { cor( $_[0], $_[1] ) }, [ 'x', 'y' ] ) } 'no leaks: column subset';
done_testing();
