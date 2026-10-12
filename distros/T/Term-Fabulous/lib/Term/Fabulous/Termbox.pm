package Term::Fabulous::Termbox;

use v5.32;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

our $VERSION = '0.02';

use Exporter 'import';
use XSLoader;

our ( @EXPORT_OK, %EXPORT_TAGS );

# The constants and their tags (:keys :colors :event :return) are installed
# by the XS BOOT code; the functions are listed here.
XSLoader::load( __PACKAGE__, $VERSION );

$EXPORT_TAGS{api} = [
	qw(
		tb_init tb_init_file tb_init_fd tb_init_rwfd tf_init_inline tf_init_inline_rwfd tb_shutdown
		tb_width tb_height tb_set_input_mode tb_set_output_mode
		tb_clear tb_set_clear_attrs tb_present tb_invalidate tb_set_cursor tb_hide_cursor
		tb_set_cell tb_set_cell_ex tb_extend_cell tb_get_cell tb_print tb_send tf_reset_attrs tf_flush
		tf_cells_differ tf_invalidate_cells
		tb_peek_event tb_poll_event tb_get_fds tf_install_input_parser tf_cursor_position tf_kitty_keyboard_query
		tf_sixel_query tf_input_ended
		tb_last_errno tb_strerror tb_has_truecolor tb_has_egc tb_attr_width tb_version
	)
];
$EXPORT_TAGS{width} = [qw(tb_iswprint tb_wcwidth tb_cluster_width)];

{
	my %seen;
	@EXPORT_OK = grep { !$seen{$_}++ } map { @$_ } values %EXPORT_TAGS;
}
$EXPORT_TAGS{all} = [@EXPORT_OK];

sub tb_peek_event ( $event, $timeout_ms ) {
	my ( $status, %fields ) = _peek_event($timeout_ms);
	_fill_event( $event, %fields ) if $status == TB_OK();
	return $status;
}

sub tb_poll_event ($event) {
	my ( $status, %fields ) = _poll_event();
	_fill_event( $event, %fields ) if $status == TB_OK();
	return $status;
}

sub _fill_event ( $event, %fields ) {
	$event->$_( $fields{$_} ) foreach keys %fields;
	return;
}

1;

__END__

=encoding UTF-8

=head1 NAME

Term::Fabulous::Termbox - termbox2 compiled into Term::Fabulous

=head1 SYNOPSIS

	use Term::Fabulous::Termbox qw(:api :keys :colors :event :return);
	use Term::Fabulous::Termbox::Event;

	my $rc = tb_init();
	die tb_strerror($rc) unless $rc == TB_OK;
	tb_set_output_mode(TB_OUTPUT_TRUECOLOR);

	tb_set_cell( 0, 0, 'A', 0xFF8800 | TB_BOLD, TB_DEFAULT );
	tb_set_cell( 1, 0, "e\x{301}", TB_DEFAULT, TB_DEFAULT );    # first codepoint ...
	tb_extend_cell( 1, 0, "\x{301}" );                           # ... then the combining mark
	tb_set_cell_ex( 2, 0, "\x{1F1E9}\x{1F1EA}", TB_DEFAULT, TB_DEFAULT );    # or the whole cluster at once
	tb_present();

	my $event = Term::Fabulous::Termbox::Event->new;
	while ( tb_poll_event($event) == TB_OK ) {
		last if $event->type == TB_EVENT_KEY && $event->key == TB_KEY_CTRL_C;
	}
	tb_shutdown();

	use Term::Fabulous::Termbox qw(:width);
	tb_wcwidth(0x4E00);                       # 2
	tb_cluster_width("\x{2764}\x{FE0F}");    # 2: VS16 asks for emoji presentation

=head1 DESCRIPTION

An XS binding of L<termbox2|https://github.com/termbox/termbox2>, compiled
from the header shipped in the distribution (F<src/termbox2.h>, see
F<src/README.termbox2> for the exact upstream commit). Nothing is looked up
at run time, and the compile-time options are fixed:

=over

=item *

