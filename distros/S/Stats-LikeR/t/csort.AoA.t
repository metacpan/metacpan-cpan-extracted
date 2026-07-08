#!/usr/bin/env perl

require 5.010;
use warnings FATAL => 'all';
use Stats::LikeR;
use Test::Exception; # throws_ok / dies_ok
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

# a small Array-of-Arrays: columns are addressed by integer index
#   col 0 = id (numeric), col 1 = val (numeric), col 2 = tag (string)
sub fresh_aoa {
	return [
		[ 3, 30, 'gamma' ],
		[ 1, 10, 'alpha' ],
		[ 2, 20, 'beta'  ],
	];
}

#--------
# AoA, sort by integer column index (numeric column -> numeric order)
#--------
{
	my $aoa = fresh_aoa();
	my $s = csort($aoa, 0);
	is( ref $s, 'ARRAY', 'AoA defaults to AoA output' );
	is( scalar @$s, 3, 'all rows returned' );
	is_deeply( [ map { $_->[0] } @$s ], [ 1, 2, 3 ],
		'AoA numeric column 0 sorts numerically ascending' );
	is_deeply( [ map { $_->[2] } @$s ], [qw/alpha beta gamma/],
		'sibling columns travel in lockstep' );
	# non-destructive: the caller's AoA order is untouched
	is_deeply( [ map { $_->[0] } @$aoa ], [ 3, 1, 2 ],
		'AoA input left untouched' );
	# rows are the SAME arrayrefs (reorder, not clone)
	is( $s->[0], $aoa->[1], 'AoA result shares the original row arrayrefs' );
}

#--------
# AoA, string column -> lexical order
#--------
{
	my $aoa = fresh_aoa();
	my $s = csort($aoa, 2);
	is_deeply( [ map { $_->[2] } @$s ], [qw/alpha beta gamma/],
		'AoA string column sorts lexically' );
}

#--------
# AoA, custom comparator: $a / $b are the row arrayrefs
#--------
{
	no warnings 'once';
	my $aoa = fresh_aoa();
	my $s = csort($aoa, sub { $b->[0] <=> $a->[0] });
	is_deeply( [ map { $_->[0] } @$s ], [ 3, 2, 1 ],
		'AoA comparator: $a/$b are row arrayrefs, descending works' );
}

#--------
# undef / short rows sort last, defined values first (asc) then undef/missing
#--------
{
	my $aoa = [
		[ 1, 5 ],
		[ 2 ],          # missing col 1
		[ 3, undef ],   # explicit undef
		[ 4, 1 ],
	];
	my $s = csort($aoa, 1);
	is_deeply( [ map { $_->[0] } @$s ], [ 4, 1, 2, 3 ],
		'defined first (asc), undef/missing last (stable among themselves)' );
}

#--------
# stability: equal keys keep their original relative order
#--------
{
	my $aoa = [
		[ 1, 'a' ],
		[ 1, 'b' ],
		[ 0, 'c' ],
		[ 1, 'd' ],
	];
	my $s = csort($aoa, 0);
	is_deeply( [ map { $_->[1] } @$s ], [qw/c a b d/],
		'stable sort preserves input order among equal keys' );
}

#--------
# output shape control: AoA -> HoA / AoA -> AoH (columns keyed by index)
#--------
{
	my $aoa = fresh_aoa();
	my $hoa = csort($aoa, 0, 'hoa');
	is( ref $hoa, 'HASH', 'AoA + output=hoa returns a hashref' );
	is_deeply( $hoa->{0}, [ 1, 2, 3 ],             'AoA->HoA: index-0 column keyed as "0"' );
	is_deeply( $hoa->{1}, [ 10, 20, 30 ],          'AoA->HoA: index-1 column keyed as "1"' );
	is_deeply( $hoa->{2}, [qw/alpha beta gamma/],  'AoA->HoA: index-2 column keyed as "2"' );

	my $aoh = csort($aoa, 0, 'aoh');
	is( ref $aoh, 'ARRAY', 'AoA + output=aoh returns an arrayref' );
	is_deeply( [ map { $_->{0} } @$aoh ], [ 1, 2, 3 ],
		'AoA->AoH: cells reachable under stringified index keys' );
	is_deeply( [ sort keys %{ $aoh->[0] } ], [qw/0 1 2/],
		'AoA->AoH: each row hash carries all positional columns' );

	# explicit same-shape + mixed-case spelling
	my $same = csort($aoa, 0, 'AoA');
	is_deeply( [ map { $_->[0] } @$same ], [ 1, 2, 3 ],
		'explicit aoa->aoa (mixed case accepted)' );
}

