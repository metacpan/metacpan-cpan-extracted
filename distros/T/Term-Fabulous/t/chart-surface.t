use v5.32;
use warnings;
use utf8;

use Test2::V0;

use Term::Fabulous::Chart::Marker;
use Term::Fabulous::Chart::Raster;
use Term::Fabulous::Chart::Surface;
use Term::Fabulous::Termbox qw(TB_BOLD TB_HI_BLACK);
use Term::Fabulous::Widget::Canvas;

my $Surface = 'Term::Fabulous::Chart::Surface';

use constant { SHADE => 0x101010, RED => 0xFF0000, GREEN => 0x00FF00, BLUE => 0x0000FF };

sub raster {
	my ( $marker, $columns, $rows ) = @_;
	return Term::Fabulous::Chart::Raster->new( marker => Term::Fabulous::Chart::Marker->named($marker), columns => $columns, rows => $rows );
}

subtest 'cells' => sub {
	my $surface = $Surface->new( columns => 4, rows => 2, background => SHADE );
	is [ $surface->columns, $surface->rows, $surface->background ],                                                  [ 4, 2, SHADE ],            'size and background';
	is [ $surface->glyph_at( 0, 0 ), $surface->fg_at( 0, 0 ), $surface->bg_at( 0, 0 ), $surface->flags_at( 0, 0 ) ], [ undef, undef, SHADE, 0 ], 'an untouched cell shows the background';
	is [ map { $surface->contains(@$_) } [ 3, 1 ], [ 4, 0 ], [ 0, 2 ], [ -1, 0 ] ],                                  [ 1, 0, 0, 0 ],             'contains';
	is [ $surface->glyph_at( 9, 0 ), $surface->bg_at( 9, 0 ), $surface->flags_at( 9, 0 ) ],                          [ undef, SHADE, 0 ],        'outside: no glyph on the background';

	ref_is $surface->put( 1, 0, 'a', RED ), $surface, 'put returns the surface';
	$surface->put( 2, 0, 'b', BLUE, GREEN, TB_BOLD )->put( 7, 0, 'c', RED );
	is [ $surface->glyph_at( 1, 0 ), $surface->fg_at( 1, 0 ), $surface->bg_at( 1, 0 ) ], [ 'a', RED, SHADE ], 'without a background the cell keeps its own';
	is [ $surface->bg_at( 2, 0 ), $surface->flags_at( 2, 0 ) ],                          [ GREEN, TB_BOLD ],  'with a background and style bits';
	is [ $surface->lines ],                                                              [ ' ab ', '    ' ],  'lines';

	ref_is $surface->fill( 2, 0, 5, 1, BLUE ), $surface, 'fill returns the surface';
	is [ $surface->glyph_at( 2, 0 ), $surface->fg_at( 2, 0 ), $surface->flags_at( 2, 0 ), $surface->bg_at( 3, 0 ), $surface->bg_at( 2, 1 ) ], [ undef, undef, 0, BLUE, SHADE ],
		'fill removes glyphs and sets the background';
	is [ $surface->lines ], [ ' a  ', '    ' ], 'the rest stays';

	like dies { $Surface->new( columns => 'x', rows =>  1 ) }, qr/columns must be a non-negative integer, got x/, 'invalid columns die';
	like dies { $Surface->new( columns => 1,   rows => -2 ) }, qr/rows must be a non-negative integer, got -2/,   'invalid rows die';
};

