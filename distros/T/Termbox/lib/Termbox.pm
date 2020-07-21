package Termbox {
    use 5.020;
    use strictures 2;
    use warnings;
    our $VERSION = "0.11";
    #
    use File::ShareDir qw[dist_dir];
    use File::Spec::Functions qw[catdir canonpath];
    #
    use FFI::CheckLib;
    use FFI::Platypus 1.00;
    use FFI::Platypus::Memory qw( malloc free );
    $ENV{FFI_PLATYPUS_DLERROR} = 1;
    my $ffi = FFI::Platypus->new(
        api          => 1,
        experimental => 2,
        lang         => 'CPP',
        lib          => find_lib_or_exit(
            lib       => 'termbox',
            recursive => 1,
            libpath   => [ qw[ . ./share/lib], canonpath( catdir( dist_dir(__PACKAGE__), 'lib' ) ) ]
        )
    );

    #
    use base qw[Exporter];
    use vars qw[@EXPORT_OK @EXPORT %EXPORT_TAGS];
    #
    $EXPORT_TAGS{api} = [
        qw[
            tb_init tb_init_file tb_init_fd tb_shutdown
            tb_width tb_height
            tb_clear tb_set_clear_attributes
            tb_present
            tb_set_cursor
            tb_put_cell tb_change_cell
            tb_cell_buffer
            tb_select_input_mode
            tb_select_output_mode
            tb_peek_event
            tb_poll_event
            ]
    ];
    use constant {
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
        TB_KEY_MOUSE_LEFT       => ( 0xFFFF - 22 ),
        TB_KEY_MOUSE_RIGHT      => ( 0xFFFF - 23 ),
        TB_KEY_MOUSE_MIDDLE     => ( 0xFFFF - 24 ),
        TB_KEY_MOUSE_RELEASE    => ( 0xFFFF - 25 ),
        TB_KEY_MOUSE_WHEEL_UP   => ( 0xFFFF - 26 ),
        TB_KEY_MOUSE_WHEEL_DOWN => ( 0xFFFF - 27 ),

        # These are all ASCII code points below SPACE character and a BACKSPACE key.
        TB_KEY_CTRL_TILDE       => 0x00,
        TB_KEY_CTRL_2           => 0x00,    # clash with 'CTRL_TILDE'
        TB_KEY_CTRL_A           => 0x01,
        TB_KEY_CTRL_B           => 0x02,
        TB_KEY_CTRL_C           => 0x03,
        TB_KEY_CTRL_D           => 0x04,
        TB_KEY_CTRL_E           => 0x05,
        TB_KEY_CTRL_F           => 0x06,
        TB_KEY_CTRL_G           => 0x07,
        TB_KEY_BACKSPACE        => 0x08,
        TB_KEY_CTRL_H           => 0x08,    # clash with 'CTRL_BACKSPACE'
        TB_KEY_TAB              => 0x09,
        TB_KEY_CTRL_I           => 0x09,    # clash with 'TAB'
        TB_KEY_CTRL_J           => 0x0A,
        TB_KEY_CTRL_K           => 0x0B,
        TB_KEY_CTRL_L           => 0x0C,
        TB_KEY_ENTER            => 0x0D,
        TB_KEY_CTRL_M           => 0x0D,    # clash with 'ENTER'
        TB_KEY_CTRL_N           => 0x0E,
        TB_KEY_CTRL_O           => 0x0F,
        TB_KEY_CTRL_P           => 0x10,
        TB_KEY_CTRL_Q           => 0x11,
        TB_KEY_CTRL_R           => 0x12,
        TB_KEY_CTRL_S           => 0x13,
        TB_KEY_CTRL_T           => 0x14,
        TB_KEY_CTRL_U           => 0x15,
        TB_KEY_CTRL_V           => 0x16,
        TB_KEY_CTRL_W           => 0x17,
        TB_KEY_CTRL_X           => 0x18,
        TB_KEY_CTRL_Y           => 0x19,
        TB_KEY_CTRL_Z           => 0x1A,
        TB_KEY_ESC              => 0x1B,
        TB_KEY_CTRL_LSQ_BRACKET => 0x1B,    # clash with 'ESC'
        TB_KEY_CTRL_3           => 0x1B,    # clash with 'ESC'
        TB_KEY_CTRL_4           => 0x1C,
        TB_KEY_CTRL_BACKSLASH   => 0x1C,    # clash with 'CTRL_4'
        TB_KEY_CTRL_5           => 0x1D,
        TB_KEY_CTRL_RSQ_BRACKET => 0x1D,    # clash with 'CTRL_5'
        TB_KEY_CTRL_6           => 0x1E,
        TB_KEY_CTRL_7           => 0x1F,
        TB_KEY_CTRL_SLASH       => 0x1F,    # clash with 'CTRL_7'
        TB_KEY_CTRL_UNDERSCORE  => 0x1F,    # clash with 'CTRL_7'
        TB_KEY_SPACE            => 0x20,
        TB_KEY_BACKSPACE2       => 0x7F,
        TB_KEY_CTRL_8           => 0x7F     # clash with 'BACKSPACE2'
    };
    $EXPORT_TAGS{keys} = [
        qw[
            TB_KEY_F1
            TB_KEY_F2
            TB_KEY_F3
            TB_KEY_F4
            TB_KEY_F5
            TB_KEY_F6
            TB_KEY_F7
            TB_KEY_F8
            TB_KEY_F9
            TB_KEY_F10
            TB_KEY_F11
            TB_KEY_F12
            TB_KEY_INSERT
            TB_KEY_DELETE
            TB_KEY_HOME
            TB_KEY_END
            TB_KEY_PGUP
            TB_KEY_PGDN
            TB_KEY_ARROW_UP
            TB_KEY_ARROW_DOWN
            TB_KEY_ARROW_LEFT
            TB_KEY_ARROW_RIGHT
            TB_KEY_MOUSE_LEFT
            TB_KEY_MOUSE_RIGHT
            TB_KEY_MOUSE_MIDDLE
            TB_KEY_MOUSE_RELEASE
            TB_KEY_MOUSE_WHEEL_UP
            TB_KEY_MOUSE_WHEEL_DOWN
            TB_KEY_CTRL_TILDE
            TB_KEY_CTRL_2
            TB_KEY_CTRL_A
            TB_KEY_CTRL_B
            TB_KEY_CTRL_C
            TB_KEY_CTRL_D
            TB_KEY_CTRL_E
            TB_KEY_CTRL_F
            TB_KEY_CTRL_G
            TB_KEY_BACKSPACE
            TB_KEY_CTRL_H
            TB_KEY_TAB
            TB_KEY_CTRL_I
            TB_KEY_CTRL_J
            TB_KEY_CTRL_K
            TB_KEY_CTRL_L
            TB_KEY_ENTER
            TB_KEY_CTRL_M
            TB_KEY_CTRL_N
            TB_KEY_CTRL_O
            TB_KEY_CTRL_P
            TB_KEY_CTRL_Q
            TB_KEY_CTRL_R
            TB_KEY_CTRL_S
            TB_KEY_CTRL_T
            TB_KEY_CTRL_U
            TB_KEY_CTRL_V
            TB_KEY_CTRL_W
            TB_KEY_CTRL_X
            TB_KEY_CTRL_Y
            TB_KEY_CTRL_Z
            TB_KEY_ESC
            TB_KEY_CTRL_LSQ_BRACKET
            TB_KEY_CTRL_3
            TB_KEY_CTRL_4
            TB_KEY_CTRL_BACKSLASH
            TB_KEY_CTRL_5
            TB_KEY_CTRL_RSQ_BRACKET
            TB_KEY_CTRL_6
            TB_KEY_CTRL_7
            TB_KEY_CTRL_SLASH
            TB_KEY_CTRL_UNDERSCORE
            TB_KEY_SPACE
            TB_KEY_BACKSPACE2
            TB_KEY_CTRL_8
            ]
    ];

    #
    use constant {
        TB_MOD_ALT    => 0x01,
        TB_MOD_MOTION => 0x02
    };
    $EXPORT_TAGS{modifier} = [
        qw[
            TB_MOD_ALT
            TB_MOD_MOTION
            ]
    ];

    #
    use constant {
        TB_DEFAULT => 0x00,
        TB_BLACK   => 0x01,
        TB_RED     => 0x02,
        TB_GREEN   => 0x03,
        TB_YELLOW  => 0x04,
        TB_BLUE    => 0x05,
        TB_MAGENTA => 0x06,
        TB_CYAN    => 0x07,
        TB_WHITE   => 0x08,
    };
    $EXPORT_TAGS{color} = [
        qw[
            TB_DEFAULT
            TB_BLACK
            TB_RED
            TB_GREEN
            TB_YELLOW
            TB_BLUE
            TB_MAGENTA
            TB_CYAN
            TB_WHITE
            ]
    ];

    #
    use constant { TB_BOLD => 0x0100, TB_UNDERLINE => 0x0200, TB_REVERSE => 0x0400 };
    $EXPORT_TAGS{font} = [
        qw[
            TB_BOLD
            TB_UNDERLINE
            TB_REVERSE
            ]
    ];
    #
    use constant { TB_EVENT_KEY => 1, TB_EVENT_RESIZE => 2, TB_EVENT_MOUSE => 3 };
    $EXPORT_TAGS{event} = [
        qw[
            TB_EVENT_KEY
            TB_EVENT_RESIZE
            TB_EVENT_MOUSE
            ]
    ];

    #
    use constant {
        TB_EUNSUPPORTED_TERMINAL => -1,
        TB_EFAILED_TO_OPEN_TTY   => -2,
        TB_EPIPE_TRAP_ERROR      => -3

    };
    $EXPORT_TAGS{error} = [
        qw[
            TB_EUNSUPPORTED_TERMINAL
            TB_EFAILED_TO_OPEN_TTY
            TB_EPIPE_TRAP_ERROR
            ]
    ];
    #
    use constant {
        TB_HIDE_CURSOR => -1

    };
    $EXPORT_TAGS{cursor} = [
        qw[
            TB_HIDE_CURSOR
            ]
    ];
    #
    use constant {
        TB_INPUT_CURRENT => 0, TB_INPUT_ESC => 1, TB_INPUT_ALT => 2,
        TB_INPUT_MOUSE   => => 4
    };
    $EXPORT_TAGS{input} = [
        qw[
            TB_INPUT_CURRENT
            TB_INPUT_ESC
            TB_INPUT_ALT
            TB_INPUT_MOUSE
            ]
    ];
    use constant {
        TB_OUTPUT_CURRENT   => 0,
        TB_OUTPUT_NORMAL    => 1,
        TB_OUTPUT_256       => 2,
        TB_OUTPUT_216       => 3,
        TB_OUTPUT_GRAYSCALE => 4
    };
    $EXPORT_TAGS{output} = [
        qw[
            TB_OUTPUT_NORMAL
            TB_OUTPUT_256
            TB_OUTPUT_216
            TB_OUTPUT_GRAYSCALE
            ]
    ];

    @EXPORT_OK = sort map { @$_ = sort @$_; @$_ } values %EXPORT_TAGS;
    $EXPORT_TAGS{'all'} = \@EXPORT_OK;    # When you want to import everything
                                          #
    use Termbox::Cell;
    $ffi->type('record(Termbox::Cell)');

    #
    use Termbox::Event;
    $ffi->type('record(Termbox::Event)');
    #
    $ffi->attach( tb_init      => ['void']   => 'int' );
    $ffi->attach( tb_init_file => ['string'] => 'int' );
    $ffi->attach( tb_init_fd   => ['int']    => 'int' );
    $ffi->attach( tb_shutdown  => ['void']   => 'void' );
    #
    $ffi->attach( tb_width  => ['void'] => 'int' );
    $ffi->attach( tb_height => ['void'] => 'int' );
    #
    $ffi->attach( tb_clear                => ['void']                   => 'void' );
    $ffi->attach( tb_set_clear_attributes => [ 'uint16_t', 'uint16_t' ] => 'void' );
    #
    $ffi->attach( tb_present => ['void'] => 'void' );
    #
    $ffi->attach( tb_set_cursor => [ 'int', 'int' ] => 'void' );
    #
    $ffi->attach( tb_put_cell => [ 'int', 'int', 'record(Termbox::Cell)*' ] => 'void' );
    $ffi->attach(
        [ 'tb_change_cell' => '_tb_change_cell' ],
        [ 'int', 'int', 'uint32_t', 'uint16_t', 'uint16_t' ] => 'void'
    );

    # The C API expects a char which doesn't so much work with Perl's representation of a character.
    sub tb_change_cell {
        _tb_change_cell( $_[0], $_[1], ( length $_[2] == 1 ? ord( $_[2] ) : $_[2] ), $_[3], $_[4] );
    }
    #
    $ffi->attach( tb_cell_buffer => ['void'] => 'record(Termbox::Cell)*' );
    #
    $ffi->attach( tb_select_input_mode => ['int'] => 'int' );
    #
    $ffi->attach( tb_select_output_mode => ['int'] => 'int' );
    #
    $ffi->attach( tb_peek_event => [ 'record(Termbox::Event)*', 'int' ] => 'int' );
    #
    $ffi->attach( tb_poll_event => ['record(Termbox::Event)*'] => 'int' );

    # Utils: Not documented yet... might keep them private
    $ffi->attach( tb_utf8_char_length     => ['char']                   => 'int' );
    $ffi->attach( tb_utf8_char_to_unicode => [ 'uint32_t *', 'string' ] => 'int' );
    $ffi->attach( tb_utf8_unicode_to_char => [qw[string uint32_t]]      => 'int' );
    #
}
1;
__END__

