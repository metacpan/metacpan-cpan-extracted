# multidimensional binning & histogramming - iterator tests

use strict;
use warnings;
use Test::More tests => 49;
use Test::Deep;
use Test::PDL qw( is_pdl test_pdl );
use Test::Exception;
use Test::NoWarnings;
use PDL;
use PDL::NDBin::Iterator;

# compatibility with non-64-bit PDL versions
BEGIN { if( ! defined &PDL::indx ) { *indx = \&PDL::long; } }

# variable declarations
my( $iter, @bins, @variables, $idx, $bin, $var, @expected, @got, $k );

#
@bins = ( 4 );
@variables = ( null );
$idx = null;
$iter = PDL::NDBin::Iterator->new( bins => \@bins, array => \@variables, idx => $idx );
isa_ok $iter, 'PDL::NDBin::Iterator', 'return value from constructor';

# test iteration
@bins = ( 4 );
@variables = ( null );
$idx = null;
$iter = PDL::NDBin::Iterator->new( bins => \@bins, array => \@variables, idx => $idx );
$k = 4;
while( $iter->advance ) { last if $k-- == 0 }
is $k, 0, 'advance() in boolean context';
ok $iter->done, 'iteration complete';
ok !$iter->advance, "doesn't reset";
ok !$iter->advance, "doesn't reset, second try";

#
@bins = ( 4 );
@variables = ( 'one', 'two', 'three' );
$idx = null;
$iter = PDL::NDBin::Iterator->new( bins => \@bins, array => \@variables, idx => $idx );
is $iter->nbins, 4, 'number of bins';
is $iter->nvars, 3, 'number of variables';
@got = ();
@expected = (
	[ 0, 0, 'one',   test_pdl( $idx ) ],
	[ 0, 1, 'two',   test_pdl( $idx ) ],
	[ 0, 2, 'three', test_pdl( $idx ) ],
	[ 1, 0, 'one',   test_pdl( $idx ) ],
	[ 1, 1, 'two',   test_pdl( $idx ) ],
	[ 1, 2, 'three', test_pdl( $idx ) ],
	[ 2, 0, 'one',   test_pdl( $idx ) ],
	[ 2, 1, 'two',   test_pdl( $idx ) ],
	[ 2, 2, 'three', test_pdl( $idx ) ],
	[ 3, 0, 'one',   test_pdl( $idx ) ],
	[ 3, 1, 'two',   test_pdl( $idx ) ],
	[ 3, 2, 'three', test_pdl( $idx ) ],
);
$k = 12;
while( $iter->advance ) {
	my $bin = $iter->bin;
	my $var = $iter->var;
	push @got, [ $bin, $var, $iter->data, $iter->idx ];
	last if $k-- == 0; # prevent endless loops
};
ok $k == 0 && $iter->done, 'number of iterations';
cmp_deeply \@got, \@expected, 'data(), idx()';

#
@bins = ( 3, 2 );
@variables = ( sequence(20), 20-sequence(20) );
$idx = 2*sequence( 20 )->convert( indx );
$iter = PDL::NDBin::Iterator->new( bins => \@bins, array => \@variables, idx => $idx );
is $iter->nbins, 6, 'number of bins';
is $iter->nvars, 2, 'number of vars';
@got = ();
@expected = (
	[ 0, 0, [ 0, 0 ] ],
	[ 0, 1, [ 0, 0 ] ],
	[ 1, 0, [ 1, 0 ] ],
	[ 1, 1, [ 1, 0 ] ],
	[ 2, 0, [ 2, 0 ] ],
	[ 2, 1, [ 2, 0 ] ],
	[ 3, 0, [ 0, 1 ] ],
	[ 3, 1, [ 0, 1 ] ],
	[ 4, 0, [ 1, 1 ] ],
	[ 4, 1, [ 1, 1 ] ],
	[ 5, 0, [ 2, 1 ] ],
	[ 5, 1, [ 2, 1 ] ],
);
$k = 12;
while( $iter->advance ) {
	my $bin = $iter->bin;
	my $var = $iter->var;
	push @got, [ $bin, $var, [ $iter->unflatten ] ];
	last if $k-- == 0; # prevent endless loops
};
ok $k == 0 && $iter->done, 'number of iterations';
is_deeply \@got, \@expected, 'unflatten()';

