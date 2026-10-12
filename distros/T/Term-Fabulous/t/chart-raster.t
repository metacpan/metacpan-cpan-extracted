use v5.32;
use warnings;
use utf8;

use Test2::V0;

use Term::Fabulous::Chart::Marker;
use Term::Fabulous::Chart::Raster;

sub raster {
	my ( $marker, $columns, $rows ) = @_;
	return Term::Fabulous::Chart::Raster->new( marker => Term::Fabulous::Chart::Marker->named($marker), columns => $columns, rows => $rows );
}

# One line per subpixel row: '#' for a drawn subpixel, '.' for an empty one.
sub pixels {
	my ($raster) = @_;
	return [
		map {
			my $y = $_;
			join '', map { defined $raster->color_at( $_, $y ) ? '#' : '.' } 0 .. $raster->width - 1
		} 0 .. $raster->height - 1
	];
}

subtest 'construction' => sub {
	my $raster = raster( braille => 3, 2 );
	is [ $raster->columns, $raster->rows, $raster->width, $raster->height ], [ 3, 2, 6, 8 ], 'cells and subpixels';
	is $raster->marker->name,                                                'braille',      'the marker';
	ok $raster->is_empty, 'nothing drawn yet';
	like dies { Term::Fabulous::Chart::Raster->new( marker => 'braille', columns => 1, rows => 1 ) }, qr/marker must be a Term::Fabulous::Chart::Marker/, 'a marker name is not a marker';
	like dies { raster( half => -1, 1 ) },     qr/columns must be a non-negative integer, got -1/, 'negative columns';
	like dies { raster( half =>  1, undef ) }, qr/rows must be a non-negative integer, got undef/, 'no rows';
};

subtest 'set and blend' => sub {
	my $raster = raster( quadrant => 2, 1 );
	$raster->set( 1, 0, 0x102030, 'a' );
	is [ $raster->color_at( 1, 0 ), $raster->owner_at( 1, 0 ) ], [ 0x102030, 'a' ], 'set colors a subpixel and tags its owner';
	ok !$raster->is_empty, 'no longer empty';
	$raster->set( $_->[0], $_->[1], 1 ) foreach [ -1, 0 ], [ 4, 0 ], [ 0, 2 ];
	is pixels($raster),                                           [ '.#..', '....' ], 'outside the raster nothing happens';
	is [ $raster->color_at( -1, 0 ), $raster->owner_at( 0, 9 ) ], [ undef,  undef ],  'reading outside gives undef';

	$raster->set( 0, 0, 0x000000 );
	$raster->blend( 0, 0, 0xFFFFFF, 0.5, 0xFF0000, 'b' );
	is [ $raster->color_at( 0, 0 ), $raster->owner_at( 0, 0 ) ], [ 0x808080, 'b' ], 'blend mixes into the color there';
	$raster->blend( 2, 1, 0xFFFFFF, 0.25, 0x000000 );
	is $raster->color_at( 2, 1 ), 0x404040, 'or into the base where nothing was drawn';
	$raster->blend( 3, 1, 0x123456, 1, 0x000000 );
	is $raster->color_at( 3, 1 ), 0x123456, 'full opacity sets the color';
};

subtest 'lines' => sub {
	my $raster = raster( quadrant => 3, 3 );
	ref_is $raster->line( 0, 0, 5, 2, 1 ), $raster, 'line returns the raster';
	is pixels($raster), [ '##....', '..##..', '....##', ('......') x 3 ], 'from end point to end point';

	$raster = raster( quadrant => 3, 3 )->line( 5.9, 5.1, 3.2, 0.7, 1 );
	is pixels($raster), [ '...#..', '...#..', '....#.', '....#.', '.....#', '.....#' ], 'continuous coordinates, in either direction';

	$raster = raster( quadrant => 3, 3 )->line( -1e6, -1e6 + 2, 1e6, 1e6 + 2, 1, 'far' );
	is pixels($raster),           [ '......', '......', '#.....', '.#....', '..#...', '...#..' ], 'a line far longer than the raster draws the part inside it';
	is $raster->owner_at( 0, 2 ), 'far',                                                          'with its owner';

	$raster = raster( quadrant => 2, 1 )->line( 0, 0, 3, 0, 0xFFFFFF, undef, 0.5, 0x000000 );
	is [ map { $raster->color_at( $_, 0 ) } 0 .. 3 ], [ (0x808080) x 4 ], 'a translucent line blends into the base';
};