C<TB_OPT_ATTR_W> is 64: an attribute carries a 24-bit color and every
style bit, C<TB_STRIKEOUT>, C<TB_UNDERLINE_2>, C<TB_OVERLINE> and
C<TB_INVISIBLE> included. L<tb_attr_width|/"tb_has_truecolor, tb_has_egc, tb_attr_width, tb_version"> reports 64.

=item *

C<TB_OPT_EGC> is set: a cell holds a whole grapheme cluster
(L</tb_extend_cell>, L</tb_set_cell_ex>). L<tb_has_egc|/"tb_has_truecolor, tb_has_egc, tb_attr_width, tb_version"> reports 1.

=item *

termbox2 measures with its own Unicode tables (C<TB_OPT_LIBC_WCHAR> is
not set), so widths are the same on every platform. L</tb_wcwidth> and
L</tb_cluster_width> expose exactly the functions C<tb_present> uses.

=back

The header is upstream's with the patches in F<src/patches> applied,
which teach it the Windows console; see L</WINDOWS> and
F<src/README.termbox2>.

Every function keeps its termbox2 name and returns its status code, C<TB_OK>
or one of the C<TB_ERR_*> constants; nothing dies on a terminal error.
The exceptions are arguments the binding cannot translate at all, such as
an empty string where a character is needed or a string that carries the
UTF8 flag over bytes that are not well-formed UTF-8 (made by
C<Encode::_utf8_on> or read through a C<:utf8> layer), which die before
termbox2 is called.

=head1 EXPORTS

Nothing is exported by default. The tags are

=over

=item C<:api>

The functions below, except the width functions.

=item C<:width>

L</tb_iswprint>, L</tb_wcwidth>, L</tb_cluster_width>.

=item C<:keys>

Every C<TB_KEY_*> constant, plus the Term::Fabulous additions
C<TF_KEY_MOUSE_MOVE>, C<TF_KEY_MOUSE_WHEEL_LEFT> and
C<TF_KEY_MOUSE_WHEEL_RIGHT>, and the keys only the kitty keyboard
protocol reports (see L</tf_install_input_parser> and L</Kitty keys>): the
ASCII control range (C<TB_KEY_CTRL_A> to
C<TB_KEY_CTRL_Z>, C<TB_KEY_TAB>, C<TB_KEY_ENTER>, C<TB_KEY_ESC>,
C<TB_KEY_SPACE>, C<TB_KEY_BACKSPACE>, C<TB_KEY_BACKSPACE2>, ...), the
function and navigation keys (C<TB_KEY_F1> to C<TB_KEY_F12>,
C<TB_KEY_ARROW_*>, C<TB_KEY_HOME>, C<TB_KEY_END>, C<TB_KEY_PGUP>,
C<TB_KEY_PGDN>, C<TB_KEY_INSERT>, C<TB_KEY_DELETE>, C<TB_KEY_BACK_TAB>) and
the mouse "keys" (C<TB_KEY_MOUSE_LEFT>, C<TB_KEY_MOUSE_RIGHT>,
C<TB_KEY_MOUSE_MIDDLE>, C<TB_KEY_MOUSE_RELEASE>, C<TB_KEY_MOUSE_WHEEL_UP>,
C<TB_KEY_MOUSE_WHEEL_DOWN>).

=item C<:colors>

C<TB_DEFAULT>, the eight basic colors C<TB_BLACK> to C<TB_WHITE>, and the
style bits C<TB_BOLD>, C<TB_UNDERLINE>, C<TB_REVERSE>, C<TB_ITALIC>,
C<TB_BLINK>, C<TB_HI_BLACK>, C<TB_BRIGHT>, C<TB_DIM>, C<TB_STRIKEOUT>,
C<TB_UNDERLINE_2>, C<TB_OVERLINE>, C<TB_INVISIBLE>. In truecolor mode the
low 24 bits of an attribute are the RGB value; since C<0x000000> means
"terminal default" there, opaque black is C<TB_HI_BLACK>. The deprecated
aliases C<TB_TRUECOLOR_BOLD>, C<TB_TRUECOLOR_UNDERLINE>,
C<TB_TRUECOLOR_REVERSE>, C<TB_TRUECOLOR_ITALIC>, C<TB_TRUECOLOR_BLINK>,
C<TB_TRUECOLOR_BLACK> are exported too.