subtest 'text' => sub {
	my $surface = $Surface->new( columns => 8, rows => 1 );
	is $surface->text( 0, 0, "a\x{65E5}b", RED ),               4,                  'a wide character takes two columns';
	is [ $surface->lines ],                                     ["a\x{65E5}b    "], 'the cell right of it shows nothing';
	is [ $surface->glyph_at( 2, 0 ), $surface->fg_at( 2, 0 ) ], [ '', RED ],        'and holds its color';

	$surface = $Surface->new( columns => 8, rows => 1 );
	is $surface->text( 0, 0, 'Hello world', RED, max => 5 ), 5,                   'text wider than max';
	is [ $surface->lines ],                                  ["Hell\x{2026}   "], 'is cut with an ellipsis';
	$surface = $Surface->new( columns => 8, rows => 1 );
	is $surface->text( 0, 0, "\x{65E5}\x{672C}\x{8A9E}", RED, max => 4 ), 3,                         'a wide character that does not fit before the ellipsis';
	is [ $surface->lines ],                                               ["\x{65E5}\x{2026}     "], 'is left out';
	is $surface->text( 0, 0, 'abc', RED, max => 3 ),                      3,                         'text as wide as max is not cut';
	is $surface->text( 0, 0, 'abc', RED, max => 0 ),                      0,                         'max 0 writes nothing';

	$surface = $Surface->new( columns => 3, rows => 1 );
	is $surface->text( 1, 0, 'abc',       RED ), 2, 'text is cut at the right edge';
	is $surface->text( 1, 0, "x\x{65E5}", RED ), 1, 'so is a wide character crossing it';
	is [ $surface->lines ], [' xb'], 'what was written';

	$surface = $Surface->new( columns => 4, rows => 1 );
	$surface->text( 0, 0, "\x{65E5}x", RED );
	$surface->put( 1, 0, 'y', RED );
	is [ $surface->lines ], [' yx '], 'writing over the right half of a wide character clears its left half';
	$surface->text( 0, 0, "\x{65E5}", RED );
	$surface->put( 0, 0, 'z', RED );
	is [ $surface->lines ], ['z x '], 'and the other way round';

	$surface = $Surface->new( columns => 4, rows => 1, background => SHADE );
	$surface->text( 1, 0, "\x{65E5}", RED, bg => GREEN, flags => TB_BOLD );
	is [ map { $surface->bg_at( $_, 0 ) } 0 .. 3 ], [ SHADE, GREEN, GREEN, SHADE ], 'bg colors both halves';
	is $surface->flags_at( 1, 0 ),                  TB_BOLD,                        'flags style the text';

	is $Surface->text_columns("a\x{65E5}"), 3, 'text_columns counts wide characters twice';
};

subtest 'composite' => sub {
	my $surface = $Surface->new( columns => 4, rows => 3, background => SHADE );
	my $raster  = raster( braille => 2, 1 );
	$raster->set( 0, 0, RED, 'line' );
	$raster->set( 1, 0, RED, 'line' );
	$raster->set( 0, 1, RED, 'other' );
	$raster->set( 2, 0, GREEN );
	ref_is $surface->composite( $raster, 'stroke', 1, 1 ), $surface, 'composite returns the surface';
	is [ $surface->lines ], [ '    ', " \x{280B}\x{2801} ", '    ' ], 'the cells drawn at the offset';
	is [ $surface->fg_at( 1, 1 ), $surface->bg_at( 1, 1 ), $surface->fg_at( 2, 1 ) ], [ RED, SHADE, GREEN ], 'over the background';
	is [ $surface->owner( 1, 1, 'stroke' ), $surface->owner( 2, 1, 'stroke' ), $surface->owner( 1, 1, 'fill' ) ], [ 'line', undef, undef ],
		'a cell is owned by the owner most of its subpixels have, in the layer';

	$surface->composite( $raster, 'fill', 3, 0 );
	is [ $surface->lines ],             [ "   \x{280B}", " \x{280B}\x{2801} ", '    ' ], 'cells outside the surface are dropped';
	is $surface->owner( 3, 0, 'fill' ), 'line',                                          'the fill layer';
	like dies { $surface->composite( $raster, 'glow' ) }, qr/unknown layer 'glow'/, 'an unknown layer dies';
};

