use v5.32;
use warnings;
use utf8;

use Test2::V0;

use Term::Fabulous::Color;
use Term::Fabulous::Chart::Palette qw(palette_colors palette_names is_palette_name chart_color mix_rgb luminance is_light_rgb contrast_rgb ink_colors rgb_hex);
use Term::Fabulous::Chart::Radial qw(CELL_ASPECT TAU circle_frame polar_of point_at);

subtest 'palettes' => sub {
	is [ palette_names() ], [qw(classic default pastel vivid)], 'all palettes, sorted';
	ok is_palette_name('vivid'), 'is_palette_name';
	ok !is_palette_name($_), 'not a palette: ' . ( $_ // 'undef' ) foreach 'neon', undef, [];
	is [ palette_colors( default => 'dark' ) ],              [ 0x3987e5, 0xd95926, 0x199e70, 0xc98500, 0xd55181, 0x008300, 0x9085e9, 0xe66767 ], 'the default palette on dark backgrounds';
	is [ ( palette_colors( default => 'light' ) )[ 0, 7 ] ], [ 0x2a78d6, 0xe34948 ],                                                             'and on light ones';
	is [ map { scalar( () = palette_colors( $_, 'dark' ) ) } palette_names() ], [ 8, 8, 8, 8 ],                                                  'eight colors each';
	like dies { palette_colors( neon    => 'dark' ) }, qr/unknown palette 'neon' \(known: classic, default, pastel, vivid\)/,            'an unknown palette dies';
	like dies { palette_colors( default => 'dim' ) },  qr/\ATerm::Fabulous::Chart::Palette: mode must be one of dark, light, got 'dim'/, 'an unknown mode dies';
};

subtest 'chart_color' => sub {
	is [ chart_color( 'Chart', 'color', 0xFF8800 ) ],                              [ 0xFF8800, 1 ],         'a packed integer is opaque';
	is [ chart_color( 'Chart', 'color', '#3987e580' ) ],                           [ 0x3987e5, 128 / 255 ], 'alpha as an opacity';
	is [ chart_color( 'Chart', 'color', 'rgb(255, 136, 0)' ) ],                    [ 0xFF8800, 1 ],         'a CSS function';
	is [ chart_color( 'Chart', 'color', [ 1, 2, 3, 0 ] ) ],                        [ 0x010203, 0 ],         'an array';
	is [ chart_color( 'Chart', 'color', Term::Fabulous::Color->rgb( 1, 2, 3 ) ) ], [ 0x010203, 1 ],         'a color object';
	like dies { chart_color( 'Chart', 'color', 'nonsense' ) }, qr/\AChart: color must be a color, got 'nonsense'/, 'an invalid color dies';
	like dies { chart_color( 'Chart', 'color', 0x1000000 ) },  qr/a packed color is at most 0xFFFFFF/,             'so does an integer out of range';
};

subtest 'color arithmetic' => sub {
	is [ mix_rgb( 0x000000, 0xFFFFFF, 0.5 ), mix_rgb( 0xFF0000, 0x0000FF, 0.25 ) ], [ 0x808080, 0xBF0040 ], 'mix_rgb mixes channel by channel';
	is [ mix_rgb( 0x123456, 0xABCDEF, 0 ), mix_rgb( 0x123456, 0xABCDEF, 1 ), mix_rgb( 0x123456, 0xABCDEF, -1 ), mix_rgb( 0x123456, 0xABCDEF, 2 ) ], [ 0x123456, 0xABCDEF, 0x123456, 0xABCDEF ],
		'and stays between the two';

	is [ luminance(0x000000), luminance(0xFFFFFF), luminance(0xFF0000) ],             [ 0, 1, float(0.2126) ], 'luminance';
	is [ map { is_light_rgb($_) } 0xFFFFFF, 0xeda100, 0x808080, 0x141923, 0x000000 ], [ 1, 1, 1, 0, 0 ],       'is_light_rgb';
	is [ contrast_rgb(0xeda100), contrast_rgb(0x141923) ],                            [ 0x111111, 0xF5F5F5 ],  'contrast_rgb: dark text on light colors and the other way round';
	is rgb_hex(0x3987e5),                                                             '#3987e5',               'rgb_hex';
	is rgb_hex(0x00000a),                                                             '#00000a',               'with leading zeros';
};

subtest 'ink_colors' => sub {
	is ink_colors( 0x000000, 'dark' ),  { title => 0xF2F2F2, text => 0xCCCCCC, label => 0x8C8C8C, axis => 0x4D4D4D, grid => 0x1F1F1F }, 'white ink mixed into a dark background';
	is ink_colors( 0xFFFFFF, 'light' ), { title => 0x171717, text => 0x3C3C3C, label => 0x797979, axis => 0xB6B6B6, grid => 0xE2E2E2 }, 'near black ink mixed into a light one';
	like dies { ink_colors( 0, 'dim' ) }, qr/\ATerm::Fabulous::Chart::Palette: mode must be one of dark, light, got 'dim'/, 'an unknown mode dies';
};

subtest 'radial geometry' => sub {
	is [ CELL_ASPECT, TAU ], [ 2, float( 8 * atan2( 1, 1 ) ) ], 'constants';
	my $circle = circle_frame( 0, 0, 40, 20 );
	is $circle, { center_x => 20, center_y => 10, radius => 20 }, 'circle_frame: the largest circle in the cells';
	is circle_frame( 4, 2, 40, 5, 1 ), { center_x => 24, center_y => 4.5, radius => 4 }, 'limited by the rows, less the margin';
	is circle_frame( 0, 0, 2, 1, 5 )->{radius}, 0, 'never a negative radius';

	is [ polar_of( $circle, 30, 10 ) ],       [ 10, 0.25 ], 'polar_of: 3 o\'clock';
	is [ polar_of( $circle, 20, 5 ) ],        [ 10, 0 ],    'a row counts as two cell widths: 12 o\'clock';
	is [ polar_of( $circle, 20, 15 ) ],       [ 10, 0.5 ],  '6 o\'clock';
	is [ polar_of( $circle, 10, 10 ) ],       [ 10, 0.75 ], '9 o\'clock';
	is [ polar_of( $circle, 30, 10, 0.25 ) ], [ 10, 0 ],    'angles count from the start';
	is [ polar_of( $circle, 20, 5, 0.25 ) ],  [ 10, 0.75 ], 'and stay between 0 and 1';

	is [ point_at( $circle, 10, 0.5 ) ], [ float(20), float(15) ], 'point_at: 6 o\'clock';
	is [ point_at( $circle, 10, 0, 0.25 ) ], [ float(30), float(10) ], 'after the start';
	foreach my $case ( [ 3, 0.1, 0 ], [ 7.5, 0.4, 0.2 ], [ 12, 0.85, 0.6 ] ) {
		my ( $distance, $angle, $start ) = @$case;
		is [ polar_of( $circle, point_at( $circle, $distance, $angle, $start ), $start ) ], [ float($distance), float($angle) ], "polar_of inverts point_at: $distance at $angle after $start";
	}
};

done_testing;
