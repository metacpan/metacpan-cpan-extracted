package Term::Fabulous::Terminal::Termbox;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.03';

use Object::Pad 0.825;

# Loaded first: dies with a clear message when termbox2 lacks truecolor,
# before the TB_OUTPUT_TRUECOLOR import below could fail obscurely.
use Term::Fabulous::Render::Attr ();

use Term::Fabulous::Role::Terminal;
use Term::Fabulous::Terminal::Termbox::Cells;

class Term::Fabulous::Terminal::Termbox :does(Term::Fabulous::Role::Terminal) :strict(params) {
	use Feature::Compat::Try;
	use POSIX qw(EINTR);
	use Scalar::Util qw(openhandle);
	use Term::Fabulous::Termbox qw(
		tb_init tb_init_rwfd tf_init_inline tf_init_inline_rwfd tb_shutdown tb_width tb_height tb_hide_cursor tb_clear
		tb_set_input_mode tb_set_output_mode tb_get_fds tb_peek_event tb_send
		tb_last_errno tb_strerror tf_install_input_parser tf_input_ended
		tf_cursor_position tf_reset_attrs tf_kitty_keyboard_query tf_sixel_query
		TB_OK TB_ERR TB_ERR_NEED_MORE TB_ERR_NO_EVENT TB_ERR_POLL TB_ERR_READ
		TB_INPUT_ESC TB_INPUT_MOUSE TB_OUTPUT_TRUECOLOR
	);
	use Term::Fabulous::Termbox::Event;
	use Term::Fabulous::Unicode qw(terminal_is_utf8);

	# termbox2 sends UTF-8. A terminal shows those bytes in the character
	# set of the locale; the Windows console is switched to UTF-8 by
	# termbox2 itself, whatever the locale says.
	use constant LOCALE_SETS_THE_CHARACTER_SET => $^O ne 'MSWin32';

	# A signal interrupts select on POSIX systems; on Windows no wait is
	# interrupted, and tb_last_errno holds a Win32 error code, not an errno.
	use constant POLL_CAN_BE_INTERRUPTED => $^O ne 'MSWin32';

	# Mouse mode 1003 (any-event tracking) reports the pointer moving with
	# no button held; termbox2 asks only for buttons, drags and the wheel.
	use constant REPORT_MOUSE_MOTION      => "\x1b[?1003h";
	use constant STOP_MOUSE_MOTION_REPORT => "\x1b[?1003l";

	# The kitty keyboard protocol with its flags 1 (disambiguate escape
	# codes) and 4 (report alternate keys), pushed onto the terminal's
	# stack of flags and popped off again.
	use constant PUSH_KITTY_KEYBOARD             => "\x1b[>5u";
	use constant POP_KITTY_KEYBOARD              => "\x1b[<u";
	use constant KITTY_KEYBOARD_QUERY_TIMEOUT_MS => 500;

	use constant CURSOR_REPORT_TIMEOUT_MS => 1000;
	use constant SIXEL_QUERY_TIMEOUT_MS   => 500;
	use constant ERASE_BELOW              => "\x1b[J";

	use constant OPEN_OPTIONS => qw(inline mouse kitty_keyboard);

	# Handles of another terminal to use instead of the controlling one.
	field $input  :param = undef;
	field $output :param = undef;

	field $cell_target           :reader = Term::Fabulous::Terminal::Termbox::Cells->new;
	field $is_open               :reader = 0;
	field $kitty_keyboard_active :reader = 0;
	field $inline;    # the rows asked for, or undef for the full screen
	field $mouse        = 0;
	field $_shows_sixel = 0;
	field @_size;    # the layout's [columns, rows]
	field $_input_fd;    # termbox's terminal input descriptor
	field @_read_handles;    # duplicates of termbox's input descriptors

	ADJUST {
		die "Term::Fabulous::Terminal::Termbox: input and output go together; pass both or neither"
			if defined $input != defined $output;
		foreach my $handle ( grep { defined } $input, $output ) {
			die "Term::Fabulous::Terminal::Termbox: input and output must be open file handles" unless openhandle($handle);
		}
	}

