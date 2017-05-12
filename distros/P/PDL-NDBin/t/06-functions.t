# multidimensional binning & histogramming - tests of the wrapper functions

use strict;
use warnings;
use Test::More tests => 83;
use Test::PDL;
use Test::Exception;
use Test::NoWarnings;
use PDL;
use PDL::NDBin qw( ndbinning ndbin );

# compatibility with non-64-bit PDL versions
BEGIN { if( ! defined &PDL::indx ) { *indx = \&PDL::long } }

sub _defined_or { defined $_[0] ? $_[0] : $_[1] }

sub debug_action
{
	my $iter = shift;
	# Piddle operations can be dangerous: when applying them to the result
	# of an index operation on an empty piddle, they may throw an
	# exception. Empty piddles are used, among others, when an ordinary
	# histogram is required. So, just to be safe, we wrap all potentially
	# dangerous calls in an `eval'.
	#
	# Remember that the actual operations are delayed until required. This
	# explains why, for instance, we have to wrap
	# C<<$iter->selection->min>> in an eval block. Even if we evaluate and
	# assign C<<$iter->selection>> to a temporary variable before, the data
	# is really evaluated, and the exception is raised, when we call min().
	my $n = $iter->want->nelem;
	my $min = _defined_or( eval { use warnings FATAL => 'all'; sprintf '%10.4f', $iter->selection->min }, '-' x 10 );
	my $max = _defined_or( eval { use warnings FATAL => 'all'; sprintf '%10.4f', $iter->selection->max }, '-' x 10 );
	note "bin (",
	     join( ',', map { sprintf "%3d", $_ } @_ ),
	     sprintf( "): #elements = %6s, ", _defined_or($n, '<UNDEF>') ),
	     "range = ($min,$max), elements in bin: ",
	     _defined_or( eval { sprintf '%s', $iter->selection }, '<N/A>' );
	return $n;
}

# create a pdl filled with bad values, of the type and length specified
sub create_bad
{
	my ( $type, $n ) = @_;
	zeroes( $type, $n )->inplace->setvaltobad( 0 )
}

# variable declarations
my ( $expected, $got, $x, $y, $z );

#
# LOW-LEVEL INTERFACE
#
note 'LOW-LEVEL INTERFACE';

# test argument parsing
lives_ok { ndbinning( null, 1, 0, 1 ) } 'correct arguments: one axis';
lives_ok { ndbinning( null, 1, 0, 1, null, 1, 0, 1 ) } 'correct arguments: two axes';
lives_ok { ndbinning( null, 1, 0, 1, null, 1, 0, 1, null, 1, 0, 1 ) } 'correct arguments: three axes';
lives_ok { ndbinning( null, 1, 0, 1, null, 1, 0, 1, null, 1, 0, 1, vars => [[ null, sub {} ]] ) } 'correct arguments: three axes, one variable, one action';
lives_ok { ndbinning( null, 1, 0, 1, null, 1, 0, 1, null, 1, 0, 1, vars => [[ null, sub {} ], [ null, sub {} ]] ) } 'correct arguments: three axes, two variables, two actions';
lives_ok { ndbinning( null, 1, 0, 1, null, 1, 0, 1, null, 1, 0, 1, vars => [[ null, sub {} ], [ null, sub {} ], [ null, sub {} ]] ) } 'correct arguments: three axes, three variables, three actions';
dies_ok { ndbinning() } 'no arguments';
dies_ok { ndbinning( 0 ) } 'wrong arguments: 0';
dies_ok { ndbinning( null ) } 'wrong arguments: null';
dies_ok { ndbinning( null, 1 ) } 'wrong arguments: null, 1';
dies_ok { ndbinning( null, 1, 0 ) } 'wrong arguments: null, 1, 0';
dies_ok { ndbinning( null, 1, 0, null ) } 'wrong arguments: null, 1, 0, null';
dies_ok { ndbinning( null, 1, 0, 1, null ) } 'wrong arguments: null, 1, 0, 1, null';
dies_ok { ndbinning( null, 1, 0, 1, null, 1 ) } 'wrong arguments: null, 1, 0, 1, null, 1';

