package Term::Fabulous::Screenshot::BoxDrawing;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Carp qw(croak);
use Exporter qw(import);
use List::Util qw(max min);

our @EXPORT_OK = qw(is_drawn_glyph glyph_shapes);

# Terminals draw the box drawing (U+2500-U+257F) and block element
# (U+2580-U+259F) characters themselves instead of taking them from the
# font, so lines meet across cells without gaps and half blocks split a
# cell exactly; many draw the Braille patterns (U+2800-U+28FF) and the
# sextants (U+1FB00-U+1FB3B) too. These shapes do the same for the
# screenshot renderers.
#
# Shapes are in the coordinates of one cell, (0, 0) at its top-left
# corner, in whole units of the renderer (pixels for PNG, user units for
# SVG): rectangles, filled with the cell's foreground color mixed over its
# background (coverage 1 is the foreground itself), polylines stroked in
# the foreground color, and circles (Braille dots) filled with it.

use constant { NONE => 0, LIGHT => 1, HEAVY => 2, DOUBLE => 3 };

# The four arms of each line character: up, right, down, left.
my %ARMS_BY_CODEPOINT = (
	0x2500 => [ 0, 1, 0, 1 ], 0x2501 => [ 0, 2, 0, 2 ], 0x2502 => [ 1, 0, 1, 0 ], 0x2503 => [ 2, 0, 2, 0 ],
	0x250C => [ 0, 1, 1, 0 ], 0x250D => [ 0, 2, 1, 0 ], 0x250E => [ 0, 1, 2, 0 ], 0x250F => [ 0, 2, 2, 0 ],
	0x2510 => [ 0, 0, 1, 1 ], 0x2511 => [ 0, 0, 1, 2 ], 0x2512 => [ 0, 0, 2, 1 ], 0x2513 => [ 0, 0, 2, 2 ],
	0x2514 => [ 1, 1, 0, 0 ], 0x2515 => [ 1, 2, 0, 0 ], 0x2516 => [ 2, 1, 0, 0 ], 0x2517 => [ 2, 2, 0, 0 ],
	0x2518 => [ 1, 0, 0, 1 ], 0x2519 => [ 1, 0, 0, 2 ], 0x251A => [ 2, 0, 0, 1 ], 0x251B => [ 2, 0, 0, 2 ],
	0x251C => [ 1, 1, 1, 0 ], 0x251D => [ 1, 2, 1, 0 ], 0x251E => [ 2, 1, 1, 0 ], 0x251F => [ 1, 1, 2, 0 ],
	0x2520 => [ 2, 1, 2, 0 ], 0x2521 => [ 2, 2, 1, 0 ], 0x2522 => [ 1, 2, 2, 0 ], 0x2523 => [ 2, 2, 2, 0 ],
	0x2524 => [ 1, 0, 1, 1 ], 0x2525 => [ 1, 0, 1, 2 ], 0x2526 => [ 2, 0, 1, 1 ], 0x2527 => [ 1, 0, 2, 1 ],
	0x2528 => [ 2, 0, 2, 1 ], 0x2529 => [ 2, 0, 1, 2 ], 0x252A => [ 1, 0, 2, 2 ], 0x252B => [ 2, 0, 2, 2 ],
	0x252C => [ 0, 1, 1, 1 ], 0x252D => [ 0, 1, 1, 2 ], 0x252E => [ 0, 2, 1, 1 ], 0x252F => [ 0, 2, 1, 2 ],
	0x2530 => [ 0, 1, 2, 1 ], 0x2531 => [ 0, 1, 2, 2 ], 0x2532 => [ 0, 2, 2, 1 ], 0x2533 => [ 0, 2, 2, 2 ],
	0x2534 => [ 1, 1, 0, 1 ], 0x2535 => [ 1, 1, 0, 2 ], 0x2536 => [ 1, 2, 0, 1 ], 0x2537 => [ 1, 2, 0, 2 ],
	0x2538 => [ 2, 1, 0, 1 ], 0x2539 => [ 2, 1, 0, 2 ], 0x253A => [ 2, 2, 0, 1 ], 0x253B => [ 2, 2, 0, 2 ],
	0x253C => [ 1, 1, 1, 1 ], 0x253D => [ 1, 1, 1, 2 ], 0x253E => [ 1, 2, 1, 1 ], 0x253F => [ 1, 2, 1, 2 ],
	0x2540 => [ 2, 1, 1, 1 ], 0x2541 => [ 1, 1, 2, 1 ], 0x2542 => [ 2, 1, 2, 1 ], 0x2543 => [ 2, 1, 1, 2 ],
	0x2544 => [ 2, 2, 1, 1 ], 0x2545 => [ 1, 1, 2, 2 ], 0x2546 => [ 1, 2, 2, 1 ], 0x2547 => [ 2, 2, 1, 2 ],
	0x2548 => [ 1, 2, 2, 2 ], 0x2549 => [ 2, 1, 2, 2 ], 0x254A => [ 2, 2, 2, 1 ], 0x254B => [ 2, 2, 2, 2 ],
	0x2550 => [ 0, 3, 0, 3 ], 0x2551 => [ 3, 0, 3, 0 ], 0x2552 => [ 0, 3, 1, 0 ], 0x2553 => [ 0, 1, 3, 0 ],
	0x2554 => [ 0, 3, 3, 0 ], 0x2555 => [ 0, 0, 1, 3 ], 0x2556 => [ 0, 0, 3, 1 ], 0x2557 => [ 0, 0, 3, 3 ],
	0x2558 => [ 1, 3, 0, 0 ], 0x2559 => [ 3, 1, 0, 0 ], 0x255A => [ 3, 3, 0, 0 ], 0x255B => [ 1, 0, 0, 3 ],
	0x255C => [ 3, 0, 0, 1 ], 0x255D => [ 3, 0, 0, 3 ], 0x255E => [ 1, 3, 1, 0 ], 0x255F => [ 3, 1, 3, 0 ],
	0x2560 => [ 3, 3, 3, 0 ], 0x2561 => [ 1, 0, 1, 3 ], 0x2562 => [ 3, 0, 3, 1 ], 0x2563 => [ 3, 0, 3, 3 ],
	0x2564 => [ 0, 3, 1, 3 ], 0x2565 => [ 0, 1, 3, 1 ], 0x2566 => [ 0, 3, 3, 3 ], 0x2567 => [ 1, 3, 0, 3 ],
	0x2568 => [ 3, 1, 0, 1 ], 0x2569 => [ 3, 3, 0, 3 ], 0x256A => [ 1, 3, 1, 3 ], 0x256B => [ 3, 1, 3, 1 ],
	0x256C => [ 3, 3, 3, 3 ],
	0x2574 => [ 0, 0, 0, 1 ], 0x2575 => [ 1, 0, 0, 0 ], 0x2576 => [ 0, 1, 0, 0 ], 0x2577 => [ 0, 0, 1, 0 ],
	0x2578 => [ 0, 0, 0, 2 ], 0x2579 => [ 2, 0, 0, 0 ], 0x257A => [ 0, 2, 0, 0 ], 0x257B => [ 0, 0, 2, 0 ],
	0x257C => [ 0, 2, 0, 1 ], 0x257D => [ 1, 0, 2, 0 ], 0x257E => [ 0, 1, 0, 2 ], 0x257F => [ 2, 0, 1, 0 ],
);

