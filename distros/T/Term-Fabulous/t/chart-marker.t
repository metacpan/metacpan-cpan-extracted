use v5.32;
use warnings;
use utf8;

use Test2::V0;

use Term::Fabulous::Chart::Marker;

my $Marker = 'Term::Fabulous::Chart::Marker';

use constant { RED => 0xFF0000, GREEN => 0x00FF00, BLUE => 0x0000FF };

# The colors of a cell whose subpixels in $mask are drawn in $color.
sub drawn {
	my ( $marker, $mask, $color ) = @_;
	return [ map { $mask & ( 1 << $_ ) ? $color : undef } 0 .. $marker->subpixels - 1 ];
}

sub glyph_of {
	my ( $marker, $mask ) = @_;
	return ( $marker->cell( drawn( $marker, $mask, RED ), undef ) )[0];
}

subtest 'names and sizes' => sub {
	is [ $Marker->names ], [qw(block block-horizontal braille half quadrant sextant)], 'all markers, sorted';
	ok $Marker->is_name('sextant'), 'is_name for a marker';
	ok !$Marker->is_name($_), 'is_name for ' . ( $_ // 'undef' ) foreach 'box', undef, [];
	ref_is $Marker->named('braille'), $Marker->named('braille'), 'named returns the shared instance';
	like dies { $Marker->named('box') }, qr/unknown marker 'box' \(known: block, block-horizontal, braille, half, quadrant, sextant\)/, 'an unknown name dies';

	my %size = map { my $marker = $Marker->named($_); $_ => [ $marker->columns, $marker->rows, $marker->subpixels ] } $Marker->names;
	is \%size, {
		braille            => [ 2, 4, 8 ],
		block              => [ 1, 8, 8 ],
		'block-horizontal' => [ 8, 1, 8 ],
		half               => [ 1, 2, 2 ],
		quadrant           => [ 2, 2, 4 ],
		sextant            => [ 2, 3, 6 ],
		},
		'subpixels across and down';
};

subtest 'empty cells' => sub {
	foreach my $name ( $Marker->names ) {
		my $marker = $Marker->named($name);
		is [ $marker->cell( [ (undef) x $marker->subpixels ], BLUE ) ], [], "$name: no drawn subpixel, no glyph";
	}
};

subtest 'braille' => sub {
	my $braille = $Marker->named('braille');
	is [ $braille->cell( [ RED, undef, undef, RED, (undef) x 4 ], 0x141923 ) ], [ "\x{2811}", RED, undef ],                                                    'dots 1 and 5, background kept';
	is [ map { glyph_of( $braille, 1 << $_ ) } 0 .. 7 ],                        [ map { chr( 0x2800 + $_ ) } 0x01, 0x08, 0x02, 0x10, 0x04, 0x20, 0x40, 0x80 ], 'the dot bit of each subpixel';
	is glyph_of( $braille, 0xFF ),                                              "\x{28FF}",                                                                    'all eight dots';
	is [ $braille->cell( [ RED, GREEN, GREEN, (undef) x 5 ], undef ) ],         [ "\x{280B}", GREEN, undef ],                                                  'the color most dots have';
	is [ $braille->cell( [ RED, GREEN, (undef) x 6 ], undef ) ],                [ "\x{2809}", RED, undef ],                                                    'on a tie, the color drawn first';
};

subtest 'half and quadrant' => sub {
	my $half = $Marker->named('half');
	is [ $half->cell( [ RED, undef ], undef ) ], [ "\x{2580}", RED, undef, undef ], 'the top half over the cell background, which dominates on a tie';
	is [ $half->cell( [ undef, RED ], BLUE ) ], [ "\x{2584}", RED, BLUE, BLUE ], 'on a tie the drawn color is the foreground, the background below dominates';
	is [ $half->cell( [ RED, GREEN ], undef ) ], [ "\x{2580}", RED, GREEN, RED ], 'two colors';
	is [ $half->cell( [ RED, RED ], BLUE ) ], [ ' ', undef, RED, RED ], 'one color everywhere: a space on that background';

	my $quadrant = $Marker->named('quadrant');
	is [ map { glyph_of( $quadrant, $_ ) } 1 .. 14 ], [ map { chr( 0x2500 + $_ ) } 0x98, 0x9D, 0x80, 0x96, 0x8C, 0x9E, 0x9B, 0x97, 0x9A, 0x90, 0x9C, 0x84, 0x99, 0x9F ], 'every partial shape';
	is [ $quadrant->cell( [ RED, undef, undef, undef ], BLUE ) ], [ "\x{259F}", BLUE, RED, BLUE ], 'the more frequent background is the foreground';
};

subtest 'two-color reduction' => sub {
	my $quadrant = $Marker->named('quadrant');
	is [ $quadrant->cell( [ RED, GREEN, GREEN, 0xEE0000 ], undef ) ], [ "\x{259E}", GREEN, RED, GREEN ], 'a third color takes the nearer of the two most frequent';
	is [ $quadrant->cell( [ RED, BLUE, undef, undef ], 0x0000EE ) ], [ "\x{259F}", 0x0000EE, RED, 0x0000EE ], 'the background below counts as a color';
	is [ $quadrant->cell( [ 0x800000, 0x800000, GREEN, undef ], undef ) ], [ "\x{259C}", 0x800000, GREEN, 0x800000 ], 'no background counts as black for the distance';
};

subtest 'sextant' => sub {
	my $sextant = $Marker->named('sextant');
	is glyph_of( $sextant, 1 ),  "\x{1FB00}", 'the first sextant';
	is glyph_of( $sextant, 20 ), "\x{1FB13}", 'the last one before the left half';
	is glyph_of( $sextant, 21 ), "\x{258C}",  'the left column is the left half block';
	is glyph_of( $sextant, 22 ), "\x{1FB14}", 'the code points skip mask 21';
	is glyph_of( $sextant, 41 ), "\x{1FB27}", 'the last one before the right half';
	is glyph_of( $sextant, 42 ), "\x{2590}",  'the right column is the right half block';
	is glyph_of( $sextant, 43 ), "\x{1FB28}", 'the code points skip mask 42';
	is glyph_of( $sextant, 62 ), "\x{1FB3B}", 'the last sextant';
	is [ $sextant->cell( drawn( $sextant, 63, RED ), undef ) ], [ ' ', undef, RED, RED ], 'all six: a space on the color';
};

subtest 'vertical eighths' => sub {
	my $block = $Marker->named('block');
	is [ map { glyph_of( $block, ( ( 1 << $_ ) - 1 ) << ( 8 - $_ ) ) } 1 .. 7 ], [ map { chr( 0x2580 + $_ ) } 1 .. 7 ], 'the lower eighths fill from the bottom';
	is glyph_of( $block, 0x0F ),                                                 "\x{2580}",                            'the upper half';
	is glyph_of( $block, 0x01 ),                                                 "\x{2594}",                            'the upper eighth';
	is [ $block->cell( drawn( $block, 0xC0, RED ), undef ) ],                    [ "\x{2582}", RED, undef, undef ],     'a low bar: mostly the cell background';
	is [ $block->cell( drawn( $block, 0x3F, RED ), BLUE ) ],                     [ "\x{2582}", BLUE, RED, RED ],        'an upper shape without a glyph: the inverted lower one';
	is [ $block->cell( drawn( $block, 0x07, RED ), undef ) ],                    [ "\x{2580}", RED, undef, undef ],     'three upper eighths: the nearest shape, the upper half';
	is [ $block->cell( drawn( $block, 0x05, RED ), BLUE ) ],                     [ "\x{2594}", RED, BLUE, BLUE ],       'the nearest shape in either orientation';
	is [ $block->cell( drawn( $block, 0x02, RED ), undef ) ],                    [ ' ', undef, undef, undef ],          'a single subpixel nearest to nothing';
};

subtest 'horizontal eighths' => sub {
	my $block = $Marker->named('block-horizontal');
	is [ map { glyph_of( $block, ( 1 << $_ ) - 1 ) } 1 .. 7 ], [ map { chr( 0x2590 - $_ ) } 1 .. 7 ], 'the left eighths fill from the left';
	is glyph_of( $block, 0xF0 ),                               "\x{2590}",                            'the right half';
	is glyph_of( $block, 0x80 ),                               "\x{2595}",                            'the right eighth';
	is [ $block->cell( drawn( $block, 0xFC, RED ), BLUE ) ],   [ "\x{258E}", BLUE, RED, RED ],        'a right part without a glyph: the inverted left one';
};

done_testing;