#--------
# ragged AoA transposed to HoA: short rows pad with undef, width = widest row
#--------
{
	my $aoa = [
		[ 2, 'x' ],
		[ 1 ],           # no col 1
		[ 3, 'z', 9 ],   # extra col 2
	];
	my $hoa = csort($aoa, 0, 'hoa');
	is_deeply( $hoa->{0}, [ 1, 2, 3 ],             'ragged AoA->HoA: col 0 sorted' );
	is_deeply( $hoa->{1}, [ undef, 'x', 'z' ],     'ragged AoA->HoA: missing col 1 -> undef' );
	is_deeply( $hoa->{2}, [ undef, undef, 9 ],     'ragged AoA->HoA: sparse col 2 filled' );
}

#--------
# cross-shape transpose lands cleanly into AoA from keyed inputs
#--------
{
	# HoA -> AoA uses sorted column-key order for positions (first, second)
	my $hoa = { first => [ 1, 2, 3 ], second => [ 30, 10, 20 ] };
	my $aoa = csort($hoa, 'second', 'aoa');
	is( ref $aoa, 'ARRAY', 'HoA + output=aoa returns an arrayref' );
	is( scalar @$aoa, 3, 'HoA->AoA row count' );
	is_deeply( $aoa, [ [ 2, 10 ], [ 3, 20 ], [ 1, 30 ] ],
		'HoA->AoA: sorted key order (first,second); sorted by second asc' );

	# AoH -> AoA uses union-of-keys (first appearance) order for positions
	my $aoh = [ { a => 2, b => 'x' }, { a => 1, b => 'y' } ];
	my $out = csort($aoh, 'a', 'aoa');
	is( ref $out, 'ARRAY', 'AoH + output=aoa returns an arrayref' );
	is_deeply( $out->[0], [ 1, 'y' ], 'AoH->AoA: first row positional, a<b order' );
	is_deeply( $out->[1], [ 2, 'x' ], 'AoH->AoA: second row positional' );
}

#--------
# edge cases: empty and single-element AoA
#--------
{
	my $one = csort([ [ 7, 8 ] ], 0);
	is_deeply( $one, [ [ 7, 8 ] ], 'single-row AoA returns unchanged' );
	# an empty arrayref can't be detected as AoA; it behaves as an empty AoH
	is_deeply( csort([], 0), [], 'empty arrayref returns empty arrayref' );
}

#--------
# argument validation: AoA column index must be a non-negative integer
#--------
throws_ok { csort( fresh_aoa(), -1 ) } qr/non-negative integer/,
	'negative AoA index croaks';
throws_ok { csort( fresh_aoa(), 'x' ) } qr/non-negative integer/,
	'non-integer AoA column croaks';
throws_ok { csort( fresh_aoa(), '1.5' ) } qr/non-negative integer/,
	'fractional AoA index croaks';
throws_ok { csort( fresh_aoa(), 99 ) } qr/not found/,
	'AoA index beyond every row croaks (column not found)';
throws_ok { csort( fresh_aoa(), 0, 'frame' ) } qr/output type must be/,
	'bad output type croaks';
throws_ok { csort( fresh_aoa(), [] ) } qr/second argument/,
	'non-scalar, non-code $by croaks';

#--------
# leak checks -- calls repeated OUTSIDE any captured assignment (house rule),
# skipped under Devel::Cover whose instrumentation registers false leaks
#--------
no_leaks_ok {
	csort( fresh_aoa(), 0 )
} 'csort(AoA) column sort: no memory leaks' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	no warnings 'once';
	csort( fresh_aoa(), sub { $b->[0] <=> $a->[0] } )
} 'csort(AoA, coderef) descending: no memory leaks' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	csort( fresh_aoa(), 0, 'hoa' )
} 'csort(AoA) -> HoA transpose: no memory leaks' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	csort( fresh_aoa(), 0, 'aoh' )
} 'csort(AoA) -> AoH transpose: no memory leaks' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	eval { csort( fresh_aoa(), -1 ) }
} 'csort(AoA) bad-index croak path: no memory leaks' unless $INC{'Devel/Cover.pm'};

done_testing();
