package Term::Fabulous::Color;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Object::Pad 0.825;

class Term::Fabulous::Color :strict(params) {
	use List::Util qw( min max );
	use POSIX qw( floor );
	use Scalar::Util qw( blessed looks_like_number );

	my @CHANNEL_NAMES = qw( red green blue alpha );

	# Accepted hash shapes, keyed by their sorted key list.
	my %CHANNEL_KEYS_BY_HASH_SHAPE = (
		'b g r'                => [qw( r g b )],
		'a b g r'              => [qw( r g b a )],
		'blue green red'       => [qw( red green blue )],
		'alpha blue green red' => [qw( red green blue alpha )],
	);

	my $HEX_SPEC = qr/\A#?([0-9a-fA-F]{6}(?:[0-9a-fA-F]{2})?)\z/;
	my $NUMBER   = qr/[+-]?(?:[0-9]+(?:\.[0-9]*)?|\.[0-9]+)/;
	my $COMMA    = qr/\s*,\s*/;

	field $red   :reader;
	field $green :reader;
	field $blue  :reader;
	field $alpha :reader;

	# INVARIANT: Color is immutable post-ADJUST; lazy memo slots are safe.
	field $_rgb_int_cache;
	field $_rgba_int_cache;
	field $_fg_sgr_cache;
	field $_bg_sgr_cache;

	ADJUST :params ( :$color ) {
		my @channels = _channels_from_input($color);
		( $red, $green, $blue, $alpha ) = map { _checked_channel( $CHANNEL_NAMES[$_], $channels[$_] ) } 0 .. 3;
	}

	sub _describe ($value) {
		return 'undef' unless defined $value;
		return ref($value) . ' reference' if ref $value;
		return "'$value'";
	}

	sub _is_finite_number ($value) {
		return 0 unless defined $value && !ref $value && looks_like_number($value);
		return 0 if $value != $value;    # NaN
		return abs($value) != 9**9**9;    # +/- Inf
	}

	sub _round ($value) {
		return floor( $value + 0.5 );
	}

	# Rounds to the nearest integer; the rounded value must lie in 0..255.
	sub _checked_channel ( $name, $value ) {
		my $rounded = _is_finite_number($value) ? _round($value) : undef;
		die "Term::Fabulous::Color: $name must be a number in 0..255, got " . _describe($value)
			unless defined $rounded && $rounded >= 0 && $rounded <= 255;
		return $rounded;
	}

	sub _checked_range ( $name, $value, $low, $high ) {
		die "Term::Fabulous::Color: $name must be a number in $low..$high, got " . _describe($value)
			unless _is_finite_number($value) && $value >= $low && $value <= $high;
		return $value;
	}

	sub _channels_from_input ($color) {
		return $color->to_rgba if blessed $color && $color->isa('Term::Fabulous::Color');
		return _channels_from_hash($color) if ref $color eq 'HASH';
		return _channels_from_array($color) if ref $color eq 'ARRAY';
		return _channels_from_string($color) if defined $color && !ref $color;
		die "Term::Fabulous::Color: invalid color input " . _describe($color);
	}

	sub _channels_from_hash ($hash) {
		my $shape    = join ' ', sort keys %$hash;
		my $keys     = $CHANNEL_KEYS_BY_HASH_SHAPE{$shape} // die "Term::Fabulous::Color: a color hash needs exactly the keys r, g, b[, a] or red, green, blue[, alpha], got {$shape}";
		my @channels = @{$hash}{@$keys};
		return @channels == 3 ? ( @channels, 255 ) : @channels;
	}

	sub _channels_from_array ($array) {
		my $count = @$array;
		die "Term::Fabulous::Color: a color array needs 3 or 4 elements, got $count"
			unless $count == 3 || $count == 4;
		return $count == 3 ? ( @$array, 255 ) : @$array;
	}

