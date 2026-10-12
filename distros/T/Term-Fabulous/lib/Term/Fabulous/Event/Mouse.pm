package Term::Fabulous::Event::Mouse;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Object::Pad 0.825;

use Clay::UI::Events::Event;

class Term::Fabulous::Event::Mouse :isa(Clay::UI::Events::Event) :strict(params) {
	use Term::Fabulous::Termbox qw(TB_KEY_MOUSE_LEFT TB_KEY_MOUSE_MIDDLE TB_KEY_MOUSE_RIGHT TB_KEY_MOUSE_RELEASE);

	my %IS_BUTTON = map { $_ => 1 } TB_KEY_MOUSE_LEFT, TB_KEY_MOUSE_MIDDLE, TB_KEY_MOUSE_RIGHT;

	field $key             :param :reader;
	field $x               :param :reader;
	field $y               :param :reader;
	field $modifiers       :param :reader = 0;
	field $released_button :param :reader = undef;
	field $wheel_used      :reader = 0;

	ADJUST {
		_check_released_button( $key, $released_button ) if defined $released_button;
	}

	sub _check_released_button ( $key, $button ) {
		die "Term::Fabulous::Event::Mouse: released_button needs the key TB_KEY_MOUSE_RELEASE, got key $key"
			unless $key == TB_KEY_MOUSE_RELEASE;
		die "Term::Fabulous::Event::Mouse: released_button must be TB_KEY_MOUSE_LEFT, TB_KEY_MOUSE_MIDDLE or TB_KEY_MOUSE_RIGHT, got '$button'"
			unless $IS_BUTTON{$button};
		return;
	}

	method event_name :common { 'Mouse' }

	method of :common ($ev) {
		return $class->new(
			key             => $ev->key,
			x               => $ev->x,
			y               => $ev->y,
			modifiers       => $ev->mod,
			released_button => $ev->key == TB_KEY_MOUSE_RELEASE && $ev->ch ? $ev->ch : undef,
		);
	}