# the example from PDL::histogram
$x = pdl( 1,1,2 );
# by default histogram() returns a piddle of the same type as the axis,
# but ndbinning() returns a piddle of type I<indx> when histogramming
$expected = indx( 0,2,1 );
$got = ndbinning( $x, 1, 0, 3 );
is_pdl $got, $expected, 'example from PDL::histogram';
$got = ndbinning( $x, 1, 0, 3,
		  vars => [[ zeroes( indx, $x->nelem ), sub { shift->want->nelem } ]] );
is_pdl $got, $expected, 'variable and action specified explicitly';
$expected = pdl( 0,2,1 );	# this is an exception, because the type is
				# locked to double by `$x => sub { ... }'
$got = ndbinning( $x => ( 1, 0, 3 ),
		  vars => [[ $x => sub { shift->want->nelem } ]] );
is_pdl $got, $expected, 'different syntax';
$expected = indx( 0,2,1 );
$got = ndbinning( $x => ( 1, 0, 3 ),
		  vars => [[ $x => 'Count' ]] );
is_pdl $got, $expected, 'different syntax, using action class name';

# the example from PDL::histogram2d
$x = pdl( 1,1,1,2,2 );
$y = pdl( 2,1,1,1,1 );
$expected = indx( [0,0,0],
		  [0,2,2],
		  [0,1,0] );
$got = ndbinning( $x => (1,0,3),
	          $y => (1,0,3) );
is_pdl $got, $expected, 'example from PDL::histogram2d';

#
$x = pdl( 1,1,1,2,2,1,1 );
$y = pdl( 2,1,3,4,1,4,4 );
$expected = indx( [1,1],
		  [1,0],
		  [1,0],
		  [2,1] );
$got = ndbinning( $x, 1, 1, 2,
		  $y, 1, 1, 4 );
is_pdl $got, $expected, 'nonsquare two-dimensional histogram';

# binning integer data
$x = byte(1,2,3,4);
$expected = indx(1,1,1,1);
$got = ndbinning( $x => (1,1,4) );
is_pdl $got, $expected, 'binning integer data: base case';
$x = short( 0,-1,3,9,6,3,1,0,1,3,7,14,3,4,2,-6,99,3,2,3,3,3,3 ); # contains out-of-range data
$expected = short( 8,9,1,0,5 );
$got = ndbinning( $x => (1,2,5), vars => [[ $x => sub { shift->want->nelem } ]] );
is_pdl $got, $expected, 'binning integer data: step = 1';
$expected = indx( 18,1,1,1,2 );
$got = ndbinning( $x => (2,3,5) );
is_pdl $got, $expected, 'binning integer data: step = 2';

# more actions & missing/undefined/invalid stuff
$x = sequence 21;
$expected = double( 1,4,7,10,13,16,19 );
$got = ndbinning( $x, 3, 0, 7, vars => [[ $x, sub { shift->selection->avg } ]] );
is_pdl $got, $expected, 'variable with action = average';
$got = ndbinning( $x, 3, 0, 7, vars => [[ $x, 'Avg' ]] );
is_pdl $got, $expected, 'variable with action = average, using action class names';
$x = 5+sequence 3; # 5 6 7
$expected = double( 0,0,1,1,1 )->inplace->setvaltobad( 0 );
$got = ndbinning( $x, 1,3,5, vars => [[ $x, sub { shift->want->nelem || undef } ]] );
is_pdl $got, $expected, 'empty bins unset'; # cannot be achieved with action classes

#
# HIGH-LEVEL INTERFACE
#
note 'HIGH-LEVEL INTERFACE';