	sub _channels_from_string ($spec) {
		if ( $spec =~ /\A[0-9]+\z/ ) {
			die "Term::Fabulous::Color: a packed integer color must be in 0..0xFFFFFF, got $spec" if $spec > 0xFFFFFF;
			return ( ( $spec >> 16 ) & 0xFF, ( $spec >> 8 ) & 0xFF, $spec & 0xFF, 255 );
		}
		if ( my ($hex) = $spec =~ $HEX_SPEC ) {
			my @channels = map { CORE::hex($_) } unpack '(A2)*', $hex;
			return @channels == 3 ? ( @channels, 255 ) : @channels;
		}
		if ( my @rgb = $spec =~ /\Argb\(\s*($NUMBER)$COMMA($NUMBER)$COMMA($NUMBER)\s*\)\z/ ) {
			return ( @rgb, 255 );
		}
		if ( my @rgba = $spec =~ /\Argba\(\s*($NUMBER)$COMMA($NUMBER)$COMMA($NUMBER)$COMMA($NUMBER%?)\s*\)\z/ ) {
			return ( @rgba[ 0 .. 2 ], _alpha_from_token( $rgba[3] ) );
		}
		if ( my @hsl = $spec =~ /\Ahsl\(\s*($NUMBER)$COMMA($NUMBER)%$COMMA($NUMBER)%\s*\)\z/ ) {
			return ( _hsl_to_rgb_float( _normalized_hsl(@hsl) ), 255 );
		}
		if ( my @hsla = $spec =~ /\Ahsla\(\s*($NUMBER)$COMMA($NUMBER)%$COMMA($NUMBER)%$COMMA($NUMBER%?)\s*\)\z/ ) {
			return ( _hsl_to_rgb_float( _normalized_hsl( @hsla[ 0 .. 2 ] ) ), _alpha_from_token( $hsla[3] ) );
		}
		if ( my $channels = _web_color_channels($spec) ) {
			return @$channels;
		}
		die "Term::Fabulous::Color: unrecognized color string '$spec'";
	}

	# The CSS color names of Term::Fabulous::Enum::WebColor, looked up
	# without regard to case. Its items are Colors themselves, so the
	# enumeration cannot be loaded before this class; the table is built
	# when the first name is looked up.
	my %RGBA_BY_WEB_NAME;

	sub _web_color_channels ($name) {
		if ( !%RGBA_BY_WEB_NAME ) {
			require Term::Fabulous::Enum::WebColor;
			%RGBA_BY_WEB_NAME = map { lc( $_->name ) => [ $_->to_rgba ] } Term::Fabulous::Enum::WebColor->values;
		}
		return $RGBA_BY_WEB_NAME{ lc $name };
	}

	# Alpha grammar of rgba()/hsla(), string and factory alike: "N%" is a
	# percentage, a number with a decimal point is a fraction of 1, a bare
	# integer is the 0..255 channel.
	sub _alpha_from_token ($token) {
		die "Term::Fabulous::Color: alpha must be a number, got " . _describe($token) unless defined $token && !ref $token;
		if ( my ($percent) = $token =~ /\A(.+)%\z/ ) {
			return _checked_range( 'alpha percentage', $percent, 0, 100 ) / 100 * 255;
		}
		if ( $token =~ /\./ ) {
			return _checked_range( 'alpha fraction', $token, 0, 1 ) * 255;
		}
		return $token;
	}

	sub _normalized_hsl ( $h, $s, $l ) {
		die "Term::Fabulous::Color: hue must be a number, got " . _describe($h)
			unless _is_finite_number($h);
		_checked_range( 'saturation', $s, 0, 100 );
		_checked_range( 'lightness',  $l, 0, 100 );
		return ( $h - 360 * floor( $h / 360 ), $s, $l );
	}

	# Unrounded HSL -> RGB. Hue in [0, 360), saturation and lightness in
	# 0..100; returns three channels in 0..255 as floats.
	sub _hsl_to_rgb_float ( $h, $s, $l ) {
		$s /= 100;
		$l /= 100;
		return ( $l * 255 ) x 3 if $s == 0;

		my $q = $l < 0.5 ? $l * ( 1 + $s ) : $l + $s - $l * $s;
		my $p = 2 * $l - $q;

		my @channels;
		foreach my $offset ( 1 / 3, 0, -1 / 3 ) {
			my $t = $h / 360 + $offset;
			$t += 1 if $t < 0;
			$t -= 1 if $t >= 1;

			my $value
				= $t < 1 / 6 ? $p + ( $q - $p ) * 6 * $t
				: $t < 1 / 2 ? $q
				: $t < 2 / 3 ? $p + ( $q - $p ) * 6 * ( 2 / 3 - $t )
				:              $p;
			push @channels, $value * 255;
		}
		return @channels;
	}

