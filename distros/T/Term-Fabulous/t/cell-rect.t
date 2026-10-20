use v5.32;
use warnings;

use Test2::V0;

use Term::Fabulous::Render::Geometry qw(cell_rect);

subtest 'edges round to the nearest cell' => sub {
	is [ cell_rect( { x =>  1.7, y =>  2,   width => 3.6, height => 2 } ) ],   [  2, 2, 5, 4 ], 'the synopsis: 1.7 rounds up, 5.3 down';
	is [ cell_rect( { x =>  2.5, y =>  0.5, width => 3,   height => 1 } ) ],   [  3, 1, 6, 2 ], 'halves round up';
	is [ cell_rect( { x => -0.7, y => -0.3, width => 2,   height => 1.4 } ) ], [ -1, 0, 1, 1 ], 'negative coordinates round the same way';
	is [ cell_rect( { x =>  4.2, y =>  0,   width => 0.2, height => 1 } ) ],   [  4, 0, 4, 1 ], 'a box narrower than half a cell is empty';
};

subtest 'boxes that meet share a cell edge' => sub {

	# Clay's single-precision floats: the left box's right edge comes out
	# a hair below the right box's left edge.
	my @left  = cell_rect( { x => 46.05, y => 0, width => 24.95 - 1e-5, height => 1 } );
	my @right = cell_rect( { x => 71,    y => 0, width => 11, height => 1 } );
	is [ $left[2], $right[0] ], [ 71, 71 ], 'an edge of 70.9999 and one of 71 land on the same cell, no blank column between';
};

done_testing;
