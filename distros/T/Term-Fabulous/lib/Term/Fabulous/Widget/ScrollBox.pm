package Term::Fabulous::Widget::ScrollBox;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

use Object::Pad 0.825;

use Clay::UI::Role::Layout::HasScroll;
use Term::Fabulous::Widget::Box;

our $VERSION = '0.02';

class Term::Fabulous::Widget::ScrollBox
	:isa(Term::Fabulous::Widget::Box)
	:does(Clay::UI::Role::Layout::HasScroll)
	:strict(params)
{
	use Clay::XS qw(
		sizing_grow sizing_fixed CLAY_LEFT_TO_RIGHT CLAY_ALIGN_Y_BOTTOM
		CLAY_ATTACH_TO_PARENT CLAY_ATTACH_POINT_LEFT_TOP CLAY_CLIP_TO_ATTACHED_PARENT
		CLAY_POINTER_CAPTURE_MODE_PASSTHROUGH
	);
	use Term::Fabulous::Check qw(boolean);
	use Term::Fabulous::Widget::Scrollbar;

	# The gutter floats over the whole box and is padded by its border: a
	# column with the horizontal scrollbar at its bottom, then the
	# vertical scrollbar, which runs the full height. It lets the pointer
	# through, so the box below still scrolls with the wheel and its
	# content is still hovered.
	my %GUTTER_LAYOUT   = ( layout_direction => CLAY_LEFT_TO_RIGHT, sizing => { width => sizing_grow(), height => sizing_grow() } );
	my %GUTTER_FLOATING = (
		attach_to            => CLAY_ATTACH_TO_PARENT,
		attach_points        => { element => CLAY_ATTACH_POINT_LEFT_TOP, parent => CLAY_ATTACH_POINT_LEFT_TOP },
		clip_to              => CLAY_CLIP_TO_ATTACHED_PARENT,
		pointer_capture_mode => CLAY_POINTER_CAPTURE_MODE_PASSTHROUGH,
	);
	my %BAR_LAYOUT = (
		vertical   => { sizing => { width => sizing_fixed(1), height => sizing_grow() } },
		horizontal => { sizing => { width => sizing_grow(),   height => sizing_fixed(1) } },
	);
	my %SIDE_OF_AXIS = ( vertical => 'right', horizontal => 'bottom' );

	field $scrollbar :param = 1;
	field $_gutter;
	field %_bar_by_axis;

	# Clay::UI stores these as given; the constructor takes any truth value.
	sub BUILDARGS ( $class, %params ) {
		$params{$_} = $params{$_} ? 1 : 0 foreach grep { exists $params{$_} } qw(horizontal vertical);
		return $class->SUPER::BUILDARGS(%params);
	}

	# The colors go to the scrollbars once they exist; undef leaves them
	# to the theme.
	ADJUST :params ( :$track_color = undef, :$thumb_color = undef ) {
		$scrollbar    = boolean( $self, scrollbar => $scrollbar );
		%_bar_by_axis = map { $_ => Term::Fabulous::Widget::Scrollbar->new( follows => $self, axis => $_, layout => $BAR_LAYOUT{$_} ) } keys %BAR_LAYOUT;
		$self->set_look( track_color => $track_color ) if defined $track_color;
		$self->set_look( thumb_color => $thumb_color ) if defined $thumb_color;

		my $column = Term::Fabulous::Widget::Box->new( layout => { sizing => { width => sizing_grow(), height => sizing_grow() }, child_alignment => { y => CLAY_ALIGN_Y_BOTTOM } } );
		$column->add_child( $_bar_by_axis{horizontal} );
		$_gutter = Term::Fabulous::Widget::Box->new( floating => {%GUTTER_FLOATING} );
		$_gutter->add_child( $column, $_bar_by_axis{vertical} );
		$self->_pad_gutter;
		$self->add_internal_children($_gutter) if $scrollbar;
	}

	method layout_properties :common () {
		return ( $class->SUPER::layout_properties, horizontal => 'boolean', vertical => 'boolean', scrollbar => 'boolean' );
	}

	# Whether a scrollbar is shown for an axis: wanted, and the box
	# scrolls that way.
	method _shows_bar ($axis) {
		return $scrollbar && ( $axis eq 'vertical' ? $self->vertical : $self->horizontal ) ? 1 : 0;
	}

	# The content keeps clear of the scrollbars: one column at the right
	# for the vertical one, one row at the bottom for the horizontal one.
	method contribute_layout :override ($config) {
		$self->SUPER::contribute_layout($config);
		my @sides = map { $SIDE_OF_AXIS{$_} } grep { $self->_shows_bar($_) } sort keys %SIDE_OF_AXIS;
		return unless @sides;
		my %padding = %{ $config->{layout}{padding} // {} };
		$padding{$_}      = ( $padding{$_} // 0 ) + 1 foreach @sides;
		$config->{layout} = { %{ $config->{layout} // {} }, padding => \%padding };
		return;
	}

	# The gutter is padded by the border, so the scrollbars sit inside it.
	method _pad_gutter () {
		$_gutter->layout( { %GUTTER_LAYOUT, padding => $self->drawn_border_sides } );
		return;
	}

	# The border may change with bordered or with the theme
	# (Term::Fabulous::Role::Themed).
	method looks_changed (@names) {
		$self->_pad_gutter if grep { $_ eq 'bordered' } @names;
		return;
	}

	method scrollbar (@new) {
		return $scrollbar unless @new;
		$scrollbar = boolean( $self, scrollbar => $new[0] );
		my $attached = defined $_gutter->parent ? 1 : 0;
		$self->add_internal_children($_gutter) if $scrollbar     && !$attached;
		$self->remove_internal_children($_gutter) if !$scrollbar && $attached;
		return $scrollbar;
	}

	# The scrollbars keep the colors (Term::Fabulous::Role::Themed): both
	# take a color given here, reset_look returns both to the theme, and a
	# read asks the vertical one.
	method forwarded_looks :common () {
		return ( _scrollbars => [ 'Term::Fabulous::Widget::Scrollbar', qw(track_color thumb_color) ] );
	}

	method _scrollbars () {
		return @_bar_by_axis{qw(vertical horizontal)};
	}

	method track_color (@new) { return @new ? $self->set_look( track_color => $new[0] ) : $self->look_value('track_color') }
	method thumb_color (@new) { return @new ? $self->set_look( thumb_color => $new[0] ) : $self->look_value('thumb_color') }
}

1;

__END__

=head1 NAME

Term::Fabulous::Widget::ScrollBox - A box whose content scrolls

=head1 SYNOPSIS

	use Clay::XS qw(sizing_grow sizing_fixed CLAY_TOP_TO_BOTTOM);
	use Term::Fabulous::Enum::BorderStyle;
	use Term::Fabulous::Widget::ScrollBox;
	use Term::Fabulous::Widget::Text;

	my $log = Term::Fabulous::Widget::ScrollBox->new(
		id               => 'log',                  # required
		layout           => {
			layout_direction => CLAY_TOP_TO_BOTTOM,
			sizing           => { width => sizing_grow(), height => sizing_fixed(10) },
			padding          => { left => 1, right => 1 },
		},
		background_color => [ 30, 35, 50, 255 ],
		bordered         => 1,
		border_color     => [ 120, 160, 220, 255 ],
		border_style     => Term::Fabulous::Enum::BorderStyle->Round,
	);
	$log->add_child( Term::Fabulous::Widget::Text->new( text => "Line $_", text_color => [ 220, 220, 220, 255 ] ) )
		foreach 1 .. 100;

	$log->on( OnScroll => sub ($event) {
		printf STDERR "scrolled by %d rows\n", $event->delta_y;
		return;
	} );

=begin html

<p><img src="https://raw.githubusercontent.com/davenonymous/perl-term-fabulous/v0.02/screenshots/example-scroll-box.svg" alt="Two framed boxes scrolled down, one with numbered lines, one with squares, each with a scrollbar in its last column whose thumb shows the visible part"></p>

=end html

=head1 DESCRIPTION

A ScrollBox is a L<Term::Fabulous::Widget::Box> for content that is
larger than the box: everything that does not fit is clipped, and the
user scrolls through it with the mouse wheel or with the scrollbars.
Typical uses are logs, long lists and help texts. Every child is laid
out in every frame, visible or not; for thousands of children, the
paragraphs of a long document say, use a
L<Term::Fabulous::Widget::VirtualList>, which attaches only the ones
near the viewport.

A vertical scrollbar (a L<Term::Fabulous::Widget::Scrollbar>) takes the
last column inside the border, and a horizontal one the last row when
the box scrolls sideways; the content keeps clear of them. While the
content fits, a scrollbar is empty but keeps its column or row, so the
content does not jump when it starts to scroll. A click on a scrollbar
scrolls so that the thumb is centered under the pointer, and dragging
with the left button keeps doing so. C<< scrollbar => 0 >> removes the
scrollbars and gives their cells back to the content.

The size of a ScrollBox comes from its own C<sizing>, not from its
content, so give it a C<fixed>, C<grow> or C<percent> height (and
width, when it scrolls sideways). With the default C<fit> sizing the
box grows with its content instead of scrolling it.

Under L<Term::Fabulous>, every notch of the mouse wheel scrolls the
ScrollBox under the pointer by three rows, and every notch of a
horizontal wheel (or a sideways tilt of the wheel) by three columns,
unless a widget under the pointer used the notch to scroll itself (see
L</CAVEATS>). The scroll position is
clamped, so the content cannot be scrolled past its first or last row.
The position is applied when the next frame is drawn. Keys do not
scroll a ScrollBox.

The content is clipped to the whole box, border included: scrolled
content passes under the border, which is drawn on top of it. Content
scrolled out of view receives no mouse events.

=head1 CONSTRUCTOR

=head2 new

	my $box = Term::Fabulous::Widget::ScrollBox->new( id => 'log', %parameters );

Unknown parameters die. A ScrollBox takes every parameter of
L<Term::Fabulous::Widget::Box> (see L<Term::Fabulous::Widget/new>) plus:

=over

=item C<id>

A non-empty string, unique in the widget tree. B<Required>: without it
the constructor dies, because the scroll position is stored by id from
one frame to the next.

=item C<vertical>

A boolean, stored as 1 or 0. Default: 1. Whether the content scrolls
up and down.

=item C<horizontal>

A boolean, stored as 1 or 0. Default: 0. Whether the content scrolls
sideways, with a horizontal wheel or with C<child_offset>.

=item C<child_offset>

C<undef> or a hash reference C<< { x => $columns, y => $rows } >>.
Default: C<undef>, which lets the mouse wheel control the position.
A hash takes over: the content is drawn shifted by that many cells, and
the wheel no longer moves it. Negative values move the content up and
left, so C<< { x => 0, y => -3 } >> shows the content from its fourth
row on. Set it back to C<undef> to give control back to the wheel. The wheel
keeps moving the hidden scroll position while C<child_offset> is set,
so the content may jump when you set it back to C<undef>.

=item C<scrollbar>

A boolean, stored as 1 or 0. Default: 1. Whether the scrollbars are
shown: a vertical one while C<vertical> is true, a horizontal one while
C<horizontal> is true. Each takes one column or row inside the border
from the content.

=item C<track_color>

The color of the scrollbars' track, anything L<Term::Fabulous::Color>
understands. Default: the theme's C<scrollbar.track>, a dark grey,
C<[ 70, 76, 90, 255 ]>, in the dark theme.

=item C<thumb_color>

The color of the scrollbars' thumb. Default: the theme's
C<scrollbar.thumb>, a light blue, C<[ 97, 175, 239, 255 ]>, in the
dark theme.

=back

=head1 METHODS

To read or set the scroll position of a ScrollBox from your program, for
example to keep a log at its newest line, call the methods
L<scroll_state and scroll_to|Term::Fabulous/"bounding_box, scroll_state, scroll_to">
of the application object with the box. The recipe
L<Scroll a ScrollBox from code|Term::Fabulous::Cookbook::LiveData/"Scroll a ScrollBox from code (keep a log at the newest line)">
shows them in a complete program.

A ScrollBox has all methods of L<Term::Fabulous::Widget> plus these
accessors (from L<Clay::UI::Role::Layout::HasScroll>):

=head2 vertical

	$box->vertical(0);

Accessor. Without an argument it returns the stored value, 1 or 0;
with an argument it stores any true or false value as 1 or 0 and
returns it. References die.
The change shows in the next frame.

=head2 horizontal

	$box->horizontal(1);

Accessor for C<horizontal>, used like L</vertical>.

=head2 child_offset

	$box->child_offset( { x => 0, y => -20 } );    # show from row 21 on
	$box->child_offset(undef);                      # back to the wheel

Accessor. Without an argument it returns the hash reference, or
C<undef> while the wheel controls the position; with an argument it
sets it and returns the new value. An invalid value dies like the
constructor parameter. The change shows in the next frame.

=head2 scrollbar

	$box->scrollbar(0);

Accessor for C<scrollbar>, used like L</vertical>. Switching the
scrollbars off gives their cells back to the content in the next frame.

=head2 track_color, thumb_color

	$box->track_color('#464c5a');
	$box->thumb_color( [ 97, 175, 239, 255 ] );

Accessors for the scrollbar colors. Without an argument they return the
color as C<[r, g, b, a]>; with one they set it on both scrollbars and
return it. An invalid color dies and leaves the old one; so does
C<undef>: C<< $box->reset_look('thumb_color') >> returns the color of
both scrollbars to the theme (see
L<Term::Fabulous::Widget/reset_look>).

=head2 children

	my @lines = @{ $box->children };

The children you added, as on any L<Term::Fabulous::Widget::Box>. The
scrollbars are not among them, and C<clear_children> and the other
removal methods leave them alone.

=head1 EVENTS

=over

=item C<OnScroll> (L<Clay::UI::Events::OnScroll>)

Fired on the ScrollBox in every frame in which its scroll position
changed. C<< $event->delta_y >> is how far the content moved, in rows:
negative when the user scrolled down (the content moved up), positive
when scrolled up. C<< $event->delta_x >> is the same for columns.
While C<child_offset> is set, C<OnScroll> still reports the movement of
the hidden scroll position that the wheel moves, even though the
content does not move.

=item C<Mouse> (L<Term::Fabulous::Event::Mouse>)

Fired for wheel notches and clicks over the box, like on any Box (see
L<Term::Fabulous::Manual::Events/MOUSE>). The scrolling does not depend on what
your listeners return: a listener that stops the event from bubbling
does not stop the scrolling. Only a call to
L<Term::Fabulous::Event::Mouse/use_wheel> keeps a notch from scrolling
the box.

=back

=head1 KDL PROPERTIES

The properties of L<Term::Fabulous::Widget::Box/KDL PROPERTIES>, plus
C<horizontal>, C<vertical> and C<scrollbar> (C<#true> or C<#false>) and
the colors C<track_color> and C<thumb_color>. The node needs an id
argument:

=for highlighter language=kdl

	ScrollBox "log" {
		layout direction=down
		sizing width=grow height="fixed(10)"
		vertical #true
		thumb_color "#61afef"
	}

C<child_offset> cannot be set from KDL.

=head1 CAVEATS

A widget inside a ScrollBox that uses the mouse wheel itself (a
L<Term::Fabulous::Widget::TextArea>, a L<Term::Fabulous::Widget::Slider>,
an open L<Term::Fabulous::Widget::Dropdown> list) takes the notches
over it while it can move, and the ScrollBox stays put; once the widget
is at its end, the notches scroll the ScrollBox again. So a long form
scrolls past a text area as soon as the text area shows its last rows.

The scrollbars are drawn over the box, inside its border, after the
content. Content that scrolls sideways passes under the vertical
scrollbar's column; while there is nothing to scroll down, that column
is empty and shows the content beneath.

=head1 SEE ALSO

L<Term::Fabulous::Manual::Events/SCROLLING>,
L<Term::Fabulous::Cookbook::LiveData/Scroll a ScrollBox from code (keep a log at the newest line)>,
L<Term::Fabulous::Widget::VirtualList> for thousands of children,
L<Term::Fabulous::Widget::Scrollbar>, L<Term::Fabulous::Widget::Box>,
L<Clay::UI::Role::Layout::HasScroll>, the example program
F<examples/scroll-box.pl>.

=cut