# Dashed lines: [ horizontal (1) or vertical (0), weight, dashes ].
my %DASHES_BY_CODEPOINT = (
	0x2504 => [ 1, LIGHT, 3 ], 0x2505 => [ 1, HEAVY, 3 ], 0x2506 => [ 0, LIGHT, 3 ], 0x2507 => [ 0, HEAVY, 3 ],
	0x2508 => [ 1, LIGHT, 4 ], 0x2509 => [ 1, HEAVY, 4 ], 0x250A => [ 0, LIGHT, 4 ], 0x250B => [ 0, HEAVY, 4 ],
	0x254C => [ 1, LIGHT, 2 ], 0x254D => [ 1, HEAVY, 2 ], 0x254E => [ 0, LIGHT, 2 ], 0x254F => [ 0, HEAVY, 2 ],
);

# Rounded corners: the two arms each one connects, [ vertical, horizontal ].
my %ARC_BY_CODEPOINT = (
	0x256D => [ 'down', 'right' ],
	0x256E => [ 'down', 'left' ],
	0x256F => [ 'up',   'left' ],
	0x2570 => [ 'up',   'right' ],
);

# Block elements as rectangles in eighths of the cell: [ left, top, right,
# bottom ], plus the coverage of the foreground (1 for solid, less for the
# shades). Quadrants split the cell at its middle.
my %BLOCKS_BY_CODEPOINT = (
	0x2580 => [ [ 0, 0, 8, 4 ] ],
	( map { ( 0x2580 + $_ => [ [ 0, 8 - $_, 8,      8 ] ] ) } 1 .. 8 ),    # lower one eighth .. full block
	( map { ( 0x2588 + $_ => [ [ 0, 0,      8 - $_, 8 ] ] ) } 1 .. 7 ),    # left seven eighths .. left one eighth
	0x2590 => [ [ 4, 0, 8, 8 ] ],
	0x2591 => [ [ 0, 0, 8, 8, 0.25 ] ],
	0x2592 => [ [ 0, 0, 8, 8, 0.5 ] ],
	0x2593 => [ [ 0, 0, 8, 8, 0.75 ] ],
	0x2594 => [ [ 0, 0, 8, 1 ] ],
	0x2595 => [ [ 7, 0, 8, 8 ] ],
	0x2596 => [ [ 0, 4, 4, 8 ] ],
	0x2597 => [ [ 4, 4, 8, 8 ] ],
	0x2598 => [ [ 0, 0, 4, 4 ] ],
	0x2599 => [ [ 0, 0, 4, 4 ], [ 0, 4, 8, 8 ] ],
	0x259A => [ [ 0, 0, 4, 4 ], [ 4, 4, 8, 8 ] ],
	0x259B => [ [ 0, 0, 8, 4 ], [ 0, 4, 4, 8 ] ],
	0x259C => [ [ 0, 0, 8, 4 ], [ 4, 4, 8, 8 ] ],
	0x259D => [ [ 4, 0, 8, 4 ] ],
	0x259E => [ [ 4, 0, 8, 4 ], [ 0, 4, 4, 8 ] ],
	0x259F => [ [ 4, 0, 8, 4 ], [ 0, 4, 8, 8 ] ],
);