	method open (%options) {
		die "Term::Fabulous::Terminal::Termbox: the terminal is open already" if $is_open;
		my %known   = map  { $_ => 1 } OPEN_OPTIONS;
		my @unknown = grep { !$known{$_} } sort keys %options;
		die "Term::Fabulous::Terminal::Termbox: open does not accept @unknown (known options: " . join( ', ', OPEN_OPTIONS ) . ")" if @unknown;
		die "Term::Fabulous::Terminal::Termbox: inline must be a whole number of rows of at least 1, got '$options{inline}'"
			if defined $options{inline} && $options{inline} !~ /\A[1-9][0-9]*\z/;
		warn "Term::Fabulous::Terminal::Termbox: the locale's character set is not UTF-8; wide characters will be misaligned\n"
			if LOCALE_SETS_THE_CHARACTER_SET && !terminal_is_utf8();

		my ( $init, $rc ) = $self->_init( defined $options{inline} );
		die "Term::Fabulous::Terminal::Termbox: $init failed: " . tb_strerror($rc) . "\n" unless $rc == TB_OK;
		( $is_open, $inline, $mouse ) = ( 1, $options{inline}, $options{mouse} ? 1 : 0 );

		try {
			$self->_prepare( $options{kitty_keyboard} );
		}
		catch ($error) {
			$self->close;
			die $error;
		}
		return;
	}

	method _init ($is_inline) {
		return $is_inline ? ( 'tf_init_inline', tf_init_inline() ) : ( 'tb_init', tb_init() ) unless defined $input;
		my @fds = ( fileno $input, fileno $output );
		return $is_inline ? ( 'tf_init_inline_rwfd', tf_init_inline_rwfd(@fds) ) : ( 'tb_init_rwfd', tb_init_rwfd(@fds) );
	}

	method _prepare ($kitty_keyboard) {
		_check_termbox( 'tb_set_output_mode',      tb_set_output_mode(TB_OUTPUT_TRUECOLOR) );
		_check_termbox( 'tb_set_input_mode',       tb_set_input_mode( TB_INPUT_ESC | ( $mouse ? TB_INPUT_MOUSE : 0 ) ) );
		_check_termbox( 'tf_install_input_parser', tf_install_input_parser() );
		_check_termbox( 'tb_send',                 tb_send(REPORT_MOUSE_MOTION) ) if $mouse;
		$self->_use_kitty_keyboard if $kitty_keyboard;
		_check_termbox( 'tb_hide_cursor', tb_hide_cursor() );

		my ( $width, $height ) = ( tb_width(), tb_height() );
		die "Term::Fabulous::Terminal::Termbox: the terminal reports an unusable size of ${width}x${height}\n"
			if $width < 1 || $height < 1;
		@_size = ( $width, defined $inline ? $self->_anchor_inline_region($height) : $height );
		$self->_detect_sixel;

		_check_termbox( 'tb_get_fds', tb_get_fds( \my $tty_fd, \my $resize_fd ) );
		$_input_fd     = $tty_fd;
		@_read_handles = map { _duplicate_for_reading($_) } grep { $_ >= 0 } $tty_fd, $resize_fd;    # Windows has no resize descriptor
		return;
	}

	method close () {
		return unless $is_open;
		$is_open = 0;
		tb_send(STOP_MOUSE_MOTION_REPORT) if $mouse;    # termbox2 switches off only the modes it switched on
		tb_send(POP_KITTY_KEYBOARD) if $kitty_keyboard_active;    # before termbox2 leaves the alternate screen, which has a stack of its own
		$kitty_keyboard_active = 0;
		$_shows_sixel          = 0;
		$cell_target->set_sixel_cell_size;
		$cell_target->forget_sixels;
		$self->_leave_inline_region if defined $cell_target->region_top;
		CORE::close($_) foreach @_read_handles;
		@_read_handles = ();
		$_input_fd     = undef;
		tb_shutdown();
		return;
	}

	# The safety net for a terminal that is dropped while open, by a program
	# that dies outside Term::Fabulous's run (step leaves the terminal open)
	# or never closes it: the shell gets its screen, modes and input back.
	# No ${^GLOBAL_PHASE} guard, because global destruction is when a
	# file-scoped object goes, and close needs only XS calls and fields.
	method DESTROY {
		$self->close if $is_open;
		return;
	}

	method size () {
		die "Term::Fabulous::Terminal::Termbox: the terminal is not open" unless $is_open;
		return @_size;
	}

	method apply_resize ( $width, $height ) {
		die "Term::Fabulous::Terminal::Termbox: the terminal is not open" unless $is_open;
		@_size = ( $width, defined $inline ? $self->_anchor_inline_region($height) : $height );
		$self->_detect_sixel if $_shows_sixel;    # a new font size changes the cell size
		return @_size;
	}

