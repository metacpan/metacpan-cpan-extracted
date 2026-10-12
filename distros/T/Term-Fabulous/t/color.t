use v5.32;
use warnings;

use Test2::V0;

use Term::Fabulous::Color;
use Term::Fabulous::Enum::WebColor;

my $Color = 'Term::Fabulous::Color';

sub rgba_of {
	my ($spec) = @_;
	return [ $Color->new( color => $spec )->to_rgba ];
}

subtest 'string grammar' => sub {
	is rgba_of('#ff00ff'),                   [ 255, 0,   255, 255 ], '#rrggbb';
	is rgba_of('7c3aed80'),                  [ 124, 58,  237, 128 ], 'rrggbbaa without #';
	is rgba_of('rgb(255, 255, 255)'),        [ 255, 255, 255, 255 ], 'rgb() accepts 255';
	is rgba_of('hsl(0, 100%, 50%)'),         [ 255, 0,   0,   255 ], 'hsl()';
	is rgba_of('hsl(720, 100%, 50%)'),       [ 255, 0,   0,   255 ], 'hue is taken modulo 360';
	is rgba_of('hsla(120, 100%, 50%, 0.5)'), [ 0,   255, 0,   128 ], 'hsla()';
	is rgba_of(0xFF8800),                    [ 255, 136, 0,   255 ], 'a packed integer';
	is rgba_of('#123456'),                   [ 18,  52,  86,  255 ], 'digits-only hex with #';
	like dies { rgba_of( 0xFFFFFF + 1 ) }, qr/packed integer color must be in 0\.\.0xFFFFFF/, 'a packed integer above 0xFFFFFF dies';
};

subtest 'web color names' => sub {
	is rgba_of('SteelBlue'),                                          [ 70, 130, 180, 255 ],                               'a web color name, as WebColor spells it';
	is [ map { rgba_of($_) } 'steelblue', 'STEELBLUE', 'sTeElBlUe' ], [ ( [ 70, 130, 180, 255 ] ) x 3 ],                   'in any case';
	is rgba_of('rebeccapurple'),                                      [ 102, 51, 153, 255 ],                               'every CSS name';
	is rgba_of('grey'),                                               rgba_of('gray'),                                     'both spellings of gray';
	is rgba_of('Tomato'),                                             [ Term::Fabulous::Enum::WebColor->Tomato->to_rgba ], 'the colors of Term::Fabulous::Enum::WebColor';
	like dies { $Color->new( color => 'steelblu' ) },   qr/\ATerm::Fabulous::Color: unrecognized color string 'steelblu' at /, 'an unknown name dies naming it';
	like dies { $Color->new( color => 'steel blue' ) }, qr/unrecognized color string 'steel blue'/,                            'names have no spaces';
	is [ grep { $_->name =~ /\A(?:[0-9a-fA-F]{6}|[0-9a-fA-F]{8})\z/ } Term::Fabulous::Enum::WebColor->values ], [], 'no name reads as a hex color';
};

subtest 'blend' => sub {
	my $black = $Color->rgb( 0, 0, 0 );
	is [ $black->blend( $Color->rgb( 255, 255, 255 ), 0.5 )->to_rgba ], [ 128, 128, 128, 255 ], 'channels are rounded';
	like dies { $black->blend( [ 255, 255, 255 ], 0.5 ) }, qr/blend needs a Term::Fabulous::Color/,    'a non-Color dies';
	like dies { $black->blend( $black,            2 ) },   qr/blend ratio must be a number in 0\.\.1/, 'a ratio outside 0..1 dies';
};

subtest 'alpha grammar' => sub {
	is rgba_of('rgba(1, 2, 3, 1)')->[3],   1,   'bare integer is the 0..255 channel';
	is rgba_of('rgba(1, 2, 3, 255)')->[3], 255, 'bare 255';
	is rgba_of('rgba(1, 2, 3, 1.0)')->[3], 255, 'decimal is a fraction of 1';
	is rgba_of('rgba(1, 2, 3, .25)')->[3], 64,  'leading-dot decimal, rounded';
	is rgba_of('rgba(1, 2, 3, 50%)')->[3], 128, 'percentage';
	like dies { rgba_of('rgba(1, 2, 3, 1.5)') },  qr/alpha fraction must be a number in 0\.\.1/,     'fraction above 1 dies';
	like dies { rgba_of('rgba(1, 2, 3, 101%)') }, qr/alpha percentage must be a number in 0\.\.100/, 'percentage above 100 dies';
	like dies { rgba_of('rgba(1, 2, 3, 256)') },  qr/alpha must be a number in 0\.\.255/,            'channel above 255 dies';
};