use constant ARC_SEGMENTS => 12;

use constant {
	BRAILLE_FIRST => 0x2800,
	BRAILLE_LAST  => 0x28FF,
	SEXTANT_FIRST => 0x1FB00,
	SEXTANT_LAST  => 0x1FB3B,
};

# Braille dot bits by [ column, row ].
my @BRAILLE_DOTS = ( [ 0, 0, 0x01 ], [ 0, 1, 0x02 ], [ 0, 2, 0x04 ], [ 1, 0, 0x08 ], [ 1, 1, 0x10 ], [ 1, 2, 0x20 ], [ 0, 3, 0x40 ], [ 1, 3, 0x80 ] );

sub is_drawn_glyph ($glyph) {
	return 0 unless length($glyph) == 1;
	my $codepoint = ord $glyph;
	return 1 if $codepoint >= 0x2500        && $codepoint <= 0x259F;
	return 1 if $codepoint >= BRAILLE_FIRST && $codepoint <= BRAILLE_LAST;
	return 1 if $codepoint >= SEXTANT_FIRST && $codepoint <= SEXTANT_LAST;
	return 0;
}

# The dots of a Braille pattern: circles at the centers of a 2 x 4 grid,
# as terminals that draw them themselves show them.
sub _braille_shapes ( $codepoint, $cell ) {
	my ( $width, $height ) = @$cell{qw(width height)};
	my $bits   = $codepoint - BRAILLE_FIRST;
	my $radius = min( $width / 2, $height / 4 ) * 0.4;
	return map { { type => 'circle', cx => $width * ( 1 + 2 * $_->[0] ) / 4, cy => $height * ( 1 + 2 * $_->[1] ) / 8, r => $radius } }
		grep { $bits & $_->[2] } @BRAILLE_DOTS;
}

