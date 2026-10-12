package Term::Fabulous::Terminal::Memory;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Object::Pad 0.825;

use Term::Fabulous::Role::Terminal;
use Term::Fabulous::Render::Target::Grid;

class Term::Fabulous::Terminal::Memory :does(Term::Fabulous::Role::Terminal) :strict(params) {
	use Term::Fabulous::Termbox qw(
		TB_EVENT_KEY TB_EVENT_MOUSE TB_EVENT_RESIZE
		TB_KEY_MOUSE_LEFT TB_KEY_MOUSE_RELEASE
	);
	use Term::Fabulous::Termbox::Event;
	use Term::Fabulous::Event::KeyPress;

	use constant OPEN_OPTIONS => qw(inline mouse kitty_keyboard);

	field $width           :param :reader;
	field $height          :param :reader;
	field $kitty_keyboard  :param :reader = 0;    # whether the terminal speaks the protocol
	field $sixel_cell_size :param = undef;    # [width, height] in pixels when the terminal shows sixel

	field $cell_target           :reader = Term::Fabulous::Render::Target::Grid->new( sixel_cell_size => $sixel_cell_size );
	field $is_open               :reader = 0;
	field $session_count         :reader = 0;
	field $mouse_enabled         :reader = 0;
	field $inline_rows           :reader = undef;
	field $kitty_keyboard_active :reader = 0;
	field $_inline;    # the rows the session asked for
	field $_rows;    # the rows of the layout, kept after close for reading the screen
	field @_queue;    # Term::Fabulous::Termbox::Event objects
	field $_input_has_ended = 0;

	# A byte in the pipe makes the read end readable while input waits, so
	# an IO::Async watcher on it wakes up like on a real terminal.
	field $_wakeup_read;
	field $_wakeup_write;
	field $_wakeup_pending = 0;

	ADJUST {
		_check_size( width  => $width );
		_check_size( height => $height );
		$_rows = $height;
		pipe( $_wakeup_read, $_wakeup_write ) or die "Term::Fabulous::Terminal::Memory: cannot create a pipe: $!\n";
		$_wakeup_write->autoflush(1);
	}

	sub _check_size ( $name, $value ) {
		die "Term::Fabulous::Terminal::Memory: $name must be a whole number of at least 1, got " . ( defined $value ? "'$value'" : 'undef' )
			unless defined $value && $value =~ /\A[1-9][0-9]*\z/;
		return;
	}

	method open (%options) {
		die "Term::Fabulous::Terminal::Memory: the terminal is open already" if $is_open;
		my %known   = map  { $_ => 1 } OPEN_OPTIONS;
		my @unknown = grep { !$known{$_} } sort keys %options;
		die "Term::Fabulous::Terminal::Memory: open does not accept @unknown (known options: " . join( ', ', OPEN_OPTIONS ) . ")" if @unknown;
		die "Term::Fabulous::Terminal::Memory: inline must be a whole number of rows of at least 1, got '$options{inline}'"
			if defined $options{inline} && $options{inline} !~ /\A[1-9][0-9]*\z/;

		$is_open = 1;
		$session_count++;
		$_inline               = $options{inline};
		$mouse_enabled         = $options{mouse}                             ? 1 : 0;
		$kitty_keyboard_active = $options{kitty_keyboard} && $kitty_keyboard ? 1 : 0;
		$_rows                 = $self->_layout_rows($height);
		$inline_rows           = defined $_inline ? $_rows : undef;
		$cell_target->clear_cells;
		return;
	}

	method _layout_rows ($screen_height) {
		return $screen_height unless defined $_inline;
		return $_inline < $screen_height ? $_inline : $screen_height;
	}

	method close () {
		return unless $is_open;
		$is_open = 0;
		( $mouse_enabled, $inline_rows, $kitty_keyboard_active ) = ( 0, undef, 0 );
		return;
	}

	method size () {
		die "Term::Fabulous::Terminal::Memory: the terminal is not open" unless $is_open;
		return ( $width, $_rows );
	}