# test argument parsing
dies_ok { ndbin() } 'no arguments';
dies_ok { ndbin( null ) } 'wrong arguments: null';
lives_ok { ndbin( pdl( 1,2 ) ) } 'correct arguments: one axis without parameters';
lives_ok { ndbin( pdl( 1,2 ), '9.', 11, 1 ) } 'correct arguments: one axis with parameters';
dies_ok { ndbin( null, '9.', 11, 1, 3 ) } 'wrong arguments: one axis + extra parameter';
TODO: {
	local $TODO = 'yet to implement slash syntax';
	lives_ok { ndbin( null, '9./11' ) } 'correct arguments: one axis, slash syntax, two args';
	lives_ok { ndbin( null, '9./11/1' ) } 'correct arguments: one axis, slash syntax, three args';
}
TODO: {
	local $TODO = 'yet to implement colon syntax';
	lives_ok { ndbin( null, '9:1' ) } 'correct arguments: one axis, colon syntax, two args';
	lives_ok { ndbin( null, '9:1:11' ) } 'correct arguments: one axis, colon syntax, three args';
}
lives_ok { ndbin( axes => [ [ pdl( 1,2 ) ] ] ) } 'keyword axes';
lives_ok { ndbin( pdl( 1,2 ), vars => [ [ pdl( 3,4 ), 'Count' ] ] ) } 'keyword vars';
dies_ok  { ndbin( pdl( 1,2 ), INVALID_KEY => 3 ) } 'invalid keys are detected and reported';

# the example from PDL::hist
$x = pdl( 13,10,13,10,9,13,9,12,11,10,10,13,7,6,8,10,11,7,12,9,11,11,12,6,12,7 );
$expected = indx( 0,0,0,0,0,0,2,3,1,3,5,4,4,4,0,0,0,0,0,0 );
$got = ndbin( $x, 0, 20, 1 );
is_pdl $got, $expected, 'example from PDL::hist';

# test variables and actions
$x = pdl( 13,10,13,10,9,13,9,12,11,10,10,13,7,6,8,10,11,7,12,9,11,11,12,6,12,7 );
$expected = double( 0,0,0,0,0,0,2,3,1,3,5,4,4,4,0,0,0,0,0,0 );
$got = ndbin( $x, 0,20,1, vars => [ [ $x, 'Count' ] ] );
is_pdl $got, $expected->convert( indx ), 'variable with action Count';
$expected = pdl( 0,0,0,0,0,0,6,7,8,9,10,11,12,13,0,0,0,0,0,0 )->inplace->setvaltobad( 0 );
$got = ndbin( $x, 0,20,1,
	      vars => [ [ $x => sub { my $iter = shift;
				      $iter->want->nelem ? $iter->selection->avg : undef } ] ] );
is_pdl $got, $expected, 'variable with action = average, specified as a coderef';
$got = ndbin( $x, 0,20,1, vars => [ [ $x => 'Avg' ] ] );
is_pdl $got, $expected, 'variable with action = average, specified as a class name';
$x = pdl( 1,1,1,2,2,1,1,1,2 );
$y = pdl( 2,1,3,4,1,4,4,4,1 );
$z = pdl( 0,1,2,3,4,5,6,7,8 );
$expected = pdl( [1,2],
		 [1,0],
		 [1,0],
		 [3,1] );
$got = ndbin( $x, { step=>1, min=>1, n=>2 },
	      $y, { step=>1, min=>1, n=>4 },
	      vars => [ [ $z => \&debug_action ] ] );
is_pdl $got, $expected, 'variable with action = debug_action';
$got = ndbin( axes => [ [ $x, step=>1, min=>1, n=>2 ],
			[ $y, step=>1, min=>1, n=>4 ] ],
	      vars => [ [ null->double, \&debug_action ] ] );
is_pdl $got, $expected, 'variable with action = debug_action, null PDL, and full spec';

