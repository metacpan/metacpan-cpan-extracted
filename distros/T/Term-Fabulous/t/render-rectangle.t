use v5.32;
use warnings;
use utf8;

use Test2::V0;

use Object::Pad 0.825;
use Term::Fabulous::Termbox qw(TB_DEFAULT TB_HI_BLACK TB_REVERSE);
use Term::Fabulous::Render::Rectangle;
use Term::Fabulous::Widget::Box;

# A cell target that records every fill_row call as [ $x, $y, $columns, $bg ]
# and every set_cell call as [ $x, $y, $glyph, $fg, $bg ], extended in place,
# and answers painted_cell from a preset grid of [ $glyph, $fg, $bg ].
my ( @prints, @cells, %painted );

class RectangleCanvas :does(Term::Fabulous::Render::Rectangle) {
	field $width  :param :reader = 10;
	field $height :param :reader = 5;

	# Painted outside any scissor: commands may touch the whole viewport.
	method clip_rect () { return [ 0, 0, $width, $height ] }

	# The painter is its own cell target: it records what it is given.
	method cell_target () { return $self }

	method fill_row (@args) {
		push @prints, [@args];
		return;
	}

	method set_cell (@args) {
		push @cells, [@args];
		return;
	}

	method extend_cell ( $x, $y, $character ) {
		$cells[-1][2] .= $character;
		return;
	}

	method painted_cell ( $x, $y ) {
		my $cell = $painted{"$x,$y"} // return ();
		return @$cell;
	}
}

my $canvas = RectangleCanvas->new;

sub fill {
	my ( $buffer, %bbox ) = @_;
	my $color  = delete $bbox{color} // { r => 1, g => 2, b => 3, a => 255 };
	my $widget = delete $bbox{widget};
	( @prints, @cells ) = ();
	$canvas->render_rectangle( { boundingBox => \%bbox, renderData => { backgroundColor => $color } }, $widget, $buffer );
	return [ map { [ $_->[0], $_->[1], $_->[2] ] } @prints ];
}

my %half_black = ( r => 0, g => 0, b => 0, a => 128 );

subtest 'negative origin is clipped' => sub {
	my $buffer = [];
	my $rows   = fill( $buffer, x => -3, y => -2, width => 6, height => 4 );
	is $rows,            [ [ 0, 0, 3 ], [ 0, 1, 3 ] ], 'only the visible cells are printed';
	is scalar(@$buffer), 2,                            'shadow buffer has only visible rows';
	is $buffer->[0],     [ (0x010203) x 3 ],           'shadow buffer has only visible cells';
};

subtest 'oversized box is clipped to the viewport' => sub {
	my $buffer = [];
	is fill( $buffer, x => 8, y => 3, width => 10, height => 10 ), [ [ 8, 3, 2 ], [ 8, 4, 2 ] ], 'right and bottom clipped';
	is scalar( @{ $buffer->[3] } ),                                10,                           'shadow row ends at the viewport edge';
};

subtest 'invisible boxes draw nothing' => sub {
	is fill( [], x => -10, y => 0, width => 5,   height => 2 ), [], 'left of the viewport';
	is fill( [], x =>  0,  y => 7, width => 5,   height => 2 ), [], 'below the viewport';
	is fill( [], x =>  2,  y => 2, width => 0.5, height => 2 ), [], 'narrower than a cell';
};

subtest 'background attributes' => sub {
	fill( [], x => 0, y => 0, width => 1, height => 1, color => { r => 0, g => 0, b => 0, a => 255 } );
	is $prints[0][3], TB_HI_BLACK, 'opaque black';
	fill( [], x => 0, y => 0, width => 1, height => 1, color => { r => 9, g => 9, b => 9, a => 0 } );
	is $prints[0][3], TB_DEFAULT, 'transparent maps to the terminal default';
};

subtest 'translucent background covers the glyphs below' => sub {
	my $buffer = [ [ (0xFFFFFF) x 3 ] ];
	fill( $buffer, x => 0, y => 0, width => 5, height => 1, color => \%half_black );
	is \@prints,     [ [ 0, 0, 3, 0x7F7F7F ], [ 3, 0, 2, TB_HI_BLACK ] ], 'one fill per run of equal blended color; the default background is drawn opaque';
	is $buffer->[0], [ (0x7F7F7F) x 3, (TB_HI_BLACK) x 2 ],               'the shadow buffer holds the blended backgrounds';
	is \@cells,      [],                                                  'no cell is read back or set';
};

subtest 'translucent background with glyphs showing through' => sub {
	my $widget = Term::Fabulous::Widget::Box->new( glyphs_show_through => 1 );
	%painted = (
		'0,0' => [ 'A',        0xFFFFFF,              0xFFFFFF ],
		'1,0' => [ '中',        0xFF0000 | TB_REVERSE, 0xFFFFFF ],
		'2,0' => [ ' ',        TB_DEFAULT,            0xFFFFFF ],
		'3,0' => [ ' ',        TB_DEFAULT,            0xFFFFFF ],
		'4,0' => [ "e\x{301}", TB_DEFAULT,            0xFFFFFF ],
	);
	my $buffer = [ [ (0xFFFFFF) x 5 ] ];
	fill( $buffer, x => 0, y => 0, width => 6, height => 1, color => \%half_black, widget => $widget );
	is \@cells,
		[
		[ 0, 0, 'A',        0x7F7F7F,              0x7F7F7F ],
		[ 1, 0, '中',        0x7F0000 | TB_REVERSE, 0x7F7F7F ],
		[ 3, 0, ' ',        TB_DEFAULT,            0x7F7F7F ],
		[ 4, 0, "e\x{301}", TB_DEFAULT,            0x7F7F7F ],
		[ 5, 0, ' ',        TB_DEFAULT,            TB_HI_BLACK ],
		],
		'glyphs are repainted with tinted foregrounds, the cell a wide glyph covers is skipped, a default foreground stays, an unpainted cell becomes a space';
	is $buffer->[0], [ (0x7F7F7F) x 5, TB_HI_BLACK ], 'the shadow buffer holds the blended backgrounds, also under the wide glyph';
	is \@prints,     [],                              'no row fill';

	$widget->glyphs_show_through(0);
	fill( $buffer, x => 0, y => 0, width => 1, height => 1, color => \%half_black, widget => $widget );
	is [ \@cells, scalar @prints ], [ [], 1 ], 'with the flag off the widget covers the glyphs again';
};

subtest 'reverse video' => sub {

	class ReversedBox :isa(Term::Fabulous::Widget::Box) {
		method reverse_video :override () { return 1 }
	}
	my $widget = ReversedBox->new( glyphs_show_through => 1 );
	my $buffer = [ [ (0xFFFFFF) x 2 ] ];
	fill( $buffer, x => 0, y => 0, width => 2, height => 1, widget => $widget );
	is $prints[0][3], 0x010203 | TB_REVERSE,             'an opaque fill carries TB_REVERSE';
	is $buffer->[0],  [ ( 0x010203 | TB_REVERSE ) x 2 ], 'so does the shadow buffer, for the text drawn on top';

	%painted = ( '0,0' => [ 'A', 0xFFFFFF, 0xFFFFFF ] );
	$buffer  = [ [0xFFFFFF] ];
	fill( $buffer, x => 0, y => 0, width => 1, height => 1, color => \%half_black, widget => $widget );
	is $cells[0][4], 0x7F7F7F | TB_REVERSE, 'a tinted cell carries it too';
};

done_testing;