	method apply_resize ( $new_width, $new_height ) {
		die "Term::Fabulous::Terminal::Memory: the terminal is not open" unless $is_open;
		( $width, $height ) = ( $new_width, $new_height );
		$_rows       = $self->_layout_rows($height);
		$inline_rows = $_rows if defined $_inline;
		return ( $width, $_rows );
	}

	method read_handles () {
		return ($_wakeup_read);
	}

	# A terminal that does not report the mouse sends no mouse events.
	method next_event () {
		while (@_queue) {
			my $event = shift @_queue;
			next if $event->type == TB_EVENT_MOUSE && !$mouse_enabled;
			return $event;
		}
		if ($_wakeup_pending) {
			sysread( $_wakeup_read, my $byte, 1 ) or die "Term::Fabulous::Terminal::Memory: cannot read its wakeup pipe: $!\n";
			$_wakeup_pending = 0;
		}
		return undef;
	}

	method input_ended () {
		return $_input_has_ended && !@_queue ? 1 : 0;
	}

	method push_event (%fields) {
		my $type = $fields{type} // die "Term::Fabulous::Terminal::Memory: push_event needs a type: TB_EVENT_KEY, TB_EVENT_MOUSE or TB_EVENT_RESIZE";
		die "Term::Fabulous::Terminal::Memory: unknown event type '$type'; use TB_EVENT_KEY, TB_EVENT_MOUSE or TB_EVENT_RESIZE"
			unless $type == TB_EVENT_KEY || $type == TB_EVENT_MOUSE || $type == TB_EVENT_RESIZE;
		die "Term::Fabulous::Terminal::Memory: no input can follow end_input" if $_input_has_ended;
		push @_queue, Term::Fabulous::Termbox::Event->new(%fields);
		$self->_wake;
		return $self;
	}

	method type_text ($text) {
		$self->push_event( type => TB_EVENT_KEY, ch => ord $_ ) foreach split //, $text // '';
		return $self;
	}

	method press_key ($name) {
		return $self->push_event( type => TB_EVENT_KEY, Term::Fabulous::Event::KeyPress->fields_for_name($name) );
	}

	method mouse (%fields) {
		return $self->push_event( %fields, type => TB_EVENT_MOUSE );
	}

	# A release names its button, as the input parser reports it.
	method click ( $x, $y ) {
		$self->mouse( key => TB_KEY_MOUSE_LEFT, x => $x, y => $y );
		$self->mouse( key => TB_KEY_MOUSE_RELEASE, x => $x, y => $y, ch => TB_KEY_MOUSE_LEFT );
		return $self;
	}

	method resize ( $new_width, $new_height ) {
		_check_size( width  => $new_width );
		_check_size( height => $new_height );
		return $self->push_event( type => TB_EVENT_RESIZE, w => $new_width, h => $new_height );
	}

	method end_input () {
		$_input_has_ended = 1;
		$self->_wake;
		return $self;
	}

	method _wake () {
		return if $_wakeup_pending;
		syswrite( $_wakeup_write, 'x' ) or die "Term::Fabulous::Terminal::Memory: cannot write its wakeup pipe: $!\n";
		$_wakeup_pending = 1;
		return;
	}

