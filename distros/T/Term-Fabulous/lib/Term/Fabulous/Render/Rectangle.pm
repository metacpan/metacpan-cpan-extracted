package Term::Fabulous::Render::Rectangle;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.05';

use Object::Pad 0.825;

role Term::Fabulous::Render::Rectangle {
	use Term::Fabulous::Termbox qw(TB_DEFAULT TB_REVERSE);
	use Term::Fabulous::Render::Attr qw(color_attr clay_color blended_bg_attr blended_fg_attr);
	use Term::Fabulous::Render::Geometry qw(visible_cell_rect);
	use Term::Fabulous::Unicode qw(cluster_columns);

	# The cells the command being painted may touch (Term::Fabulous::Render).
	method clip_rect;

	# The cell target the frame is painted into (Term::Fabulous::Render).
	method cell_target;

	# Paints the visible (clipped) part of the box in the background color
	# and records the resulting background of every cell in the shadow
	# buffer. An opaque color fills the rows; a translucent one is blended
	# with what the shadow buffer holds below it, and either covers the
	# glyphs there or leaves them showing through, as the widget asks.
	method render_rectangle ( $command, $widget, $buffer ) {
		my ( $x0, $y0, $x1, $y1 ) = visible_cell_rect( $command->{boundingBox}, $self->clip_rect );
		return unless defined $x0;

		my $color     = clay_color( $command->{renderData}{backgroundColor} );
		my $style     = _reverse_video($widget) ? TB_REVERSE : 0;
		my $paint_row = !$color->is_translucent ? \&_paint_opaque_row : _glyphs_show_through($widget) ? \&_paint_tinted_row : \&_paint_covered_row;
		my $target    = $self->cell_target;
		foreach my $y ( $y0 .. $y1 - 1 ) {
			$paint_row->( $target, $color, $style, $buffer->[$y] //= [], $x0, $x1, $y );
		}
		return;
	}

	sub _glyphs_show_through ($widget) {
		return defined $widget && $widget->isa('Term::Fabulous::Widget') && $widget->glyphs_show_through;
	}

	# A widget drawn in reverse video puts TB_REVERSE into the background of
	# its cells; the text and borders painted on top inherit it, so the
	# whole widget swaps its colors.
	sub _reverse_video ($widget) {
		return defined $widget && $widget->isa('Term::Fabulous::Widget') && $widget->reverse_video;
	}

	sub _paint_opaque_row ( $target, $color, $style, $row, $x0, $x1, $y ) {
		my $bg_attr = color_attr($color) | $style;
		my $columns = $x1 - $x0;
		@{$row}[ $x0 .. $x1 - 1 ] = ($bg_attr) x $columns;
		$target->fill_row( $x0, $y, $columns, $bg_attr );
		return;
	}

	# Covers the cells with spaces in the blended color, one fill per run
	# of equal color.
	sub _paint_covered_row ( $target, $color, $style, $row, $x0, $x1, $y ) {
		my @blended = map { blended_bg_attr( $color, $row->[$_] // TB_DEFAULT ) | $style } $x0 .. $x1 - 1;
		@{$row}[ $x0 .. $x1 - 1 ] = @blended;

		my $run_start = 0;
		foreach my $index ( 1 .. $#blended + 1 ) {
			next if $index <= $#blended && $blended[$index] == $blended[$run_start];
			$target->fill_row( $x0 + $run_start, $y, $index - $run_start, $blended[$run_start] );
			$run_start = $index;
		}
		return;
	}

	# Repaints every cell with the glyph the target holds there, its
	# foreground tinted; a cell without a glyph becomes a space. The cells
	# a wide glyph covers are skipped, like the target does for them.
	sub _paint_tinted_row ( $target, $color, $style, $row, $x0, $x1, $y ) {
		my $covered_until = $x0;
		foreach my $x ( $x0 .. $x1 - 1 ) {
			my $bg_attr = $row->[$x] = blended_bg_attr( $color, $row->[$x] // TB_DEFAULT ) | $style;
			next if $x < $covered_until;

			my ( $glyph, $fg_attr ) = $target->painted_cell( $x, $y );
			if ( !defined $glyph || $glyph eq ' ' ) {
				$target->set_cell( $x, $y, ' ', TB_DEFAULT, $bg_attr );
				next;
			}
			my ( $base, @extenders ) = split //, $glyph;
			$target->set_cell( $x, $y, $base, blended_fg_attr( $color, $fg_attr ), $bg_attr );
			$target->extend_cell( $x, $y, $_ ) foreach @extenders;
			$covered_until = $x + cluster_columns($glyph);
		}
		return;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Render::Rectangle - Paint widget backgrounds

=head1 SYNOPSIS

	# Composed by Term::Fabulous::Render; called from draw for every
	# rectangle render command:
	$ui->render_rectangle( $command, $widget, $buffer );

=head1 DESCRIPTION

Most programs never use this module directly, and neither do widgets
of your own. It is one of the roles L<Term::Fabulous::Render> is made
of, and it paints the rectangle render commands Clay emits for widget
backgrounds (C<background_color>). Read it if you write your own UI
class or want to know exactly how backgrounds are painted and blended.

=head1 METHODS

=head2 render_rectangle

	$ui->render_rectangle( $command, $widget, $buffer );

Paints the cells of the command's bounding box that lie inside the
command's clip rect (see L<Term::Fabulous::Render/clip_rect>) in
the command's background color. It also records the resulting
background of every painted cell in C<$buffer>, an array reference of
rows of attributes indexed C<< $buffer->[$y][$x] >>, so that text and
borders drawn on top later in the frame know the background below them.

An opaque color (alpha 255) fills the cells with spaces, using the
target's C<fill_row>. A translucent color (alpha 1 to 254) is blended
with the background C<$buffer> holds for each cell
(L<Term::Fabulous::Render::Attr/blended_bg_attr>), and then one of two
things happens, depending on the widget's C<glyphs_show_through>
(L<Term::Fabulous::Widget/glyphs_show_through>):

=over

=item *

Off (the default, also when C<$widget> is not a
L<Term::Fabulous::Widget>): the cells are covered with spaces in the
blended colors, one C<fill_row> per run of equal color.

=item *

On: every cell is read back from the target (C<painted_cell>) and
repainted with the glyph found there, its foreground tinted with the
same color (L<Term::Fabulous::Render::Attr/blended_fg_attr>); a cell
holding nothing or a space becomes a space. The cells a wide glyph
covers are not touched.

=back

When C<$widget> is a L<Term::Fabulous::Widget> whose
C<reverse_video> method returns true (a pressed
L<Term::Fabulous::Widget::Button>, see
L<Term::Fabulous::Widget::Button/reverse_video>), every background attribute
gets the C<TB_REVERSE> flag. The text and borders painted on top later
take their background from C<$buffer>, flag included, so the whole
widget is shown with swapped colors.

Clay never emits a rectangle for a color with alpha 0.

C<$command> is a Clay render command hash (see
L<Clay::XS/RENDER COMMANDS>); C<$widget> is the widget it belongs to.

=head1 REQUIRED METHODS

The consuming class provides C<cell_target>, which returns the cell
target the background is painted into (its C<fill_row>, C<set_cell>,
C<extend_cell> and C<painted_cell> are called; see
L<Term::Fabulous::Render/CELL TARGET>), and C<clip_rect> (from
L<Term::Fabulous::Render>, see L<Term::Fabulous::Render/clip_rect>).

=head1 SEE ALSO

L<Term::Fabulous::Render>, L<Term::Fabulous::Render::Frame>.

=cut