	# Unrounded RGB -> HSL. Channels in 0..255; returns hue in [0, 360) and
	# saturation / lightness in 0..100 as floats.
	sub _rgb_to_hsl_float ( $red, $green, $blue ) {
		( $red, $green, $blue ) = map { $_ / 255 } ( $red, $green, $blue );

		my $max       = max( $red, $green, $blue );
		my $min       = min( $red, $green, $blue );
		my $lightness = ( $max + $min ) / 2;
		return ( 0, 0, $lightness * 100 ) if $max == $min;

		my $delta      = $max - $min;
		my $saturation = $lightness < 0.5 ? $delta / ( $max + $min ) : $delta / ( 2 - $max - $min );
		my $hue
			= $max == $red   ? 60 * ( ( $green - $blue ) / $delta )
			: $max == $green ? 60 * ( 2 + ( $blue - $red ) / $delta )
			:                  60 * ( 4 + ( $red - $green ) / $delta );
		$hue += 360 if $hue < 0;

		return ( $hue, $saturation * 100, $lightness * 100 );
	}

	method blend ( $other, $ratio ) {
		die "Term::Fabulous::Color: blend needs a Term::Fabulous::Color to blend with, got " . _describe($other)
			unless blessed $other && $other->isa('Term::Fabulous::Color');
		_checked_range( 'blend ratio', $ratio, 0, 1 );
		my $inv_ratio = 1 - $ratio;

		return Term::Fabulous::Color->new(
			color => [
				$red * $inv_ratio + $other->red * $ratio,
				$green * $inv_ratio + $other->green * $ratio,
				$blue * $inv_ratio + $other->blue * $ratio,
				$alpha * $inv_ratio + $other->alpha * $ratio,
			],
		);
	}

	method with_alpha ($new_alpha) {
		return Term::Fabulous::Color->new( color => [ $red, $green, $blue, $new_alpha ], );
	}

	method is_translucent () {
		return $alpha > 0 && $alpha < 255;
	}

	method lighten ($amount) {
		die "Term::Fabulous::Color: lighten amount must be a number, got " . _describe($amount)
			unless _is_finite_number($amount);

		my ( $h, $s, $l ) = _rgb_to_hsl_float( $red, $green, $blue );
		my $lightness = min( 100, max( 0, $l + $amount * 100 ) );
		return Term::Fabulous::Color->new( color => [ _hsl_to_rgb_float( $h, $s, $lightness ), $alpha ] );
	}

	method darken ($amount) {
		die "Term::Fabulous::Color: darken amount must be a number, got " . _describe($amount)
			unless _is_finite_number($amount);

		return $self->lighten( -$amount );
	}

	method ansi () {
		return sprintf( "\e[38;2;%d;%d;%dm", $red, $green, $blue );
	}

	method ansi_bg () {
		return sprintf( "\e[48;2;%d;%d;%dm", $red, $green, $blue );
	}

	method hexString () {
		return sprintf( "#%02x%02x%02x%02x", $red, $green, $blue, $alpha );
	}

	method to_rgba () {
		return ( $red, $green, $blue, $alpha );
	}

	method to_hsl () {
		return Term::Fabulous::Color->rgb_to_hsl( $red, $green, $blue );
	}

	method rgba_int () {
		return $_rgba_int_cache //= ( $red << 24 ) | ( $green << 16 ) | ( $blue << 8 ) | $alpha;
	}

	# Alpha-0 emits the terminal default-fg reset (\e[39m) instead of literal black.
	method fg_sgr () {
		return $_fg_sgr_cache
			//= $alpha == 0
			? "\e[39m"
			: sprintf( "\e[38;2;%d;%d;%dm", $red, $green, $blue );
	}

	# Alpha-0 emits the terminal default-bg reset (\e[49m); see fg_sgr.
	method bg_sgr () {
		return $_bg_sgr_cache
			//= $alpha == 0
			? "\e[49m"
			: sprintf( "\e[48;2;%d;%d;%dm", $red, $green, $blue );
	}

