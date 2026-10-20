package Term::Fabulous::Enum::WebColor;

use v5.32;
use warnings;

our $VERSION = '0.05';

use Object::PadX::Enum;

# The named colors of CSS Color Module Level 4, in alphabetical order,
# spelled as in the HTML color name listings (DarkGoldenRod, SeaShell).
enum Term::Fabulous::Enum::WebColor :isa(Term::Fabulous::Color) {
	item AliceBlue( color => '#f0f8ff' );
	item AntiqueWhite( color => '#faebd7' );
	item Aqua( color => '#00ffff' );
	item Aquamarine( color => '#7fffd4' );
	item Azure( color => '#f0ffff' );
	item Beige( color => '#f5f5dc' );
	item Bisque( color => '#ffe4c4' );
	item Black( color => '#000000' );
	item BlanchedAlmond( color => '#ffebcd' );
	item Blue( color => '#0000ff' );
	item BlueViolet( color => '#8a2be2' );
	item Brown( color => '#a52a2a' );
	item BurlyWood( color => '#deb887' );
	item CadetBlue( color => '#5f9ea0' );
	item Chartreuse( color => '#7fff00' );
	item Chocolate( color => '#d2691e' );
	item Coral( color => '#ff7f50' );
	item CornflowerBlue( color => '#6495ed' );
	item Cornsilk( color => '#fff8dc' );
	item Crimson( color => '#dc143c' );
	item Cyan( color => '#00ffff' );
	item DarkBlue( color => '#00008b' );
	item DarkCyan( color => '#008b8b' );
	item DarkGoldenRod( color => '#b8860b' );
	item DarkGray( color => '#a9a9a9' );
	item DarkGreen( color => '#006400' );
	item DarkGrey( color => '#a9a9a9' );
	item DarkKhaki( color => '#bdb76b' );
	item DarkMagenta( color => '#8b008b' );
	item DarkOliveGreen( color => '#556b2f' );
	item DarkOrange( color => '#ff8c00' );
	item DarkOrchid( color => '#9932cc' );
	item DarkRed( color => '#8b0000' );
	item DarkSalmon( color => '#e9967a' );
	item DarkSeaGreen( color => '#8fbc8f' );
	item DarkSlateBlue( color => '#483d8b' );
	item DarkSlateGray( color => '#2f4f4f' );
	item DarkSlateGrey( color => '#2f4f4f' );
	item DarkTurquoise( color => '#00ced1' );
	item DarkViolet( color => '#9400d3' );
	item DeepPink( color => '#ff1493' );
	item DeepSkyBlue( color => '#00bfff' );
	item DimGray( color => '#696969' );
	item DimGrey( color => '#696969' );
	item DodgerBlue( color => '#1e90ff' );
	item FireBrick( color => '#b22222' );
	item FloralWhite( color => '#fffaf0' );
	item ForestGreen( color => '#228b22' );
	item Fuchsia( color => '#ff00ff' );
	item Gainsboro( color => '#dcdcdc' );
	item GhostWhite( color => '#f8f8ff' );
	item Gold( color => '#ffd700' );
	item GoldenRod( color => '#daa520' );
	item Gray( color => '#808080' );
	item Green( color => '#008000' );
	item GreenYellow( color => '#adff2f' );
	item Grey( color => '#808080' );
	item HoneyDew( color => '#f0fff0' );
	item HotPink( color => '#ff69b4' );
	item IndianRed( color => '#cd5c5c' );
	item Indigo( color => '#4b0082' );
	item Ivory( color => '#fffff0' );
	item Khaki( color => '#f0e68c' );
	item Lavender( color => '#e6e6fa' );
	item LavenderBlush( color => '#fff0f5' );
	item LawnGreen( color => '#7cfc00' );
	item LemonChiffon( color => '#fffacd' );
	item LightBlue( color => '#add8e6' );
	item LightCoral( color => '#f08080' );
	item LightCyan( color => '#e0ffff' );
	item LightGoldenRodYellow( color => '#fafad2' );
	item LightGray( color => '#d3d3d3' );
	item LightGreen( color => '#90ee90' );
	item LightGrey( color => '#d3d3d3' );
	item LightPink( color => '#ffb6c1' );
	item LightSalmon( color => '#ffa07a' );
	item LightSeaGreen( color => '#20b2aa' );
	item LightSkyBlue( color => '#87cefa' );
	item LightSlateGray( color => '#778899' );
	item LightSlateGrey( color => '#778899' );
	item LightSteelBlue( color => '#b0c4de' );
	item LightYellow( color => '#ffffe0' );
	item Lime( color => '#00ff00' );
	item LimeGreen( color => '#32cd32' );
	item Linen( color => '#faf0e6' );
	item Magenta( color => '#ff00ff' );
	item Maroon( color => '#800000' );
	item MediumAquaMarine( color => '#66cdaa' );
	item MediumBlue( color => '#0000cd' );
	item MediumOrchid( color => '#ba55d3' );
	item MediumPurple( color => '#9370db' );
	item MediumSeaGreen( color => '#3cb371' );
	item MediumSlateBlue( color => '#7b68ee' );
	item MediumSpringGreen( color => '#00fa9a' );
	item MediumTurquoise( color => '#48d1cc' );
	item MediumVioletRed( color => '#c71585' );
	item MidnightBlue( color => '#191970' );
	item MintCream( color => '#f5fffa' );
	item MistyRose( color => '#ffe4e1' );
	item Moccasin( color => '#ffe4b5' );
	item NavajoWhite( color => '#ffdead' );
	item Navy( color => '#000080' );
	item OldLace( color => '#fdf5e6' );
	item Olive( color => '#808000' );
	item OliveDrab( color => '#6b8e23' );
	item Orange( color => '#ffa500' );
	item OrangeRed( color => '#ff4500' );
	item Orchid( color => '#da70d6' );
	item PaleGoldenRod( color => '#eee8aa' );
	item PaleGreen( color => '#98fb98' );
	item PaleTurquoise( color => '#afeeee' );
	item PaleVioletRed( color => '#db7093' );
	item PapayaWhip( color => '#ffefd5' );
	item PeachPuff( color => '#ffdab9' );
	item Peru( color => '#cd853f' );
	item Pink( color => '#ffc0cb' );
	item Plum( color => '#dda0dd' );
	item PowderBlue( color => '#b0e0e6' );
	item Purple( color => '#800080' );
	item RebeccaPurple( color => '#663399' );
	item Red( color => '#ff0000' );
	item RosyBrown( color => '#bc8f8f' );
	item RoyalBlue( color => '#4169e1' );
	item SaddleBrown( color => '#8b4513' );
	item Salmon( color => '#fa8072' );
	item SandyBrown( color => '#f4a460' );
	item SeaGreen( color => '#2e8b57' );
	item SeaShell( color => '#fff5ee' );
	item Sienna( color => '#a0522d' );
	item Silver( color => '#c0c0c0' );
	item SkyBlue( color => '#87ceeb' );
	item SlateBlue( color => '#6a5acd' );
	item SlateGray( color => '#708090' );
	item SlateGrey( color => '#708090' );
	item Snow( color => '#fffafa' );
	item SpringGreen( color => '#00ff7f' );
	item SteelBlue( color => '#4682b4' );
	item Tan( color => '#d2b48c' );
	item Teal( color => '#008080' );
	item Thistle( color => '#d8bfd8' );
	item Tomato( color => '#ff6347' );
	item Turquoise( color => '#40e0d0' );
	item Violet( color => '#ee82ee' );
	item Wheat( color => '#f5deb3' );
	item White( color => '#ffffff' );
	item WhiteSmoke( color => '#f5f5f5' );
	item Yellow( color => '#ffff00' );
	item YellowGreen( color => '#9acd32' );
	}

	1;