	method lines (%options) {
		my @unknown = grep { $_ ne 'colors' } sort keys %options;
		die "Term::Fabulous::Terminal::Memory: lines does not accept @unknown (known options: colors)" if @unknown;
		return map { $cell_target->row_text( $_, columns => $width, colors => $options{colors} // 0 ) } 0 .. $_rows - 1;
	}

	method cell ( $x, $y ) {
		return $cell_target->cell( $x, $y );
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Terminal::Memory - A terminal in memory, for tests

=head1 SYNOPSIS

	use Test2::V0;
	use Term::Fabulous;
	use Term::Fabulous::Terminal::Memory;
	use Term::Fabulous::Widget::Box;
	use Term::Fabulous::Widget::TextField;

	my $field = Term::Fabulous::Widget::TextField->new( preferred_columns => 10 );
	my $root  = Term::Fabulous::Widget::Box->new;
	$root->add_child($field);

	my $terminal = Term::Fabulous::Terminal::Memory->new( width => 30, height => 2 );
	my $ui       = Term::Fabulous->new( root => $root, width => 30, height => 2, terminal => $terminal );

	$ui->step;                                        # opens the terminal, fires Start, draws a frame
	$terminal->press_key('Tab')->type_text('Ada');    # focus the field and type
	$ui->step;                                        # handles the input as run would, draws

	is $field->value, 'Ada', 'the field holds the text';
	is [ $terminal->lines ], [ 'Ada       ', '' ], 'what the screen shows';
	done_testing;

The text field has a background color, so its ten columns are kept as
spaces in L</lines>. A longer test, with clicks, is in
L<Term::Fabulous::Cookbook::Output/Test a widget without a terminal>.

=head1 DESCRIPTION

A terminal (see L<Term::Fabulous::Role::Terminal>) that exists only in
memory. Give it to L<Term::Fabulous/new> as C<terminal>, queue input
with the methods below, let the application handle it with
L<Term::Fabulous/step> (or L<Term::Fabulous/run>), and read back the
screen with L</lines> and L</cell>.

Input goes through everything that real input goes through: the
focused widget gets the keys, Tab and Shift+Tab move the focus, a click
is hit-tested against the last frame, focuses what it hits and
presses and releases it (C<OnPress>, C<OnRelease>), the wheel scrolls,
and resizes fire C<Resize>. The events are those termbox2 reports for a
real terminal, so key names, mouse buttons and modifiers come out as
they do there.

The screen is a L<Term::Fabulous::Render::Target::Grid>
(L</cell_target>): each frame paints into it as into the terminal. It
starts empty, and it keeps the last frame after the session was closed,
so a test can look at what L<Term::Fabulous/run> left on the screen.

The terminal also records what the application switched on, for the
open session: L</mouse_enabled>, L</inline_rows> and
L</kitty_keyboard_active>.

=head1 CONSTRUCTOR

=head2 new

	my $terminal = Term::Fabulous::Terminal::Memory->new( width => 80, height => 24 );
	my $terminal = Term::Fabulous::Terminal::Memory->new( width => 80, height => 24, kitty_keyboard => 1 );
	my $terminal = Term::Fabulous::Terminal::Memory->new( width => 80, height => 24, sixel_cell_size => [ 10, 20 ] );

C<width> and C<height> are the size of the screen, whole numbers of at
least 1; required. C<kitty_keyboard> says whether the terminal speaks
the kitty keyboard protocol, so that an application that asks for it
gets it; default 0. C<sixel_cell_size>, C<[width, height]> in pixels,
makes it a terminal that shows sixel graphics with cells of that size:
the pictures of L<Term::Fabulous::Widget::Sixel> are recorded, and
L<Term::Fabulous::Render::Target::Grid/sixels> on L</cell_target>
returns those of the last frame. Without it, the default, the terminal
shows no sixel graphics. Unknown parameters die.

=head1 INPUT

Input is queued until the application reads it:
L<C<< $ui->step >>|Term::Fabulous/step> reads all of it, and
L<C<< $ui->run >>|Term::Fabulous/run> watches C<read_handles>
(see L<Term::Fabulous::Role::Terminal/read_handles>), a pipe that is
readable while input waits; on Windows, where C<select> cannot watch a
pipe, it polls C<next_event> instead. Every method returns the
terminal, so calls can be chained. After L</end_input>, queuing more
input dies.

=head2 type_text

	$terminal->type_text('hello');

One key event per character, as typing the text would send.

=head2 press_key

	$terminal->press_key('Enter');
	$terminal->press_key('Ctrl+Shift+Left');
	$terminal->press_key('BackTab');    # Shift+Tab
	$terminal->press_key('Ctrl+C');

One key, by the name L<Term::Fabulous::Event::KeyPress/key_name> gives
it; see L<Term::Fabulous::Event::KeyPress/KEY NAMES>. A name that
C<key_name> never returns dies (see
L<Term::Fabulous::Event::KeyPress/fields_for_name>).

=head2 click

	$terminal->click( $x, $y );

A press and a release of the left mouse button on the cell C<($x, $y)>,
counted from 0 at the top-left of the screen.

=head2 mouse

	use Term::Fabulous::Termbox qw(TB_KEY_MOUSE_WHEEL_DOWN TF_KEY_MOUSE_MOVE TB_MOD_MOTION);

	$terminal->mouse( key => TB_KEY_MOUSE_WHEEL_DOWN, x => 3, y => 1 );
	$terminal->mouse( key => TF_KEY_MOUSE_MOVE, mod => TB_MOD_MOTION, x => 5, y => 2 );

Any other mouse event, with the fields of a
L<Term::Fabulous::Termbox::Event> (C<key>, C<x>, C<y>, C<mod>, C<ch>);
see L<Term::Fabulous::Event::Mouse> for what they mean. Mouse events are
dropped, as a real terminal would not send them, while the session does
not report the mouse (L</mouse_enabled>).

=head2 resize

	$terminal->resize( 100, 30 );

The terminal changes its size. The application applies it when it reads
the event: L<Term::Fabulous/step> at once, L<Term::Fabulous/run> after
its debounce interval. Sizes that are not whole numbers of at least 1
die.

=head2 push_event

	use Term::Fabulous::Termbox qw(TB_EVENT_KEY);

	$terminal->push_event( type => TB_EVENT_KEY, key => 0, ch => ord 'a', mod => 0 );

Any event, with the fields of a L<Term::Fabulous::Termbox::Event>. The
C<type> must be C<TB_EVENT_KEY>, C<TB_EVENT_MOUSE> or
C<TB_EVENT_RESIZE>. Unknown fields die.

=head2 end_input

	$terminal->end_input;

The input ends, as when the real terminal goes away: once the queued
events are read, C<input_ended> is 1, and L<Term::Fabulous/run> and
L<Term::Fabulous/step> die with C<Term::Fabulous: the terminal was
closed>.

=head1 OUTPUT

=head2 lines

	my @lines = $terminal->lines;
	my @lines = $terminal->lines( colors => 1 );

The screen as one character string per row: the rows of the layout
(the screen's height, or the rows of an inline region), as wide as the
screen, with the spaces at the end of a row left out unless they have a
background color. With C<colors> true, the rows carry ANSI color
sequences as L<Term::Fabulous::Render::Target::Grid/row_text> describes;
default 0.

=head2 cell

	my ( $glyph, $fg, $bg ) = @{ $terminal->cell( $x, $y ) // [] };

The cell at C<($x, $y)> as L<Term::Fabulous::Render::Target::Grid/cell>
describes it, or C<undef> when the last frame painted nothing there.

=head2 cell_target

The L<Term::Fabulous::Render::Target::Grid> the frames are painted
into.

=head1 STATE

=head2 width, height

The size of the screen: the constructor's, or the last size a resize
event applied.

=head2 kitty_keyboard

The C<kitty_keyboard> constructor parameter.

=head2 is_open

1 while a session is open.

=head2 session_count

How many sessions were opened so far.

=head2 mouse_enabled

1 while the open session reports the mouse.

=head2 inline_rows

The rows of the inline region of the open session, or C<undef> in
full-screen mode and when no session is open.

=head2 kitty_keyboard_active

1 while the open session uses the kitty keyboard protocol: the
application asked for it and the terminal speaks it
(C<kitty_keyboard>).

=head1 TERMINAL METHODS

The methods of L<Term::Fabulous::Role::Terminal>, called by
L<Term::Fabulous>: C<open> (dies when a session is open already, and on
unknown options), C<close>, C<size>, C<apply_resize>, C<read_handles>,
C<next_event> and C<input_ended>. An inline region starts at the first
row of the screen.

=head1 SEE ALSO

L<Term::Fabulous/step>, L<Term::Fabulous::Manual::Programs/TESTING>,
L<Term::Fabulous::Role::Terminal>, L<Term::Fabulous::Terminal::Termbox>.

=cut
