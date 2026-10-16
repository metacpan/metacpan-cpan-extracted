package Term::Fabulous::Role::Terminal;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

role Term::Fabulous::Role::Terminal {
	method open;
	method close;
	method is_open;
	method size;
	method apply_resize;
	method read_handles;
	method next_event;
	method input_ended;
	method kitty_keyboard_active;
	method cell_target;
}

1;

__END__

=head1 NAME

Term::Fabulous::Role::Terminal - What Term::Fabulous needs from a
terminal

=head1 SYNOPSIS

	use Object::Pad 0.825;
	use Term::Fabulous::Role::Terminal;

	class My::Terminal :does(Term::Fabulous::Role::Terminal) {
		method open (%options)           { ... }
		method close ()                  { ... }
		method is_open ()                { ... }
		method size ()                   { ... }    # ( $columns, $rows )
		method apply_resize ( $w, $h )   { ... }    # ( $columns, $rows )
		method read_handles ()           { ... }
		method next_event ()             { ... }    # a Term::Fabulous::Termbox::Event or undef
		method input_ended ()            { ... }
		method kitty_keyboard_active ()  { ... }
		method cell_target ()            { ... }
	}

	my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24, terminal => My::Terminal->new );

=head1 DESCRIPTION

Most programs never use this module directly. L<Term::Fabulous> talks
to the terminal only through an object that composes this role, its
I<terminal>. Two terminals come with the distribution:

=over

=item L<Term::Fabulous::Terminal::Termbox>

The real terminal, through termbox2. The default.

=item L<Term::Fabulous::Terminal::Memory>

A terminal in memory, for tests: the test queues keys, clicks and
resizes, drives the application with L<Term::Fabulous/step> and reads
back what the screen shows.

=back

Term::Fabulous keeps everything that is not about the terminal itself:
the L<IO::Async> loop, its timers and signals, the routing of keys and
the mouse to the widgets, focus, wheel scrolling and frame pacing. A
terminal only opens and closes the session, reports input and receives
the painted cells.

=head1 REQUIRED METHODS

A class composing the role provides all of the following. Errors are
reported by dying with a message that starts with the class name.

=head2 open

	$terminal->open( inline => undef, mouse => 1, kitty_keyboard => 1 );

Starts a session. C<inline> is C<undef> for the full screen, or the
number of rows of a region below the shell's output (see
L<Term::Fabulous/INLINE MODE>). C<mouse> says whether the terminal
reports the mouse, including motion with no button held.
C<kitty_keyboard> says whether to ask the terminal for the kitty
keyboard protocol, and to switch it on if the terminal speaks it.
Term::Fabulous always passes all three. Dies when the session cannot
start; the terminal is then left as it was. Dies when it is open
already.

=head2 close

	$terminal->close;

Ends the session and gives the terminal back as it was: the modes
L</open> switched on are off again, an inline region's last frame stays
on the screen with the cursor below it. Does nothing when no session is
open.

=head2 is_open

1 between L</open> and L</close>, otherwise 0.

=head2 size

	my ( $columns, $rows ) = $terminal->size;

The size of the layout, in cells, while the session is open: the
terminal's size, or in inline mode its width and the rows of the
region. Both are at least 1.

=head2 apply_resize

	my ( $columns, $rows ) = $terminal->apply_resize( $width, $height );

Called with the size a resize event reported, once Term::Fabulous
applies it. Returns the new size of the layout, like L</size>; in
inline mode the terminal finds its region again first.

=head2 read_handles

	my @handles = $terminal->read_handles;

File handles that become readable when input waits, while the session
is open. Term::Fabulous watches them with L<IO::Async> during
L<Term::Fabulous/run> and calls L</next_event> when one is readable.
Term::Fabulous never reads from them and never closes them, and it
switches them back to blocking mode after IO::Async has made them
non-blocking. Handles the terminal owns must stay open until L</close>.
A terminal that returns no handles, and every terminal on Windows, is
polled instead: L<Term::Fabulous/run> calls L</next_event> at a steady
rate (L<Term::Fabulous/termbox_input_poll_interval>).

=head2 next_event

	while ( defined( my $event = $terminal->next_event ) ) { ... }

Returns the next input event without waiting, as a
L<Term::Fabulous::Termbox::Event> of the type C<TB_EVENT_KEY>,
C<TB_EVENT_MOUSE> or C<TB_EVENT_RESIZE>, or C<undef> when none waits.
Dies when reading the input fails.

=head2 input_ended

1 when the input has ended for good (the terminal went away), so that
no event will ever come again; otherwise 0. Term::Fabulous asks after
reading the events of a readable handle.

=head2 kitty_keyboard_active

1 while the session uses the kitty keyboard protocol, otherwise 0.

=head2 cell_target

	my $target = $terminal->cell_target;

The object L<Term::Fabulous::Render> paints into: a cell target, see
L<Term::Fabulous::Render/CELL TARGET>. It is the same object for the
lifetime of the terminal. A terminal that shows sixel graphics gives it
the role L<Term::Fabulous::Render::Target::Sixel> and keeps its cell
size up to date while the session is open.

=head1 SEE ALSO

L<Term::Fabulous>, L<Term::Fabulous::Terminal::Termbox>,
L<Term::Fabulous::Terminal::Memory>, L<Term::Fabulous::Render/CELL TARGET>.

=cut
