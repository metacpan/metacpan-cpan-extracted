package Term::Fabulous::Event::MouseMove;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Object::Pad 0.825;

use Clay::UI::Events::Event;

class Term::Fabulous::Event::MouseMove :isa(Clay::UI::Events::Event) :strict(params) {
	field $x :param :reader;
	field $y :param :reader;
	field $modifiers :param :reader = 0;

	method event_name :common { 'MouseMove' }

	method of :common ($ev) {
		return $class->new(
			x         => $ev->x,
			y         => $ev->y,
			modifiers => $ev->mod,
		);
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Event::MouseMove - The mouse pointer moved with no
button held

=head1 SYNOPSIS

	$canvas->on( MouseMove => sub ($event) {
		my ( $column, $row ) = $canvas->cell_at($event);
		$status->text("pointer over $column,$row");
		return;
	} );

=head1 DESCRIPTION

L<Term::Fabulous> fires a C<MouseMove> event every time the terminal
reports that the pointer moved while no mouse button was held, while
L<Term::Fabulous/run> is active and mouse input is enabled (the
C<mouse> parameter of L<Term::Fabulous/new>, on by default except in
inline mode). Moves
with a button held are drags and fire C<Mouse>
(L<Term::Fabulous::Event::Mouse>) instead.

Like C<Mouse>, the event is fired on the topmost widget that painted
the cell under the pointer in the last frame (see
L<Term::Fabulous::Manual::Events/MOUSE>), or on the root widget when there is
none, and then bubbles up to the ancestors. Term::Fabulous also records
the new pointer position before it fires the event, so the hover state
of the widgets (C<OnHoverStart>, C<OnHoverStopped>, C<is_hovered>)
follows the pointer with the next frame.

Terminals report moves generously, often for every cell the pointer
crosses, so keep C<MouseMove> listeners cheap.

The class is a subclass of L<Clay::UI::Events::Event>, so C<target>,
C<current_target>, C<name> (C<'MouseMove'> unless given to the
constructor) and C<bubble_mode> (C<IF_CONTINUE>) are available as well.

=head1 CONSTRUCTOR

=head2 new

	my $event = Term::Fabulous::Event::MouseMove->new( x => 10, y => 3 );

Programs rarely build these events themselves; it is useful in tests.
Unknown parameters die. Besides the parameters below, the C<name> and
C<bubble_mode> parameters of L<Clay::UI::Events::Event> are accepted.

=over

=item C<x>

Required. The column of the pointer, counted from 0 at the left edge of
the terminal.

=item C<y>

Required. The row of the pointer, counted from 0 at the top edge of the
terminal.

=item C<modifiers>

Optional. A bit mask of C<TB_MOD_SHIFT>, C<TB_MOD_ALT>, C<TB_MOD_CTRL>
and C<TB_MOD_MOTION>. Default: C<0>.

=back

=head2 of

	my $event = Term::Fabulous::Event::MouseMove->of($termbox_event);

Builds an event from a C<Term::Fabulous::Termbox::Event>: C<x>, C<y>
and C<modifiers> from its C<x>, C<y> and C<mod>. Called by
L<Term::Fabulous>; class method.

=head1 METHODS

=head2 x

	my $column = $event->x;

The column of the cell under the pointer, from 0 at the left edge of
the terminal. To get a position inside a canvas, use
L<Term::Fabulous::Widget::Canvas/cell_at> or
L<Term::Fabulous::Widget::PixelCanvas/pixel_at>; both accept this event.

=head2 y

	my $row = $event->y;

The row of the cell under the pointer, from 0 at the top edge of the
terminal.

=head2 modifiers

	my $with_shift = $event->modifiers & TB_MOD_SHIFT;

A bit mask of the modifier keys held while the pointer moved:
C<TB_MOD_SHIFT>, C<TB_MOD_ALT>, C<TB_MOD_CTRL> from
L<Term::Fabulous::Termbox>. C<TB_MOD_MOTION> is always set for an
event L<Term::Fabulous> fires, since the pointer moved.

=head1 SEE ALSO

L<Term::Fabulous::Manual::Events/MOUSE>, L<Term::Fabulous::Event::Mouse>,
L<Term::Fabulous>, L<Clay::UI::Events::Event>.

=cut