=item C<:event>

C<TB_EVENT_KEY>, C<TB_EVENT_RESIZE>, C<TB_EVENT_MOUSE>; the modifiers
C<TB_MOD_ALT>, C<TB_MOD_CTRL>, C<TB_MOD_SHIFT>, C<TB_MOD_MOTION>, and the
Term::Fabulous additions C<TF_MOD_SUPER>, C<TF_MOD_HYPER>, C<TF_MOD_META>
(16, 32, 64; only the kitty keyboard protocol reports them); the input
modes C<TB_INPUT_CURRENT>, C<TB_INPUT_ESC>, C<TB_INPUT_ALT>,
C<TB_INPUT_MOUSE>; the output modes C<TB_OUTPUT_CURRENT>,
C<TB_OUTPUT_NORMAL>, C<TB_OUTPUT_256>, C<TB_OUTPUT_216>,
C<TB_OUTPUT_GRAYSCALE>, C<TB_OUTPUT_TRUECOLOR>.

=item C<:return>

C<TB_OK> and every C<TB_ERR_*> code, L<tb_strerror|/"tb_last_errno, tb_strerror"> names them.

=item C<:all>

Everything.

=back

=head2 Kitty keys

The keys of the kitty keyboard protocol's functional key table that
neither termbox2 nor the legacy encodings have a code for, numbered
from C<0xFFFF - 32> down in the order of kitty's table:
C<TF_KEY_CAPS_LOCK>, C<TF_KEY_SCROLL_LOCK>, C<TF_KEY_NUM_LOCK>,
C<TF_KEY_PRINT_SCREEN>, C<TF_KEY_PAUSE>, C<TF_KEY_MENU>; C<TF_KEY_F13>
to C<TF_KEY_F35>; the keypad keys C<TF_KEY_KP_0> to C<TF_KEY_KP_9>,
C<TF_KEY_KP_DECIMAL>, C<TF_KEY_KP_DIVIDE>, C<TF_KEY_KP_MULTIPLY>,
C<TF_KEY_KP_SUBTRACT>, C<TF_KEY_KP_ADD>, C<TF_KEY_KP_ENTER>,
C<TF_KEY_KP_EQUAL>, C<TF_KEY_KP_SEPARATOR>, C<TF_KEY_KP_LEFT>,
C<TF_KEY_KP_RIGHT>, C<TF_KEY_KP_UP>, C<TF_KEY_KP_DOWN>,
C<TF_KEY_KP_PAGE_UP>, C<TF_KEY_KP_PAGE_DOWN>, C<TF_KEY_KP_HOME>,
C<TF_KEY_KP_END>, C<TF_KEY_KP_INSERT>, C<TF_KEY_KP_DELETE>,
C<TF_KEY_KP_BEGIN>; and the media keys C<TF_KEY_MEDIA_PLAY>,
C<TF_KEY_MEDIA_PAUSE>, C<TF_KEY_MEDIA_PLAY_PAUSE>,
C<TF_KEY_MEDIA_REVERSE>, C<TF_KEY_MEDIA_STOP>,
C<TF_KEY_MEDIA_FAST_FORWARD>, C<TF_KEY_MEDIA_REWIND>,
C<TF_KEY_MEDIA_TRACK_NEXT>, C<TF_KEY_MEDIA_TRACK_PREVIOUS>,
C<TF_KEY_MEDIA_RECORD>, C<TF_KEY_LOWER_VOLUME>,
C<TF_KEY_RAISE_VOLUME>, C<TF_KEY_MUTE_VOLUME>. They are exported with
C<:keys>.

=head1 FUNCTIONS

=head2 Lifecycle

=head3 tb_init, tb_init_file, tb_init_fd, tb_init_rwfd

	my $rc = tb_init();
	my $rc = tb_init_file('/dev/tty');
	my $rc = tb_init_fd($ttyfd);
	my $rc = tb_init_rwfd( $rfd, $wfd );

