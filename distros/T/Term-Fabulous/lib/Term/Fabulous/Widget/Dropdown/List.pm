package Term::Fabulous::Widget::Dropdown::List;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Term::Fabulous::Widget::Display;

our $VERSION = '0.03';

class Term::Fabulous::Widget::Dropdown::List
	:isa(Term::Fabulous::Widget::Display)
	:strict(params)
{
	use Clay::UI::Enum::Result;
	use List::Util qw(max);
	use Scalar::Util qw(weaken);
	use Term::Fabulous::Termbox qw(TB_KEY_MOUSE_LEFT TB_KEY_MOUSE_RELEASE TB_KEY_MOUSE_WHEEL_UP TB_KEY_MOUSE_WHEEL_DOWN);
	use Term::Fabulous::Unicode qw(grapheme_clusters cluster_columns string_columns);
	use Term::Fabulous::Viewport qw(clamp_offset reveal_range scroll_thumb);
	use Term::Fabulous::Widget::Scrollbar;

	field $dropdown     :param :weak;
	field $visible_rows :param :reader;

	# The first option shown.
	field $top = 0;

	ADJUST {
		weaken( my $weak_self = $self );
		$self->on(
			Mouse => sub ($event) {
				return $weak_self->_handle_mouse($event) ? Clay::UI::Enum::Result->HANDLED : Clay::UI::Enum::Result->CONTINUE;
			}
		);
	}

	method top_option () {
		return $top;
	}

	# The list's background, border color and border style come from the
	# dropdown (its list colors, its accent and the theme's dropdown
	# family), read when the frame is drawn; the readers say so too.
	method background_color :override (@new) {
		return $self->SUPER::background_color(@new) if @new;
		return $self->SUPER::background_color // ( defined $dropdown ? $dropdown->list_background_color : undef );
	}

	method border_color :override (@new) {
		return $self->SUPER::border_color(@new) if @new;
		return $self->SUPER::border_color if $self->has_look_override('border_color') || !defined $dropdown;
		return $dropdown->accent_color;
	}

	method contribute_look_theme :override ($config) {
		return unless defined $dropdown;
		$config->{background_color} = $self->background_color;
		my $border = $config->{border} // return;
		$config->{border} = { %$border, color => $self->border_color };
		return;
	}

	# A side without a style of its own is drawn in the dropdown's
	# list.border.style (Term::Fabulous::Role::HasBorderStyle).
	method derived_border_style ($side) {
		return defined $dropdown ? $dropdown->look('list.border.style') : undef;
	}

	method _scrolls () {
		return $dropdown->option_count > $visible_rows;
	}

	# Scrolls the highlighted option into view.
	method show_highlight () {
		my $highlighted = $dropdown->highlighted_index // 0;
		$top = reveal_range( $dropdown->option_count, $visible_rows, $top, $highlighted, $highlighted + 1 );
		return $self->mark_changed;
	}

	method scroll ($rows) {
		$top = clamp_offset( $dropdown->option_count, $visible_rows, $top + $rows );
		return $self->mark_changed;
	}

	# The option shown at a buffer row, or undef.
	method option_at_row ($row) {
		my $index = $top + $row;
		return $row >= 0 && $index < $dropdown->option_count ? $index : undef;
	}

	method _handle_mouse ($event) {
		my $key = $event->key;
		if ( $key == TB_KEY_MOUSE_WHEEL_UP || $key == TB_KEY_MOUSE_WHEEL_DOWN ) {
			my $before = $top;
			$self->scroll( $key == TB_KEY_MOUSE_WHEEL_UP ? -1 : 1 );
			return 0 if $top == $before;    # every option shown, or at an end
			$event->use_wheel;
			return 1;
		}
		return 0 unless $key == TB_KEY_MOUSE_LEFT || $key == TB_KEY_MOUSE_RELEASE;

		my ( $column, $row ) = $self->cell_at($event);
		my $index = defined $row && $column < $self->_text_columns ? $self->option_at_row($row) : undef;
		return 1 unless defined $index;
		if ( $key == TB_KEY_MOUSE_LEFT ) {
			$dropdown->highlight($index);
			return 1;
		}
		$dropdown->choose($index);
		return 1;
	}

	method _text_columns () {
		return $self->columns - ( $self->_scrolls ? 1 : 0 );
	}

	# The widest label with its margins, and a column for the scrollbar
	# (Term::Fabulous::Widget::Display); the dropdown gives the list its
	# size when it opens it.
	method natural_size () {
		return ( 0, $visible_rows ) unless defined $dropdown;
		my $widest = max( 0, map { string_columns( $dropdown->option_label($_) ) } 0 .. $dropdown->option_count - 1 );
		return ( $widest + 2 + ( $self->_scrolls ? 1 : 0 ), $visible_rows );
	}

	# What the shown rows paint: [ label, fg, bg ] each.
	method _shown_rows () {
		return map { [ $dropdown->option_label($_), $dropdown->option_attrs($_) ] } grep { defined } map { $self->option_at_row($_) } 0 .. $self->rows - 1;
	}

	# The options and colors the list shows come from the dropdown, which
	# does not mark the list changed.
	method paint_key :override () {
		return $self->SUPER::paint_key unless defined $dropdown;
		return ( $self->SUPER::paint_key, $top, $dropdown->option_count, map { @$_ } $self->_shown_rows );
	}

	method paint () {
		return unless defined $dropdown;
		my @rows  = $self->_shown_rows;
		my $width = $self->_text_columns;
		foreach my $row ( 0 .. $#rows ) {
			my ( $label, $fg, $bg ) = @{ $rows[$row] };
			$self->put_attrs( $_, $row, ' ', undef, $bg ) foreach 0 .. $width - 1;
			$self->_paint_label( $row, $label, $fg, $bg, $width - 1 );
		}
		$self->_paint_scrollbar if $self->_scrolls;
		return;
	}

	# One space of margin on either side of the label.
	method _paint_label ( $row, $label, $fg, $bg, $limit ) {
		my $x = 1;
		foreach my $cluster ( grapheme_clusters($label) ) {
			my $columns = cluster_columns($cluster);
			last if $x + $columns > $limit;
			$self->put_attrs( $x, $row, $cluster, $fg, $bg );
			$x += $columns;
		}
		return;
	}

	# In the rightmost column, in the theme's scrollbar colors.
	method _paint_scrollbar () {
		Term::Fabulous::Widget::Scrollbar->paint_track(
			$self,
			axis       => 'vertical',
			at         => $self->columns - 1,
			thumb      => scroll_thumb( $dropdown->option_count, $visible_rows, $top, $self->rows ),
			track_attr => $self->color_attr( $self->family_look( scrollbar => 'track' ) ),
			thumb_attr => $self->color_attr( $self->family_look( scrollbar => 'thumb' ) ),
		);
		return;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::Dropdown::List - The option list of an open dropdown

=head1 DESCRIPTION

This class is internal to L<Term::Fabulous::Widget::Dropdown>.
Applications never create a list themselves: the dropdown creates one
each time it opens, adds it as a floating child of itself (so it is
drawn over the other widgets, attached below or above the dropdown), and
removes it when it closes.

The list is a L<Term::Fabulous::Widget::Display> that paints the
dropdown's options with a one-column margin on both sides, highlights
one of them, scrolls through them when there are more options than
rows, and then shows a scrollbar in its rightmost column. It turns mouse
presses into highlights and mouse releases into choices, and scrolls on
the mouse wheel. It never takes the keyboard focus; the dropdown keeps
the focus and handles the keys.

The methods below are documented for authors of dropdown subclasses and
for tests.

=head1 CONSTRUCTOR

=head2 new

	my $list = Term::Fabulous::Widget::Dropdown::List->new(
		dropdown     => $dropdown,
		visible_rows => 8,
		...
	);

Called by the dropdown with these parameters, plus C<background_color>,
C<border_color>, C<bordered>, C<border_style>, C<layout> and
C<floating> (see L<Term::Fabulous::Widget/floating>). Unknown
parameters die.

=over

=item C<dropdown>

Required. The L<Term::Fabulous::Widget::Dropdown> the list belongs to.
Held as a weak reference.

=item C<visible_rows>

Required. A positive integer: how many options the list shows at once.

=back

=head1 METHODS

=head2 visible_rows

	my $rows = $list->visible_rows;

How many options the list shows at once.

=head2 top_option

	my $index = $list->top_option;

The index of the first option shown (from 0).

=head2 show_highlight

	$list->show_highlight;

Scrolls the dropdown's highlighted option into view and marks the list
changed. Returns the list.

=head2 scroll

	$list->scroll(-1);

Scrolls by a number of options (negative: towards the first), staying
within the options. Returns the list.

=head2 option_at_row

	my $index = $list->option_at_row($row);

The index of the option shown at a row of the list's content (from 0),
or C<undef> for a row without an option.

=head2 paint, paint_key, natural_size

The L<Term::Fabulous::Widget::Display> interface. C<paint> draws the
visible options and, when the list scrolls, the scrollbar. The paint key
adds the first option shown, what the shown rows display and the
scrollbar's colors, so the list paints again whenever that changed, also
when the change came from the dropdown (its colors, its highlight, its
options). The natural size (the widest label with its margins and the
scrollbar column, by C<visible_rows>) is used only for an axis the
dropdown leaves unsized; it always sizes both.

=head1 MOUSE

A left press on an option highlights it; releasing the left button over
an option chooses it (see L<Term::Fabulous::Widget::Dropdown/choose>).
Presses on the scrollbar column are ignored. Each notch of the mouse
wheel scrolls by one option.

=head1 SEE ALSO

L<Term::Fabulous::Widget::Dropdown>.

=cut
