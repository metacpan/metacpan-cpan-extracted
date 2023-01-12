[![Actions Status](https://github.com/sanko/Termbox.pm/actions/workflows/ci.yaml/badge.svg)](https://github.com/sanko/Termbox.pm/actions) [![MetaCPAN Release](https://badge.fury.io/pl/Termbox.svg)](https://metacpan.org/release/Termbox)
# NAME

Termbox - Create Text-based User Interfaces Without ncurses

# SYNOPSIS

```perl
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
```

# DESCRIPTION

Termbox is a library that provides minimalistic API which allows the programmer
to write text-based user interfaces. The library is cross-platform and has both
terminal-based implementations on \*nix operating systems and a winapi console
based implementation for windows operating systems. The basic idea is an
abstraction of the greatest common subset of features available on all major
terminals and other terminal-like APIs in a minimalistic fashion. Small API
means it is easy to implement, test, maintain and learn it, that's what makes
the termbox a distinct library in its area.

## Note

This is a first draft to get my feet wet with FFI::Platypus. It'll likely be
prone to tipping over. For now, libtermbox is built by this package during
installation but that'll change when I wrap my mind around Alien::Base, et. al.

This module's API will likely change to be more Perl and less C.

# Functions

Termbox's API is very small. You can build most UIs with just a few functions.
Import them by name or with `:all`.

## `tb_init( )`

Initializes the termbox library. This function should be called before any
other functions. Calling this is the same as `tb_init_file('/dev/tty')`. After
successful initialization, the library must be finalized using the
`tb_shutdown( )` function.

If this returns anything other than `0`, it didn't work.

## `tb_init_file( $name )`

This function will init the termbox library on the file name provided.

## `tb_init_fd( $fileno )`

This function will init the termbox library on the provided filehandle. This is
untested.

## `tb_shutdown( )`

Causes the termbox library to attempt to clean up after itself.

## `tb_width( )`

Returns the horizontal size of the internal back buffer (which is the same as
terminal's window size in characters).

The internal buffer can be resized after `tb_clear( )` or `tb_present( )`
function calls. This function returns an unspecified negative value when called
before `tb_init( )` or after `tb_shutdown( )`.

## `tb_height( )`

Returns the vertical size of the internal back buffer (which is the same as
terminal's window size in characters).

The internal buffer can be resized after `tb_clear( )` or `tb_present( )`
function calls. This function returns an unspecified negative value when called
before `tb_init( )` or after `tb_shutdown( )`.

## `tb_clear( )`

Clears the internal back buffer using `TB_DEFAULT` color or the
color/attributes set by `tb_set_clear_attributes( )` function.

## `tb_set_clear_attributes( $fg, $bg )`

Overrides the use of `TB_DEFAULT` to clear the internal back buffer when
`tb_clear( )` is called.

## `tb_present( )`

Synchronizes the internal back buffer with the terminal.

## `tb_set_cursor( $x, $y )`

Sets the position of the cursor. Upper-left character is `(0, 0)`. If you pass
`TB_HIDE_CURSOR` as both coordinates, then the cursor will be hidden. Cursor
is hidden by default.

## `tb_put_cell( $x, $y, $cell )`

Changes cell's parameters in the internal back buffer at the specified
position.

## `tb_change_cell( $x, $y, $char, $fg, $bg)`

Changes cell's parameters in the internal back buffer at the specified
position, with the specified character, and with the specified foreground and
background colors.

## `tb_cell_buffer( )`

Returns a `Termbox::Cell` object containing a pointer to internal cell back
buffer. You can get its dimensions using `tb_width( )` and `tb_height( )`
methods. The pointer stays valid as long as no `tb_clear( )` and `tb_present(
)` calls are made. The buffer is one-dimensional buffer containing lines of
cells starting from the top.

## `tb_select_input_mode( $mode )`

Sets the termbox input mode. Termbox has two input modes:

- 1. Esc input mode.

    When ESC sequence is in the buffer and it doesn't match any known ESC sequence
    where ESC means `TB_KEY_ESC`.

- 2. Alt input mode.

    When ESC sequence is in the buffer and it doesn't match any known sequence ESC
    enables `TB_MOD_ALT` modifier for the next keyboard event.

You can also apply `TB_INPUT_MOUSE` via bitwise OR operation to either of the
modes (e.g. `TB_INPUT_ESC | TB_INPUT_MOUSE`). If none of the main two modes
were set, but the mouse mode was, `TB_INPUT_ESC` mode is used. If for some
reason you've decided to use `(TB_INPUT_ESC | TB_INPUT_ALT)` combination, it
will behave as if only TB\_INPUT\_ESC was selected.

If 'mode' is `TB_INPUT_CURRENT`, it returns the current input mode.

Default termbox input mode is `TB_INPUT_ESC`.

## `tb_select_output_mode( $mode )`

Sets the termbox output mode. Termbox has three output options:

- 1. `TB_OUTPUT_NORMAL` - `1 .. 8`

    This mode provides 8 different colors: black, red, green, yellow, blue,
    magenta, cyan, white

    Shortcut: `TB_BLACK`, `TB_RED`, etc.

    Attributes: `TB_BOLD`, `TB_UNDERLINE`, `TB_REVERSE`

    Example usage:

    ```
        tb_change_cell(x, y, '@', TB_BLACK | TB_BOLD, TB_RED);
    ```

- 2. `TB_OUTPUT_256` - `0 .. 256`

    In this mode you can leverage the 256 terminal mode:

    ```
        0x00 - 0x07: the 8 colors as in TB_OUTPUT_NORMAL
        0x08 - 0x0f: TB_* | TB_BOLD
        0x10 - 0xe7: 216 different colors
        0xe8 - 0xff: 24 different shades of grey
    ```

    Example usage:

    ```
        tb_change_cell(x, y, '@', 184, 240);
        tb_change_cell(x, y, '@', 0xb8, 0xf0);
    ```

- 3. `TB_OUTPUT_216` - `0 .. 216`

    This mode supports the 3rd range of the 256 mode only. But you don't need to
    provide an offset.

- 4. `TB_OUTPUT_GRAYSCALE` - `0 .. 23`

    This mode supports the 4th range of the 256 mode only. But you do not need to
    provide an offset.

If 'mode' is `TB_OUTPUT_CURRENT`, it returns the current output mode.

Default termbox output mode is `TB_OUTPUT_NORMAL`.

## `tb_peek_event( $event, $timeout )`

Wait for an event up to 'timeout' milliseconds and fill the 'event' object with
it, when the event is available. Returns the type of the event (one of
`TB_EVENT_*` constants) or `-1` if there was an error or `0` in case there
were no event during 'timeout' period.

Current usage:

```perl
    my $ev = Termbox::Event->new( );
    tb_peek_event( $evl, 1 ); # $ev is filled by the API; yes, this will change before v1.0
```

## `tb_poll_event( $event )`

Wait for an event forever and fill the 'event' object with it, when the event
is available. Returns the type of the event (one of `TB_EVENT_*` constants) or
\-1 if there was an error.

Current usage:

```perl
    my $ev = Termbox::Event->new( );
    tb_peek_event( $evl, 1 ); # $ev is filled by the API; yes, this will change before v1.0
```

# Constants

TODO: These aren't fleshed out yet, I'm thinking of grabbing them from the C
side of FFI::Platypus.

You may import these by name or with the following tags:

## `:keys`

These are a safe subset of terminfo keys which exist on all popular terminals.
Termbox only uses them to stay truly portable. See also Termbox::Event's `key(
)` method.

TODO: For now, please see
https://github.com/nsf/termbox/blob/master/src/termbox.h for the list

## `:modifier`

Modifier constants. See Termbox::Event's `mod( )` method and the
`tb_select_input_mode( )` function.

- `TB_MOD_ALT` - Alt key modifier.
- `TB_MOD_MOTION` - Mouse motion modifier

## `:color`

See Termbox::Cell's `fg( )` and `bg( )` values.

- `TB_DEFAULT`
- `TB_BLACK`
- `TB_RED`
- `TB_GREEN`
- `TB_YELLOW`
- `TB_BLUE`
- `TB_MAGENTA`
- `TB_CYAN`
- `TB_WHITE`

## `:font`

Attributes, it is possible to use multiple attributes by combining them using
bitwise OR (`|`). Although, colors cannot be combined. But you can combine
attributes and a single color. See also Termbox::Cell's `fg( )` and `bg( )`
methods.

- `TB_BOLD`
- `TB_UNDERLINE`
- `TB_REVERSE`

## `:event`

- `TB_EVENT_KEY`
- `TB_EVENT_RESIZE`
- `TB_EVENT_MOUSE`

## `:error`

Error codes returned by `tb_init( )`. A claim is made that all of them are
self-explanatory except the pipe trap error. Termbox uses unix pipes in order
to deliver a message from a signal handler (`SIGWINCH`) to the main event
reading loop. Honestly in most cases you should just check the returned code as
`<< 0`>.

- `TB_EUNSUPPORTED_TERMINAL`
- `TB_EFAILED_TO_OPEN_TTY`
- `TB_EPIPE_TRAP_ERROR`

## `:cursor`

- `TB_HIDE_CURSOR` - Pass this to `tb_set_cursor( $x, $y )` to hide the cursor

## `:input`

Pass one of these to `tb_select_input_mode( $mode )`:

- `TB_INPUT_CURRENT`
- `TB_INPUT_ESC`
- `TB_INPUT_ALT`
- `TB_INPUT_MOUSE`

## `:output`

Pass one of these to `tb_select_output_mode( $mode )`:

- `TB_OUTPUT_CURRENT`
- `TB_OUTPUT_NORMAL`
- `TB_OUTPUT_256`
- `TB_OUTPUT_216`
- `TB_OUTPUT_GRAYSCALE`

# Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

CPAN ID: SANKO

# License and Legal

Copyright (C) 2020-2023 by Sanko Robinson <sanko@cpan.org>

This program is free software; you can redistribute it and/or modify it under
the terms of The Artistic License 2.0. See
http://www.perlfoundation.org/artistic\_license\_2\_0.  For clarification, see
http://www.perlfoundation.org/artistic\_2\_0\_notes.

When separated from the distribution, all POD documentation is covered by the
Creative Commons Attribution-Share Alike 3.0 License. See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For clarification,
see http://creativecommons.org/licenses/by-sa/3.0/us/.