=encoding utf-8

=head1 NAME

Termbox - Create Text-based User Interfaces Without ncurses

=head1 SYNOPSIS

	use Termbox qw[:all];
	my @chars = split //, 'hello, world!';
	my $code  = tb_init();
	die sprintf "termbox init failed, code: %d\n", $code if $code;
	tb_select_input_mode(TB_INPUT_ESC);
	tb_select_output_mode(TB_OUTPUT_NORMAL);
	tb_clear();
	my @rows = (
		[TB_WHITE,   TB_BLACK],
		[TB_BLACK,   TB_DEFAULT],
		[TB_RED,     TB_GREEN],
		[TB_GREEN,   TB_RED],
		[TB_YELLOW,  TB_BLUE],
		[TB_MAGENTA, TB_CYAN]);

	for my $colors (0 .. $#rows) {
		my $j = 0;
		for my $char (@chars) {
			tb_change_cell($j, $colors, ord $char, @{ $rows[$colors] });
			$j++;
		}
	}
	tb_present();
	while (1) {
		my $ev = Termbox::Event->new();
		tb_poll_event($ev);
		if ($ev->key == TB_KEY_ESC) {
			tb_shutdown();
			exit 0;
		}
	}

=head1 DESCRIPTION

Termbox is a library that provides minimalistic API which allows the programmer
to write text-based user interfaces. The library is crossplatform and has both
terminal-based implementations on *nix operating systems and a winapi console
based implementation for windows operating systems. The basic idea is an
abstraction of the greatest common subset of features available on all major
terminals and other terminal-like APIs in a minimalistic fashion. Small API
means it is easy to implement, test, maintain and learn it, that's what makes
the termbox a distinct library in its area.

