package Termbox {
    use 5.020;
    use strict;
    use warnings;
    our $VERSION = "2.00";
    #
    use File::ShareDir        qw[dist_dir];
    use File::Spec::Functions qw[catdir canonpath];
    #
    use FFI::CheckLib;
    use FFI::Platypus 2;
    use FFI::Platypus::Memory qw( malloc free );
    $ENV{FFI_PLATYPUS_DLERROR} = 1;
    my $ffi = FFI::Platypus->new(
        api  => 1,
        lang => 'C',
        lib  => find_lib_or_exit(
            lib       => 'termbox2',
            recursive => 1,
            libpath   => [ qw[ . ./share/lib], canonpath( catdir( dist_dir(__PACKAGE__), 'lib' ) ) ]
        )
    );
    #
    use base qw[Exporter];
    use vars qw[@EXPORT_OK @EXPORT %EXPORT_TAGS];

    # Utility functions that should be at the end but we need it here
    $ffi->attach( tb_has_truecolor => ['void'] => 'int' );
    $ffi->attach( tb_has_egc       => ['void'] => 'int' );
    #
    our $TRUECOLOR  = tb_has_truecolor();
    our $uintattr_t = $TRUECOLOR ? 'uint32_t' : 'uint16_t';
    #
    $EXPORT_TAGS{api} = [
        qw[
            tb_init tb_init_file tb_init_fd tb_init_rwfd tb_shutdown
            tb_width tb_height
            tb_clear tb_set_clear_attrs
            tb_present
            tb_invalidate
            tb_set_cursor tb_hide_cursor
            tb_set_cell tb_set_cell_ex tb_extend_cell
            tb_set_input_mode
            tb_set_output_mode
            tb_peek_event
            tb_poll_event
            tb_get_fds
            tb_print
            tb_send
            tb_set_func
            tb_utf8_char_length tb_utf8_char_to_unicode tb_utf8_unicode_to_char
            tb_last_errno tb_strerror
            tb_cell_buffer
            tb_has_truecolor tb_has_egc
            tb_version
        ]
    ];
    #
    sub _export ($$) {
        my ( $tag, $values ) = @_;
        push @{ $EXPORT_TAGS{$tag} }, keys %$values;
        no strict 'refs';
        for my $key ( keys %$values ) {
            *{ __PACKAGE__ . '::' . $key } = sub () { $values->{$key} }
        }
    }
    #
    _export keys => {

        # Terminal-dependent key constants (tb_event.key) and terminfo capabilities
        TB_KEY_F1               => ( 0xFFFF - 0 ),
        TB_KEY_F2               => ( 0xFFFF - 1 ),
        TB_KEY_F3               => ( 0xFFFF - 2 ),
        TB_KEY_F4               => ( 0xFFFF - 3 ),
        TB_KEY_F5               => ( 0xFFFF - 4 ),
        TB_KEY_F6               => ( 0xFFFF - 5 ),
        TB_KEY_F7               => ( 0xFFFF - 6 ),
        TB_KEY_F8               => ( 0xFFFF - 7 ),
        TB_KEY_F9               => ( 0xFFFF - 8 ),
        TB_KEY_F10              => ( 0xFFFF - 9 ),
        TB_KEY_F11              => ( 0xFFFF - 10 ),
        TB_KEY_F12              => ( 0xFFFF - 11 ),
        TB_KEY_INSERT           => ( 0xFFFF - 12 ),
        TB_KEY_DELETE           => ( 0xFFFF - 13 ),
        TB_KEY_HOME             => ( 0xFFFF - 14 ),
        TB_KEY_END              => ( 0xFFFF - 15 ),
        TB_KEY_PGUP             => ( 0xFFFF - 16 ),
        TB_KEY_PGDN             => ( 0xFFFF - 17 ),
        TB_KEY_ARROW_UP         => ( 0xFFFF - 18 ),
        TB_KEY_ARROW_DOWN       => ( 0xFFFF - 19 ),
        TB_KEY_ARROW_LEFT       => ( 0xFFFF - 20 ),
        TB_KEY_ARROW_RIGHT      => ( 0xFFFF - 21 ),
        TB_KEY_BACK_TAB         => ( 0xffff - 22 ),
        TB_KEY_MOUSE_LEFT       => ( 0xffff - 23 ),
        TB_KEY_MOUSE_RIGHT      => ( 0xffff - 24 ),
        TB_KEY_MOUSE_MIDDLE     => ( 0xffff - 25 ),
        TB_KEY_MOUSE_RELEASE    => ( 0xffff - 26 ),
        TB_KEY_MOUSE_WHEEL_UP   => ( 0xffff - 27 ),
        TB_KEY_MOUSE_WHEEL_DOWN => ( 0xffff - 28 ),
        #
        TB_CAP_F1           => 0,
        TB_CAP_F2           => 1,
        TB_CAP_F3           => 2,
        TB_CAP_F4           => 3,
        TB_CAP_F5           => 4,
        TB_CAP_F6           => 5,
        TB_CAP_F7           => 6,
        TB_CAP_F8           => 7,
        TB_CAP_F9           => 8,
        TB_CAP_F10          => 9,
        TB_CAP_F11          => 10,
        TB_CAP_F12          => 11,
        TB_CAP_INSERT       => 12,
        TB_CAP_DELETE       => 13,
        TB_CAP_HOME         => 14,
        TB_CAP_END          => 15,
        TB_CAP_PGUP         => 16,
        TB_CAP_PGDN         => 17,
        TB_CAP_ARROW_UP     => 18,
        TB_CAP_ARROW_DOWN   => 19,
        TB_CAP_ARROW_LEFT   => 20,
        TB_CAP_ARROW_RIGHT  => 21,
        TB_CAP_BACK_TAB     => 22,
        TB_CAP__COUNT_KEYS  => 23,
        TB_CAP_ENTER_CA     => 23,
        TB_CAP_EXIT_CA      => 24,
        TB_CAP_SHOW_CURSOR  => 25,
        TB_CAP_HIDE_CURSOR  => 26,
        TB_CAP_CLEAR_SCREEN => 27,
        TB_CAP_SGR0         => 28,
        TB_CAP_UNDERLINE    => 29,
        TB_CAP_BOLD         => 30,
        TB_CAP_BLINK        => 31,
        TB_CAP_ITALIC       => 32,
        TB_CAP_REVERSE      => 33,
        TB_CAP_ENTER_KEYPAD => 34,
        TB_CAP_EXIT_KEYPAD  => 35,
        TB_CAP__COUNT       => 36
    };
    _export colors => {
        TB_DEFAULT   => 0x0000,
        TB_BLACK     => 0x0001,
        TB_RED       => 0x0002,
        TB_GREEN     => 0x0003,
        TB_YELLOW    => 0x0004,
        TB_BLUE      => 0x0005,
        TB_MAGENTA   => 0x0006,
        TB_CYAN      => 0x0007,
        TB_WHITE     => 0x0008,
        TB_BOLD      => 0x0100,
        TB_UNDERLINE => 0x0200,
        TB_REVERSE   => 0x0400,
        TB_ITALIC    => 0x0800,
        TB_BLINK     => 0x1000,
        TB_256_BLACK => 0x2000, (
            $TRUECOLOR ? (
                TB_TRUECOLOR_BOLD      => 0x01000000,
                TB_TRUECOLOR_UNDERLINE => 0x02000000,
                TB_TRUECOLOR_REVERSE   => 0x04000000,
                TB_TRUECOLOR_ITALIC    => 0x08000000,
                TB_TRUECOLOR_BLINK     => 0x10000000,
                TB_TRUECOLOR_BLACK     => 0x20000000,
                ) :
                ()
        )
    };
    _export event => {

        #~ Event types (tb_event.type)
        TB_EVENT_KEY    => 1,
        TB_EVENT_RESIZE => 2,
        TB_EVENT_MOUSE  => 3,

        #~ Key modifiers (bitwise) (tb_event.mod)
        TB_MOD_ALT    => 1,
        TB_MOD_CTRL   => 2,
        TB_MOD_SHIFT  => 4,
        TB_MOD_MOTION => 8,

        #~ Input modes (bitwise) (tb_set_input_mode)
        TB_INPUT_CURRENT => 0,
        TB_INPUT_ESC     => 1,
        TB_INPUT_ALT     => 2,
        TB_INPUT_MOUSE   => 4,

        #~ Output modes (tb_set_output_mode)
        TB_OUTPUT_CURRENT   => 0,
        TB_OUTPUT_NORMAL    => 1,
        TB_OUTPUT_256       => 2,
        TB_OUTPUT_216       => 3,
        TB_OUTPUT_GRAYSCALE => 4,
        ( $TRUECOLOR ? ( TB_OUTPUT_TRUECOLOR => 5 ) : () )
    };
    _export return => {
        TB_OK                   => 0,
        TB_ERR                  => -1,
        TB_ERR_NEED_MORE        => -2,
        TB_ERR_INIT_ALREADY     => -3,
        TB_ERR_INIT_OPEN        => -4,
        TB_ERR_MEM              => -5,
        TB_ERR_NO_EVENT         => -6,
        TB_ERR_NO_TERM          => -7,
        TB_ERR_NOT_INIT         => -8,
        TB_ERR_OUT_OF_BOUNDS    => -9,
        TB_ERR_READ             => -10,
        TB_ERR_RESIZE_IOCTL     => -11,
        TB_ERR_RESIZE_PIPE      => -12,
        TB_ERR_RESIZE_SIGACTION => -13,
        TB_ERR_POLL             => -14,
        TB_ERR_TCGETATTR        => -15,
        TB_ERR_TCSETATTR        => -16,
        TB_ERR_UNSUPPORTED_TERM => -17,
        TB_ERR_RESIZE_WRITE     => -18,
        TB_ERR_RESIZE_POLL      => -19,
        TB_ERR_RESIZE_READ      => -20,
        TB_ERR_RESIZE_SSCANF    => -21,
        TB_ERR_CAP_COLLISION    => -22
    };
    _export return =>
        { TB_ERR_SELECT => TB_ERR_POLL(), TB_ERR_RESIZE_SELECT => TB_ERR_RESIZE_POLL() };
    _export func => { TB_FUNC_EXTRACT_PRE => 0, TB_FUNC_EXTRACT_POST => 1 };
    #
    @EXPORT_OK          = sort map { @$_ = sort @$_; @$_ } values %EXPORT_TAGS;
    $EXPORT_TAGS{'all'} = \@EXPORT_OK;    # When you want to import everything

    #
    package                               #
        Termbox::Cell {
        use FFI::Platypus::Record;
        record_layout_1(
            uint32_t             => 'ch',
            $Termbox::uintattr_t => 'fg',
            $Termbox::uintattr_t => 'bg', (
                Termbox::tb_has_egc() ? ( 'opaque' => 'ech', size_t => 'nech', size_t => 'cech' ) :
                    ()
            )
        );
        };
    $ffi->type('record(Termbox::Cell)');
    #
    package    #
        Termbox::Event {
        use FFI::Platypus::Record;
        record_layout_1(
            qw[
                uint8_t  type
                uint8_t  mod
                uint16_t key
                uint32_t ch
                int32_t  w
                int32_t  h
                int32_t  x
                int32_t  y
            ]
        );
        };
    #
    $ffi->type('record(Termbox::Event)');
    #
    $ffi->attach( tb_init      => ['void']         => 'int' );
    $ffi->attach( tb_init_file => ['string']       => 'int' );
    $ffi->attach( tb_init_fd   => ['int']          => 'int' );
    $ffi->attach( tb_init_rwfd => [ 'int', 'int' ] => 'int' );
    $ffi->attach( tb_shutdown  => ['void']         => 'void' );
    #
    $ffi->attach( tb_width  => ['void'] => 'int' );
    $ffi->attach( tb_height => ['void'] => 'int' );
    #
    $ffi->attach( tb_clear           => ['void']                     => 'void' );
    $ffi->attach( tb_set_clear_attrs => [ $uintattr_t, $uintattr_t ] => 'void' );
    #
    $ffi->attach( tb_present => ['void'] => 'void' );
    #
    $ffi->attach( tb_invalidate => ['void'] => 'void' );
    #
    $ffi->attach( tb_set_cursor  => [ 'int', 'int' ] => 'void' );
    $ffi->attach( tb_hide_cursor => ['void']         => 'void' );
    #
    $ffi->attach(
        tb_set_cell => [ 'int', 'int', 'uint32_t', $uintattr_t, $uintattr_t ] => 'int',
        sub {
            my ( $xsub, $x, $y, $ch, $fg, $bg ) = @_;
            $xsub->( $x, $y, ord $ch, $fg, $bg );
        }
    );
    $ffi->attach(
        tb_set_cell_ex => [ 'int', 'int', 'uint32_t', 'size_t', $uintattr_t, $uintattr_t ] => 'int',
        sub {
            my ( $xsub, $x, $y, $ch, $nch, $fg, $bg ) = @_;
            $xsub->( $x, $y, ord $ch, $nch, $fg, $bg );
        }
    );
    $ffi->attach(
        tb_extend_cell => [ 'int', 'int', 'uint32_t' ] => 'int',
        sub {
            my ( $xsub, $x, $y, $ch ) = @_;
            $xsub->( $x, $y, ord $ch );
        }
    );
    #
    $ffi->attach( tb_set_input_mode => ['int'] => 'int' );
    #
    $ffi->attach( tb_set_output_mode => ['int'] => 'int' );
    #
    $ffi->attach( tb_peek_event => [ 'record(Termbox::Event)*', 'int' ] => 'int' );
    #
    $ffi->attach( tb_poll_event => ['record(Termbox::Event)*'] => 'int' );
    #
    $ffi->attach( tb_get_fds => [ 'int*', 'int*' ] => 'int' );
    #
    $ffi->attach( tb_print => [ 'int', 'int', $uintattr_t, $uintattr_t, 'string' ] => 'int' );

#~ int tb_printf(int x, int y, uintattr_t fg, uintattr_t bg, const char *fmt, ...);
#~ int tb_print_ex(int x, int y, uintattr_t fg, uintattr_t bg, size_t *out_w, const char *str);
#~ int tb_printf_ex(int x, int y, uintattr_t fg, uintattr_t bg, size_t *out_w, const char *fmt, ...);
#
    $ffi->attach( tb_send => [ 'string', 'size_t' ] => 'int' );
    #
    $ffi->type( '(opaque, opaque)->int' => 'closure_t' );   # int (*fn)(struct tb_event *, size_t *)
    $ffi->attach(
        tb_set_func => [ 'int', 'closure_t' ] => 'int',
        sub {
            CORE::state $cache;
            my ( $xsub, $fn_type, $func ) = @_;
            $cache->{$fn_type}->unsticky if $cache->{$fn_type};
            my $closure;
            if ($func) {
                $closure = $ffi->closure(
                    sub {
                        my ( $event, $size ) = @_;
                        $func->(
                            $ffi->cast( 'opaque', 'record(Termbox::Event)*', $event ),
                            $ffi->cast( 'opaque', 'size_t*',                 $size )
                        );
                    }
                );
                $closure->sticky;
            }
            $cache->{$fn_type} = $closure;
            $xsub->( $fn_type, $closure );
        }
    );
    #
    $ffi->attach( tb_utf8_char_length     => ['char']                   => 'int' );
    $ffi->attach( tb_utf8_char_to_unicode => [ 'uint32_t*', 'string*' ] => 'int' );
    $ffi->attach( tb_utf8_unicode_to_char => [ 'string', 'uint32_t' ]   => 'int' );
    $ffi->attach( tb_last_errno           => ['void']                   => 'int' );
    $ffi->attach( tb_strerror             => ['int']                    => 'string' );
    $ffi->attach( tb_cell_buffer          => ['void'] => 'record(Termbox::Cell)*' );

    # tb_has_truecolor and tbs_has_egc are defined near the top
    $ffi->attach( tb_version => ['void'] => 'string' );
}
1;
__END__