	method read_handles () {
		return @_read_handles;
	}

	method next_event () {
		my $event = Term::Fabulous::Termbox::Event->new;
		my $rc    = tb_peek_event( $event, 0 );
		return $event if $rc == TB_OK;

		# Nothing buffered, or only the start of a key sequence whose
		# remaining bytes make the descriptor readable again; an
		# interrupted poll leaves it readable, too.
		return undef if $rc == TB_ERR_NO_EVENT || $rc == TB_ERR || $rc == TB_ERR_NEED_MORE;
		return undef if $rc == TB_ERR_POLL && POLL_CAN_BE_INTERRUPTED && tb_last_errno() == EINTR;
		die "Term::Fabulous::Terminal::Termbox: reading terminal input failed: " . tb_strerror($rc) . "\n";
	}

	# After termbox has read all it could, a descriptor that still reports
	# readable with no byte to read is at end of file: the terminal is gone.
	# termbox reports that only as "no event", again and again.
	method input_ended () {
		return 0 unless defined $_input_fd;
		return tf_input_ended($_input_fd);
	}

	# A terminal that does not answer the query does not speak the
	# protocol; the input parser reads the legacy encodings as before.
	method _use_kitty_keyboard () {
		my $rc = tf_kitty_keyboard_query( KITTY_KEYBOARD_QUERY_TIMEOUT_MS, \my $supported );
		return if $rc == TB_ERR_NO_EVENT;
		_check_termbox( 'tf_kitty_keyboard_query', $rc );
		return unless $supported;
		_check_termbox( 'tb_send', tb_send(PUSH_KITTY_KEYBOARD) );
		$kitty_keyboard_active = 1;
		return;
	}

	# A terminal that does not answer shows no sixel; one that does not
	# tell the size of its cells shows none Term::Fabulous could place.
	# Input that cannot be read is no answer either: next_event reports it.
	method _detect_sixel () {
		my $rc = tf_sixel_query( SIXEL_QUERY_TIMEOUT_MS, \my $supported, \my $cell_width, \my $cell_height );
		_check_termbox( 'tf_sixel_query', $rc ) unless $rc == TB_ERR_NO_EVENT || $rc == TB_ERR_READ;
		$_shows_sixel = $rc == TB_OK && $supported ? 1 : 0;
		$cell_target->set_sixel_cell_size( $_shows_sixel && $cell_width > 0 ? ( $cell_width, $cell_height ) : () );
		return;
	}

	# The region starts on the cursor's row, or on the next one when text
	# precedes the cursor there. When it would reach below the screen,
	# the terminal scrolls up first. Its rows are erased, since termbox
	# takes the rows it has not drawn yet for blank.
	method _anchor_inline_region ($screen_height) {
		my $rc = tf_cursor_position( CURSOR_REPORT_TIMEOUT_MS, \my $column, \my $row );
		die "Term::Fabulous::Terminal::Termbox: the terminal did not report its cursor position; inline mode needs a terminal that answers ESC [ 6 n\n"
			if $rc == TB_ERR_NO_EVENT;
		_check_termbox( 'tf_cursor_position', $rc );

		my $rows     = $inline < $screen_height ? $inline : $screen_height;
		my $top      = $column == 0             ? $row    : $row + 1;
		my $overflow = $top + $rows - $screen_height;
		_check_termbox( 'tf_reset_attrs', tf_reset_attrs() );    # scrolled-in and erased rows take the current background
		if ( $overflow > 0 ) {
			_check_termbox( 'tb_send', tb_send( _cursor_to_row( $screen_height - 1 ) . "\n" x $overflow ) );
			$top -= $overflow;
		}
		_check_termbox( 'tb_send',  tb_send( _cursor_to_row($top) . ERASE_BELOW ) );
		_check_termbox( 'tb_clear', tb_clear() );    # cells of an earlier region must not come back at their old rows
		$cell_target->place_region( $top, $rows );
		return $rows;
	}

	# The last frame stays where it is; the shell goes on below it.
	method _leave_inline_region () {
		my $last_row = $cell_target->region_top + $cell_target->region_rows - 1;
		tf_reset_attrs();
		tb_send( _cursor_to_row($last_row) . "\n" );
		$cell_target->place_region( undef, undef );
		return;
	}

