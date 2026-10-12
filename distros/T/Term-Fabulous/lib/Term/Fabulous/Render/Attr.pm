package Term::Fabulous::Render::Attr;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Exporter 'import';
our @EXPORT_OK = qw(color_attr clay_color cell_color_attr blended_bg_attr blended_fg_attr STYLE_FLAGS);

use Scalar::Util qw(blessed);
use Term::Fabulous::Termbox qw(
	TB_DEFAULT TB_HI_BLACK
	TB_BOLD TB_DIM TB_ITALIC TB_UNDERLINE TB_BLINK TB_REVERSE TB_INVISIBLE TB_STRIKEOUT TB_UNDERLINE_2 TB_OVERLINE
);

use Term::Fabulous::Color;

use constant CACHE_LIMIT => 4096;
use constant MAX_RGB     => 0xFFFFFF;

# The bits of an attribute that hold its color; the rest are style flags.
use constant COLOR_BITS => MAX_RGB | TB_HI_BLACK;

# Every style flag: [ flag, SGR parameter, name ], by SGR parameter. The
# one table of what a flag means on a terminal.
use constant STYLE_FLAGS => (
	[ TB_BOLD,        1,  'bold' ],
	[ TB_DIM,         2,  'dim' ],
	[ TB_ITALIC,      3,  'italic' ],
	[ TB_UNDERLINE,   4,  'underline' ],
	[ TB_BLINK,       5,  'blink' ],
	[ TB_REVERSE,     7,  'reverse' ],
	[ TB_INVISIBLE,   8,  'invisible' ],
	[ TB_STRIKEOUT,   9,  'strikeout' ],
	[ TB_UNDERLINE_2, 21, 'double_underline' ],
	[ TB_OVERLINE,    53, 'overline' ],
);

my %attr_by_rgba;
my %color_by_clay_rgba;
my %blended_attr_by_pair;

sub color_attr ($color) {
	my $rgba = $color->rgba_int;
	my $attr = $attr_by_rgba{$rgba};
	return $attr if defined $attr;

	%attr_by_rgba = () if keys(%attr_by_rgba) >= CACHE_LIMIT;
	return $attr_by_rgba{$rgba} = _termbox_attr($color);
}

