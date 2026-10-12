package Term::Fabulous::Chart::Palette;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Exporter 'import';
our @EXPORT_OK = qw(
	palette_colors palette_names is_palette_name chart_color mix_rgb luminance is_light_rgb
	contrast_rgb ink_colors rgb_hex
);

use Carp qw(croak);
use Term::Fabulous::Check qw(cell_color one_of);

# The categorical palettes, each with steps for dark and for light
# backgrounds. "default" is the validated palette of the documentation:
# its order keeps neighboring series apart for readers with color vision
# deficiencies. The others are for looks.
my %PALETTES = (
	default => {
		dark  => [qw(3987e5 d95926 199e70 c98500 d55181 008300 9085e9 e66767)],
		light => [qw(2a78d6 eb6834 1baf7a eda100 e87ba4 008300 4a3aa7 e34948)],
	},
	classic => {
		dark  => [qw(61afef e06c75 98c379 e5c07b c678dd 56b6c2 d19a66 be5046)],
		light => [qw(4078f2 e45649 50a14f c18401 a626a4 0184bc 986801 ca1243)],
	},
	pastel => {
		dark  => [qw(a1c9f4 ffb482 8de5a1 ff9f9b d0bbff debb9b fab0e4 b9f2f0)],
		light => [qw(6c9bd2 e08b52 5cb871 dd6c66 a08ad8 b38b65 d27ab8 5fb8b4)],
	},
	vivid => {
		dark  => [qw(00a8ff ff5c8a 2ecc71 ffc300 b76cff 00d2c6 ff8a3d a3e635)],
		light => [qw(0077cc d6336c 1e9e57 c79100 8a3ffc 00897b e8590c 6a9e00)],
	},
);

# The ink of text on a dark and on a light background; everything else
# (labels, grid, axes) is mixed from it and the background.
my %INK = ( dark => 0xFFFFFF, light => 0x0B0B0B );

sub palette_names () {
	my @names = sort keys %PALETTES;
	return @names;
}

sub is_palette_name ($name) {
	return defined $name && !ref $name && exists $PALETTES{$name} ? 1 : 0;
}