=encoding utf-8

=head1 NAME

Termbox - Create Text-based User Interfaces Without ncurses

=head1 SYNOPSIS

    use Termbox 2 qw[:all];
    #
    my @chars = split //, 'hello, world!';
    my $code  = tb_init();
    tb_clear();
    my @rows = (
        [ TB_WHITE,   TB_BLACK ],
        [ TB_BLACK,   TB_DEFAULT ],
        [ TB_RED,     TB_GREEN ],
        [ TB_GREEN,   TB_RED ],
        [ TB_YELLOW,  TB_BLUE ],
        [ TB_MAGENTA, TB_CYAN ]
    );
    for my $row ( 0 .. $#rows ) {
        for my $col ( 0 .. $#chars ) {
            tb_set_cell( $col, $row, $chars[$col], @{ $rows[$row] } );
        }
    }
    tb_present();
    sleep 3;
    tb_shutdown();

=head1 DESCRIPTION

Termbox is a terminal rendering library that retains the
L<suckless|https://suckless.org/coding_style/> spirit of the original termbox
(simple API, no dependencies beyond libc) and adds some improvements:

=over

=item strict error checking

=item more efficient escape sequence parsing

=item code gen for built-in escape sequences

=item opt-in support for 32-bit color

=item extended grapheme clusters

