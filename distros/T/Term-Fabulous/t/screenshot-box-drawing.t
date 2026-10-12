use v5.32;
use warnings;
use utf8;

use Test2::V0;

use FindBin;
use lib "$FindBin::Bin/../tools/lib";

use Term::Fabulous::Screenshot::BoxDrawing qw(is_drawn_glyph glyph_shapes);

# A 10 x 20 cell with lines one unit thick; the shapes of the chart
# glyphs that terminals draw themselves.
sub shapes {
	my ($glyph) = @_;
	return [ glyph_shapes( $glyph, 10, 20, 1 ) ];
}

subtest 'Braille dots are circles on a 2 x 4 grid' => sub {
	is shapes("\x{2801}"), [ { type => 'circle', cx => 2.5, cy => 2.5,  r => 2 } ], 'dot 1 sits in the top left; its radius is 0.4 of half a dot cell';
	is shapes("\x{2880}"), [ { type => 'circle', cx => 7.5, cy => 17.5, r => 2 } ], 'dot 8 in the bottom right';
	is [ map { [ $_->{cx}, $_->{cy} ] } glyph_shapes( "\x{28FF}", 10, 20, 1 ) ],
		[ [ 2.5, 2.5 ], [ 2.5, 7.5 ], [ 2.5, 12.5 ], [ 7.5, 2.5 ], [ 7.5, 7.5 ], [ 7.5, 12.5 ], [ 2.5, 17.5 ], [ 7.5, 17.5 ] ], 'all eight dots in the order of their bits';
	is shapes("\x{2800}"),                       [],                                                      'the blank pattern has none';
	is [ glyph_shapes( "\x{2801}", 5, 20, 1 ) ], [ { type => 'circle', cx => 1.25, cy => 2.5, r => 1 } ], 'a narrow cell makes smaller dots';
};

subtest 'sextants are rectangles in a 2 x 3 grid' => sub {
	my %rect_of = ( 0 => [ 0, 0, 5, 7 ], 1 => [ 5, 0, 10, 7 ], 2 => [ 0, 7, 5, 13 ], 3 => [ 5, 7, 10, 13 ], 4 => [ 0, 13, 5, 20 ], 5 => [ 5, 13, 10, 20 ] );
	my $rect = sub { my ( $left, $top, $right, $bottom ) = @{ $rect_of{ $_[0] } }; return { type => 'rect', x => $left, y => $top, width => $right - $left, height => $bottom - $top, coverage => 1 } };
	is shapes("\x{1FB00}"), [ $rect->(0) ],                                     'the first sextant is the top left block';
	is shapes("\x{1FB01}"), [ $rect->(1) ],                                     'the second the top right';
	is shapes("\x{1FB13}"), [ $rect->(2), $rect->(4) ],                         'U+1FB13 is the left middle and bottom blocks (mask 20)';
	is shapes("\x{1FB14}"), [ $rect->(1), $rect->(2), $rect->(4) ],             'U+1FB14 skips the left half (mask 21), which is a block element';
	is shapes("\x{1FB28}"), [ $rect->(0), $rect->(1), $rect->(3), $rect->(5) ], 'U+1FB28 skips the right half (mask 42) as well';
	is shapes("\x{1FB3B}"), [ map { $rect->($_) } 1 .. 5 ],                     'the last sextant is everything but the top left block';
};

subtest 'what is drawn' => sub {
	ok is_drawn_glyph($_), sprintf 'U+%04X is drawn', ord $_ foreach "\x{2500}", "\x{259F}", "\x{2800}", "\x{28FF}", "\x{1FB00}", "\x{1FB3B}";
	ok !is_drawn_glyph($_), sprintf 'U+%04X is not', ord $_ foreach 'A', "\x{25A0}", "\x{27FF}", "\x{2900}", "\x{1FB3C}";
	like dies { glyph_shapes( 'A',        10, 20,   1 ) }, qr/'A' is not a box drawing or block element character/, 'a glyph the font draws dies';
	like dies { glyph_shapes( "\x{2801}", 10, 20.5, 1 ) }, qr/must be positive whole numbers/,                      'so does a cell of fractional size';
};

done_testing;
