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
no_leaks_ok { col2col( \%hoa, sub { cor( $_[0], $_[1] ) } ) } 'no leaks: code block' unless $INC{'Devel/Cover.pm'};
no_leaks_ok { col2col( \%hoa, 'cor' ) } 'no leaks: function-name shorthand' unless $INC{'Devel/Cover.pm'};
no_leaks_ok { col2col( \@aoh, sub { cor( $_[0], $_[1] ) } ) } 'no leaks: array-of-hashes input' unless $INC{'Devel/Cover.pm'};
no_leaks_ok { col2col( \%hoh, sub { cor( $_[0], $_[1] ) } ) } 'no leaks: hash-of-hashes input' unless $INC{'Devel/Cover.pm'};
no_leaks_ok { col2col( \%hoa, sub { cor( $_[0], $_[1] ) }, [ 'x', 'y' ] ) } 'no leaks: column subset' unless $INC{'Devel/Cover.pm'};
# 16. rm.undef (synonym rm.na) toggles the pairwise-complete-cases behaviour.
#     It defaults to TRUE: a row that is undef in either column is dropped so
#     both columns reach the block complete and equal length (sections 7-8).
#     Setting it false keeps every row, passing undef through in the gaps. cols
#     is positional, so pass it (undef is fine) ahead of any trailing option.
my %gap2 = ( 'a' => [ 1, 2, 3, 4, 5 ], 'b' => [ 2, undef, 6, 8, 10 ] );
my $len_block = sub { return scalar( @{ $_[0] } ) . ',' . scalar( @{ $_[1] } ) };
my $rm_default = col2col( \%gap2, $len_block );
is( $rm_default->{'a'}{'b'}, '4,4', 'rm.undef defaults to TRUE: gap row dropped pairwise' );
my $rm_true = col2col( \%gap2, $len_block, undef, 'rm.undef' => 1 );
is( $rm_true->{'a'}{'b'}, '4,4', 'rm.undef => 1 drops the gap row, like the default' );
is_deeply( $rm_true, $rm_default, 'omitting rm.undef equals rm.undef => 1 (TRUE by default)' );
my $rm_false = col2col( \%gap2, $len_block, undef, 'rm.undef' => 0 );
is( $rm_false->{'a'}{'b'}, '5,5', 'rm.undef => 0 keeps all rows, so columns stay full length' );
my $na_false = col2col( \%gap2, $len_block, undef, 'rm.na' => 0 );
is( $na_false->{'a'}{'b'}, '5,5', 'rm.na => 0 is a synonym for rm.undef => 0' );
is_deeply( $na_false, $rm_false, 'rm.na and rm.undef name the same option' );
my $mark = col2col( \%gap2, sub { my ( $x, $y ) = @_; return join( ',', map { defined($_) ? 'D' : 'U' } @$y ) }, undef, 'rm.undef' => 0 );
is( $mark->{'a'}{'b'}, 'D,U,D,D,D', 'rm.undef => 0 passes undef through in place (col b, row 2)' );
is( $mark->{'b'}{'a'}, 'D,D,D,D,D', 'the gap-free column still has every row defined' );
my $col_false = col2col( \%gap2, $len_block, 'a', 'rm.na' => 0 );
is_deeply( [ sort keys %$col_false ], [ 'a' ], 'a cols restriction still applies alongside an option' );
is( $col_false->{'a'}{'b'}, '5,5', 'cols restriction + rm.na => 0 keeps full length' );
dies_ok { col2col( \%gap2, $len_block, undef, 'rm.bogus' => 1 ) } 'unknown option name dies';
dies_ok { col2col( \%gap2, $len_block, undef, 'rm.undef' ) } 'an option without a value dies (odd trailing args)';
no_leaks_ok { col2col( \%gap2, $len_block, undef, 'rm.undef' => 0 ) } 'no leaks: rm.undef => 0 keeps every row' unless $INC{'Devel/Cover.pm'};
no_leaks_ok { col2col( \%gap2, $len_block, 'a', 'rm.na' => 0 ) } 'no leaks: cols restriction plus rm.na => 0' unless $INC{'Devel/Cover.pm'};
# 17. na => 'pairwise' | 'omit' | 'keep' chooses how undef is handled when one
#     column is paired with another. 'pairwise' (the default) keeps only rows
#     defined in BOTH, so the block gets equal aligned columns (paired stats
#     such as cor). 'omit' drops each column's own undef independently, so the
#     two columns may differ in length (unpaired tests such as t_test and
#     kruskal_test, where a gap in one sample must not discard a value in the
#     other). 'keep' passes every row through with undef in the gaps.
my %gap3 = ( 'a' => [ 1, 2, 3, 4, 5 ], 'b' => [ 10, undef, undef, 40, 50 ] );
my $show3 = sub { my ( $x, $y ) = @_; return join( ',', map { defined($_) ? $_ : 'U' } @$x ) . '|' . join( ',', map { defined($_) ? $_ : 'U' } @$y ) };
my $len3  = sub { return scalar( @{ $_[0] } ) . ',' . scalar( @{ $_[1] } ) };
# pairwise: rows defined in both are 0,3,4 -> a=[1,4,5], b=[10,40,50]
my $na_pw = col2col( \%gap3, $show3, undef, 'na' => 'pairwise' );
is( $na_pw->{'a'}{'b'}, '1,4,5|10,40,50', "na => 'pairwise' keeps only rows defined in both" );
is_deeply( col2col( \%gap3, $show3 ), $na_pw, "pairwise is the default na mode" );
is_deeply( col2col( \%gap3, $show3, undef, 'rm.undef' => 1 ), $na_pw, "rm.undef => 1 is an alias for na => 'pairwise'" );
# omit: a keeps all 5, b keeps its 3 -> different lengths, each column's own undef gone
my $na_om = col2col( \%gap3, $show3, undef, 'na' => 'omit' );
is( $na_om->{'a'}{'b'}, '1,2,3,4,5|10,40,50', "na => 'omit' drops each column's own undef independently" );
is( col2col( \%gap3, $len3, undef, 'na' => 'omit' )->{'a'}{'b'}, '5,3', "na => 'omit' columns may differ in length" );
# keep: every row, undef passed through
my $na_kp = col2col( \%gap3, $show3, undef, 'na' => 'keep' );
is( $na_kp->{'a'}{'b'}, '1,2,3,4,5|10,U,U,40,50', "na => 'keep' passes undef through" );
is_deeply( col2col( \%gap3, $show3, undef, 'rm.na' => 0 ), $na_kp, "rm.na => 0 is an alias for na => 'keep'" );
# a column with no defined values under omit -> that pair is skipped (undef), no crash
my %allundef = ( 'a' => [ 1, 2, 3 ], 'z' => [ undef, undef, undef ] );
my $au = col2col( \%allundef, $show3, undef, 'na' => 'omit' );
ok( !defined $au->{'a'}{'z'}, "na => 'omit' yields undef for a pair with an all-undef column" );
dies_ok { col2col( \%gap3, $show3, undef, 'na' => 'omit', 'rm.undef' => 1 ) } 'na together with rm.undef dies';
dies_ok { col2col( \%gap3, $show3, undef, 'na' => 'bogus' ) } 'an invalid na value dies';
no_leaks_ok { col2col( \%gap3, $show3, undef, 'na' => 'omit' ) } 'no leaks: na => omit' unless $INC{'Devel/Cover.pm'};
no_leaks_ok { col2col( \%gap3, $show3, undef, 'na' => 'keep' ) } 'no leaks: na => keep' unless $INC{'Devel/Cover.pm'};
# 18. skip.errors defaults to TRUE: a block that croaks for a pair does not abort
#     col2col; the offending cell keeps the FIRST LINE of the error message so the
#     caller sees which (outer => inner) pair failed and why, while every other
#     cell is computed as usual. Storing only the first line keeps cells tidy even
#     when Carp / Devel::Confess append a multi-line stack trace. Set
#     skip.errors => 0 to make a croak propagate and abort the whole call.
my %se = ( 'p' => [ 1, 2, 3 ], 'q' => [ 4, 5, 6 ], 'r' => [ 7, 8, 9 ] );
my $boom = sub { my ( $a, $b ) = @_; die "boom for this pair\n" if $b->[0] == 4; return $a->[0] + $b->[0] };
# default (no option): the croak is trapped, not propagated
my $se_def = col2col( \%se, $boom );
is( ref $se_def, 'HASH', 'skip.errors defaults to true: col2col returns rather than dying' );
is( $se_def->{'p'}{'q'}, 'boom for this pair', 'default: failing cell holds the first line of the croak message' );
is( $se_def->{'r'}{'q'}, 'boom for this pair', 'default: every pair that hits the croak is reported' );
is( $se_def->{'p'}{'r'}, 1 + 7, 'default: a pair that does not croak is computed normally' );
unlike( $se_def->{'p'}{'q'}, qr/\n/, 'default: stored message is a single line' );
# explicit skip.errors => 1 is identical to the default
my $se_r = col2col( \%se, $boom, undef, 'skip.errors' => 1 );
is_deeply( $se_r, $se_def, 'skip.errors => 1 matches the default' );
# skip.errors => 0 opts out: the croak propagates and aborts the call
dies_ok { col2col( \%se, $boom, undef, 'skip.errors' => 0 ) } 'skip.errors => 0 lets a croaking block abort the whole call';
# a message carrying a trailing stack trace (as Devel::Confess / Carp add) is
# reduced to its first line:
my $trace = sub { my ( $a, $b ) = @_; die "bad pair\n at file line 9.\n\tmain::__ANON__ called at x line 3\n" if $b->[0] == 4; return 0 };
my $tr = col2col( \%se, $trace );
is( $tr->{'p'}{'q'}, 'bad pair', 'a multi-line (trace-augmented) message keeps only its first line' );
no_leaks_ok { col2col( \%se, $boom ) } 'no leaks: trapping a croaking block by default' unless $INC{'Devel/Cover.pm'};