# Sextants: two columns and three rows of blocks. The code points count
# the masks 1 to 62 without the left (21) and right (42) halves.
sub _sextant_shapes ( $codepoint, $cell ) {
	my ( $width, $height ) = @$cell{qw(width height)};
	my $mask = $codepoint - SEXTANT_FIRST + 1;
	$mask++ if $mask >= 21;
	$mask++ if $mask >= 42;
	my @x = ( 0, int( $width / 2 + 0.5 ),  $width );
	my @y = ( 0, int( $height / 3 + 0.5 ), int( 2 * $height / 3 + 0.5 ), $height );
	return map { _rect( $x[ $_ % 2 ], $y[ int( $_ / 2 ) ], $x[ $_ % 2 + 1 ], $y[ int( $_ / 2 ) + 1 ] ) } grep { $mask & ( 1 << $_ ) } 0 .. 5;
}

# The shapes of $glyph in a cell $width x $height with light lines
# $thickness thick, all whole numbers. Dies for a glyph is_drawn_glyph
# rejects.
sub glyph_shapes ( $glyph, $width, $height, $thickness ) {
	croak "Term::Fabulous::Screenshot::BoxDrawing: '$glyph' is not a box drawing or block element character" unless is_drawn_glyph($glyph);
	croak "Term::Fabulous::Screenshot::BoxDrawing: the cell ($width x $height) and the line thickness ($thickness) must be positive whole numbers"
		unless _is_positive_integer($width) && _is_positive_integer($height) && _is_positive_integer($thickness);

	my $codepoint = ord $glyph;
	my $cell      = _cell_metrics( $width, $height, $thickness );
	return _braille_shapes( $codepoint, $cell ) if $codepoint >= BRAILLE_FIRST && $codepoint <= BRAILLE_LAST;
	return _sextant_shapes( $codepoint, $cell ) if $codepoint >= SEXTANT_FIRST;
	return _block_shapes( $BLOCKS_BY_CODEPOINT{$codepoint}, $cell ) if exists $BLOCKS_BY_CODEPOINT{$codepoint};
	return _line_shapes( $ARMS_BY_CODEPOINT{$codepoint}, $cell ) if exists $ARMS_BY_CODEPOINT{$codepoint};
	return _dash_shapes( @{ $DASHES_BY_CODEPOINT{$codepoint} }, $cell ) if exists $DASHES_BY_CODEPOINT{$codepoint};
	return _arc_shapes( @{ $ARC_BY_CODEPOINT{$codepoint} }, $cell ) if exists $ARC_BY_CODEPOINT{$codepoint};
	return _diagonal_shapes( $codepoint, $cell );
}

sub _is_positive_integer ($value) {
	return $value =~ /\A[1-9][0-9]*\z/ ? 1 : 0;
}

# A light line starts at x0 (vertical) or y0 (horizontal), so that every
# cell puts its lines at the same place and they meet seamlessly.
sub _cell_metrics ( $width, $height, $thickness ) {
	return {
		width     => $width,
		height    => $height,
		thickness => $thickness,
		x0        => int( ( $width - $thickness ) / 2 ),
		y0        => int( ( $height - $thickness ) / 2 ),
	};
}

sub _rect ( $left, $top, $right, $bottom, $coverage = 1 ) {
	return () if $right <= $left || $bottom <= $top;
	return { type => 'rect', x => $left, y => $top, width => $right - $left, height => $bottom - $top, coverage => $coverage };
}

