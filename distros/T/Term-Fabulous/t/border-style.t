use v5.32;
use warnings;

use Test2::V0;

use Object::Pad 0.825;

use Clay::XS qw(sizing_fixed);
use Term::Fabulous::Color;
use Term::Fabulous::Enum::BorderStyle;
use Term::Fabulous::Layout;
use Term::Fabulous::Static;
use Term::Fabulous::Theme;
use Term::Fabulous::Widget::Box;
use Term::Fabulous::Widget::ScrollBox;
use Term::Fabulous::Widget::Text;

my $Style = 'Term::Fabulous::Enum::BorderStyle';

subtest 'mixed joints' => sub {
	is $Style->Solid->get_mixed_joint( $Style->Heavy )->[0],           "\x{2542}", 'Solid crossing Heavy';
	is $Style->Solid->get_mixed_joint( $Style->Double )->[0],          "\x{256B}", 'Solid crossing Double';
	is $Style->Double->get_mixed_joint( $Style->Solid )->[1],          "\x{2564}", 'Double crossing Solid';
	is $Style->get_mixed_joints( $Style->Heavy, $Style->Solid )->[0],  "\x{253F}", 'class-method form';
	is scalar( @{ $Style->Heavy->get_mixed_joint( $Style->Solid ) } ), 5,          'five glyphs';
	is $Style->Round->get_mixed_joint( $Style->Solid ),                undef,      'no table';
	is $Style->Solid->get_mixed_joint( $Style->Round ),                undef,      'no table for that vertical style';
	like dies { $Style->Solid->get_mixed_joint('Heavy') }, qr/vertical style must be a Term::Fabulous::Enum::BorderStyle/, 'a name is rejected';
	ref_is $Style->Dashed->joints, $Style->Heavy->joints, 'Dashed uses the heavy joints';
};

subtest 'junction' => sub {
	my ( $S, $H, $D, $R, $A ) = map { $Style->$_ } qw(Solid Heavy Double Round Ascii);
	is $Style->junction( left => $S, right => $S ),                       "\x{2500}", 'two opposite arms: the edge glyph';
	is $Style->junction( right => $Style->Dashed ),                       "\x{254D}", 'one arm: the edge glyph, a dashed line stays dashed';
	is $Style->junction( up => $S, down => $S ),                          "\x{2502}", 'vertical arms: the left edge glyph';
	is $Style->junction( right => $R, down => $R ),                       "\x{256D}", 'a corner of a round style is round';
	is $Style->junction( up => $S, left => $H ),                          "\x{251B}", 'a corner of mixed styles takes the horizontal one';
	is $Style->junction( up => $S, right => $S, down => $S, left => $S ), "\x{253C}", 'four arms: the cross';
	is $Style->junction( left => $D, right => $D, down => $S ),           "\x{2564}", 'mixed families use the mixed joints';
	is $Style->junction( up => $S, down => $S, right => $H ),             "\x{251D}", 'heavy to the right of a light line';
	is $Style->junction( up => $R, down => $R, left => $S, right => $S ), "\x{253C}", 'Round counts as Solid';
	is $Style->junction( up => $H, down => $H, left => $D, right => $D ), "\x{256C}", 'without a mixed table, the horizontal joints';
	is $Style->junction( right => $A, down => $A, left => $A ),           '+',        'Ascii joints';
	is $Style->junction( right => $Style->Blank, down => $Style->Thick ), undef,      'styles without joints are no arms';
	is $Style->junction(),                                                undef,      'no arms';
	like dies { $Style->junction( middle => $S ) },      qr/junction takes the arms up, right, down and left, got middle/, 'an unknown arm dies';
	like dies { $Style->junction( up     => 'Solid' ) }, qr/the up arm style must be a Term::Fabulous::Enum::BorderStyle/, 'a style name dies';
};

subtest 'junction: an arm without joints is no line, also next to one with joints' => sub {
	my ( $S, $Hidden ) = map { $Style->$_ } qw(Solid Hidden);
	is $Style->junction( right => $Hidden, left => $S, down => $S ), "\x{2510}", 'a hidden right arm leaves the corner of the left and the down arm';
	is $Style->junction( down => $Hidden, up => $S, right => $S, left => $S ), "\x{2534}", 'a hidden down arm leaves the T of the other three';
};

subtest 'style list' => sub {
	is $Style->from_name('Tab'), undef, 'Tab is gone';
	isa_ok $Style->from_name('Hidden'), [$Style], 'Hidden exists';
	like dies { Term::Fabulous::Layout->new( string => "use Term::Fabulous::Widget::Box as Box\nBox {\n\tborder style=Tab\n}" )->build },
		qr/Box: border style must be a border style or its name, got 'Tab' \(known: Ascii, .*Wide\)/, 'a layout with style=Tab dies';
};

