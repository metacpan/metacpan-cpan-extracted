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

# a small Hash-of-Hashes; the outer key is the row name
sub fresh_hoh {
	return {
		alpha => { id => 1, val => 30, tag => 'C' },
		beta  => { id => 2, val => 20, tag => 'B' },
		gamma => { id => 3, val => 10, tag => 'A' },
	};
}

#--------
# HoH -> AoH (default output) preserves the row name under 'row.name'
#--------
{
	my $hoh = fresh_hoh();
	my $aoh = csort($hoh, 'id');	# ascending by id -> alpha, beta, gamma
	is( ref $aoh, 'ARRAY', 'HoH defaults to AoH output' );
	is( scalar @$aoh, 3, 'all rows returned' );
	is( $aoh->[0]{'row.name'}, 'alpha', 'row 0 carries its outer key' );
	is( $aoh->[1]{'row.name'}, 'beta',  'row 1 carries its outer key' );
	is( $aoh->[2]{'row.name'}, 'gamma', 'row 2 carries its outer key' );
	# the ordinary columns still travel alongside the name
	is( $aoh->[0]{id},  1,  'row 0 id intact' );
	is( $aoh->[2]{tag}, 'A','row 2 tag intact' );
}

#--------
# HoH -> HoA gives an aligned 'row.name' column
#--------
{
	my $hoh = fresh_hoh();
	no warnings 'once';
	my $hoa = csort($hoh, sub { $b->{id} <=> $a->{id} }, 'hoa');	# desc id
	is( ref $hoa, 'HASH', 'coderef sort of HoH -> HoA' );
	is_deeply( $hoa->{'row.name'}, [qw/gamma beta alpha/],
		'row.name column aligns with the descending sort' );
	is_deeply( $hoa->{id},  [3, 2, 1],       'id column follows the same order' );
	is_deeply( $hoa->{val}, [10, 20, 30],    'val column stays row-aligned' );
	is_deeply( $hoa->{tag}, [qw/A B C/],     'tag column stays row-aligned' );
}

#--------
# 4th arg overrides the row-name column name
#--------
{
	my $hoh = fresh_hoh();
	my $aoh = csort($hoh, 'id', 'aoh', 'sample');
	is( $aoh->[0]{sample}, 'alpha', 'custom row-name column is honored' );
	ok( !exists $aoh->[0]{'row.name'}, 'default row-name column absent when overridden' );

	my $hoa = csort($hoh, 'id', 'hoa', 'sample');
	is_deeply( $hoa->{sample}, [qw/alpha beta gamma/],
		'custom row-name column present in HoA output' );
}

#--------
# sorting BY the row-name column works once it exists
#--------
{
	my $hoh = fresh_hoh();
	my $aoh = csort($hoh, 'row.name');
	is_deeply( [ map { $_->{'row.name'} } @$aoh ], [qw/alpha beta gamma/],
		'can sort by the injected row-name column' );
}

#--------
# the caller's HoH is never mutated by the row-name injection
#--------
{
	my $hoh = fresh_hoh();
	csort($hoh, 'id');
	csort($hoh, 'id', 'aoh', 'sample');
	ok( !exists $hoh->{alpha}{'row.name'}, 'source row not polluted with row.name' );
	ok( !exists $hoh->{alpha}{sample},     'source row not polluted with custom name' );
	is( scalar keys %{ $hoh->{alpha} }, 3, 'source row still has exactly its 3 columns' );
}

#--------
# usage / argument-validation croaks
#--------
throws_ok { csort( fresh_hoh() ) } qr/Usage: csort/,
	'too few args croaks with the new usage message';
throws_ok { csort( fresh_hoh(), 'id', 'aoh', 'x', 'y' ) } qr/Usage: csort/,
	'too many args croaks with the new usage message';
throws_ok { csort( 'not-a-ref', 'id' ) } qr/first argument/,
	'non-ref data croaks';
throws_ok { csort( fresh_hoh(), [] ) } qr/second argument/,
	'non-scalar, non-code $by croaks';
throws_ok { csort( fresh_hoh(), 'id', 'xyz' ) } qr/output type must be/,
	'bad output type croaks';
throws_ok { csort( { a => { x => 1 }, b => 42 }, 'x' ) }
	qr/is not (?:a hash-ref|an array-ref)/,
	'mixed HoH row croaks';

#--------
# leak checks -- assignments live OUTSIDE the measured block on purpose,
# so coverage runs (which skip the guarded statement) don't null them out
#--------
no_leaks_ok {
	csort( fresh_hoh(), 'id' )
} 'csort(HoH) -> AoH: no memory leaks' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	no warnings 'once';
	csort( fresh_hoh(), sub { $b->{id} <=> $a->{id} }, 'hoa' )
} 'csort(HoH, coderef) -> HoA: no memory leaks' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	csort( fresh_hoh(), 'id', 'aoh', 'sample' )
} 'csort(HoH) custom row-name column: no memory leaks' unless $INC{'Devel/Cover.pm'};

no_leaks_ok {
	eval { csort( { a => { x => 1 }, b => 42 }, 'x' ) }
} 'csort(HoH) mid-fold croak path: no memory leaks' unless $INC{'Devel/Cover.pm'};

done_testing();