#
@bins = ( 3, 2 );
@variables = ( sequence(20) );
$idx = sequence( 20 )->convert( indx ) % 6;
$iter = PDL::NDBin::Iterator->new( bins => \@bins, array => \@variables, idx => $idx );
is $iter->nbins*$iter->nvars, 6, 'nbins() * nvars()';
@got = ();
@expected = (
	indx( 0,6,12,18 ),
	indx( 1,7,13,19 ),
	indx( 2,8,14 ),
	indx( 3,9,15 ),
	indx( 4,10,16 ),
	indx( 5,11,17 ),
);
$k = 6;
while( $iter->advance ) {
	push @got, $iter->want;
	last if $k-- == 0; # prevent endless loops
};
ok $k == 0 && $iter->done, 'number of iterations';
for( 0 .. $#got ) {
	is_pdl $got[ $_ ], $expected[ $_ ], "want() iteration $_";
}

#
@bins = ( 2, 4 );
@variables = ( sequence(20), 20-sequence(20) );
# #     0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19
# idx   0  1  2  3  4  5  6  7  0  1  2  3  4  5  6  7  0  1  2  3
# var1  0  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16 17 18 19
# var2 20 19 18 17 16 15 14 13 12 11 10  9  8  7  6  5  4  3  2  1
$idx = sequence( 20 )->convert( indx ) % 8;
$iter = PDL::NDBin::Iterator->new( bins => \@bins, array => \@variables, idx => $idx );
is $iter->nbins*$iter->nvars, 16, 'nbins() * nvars()';
@got = ();
@expected = (
	pdl( 0,8,16 ),
	pdl( 20,12,4 ),
	pdl( 1,9,17 ),
	pdl( 19,11,3 ),
	pdl( 2,10,18 ),
	pdl( 18,10,2 ),
	pdl( 3,11,19 ),
	pdl( 17,9,1 ),
	pdl( 4,12 ),
	pdl( 16,8 ),
	pdl( 5,13 ),
	pdl( 15,7 ),
	pdl( 6,14 ),
	pdl( 14,6 ),
	pdl( 7,15 ),
	pdl( 13,5 ),
);
$k = 16;
while( $iter->advance ) {
	push @got, $iter->selection;
	last if $k-- == 0; # prevent endless loops
};
ok $k == 0 && $iter->done, 'number of iterations';
for( 0 .. $#got ) {
	is_pdl $got[ $_ ], $expected[ $_ ], "selection() iteration $_";
}

# test variable deactivation
@bins = ( 2, 4, 3 );
@variables = ( random(20), random(20), random(20), random(20) );
$idx = 24*random( 20 )->convert( indx );
{
	$iter = PDL::NDBin::Iterator->new( bins => \@bins, array => \@variables, idx => $idx );
	is $iter->nbins*$iter->nvars, 96, 'nbins() * nvars()';
	my @visited = (0) x @variables;
	$k = 96;
	while( $iter->advance ) {
		my $var = $iter->var;
		$visited[ $var ]++;
		$iter->var_active( 1 );
		last if $k-- == 0; # prevent endless loops
	};
	ok $k == 0 && $iter->done, 'number of iterations';
	is_deeply \@visited, [ ($iter->nbins) x @variables ], 'all variables visited n times, where n = number of bins';
}
{
	$iter = PDL::NDBin::Iterator->new( bins => \@bins, array => \@variables, idx => $idx );
	is $iter->nbins*$iter->nvars, 96, 'nbins() * nvars()';
	my @visited = (0) x @variables;
	$k = 4;
	while( $iter->advance ) {
		my $var = $iter->var;
		$visited[ $var ]++;
		$iter->var_active( 0 );
		last if $k-- == 0; # prevent endless loops
	};
	ok $k == 0 && $iter->done, 'number of iterations';
	is_deeply \@visited, [ (1) x @variables ], 'all variables visited once';
}

# test mixed variable deactivation
{
	my @bins = ( 3, 1, 6 );
	# the second variable will deactivate after having been called once
	my @variables = ( random(30), random(30), random(30) );
	my @deactivates = ( 0, 1, 0 );
	my $idx = 18*random( 20 )->convert( indx );
	my $iter = PDL::NDBin::Iterator->new( bins => \@bins, array => \@variables, idx => $idx );
	is $iter->nbins*$iter->nvars, 54, 'nbins() * nvars()';
	my $expected = [
		    [ 1,1,1 ],
		map [ 1,0,1 ], 1 .. $iter->nbins-1
	];
	my $got = [
		map [ 0,0,0 ], 1 .. $iter->nbins
	];
	my $k = 37;
	while( $iter->advance ) {
		my $bin = $iter->bin;
		my $var = $iter->var;
		$got->[ $bin ][ $var ]++;
		if( $deactivates[ $var ] ) { $iter->var_active( 0 ) }
		last if $k-- == 0; # prevent endless loops
	};
	ok $k == 0 && $iter->done, 'number of iterations';
	is_deeply $got, $expected, 'mixed active/non-active variables: bins/variables visited as expected';
}