	method rgb_int () {
		return $_rgb_int_cache //= ( $red << 16 ) | ( $green << 8 ) | $blue;
	}

	method rgba_float () {
		return ( $red / 255, $green / 255, $blue / 255, $alpha / 255 );
	}

	method rgb_float () {
		return ( $red / 255, $green / 255, $blue / 255 );
	}

	method hsl_to_rgb :common ( $h, $s, $l ) {
		return map { _round($_) } _hsl_to_rgb_float( _normalized_hsl( $h, $s, $l ) );
	}

	method rgb_to_hsl :common ( $r, $g, $b ) {
		_checked_range( 'red',   $r, 0, 255 );
		_checked_range( 'green', $g, 0, 255 );
		_checked_range( 'blue',  $b, 0, 255 );

		my ( $h, $s, $l ) = map { _round($_) } _rgb_to_hsl_float( $r, $g, $b );
		return ( $h % 360, $s, $l );
	}

	method rgb :common ( $r, $g, $b ) {
		return Term::Fabulous::Color->new( color => [ $r, $g, $b ] );
	}

	method rgba :common ( $r, $g, $b, $a ) {
		return Term::Fabulous::Color->new( color => [ $r, $g, $b, _alpha_from_token($a) ] );
	}

	method hex :common ( $spec ) {
		die "Term::Fabulous::Color: hex expects '#rrggbb' or '#rrggbbaa', got " . _describe($spec)
			unless defined $spec && !ref $spec && $spec =~ $HEX_SPEC;
		return Term::Fabulous::Color->new( color => $spec );
	}

	method hsl :common ( $h, $s, $l ) {
		return Term::Fabulous::Color->new( color => [ _hsl_to_rgb_float( _normalized_hsl( $h, $s, $l ) ), 255 ] );
	}

	method hsla :common ( $h, $s, $l, $a ) {
		return Term::Fabulous::Color->new( color => [ _hsl_to_rgb_float( _normalized_hsl( $h, $s, $l ) ), _alpha_from_token($a) ] );
	}

}

1;

__END__

=head1 NAME

Term::Fabulous::Color - An immutable RGBA color, parsed from many notations

=head1 SYNOPSIS

	use Term::Fabulous::Color;
	use Term::Fabulous::Widget::Box;

	# One constructor that understands every notation ...
	my $purple = Term::Fabulous::Color->new( color => '#7c3aed' );
	my $faded  = Term::Fabulous::Color->new( color => 'rgba(255, 0, 128, 0.5)' );
	my $teal   = Term::Fabulous::Color->new( color => 'hsl(174, 72%, 56%)' );
	my $blue   = Term::Fabulous::Color->new( color => [ 40, 80, 200 ] );
	my $gray   = Term::Fabulous::Color->new( color => { r => 128, g => 128, b => 128, a => 255 } );

	# ... and shortcuts for the common cases.
	my $red    = Term::Fabulous::Color->rgb( 255, 0, 0 );
	my $glass  = Term::Fabulous::Color->rgba( 255, 0, 0, 128 );
	my $violet = Term::Fabulous::Color->hex('#7c3aed');
	my $mint   = Term::Fabulous::Color->hsl( 150, 60, 70 );

	# Derive new colors; the original never changes.
	my $hover  = $purple->lighten(0.1);
	my $shadow = $purple->darken(0.2);
	my $mix    = $red->blend( $blue, 0.25 );

	# Widgets take the object itself, or any of the formats new() accepts.
	my $box = Term::Fabulous::Widget::Box->new( background_color => $shadow );

=head1 DESCRIPTION

A color with red, green, blue and alpha (opacity) channels, each an
integer from 0 to 255. Color objects are immutable: methods such as
L</lighten> and L</blend> return a new object.

Term::Fabulous uses this class to parse every color given as a string:
colors in L<KDL layout files|Term::Fabulous::Layout>, the colors of the
input widgets and the cell colors of a
L<canvas|Term::Fabulous::Widget::Canvas>, and every widget color
(C<background_color>, C<border_color>, the C<text_color> of a Text
widget, the input widget colors) takes a Color object or any input
L</new> accepts. See L<Term::Fabulous::Manual::Looks/COLORS>.

