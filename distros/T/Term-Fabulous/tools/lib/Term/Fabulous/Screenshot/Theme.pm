package Term::Fabulous::Screenshot::Theme;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

class Term::Fabulous::Screenshot::Theme :strict(params) {
	use Carp qw(croak);

	# The terminal: cell size and font, in image units (pixels at scale 1).
	field $cell_width     :param :reader = 9;
	field $cell_height    :param :reader = 18;
	field $font_size      :param :reader = 15;
	field $baseline       :param :reader = 14;    # from the top of a cell
	field $line_thickness :param :reader = 1;    # of light box drawing lines

	# The colors the terminal shows where a program sets none.
	field $default_foreground :param :reader = 0xD4D8E0;
	field $default_background :param :reader = 0x161622;

	# The window around the terminal.
	field $margin           :param :reader = 16;    # room for the shadow
	field $corner_radius    :param :reader = 10;
	field $title_bar_height :param :reader = 34;
	field $padding_x        :param :reader = 14;
	field $padding_top      :param :reader = 10;
	field $padding_bottom   :param :reader = 14;
	field $title_bar_color  :param :reader = 0x1F2430;
	field $title_color      :param :reader = 0x9AA3B5;
	field $title_font_size  :param :reader = 13;
	field $outline_color    :param :reader = 0xFFFFFF;
	field $outline_opacity  :param :reader = 0.08;
	field $shadow_opacity   :param :reader = 0.3;
	field $shadow_blur      :param :reader = 5;
	field $shadow_offset    :param :reader = 3;
	field $button_colors    :param :reader = [ 0xFF5F57, 0xFEBC2E, 0x28C840 ];    # close, minimize, zoom
	field $button_radius    :param :reader = 6;
	field $button_spacing   :param :reader = 20;

	# Fonts tried in order by SVG viewers; any monospace font works, since
	# the renderer places every cell itself.
	field $font_family :param :reader = q{'JetBrains Mono', 'Cascadia Mono', 'SF Mono', Menlo, Consolas, 'DejaVu Sans Mono', 'Liberation Mono', monospace};

	ADJUST {
		foreach my $size ( $cell_width, $cell_height, $line_thickness ) {
			croak "Term::Fabulous::Screenshot::Theme: cell sizes and the line thickness must be positive whole numbers, got '$size'"
				unless $size =~ /\A[1-9][0-9]*\z/;
		}
	}

	# Where the parts of the window go, for a terminal of the given size.
	method layout ( $columns, $rows ) {
		my $window_width  = $columns * $cell_width + 2 * $padding_x;
		my $window_height = $title_bar_height + $padding_top + $rows * $cell_height + $padding_bottom;
		return {
			image_width   => $window_width + 2 * $margin,
			image_height  => $window_height + 2 * $margin + $shadow_offset,
			window_x      => $margin,
			window_y      => $margin,
			window_width  => $window_width,
			window_height => $window_height,
			terminal_x    => $margin + $padding_x,
			terminal_y    => $margin + $title_bar_height + $padding_top,
		};
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Screenshot::Theme - The look of the screenshot windows

=head1 SYNOPSIS

	use Term::Fabulous::Screenshot::Theme;

	my $theme  = Term::Fabulous::Screenshot::Theme->new;
	my $layout = $theme->layout( 80, 24 );    # image size, window and terminal position

=head1 DESCRIPTION

Maintainer tool, not installed. Every screenshot shows the terminal in a
dark window with a title bar and the three window buttons, on a
transparent background with a soft shadow. This class holds the sizes
and colors of that window and of the terminal cells, in image units: SVG
user units, or pixels of a PNG at scale 1.

Every parameter of C<new> has a default and a reader of the same name.
Colors are C<0xRRGGBB> numbers.

=head1 PARAMETERS

=over

=item C<cell_width>, C<cell_height>, C<line_thickness>

The size of a terminal cell and the thickness of light box drawing
lines, positive whole numbers. Default: 9, 18 and 1.

=item C<font_size>, C<baseline>

The size of the text and the distance of its baseline from the top of
the cell. Default: 15 and 14.

=item C<font_family>

The CSS font list of SVG text.

=item C<default_foreground>, C<default_background>

The colors of cells that use the terminal's default colors.

=item C<margin>, C<corner_radius>, C<title_bar_height>, C<padding_x>, C<padding_top>, C<padding_bottom>

The space around the window, the rounding of its corners, the height of
the title bar and the space between the window's edge and the terminal
cells.

=item C<title_bar_color>, C<title_color>, C<title_font_size>, C<outline_color>, C<outline_opacity>, C<shadow_opacity>, C<shadow_blur>, C<shadow_offset>, C<button_colors>, C<button_radius>, C<button_spacing>

The details of the window frame.

=back

=head1 METHODS

=head2 layout

	my $layout = $theme->layout( $columns, $rows );

A hash with C<image_width>, C<image_height>, C<window_x>, C<window_y>,
C<window_width>, C<window_height>, C<terminal_x> and C<terminal_y>: the
positions of the window and of the top-left terminal cell in the image.

=cut