sub clay_color ($clay_rgba) {
	die "Term::Fabulous::Render::Attr: a Clay color must be a hash reference with r, g, b, a"
		unless ref $clay_rgba eq 'HASH';

	my $key   = join ',', map { $_ // '' } @{$clay_rgba}{qw(r g b a)};
	my $color = $color_by_clay_rgba{$key};
	return $color if defined $color;

	%color_by_clay_rgba = () if keys(%color_by_clay_rgba) >= CACHE_LIMIT;
	return $color_by_clay_rgba{$key} = Term::Fabulous::Color->new( color => $clay_rgba );
}

# undef, and colors with alpha 0, leave a cell without a color of its own.
sub cell_color_attr ( $what, $color ) {
	return undef unless defined $color;
	if ( !ref $color && $color =~ /\A[0-9]+\z/ ) {
		die "Term::Fabulous::Render::Attr: $what must be a packed 0xRRGGBB value, got $color" if $color > MAX_RGB;
		return $color == 0 ? TB_HI_BLACK : $color + 0;
	}
	my $object = blessed $color && $color->isa('Term::Fabulous::Color') ? $color : Term::Fabulous::Color->new( color => $color );
	my $attr   = color_attr($object);
	return $attr == TB_DEFAULT ? undef : $attr;
}

# termbox2 in truecolor mode reads 0x000000 as "terminal default", so opaque
# black needs its dedicated flag; alpha 0 means "no color" and maps to the
# terminal default on purpose.
sub _termbox_attr ($color) {
	return TB_DEFAULT if $color->alpha == 0;

	my $rgb = $color->rgb_int;
	return $rgb == 0 ? TB_HI_BLACK : $rgb;
}

# A translucent background painted over the background attribute below it.
# The terminal default color has no RGB to blend with, so the color is
# drawn opaque there. Style flags of the attribute below are kept.
sub blended_bg_attr ( $color, $under ) {
	my $flags = $under & ~COLOR_BITS;
	my $rgb   = _attr_rgb($under);
	return $flags | color_attr($color) unless defined $rgb;
	return $flags | _blend_over_rgb( $color, $rgb );
}

# A translucent background painted over a glyph: its foreground attribute
# is tinted the same way, except that a terminal-default foreground, which
# cannot be blended, stays as it is.
sub blended_fg_attr ( $color, $under ) {
	my $rgb = _attr_rgb($under);
	return $under unless defined $rgb;
	return ( $under & ~COLOR_BITS ) | _blend_over_rgb( $color, $rgb );
}

# The 0xRRGGBB value of an attribute; undef for the terminal default.
sub _attr_rgb ($attr) {
	return 0 if $attr & TB_HI_BLACK;
	my $rgb = $attr & MAX_RGB;
	return $rgb == 0 ? undef : $rgb;
}

# The color attribute of $color composited over the opaque color $rgb.
sub _blend_over_rgb ( $color, $rgb ) {
	my $key  = $color->rgba_int . ",$rgb";
	my $attr = $blended_attr_by_pair{$key};
	return $attr if defined $attr;

	%blended_attr_by_pair = () if keys(%blended_attr_by_pair) >= CACHE_LIMIT;
	my @over  = $color->to_rgba;
	my $alpha = pop @over;
	my @under = ( ( $rgb >> 16 ) & 0xFF, ( $rgb >> 8 ) & 0xFF, $rgb & 0xFF );
	my $mixed = 0;
	foreach my $channel ( 0 .. 2 ) {
		$mixed = ( $mixed << 8 ) | int( ( $over[$channel] * $alpha + $under[$channel] * ( 255 - $alpha ) ) / 255 + 0.5 );
	}
	return $blended_attr_by_pair{$key} = $mixed == 0 ? TB_HI_BLACK : $mixed;
}

1;

__END__

=head1 NAME

Term::Fabulous::Render::Attr - Turn colors into termbox2 truecolor attributes

=head1 SYNOPSIS

	use Term::Fabulous::Render::Attr qw(color_attr clay_color cell_color_attr blended_bg_attr STYLE_FLAGS);
	use Term::Fabulous::Color;

	my $fg = color_attr( Term::Fabulous::Color->rgb( 0, 0, 0 ) );               # TB_HI_BLACK
	my $bg = color_attr( clay_color( { r => 20, g => 25, b => 35, a => 255 } ) );  # 0x141923
	my $cell_fg = cell_color_attr( fg => '#ffcc00' );                             # 0xFFCC00
	my $dimmed  = blended_bg_attr( Term::Fabulous::Color->rgba( 0, 0, 0, 128 ), 0xFFFFFF );  # 0x7F7F7F

	my %name_of_sgr = map { $_->[1] => $_->[2] } STYLE_FLAGS;                   # 1 => 'bold', ...

=head1 DESCRIPTION

Most programs never use this module directly. It is used by the render
roles and the canvas widgets. Read it if you write your own cell target
or UI class (see L<Term::Fabulous::Render>), or to understand the color
values returned by L<Term::Fabulous::Widget::Canvas/cell> and
L<Term::Fabulous::Widget::PixelCanvas/pixel>.

termbox2 describes the colors of a cell with an integer I<attribute>. In
truecolor mode, the one Term::Fabulous uses, an attribute holds a
24-bit color C<0xRRGGBB> in its low bits and flags such as reverse video
in its high bits. Two values are special:

=over

=item C<TB_DEFAULT> (0)

The terminal's default color. This is what a color with alpha 0 ("no
color") becomes.

=item C<TB_HI_BLACK>

Opaque black. termbox2 would read the color C<0x000000> as the default
color, so black needs this flag of its own.

=back

A color with an alpha from 1 to 254 is I<translucent>. Terminals cannot
blend colors themselves, so L</blended_bg_attr> and L</blended_fg_attr>
compute the mix of such a color with the attribute below it. The
terminal default color has no RGB value to mix with; see those functions
for what happens then.

Truecolor is always available: termbox2 is compiled into the
distribution with 64-bit attributes (see L<Term::Fabulous::Termbox>).

=head1 FUNCTIONS

Nothing is exported by default. Import the functions you need by name,
and L</STYLE_FLAGS> likewise.

=head2 color_attr

	my $attr = color_attr($color);

Takes a L<Term::Fabulous::Color> object and returns its attribute:
C<TB_DEFAULT> when its alpha is 0, C<TB_HI_BLACK> for black, and
the packed C<0xRRGGBB> value otherwise. Results are cached (the cache is
emptied when it reaches 4096 entries).

=head2 clay_color

	my $color = clay_color( $command->{renderData}{backgroundColor} );

Takes a color as it appears in Clay render commands, a hash reference
with the keys C<r>, C<g>, C<b> and C<a>, and returns the matching
L<Term::Fabulous::Color> object. Results are cached, so a frame does not
parse colors it has seen before (the cache is emptied when it reaches
4096 entries). Dies unless the argument is a hash reference; invalid
channels die in L<Term::Fabulous::Color>.

=head2 cell_color_attr

	my $attr = cell_color_attr( fg => $color );

Converts the color argument of the canvas drawing methods (see
L<Term::Fabulous::Widget::Canvas/Colors>) into an attribute:

=over

=item *

C<undef> returns C<undef> ("no color of its own").

=item *

A non-negative integer is taken as a packed C<0xRRGGBB> color as it is;
C<0> becomes C<TB_HI_BLACK>. Integers above C<0xFFFFFF> die.

=item *

A L<Term::Fabulous::Color> object, or anything
C<< Term::Fabulous::Color->new >> accepts (C<[r, g, b, a]>, C<'#rrggbb'>,
C<'hsl(...)'>, ...), goes through L</color_attr>. A color with alpha 0
returns C<undef>.

=back

The first argument names the color in error messages, for example
C<Term::Fabulous::Render::Attr: fg must be a packed 0xRRGGBB value, got 16777216>.
Invalid colors die in L<Term::Fabulous::Color>.

=head2 blended_bg_attr

	my $attr = blended_bg_attr( $color, $under );

The background attribute of a translucent L<Term::Fabulous::Color>
painted over the background attribute C<$under>: each channel of the
color is mixed with the channel below it by the color's alpha
(C<over * alpha + under * (255 - alpha)>, divided by 255 and rounded),
and black becomes C<TB_HI_BLACK>. When C<$under> is the terminal
default color, which cannot be blended, the result is the color drawn
opaque (L</color_attr>). Style flags in C<$under> are kept. An opaque
color returns itself, a color with alpha 0 returns C<$under>. Results
are cached like L</color_attr>.

=head2 blended_fg_attr

	my $attr = blended_fg_attr( $color, $under );

The same mix for the foreground attribute C<$under> of a glyph that a
translucent background is painted over, so that the glyph shows through
tinted. A terminal-default foreground cannot be blended and is returned
unchanged; style flags such as C<TB_REVERSE> are kept.

=head1 CONSTANTS

=head2 STYLE_FLAGS

	foreach my $style (STYLE_FLAGS) {
		my ( $flag, $sgr, $name ) = @$style;
		...
	}

Every style flag of an attribute, as a list of array references
C<[ $flag, $sgr, $name ]> in the order of their SGR parameters (they are
shared; do not change them): the termbox2 flag of L<Term::Fabulous::Termbox>, the SGR
parameter that switches it on in a terminal, and its name:

	TB_BOLD          1  bold
	TB_DIM           2  dim
	TB_ITALIC        3  italic
	TB_UNDERLINE     4  underline
	TB_BLINK         5  blink
	TB_REVERSE       7  reverse
	TB_INVISIBLE     8  invisible
	TB_STRIKEOUT     9  strikeout
	TB_UNDERLINE_2  21  double_underline
	TB_OVERLINE     53  overline

The parameters are the ones termbox2 writes for these flags.
L<Term::Fabulous::Render::Target::Grid/row_text> writes them, and the
screenshot tools read them back, from this one table.

=head1 SEE ALSO

L<Term::Fabulous::Color>, L<Term::Fabulous::Render>,
L<Term::Fabulous::Manual::Looks/COLORS>.

=cut