__END__

=head1 NAME

Term::Fabulous::Enum::WebColor - The CSS named colors as
Term::Fabulous::Color objects

=head1 SYNOPSIS

	use Term::Fabulous::Enum::WebColor;

	my $tomato = Term::Fabulous::Enum::WebColor->Tomato;    # a Term::Fabulous::Color
	$box->background_color($tomato);                         # widgets take the object itself
	$canvas->fill( 0, 0, 10, 2, ' ', undef, Term::Fabulous::Enum::WebColor->MidnightBlue );

	my $color = Term::Fabulous::Enum::WebColor->from_name('SteelBlue');    # undef for unknown names
	my @all   = Term::Fabulous::Enum::WebColor->values;                     # 148 colors, AliceBlue first

=head1 DESCRIPTION

An L<Object::PadX::Enum> enumeration of the 148 named colors of CSS
(CSS Color Module Level 4, including the C<Gray>/C<Grey> spellings and
C<RebeccaPurple>). Every item is a L<Term::Fabulous::Color> with alpha
255, so it has all of that class's methods: C<to_rgba>, C<rgb_int>,
C<lighten>, C<blend> and so on. Items are singletons; derived colors
such as C<< ->Red->with_alpha(128) >> are new, plain
Term::Fabulous::Color objects.