subtest 'dash patterns' => sub {
	my $raster = raster( quadrant => 4, 1 );
	ref_is $raster->start_pattern( [ 2, 1 ] ), $raster, 'start_pattern returns the raster';
	$raster->line( 0, 0, 7, 0, 1 );
	is pixels($raster)->[0], '##.##.##', 'two on, one off';

	$raster = raster( quadrant => 4, 1 )->start_pattern( [ 2, 1 ] );
	$raster->line( 0, 0, 1, 0, 1 )->line( 2, 1, 7, 1, 1 );
	is pixels($raster), [ '##......', '...##.##' ], 'the pattern runs on from line to line';

	$raster->start_pattern( [ 2, 1 ] )->line( 0, 1, 7, 1, 2 );
	is pixels($raster)->[1], '##.##.##', 'start_pattern restarts it';

	$raster = raster( quadrant => 4, 1 )->start_pattern( [ 2, 1 ] )->line( -3, 0, 7, 0, 1 );
	is pixels($raster)->[0], '##.##.##', 'a clipped line keeps the phase of its start';

	$raster = raster( quadrant => 4, 1 )->start_pattern( [ 1, 1, 3, 1 ] )->line( 0, 0, 7, 0, 1 );
	is pixels($raster)->[0], '#.###.#.', 'longer patterns alternate on and off';

	$raster = raster( quadrant => 4, 1 )->start_pattern( [ 2, 1 ] )->start_pattern(undef)->line( 0, 0, 7, 0, 1 );
	is pixels($raster)->[0], '########', 'undef draws solid lines';
	$raster = raster( quadrant => 4, 1 )->start_pattern( [] )->line( 0, 0, 7, 0, 1 );
	is pixels($raster)->[0], '########', 'so does an empty pattern';
};

subtest 'fills take the subpixels whose centers lie inside' => sub {
	my $raster = raster( quadrant => 3, 2 );
	ref_is $raster->fill_rect( 0, 0, 2.5, 1, 1, 'left' ), $raster, 'fill_rect returns the raster';
	$raster->fill_rect( 6, 1, 2.5, 0, 2, 'right' );
	is pixels($raster),                               [ '######', '......', '......', '......' ], 'two rectangles sharing an edge';
	is [ map { $raster->owner_at( $_, 0 ) } 0 .. 5 ], [ ('left') x 2, ('right') x 4 ],            'do not overlap';

	$raster = raster( quadrant => 3, 2 )->fill_rect( 1.5, 0.5, 3.5, 2.5, 1 );
	is pixels($raster), [ '.##...', '.##...', '......', '......' ], 'a center on the near edge is inside, on the far edge outside';
	$raster = raster( quadrant => 3, 2 )->fill_rect( -5, 3, 9, 9, 1 )->fill_rect( 1, 0, 1, 4, 1 );
	is pixels($raster), [ ('......') x 3, '######' ], 'clipped to the raster; an empty rectangle draws nothing';

	$raster = raster( quadrant => 2, 3 );
	ref_is $raster->fill_column( 1, 4.6, 1.4, 1 ), $raster, 'fill_column returns the raster';
	$raster->fill_column( -1, 0, 6, 1 )->fill_column( 4, 0, 6, 1 )->fill_column( 3, 2, 2, 1 );
	is pixels($raster), [ '....', '.#..', '.#..', '.#..', '.#..', '....' ], 'one column between two heights, in either order';

	$raster = raster( quadrant => 2, 1 )->fill_rect( 0, 0, 4, 2, 0xFFFFFF, undef, 0.25, 0x000000 );
	is $raster->color_at( 3, 1 ), 0x404040, 'a translucent fill blends';
};

