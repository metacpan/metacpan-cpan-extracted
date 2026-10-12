use v5.32;
use warnings;

use feature 'signatures';
no warnings 'experimental::signatures';

use Test2::V0;

use Term::Fabulous::Render::Geometry qw(line_steps);

# The steps of a line as [ first, pixels... ] for comparison.
sub steps (@line) {
	my ( $first, @pixels ) = line_steps(@line);
	return [ $first, @pixels ];
}

subtest 'lines in a 6 x 4 raster' => sub {

	# [ x0, y0, x1, y1, first, pixels, what ]
	my @cases = (
		[  1,  1, 4,   1, 0, [ [ 1, 1 ], [ 2, 1 ], [ 3, 1 ], [ 4, 1 ] ],                     'horizontal' ],
		[  2,  0, 2,   3, 0, [ [ 2, 0 ], [ 2, 1 ], [ 2, 2 ], [ 2, 3 ] ],                     'vertical' ],
		[  3,  2, 3,   2, 0, [ [ 3, 2 ] ],                                                   'a single pixel' ],
		[  0,  0, 3,   3, 0, [ [ 0, 0 ], [ 1, 1 ], [ 2, 2 ], [ 3, 3 ] ],                     'a diagonal steps along x' ],
		[  0,  0, 5,   2, 0, [ [ 0, 0 ], [ 1, 0 ], [ 2, 1 ], [ 3, 1 ], [ 4, 2 ], [ 5, 2 ] ], 'shallow: halves round up on the minor axis' ],
		[  1,  0, 2,   3, 0, [ [ 1, 0 ], [ 1, 1 ], [ 2, 2 ], [ 2, 3 ] ],                     'steep: one step per row' ],
		[  4,  1, 1,   1, 0, [ [ 4, 1 ], [ 3, 1 ], [ 2, 1 ], [ 1, 1 ] ],                     'reversed: from the start point' ],
		[  3,  3, 0,   0, 0, [ [ 3, 3 ], [ 2, 2 ], [ 1, 1 ], [ 0, 0 ] ],                     'reversed diagonal' ],
		[ -2,  0, 3,   1, 2, [ [ 0, 0 ], [ 1, 1 ], [ 2, 1 ], [ 3, 1 ] ],                     'starting left of the raster: the first step inside is 2' ],
		[  3,  1, 9,   1, 0, [ [ 3, 1 ], [ 4, 1 ], [ 5, 1 ] ],                               'leaving the raster on the right' ],
		[ -3,  2, 8,   2, 3, [ map { [ $_, 2 ] } 0 .. 5 ],                                   'crossing the raster' ],
		[  1,  6, 1,  -5, 3, [ map { [ 1, $_ ] } reverse 0 .. 3 ],                           'crossing it upward' ],
		[  7,  1, 10,  2, 0, [],                                                             'entirely right of the raster: no pixels' ],
		[ -9, -9, -2, -5, 9, [],                                                             'entirely before it: the first step lies beyond the line' ],
		[  0, -2, 5,  -1, 0, [ map { [ $_, $_ < 3 ? -2 : -1 ] } 0 .. 5 ],                    'inside along x but above: the pixels lie outside on y (the writer skips them)' ],
	);
	foreach my $case (@cases) {
		my ( $x0, $y0, $x1, $y1, $first, $pixels, $what ) = @$case;
		is steps( $x0, $y0, $x1, $y1, 6, 4 ), [ $first, @$pixels ], $what;
	}
};

subtest 'far longer than the raster' => sub {
	my ( $first, @pixels ) = line_steps( -1_000_000, 0, 1_000_000, 1, 6, 4 );
	is [ $first, scalar @pixels ], [ 1_000_000, 6 ],             'only the six steps inside are computed';
	is \@pixels,                   [ map { [ $_, 1 ] } 0 .. 5 ], 'and they lie past the middle of the line, on its second row';
};

# Every step of the whole line, Bresenham's way, for comparison.
sub all_steps ( $x0, $y0, $x1, $y1 ) {
	my ( $dx, $dy ) = ( abs( $x1 - $x0 ), abs( $y1 - $y0 ) );
	my ( $sx, $sy ) = ( $x0 < $x1 ? 1 : -1, $y0 < $y1 ? 1 : -1 );
	my $major = $dx >= $dy ? $dx : $dy;
	my $minor = $dx >= $dy ? $dy : $dx;
	return map {
		my $moved = $major ? int( ( 2 * $minor * $_ + $major ) / ( 2 * $major ) ) : 0;
		$dx >= $dy ? [ $x0 + $sx * $_, $y0 + $sy * $moved ] : [ $x0 + $sx * $moved, $y0 + $sy * $_ ];
	} 0 .. $major;
}

subtest 'the clipped steps are the steps of the whole line inside the raster' => sub {
	my ( $width, $height ) = ( 7, 5 );
	my ( @got,   @expected );
	foreach my $x0 ( -3, 0, 4, 9 ) {
		foreach my $y0 ( -2, 0, 3, 7 ) {
			foreach my $x1 ( -4, 2, 6, 11 ) {
				foreach my $y1 ( -3, 1, 4, 8 ) {
					my @all    = all_steps( $x0, $y0, $x1, $y1 );
					my $along  = abs( $x1 - $x0 ) >= abs( $y1 - $y0 ) ? 0       : 1;
					my $limit  = $along                               ? $height : $width;
					my @inside = grep { $all[$_][$along] >= 0 && $all[$_][$along] < $limit } 0 .. $#all;
					my ( $first, @pixels ) = line_steps( $x0, $y0, $x1, $y1, $width, $height );
					push @got,      [ "$x0,$y0 -> $x1,$y1", @inside ? $first     : 'none', @pixels ];
					push @expected, [ "$x0,$y0 -> $x1,$y1", @inside ? $inside[0] : 'none', @all[@inside] ];
				}
			}
		}
	}
	is \@got, \@expected, 'for 256 lines in, through and around the raster';
};

done_testing;