The item names are in PascalCase, as the other enumerations of
Term::Fabulous, and C<from_name> is case sensitive: C<'SteelBlue'> is
found, C<'steelblue'> is not. Every color input of Term::Fabulous takes
the names as strings as well, in any case (C<'steelblue'>,
C<text_color "SteelBlue"> in KDL): see
L<Term::Fabulous::Color/A string>. F<examples/web-colors.pl> shows all of the colors in a grid.

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.05/screenshots/example-web-colors.svg" alt="A grid of color swatches with their hex values and names, and a dropdown to sort them"></p>

=end html

=head1 METHODS

=head2 values

	my @colors = Term::Fabulous::Enum::WebColor->values;

Class method. All items in the order of the table below.

=head2 from_name

	my $color = Term::Fabulous::Enum::WebColor->from_name('Tomato');

Class method. The item with that exact name, or C<undef>.

=head2 from_ordinal

	my $color = Term::Fabulous::Enum::WebColor->from_ordinal(0);    # AliceBlue

Class method. The item at a position of L</values>, counted from 0, or
C<undef> when there is none.

=head2 name

	say Term::Fabulous::Enum::WebColor->Tomato->name;    # Tomato

The name of an item.

=head2 ordinal

	my $position = Term::Fabulous::Enum::WebColor->Tomato->ordinal;

The position of an item in L</values>, counted from 0.

Every item also has all methods of L<Term::Fabulous::Color>.

=head1 COLORS