Open the terminal. C<tb_init> uses F</dev/tty>; C<tb_init_rwfd> reads
the terminal from one file descriptor and writes to another, which may
be a pipe or a file as well. On Windows, C<tb_init> opens the console
(C<CONIN$> and C<CONOUT$>), and C<tb_init_rwfd> takes the descriptors
C<fileno> returns; see L</WINDOWS>.

=head3 tf_init_inline, tf_init_inline_rwfd

	my $rc = tf_init_inline();
	my $rc = tf_init_inline_rwfd( $rfd, $wfd );

A Term::Fabulous addition: open the terminal like C<tb_init> and
C<tb_init_rwfd>, but without taking over the screen. termbox2 then
neither switches to the alternate screen nor clears the screen, not
when it starts, not on a resize and not in C<tb_shutdown>, so what the
terminal showed before stays. The cell buffers still cover the whole
terminal and C<tb_present> still places cells at absolute positions:
the caller paints only the rows it owns (see L</tf_cursor_position>)
and leaves the others as C<tb_clear> left them, so that C<tb_present>
sends nothing for them. The C<inline> parameter of L<Term::Fabulous/new>
is built on this.

=head3 tb_shutdown

Restores the terminal.

=head3 tb_width, tb_height

The terminal size in cells, or C<TB_ERR_NOT_INIT> before L<tb_init|/"tb_init, tb_init_file, tb_init_fd, tb_init_rwfd">.

=head3 tb_set_input_mode, tb_set_output_mode

	tb_set_input_mode( TB_INPUT_ESC | TB_INPUT_MOUSE );
	tb_set_output_mode(TB_OUTPUT_TRUECOLOR);

=head2 Drawing

=head3 tb_clear, tb_set_clear_attrs, tb_present, tb_invalidate

As in termbox2: C<tb_clear> fills the back buffer with the clear
attributes, C<tb_present> sends the changed cells, C<tb_invalidate> forces
a full redraw on the next C<tb_present>.

=head3 tb_set_cursor, tb_hide_cursor

	tb_set_cursor( $x, $y );
	tb_hide_cursor();

Show the terminal cursor at cell (C<$x>, C<$y>), or hide it. Both return
C<TB_OK> or an error code; the change shows with the next C<tb_present>.

=head3 tb_set_cell

	tb_set_cell( $x, $y, $character, $fg, $bg );

Writes one cell. C<$character> is a Perl string whose first codepoint is
used; an integer that was never a string is taken as the codepoint itself.
An empty string or malformed UTF-8 dies.

=head3 tb_extend_cell

	tb_extend_cell( $x, $y, $character );

Appends the first codepoint of C<$character> to the cell's grapheme
cluster. An empty string or malformed UTF-8 dies.

=head3 tb_set_cell_ex

	tb_set_cell_ex( $x, $y, $cluster, $fg, $bg );

Writes a whole grapheme cluster at once: every codepoint of C<$cluster>.
An empty string or malformed UTF-8 dies.

=head3 tb_get_cell

	my ( $rc, $text, $fg, $bg ) = tb_get_cell( $x, $y, $back );

Reads a cell from the back (C<$back> true) or front buffer. C<$text> is the
cell's cluster as a string. Only C<$rc> is returned unless it is C<TB_OK>.

=head3 tb_print

	tb_print( $x, $y, $fg, $bg, $text );

Writes a string cell by cell, advancing by each cluster's width.

=head3 tb_send

	tb_send($bytes);

Queues bytes for the terminal, for escape sequences termbox2 has no
function for. A string whose characters are all below 0x100 is sent
byte for byte, whether or not Perl stores it UTF-8 encoded; a string
with a wider character is sent UTF-8 encoded. Like everything termbox2
writes, the bytes stay in its output buffer until the next
C<tb_present> or C<tb_shutdown>.

=head3 tf_reset_attrs

	my $rc = tf_reset_attrs();

A Term::Fabulous addition. Queues the reset of all colors and styles
(C<SGR 0>), for escape sequences sent with L</tb_send> that depend on
them, such as erasing (it uses the current background color). The next
cell C<tb_present> draws sets its colors again, which termbox2 would
otherwise skip when it believes the terminal still has them.

=head3 tf_flush

	my $rc = tf_flush();