# 19. Options may be passed as a hash ref in place of cols, so no undef
#     placeholder is needed when there is no column restriction. It is
#     equivalent to the trailing name => value form.
my $hash_form = col2col( \%se, $boom, { 'skip.errors' => 1 } );
is_deeply( $hash_form, $se_def, 'options as a hash ref == default (no undef placeholder needed)' );
my %gap4 = ( 'a' => [ 1, 2, 3, 4, 5 ], 'b' => [ 10, undef, undef, 40, 50 ] );
my $hash_na = col2col( \%gap4, sub { my ( $x, $y ) = @_; scalar(@$x) . ',' . scalar(@$y) }, { 'na' => 'omit' } );
is( $hash_na->{'a'}{'b'}, '5,3', "na => 'omit' via the hash-ref form" );
my $hash_off = col2col( \%gap4, sub { my ( $x, $y ) = @_; scalar(@$x) . ',' . scalar(@$y) }, { 'skip.errors' => 0 } );
is( $hash_off->{'a'}{'b'}, '3,3', 'skip.errors => 0 via the hash-ref form (default na still pairwise)' );
dies_ok { col2col( \%se, $boom, { 'skip.errors' => 1 }, 'na' => 'keep' ) } 'a hash ref of options must be the last argument';
dies_ok { col2col( \%se, $boom, { 'bogus' => 1 } ) } 'an unknown option in the hash ref dies';
done_testing();