	sub _cursor_to_row ($row) {
		return "\x1b[" . ( $row + 1 ) . ";1H";
	}

	sub _check_termbox ( $function, $rc ) {
		die "Term::Fabulous::Terminal::Termbox: $function failed: " . tb_strerror($rc) . "\n" unless $rc == TB_OK;
		return;
	}

	# A watcher may drop its handle; a duplicate keeps termbox's own
	# descriptor open until tb_shutdown().
	sub _duplicate_for_reading ($fd) {
		CORE::open( my $handle, '<&', $fd ) or die "Term::Fabulous::Terminal::Termbox: cannot duplicate file descriptor $fd: $!\n";
		return $handle;
	}
}

1;

__END__

=head1 NAME

Term::Fabulous::Terminal::Termbox - The real terminal, through termbox2

=head1 SYNOPSIS

	use Term::Fabulous;
	use Term::Fabulous::Terminal::Termbox;

	# The default terminal of Term::Fabulous; there is no need to pass it.
	my $ui = Term::Fabulous->new( root => $root, width => 80, height => 24 );

	# Another terminal, for example the slave side of a pseudo terminal.
	my $terminal = Term::Fabulous::Terminal::Termbox->new( input => $tty, output => $tty );
	my $other    = Term::Fabulous->new( root => $other_root, width => 80, height => 24, terminal => $terminal );

=head1 DESCRIPTION

Most programs never use this module directly: it is the terminal
L<Term::Fabulous> uses unless it is given another one. It implements
L<Term::Fabulous::Role::Terminal> with the termbox2 library
(L<Term::Fabulous::Termbox>), and paints through its cell target
L<Term::Fabulous::Terminal::Termbox::Cells>.

When a session is opened (see L</open>), it:

=over

=item *

starts termbox2 in full-screen mode (C<tb_init>, which switches to the
alternate screen) or, in inline mode, without taking over the screen
(C<tf_init_inline>);

=item *

switches to 24-bit colors and to the input parser of
L<Term::Fabulous::Termbox>, which reads Alt combinations, the mouse in
SGR encoding and the kitty keyboard protocol;

=item *

with C<mouse>, asks the terminal for clicks, drags, the wheel and the
pointer moving without a button (mouse mode 1003);

=item *

with C<kitty_keyboard>, asks the terminal whether it speaks the
L<kitty keyboard protocol|https://sw.kovidgoyal.net/kitty/keyboard-protocol/>,
waiting at most half a second for the answer, and if it does, pushes the
flags 1 (disambiguate escape codes) and 4 (report alternate keys);

=item *

hides the cursor;

=item *