A Term::Fabulous addition. Writes what L</tb_send> and the drawing
functions queued, without waiting for the next C<tb_present>.

=head3 tf_cells_differ

	my $rc = tf_cells_differ( $x, $y, $width, $height, \my $differ );

A Term::Fabulous addition. Sets C<$differ> to 1 when the next
C<tb_present> would draw a cell of the rectangle, because the cell was
set to something other than what the terminal shows, else to 0. The
part of the rectangle outside the screen is ignored. Returns C<TB_OK>
or an error; C<$differ> is untouched unless the result is C<TB_OK>.
Dies unless the last argument is a scalar reference.

=head3 tf_invalidate_cells

	my $rc = tf_invalidate_cells( $x, $y, $width, $height );

A Term::Fabulous addition. Makes the next C<tb_present> draw every
cell of the rectangle, like C<tb_invalidate> does for the whole screen:
for cells the terminal shows differently from what termbox2 believes,
such as the cells a sixel image covered. The part of the rectangle
outside the screen is ignored.

=head2 Events

=head3 tb_peek_event

	my $rc = tb_peek_event( $event, $timeout_ms );

Waits up to C<$timeout_ms> for an event and fills C<$event>, a
L<Term::Fabulous::Termbox::Event>, in place. Returns C<TB_OK>,
C<TB_ERR_NO_EVENT> after the timeout, or an error. C<$event> is untouched
unless the result is C<TB_OK>.

=head3 tb_poll_event

	my $rc = tb_poll_event($event);

Like L</tb_peek_event> without a timeout.

=head3 tf_install_input_parser

	my $rc = tf_install_input_parser();