=for highlighter language=text

	Name                  Value
	--------------------  -------
	AliceBlue             #f0f8ff
	AntiqueWhite          #faebd7
	Aqua                  #00ffff
	Aquamarine            #7fffd4
	Azure                 #f0ffff
	Beige                 #f5f5dc
	Bisque                #ffe4c4
	Black                 #000000
	BlanchedAlmond        #ffebcd
	Blue                  #0000ff
	BlueViolet            #8a2be2
	Brown                 #a52a2a
	BurlyWood             #deb887
	CadetBlue             #5f9ea0
	Chartreuse            #7fff00
	Chocolate             #d2691e
	Coral                 #ff7f50
	CornflowerBlue        #6495ed
	Cornsilk              #fff8dc
	Crimson               #dc143c
	Cyan                  #00ffff
	DarkBlue              #00008b
	DarkCyan              #008b8b
	DarkGoldenRod         #b8860b
	DarkGray              #a9a9a9
	DarkGreen             #006400
	DarkGrey              #a9a9a9
	DarkKhaki             #bdb76b
	DarkMagenta           #8b008b
	DarkOliveGreen        #556b2f
	DarkOrange            #ff8c00
	DarkOrchid            #9932cc
	DarkRed               #8b0000
	DarkSalmon            #e9967a
	DarkSeaGreen          #8fbc8f
	DarkSlateBlue         #483d8b
	DarkSlateGray         #2f4f4f
	DarkSlateGrey         #2f4f4f
	DarkTurquoise         #00ced1
	DarkViolet            #9400d3
	DeepPink              #ff1493
	DeepSkyBlue           #00bfff
	DimGray               #696969
	DimGrey               #696969
	DodgerBlue            #1e90ff
	FireBrick             #b22222
	FloralWhite           #fffaf0
	ForestGreen           #228b22
	Fuchsia               #ff00ff
	Gainsboro             #dcdcdc
	GhostWhite            #f8f8ff
	Gold                  #ffd700
	GoldenRod             #daa520
	Gray                  #808080
	Green                 #008000
	GreenYellow           #adff2f
	Grey                  #808080
	HoneyDew              #f0fff0
	HotPink               #ff69b4
	IndianRed             #cd5c5c
	Indigo                #4b0082
	Ivory                 #fffff0
	Khaki                 #f0e68c
	Lavender              #e6e6fa
	LavenderBlush         #fff0f5
	LawnGreen             #7cfc00
	LemonChiffon          #fffacd
	LightBlue             #add8e6
	LightCoral            #f08080
	LightCyan             #e0ffff
	LightGoldenRodYellow  #fafad2
	LightGray             #d3d3d3
	LightGreen            #90ee90
	LightGrey             #d3d3d3
	LightPink             #ffb6c1
	LightSalmon           #ffa07a
	LightSeaGreen         #20b2aa
	LightSkyBlue          #87cefa
	LightSlateGray        #778899
	LightSlateGrey        #778899
	LightSteelBlue        #b0c4de
	LightYellow           #ffffe0
	Lime                  #00ff00
	LimeGreen             #32cd32
	Linen                 #faf0e6
	Magenta               #ff00ff
	Maroon                #800000
	MediumAquaMarine      #66cdaa
	MediumBlue            #0000cd
	MediumOrchid          #ba55d3
	MediumPurple          #9370db
	MediumSeaGreen        #3cb371
	MediumSlateBlue       #7b68ee
	MediumSpringGreen     #00fa9a
	MediumTurquoise       #48d1cc
	MediumVioletRed       #c71585
	MidnightBlue          #191970
	MintCream             #f5fffa
	MistyRose             #ffe4e1
	Moccasin              #ffe4b5
	NavajoWhite           #ffdead
	Navy                  #000080
	OldLace               #fdf5e6
	Olive                 #808000
	OliveDrab             #6b8e23
	Orange                #ffa500
	OrangeRed             #ff4500
	Orchid                #da70d6
	PaleGoldenRod         #eee8aa
	PaleGreen             #98fb98
	PaleTurquoise         #afeeee
	PaleVioletRed         #db7093
	PapayaWhip            #ffefd5
	PeachPuff             #ffdab9
	Peru                  #cd853f
	Pink                  #ffc0cb
	Plum                  #dda0dd
	PowderBlue            #b0e0e6
	Purple                #800080
	RebeccaPurple         #663399
	Red                   #ff0000
	RosyBrown             #bc8f8f
	RoyalBlue             #4169e1
	SaddleBrown           #8b4513
	Salmon                #fa8072
	SandyBrown            #f4a460
	SeaGreen              #2e8b57
	SeaShell              #fff5ee
	Sienna                #a0522d
	Silver                #c0c0c0
	SkyBlue               #87ceeb
	SlateBlue             #6a5acd
	SlateGray             #708090
	SlateGrey             #708090
	Snow                  #fffafa
	SpringGreen           #00ff7f
	SteelBlue             #4682b4
	Tan                   #d2b48c
	Teal                  #008080
	Thistle               #d8bfd8
	Tomato                #ff6347
	Turquoise             #40e0d0
	Violet                #ee82ee
	Wheat                 #f5deb3
	White                 #ffffff
	WhiteSmoke            #f5f5f5
	Yellow                #ffff00
	YellowGreen           #9acd32

=head1 SEE ALSO

L<Term::Fabulous::Color>, L<Object::PadX::Enum>,
L<Term::Fabulous::Manual::Looks/COLORS>.

=cut