subtest 'is_translucent' => sub {
	is [ map { $Color->rgba( 0, 0, 0, $_ )->is_translucent ? 1 : 0 } 0, 1, 254, 255 ], [ 0, 1, 1, 0 ], 'true for alpha 1 to 254 only';
};

subtest 'hash, array and clone inputs' => sub {
	is rgba_of( { r => 1, g => 2, b => 3 } ),                      [ 1, 2, 3, 255 ], 'r/g/b hash';
	is rgba_of( { red => 1, green => 2, blue => 3, alpha => 4 } ), [ 1, 2, 3, 4 ],   'red/green/blue/alpha hash';
	is rgba_of( [ 1, 2, 3 ] ),                                     [ 1, 2, 3, 255 ], 'three-element array';
	is rgba_of( $Color->new( color => [ 9, 8, 7, 6 ] ) ),          [ 9, 8, 7, 6 ],   'clone of another Color';
	like dies { rgba_of( { r => 1, g => 2 } ) },                 qr/color hash needs exactly the keys/, 'incomplete hash dies';
	like dies { rgba_of( { r => 1, g => 2, b => 3, x => 4 } ) }, qr/color hash needs exactly the keys/, 'extra hash key dies';
	like dies { rgba_of( [ 1, 2 ] ) },                           qr/needs 3 or 4 elements, got 2/,      'short array dies';
	like dies { rgba_of(undef) },                                qr/invalid color input undef/,         'undef dies';
};

subtest 'channel validation and rounding' => sub {
	is rgba_of( [ 254.6, 0.4, 255, 0 ] ), [ 255, 0, 255, 0 ], 'channels are rounded to the nearest integer';
	like dies { rgba_of( [ 256,    0, 0 ] ) },   qr/red must be a number in 0\.\.255, got '256'/,  'above 255 dies';
	like dies { rgba_of( [ 0,     -1, 0 ] ) },   qr/green must be a number in 0\.\.255, got '-1'/, 'negative dies';
	like dies { rgba_of( [ 0,      0, 'x' ] ) }, qr/blue must be a number in 0\.\.255, got 'x'/,   'non-numeric dies';
	like dies { rgba_of( [ 'nan',  0, 0 ] ) },   qr/red must be a number/,                         'NaN dies';
	like dies { $Color->new( color => [ 1, 2, 3 ], red => 1 ) }, qr/Unrecognised parameters/, 'channel params are not constructor params';
};

subtest 'HSL conversions round once' => sub {
	my $color = $Color->rgb( 10, 200, 30 );
	is [ $color->lighten(0)->to_rgba ],                                    [ 10, 200, 30, 255 ],                                      'lighten(0) is an identity';
	is [ $color->to_hsl ],                                                 [ 126, 90, 41 ],                                           'to_hsl rounds';
	is [ $Color->hsl_to_rgb( 0, 100, 50 ) ],                               [ 255, 0, 0 ],                                             'hsl_to_rgb';
	is [ $Color->rgb_to_hsl( 255, 0, 0 ) ],                                [ 0, 100, 50 ],                                            'rgb_to_hsl';
	is [ $Color->hsl( 174, 72, 56 )->to_rgba ],                            [ $Color->new( color => 'hsl(174, 72%, 56%)' )->to_rgba ], 'hsl factory matches the string form';
	is [ map { $Color->hsla( 174, 72, 56, $_ )->alpha } 0.5, '50%', 128 ], [ 128, 128, 128 ],                                         'hsla alpha uses the string grammar';
	is [ map { $Color->rgba( 1, 2, 3, $_ )->alpha } 0.5, '50%', 128 ],     [ 128, 128, 128 ],                                         'rgba alpha uses the string grammar';
	like dies { $Color->hsla( 0, 0, 0, 1.5 ) },   qr/alpha fraction must be a number in 0\.\.1/, 'hsla alpha fraction above 1 dies';
	like dies { $Color->rgba( 0, 0, 0, undef ) }, qr/alpha must be a number, got undef/,         'rgba alpha undef dies';
	is [ $color->darken(0.1)->to_rgba ], [ $color->lighten(-0.1)->to_rgba ], 'darken is negative lighten';
};

done_testing;