F<examples/colors.pl> shows one color written in six formats, colors
derived with L</darken>, L</lighten> and L</blend>, and backgrounds with
less and less alpha:

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.02/screenshots/example-colors.svg" alt="Six orange swatches written in different formats; a blue darkened, lightened and blended with white in steps; red swatches with alpha 255, 192, 128, 64 and 0 over a light panel; a line in the terminal's default text color"></p>

=end html

=head2 Alpha

An alpha of 0 means "no color": a background with alpha 0 is not
painted, so whatever is below it shows through, and a text or foreground
color with alpha 0 uses the terminal default color. An alpha from 1 to 254
(see L</is_translucent>) makes a widget background translucent: it is
blended with the colors below it when it is painted. Text and border
colors with such an alpha are drawn opaque. See
L<Term::Fabulous::Manual::Looks/Alpha and the terminal default color>.

=head2 Channel rules

Every channel is rounded to the nearest integer once, when the color is
built (an exact half rounds up), and the rounded value must be from 0 to
255. So C<255.4> becomes 255, C<0.5> becomes 1 and C<-0.4> becomes 0,
while C<255.5> and C<-1> die. Undefined values, non-numbers, NaN and
infinities die too. The error names the channel and the value:

=for highlighter language=text

	Term::Fabulous::Color: red must be a number in 0..255, got '300'

=head1 CONSTRUCTOR

=head2 new

=for highlighter language=perl

	my $color = Term::Fabulous::Color->new( color => $spec );

Builds a color from C<$spec>. C<color> is the only parameter and it is
required; unknown parameters die. C<$spec> can be any of the following.

=over

=item A Term::Fabulous::Color object

Its four channels are copied. Objects of subclasses work as well.

=item An array reference

C<[ $r, $g, $b ]> or C<[ $r, $g, $b, $a ]>. Alpha defaults to 255. Any
other number of elements dies.

=item A hash reference

With exactly the keys C<r>, C<g>, C<b> (and optionally C<a>), or exactly
C<red>, C<green>, C<blue> (and optionally C<alpha>). Alpha defaults to
255. Any other set of keys dies.

=item A string