	method use_wheel () {
		$wheel_used = 1;
		return $self;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Event::Mouse - A mouse click, release, drag or wheel
turn from the terminal

=head1 SYNOPSIS

	use Term::Fabulous::Termbox qw(TB_KEY_MOUSE_LEFT TB_KEY_MOUSE_RIGHT TB_KEY_MOUSE_WHEEL_UP TB_MOD_MOTION);

	$panel->on( Mouse => sub ($event) {
		my ( $x, $y ) = ( $event->x, $event->y );    # terminal cell, from 0
		if ( $event->key == TB_KEY_MOUSE_LEFT ) {
			if ( $event->modifiers & TB_MOD_MOTION ) {
				drag_to( $x, $y );                   # moved with the left button held
			}
			else {
				start_at( $x, $y );                  # left button pressed
			}
		}
		return;
	} );

=head1 DESCRIPTION

L<Term::Fabulous> fires a C<Mouse> event for every mouse report the
terminal sends while L<Term::Fabulous/run> is active and mouse input is
enabled (the C<mouse> parameter of L<Term::Fabulous/new>, on by
default except in inline mode, which has no mouse support). The event is fired on the topmost widget that painted the
cell under the pointer in the last frame (see
L<Term::Fabulous::Manual::Events/MOUSE> for the exact rules), or on the root
widget when there is none, and then bubbles up to the ancestors.

The class is a subclass of L<Clay::UI::Events::Event>, so C<target>,
C<current_target>, C<name> (C<'Mouse'> unless given to the constructor)
and C<bubble_mode> (C<IF_CONTINUE>) are available as well.

=head2 What the terminal reports

Terminals report the mouse only in these cases:

=over

=item * a button is pressed: C<key> is C<TB_KEY_MOUSE_LEFT>,
C<TB_KEY_MOUSE_MIDDLE> or C<TB_KEY_MOUSE_RIGHT>;

=item * a button is released: C<key> is C<TB_KEY_MOUSE_RELEASE>, and
C<released_button> says which button it was when the terminal reports
it (SGR mouse reports, which L<Term::Fabulous> asks for, do);

=item * the pointer moves while a button is held (a drag): C<key> is the
held button's key again and C<modifiers> has C<TB_MOD_MOTION> set;

=item * the wheel turns: C<key> is C<TB_KEY_MOUSE_WHEEL_UP> or
C<TB_KEY_MOUSE_WHEEL_DOWN>, one event per notch; a horizontal wheel
(or a sideways tilt of the wheel) gives C<TF_KEY_MOUSE_WHEEL_LEFT> or
C<TF_KEY_MOUSE_WHEEL_RIGHT>.

=back

The pointer moving without a button held is reported as well, but it
is not a C<Mouse> event: it fires C<MouseMove>
(L<Term::Fabulous::Event::MouseMove>) instead.

Terminals encode Shift, Ctrl and Alt in their mouse reports;
C<modifiers> carries them as C<TB_MOD_SHIFT>, C<TB_MOD_CTRL> and
C<TB_MOD_ALT>, so a Shift+click can be told from a click.

=head1 CONSTRUCTOR

=head2 new

	use Term::Fabulous::Termbox qw(TB_KEY_MOUSE_LEFT TB_KEY_MOUSE_RELEASE TB_MOD_MOTION);

	my $press   = Term::Fabulous::Event::Mouse->new( key => TB_KEY_MOUSE_LEFT, x => 10, y => 3 );
	my $drag    = Term::Fabulous::Event::Mouse->new( key => TB_KEY_MOUSE_LEFT, x => 12, y => 3, modifiers => TB_MOD_MOTION );
	my $release = Term::Fabulous::Event::Mouse->new( key => TB_KEY_MOUSE_RELEASE, x => 12, y => 3 );

	$canvas->fire_event($press);

Programs rarely build mouse events themselves; L<Term::Fabulous> does it
for every report. Building one by hand is useful in tests of one
widget's C<Mouse> listeners; the
L<C<click>|Term::Fabulous::Terminal::Memory/click> method of
Term::Fabulous::Terminal::Memory clicks like a real mouse (see L<Term::Fabulous::Manual::Programs/TESTING>). Note
that firing a hand-built event
on a widget only runs the listeners. For a real left press,
L<Term::Fabulous> records the pointer position and moves the keyboard
focus (see L<Term::Fabulous::Manual::Events/FOCUS>) before it fires the
C<Mouse> event. Clay::UI's C<OnPress> and C<OnRelease>
events (L<Clay::UI::Role::Interaction::Pressable>) come later, during
the next frame (within 1/30 second), when the recorded pointer is
handed to Clay. A hand-built C<Mouse> event does none of this. Unknown
parameters die. Besides the parameters below, the C<name> and
C<bubble_mode> parameters of L<Clay::UI::Events::Event> are accepted.

=over

=item C<key>

Required. One of the C<TB_KEY_MOUSE_*> constants listed under L</key>.

=item C<x>

Required. The column of the pointer, counted from 0 at the left edge of
the terminal.

=item C<y>

Required. The row of the pointer, counted from 0 at the top edge of the
terminal.

=item C<modifiers>

Optional. A bit mask of C<TB_MOD_MOTION>, C<TB_MOD_SHIFT>, C<TB_MOD_ALT>
and C<TB_MOD_CTRL>. Default: C<0>.

=item C<released_button>

Optional. With C<key> C<TB_KEY_MOUSE_RELEASE> only: the button that was
released, C<TB_KEY_MOUSE_LEFT>, C<TB_KEY_MOUSE_MIDDLE> or
C<TB_KEY_MOUSE_RIGHT>. Default: C<undef>, the terminal did not say.
Anything else dies.

=back

An event object can be fired only once. Build a new one for every
C<fire_event> call.

=head2 of

	my $event = Term::Fabulous::Event::Mouse->of($termbox_event);

Builds an event from a C<Term::Fabulous::Termbox::Event>: C<key>, C<x>, C<y> and
C<modifiers> from its C<key>, C<x>, C<y> and C<mod>, and for a release
C<released_button> from its C<ch> (see
L<Term::Fabulous::Termbox/tf_install_input_parser>). Called by
L<Term::Fabulous>; class method.

=head1 METHODS

=head2 key

	my $key = $event->key;

Which button or wheel direction the event is about. Import the
constants from L<Term::Fabulous::Termbox>:

	use Term::Fabulous::Termbox qw(
		TB_KEY_MOUSE_LEFT TB_KEY_MOUSE_MIDDLE TB_KEY_MOUSE_RIGHT
		TB_KEY_MOUSE_RELEASE TB_KEY_MOUSE_WHEEL_UP TB_KEY_MOUSE_WHEEL_DOWN
		TF_KEY_MOUSE_WHEEL_LEFT TF_KEY_MOUSE_WHEEL_RIGHT
		TB_MOD_MOTION
	);

	Constant                  Meaning
	------------------------  ------------------------------------------
	TB_KEY_MOUSE_LEFT         left button pressed (or dragged)
	TB_KEY_MOUSE_MIDDLE       middle button pressed (or dragged)
	TB_KEY_MOUSE_RIGHT        right button pressed (or dragged)
	TB_KEY_MOUSE_RELEASE      a button was released (see released_button)
	TB_KEY_MOUSE_WHEEL_UP     wheel turned up (away from the user) one notch
	TB_KEY_MOUSE_WHEEL_DOWN   wheel turned down one notch
	TF_KEY_MOUSE_WHEEL_LEFT   horizontal wheel turned left one notch
	TF_KEY_MOUSE_WHEEL_RIGHT  horizontal wheel turned right one notch

The C<TF_KEY_*> constants are Term::Fabulous additions; termbox2 has no
codes for a horizontal wheel.

=head2 x

	my $column = $event->x;

The column of the cell under the pointer, an integer from 0 at the left
edge of the terminal, also on terminals wider than 255 columns. To get a
position inside a canvas, use L<Term::Fabulous::Widget::Canvas/cell_at>
or L<Term::Fabulous::Widget::PixelCanvas/pixel_at>.

=head2 y

	my $row = $event->y;

The row of the cell under the pointer, an integer from 0 at the top
edge of the terminal.

=head2 modifiers

	my $dragging = $event->modifiers & TB_MOD_MOTION;
	my $shifted  = $event->modifiers & TB_MOD_SHIFT;

A bit mask. C<TB_MOD_MOTION> is set when the event reports a move with
a button held (a drag); C<TB_MOD_SHIFT>, C<TB_MOD_ALT> and C<TB_MOD_CTRL>
are set for the modifier keys held at the time.

=head2 released_button

	use Term::Fabulous::Termbox qw(TB_KEY_MOUSE_RELEASE TB_KEY_MOUSE_RIGHT);

	if ( $event->key == TB_KEY_MOUSE_RELEASE && ( $event->released_button // 0 ) == TB_KEY_MOUSE_RIGHT ) {
		close_context_menu();
	}

For a C<TB_KEY_MOUSE_RELEASE>: the key of the button that was released,
C<TB_KEY_MOUSE_LEFT>, C<TB_KEY_MOUSE_MIDDLE> or C<TB_KEY_MOUSE_RIGHT>;
C<undef> when the terminal did not say. L<Term::Fabulous> takes a
release that names no button for a release of the left button. For
every other key: C<undef>.

=head2 use_wheel

	$event->use_wheel if $self->scroll_down_one_notch;

For a widget that scrolls itself with the wheel: marks the wheel notch
of this event as used. L<Term::Fabulous> scrolls the scroll containers
around the pointer (L<Term::Fabulous::Widget::ScrollBox>) by every notch
no widget used, so call it only when the notch moved something; a
widget that is already at its end leaves the notch to its scroll box.
Whether the event bubbles on is up to the return value of the listener,
as for any event. Returns the event.

=head2 wheel_used

	my $scrolled_itself = $event->wheel_used;

1 after L</use_wheel>, otherwise 0.

=head1 SEE ALSO

L<Term::Fabulous::Manual::Events/MOUSE>, L<Term::Fabulous>,
L<Term::Fabulous::Event::MouseMove>, L<Term::Fabulous::Event::KeyPress>,
L<Clay::UI::Events::Event>, L<Term::Fabulous::Termbox>,
L<Term::Fabulous::Cookbook::Canvases/Paint with the mouse (Canvas, clicks and drags)>.

=cut