=back

=head2 Note

This module wraps C<libtermbox2>, an incompatible fork of the now abandoned
C<libtermbox>. I'm not sure why you would but if you're looking for the
original, try any version of L<Termbox|Termbox>.pm before 2.0.

=head1 Functions

Termbox's API is very small. You can build most UIs with just a few functions.
Import them by name or with C<:all>.

=head2 C<tb_init( )>

Initializes the termbox2 library. This function should be called before any
other functions. Calling this is the same as C<tb_init_file('/dev/tty')>. After
successful initialization, the library must be finalized using the
C<tb_shutdown( )> function.

If this returns anything other than C<0>, it didn't work.

=head2 C<tb_init_file( $name )>

This function will init the termbox2 library on the file name provided.

=head2 C<tb_init_fd( $fileno )>

This function will init the termbox2 library on the provided filehandle. This
is untested.

=head2 C<tb_init_rwfd( $rfileno, $wfileno )>

This function will init the termbox2 library on the provided filehandles. This
is untested.

=head2 C<tb_shutdown( )>

Causes the termbox2 library to attempt to clean up after itself.

=head2 C<tb_width( )>

Returns the horizontal size of the internal back buffer (which is the same as
terminal's window size in columns).

The internal buffer can be resized after C<tb_clear( )> or C<tb_present( )>
function calls. This function returns an unspecified negative value when called
before C<tb_init( )> or after C<tb_shutdown( )>.

=head2 C<tb_height( )>

Returns the vertical size of the internal back buffer (which is the same as
terminal's window size in rows).

The internal buffer can be resized after C<tb_clear( )> or C<tb_present( )>
function calls. This function returns an unspecified negative value when called
before C<tb_init( )> or after C<tb_shutdown( )>.

=head2 C<tb_clear( )>

Clears the internal back buffer using C<TB_DEFAULT> color or the
color/attributes set by C<tb_set_clear_attrs( )> function.

=head2 C<tb_set_clear_attrs( $fg, $bg )>

Overrides the use of C<TB_DEFAULT> to clear the internal back buffer when
C<tb_clear( )> is called.

=head2 C<tb_present( )>

Synchronizes the internal back buffer with the terminal by writing to tty.

=head2 C<tb_invalidate( )>

Clears the internal front buffer effectively forcing a complete re-render of
the back buffer to the tty. It is not necessary to call this under normal
circumstances.

=head2 C<tb_set_cursor( $x, $y )>

Sets the position of the cursor. Upper-left character is C<(0, 0)>.

=head2 C<tb_hide_cursor( )>

Hides the cursor.

=head2 C<tb_set_cell( $x, $y, $ch, $fg, $bg )>

Set cell contents in the internal back buffer at the specified position.

Function C<tb_set_cell($x, $y, $ch, $fg, $bg)>is equivalent to
C<tb_set_cell_ex($x, $y, $ch, 1, $fg, $bg)>.

=head2 C<tb_set_cell_ex( $x, $y, $ch, $nch, $fg, $bg )>

Set cell contents in the internal back buffer at the specified position. Use
this function for rendering grapheme clusters (e.g., combining diacritical
marks).

=head2 C<tb_extend_cell( $x, $y, $ch )>

Shortcut to append 1 code point to the given cell.

=head2 C<tb_set_input_mode( $mode )>

Sets the input mode. Termbox has two input modes:

=over

=item 1. C<TB_INPUT_ESC>

When escape (C<\x1b>) is in the buffer and there's no match for an escape
sequence, a key event for TB_KEY_ESC is returned.

=item 2. C<TB_INPUT_ALT>

When escape (C<\x1b>) is in the buffer and there's no match for an escape
sequence, the next keyboard event is returned with a C<TB_MOD_ALT> modifier.

=back

You can also apply C<TB_INPUT_MOUSE> via bitwise OR operation to either of the
modes (e.g., C<TB_INPUT_ESC | TB_INPUT_MOUSE>) to receive C<TB_EVENT_MOUSE>
events. If none of the main two modes were set, but the mouse mode was,
C<TB_INPUT_ESC> mode is used. If for some reason you've decided to use
(C<TB_INPUT_ESC | TB_INPUT_ALT>) combination, it will behave as if only
C<TB_INPUT_ESC> was selected.

If mode is C<TB_INPUT_CURRENT>, the function returns the current input mode.

The default input mode is C<TB_INPUT_ESC>.

=head2 C<tb_set_output_mode( $mode )>

Sets the termbox2 output mode. Termbox has multiple output modes:

=over

=item 1. C<TB_OUTPUT_NORMAL> => [0..8]

This mode provides 8 different colors: C<TB_BLACK>, C<TB_RED>, C<TB_GREEN>,
C<TB_YELLOW>, C<TB_BLUE>, C<TB_MAGENTA>, C<TB_CYAN>, C<TB_WHITE>

Plus C<TB_DEFAULT> which skips sending a color code (i.e., uses the terminal's
default color).

Colors (including C<TB_DEFAULT>) may be bitwise OR'd with attributes:
C<TB_BOLD>, C<TB_UNDERLINE>, C<TB_REVERSE>, C<TB_ITALIC>, C<TB_BLINK>

As in all modes, the value C<0> is interpreted as C<TB_DEFAULT> for
convenience.

Some notes: C<TB_REVERSE> can be applied as either fg or bg attributes for the
same effect. C<TB_BOLD>, C<TB_UNDERLINE>, C<TB_ITALIC>, C<TB_BLINK> apply as fg
attributes only, and are ignored as bg attributes.

Example usage:

    tb_set_cell($x, $y, '@', TB_BLACK | TB_BOLD, TB_RED);

=item 2. C<TB_OUTPUT_256> => [0..255] + C<TB_256_BLACK>

In this mode you get 256 distinct colors (plus default):

                0x00   (1): TB_DEFAULT
        TB_256_BLACK   (1): TB_BLACK in TB_OUTPUT_NORMAL
          0x01..0x07   (7): the next 7 colors as in TB_OUTPUT_NORMAL
          0x08..0x0f   (8): bright versions of the above
          0x10..0xe7 (216): 216 different colors
          0xe8..0xff  (24): 24 different shades of gray

Attributes may be bitwise OR'd as in C<TB_OUTPUT_NORMAL>.

Note C<TB_256_BLACK> must be used for black, as C<0x00> represents default.

=item 3. C<TB_OUTPUT_216> => [0..216]

This mode supports the 216-color range of C<TB_OUTPUT_256> only, but you don't
need to provide an offset:

                0x00   (1): TB_DEFAULT
          0x01..0xd8 (216): 216 different colors

=item 4. C<TB_OUTPUT_GRAYSCALE> => [0..24]

This mode supports the 24-color range of C<TB_OUTPUT_256> only, but you don't
need to provide an offset:

                0x00   (1): TB_DEFAULT
          0x01..0x18  (24): 24 different shades of gray

=item 5. C<TB_OUTPUT_TRUECOLOR> => [0x000000..0xffffff] + C<TB_TRUECOLOR_BLACK>

This mode provides 24-bit color on supported terminals. The format is
C<0xRRGGBB>. Colors may be bitwise OR'd with C<TB_TRUECOLOR_*> attributes.

Note C<TB_TRUECOLOR_BLACK> must be used for black, as C<0x000000> represents
default.

=back

If mode is C<TB_OUTPUT_CURRENT>, the function returns the current output mode.

The default output mode is C<TB_OUTPUT_NORMAL>.

To use the terminal default color (i.e., to not send an escape code), pass
C<TB_DEFAULT>. For convenience, the value C<0> is interpreted as C<TB_DEFAULT>
in all modes.

Note, cell attributes persist after switching output modes. Any translation
between, for example, C<TB_OUTPUT_NORMAL>'s C<TB_RED> and
C<TB_OUTPUT_TRUECOLOR>'s C<0xff0000> must be performed by the caller. Also note
that cells previously rendered in one mode may persist unchanged until the
front buffer is cleared (such as after a resize event) at which point it will
be re-interpreted and flushed according to the current mode. Callers may invoke
C<tb_invalidate( )> if it is desirable to immediately re-interpret and flush
the entire screen according to the current mode.

Note, not all terminals support all output modes, especially beyond
C<TB_OUTPUT_NORMAL>. There is also no very reliable way to determine color
support dynamically. If portability is desired, callers are recommended to use
C<TB_OUTPUT_NORMAL> or make output mode end-user configurable.

=head2 C<tb_peek_event( $event, $timeout_ms )>

Wait for an event up to C<$timeout_ms> milliseconds and fill the $event
structure with it. If no event is available within the timeout period,
C<TB_ERR_NO_EVENT> is returned. On a resize event, the underlying C<select(2)>
call may be interrupted, yielding a return code of C<TB_ERR_POLL>. In this
case, you may check C<errno> via C<tb_last_errno( )>. If it's C<EINTR>, you can
safely ignore that and call C<tb_peek_event( )> again.

=head2 C<tb_poll_event( $event )>

Same as C<tb_peek_event( $event, $timeout_ms )> except no timeout.

=head2 C<tb_get_fds( \$ttyfd, \$resizefd )>

Internal termbox2 FDs that can be used with C<poll()> / C<select()>. Must call
C<tb_poll_event( $event )> / C<tb_peek_event( $event, $timeout_ms )> if
activity is detected.

=head2 C<tb_print( $x, $y, $fg, $bg, $str )>

It prints text.

=head2 C<tb_send( $buf, $nbuf )>

Send raw bytes to terminal.

=head2 C<tb_set_func( $fn_type, $fn )>

Set custom functions. C<$fn_type> is one of C<TB_FUNC_*> constants, C<fn> is a
compatible function pointer, or C<undef> to clear.

=over

=item C<TB_FUNC_EXTRACT_PRE>

If specified, invoke this function BEFORE termbox2 tries to extract any escape
sequences from the input buffer.

=item C<TB_FUNC_EXTRACT_POST>

If specified, invoke this function AFTER termbox2 tries (and fails) to extract
any escape sequences from the input buffer.

=back

=head2 C<tb_utf8_char_length( $c )>

Returns the length of a utf8 encoded character.

=head2 C<tb_utf8_char_to_unicode( \$out, $c )>

Converts a utf8 encoded character to Unicode.

=head2 C<tb_utf8_unicode_to_char( \$out, $c )>

Converts a Unicode character to utf8.

=head2 C<tb_last_errno( )>

Returns the last C<errno>.

=head2 C<tb_strerror( $err )>

Returns a string describing the given error.

=head2 C<tb_cell_buffer( )>

Returns the current cell buffer.

=head2 C<tb_has_truecolor( )>

Returns a true value if truecolor values are supported.

=head2 C<tb_has_egc( )>

Returns a true value if Unicode's extended grapheme clusters are supported.

=head2 Ctb_version( )>

Returns the version string of the wrapped libtermbox2.

=head1 Constants

You may import these by name or with the following tags:

=head2 C<:keys>

These are a safe subset of terminfo keys which exist on all popular terminals.
Termbox only uses them to stay truly portable. See also Termbox::Event's C<key(
)> method.

Please see
L<termbox2.h|https://github.com/termbox/termbox2/blob/1e0092b50ee96f5993f456e8ecdb06044a38b8eb/termbox2.h#L79>
for the list

=head2 C<:color>

These are foreground and background color values.

Please see
L<termbox2.h|https://github.com/termbox/termbox2/blob/1e0092b50ee96f5993f456e8ecdb06044a38b8eb/termbox2.h#L204>
for the list

=head2 C<:event>

Please see
L<termbox2.h|https://github.com/termbox/termbox2/blob/1e0092b50ee96f5993f456e8ecdb06044a38b8eb/termbox2.h#L229>
for the list

=head2 C<:return>

Common function return values unless otherwise noted.

Library behavior is undefined after receiving C<TB_ERR_MEM>. Callers may
attempt reinitializing by freeing memory, invoking C<tb_shutdown( )>, then
C<tb_init( )>.

Please see
L<termbox2.h|https://github.com/termbox/termbox2/blob/1e0092b50ee96f5993f456e8ecdb06044a38b8eb/termbox2.h#L256>
for the list

=head2 C<:func>

Function types to be used with C<tb_set_func( $fn_type, $func )>.

Please see
L<termbox2.h|https://github.com/termbox/termbox2/blob/1e0092b50ee96f5993f456e8ecdb06044a38b8eb/termbox2.h#L289>
for the list

=head1 LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

=head1 AUTHOR

Sanko Robinson E<lt>sanko@cpan.orgE<gt>

=begin stopwords

ncurses winapi termbox termbox2 libtermbox2 bitwise terminfo unix tty libc
filehandles fg bg utf8 truecolor reinitializing configurable 0x000000..0xffffff

=end stopwords

=cut
