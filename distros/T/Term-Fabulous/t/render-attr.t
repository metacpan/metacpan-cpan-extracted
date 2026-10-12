use v5.32;
use warnings;

use Test2::V0;

use Term::Fabulous::Termbox qw(TB_DEFAULT TB_HI_BLACK TB_REVERSE);
use Term::Fabulous::Color;
use Term::Fabulous::Render::Attr qw(color_attr clay_color blended_bg_attr blended_fg_attr);

subtest 'color_attr' => sub {
	is color_attr( Term::Fabulous::Color->rgba( 0, 0, 0, 255 ) ),  TB_HI_BLACK, 'opaque black';
	is color_attr( Term::Fabulous::Color->rgba( 0, 0, 0, 0 ) ),    TB_DEFAULT,  'alpha 0 is the terminal default';
	is color_attr( Term::Fabulous::Color->rgba( 9, 9, 9, 0 ) ),    TB_DEFAULT,  'alpha 0 ignores the channels';
	is color_attr( Term::Fabulous::Color->rgb( 18, 52, 86 ) ),     0x123456,    'packed rgb';
	is color_attr( Term::Fabulous::Color->rgba( 18, 52, 86, 1 ) ), 0x123456,    'partial alpha is opaque when not blended';
	is color_attr( Term::Fabulous::Color->rgb( 255, 255, 255 ) ),  0xFFFFFF,    'white stays inside the color bits';
};

subtest 'clay_color' => sub {
	my $color = clay_color( { r => '20', g => '25', b => '35', a => '255' } );
	isa_ok $color, 'Term::Fabulous::Color';
	is [ $color->to_rgba ], [ 20, 25, 35, 255 ], 'channels';
	ref_is clay_color( { r => 20, g => 25, b => 35, a => 255 } ), $color, 'memoized by channel values';
	like dies { clay_color(undef) },                                    qr/must be a hash reference/,         'undef dies';
	like dies { clay_color( { r => 300, g => 0, b => 0, a => 255 } ) }, qr/red must be a number in 0\.\.255/, 'invalid channel dies';
};

subtest 'blended attributes' => sub {
	my $half_black = Term::Fabulous::Color->rgba( 0,   0,   0,   128 );
	my $half_white = Term::Fabulous::Color->rgba( 255, 255, 255, 128 );
	is blended_bg_attr( $half_black,                               0xFFFFFF ),              0x7F7F7F,              'half black over white';
	is blended_bg_attr( $half_white,                               TB_HI_BLACK ),           0x808080,              'half white over black';
	is blended_bg_attr( $half_black,                               0x010101 ),              TB_HI_BLACK,           'a black result carries the black flag';
	is blended_bg_attr( $half_black,                               TB_DEFAULT ),            TB_HI_BLACK,           'the terminal default cannot be blended: drawn opaque';
	is blended_bg_attr( $half_black,                               0xFFFFFF | TB_REVERSE ), 0x7F7F7F | TB_REVERSE, 'style flags below are kept';
	is blended_bg_attr( Term::Fabulous::Color->rgb( 1, 2, 3 ),     0xFFFFFF ),              0x010203,              'an opaque color replaces';
	is blended_bg_attr( Term::Fabulous::Color->rgba( 1, 2, 3, 0 ), 0xFFFFFF ),              0xFFFFFF,              'alpha 0 leaves the attribute below';
	is blended_fg_attr( $half_black, 0xFF0000 | TB_REVERSE ), 0x7F0000 | TB_REVERSE, 'a foreground is tinted and keeps its flags';
	is blended_fg_attr( $half_black, TB_DEFAULT ),            TB_DEFAULT,            'a default foreground stays as it is';
};

done_testing;