subtest 'fill_polygon' => sub {
	my $raster = raster( quadrant => 3, 3 );
	ref_is $raster->fill_polygon( [ [ 0, 3 ], [ 3, 0 ], [ 6, 3 ], [ 3, 6 ] ], 1 ), $raster, 'fill_polygon returns the raster';
	is pixels($raster), [ '..#...', '.###..', '#####.', '#####.', '.###..', '..#...' ], 'a diamond';

	$raster = raster( quadrant => 3, 3 )->fill_polygon( [ [ 0, 0 ], [ 6, 0 ], [ 6, 6 ], [ 0, 6 ], [ 0, 2 ], [ 4, 2 ], [ 4, 4 ], [ 2, 4 ], [ 2, 2 ], [ 0, 2 ] ], 1 );
	is pixels($raster), [ '######', '######', '##..##', '##..##', '######', '######' ], 'even-odd: an inner ring is a hole';

	$raster = raster( quadrant => 3, 3 )->fill_polygon( [ [ 0, 0 ], [ 6, 6 ] ], 1 );
	ok $raster->is_empty, 'fewer than three corners draw nothing';
};

subtest 'paint_area' => sub {
	my $raster = raster( quadrant => 2, 1 );
	my @asked;
	ref_is $raster->paint_area( -1, -1, 3, 9, sub { my ( $x, $y ) = @_; push @asked, "$x,$y"; return ( $x + $y ) % 2 ? () : ( 1, "$x$y" ) } ), $raster, 'paint_area returns the raster';
	is \@asked,                   [ '0,0', '1,0', '2,0', '0,1', '1,1', '2,1' ], 'every subpixel of the clipped area, row by row';
	is pixels($raster),           [ '#.#.', '.#..' ],                           'the empty list leaves a subpixel';
	is $raster->owner_at( 1, 1 ), '11',                                         'with the owner returned';
};

subtest 'each_cell' => sub {
	my $raster = raster( braille => 2, 1 );
	$raster->set( 3, 0, 0xAA, 'x' );
	$raster->set( 0, 1, 0xBB, 'y' );
	$raster->set( 1, 0, 0xCC );
	$raster->set( 2, 3, 0xDD, 'z' );
	my @visits;
	$raster->each_cell( sub { push @visits, [@_] } );
	is \@visits, [
		[ 1, 0, [ undef, 0xAA, (undef) x 4, 0xDD, undef ], [ undef, 'x', (undef) x 4, 'z', undef ], [ undef, 1, (undef) x 4, 4, undef ] ],
		[ 0, 0, [ undef, 0xCC, 0xBB, (undef) x 5 ], [ (undef) x 2, 'y', (undef) x 5 ], [ undef, 3, 2, (undef) x 5 ] ],
		],
		'the drawn cells in the order first drawn, their subpixels row by row, with when each was drawn';
};

subtest 'the dot drawn last colors a Braille cell' => sub {
	my $raster = raster( braille => 1, 1 );
	$raster->set( $_, 0, 0x111111 ) foreach 0, 1;
	$raster->set( 0,  1, 0x111111 );
	$raster->set( 1,  3, 0x222222 );
	my ($cell) = do {
		my @cells;
		$raster->each_cell( sub { push @cells, [@_] } );
		@cells;
	};
	my ( undef, $fg ) = $raster->marker->cell( $cell->[2], undef, $cell->[4] );
	is $fg, 0x222222, 'with the drawing order, the later color wins over the more frequent one';
	( undef, $fg ) = $raster->marker->cell( $cell->[2], undef );
	is $fg, 0x111111, 'without it, the most frequent color';
};

done_testing;
