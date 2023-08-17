[![Actions Status](https://github.com/sanko/Termbox.pm/actions/workflows/ci.yaml/badge.svg)](https://github.com/sanko/Termbox.pm/actions) [![MetaCPAN Release](https://badge.fury.io/pl/Termbox.svg)](https://metacpan.org/release/Termbox)
# NAME

Termbox - Create Text-based User Interfaces Without ncurses

# SYNOPSIS

```perl
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
```

# DESCRIPTION

Termbox is a terminal rendering library that retains the
[suckless](https://suckless.org/coding_style/) spirit of the original termbox
(simple API, no dependencies beyond libc) and adds some improvements:

- strict error checking
- more efficient escape sequence parsing
- code gen for built-in escape sequences
- opt-in support for 32-bit color
- extended grapheme clusters

## Note

This module wraps `libtermbox2`, an incompatible fork of the now abandoned
`libtermbox`. I'm not sure why you would but if you're looking for the
original, try any version of [Termbox](https://metacpan.org/pod/Termbox).pm before 2.0.

# Functions

Termbox's API is very small. You can build most UIs with just a few functions.
Import them by name or with `:all`.

## `tb_init( )`

Initializes the termbox2 library. This function should be called before any
other functions. Calling this is the same as `tb_init_file('/dev/tty')`. After
successful initialization, the library must be finalized using the
`tb_shutdown( )` function.

If this returns anything other than `0`, it didn't work.

## `tb_init_file( $name )`

This function will init the termbox2 library on the file name provided.

## `tb_init_fd( $fileno )`

This function will init the termbox2 library on the provided filehandle. This
is untested.

## `tb_init_rwfd( $rfileno, $wfileno )`

This function will init the termbox2 library on the provided filehandles. This
is untested.

## `tb_shutdown( )`

Causes the termbox2 library to attempt to clean up after itself.

## `tb_width( )`

Returns the horizontal size of the internal back buffer (which is the same as
terminal's window size in columns).

The internal buffer can be resized after `tb_clear( )` or `tb_present( )`
function calls. This function returns an unspecified negative value when called
before `tb_init( )` or after `tb_shutdown( )`.

## `tb_height( )`

Returns the vertical size of the internal back buffer (which is the same as
terminal's window size in rows).

The internal buffer can be resized after `tb_clear( )` or `tb_present( )`
function calls. This function returns an unspecified negative value when called
before `tb_init( )` or after `tb_shutdown( )`.

## `tb_clear( )`

Clears the internal back buffer using `TB_DEFAULT` color or the
color/attributes set by `tb_set_clear_attrs( )` function.

## `tb_set_clear_attrs( $fg, $bg )`

Overrides the use of `TB_DEFAULT` to clear the internal back buffer when
`tb_clear( )` is called.

## `tb_present( )`

Synchronizes the internal back buffer with the terminal by writing to tty.

## `tb_invalidate( )`

Clears the internal front buffer effectively forcing a complete re-render of
the back buffer to the tty. It is not necessary to call this under normal
circumstances.

## `tb_set_cursor( $x, $y )`

Sets the position of the cursor. Upper-left character is `(0, 0)`.

## `tb_hide_cursor( )`

Hides the cursor.

## `tb_set_cell( $x, $y, $ch, $fg, $bg )`

Set cell contents in the internal back buffer at the specified position.

Function `tb_set_cell($x, $y, $ch, $fg, $bg)`is equivalent to
`tb_set_cell_ex($x, $y, $ch, 1, $fg, $bg)`.

## `tb_set_cell_ex( $x, $y, $ch, $nch, $fg, $bg )`

Set cell contents in the internal back buffer at the specified position. Use
this function for rendering grapheme clusters (e.g., combining diacritical
marks).

## `tb_extend_cell( $x, $y, $ch )`

Shortcut to append 1 code point to the given cell.

## `tb_set_input_mode( $mode )`

Sets the input mode. Termbox has two input modes:

- 1. `TB_INPUT_ESC`

    When escape (`\x1b`) is in the buffer and there's no match for an escape
    sequence, a key event for TB\_KEY\_ESC is returned.

- 2. `TB_INPUT_ALT`

    When escape (`\x1b`) is in the buffer and there's no match for an escape
    sequence, the next keyboard event is returned with a `TB_MOD_ALT` modifier.

You can also apply `TB_INPUT_MOUSE` via bitwise OR operation to either of the
modes (e.g., `TB_INPUT_ESC | TB_INPUT_MOUSE`) to receive `TB_EVENT_MOUSE`
events. If none of the main two modes were set, but the mouse mode was,
`TB_INPUT_ESC` mode is used. If for some reason you've decided to use
(`TB_INPUT_ESC | TB_INPUT_ALT`) combination, it will behave as if only
`TB_INPUT_ESC` was selected.

If mode is `TB_INPUT_CURRENT`, the function returns the current input mode.

The default input mode is `TB_INPUT_ESC`.

## `tb_set_output_mode( $mode )`

Sets the termbox2 output mode. Termbox has multiple output modes:

- 1. `TB_OUTPUT_NORMAL` => \[0..8\]

    This mode provides 8 different colors: `TB_BLACK`, `TB_RED`, `TB_GREEN`,
    `TB_YELLOW`, `TB_BLUE`, `TB_MAGENTA`, `TB_CYAN`, `TB_WHITE`

    Plus `TB_DEFAULT` which skips sending a color code (i.e., uses the terminal's
    default color).

    Colors (including `TB_DEFAULT`) may be bitwise OR'd with attributes:
    `TB_BOLD`, `TB_UNDERLINE`, `TB_REVERSE`, `TB_ITALIC`, `TB_BLINK`

    As in all modes, the value `0` is interpreted as `TB_DEFAULT` for
    convenience.

    Some notes: `TB_REVERSE` can be applied as either fg or bg attributes for the
    same effect. `TB_BOLD`, `TB_UNDERLINE`, `TB_ITALIC`, `TB_BLINK` apply as fg
    attributes only, and are ignored as bg attributes.

    Example usage:

    ```
    tb_set_cell($x, $y, '@', TB_BLACK | TB_BOLD, TB_RED);
    ```

- 2. `TB_OUTPUT_256` => \[0..255\] + `TB_256_BLACK`

    In this mode you get 256 distinct colors (plus default):

    ```
                0x00   (1): TB_DEFAULT
        TB_256_BLACK   (1): TB_BLACK in TB_OUTPUT_NORMAL
          0x01..0x07   (7): the next 7 colors as in TB_OUTPUT_NORMAL
          0x08..0x0f   (8): bright versions of the above
          0x10..0xe7 (216): 216 different colors
          0xe8..0xff  (24): 24 different shades of gray
    ```

    Attributes may be bitwise OR'd as in `TB_OUTPUT_NORMAL`.

    Note `TB_256_BLACK` must be used for black, as `0x00` represents default.

- 3. `TB_OUTPUT_216` => \[0..216\]

    This mode supports the 216-color range of `TB_OUTPUT_256` only, but you don't
    need to provide an offset:

    ```
                0x00   (1): TB_DEFAULT
          0x01..0xd8 (216): 216 different colors
    ```

- 4. `TB_OUTPUT_GRAYSCALE` => \[0..24\]

    This mode supports the 24-color range of `TB_OUTPUT_256` only, but you don't
    need to provide an offset:

    ```
                0x00   (1): TB_DEFAULT
          0x01..0x18  (24): 24 different shades of gray
    ```

- 5. `TB_OUTPUT_TRUECOLOR` => \[0x000000..0xffffff\] + `TB_TRUECOLOR_BLACK`

    This mode provides 24-bit color on supported terminals. The format is
    `0xRRGGBB`. Colors may be bitwise OR'd with `TB_TRUECOLOR_*` attributes.

    Note `TB_TRUECOLOR_BLACK` must be used for black, as `0x000000` represents
    default.

If mode is `TB_OUTPUT_CURRENT`, the function returns the current output mode.

The default output mode is `TB_OUTPUT_NORMAL`.

To use the terminal default color (i.e., to not send an escape code), pass
`TB_DEFAULT`. For convenience, the value `0` is interpreted as `TB_DEFAULT`
in all modes.

Note, cell attributes persist after switching output modes. Any translation
between, for example, `TB_OUTPUT_NORMAL`'s `TB_RED` and
`TB_OUTPUT_TRUECOLOR`'s `0xff0000` must be performed by the caller. Also note
that cells previously rendered in one mode may persist unchanged until the
front buffer is cleared (such as after a resize event) at which point it will
be re-interpreted and flushed according to the current mode. Callers may invoke
`tb_invalidate( )` if it is desirable to immediately re-interpret and flush
the entire screen according to the current mode.

Note, not all terminals support all output modes, especially beyond
`TB_OUTPUT_NORMAL`. There is also no very reliable way to determine color
support dynamically. If portability is desired, callers are recommended to use
`TB_OUTPUT_NORMAL` or make output mode end-user configurable.

## `tb_peek_event( $event, $timeout_ms )`

Wait for an event up to `$timeout_ms` milliseconds and fill the $event
structure with it. If no event is available within the timeout period,
`TB_ERR_NO_EVENT` is returned. On a resize event, the underlying `select(2)`
call may be interrupted, yielding a return code of `TB_ERR_POLL`. In this
case, you may check `errno` via `tb_last_errno( )`. If it's `EINTR`, you can
safely ignore that and call `tb_peek_event( )` again.

## `tb_poll_event( $event )`

Same as `tb_peek_event( $event, $timeout_ms )` except no timeout.

## `tb_get_fds( \$ttyfd, \$resizefd )`

Internal termbox2 FDs that can be used with `poll()` / `select()`. Must call
`tb_poll_event( $event )` / `tb_peek_event( $event, $timeout_ms )` if
activity is detected.

## `tb_print( $x, $y, $fg, $bg, $str )`

It prints text.

## `tb_send( $buf, $nbuf )`

Send raw bytes to terminal.

## `tb_set_func( $fn_type, $fn )`

Set custom functions. `$fn_type` is one of `TB_FUNC_*` constants, `fn` is a
compatible function pointer, or `undef` to clear.

- `TB_FUNC_EXTRACT_PRE`

    If specified, invoke this function BEFORE termbox2 tries to extract any escape
    sequences from the input buffer.

- `TB_FUNC_EXTRACT_POST`

    If specified, invoke this function AFTER termbox2 tries (and fails) to extract
    any escape sequences from the input buffer.

## `tb_utf8_char_length( $c )`

Returns the length of a utf8 encoded character.

## `tb_utf8_char_to_unicode( \$out, $c )`

Converts a utf8 encoded character to Unicode.

## `tb_utf8_unicode_to_char( \$out, $c )`

Converts a Unicode character to utf8.

## `tb_last_errno( )`

Returns the last `errno`.

## `tb_strerror( $err )`

Returns a string describing the given error.

## `tb_cell_buffer( )`

Returns the current cell buffer.

## `tb_has_truecolor( )`

Returns a true value if truecolor values are supported.

## `tb_has_egc( )`

Returns a true value if Unicode's extended grapheme clusters are supported.

## Ctb\_version( )>

Returns the version string of the wrapped libtermbox2.

# Constants

You may import these by name or with the following tags:

## `:keys`

These are a safe subset of terminfo keys which exist on all popular terminals.
Termbox only uses them to stay truly portable. See also Termbox::Event's `key(
)` method.

Please see
[termbox2.h](https://github.com/termbox/termbox2/blob/1e0092b50ee96f5993f456e8ecdb06044a38b8eb/termbox2.h#L79)
for the list

## `:color`

These are foreground and background color values.

Please see
[termbox2.h](https://github.com/termbox/termbox2/blob/1e0092b50ee96f5993f456e8ecdb06044a38b8eb/termbox2.h#L204)
for the list

## `:event`

Please see
[termbox2.h](https://github.com/termbox/termbox2/blob/1e0092b50ee96f5993f456e8ecdb06044a38b8eb/termbox2.h#L229)
for the list

## `:return`

Common function return values unless otherwise noted.

Library behavior is undefined after receiving `TB_ERR_MEM`. Callers may
attempt reinitializing by freeing memory, invoking `tb_shutdown( )`, then
`tb_init( )`.

Please see
[termbox2.h](https://github.com/termbox/termbox2/blob/1e0092b50ee96f5993f456e8ecdb06044a38b8eb/termbox2.h#L256)
for the list

## `:func`

Function types to be used with `tb_set_func( $fn_type, $func )`.

Please see
[termbox2.h](https://github.com/termbox/termbox2/blob/1e0092b50ee96f5993f456e8ecdb06044a38b8eb/termbox2.h#L289)
for the list

# LICENSE

Copyright (C) Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under
the terms found in the Artistic License 2. Other copyrights, terms, and
conditions may apply to data transmitted through this module.

# AUTHOR

Sanko Robinson <sanko@cpan.org>