# binning integer data
$x = short( 1,2,3,4 );
$expected = indx( 1,1,1,1 ); # by default ndbin chooses n(bins)=n(data el.) if n(data el.) < 100
$got = ndbin( $x );
is_pdl $got, $expected, 'binning integer data: range = 1..4, auto parameters';
$x = short( 1,2,3,4,5,6,7,8 );
$expected = indx( 2,2,2,2 );
$got = ndbin( $x, { step => 2 } );
is_pdl $got, $expected, 'binning integer data: range = 1..4, step = 2';
$got = ndbin( $x, { n => 4 } );
is_pdl $got, $expected, 'binning integer data: range = 1..4, n = 4';
$x = short( -3,-2,-1,0,1,2 );
$expected = indx( 2,2,2 );
$got = ndbin( $x => { n => 3 } );
is_pdl $got, $expected, 'binning integer data: range = -3..2, n = 3';
$x = short( -3,-2,-1,0,1,2,3 );
$expected = indx( 4,3 );
$got = ndbin( $x => { n => 2 } );
is_pdl $got, $expected, 'binning integer data: range = -3..3, n = 2';
$x = short( -3,-2,-1,0,1,2,3 );
$expected = indx( 3,2,2 );
$got = ndbin( $x => { n => 3 } );
is_pdl $got, $expected, 'binning integer data: range = -3..3, n = 3';
$x = short( 3,4,5,6,7,8,9,10,11 );
$expected = indx( [9] );
$got = ndbin( $x, { step => 10 } );
is_pdl $got, $expected, 'binning integer data: range = 3..11, step = 10';
$got = ndbin( $x, { n => 1 } );
is_pdl $got, $expected, 'binning integer data: range = 3..11, n = 1';
$x = short( 3,4,5,6,7,8,9,10,11,12 );
$expected = indx( [10] );
$got = ndbin( $x, { step => 10 } );
is_pdl $got, $expected, 'binning integer data: range = 3..12, step = 10';
$got = ndbin( $x, { n => 1 } );
is_pdl $got, $expected, 'binning integer data: range = 3..12, n = 1';
$expected = indx( 5,5 );
$got = ndbin( $x, { n => 2 } );
is_pdl $got, $expected, 'binning integer data: range = 3..12, n = 2';
$x = short( 3,4,5,6,7,8,9,10,11,12,13 );
$expected = indx( 10,1 );
$got = ndbin( $x, { step => 10 } );
is_pdl $got, $expected, 'binning integer data: range = 3..13, step = 10';
$expected = indx( 6,5 );
$got = ndbin( $x, { n => 2 } );
is_pdl $got, $expected, 'binning integer data: range = 3..13, n = 2';

# test with weird data
dies_ok { ndbin( pdl( 3,3,3 ) ) } 'data range = 0';
$expected = indx( [3] );
$got = ndbin( short( 1,1,1 ), { n => 1 } );
is_pdl $got, $expected, 'data range = 0 BUT integral data and n = 1 (corner case)';
dies_ok { ndbin( short( 1,2 ), { n => 4 } ) } 'invalid data: step size < 1 for integral data';

# test exceptions in actions
$x = pdl( 1,2,3 );
$expected = create_bad long, 3;
throws_ok { ndbin( $x, vars => [ [ null, sub { die } ] ] ) }
	qr/^Died at /, 'exceptions in actions passed through';
lives_ok { ndbin( $x, vars => [ [ null() => sub { shift->want->min } ] ] ) }
	'want->min on empty piddle does not die';
throws_ok { ndbin( $x, vars => [ [ null() => sub { shift->selection->min } ] ] ) }
	qr/^PDL::index: invalid index 0 /, 'selection->min on empty piddle';
throws_ok { ndbin( $x, vars => [ [ null() => sub { shift->wrong_method } ] ] ) }
	qr/^Can't locate object method "wrong_method"/, 'call nonexistent method';
lives_ok { $got = ndbin( $x, vars => [ [ null->long, sub { eval { die } } ] ] ) }
	'does not raise an exception when wrapping action in an eval block ...';
is_pdl $got, $expected, '... and all values are unset';

# test action arguments
$x = pdl( 1,3,3 );
$y = pdl( 1,3,3 );
$z = pdl( 9,0,1 );
$expected = zeroes(2,3,4)->long + 1;
$got = ndbin( $x => { n => 2 },
	      $y => { n => 3 },
	      $z => { n => 4 },
	      vars => [ [ null->long, sub { @_ } ] ] );
is_pdl $got, $expected, 'number of arguments for actions';