subtest 'widget border styles take items and names' => sub {
	ref_is( Term::Fabulous::Widget::Box->new( border_style     => 'Round' )->border_style_top,  $Style->Round,  'border_style takes a name' );
	ref_is( Term::Fabulous::Widget::Box->new( border_style_top => 'Double' )->border_style_top, $Style->Double, 'so does a side parameter' );
	like dies { Term::Fabulous::Widget::Box->new( border_style => 'round' ) },
		qr/\ATerm::Fabulous::Widget::Box: border_style must be a border style or its name, got 'round' \(known: Ascii, Blank, /, 'names are case sensitive';
	like dies { Term::Fabulous::Widget::Box->new( border_style_top => [] ) }, qr/border_style_top must be a border style or its name, got an ARRAY reference/, 'a side parameter is checked';

	my $box = Term::Fabulous::Widget::Box->new( border_style => $Style->Round );
	ref_is $box->border_style_left, $Style->Round, 'border_style sets every side';
	my $mixed = Term::Fabulous::Widget::Box->new( border_style => $Style->Round, border_style_left => $Style->Thick );
	is [ map { $mixed->$_ } qw(border_style_left border_style_top) ], [ $Style->Thick, $Style->Round ], 'a side parameter wins over border_style';
	ref_is $box->border_style_left('Heavy'), $Style->Heavy, 'an accessor takes a name and returns the item';
	like dies { $box->border_style_left('Tab') }, qr/border_style_left must be a border style or its name, got 'Tab'/, 'accessor write is checked';
	ok lives { $box->border_style_left(undef) }, 'undef clears a side';
};

# A box that derives a Double left side and a Hidden bottom side.
class DerivingBox :isa(Term::Fabulous::Widget::Box) {

	method derived_border_style ($side) {
		return $side eq 'left' ? Term::Fabulous::Enum::BorderStyle->Double : $side eq 'bottom' ? Term::Fabulous::Enum::BorderStyle->Hidden : undef;
	}
}

subtest 'the style a side is drawn in' => sub {
	my $theme_style = Term::Fabulous::Theme->default->look( box => 'border.style' );
	my $box         = DerivingBox->new( border_style_top => 'Heavy' );
	ref_is $box->border_style_of('top'),     $Style->Heavy,  'its own style first';
	ref_is $box->border_style_of('left'),    $Style->Double, 'else the derived one';
	ref_is $box->border_style_of('right'),   $theme_style,   'else the theme\'s border.style';
	ref_is $box->border_style_of('bottom'),  $Style->Hidden, 'a derived Hidden side';
	ref_is $box->border_style_left('Thick'), $Style->Thick,  'a style of its own';
	ref_is $box->border_style_of('left'),    $Style->Thick,  'wins over the derived one';
	is $box->border_style_left(undef), undef, 'the writer returns the new value, undef too';
	ref_is $box->border_style_left,  $Style->Double, 'and the reader the style in use again';
	ref_is $box->border_style_right, $theme_style,   'every reader answers the style in use';
	like dies { $box->border_style_of('middle') }, qr/border_style_of takes a side \(left right top bottom\), got 'middle'/, 'an unknown side dies';

	my $none = Term::Fabulous::Theme->new( name => 'none', slots => { 'box.border.style' => 'none' } );
	my $bare = Term::Fabulous::Widget::Box->new( bordered => 1, layout => { sizing => { width => sizing_fixed(4), height => sizing_fixed(3) } } );
	my $ui   = Term::Fabulous::Static->new( root => $bare, width => 4, theme => $none );
	ref_is $bare->border_style_of('top'), $Style->Blank, 'without a style anywhere: Blank';

	my $framed = DerivingBox->new( bordered => 1, border_style => 'Solid', layout => { sizing => { width => sizing_fixed(4), height => sizing_fixed(3) } } );
	$framed->border_style_left(undef);
	$framed->border_style_bottom(undef);
	is [ Term::Fabulous::Static->new( root => $framed, width => 4 )->render_lines( colors => 0 ) ], [ "\x{250C}\x{2500}\x{2500}\x{2510}", "\x{2551}  \x{2502}", "\x{2551}  \x{2502}" ],
		'the renderer draws the derived styles, and a derived Hidden side takes no space';
};

subtest 'widget colors take every Term::Fabulous::Color format' => sub {
	my $box = Term::Fabulous::Widget::Box->new( background_color => '#ff8800', border_color => Term::Fabulous::Color->rgb( 1, 2, 3 ) );
	is [ $box->background_color, $box->border_color ], [ [ 255, 136, 0, 255 ], [ 1, 2, 3, 255 ] ], 'constructor strings and objects become [r, g, b, a]';
	is $box->background_color('rgb(4, 5, 6)'),         [ 4, 5, 6, 255 ],                           'the writer converts too';
	is $box->background_color(undef),                  undef,                                      'undef still clears the color';
	like dies { Term::Fabulous::Widget::Box->new( border_color => 'nope' ) }, qr/\ATerm::Fabulous::Widget::Box: border_color must be a color, got 'nope' \(unrecognized color string 'nope'\)/,
		'an invalid color names the parameter';
	is( Term::Fabulous::Widget::Text->new( text => 'x', text_color => '#ffffff' )->text_color, [ 255, 255, 255, 255 ], 'Text text_color' );
	is( Term::Fabulous::Widget::ScrollBox->new( id => 's', vertical => '' )->vertical,         0,                      'ScrollBox booleans are stored as 1 or 0' );
};

done_testing;