A Term::Fabulous addition. Installs a reader that runs before termbox2's
own escape sequence parsers and decodes what they get wrong: Escape
followed by a key in the same read becomes that key with C<TB_MOD_ALT>
(Alt+x, Alt+Enter, Alt plus an umlaut), and SGR mouse reports keep
their modifier bits (C<TB_MOD_SHIFT>, C<TB_MOD_ALT>, C<TB_MOD_CTRL>),
report the pointer moving with no button as C<TF_KEY_MOUSE_MOVE> with
C<TB_MOD_MOTION>, and report a horizontal wheel as
C<TF_KEY_MOUSE_WHEEL_LEFT> and C<TF_KEY_MOUSE_WHEEL_RIGHT>, and say
which button a C<TB_KEY_MOUSE_RELEASE> released: the event's C<ch> is
C<TB_KEY_MOUSE_LEFT>, C<TB_KEY_MOUSE_MIDDLE> or C<TB_KEY_MOUSE_RIGHT>
(0 when the terminal did not name the button, as in reports termbox2
decodes itself). Escape
sequences that begin with C<ESC [> or C<ESC O> and are not SGR mouse
reports are left to termbox2. C<tb_shutdown> forgets the parser, so
call this after every C<tb_init>. Returns C<TB_OK>.

It also decodes the key reports of the
L<kitty keyboard protocol|https://sw.kovidgoyal.net/kitty/keyboard-protocol/>,
C<ESC [ code ; modifiers u>, and the legacy forms of the function keys,
C<ESC [ number ; modifiers ~> and C<ESC [ 1 ; modifiers letter>, when
they carry modifiers. kitty's Super, Hyper and Meta become
C<TF_MOD_SUPER>, C<TF_MOD_HYPER> and C<TF_MOD_META>; Caps Lock and Num
Lock are dropped. The keys come as termbox2 would report them from a
legacy terminal wherever that report is exact, so code written for
termbox2 keeps working:

=over

=item *

Escape is C<TB_KEY_ESC>; Enter, Tab and Backspace without Ctrl are
their control byte with C<TB_MOD_CTRL>, as termbox2 reports the bytes;
Shift+Tab is C<TB_KEY_BACK_TAB>.

=item *

Ctrl plus a letter, Space, C<\> or C<]> is its control byte (Ctrl+C is
C<TB_KEY_CTRL_C>), with C<TB_MOD_SHIFT> and the other modifiers added
when they were held.

=item *

What the legacy encoding cannot carry has its character in C<ch>
instead, with exact modifiers: Ctrl plus Enter, Tab, Backspace or
Escape (C<ch> is the control byte), and Ctrl plus a key whose control
byte is another key's or that has none (Ctrl+I, Ctrl+M, Ctrl+H, Ctrl+[,
Ctrl+1, ...; C<ch> is the unshifted character).

=item *

Alt, Super, Hyper or Meta plus a key without Ctrl is the character
Shift makes in C<ch>, without C<TB_MOD_SHIFT>, like Alt plus a key from
a legacy terminal: Alt+Shift+1 is C<!> with C<TB_MOD_ALT> when the
terminal reports the shifted key (kitty's "report alternate keys"
flag), and Alt+Shift+a is C<A> either way.

=item *

The keys without a legacy encoding are the L</Kitty keys>.

=back

kitty sends these reports for the keys that have no legacy encoding
even to programs that did not ask for the protocol. For the others,
ask the terminal with C<< tb_send("\e[>5u") >> after
L</tf_kitty_keyboard_query> found it supported, and send C<"\e[<u">
before C<tb_shutdown>, as L<Term::Fabulous> does.

The parser only decodes; to receive motion reports at all, ask the
terminal with C<< tb_send("\e[?1003h") >> (and send C<"\e[?1003l">
before C<tb_shutdown>), as L<Term::Fabulous> does.

=head3 tf_cursor_position

	my $rc = tf_cursor_position( $timeout_ms, \my $x, \my $y );

A Term::Fabulous addition. Asks the terminal where its cursor is
(C<ESC [ 6 n>), waits up to C<$timeout_ms> milliseconds for the answer
and stores the column and the row, counted from 0, through the
references. Input that arrives meanwhile, such as keys typed ahead,
stays queued for L</tb_peek_event>; it is read already, so the
terminal descriptor no longer reports it as readable. Returns
C<TB_OK>, C<TB_ERR_NO_EVENT> when no answer arrived in time, or
another error; the references are untouched unless the result is
C<TB_OK>. Dies unless both references are scalar references.

=head3 tf_kitty_keyboard_query

	my $rc = tf_kitty_keyboard_query( $timeout_ms, \my $supported );

A Term::Fabulous addition. Asks the terminal whether it speaks the
L<kitty keyboard protocol|https://sw.kovidgoyal.net/kitty/keyboard-protocol/>:
it sends the query for the protocol's flags (C<ESC [ ? u>) followed by
the one for the primary device attributes (C<ESC [ c>), which every
terminal answers, and waits up to C<$timeout_ms> milliseconds for
that answer. C<$supported> is then 1 when the terminal reported its
flags, 0 when it answered the device attributes alone. Both answers
are taken out of the input; keys that arrive meanwhile stay queued for
L</tb_peek_event>, as with L</tf_cursor_position>. Returns C<TB_OK>,
C<TB_ERR_NO_EVENT> when no answer arrived in time (the terminal is
taken not to speak the protocol), or another error; C<$supported> is
untouched unless the result is C<TB_OK>. Dies unless the argument is
a scalar reference.

=head3 tf_sixel_query

	my $rc = tf_sixel_query( $timeout_ms, \my $supported, \my $cell_width, \my $cell_height );

A Term::Fabulous addition. Asks the terminal whether it shows sixel
graphics and how many pixels a cell has: it sends the query for the
size of a cell (C<ESC [ 16 t>) followed by the one for the primary
device attributes (C<ESC [ c>), which every terminal answers, and
waits up to C<$timeout_ms> milliseconds for that answer. C<$supported>
is then 1 when the device attributes list C<4> (sixel graphics), else
0. C<$cell_width> and C<$cell_height> are the pixels of a cell the
terminal reported, else the ones the window size of the terminal
device gives (C<ioctl TIOCGWINSZ>), else both 0. Both answers are
taken out of the input; keys that arrive meanwhile stay queued for
L</tb_peek_event>, as with L</tf_cursor_position>. Returns C<TB_OK>,
C<TB_ERR_NO_EVENT> when no device attributes arrived in time, or
another error; the references are untouched unless the result is
C<TB_OK>. Dies unless the last three arguments are scalar references.

=head3 tf_input_ended

	my $ended = tf_input_ended($fd);

A Term::Fabulous addition. 1 when the input descriptor has ended for
good: it reports readable but has no byte to read (C<ioctl FIONREAD>),
or cannot even tell because the terminal hung up (C<EIO>, or C<ENXIO>
on FreeBSD); on Windows, when a console no longer answers, a pipe has
lost its writer or a file is at its end. Otherwise 0. termbox2 itself
reports the end of the input only as C<TB_ERR_NO_EVENT>, again and
again. Works with any descriptor, before C<tb_init> and after
C<tb_shutdown> too.

=head3 tb_get_fds

	my $rc = tb_get_fds( \my $tty_fd, \my $resize_fd );

Stores termbox2's tty and resize-pipe descriptors through the references,
for an event loop that waits on them itself. Dies unless both arguments
are scalar references. On Windows the resize descriptor is -1: resizes
arrive as console input, and the console descriptor cannot be waited on
with C<select> anyway, so poll L</tb_peek_event> instead.

=head2 Widths

=head3 tb_iswprint

	my $printable = tb_iswprint($codepoint);

=head3 tb_wcwidth

	my $columns = tb_wcwidth($codepoint);

The columns one codepoint takes: 0, 1, 2, or -1 for a codepoint that is
not printable.

=head3 tb_cluster_width

	my $columns = tb_cluster_width($cluster);

The columns a grapheme cluster takes, measured the way C<tb_present> does:
the widest codepoint's width, forced to 1 when the cluster holds a
variation selector 15 (text presentation) and to 2 when it holds a
variation selector 16 (emoji presentation), a zero-width joiner or two
regional indicators. Clusters below width 1 still occupy one cell when
drawn. Dies on an empty string or malformed UTF-8.

=head2 Diagnostics

=head3 tb_last_errno, tb_strerror

	my $message = tb_strerror($rc);

=head3 tb_has_truecolor, tb_has_egc, tb_attr_width, tb_version

Report the compile-time options: 1, 1, 64 and the termbox2 version string.

=head1 WINDOWS

The patches in F<src/patches> give termbox2 a Windows console backend
(see F<src/README.termbox2>). While termbox2 is initialized, the console
runs in virtual terminal mode: the console turns the keys into the
escape sequences an xterm sends, which termbox2 and
L</tf_install_input_parser> read as on any other system, and it
interprets the escape sequences termbox2 writes. Both directions use
UTF-8; the console's code pages and modes are restored by
C<tb_shutdown>. Window size changes arrive as console input and become
C<TB_EVENT_RESIZE> events; the console also reports its size once right
after it is opened. The mouse is reported while C<tb_set_input_mode>
has C<TB_INPUT_MOUSE> set: a terminal that encodes the mouse itself
(Windows Terminal) sends SGR reports like any xterm, a legacy console
window delivers mouse records, which the backend turns into the same
SGR reports. The built-in capabilities of C<xterm-256color> are used
unless C<TERM> is set; there is no terminfo database to read.

C<TB_ERR_*> codes and C<tb_strerror> work as elsewhere; the message of
a failed system call comes from Windows (L<tb_last_errno|/"tb_last_errno, tb_strerror">
then holds a Win32 error code). A pipe given to C<tb_init_rwfd> is
polled every few milliseconds while termbox2 waits for input.

=head1 NOT BOUND

C<tb_printf>, C<tb_sendf> and C<tb_printf_ex> (variadic; format in Perl and
use L</tb_print> or L</tb_send>), the deprecated C<tb_set_func> and
C<tb_cell_buffer> (use L</tb_get_cell>), and the C<tb_utf8_*> helpers
(Perl strings are already Unicode).

=head1 SEE ALSO

L<Term::Fabulous::Termbox::Event>, L<Term::Fabulous>,
L<termbox2|https://github.com/termbox/termbox2>.

=head1 AUTHOR

davenonymous <perl@davenonymous.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2026 davenonymous

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

termbox2 is Copyright (c) 2015-2026 Adam Saponara and 2010-2020 nsf, and
distributed under the MIT license; see the header of F<src/termbox2.h>.

=cut
