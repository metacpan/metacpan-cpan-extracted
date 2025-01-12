use v5.36;
use utf8;
use open qw(:std :utf8);

use Test::More;
END { done_testing() }

my $class = 'XYPoint';

use constant π => 3.1415926;

subtest setup => sub {
	use_ok( 'PeGS::PDF' );
	can_ok( $class, qw(new x y xy clone add add_x add_y) );
	};

subtest 'simple point' => sub {
	my $x = 54;
	my $y = 67;

	my $point = $class->new( $x, $y );
	isa_ok( $point, $class );
	is( $point->x, $x, 'x value' );
	is( $point->y, $y, 'y value' ); # ,

	my( $x1, $y1 ) = $point->xy;
	is( $x1, $x, 'x value from xy' );
	is( $y1, $y, 'y value from xy' );

	};

subtest 'add to point' => sub {
	my $x = 54;
	my $y = 67;

	my $point = $class->new( $x, $y );
	isa_ok( $point, $class );
	is( $point->x, $x, 'x value' );
	is( $point->y, $y, 'y value' ); # ,

	my( $dx, $dy ) = ( 3, 8 );

	$point->add( $dx, $dy );
	is( $point->x, $x + $dx, "x value after adding $dx" );
	is( $point->y, $y + $dy, "y value after adding $dy" ); # ,
	};

subtest 'clone point' => sub {
	my $x = 54;
	my $y = 67;

	my $point = $class->new( $x, $y );
	isa_ok( $point, $class );
	is( $point->x, $x, 'x value' );
	is( $point->y, $y, 'y value' ); #,

	my( $dx, $dy ) = ( 3, 8 );

	my $cloned = $point->clone;
	isa_ok( $cloned, $class, "cloned object" );

	$cloned->add( $dx, $dy );
	is( $cloned->x, $x + $dx, "cloned x value after adding $dx" );
	is( $cloned->y, $y + $dy, "cloned y value after adding $dy" ); # ,

	my( $x1, $y1 ) = $cloned->xy;
	is( $x1, $x + $dx, 'x value from xy' );
	is( $y1, $y + $dy, 'y value from xy' );


	is( $point->x, $x, 'original x value after clone is the same' );
	is( $point->y, $y, 'original y value after clone is the same' ); # ,
	};

subtest 'angle and distance' => sub {
	my @table = (
		[ [0,0], [ 1, 1],  1/4 * π, sqrt(2) ],
		[ [0,0], [-1, 1],  3/4 * π, sqrt(2) ],
		[ [0,0], [ 1,-1], -1/4 * π, sqrt(2) ],
		[ [0,0], [-1,-1], -3/4 * π, sqrt(2) ],

		[ [0,0], [ 0, 1],  1/2 * π, 1 ],
		[ [0,0], [ 0,-1], -1/2 * π, 1 ],
		[ [0,0], [ 1, 0],    0 * π, 1 ],
		[ [0,0], [-1, 0],    1 * π, 1 ],
		);

	foreach my $tuple ( @table ) {
		my( $p1, $p2, $expected_angle, $expected_length ) = $tuple->@*;

		my $label = sprintf "%s to %s", map { local $" = ', '; "(@$_)" } ( $p1, $p2 );
		subtest $label => sub {
			$p1 = $class->new( $p1->@* );
			$p2 = $class->new( $p2->@* );
			isa_ok( $_, $class ) foreach ( $p1, $p2 );

			my( $cmp_op, $word ) = $expected_angle < 0 ? ('<', 'negative') : ('>=', 'positive');
			my( $angle, $distance ) = $p1->angle_length_to( $p2 );
			cmp_ok $angle, $cmp_op,  0,
				sprintf "angle from %s to %s is %s",
					map( { $_->as_string } ( $p1, $p2 ) ),
					$word
					;
			is
				sprintf( "%.2f", $angle),
				sprintf( "%.2f", $expected_angle ),
				"Angle is about π/4";
			is
				sprintf( "%.2f", $distance),
				sprintf( "%.2f", $expected_length ),
				"Distance is about the sqrt of 2";

			diag( "ANGLE: $angle" ); my $degree = $angle * 360 / 2 / 3.1415926;
			diag( "ANGLE: $degree" );
			diag( "DISTANCE: $distance" );
			};
		}
	};