# test unflattened bin numbers
$x = sequence 10;
$y = sequence 10;
$z = sequence 10;
$expected = sequence( 2*5*3 )->long->reshape( 2, 5, 3 );
$got = ndbin( $x => { n => 2 },
	      $y => { n => 5 },
	      $z => { n => 3 },
	      vars => [ [ null->long, sub { my @u = shift->unflatten; $u[0] + 2*$u[1] + 2*5*$u[2] } ] ] );
is_pdl $got, $expected, 'bin numbers returned from iterator';

# simulate the functionality formerly known as SKIP_EMPTY
# note that we have to supply a fake variable of type `indx' to simulate the
# behaviour of PDL::NDBin::Action::Count
$x = pdl( 1,3,3 );		# 3 bins, but middle bin will be empty
$expected = indx( 1,0,2 );
$got = ndbin( $x, vars => [ [ $x => 'Count' ] ] );
is_pdl $got, $expected, 'do not skip empty bins, action class';
$got = ndbin( $x, vars => [ [ null->convert( indx ) => sub { shift->want->nelem } ] ] );
is_pdl $got, $expected, 'do not skip empty bins, action coderef';
$expected->inplace->setvaltobad( 0 );
$got = ndbin( $x, vars => [ [ null->convert( indx ) => sub { my $n = shift->want->nelem; return unless $n; $n } ] ] );
is_pdl $got, $expected, 'skip empty bins (cannot be achieved with action class)';

# this is an attempt to catch a strange test failure ...
# test whether the number of bins in the final histogram is chosen as
# advertised
for my $n ( 5,21,99,100,101,1000 ) {
	my $x = random( $n );
	my $histogram = ndbin( $x );
	is $histogram->nelem, $n < 100 ? $n : 100, q{uses $n bins if 'n' not supplied, where $n = nelem} or diag $x;
}

# cross-check with hist and some random data
$x = pdl( 0.7143, 0.6786, 0.9214, 0.5065, 0.9963, 0.9703, 0.1574, 0.4718,
	0.4099, 0.7701, 0.1881, 0.9412, 0.0034, 0.4440, 0.9423, 0.2065, 0.9656,
	0.5672, 0.2300, 0.5300, 0.1842 );
$y = pdl( 0.7422, 0.0299, 0.6629, 0.9118, 0.1224, 0.6173, 0.9203, 0.9999,
	0.1480, 0.4297, 0.5000, 0.9637, 0.1148, 0.2922, 0.0846, 0.0954, 0.1379,
	0.3187, 0.1655, 0.5777, 0.3047 );
# The following tests had to be disabled, as the computation for the default
# number of bins in hist() has changed between 2.4.11 and 2.4.12. Anyway, it
# was not even documented, so we shouldn't have relied on it in the first
# place.
#$expected = hist( $x )->convert( indx );		# reference values computed by PDL's built-in `hist'
#$got = ndbin( $x );
#is_pdl $got, $expected, 'cross-check $x with hist';
#$expected = hist( $y )->convert( indx );
#$got = ndbin( $y );
#is_pdl $got, $expected, 'cross-check $y with hist';
$expected = hist( $x, 0, 1, 0.1 )->convert( indx );
$got = ndbin( $x, 0, 1, 0.1 );
is_pdl $got, $expected, 'cross-check $x with hist, with (min,max,step) supplied';
$expected = hist( $y, 0, 1, 0.1 )->convert( indx );
$got = ndbin( $y, 0, 1, 0.1 );
is_pdl $got, $expected, 'cross-check $y with hist, with (min,max,step) supplied';
$expected = histogram( $x, .1, 0, 10 )->convert( indx );
$got = ndbin( $x, { step => .1, min => 0, n => 10 } );
is_pdl $got, $expected, 'cross-check $x with histogram';
$expected = histogram( $y, .1, 0, 10 )->convert( indx );
$got = ndbin( $y, { step => .1, min => 0, n => 10 } );
is_pdl $got, $expected, 'cross-check $y with histogram';
$expected = histogram2d( $x, $y, .1, 0, 10, .1, 0, 10 )->convert( indx );
$got = ndbin( $x, { step => .1, min => 0, n => 10 },
	      $y, { step => .1, min => 0, n => 10 } );
is_pdl $got, $expected, 'cross-check with histogram2d';