In one of the notations below. The string must not have leading or
trailing whitespace; whitespace after C<(> and around the commas is
allowed. The function names are lowercase. Three-digit hex such as
C<'#f00'> is not supported.

=for highlighter language=text

	String              Example                     Meaning
	------------------  --------------------------  ---------------------------------
	#rrggbb             '#7c3aed', '7c3aed'         hex, alpha 255; '#' is optional
	#rrggbbaa           '#7c3aed80'                 hex with alpha
	packed integer      0xFF8800, '16746496'        0xRRGGBB as one number, alpha 255
	rgb(r, g, b)        'rgb(124, 58, 237)'         channels 0..255, alpha 255
	rgba(r, g, b, a)    'rgba(124, 58, 237, 0.5)'   alpha as described below
	hsl(h, s%, l%)      'hsl(262, 83%, 58%)'        hue in degrees, alpha 255
	hsla(h, s%, l%, a)  'hsla(262, 83%, 58%, 50%)'  alpha as described below
	web color name      'SteelBlue', 'steelblue'    a CSS named color, alpha 255

Hex digits may be upper or lower case. A string of digits only is a
packed C<0xRRGGBB> integer (the form the canvas drawing methods take as
well), so a hex color that consists of digits only, such as
C<'123456'>, needs its C<#>. A packed integer above C<0xFFFFFF> dies.
Channel values in C<rgb()> and C<rgba()> may have decimals; they are
rounded (see L</Channel rules>).

In C<hsl()> and C<hsla()>, the hue is in degrees and taken modulo 360,
so C<360> is the same as C<0> and C<-90> the same as C<270>. Saturation
and lightness are percentages from 0 to 100 and must be written with a
C<%> sign.

The alpha of C<rgba()> and C<hsla()> is read according to how it is
written, in the strings and in the L</rgba> and L</hsla> class methods
alike:

	Written as             Example   Meaning               Alpha
	---------------------  --------  --------------------  -----
	integer, no point      128       channel value 0..255  128
	number with a point    0.5       fraction 0..1         128
	number with %          50%       percentage 0..100     128

Watch the difference between C<1> and C<1.0>: C<'rgba(0, 0, 0, 1)'> has
alpha 1 (almost fully transparent),
while C<'rgba(0, 0, 0, 1.0)'> has alpha 255. In Perl code, a number
without a fractional part is written without a point when it becomes a
string, so C<< ->rgba( 0, 0, 0, 1.0 ) >> is alpha 1 as well; pass
C<'100%'> or C<255> for opaque.

A web color name is one of the 148 CSS named colors of
L<Term::Fabulous::Enum::WebColor> (C<Gray> and C<Grey> spellings,
C<RebeccaPurple>), in any case: C<'SteelBlue'>, C<'steelblue'> and
C<'STEELBLUE'> are the same color. Where a name could also mean
something else, the other meaning is looked up first: a palette token of
a L<theme|Term::Fabulous::Theme> (C<accent>, C<text>, ...; none of them
is a web color name) and the words of a
L<style string|Term::Fabulous::Text::Style> (C<bold>, C<default>, ...).

This grammar is the one of every color in Term::Fabulous: widget color
parameters and accessors, canvas cells, KDL layout files, theme files
and rich text markup.

=back

Anything else (C<undef>, other references or objects, unknown strings)
dies with the offending value in the message.

=head2 rgb

=for highlighter language=perl

	my $color = Term::Fabulous::Color->rgb( $r, $g, $b );

Class method. An opaque color (alpha 255) from three channels from 0 to
255 (see L</Channel rules>).

=head2 rgba

	my $color = Term::Fabulous::Color->rgba( $r, $g, $b, $a );

Class method. Like L</rgb> with an explicit alpha, read with the alpha
grammar of the C<rgba()> string (see L</new>): a bare integer is the
channel value from 0 to 255, a number with a decimal point a fraction
of 1, and a string ending in C<%> a percentage.

=head2 hex

	my $color = Term::Fabulous::Color->hex('#7c3aed');
	my $color = Term::Fabulous::Color->hex('7c3aed80');

Class method. A color from a six- or eight-digit hex string with an
optional leading C<#>. Any other string dies, even one that L</new>
would accept.

=head2 hsl

	my $color = Term::Fabulous::Color->hsl( $hue, $saturation, $lightness );

Class method. An opaque color from a hue in degrees (taken modulo 360)
and saturation and lightness as plain numbers from 0 to 100 (no C<%>
sign). The conversion is computed in floating point, and each channel
is rounded once at the end.

=head2 hsla

	my $color = Term::Fabulous::Color->hsla( $hue, $saturation, $lightness, $alpha );

Class method. Like L</hsl>, plus an alpha read with the same grammar
as in L</rgba> and in the C<hsla()> string: C<< ->hsla( 0, 0, 0, 0.5 ) >>
and C<< ->hsla( 0, 0, 0, '50%' ) >> give alpha 128, while
C<< ->hsla( 0, 0, 0, 1 ) >> gives alpha 1, not opaque.

=head1 METHODS

=head2 red

	my $r = $color->red;

The red channel, an integer from 0 to 255.

=head2 green

	my $g = $color->green;

The green channel, an integer from 0 to 255.

=head2 blue

	my $b = $color->blue;

The blue channel, an integer from 0 to 255.

=head2 alpha

	my $a = $color->alpha;

The alpha channel, an integer from 0 (transparent) to 255 (opaque).

=head2 is_translucent

	if ( $color->is_translucent ) { ... }

True when the alpha is from 1 to 254: the color is neither "no color"
(alpha 0) nor opaque (alpha 255). A translucent background is blended
with what is below it; see L</Alpha>.

=head2 to_rgba

	my ( $r, $g, $b, $a ) = $color->to_rgba;

Returns the four channels as a list. Widgets take the Color object
itself; wrap the result in C<[ ]> where a plain C<[r, g, b, a]> array
is wanted.

=head2 to_hsl

	my ( $hue, $saturation, $lightness ) = $color->to_hsl;

Returns hue (0 to 359), saturation and lightness (0 to 100) of the
color, each rounded to an integer. Alpha is ignored.

=head2 lighten

	my $brighter = $color->lighten(0.15);

Returns a color with more lightness in HSL terms. C<$amount> is a
fraction added to the lightness: C<0.15> adds 15 percentage points. The
result is clamped to 0% to 100% lightness, so C<lighten(1)> is white.
Hue, saturation and alpha stay the same, and C<lighten(0)> returns an
identical color. A negative amount darkens. Dies if C<$amount> is not a
number.

=head2 darken

	my $shadow = $color->darken(0.15);

The same as C<< $color->lighten(-$amount) >>.

=head2 blend

	my $mix = $color->blend( $other, $ratio );

Returns a mix of this color and C<$other>, channel by channel, alpha
included: C<$ratio> 0 gives this color, 1 gives C<$other>, 0.5 the
middle. Channels of the result are rounded like every other channel
(see L</Channel rules>): black blended with white at 0.5 is
C<(128, 128, 128)>. C<$other> must be a Term::Fabulous::Color object
and C<$ratio> a number from 0 to 1; anything else dies with a message
that names the offending argument.

=head2 with_alpha

	my $translucent = $color->with_alpha(128);

Returns a copy with a different alpha channel (0 to 255, rounded as
described in L</Channel rules>).

=head2 rgb_int

	my $packed = $color->rgb_int;    # 0xRRGGBB

The red, green and blue channels packed into one integer, C<0xRRGGBB>.
This is also the fast way to give a color to the canvas drawing methods
(see L<Term::Fabulous::Widget::Canvas/Colors>), but note that a packed
integer has no alpha channel.

=head2 rgba_int

	my $packed = $color->rgba_int;   # 0xRRGGBBAA

All four channels packed into one integer, C<0xRRGGBBAA>.

=head2 rgb_float

	my ( $r, $g, $b ) = $color->rgb_float;

The red, green and blue channels scaled to the range 0 to 1.

=head2 rgba_float

	my ( $r, $g, $b, $a ) = $color->rgba_float;

All four channels scaled to the range 0 to 1.

=head2 hexString

	my $hex = $color->hexString;     # '#7c3aedff'

The color as a lowercase C<#rrggbbaa> string. Alpha is always included.

=head2 ansi

	print $color->ansi, 'colored text', "\e[0m";

The 24-bit ANSI escape sequence that sets this color as the foreground
color (C<ESC [ 38 ; 2 ; r ; g ; b m>). Alpha is ignored.

=head2 ansi_bg

	print $color->ansi_bg, ' ', "\e[0m";

The 24-bit ANSI escape sequence that sets this color as the background
color (C<ESC [ 48 ; 2 ; r ; g ; b m>). Alpha is ignored.

=head2 fg_sgr

	print $color->fg_sgr;

Like L</ansi>, except that a color with alpha 0 returns C<ESC [ 39 m>,
which switches back to the terminal's default foreground color.

=head2 bg_sgr

	print $color->bg_sgr;

Like L</ansi_bg>, except that a color with alpha 0 returns
C<ESC [ 49 m>, which switches back to the terminal's default background
color.

=head2 hsl_to_rgb

	my ( $r, $g, $b ) = Term::Fabulous::Color->hsl_to_rgb( $hue, $saturation, $lightness );

Class method. Converts hue (degrees, taken modulo 360), saturation and
lightness (0 to 100) to red, green and blue (0 to 255), computed in
floating point and rounded once. Dies if saturation or lightness are
outside 0..100.

=head2 rgb_to_hsl

	my ( $hue, $saturation, $lightness ) = Term::Fabulous::Color->rgb_to_hsl( $r, $g, $b );

Class method. Converts red, green and blue (numbers from 0 to 255) to
hue (0 to 359) and saturation and lightness (0 to 100), each rounded to
an integer. Dies if a channel is outside 0..255.

=head1 SEE ALSO

L<Term::Fabulous::Manual::Looks/COLORS>, L<Term::Fabulous::Render::Attr>,
L<Term::Fabulous::Widget::Canvas/Colors>, L<Term::Fabulous::Enum::WebColor>,
L<Term::Fabulous::Theme>,
L<Term::Fabulous::Cookbook::Layout/Switch themes at run time (built-in themes and a theme file)>.

=cut