subtest 'Braille over block cells takes the color most of the cell shows' => sub {
	my $surface = $Surface->new( columns => 3, rows => 1, background => SHADE );
	my $area    = raster( block => 3, 1 );
	$area->fill_rect( 0, 2, 1, 8, BLUE, 'area' );
	$area->fill_rect( 1, 6, 2, 8, BLUE, 'area' );
	$surface->composite( $area, 'fill' );
	is [ $surface->lines ],                                  ["\x{2586}\x{2582} "], 'the area';
	is [ $surface->fg_at( 0, 0 ), $surface->bg_at( 0, 0 ) ], [ BLUE, SHADE ],       'a block glyph over the background';

	my $line = raster( braille => 3, 1 );
	$line->set( $_, 0, RED ) foreach 0, 2, 4;
	$surface->composite( $line, 'stroke' );
	is [ $surface->lines ],                                                    ["\x{2801}\x{2801}\x{2801}"], 'the line';
	is [ map { $surface->bg_at( $_, 0 ) } 0 .. 2 ],                            [ BLUE, SHADE, SHADE ],       'takes the color most of each cell showed as its background';
	is [ $surface->owner( 0, 0, 'fill' ), $surface->owner( 0, 0, 'stroke' ) ], [ 'area', undef ],            'the layers keep their owners';
};

subtest 'owner_near' => sub {
	my $surface = $Surface->new( columns => 3, rows => 3 );
	ref_is $surface->set_owner( 1, 1, 'fill', 'bar' ), $surface, 'set_owner returns the surface';
	is $surface->owner_near( 1, 1 ), 'bar', 'a fill in the cell';
	$surface->set_owner( 1, 1, 'stroke', 'line' );
	is $surface->owner_near( 1, 1 ), 'line', 'a stroke in the cell comes first';
	is $surface->owner_near( 2, 2 ), 'line', 'a stroke in a neighboring cell';
	$surface->set_owner( 2, 2, 'fill', 'slice' );
	is $surface->owner_near( 2, 2 ),                                        'slice',          'comes after a fill in the cell';
	is [ $surface->owner_near( 3, 1 ), $surface->owner( 3, 1, 'stroke' ) ], [ undef, undef ], 'outside: none';

	$surface = $Surface->new( columns => 3, rows => 1 );
	$surface->set_owner( 0, 0, 'fill', 'bar' );
	is $surface->owner_near( 1, 0 ), undef, 'a fill in a neighboring cell does not count';
	$surface->set_owner( 0, 0, 'stroke', 'left' )->set_owner( 2, 0, 'stroke', 'right' );
	is $surface->owner_near( 1, 0 ), 'left', 'the nearest neighbor first, left before right';
};

subtest 'paint' => sub {
	my $surface = $Surface->new( columns => 6, rows => 1, background => SHADE );
	$surface->put( 0, 0, 'a', RED, undef, TB_BOLD );
	$surface->fill( 1, 0, 1, 1, GREEN );
	$surface->text( 2, 0, "\x{65E5}", BLUE );
	$surface->put( 4, 0, 'b', 0x000000, SHADE );
	$surface->put( 5, 0, ' ', RED );

	my $canvas = Term::Fabulous::Widget::Canvas->new;
	$canvas->fit_to( 6, 1 );
	$canvas->put( 5, 0, 'q' );
	$surface->paint($canvas);
	is $canvas->cell( 0, 0 ), [ 'a',        RED | TB_BOLD, undef ], 'a glyph with style bits on the surface background';
	is $canvas->cell( 1, 0 ), [ ' ',        undef, GREEN ], 'a background of its own';
	is $canvas->cell( 2, 0 ), [ "\x{65E5}", BLUE,        undef ], 'a wide glyph';
	is $canvas->cell( 4, 0 ), [ 'b',        TB_HI_BLACK, undef ], 'black is opaque black';
	is $canvas->cell( 5, 0 ), undef, 'paint clears the canvas; a space on the surface background stays unset';

	$surface = $Surface->new( columns => 2, rows => 1 );
	$surface->fill( 0, 0, 1, 1, SHADE );
	$canvas->fit_to( 2, 1 );
	$surface->paint($canvas);
	is [ $canvas->cell( 0, 0 ), $canvas->cell( 1, 0 ) ], [ [ ' ', undef, SHADE ], undef ], 'without a surface background every background is its own';
};

done_testing;
