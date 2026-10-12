use v5.32;
use warnings;
use utf8;

use Test2::V0;

use Term::Fabulous::Termbox qw(TB_HI_BLACK);
use Term::Fabulous::Color;
use Term::Fabulous::Widget::Canvas;

sub canvas {
	my ( $columns, $rows ) = @_;
	my $canvas = Term::Fabulous::Widget::Canvas->new;
	$canvas->fit_to( $columns, $rows );
	$canvas->take_changed_spans;
	return $canvas;
}

sub glyphs {
	my ( $canvas, $y ) = @_;
	return join '', map { my $cell = $canvas->cell( $_, $y ); defined $cell ? $cell->[0] : '.' } 0 .. $canvas->columns - 1;
}

subtest 'put and cell' => sub {
	my $canvas = canvas( 4, 2 );
	ref_is $canvas->put( 1, 0, 'a', 0xFF0000, 0x00FF00 ), $canvas, 'put returns the canvas';
	is $canvas->cell( 1, 0 ), [ 'a', 0xFF0000, 0x00FF00 ], 'packed integers are the attributes';
	is $canvas->cell( 0, 0 ), undef,                       'an unset cell';

	$canvas->put( 2.7, 1.2, 'b', 0, Term::Fabulous::Color->rgb( 1, 2, 3 ) );
	is $canvas->cell( 2, 1 ), [ 'b', TB_HI_BLACK, 0x010203 ], 'coordinates round down, 0 is opaque black, Color objects work';

	$canvas->put( 3, 1, 'c', '#0a0b0c', [ 9, 9, 9, 0 ] );
	is $canvas->cell( 3, 1 ), [ 'c', 0x0A0B0C, undef ], 'color strings work, alpha 0 is no color';
};

subtest 'writes outside the buffer are dropped' => sub {
	my $canvas = canvas( 3, 2 );
	$canvas->put( $_->[0], $_->[1], 'x' ) foreach [ -1, 0 ], [ 3, 0 ], [ 0, -0.5 ], [ 0, 2 ], [ 2, 0 ];
	is [ glyphs( $canvas, 0 ), glyphs( $canvas, 1 ) ], [ '..x', '...' ], 'only the cell inside';
	$canvas->put( 2, 1, '日' );
	is glyphs( $canvas, 1 ), '...', 'a wide glyph crossing the right edge';
};

subtest 'invalid input dies' => sub {
	my $canvas = canvas( 3, 1 );
	like dies { $canvas->put( 0, 0, 'ab' ) },               qr/exactly one grapheme cluster, got 2/, 'two clusters';
	like dies { $canvas->put( 0, 0, '' ) },                 qr/non-empty string/,                    'an empty glyph';
	like dies { $canvas->put( 'left', 0, 'a' ) },           qr/x must be a finite number/,           'a non-numeric coordinate';
	like dies { $canvas->put( 0, 0, 'a', 0x1000000 ) },     qr/fg must be a packed 0xRRGGBB/,        'an integer color out of range';
	like dies { $canvas->put( 0, 0, 'a', undef, 'nope' ) }, qr/unrecognized color string/,           'an invalid color string';
};

subtest 'wide glyphs' => sub {
	my $canvas = canvas( 6, 1 );
	$canvas->put_text( 0, 0, 'a日本' );
	is glyphs( $canvas, 0 ), 'a日.本..', 'put_text advances by the glyph width';

	$canvas->put( 2, 0, 'x', 0x112233, 0x445566 );
	is glyphs( $canvas, 0 ), 'a x本..', 'overwriting the covered cell leaves a space in the first one';
	$canvas->put( 3, 0, 'y' );
	is glyphs( $canvas, 0 ), 'a xy .', 'overwriting the first cell leaves a space in the covered one';
};

subtest 'fill, erase and clear' => sub {
	my $canvas = canvas( 5, 3 );
	$canvas->fill( -1, 1, 5, 9, '#' );
	is [ map { glyphs( $canvas, $_ ) } 0 .. 2 ], [ '.....', '####.', '####.' ], 'the rect is clipped to the buffer';
	$canvas->fill( 0, 0, 5, 1, '日' );
	is glyphs( $canvas, 0 ), '日.日..', 'wide glyphs repeat in steps of their width';

	$canvas->erase( 0, 1 );
	is glyphs( $canvas, 1 ), '.###.', 'erase unsets one cell';
	$canvas->clear;
	is [ map { glyphs( $canvas, $_ ) } 0 .. 2 ], [ ('.....') x 3 ], 'clear unsets every cell';
};

subtest 'changed spans' => sub {
	my $canvas = canvas( 8, 3 );
	is $canvas->take_changed_spans, [], 'nothing changed';

	$canvas->put( 5, 0, 'a' )->put( 2, 0, 'b' )->put( 4, 2, '日' );
	is $canvas->take_changed_spans, [ [ 2, 6 ], undef, [ 4, 6 ] ], 'one span per row';

	$canvas->put( 5, 2, 'c' );
	is $canvas->take_changed_spans, [ undef, undef, [ 4, 6 ] ], 'breaking a wide glyph includes its other cell';

	$canvas->clear;
	is $canvas->take_changed_spans, [ [ 2, 6 ], undef, [ 4, 6 ] ], 'clear changes the cells that were set';

	$canvas->put( 1, 1, 'x', 0xFF0000 );
	$canvas->take_changed_spans;
	$canvas->clear->put( 1, 1, 'x', 0xFF0000 );
	is $canvas->take_changed_spans, [], 'a clear that paints the same cells again changes nothing';
	$canvas->put( 1, 1, 'x', 0x00FF00 );
	is $canvas->take_changed_spans, [ undef, [ 1, 2 ] ], 'a new color is a change';
};

subtest 'fit_to' => sub {
	my $canvas = canvas( 4, 2 );
	my @events;
	$canvas->on( CanvasResize => sub { push @events, [ $_[0]->columns, $_[0]->rows ]; return } );

	$canvas->put_text( 0, 0, 'ab日' )->put( 0, 1, 'z' );
	$canvas->fit_to( 4, 2 );
	is \@events, [], 'the same size fires nothing';

	$canvas->fit_to( 3, 3 );
	is \@events,                                 [ [ 3, 3 ] ],            'a new size fires CanvasResize';
	is [ map { glyphs( $canvas, $_ ) } 0 .. 2 ], [ 'ab.', 'z..', '...' ], 'cells inside are kept, the cut wide glyph is unset';
	is $canvas->take_changed_spans,              [ ( [ 0, 3 ] ) x 3 ],    'everything changed';
	like dies { $canvas->fit_to( -1, 2 ) }, qr/non-negative integer size/, 'a negative size dies';
};

done_testing;