# The colors of a named palette as packed 0xRRGGBB integers, in their order.
sub palette_colors ( $name, $mode ) {
	croak "Term::Fabulous::Chart::Palette: unknown palette '" . ( $name // 'undef' ) . "' (known: " . join( ', ', palette_names() ) . ")"
		unless is_palette_name($name);
	one_of( __PACKAGE__, mode => $mode, keys %INK );
	return map { hex } $PALETTES{$name}{$mode}->@*;
}

# A user's color as ( 0xRRGGBB, opacity from 0 to 1 ): every format a
# canvas cell takes. Dies like the other color checks.
sub chart_color ( $owner, $name, $value ) {
	my ( $red, $green, $blue, $alpha ) = cell_color( $owner, $name, $value )->@*;
	return ( ( $red << 16 ) | ( $green << 8 ) | $blue, $alpha / 255 );
}

# $from mixed with $amount (0 to 1) of $to.
sub mix_rgb ( $from, $to, $amount ) {
	return $from if $amount <= 0;
	return $to if $amount >= 1;
	my $mixed = 0;
	foreach my $shift ( 16, 8, 0 ) {
		my ( $start, $end ) = ( ( $from >> $shift ) & 0xFF, ( $to >> $shift ) & 0xFF );
		$mixed |= int( $start + ( $end - $start ) * $amount + 0.5 ) << $shift;
	}
	return $mixed;
}

# The relative luminance of WCAG 2: 0 for black, 1 for white.
sub luminance ($rgb) {
	my @linear = map {
		my $channel = ( ( $rgb >> $_ ) & 0xFF ) / 255;
		$channel <= 0.04045 ? $channel / 12.92 : ( ( $channel + 0.055 ) / 1.055 )**2.4
	} 16, 8, 0;
	return 0.2126 * $linear[0] + 0.7152 * $linear[1] + 0.0722 * $linear[2];
}

# Whether dark text reads better than light text on the color.
sub is_light_rgb ($rgb) {
	my $luminance = luminance($rgb);
	return ( 1.05 / ( $luminance + 0.05 ) ) < ( ( $luminance + 0.05 ) / 0.05 ) ? 1 : 0;
}

# Text that stays readable on the color: near black or near white.
sub contrast_rgb ($rgb) {
	return is_light_rgb($rgb) ? 0x111111 : 0xF5F5F5;
}

# The colors of a chart's text and lines on a background in a mode:
# title, text (legend), label (ticks, axis titles), axis and grid.
sub ink_colors ( $background, $mode ) {
	my $ink = $INK{ one_of( __PACKAGE__, mode => $mode, keys %INK ) };
	return {
		title => mix_rgb( $background, $ink, 0.95 ),
		text  => mix_rgb( $background, $ink, 0.80 ),
		label => mix_rgb( $background, $ink, 0.55 ),
		axis  => mix_rgb( $background, $ink, 0.30 ),
		grid  => mix_rgb( $background, $ink, 0.12 ),
	};
}

sub rgb_hex ($rgb) {
	return sprintf '#%06x', $rgb;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Chart::Palette - Color palettes and color arithmetic for
the chart widgets

=head1 SYNOPSIS

	use Term::Fabulous::Chart::Palette qw(palette_colors mix_rgb contrast_rgb chart_color);

	my @dark_steps = palette_colors( default => 'dark' );    # 0x3987e5, 0xd95926, ...
	my $faded      = mix_rgb( $dark_steps[0], 0x141923, 0.6 ); # 60 % of the way to the background
	my $on_slice   = contrast_rgb(0xeda100);                   # dark text on yellow
	my ( $rgb, $opacity ) = chart_color( $widget, color => '#3987e580' );

=head1 DESCRIPTION

The functions the chart widgets (L<Term::Fabulous::Widget::Chart> and its
subclasses) use to pick, check and mix colors. Colors are passed around as
packed C<0xRRGGBB> integers, the fastest form a canvas cell takes. All
functions are exported on request. To choose a palette for a chart, pass
its name (or an array of colors of your own) as the chart's C<palette>;
see L<Term::Fabulous::Widget::Chart/Colors and themes> and the recipe
L<Term::Fabulous::Cookbook::ChartStyles/Light backgrounds, palettes and colors of your own>.
You need the functions below only for charts or widgets of your own.

=head2 Palettes

A palette is an ordered list of eight colors. A chart gives its first
series (or its first slice) the first color, the second series the second,
and so on, and a series keeps its color when other series are removed. Each
palette has steps for dark and for light backgrounds; a chart chooses the
steps that suit its background (see L<Term::Fabulous::Widget::Chart/theme>).

=over

=item C<default>

Blue, orange, aqua, yellow, magenta, green, violet, red: the palette a
chart uses unless you choose another. The order keeps neighbors apart for
readers with the common color vision deficiencies. On a dark background
every color has at least 3:1 contrast to the background; on a light one,
aqua, yellow and magenta have less (about 2:1 to 2.7:1), so use them
there for fills and bars rather than for thin lines. Use this palette
unless you have a reason not to.

=item C<classic>

The colors of popular dark and light editor themes: softer blue, red, green,
yellow and purple. They match the colors of the Term::Fabulous examples.

=item C<pastel>

Light, soft colors; good for large fills such as pie slices and stacked
areas on a dark background.

=item C<vivid>

Saturated, bright colors for thin lines on a dark background.

=back

Only C<default> was checked for color vision deficiencies. With the other
palettes, and in general with more than four series, help readers with
labels: the legend, value labels, or different line styles and point
glyphs.

=head1 FUNCTIONS

=head2 palette_colors

	my @colors = palette_colors( $name, $mode );

The eight colors of a palette as packed integers. C<$mode> is C<dark> or
C<light>. Dies for an unknown name or mode.

=head2 palette_names

The names of all palettes, sorted: C<classic>, C<default>, C<pastel>,
C<vivid>.

=head2 is_palette_name

True for the name of a palette.

=head2 chart_color

	my ( $rgb, $opacity ) = chart_color( $owner, $name, $color );

Reads a color in any format a canvas cell takes (see
L<Term::Fabulous::Widget::Canvas/Colors>): a packed C<0xRRGGBB> integer, a
string such as C<'#ff8800'>, C<'#ff880080'>, C<'rgb(255, 136, 0)'> or
C<'hsl(32, 100%, 50%)'>, an array or hash reference, or a
L<Term::Fabulous::Color> (such as C<< Term::Fabulous::Enum::WebColor->Tomato >>).
Returns the color as a packed integer and its alpha as an opacity from 0 to
1. Dies with C<$owner> and C<$name> in the message for anything else.

=head2 mix_rgb

	my $mixed = mix_rgb( $from, $to, $amount );

The color C<$amount> (0 to 1) of the way from C<$from> to C<$to>, channel
by channel. This is how translucent fills are drawn: the fill color mixed
into what is below it.

=head2 luminance

The relative luminance of a color as WCAG 2 defines it, from 0 (black) to 1
(white).

=head2 is_light_rgb

True when dark text has more contrast on the color than light text.

=head2 contrast_rgb

Near black (C<0x111111>) for a light color, near white (C<0xF5F5F5>) for a
dark one: the color of text written on it.

=head2 ink_colors

	my $ink = ink_colors( $background, $mode );
	# { title => ..., text => ..., label => ..., axis => ..., grid => ... }

The colors of a chart's chrome on a background: the title, the legend text,
the tick labels and axis titles, the axis lines and the grid lines. They are
mixed from the background and the ink of the mode (white on dark, near black
on light), so grid lines are always one shade off the background and labels
are recessive, whatever background the chart has.

=head2 rgb_hex

The C<#rrggbb> string of a packed color.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Chart>, L<Term::Fabulous::Manual::Charts/CHARTS>,
L<Term::Fabulous::Color>.

=cut