sub _block_shapes ( $blocks, $cell ) {
	my ( $width, $height ) = @$cell{qw(width height)};
	my $x_at = sub ($eighths) { int( $width * $eighths / 8 + 0.5 ) };
	my $y_at = sub ($eighths) { int( $height * $eighths / 8 + 0.5 ) };
	return map { _rect( $x_at->( $_->[0] ), $y_at->( $_->[1] ), $x_at->( $_->[2] ), $y_at->( $_->[3] ), $_->[4] // 1 ) } @$blocks;
}

# The strokes of a line of the given weight across an axis that starts a
# light line at $start: [ from, to ] pairs, one for a single line, two
# rails for a double line.
sub _strokes ( $weight, $start, $thickness ) {
	return [ [ $start, $start + $thickness ] ] if $weight == LIGHT;
	if ( $weight == HEAVY ) {
		my $from = $start - int( $thickness / 2 );
		return [ [ $from, $from + 2 * $thickness ] ];
	}
	return [ [ $start - $thickness, $start ], [ $start + $thickness, $start + 2 * $thickness ] ] if $weight == DOUBLE;
	return [];
}

# Lines from the middle of the cell to its edges. Each arm is a single
# stroke or two rails. Single strokes reach across the arms that cross
# them, so corners and junctions are solid. A rail of a double arm stops
# at the arm on its side, overlapping its nearest stroke, or, when there
# is none, runs to the far side of the arm opposite, which closes the
# outer corner.
sub _line_shapes ( $arms, $cell ) {
	my ( $up, $right, $down, $left ) = @$arms;
	my ( $width, $height, $thickness, $x0, $y0 ) = @$cell{qw(width height thickness x0 y0)};

	my %vertical           = ( up   => _strokes( $up,   $x0, $thickness ), down  => _strokes( $down,  $x0, $thickness ) );
	my %horizontal         = ( left => _strokes( $left, $y0, $thickness ), right => _strokes( $right, $y0, $thickness ) );
	my @vertical_strokes   = map { @$_ } values %vertical;
	my @horizontal_strokes = map { @$_ } values %horizontal;

	# How far single strokes reach across the middle.
	my $vertical_low    = @vertical_strokes   ? min( map { $_->[0] } @vertical_strokes )   : $x0;
	my $vertical_high   = @vertical_strokes   ? max( map { $_->[1] } @vertical_strokes )   : $x0 + $thickness;
	my $horizontal_low  = @horizontal_strokes ? min( map { $_->[0] } @horizontal_strokes ) : $y0;
	my $horizontal_high = @horizontal_strokes ? max( map { $_->[1] } @horizontal_strokes ) : $y0 + $thickness;

	my @shapes;
	foreach my $arm ( [ left => $left ], [ right => $right ], [ up => $up ], [ down => $down ] ) {
		my ( $direction, $weight ) = @$arm;
		next if $weight == NONE;
		my $is_horizontal = $direction eq 'left' || $direction eq 'right';
		my $strokes       = $is_horizontal ? $horizontal{$direction} : $vertical{$direction};
		my $towards_end   = $direction eq 'left' || $direction eq 'up';    # the arm runs from 0 towards the middle
		my $length        = $is_horizontal ? $width : $height;

		my @spans;
		if ( $weight != DOUBLE ) {
			my ( $low, $high ) = $is_horizontal ? ( $vertical_low, $vertical_high ) : ( $horizontal_low, $horizontal_high );

			# A stem that ends at a line passing by (a T, as in ├ or ╢) stops
			# at the stroke of that line nearest to it, so it does not fill
			# the gap between the rails of a double line.
			my ( $before, $after ) = $is_horizontal ? ( $vertical{up}, $vertical{down} ) : ( $horizontal{left}, $horizontal{right} );
			my $opposite = $is_horizontal ? $horizontal{ $direction eq 'left' ? 'right' : 'left' } : $vertical{ $direction eq 'up' ? 'down' : 'up' };
			if ( @$before && @$after && !@$opposite ) {
				my @passing = sort { $a->[0] <=> $b->[0] } @$before, @$after;
				( $low, $high ) = ( $passing[-1][0], $passing[0][1] );
			}
			@spans = map { [ $_, $towards_end ? ( 0, $high ) : ( $low, $length ) ] } @$strokes;
		}
		else {
			my ( $side_before, $side_after ) = $is_horizontal ? ( $vertical{up}, $vertical{down} ) : ( $horizontal{left}, $horizontal{right} );
			my $middle = $is_horizontal ? [ $x0, $x0 + $thickness ] : [ $y0, $y0 + $thickness ];
			my @rails  = @$strokes;
			@spans = (
				[ $rails[0], _rail_extent( $side_before, $side_after,  $towards_end, $length, $middle ) ],
				[ $rails[1], _rail_extent( $side_after,  $side_before, $towards_end, $length, $middle ) ],
			);
		}

		foreach my $span (@spans) {
			my ( $across, $from, $to ) = ( $span->[0], $span->[1], $span->[2] );
			push @shapes, $is_horizontal ? _rect( $from, $across->[0], $to, $across->[1] ) : _rect( $across->[0], $from, $across->[1], $to );
		}
	}
	return @shapes;
}

# Where a rail of a double arm runs, along the arm: from the cell edge to
# the stroke of the arm on the rail's side ($beside) that is nearest to
# the edge, overlapping it; without such an arm, to the far side of the
# arm opposite ($opposite); without either, across the middle line
# ($middle, where a light line would cross), so the rails of two opposite
# arms join.
sub _rail_extent ( $beside, $opposite, $towards_end, $length, $middle ) {
	if (@$beside) {
		my $nearest = $towards_end ? $beside->[0] : $beside->[-1];
		return $towards_end ? ( 0, $nearest->[1] ) : ( $nearest->[0], $length );
	}
	if (@$opposite) {
		return $towards_end ? ( 0, max( map { $_->[1] } @$opposite ) ) : ( min( map { $_->[0] } @$opposite ), $length );
	}
	return $towards_end ? ( 0, $middle->[1] ) : ( $middle->[0], $length );
}

sub _dash_shapes ( $is_horizontal, $weight, $dashes, $cell ) {
	my ( $width, $height, $thickness, $x0, $y0 ) = @$cell{qw(width height thickness x0 y0)};
	my ($stroke) = @{ _strokes( $weight, $is_horizontal ? $y0 : $x0, $thickness ) };
	my $length = $is_horizontal ? $width : $height;

	# Each dash takes its share of the cell minus a gap at its end; the gap
	# is split around the cell edge so dashes are even across cells.
	my $share = $length / $dashes;
	my $gap   = max( 1, int( $share / 3 + 0.5 ) );
	my @shapes;
	foreach my $index ( 0 .. $dashes - 1 ) {
		my $from = int( $index * $share + $gap / 2 + 0.5 );
		my $to   = int( ( $index + 1 ) * $share - $gap / 2 + 0.5 );
		push @shapes, $is_horizontal ? _rect( $from, $stroke->[0], $to, $stroke->[1] ) : _rect( $stroke->[0], $from, $stroke->[1], $to );
	}
	return @shapes;
}

# A quarter circle between the middle of the vertical and the horizontal
# edge it connects, with straight ends, stroked as thick as a light line.
sub _arc_shapes ( $vertical, $horizontal, $cell ) {
	my ( $width, $height, $thickness, $x0, $y0 ) = @$cell{qw(width height thickness x0 y0)};
	my ( $center_x, $center_y ) = ( $x0 + $thickness / 2, $y0 + $thickness / 2 );
	my $radius = min( $center_x, $width - $center_x, $center_y, $height - $center_y );

	my $edge_y = $vertical eq 'down'    ? $height : 0;
	my $edge_x = $horizontal eq 'right' ? $width  : 0;
	my $sign_x = $horizontal eq 'right' ? 1       : -1;
	my $sign_y = $vertical eq 'down'    ? 1       : -1;
	my ( $pivot_x, $pivot_y ) = ( $center_x + $sign_x * $radius, $center_y + $sign_y * $radius );

	my @points = ( $center_x, $edge_y );
	foreach my $step ( 0 .. ARC_SEGMENTS ) {
		my $angle = ( $step / ARC_SEGMENTS ) * ( atan2( 1, 1 ) * 2 );    # 0 .. 90 degrees
		push @points, $pivot_x - $sign_x * $radius * cos($angle), $pivot_y - $sign_y * $radius * sin($angle);
	}
	push @points, $edge_x, $center_y;
	return { type => 'polyline', points => \@points, width => $thickness };
}

sub _diagonal_shapes ( $codepoint, $cell ) {
	my ( $width, $height, $thickness ) = @$cell{qw(width height thickness)};
	my $rising  = { type => 'polyline', points => [ $width, 0, 0, $height ], width => $thickness };
	my $falling = { type => 'polyline', points => [ 0, 0, $width, $height ], width => $thickness };
	return $rising if $codepoint == 0x2571;
	return $falling if $codepoint == 0x2572;
	return ( $rising, $falling ) if $codepoint == 0x2573;
	croak sprintf 'Term::Fabulous::Screenshot::BoxDrawing: no shapes for U+%04X', $codepoint;
}

1;

__END__

=head1 NAME

Term::Fabulous::Screenshot::BoxDrawing - Box drawing and block element
characters as shapes

=head1 SYNOPSIS

	use Term::Fabulous::Screenshot::BoxDrawing qw(is_drawn_glyph glyph_shapes);

	if ( is_drawn_glyph($glyph) ) {
		foreach my $shape ( glyph_shapes( $glyph, 9, 18, 1 ) ) {
			...    # { type => 'rect', x, y, width, height, coverage }
			       # { type => 'polyline', points => [ x1, y1, x2, y2, ... ], width }
			       # { type => 'circle', cx, cy, r }
		}
	}

=head1 DESCRIPTION

Maintainer tool, not installed. Terminal emulators draw the box drawing
characters (U+2500 to U+257F) and the block elements (U+2580 to U+259F)
themselves rather than with the font, so that lines meet across cells
and half blocks split a cell exactly; many also draw the Braille
patterns (U+2800 to U+28FF) and the sextants of the "Symbols for Legacy
Computing" (U+1FB00 to U+1FB3B), which the chart widgets use. The
screenshot renderers do the same with the shapes this module computes,
which makes borders seamless, canvas pixels square and chart lines
crisp in every viewer, whatever font it has.

All 160 box drawing and block element characters are covered: light,
heavy and double lines and all their junctions, dashed lines, rounded
corners, diagonals, the eighth and half blocks, the quadrants and the
three shades; and all 256 Braille patterns (dots as circles on a 2 x 4
grid) and all 60 sextants.

=head1 FUNCTIONS

=head2 is_drawn_glyph

True for a single character from U+2500 to U+259F, U+2800 to U+28FF or
U+1FB00 to U+1FB3B.

=head2 glyph_shapes

	my @shapes = glyph_shapes( $glyph, $cell_width, $cell_height, $line_thickness );

The shapes that draw C<$glyph> in a cell of the given size, in the
cell's coordinates, with light lines C<$line_thickness> thick (heavy
lines are twice that, double lines two light lines with a gap between
them). All three numbers must be positive whole numbers; rectangles then
have whole-number coordinates, so the same line lands on the same
pixels in every cell.

=over

=item C<< { type =E<gt> 'rect', x, y, width, height, coverage } >>

A filled rectangle. C<coverage> is how much of the foreground color
covers the background: 1 for solid shapes, 0.25, 0.5 and 0.75 for the
shades.

=item C<< { type =E<gt> 'polyline', points, width } >>

A line through the points (an array of x, y, x, y, ...) stroked
C<width> thick in the foreground color: the rounded corners and the
diagonals.

=item C<< { type =E<gt> 'circle', cx, cy, r } >>

A circle filled with the foreground color: a Braille dot. Its center and
radius may be fractions.

=back

Dies for a character outside the range or on invalid sizes.

=cut