in inline mode, asks the terminal for the cursor position (C<ESC [ 6 n>,
at most a second), places the region on the cursor's line or the line
below it, scrolls the terminal up when the region does not fit below,
and erases the region's rows;

=item *

asks the terminal whether it shows sixel graphics and how many pixels
a cell has (C<tf_sixel_query> of L<Term::Fabulous::Termbox>), waiting
at most half a second, and tells its cell target
(L<Term::Fabulous::Terminal::Termbox::Cells/set_sixel_cell_size>), so
that L<Term::Fabulous::Widget::Sixel> can show pictures. A terminal
that does not answer, does not list sixel graphics in its device
attributes or does not tell the size of its cells shows none.

=back

L</close> undoes all of it in reverse: mouse motion reporting off, the
kitty flags popped, the cursor placed below the inline region, and
C<tb_shutdown>.

=head1 CONSTRUCTOR

=head2 new

	my $terminal = Term::Fabulous::Terminal::Termbox->new;
	my $terminal = Term::Fabulous::Terminal::Termbox->new( input => $in, output => $out );

Without parameters, the session uses the controlling terminal
(F</dev/tty>). With C<input> and C<output>, two open file handles, it
reads the terminal's input from the one and writes to the other
(C<tb_init_rwfd> and C<tf_init_inline_rwfd>), for example both the slave
side of a pseudo terminal; the terminal's size is read from C<output>.
They go together: only one of them dies, and so does a handle that is
not open. Nothing is opened until L</open>.

=head1 METHODS

The methods of L<Term::Fabulous::Role::Terminal>. Errors die with
messages that start with C<Term::Fabulous::Terminal::Termbox:>.

=head2 open

	$terminal->open( inline => undef, mouse => 1, kitty_keyboard => 1 );

Starts a session as described above. Unknown options die, and so does
an C<inline> that is not a whole number of rows of at least 1. When
termbox2 cannot start, C<open> dies with the termbox2 error, for
example C<tb_init failed: No such device or address> when the process
has no controlling terminal; when the terminal reports a size of 0
columns or rows, with C<the terminal reports an unusable size>; in
inline mode, when the terminal does not report its cursor position in
time, with C<the terminal did not report its cursor position; inline
mode needs a terminal that answers ESC [ 6 n>. After a failure the
terminal is closed again.

When the locale's character set is not UTF-8, C<open> warns:
C<Term::Fabulous::Terminal::Termbox: the locale's character set is not
UTF-8; wide characters will be misaligned>. termbox2 sends UTF-8, and a
terminal running under another locale shows the bytes of a wide
character as several narrow ones (see
L<Term::Fabulous::Unicode/terminal_is_utf8>). Not on Windows, where
termbox2 switches the console to UTF-8 itself.

=head2 close

	$terminal->close;

Ends the session as described above. Does nothing when no session is
open, so calling it twice is harmless.

A terminal object that is destroyed while its session is open closes
it first, also when the program ends or dies with the object still
around, so a program that drives the terminal itself (with
L<Term::Fabulous/step> or L</open>) and dies never leaves the shell in
raw mode, on the alternate screen or with mouse reporting switched on.
Closing explicitly is still the way to restore the terminal at a moment
of your choosing.

=head2 is_open

1 while a session is open.

=head2 size

	my ( $columns, $rows ) = $terminal->size;

The terminal's size, or in inline mode its width and the rows of the
region: the C<inline> rows, or fewer on a terminal that is not as high.

=head2 apply_resize

	my ( $columns, $rows ) = $terminal->apply_resize( $width, $height );

Takes the size of a resize event. In inline mode it finds the region
again: it asks the terminal where the cursor is (between frames the
hidden cursor waits at the start of the region's first row, and a
terminal that rewraps its lines moves it along), erases from there down
and places the region there. A terminal that shows sixel graphics is
asked for the size of its cells again, which a new font size changes.
Returns the new size, like L</size>.

=head2 read_handles

Duplicates of termbox2's terminal input and resize descriptors, opened
by L</open> and closed by L</close>. On Windows, only the input
descriptor: resizes arrive through it. Perl's C<select> cannot watch a
console there, so L<Term::Fabulous/run> polls L</next_event> instead of
watching the handles; see L<Term::Fabulous/termbox_input_poll_interval>.

=head2 next_event

	my $event = $terminal->next_event;    # Term::Fabulous::Termbox::Event or undef

The next event termbox2 has read (C<tb_peek_event> without waiting), or
C<undef> when there is none yet: nothing buffered, only the beginning
of a key sequence, or an interrupted poll. Any other error dies with
C<reading terminal input failed: ...>.

=head2 input_ended

1 when the terminal input descriptor reports readable but has no byte
to read, or cannot even tell because the terminal hung up (C<EIO>, or
C<ENXIO> on FreeBSD); on Windows, when the console no longer answers or
a pipe lost its writer. The terminal went away; termbox2 reports that
only as "no event", again and again. See
L<Term::Fabulous::Termbox/tf_input_ended>.

=head2 kitty_keyboard_active

1 while the session uses the kitty keyboard protocol.

=head2 cell_target

The L<Term::Fabulous::Terminal::Termbox::Cells> the frames are painted
into.

=head1 WINDOWS

The terminal is the Windows console, through termbox2's console backend
(L<Term::Fabulous::Termbox/WINDOWS>): C<new> without handles opens
C<CONIN$> and C<CONOUT$>, and C<input> and C<output> may be any two
handles, such as the two ends the test suite uses. The console runs in
virtual terminal mode while the session is open, so keys, the mouse and
the terminal queries work as in an xterm; Windows Terminal answers the
cursor position query of inline mode and the device attributes query.
It does not speak the kitty keyboard protocol, so C<kitty_keyboard>
stays off there, and it reports no cell size, so no sixel pictures are
shown. Resizes arrive as input and are read by L</next_event>, which
L<Term::Fabulous/run> polls, since C<select> cannot watch a console.

=head1 SEE ALSO

L<Term::Fabulous>, L<Term::Fabulous::Role::Terminal>,
L<Term::Fabulous::Terminal::Memory>, L<Term::Fabulous::Termbox>.

=cut