=head2 Note

This is a first draft to get my feet wet with FFI::Platypus. It'll likely be
prone to tipping over. For now, libtermbox is built by this package during
installation but that'll change when I wrap my mind around Alien::Base, et. al.

This module's API will likely change to be more Perl and less C.

=head1 Functions

Termbox's API is very small. You can build most UIs with just a few functions.
Import them by name or with C<:all>.

=head2 C<tb_init( )>

Initializes the termbox library. This function should be called before any
other functions. Calling this is the same as C<tb_init_file('/dev/tty')>. After
successful initialization, the library must be finalized using the
C<tb_shutdown( )> function.

If this returns anything other than C<0>, it didn't work.

=head2 C<tb_init_file( $name )>

This function will init the termbox library on the file name provided.

=head2 C<tb_init_fd( $fileno )>

This function will init the termbox library on the provided filehandle. This is
untested.

=head2 C<tb_shutdown( )>

Causes the termbox library to attempt to clean up after itself.

=head2 C<tb_width( )>

Returns the horizontal size of the internal back buffer (which is the same as
terminal's window size in characters).

The internal buffer can be resized after C<tb_clear( )> or C<tb_present( )>
function calls. This function returns an unspecified negative value when called
before C<tb_init( )> or after C<tb_shutdown( )>.

=head2 C<tb_height( )>

Returns the vertical size of the internal back buffer (which is the same as
terminal's window size in characters).

The internal buffer can be resized after C<tb_clear( )> or C<tb_present( )>
function calls. This function returns an unspecified negative value when called
before C<tb_init( )> or after C<tb_shutdown( )>.

=head2 C<tb_clear( )>

Clears the internal back buffer using C<TB_DEFAULT> color or the
color/attributes set by C<tb_set_clear_attributes( )> function.

=head2 C<tb_set_clear_attributes( $fg, $bg )>

Overrides the use of C<TB_DEFAULT> to clear the internal back buffer when
C<tb_clear( )> is called.

=head2 C<tb_present( )>

Synchronizes the internal back buffer with the terminal.

=head2 C<tb_set_cursor( $x, $y )>

Sets the position of the cursor. Upper-left character is C<(0, 0)>. If you pass
C<TB_HIDE_CURSOR> as both coordinates, then the cursor will be hidden. Cursor
is hidden by default.

=head2 C<tb_put_cell( $x, $y, $cell )>

Changes cell's parameters in the internal back buffer at the specified
position.

=head2 C<tb_change_cell( $x, $y, $char, $fg, $bg)>

Changes cell's parameters in the internal back buffer at the specified
position, with the specified character, and with the specified foreground and
background colors.

=head2 C<tb_cell_buffer( )>

Returns a C<Termbox::Cell> object containing a pointer to internal cell back
buffer. You can get its dimensions using C<tb_width( )> and C<tb_height( )>
methods. The pointer stays valid as long as no C<tb_clear( )> and C<tb_present(
)> calls are made. The buffer is one-dimensional buffer containing lines of
cells starting from the top.

=head2 C<tb_select_input_mode( $mode )>

Sets the termbox input mode. Termbox has two input modes:

=over

=item 1. Esc input mode.

When ESC sequence is in the buffer and it doesn't match any known ESC sequence
where ESC means C<TB_KEY_ESC>.

=item 2. Alt input mode.

When ESC sequence is in the buffer and it doesn't match any known sequence ESC
enables C<TB_MOD_ALT> modifier for the next keyboard event.

=back

You can also apply C<TB_INPUT_MOUSE> via bitwise OR operation to either of the
modes (e.g. C<TB_INPUT_ESC | TB_INPUT_MOUSE>). If none of the main two modes
were set, but the mouse mode was, C<TB_INPUT_ESC> mode is used. If for some
reason you've decided to use C<(TB_INPUT_ESC | TB_INPUT_ALT)> combination, it
will behave as if only TB_INPUT_ESC was selected.

If 'mode' is C<TB_INPUT_CURRENT>, it returns the current input mode.

Default termbox input mode is C<TB_INPUT_ESC>.

=head2 C<tb_select_output_mode( $mode )>

Sets the termbox output mode. Termbox has three output options:

=over


=item 1. C<TB_OUTPUT_NORMAL> - C<1 .. 8>

This mode provides 8 different colors: black, red, green, yellow, blue,
magenta, cyan, white

Shortcut: C<TB_BLACK>, C<TB_RED>, etc.

Attributes: C<TB_BOLD>, C<TB_UNDERLINE>, C<TB_REVERSE>

Example usage:

	tb_change_cell(x, y, '@', TB_BLACK | TB_BOLD, TB_RED);


=item 2. C<TB_OUTPUT_256> - C<0 .. 256>

In this mode you can leverage the 256 terminal mode:

	0x00 - 0x07: the 8 colors as in TB_OUTPUT_NORMAL
	0x08 - 0x0f: TB_* | TB_BOLD
	0x10 - 0xe7: 216 different colors
	0xe8 - 0xff: 24 different shades of grey

Example usage:

	tb_change_cell(x, y, '@', 184, 240);
	tb_change_cell(x, y, '@', 0xb8, 0xf0);

=item 3. C<TB_OUTPUT_216> - C<0 .. 216>

This mode supports the 3rd range of the 256 mode only. But you don't need to
provide an offset.

=item 4. C<TB_OUTPUT_GRAYSCALE> - C<0 .. 23>

This mode supports the 4th range of the 256 mode only. But you dont need to
provide an offset.

=back

If 'mode' is C<TB_OUTPUT_CURRENT>, it returns the current output mode.

Default termbox output mode is C<TB_OUTPUT_NORMAL>.

=head2 C<tb_peek_event( $event, $timeout )>

Wait for an event up to 'timeout' milliseconds and fill the 'event' object with
it, when the event is available. Returns the type of the event (one of
C<TB_EVENT_*> constants) or C<-1> if there was an error or C<0> in case there
were no event during 'timeout' period.

Current usage:

	my $ev = Termbox::Event->new( );
	tb_peek_event( $evl, 1 ); # $ev is filled by the API; yes, this will change before v1.0

=head2 C<tb_poll_event( $event )>

Wait for an event forever and fill the 'event' object with it, when the event
is available. Returns the type of the event (one of C<TB_EVENT_*> constants) or
-1 if there was an error.

Current usage:

	my $ev = Termbox::Event->new( );
	tb_peek_event( $evl, 1 ); # $ev is filled by the API; yes, this will change before v1.0

=head1 Constants

TODO: These aren't fleshed out yet, I'm thinking of grabbing them from the C
side of FFI::Platypus.

You may import these by name or with the following tags:

=head2 C<:keys>

These are a safe subset of terminfo keys which exist on all popular terminals.
Termbox only uses them to stay truly portable. See also Termbox::Event's C<key(
)> method.

TODO: For now, please see
https://github.com/nsf/termbox/blob/master/src/termbox.h for the list

=head2 C<:modifier>

Modifier constants. See Termbox::Event's C<mod( )> method and the
C<tb_select_input_mode( )> function.

=over

=item C<TB_MOD_ALT> - Alt key modifier.

=item C<TB_MOD_MOTION> - Mouse motion modifier

=back

=head2 C<:color>

See Termbox::Cell's C<fg( )> and C<bg( )> values.

=over

=item C<TB_DEFAULT>

=item C<TB_BLACK>

=item C<TB_RED>

=item C<TB_GREEN>

=item C<TB_YELLOW>

=item C<TB_BLUE>

=item C<TB_MAGENTA>

=item C<TB_CYAN>

=item C<TB_WHITE>

=back

=head2 C<:font>

Attributes, it is possible to use multiple attributes by combining them using
bitwise OR (C<|>). Although, colors cannot be combined. But you can combine
attributes and a single color. See also Termbox::Cell's C<fg( )> and C<bg( )>
methods.

=over

=item C<TB_BOLD>

=item C<TB_UNDERLINE>

=item C<TB_REVERSE>

=back

=head2 C<:event>

=over

=item C<TB_EVENT_KEY>

=item C<TB_EVENT_RESIZE>

=item C<TB_EVENT_MOUSE>

=back

=head2 C<:error>

Error codes returned by C<tb_init( )>. A claim is made that all of them are
self-explanatory except the pipe trap error. Termbox uses unix pipes in order
to deliver a message from a signal handler (C<SIGWINCH>) to the main event
reading loop. Honestly in most cases you should just check the returned code as
C<<E<lt> 0>>.

=over

=item C<TB_EUNSUPPORTED_TERMINAL>

=item C<TB_EFAILED_TO_OPEN_TTY>

=item C<TB_EPIPE_TRAP_ERROR>

=back

=head2 C<:cursor>

=over

=item C<TB_HIDE_CURSOR> - Pass this to C<tb_set_cursor( $x, $y )> to hide the cursor

=back

=head2 C<:input>

Pass one of these to C<tb_select_input_mode( $mode )>:

=over

=item C<TB_INPUT_CURRENT>

=item C<TB_INPUT_ESC>

=item C<TB_INPUT_ALT>

=item C<TB_INPUT_MOUSE>

=back

=head2 C<:output>

Pass one of these to C<tb_select_output_mode( $mode )>:

=over

=item C<TB_OUTPUT_CURRENT>

=item C<TB_OUTPUT_NORMAL>

=item C<TB_OUTPUT_256>

=item C<TB_OUTPUT_216>

=item C<TB_OUTPUT_GRAYSCALE>

=back

=head1 Author

Sanko Robinson E<lt>sanko@cpan.orgE<gt> - http://sankorobinson.com/

CPAN ID: SANKO

=head1 License and Legal

Copyright (C) 2020 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it under
the terms of The Artistic License 2.0. See
http://www.perlfoundation.org/artistic_license_2_0.  For clarification, see
http://www.perlfoundation.org/artistic_2_0_notes.

When separated from the distribution, all POD documentation is covered by the
Creative Commons Attribution-Share Alike 3.0 License. See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For clarification,
see http://creativecommons.org/licenses/by-sa/3.0/us/.

=cut
