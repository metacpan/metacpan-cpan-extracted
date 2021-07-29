# NAME

TCOD - FFI bindings for libtcod

# SYNOPSIS

    use TCOD;
    use File::Share 'dist_file';

    use constant {
        WIDTH  => 80,
        HEIGHT => 60,
    };

    my $tileset = TCOD::Tileset->load_tilesheet(
        path    => dist_file( TCOD => 'fonts/dejavu10x10_gs_tc.png' ),
        columns => 32,
        rows    => 8,
        charmap => TCOD::CHARMAP_TCOD,
    );

    my $context = TCOD::Context->new(
        columns => WIDTH,
        rows    => HEIGHT,
        tileset => $tileset,
    );

    my $console = $context->new_console;

    while (1) {
        $console->clear;
        $console->print( 0, 0, 'Hello World!' );
        $context->present( $console );

        my $iter = TCOD::Event::wait;
        while ( my $event = $iter->() ) {
            $context->convert_event($event);
            print $event->as_string . "\n";
            exit if $event->type eq 'QUIT';
        }
    }

# DESCRIPTION

TCOD offers Perl bindings to libtcod, a library for developing roguelike games.

If you're getting started, see [TCOD::Context](https://metacpan.org/pod/TCOD%3A%3AContext) to manage rendering contexts
and [TCOD::Tileset](https://metacpan.org/pod/TCOD%3A%3ATileset) to load custom fonts to display. [TCOD::Event](https://metacpan.org/pod/TCOD%3A%3AEvent) can be
used to interact with input and system events. If you want to calculate
line-of-sight within a map you can use [TCOD::Map](https://metacpan.org/pod/TCOD%3A%3AMap), which can also be used
by [TCOD::Path](https://metacpan.org/pod/TCOD%3A%3APath) for path-finding.

## On Stability

This distribution is currently **experimental**, and as such, its API might
still change without warning. Any change, breaking or not, will be noted in
the change log, so if you wish to use it, please pin your dependencies and
make sure to check the change log before upgrading.

# FUNCTIONS

## get\_error

    $string = TCOD::get_error;

Get the current error message, if any.

Some functions (eg. [TCOD::Context::new](https://metacpan.org/pod/TCOD%3A%3AContext#new) will set this
string on error. When an error is indicated, you can use this method to
retrieve the error.

The string returned by this function is only meaningful if an error has been
indicated by some other function, and will only remain meaningful until a new
function that uses this mechanism is called.

# ENUMS

The enums listed below are available as constants like the ones defined using
[constant](https://metacpan.org/pod/constant), which means the same caveats apply here.

To provide introspection into the values of the enums, they are also made
available as package variables with the names of each enum. This makes it
possible to get the name of a value in a given enum with code like the
following:

    say $TCOD::Alignment{ TCOD::LEFT }; # Prints 'LEFT'

## Alignment

- TCOD::LEFT
- TCOD::RIGHT
- TCOD::CENTER

## Charmap

- TCOD::CHARMAP\_TCOD
- TCOD::CHARMAP\_CP437

## Renderer

- TCOD::RENDERER\_GLSL
- TCOD::RENDERER\_OPENGL
- TCOD::RENDERER\_SDL
- TCOD::RENDERER\_SDL2
- TCOD::RENDERER\_OPENGL2
- TCOD::NB\_RENDERERS

## BackgroundFlag

This flag is used by most functions that modify a cell background colour. It
defines how the console's current background color is used to modify the
cell's existing background color.

See the documentation for [TCOD::Color](https://metacpan.org/pod/TCOD%3A%3AColor#COLOR-ARITHMETIC) for
details on how color arithmetic works when referenced below.

When equations are listed below, these are applied to each individual
component in turn, with `new` being the component for the new color, `old`
being the one for the current one, and `white` standing in for the maximum
value for a color component (255).

- TCOD::BKGND\_NONE

    The cell's background is not modified.

- TCOD::BKGND\_SET

    The cell's background is replaced with the new color.

- TCOD::BKGND\_MULTIPLY

    The cell's background is multiplied with the new color.

- TCOD::BKGND\_LIGHTEN

    Each of the components of the cell's background is replaced with the
    respective component of the new color if it is lighter.

- TCOD::BKGND\_DARKEN

    Each of the components of the cell's background is replaced with the
    respective component of the new color if it is darker.

- TCOD::BKGND\_SCREEN

    The cell's background color is modified according to the following operation:

        white - ( white - old ) * ( white - new )

- TCOD::BKGND\_COLOR\_DODGE

    The cell's background color is modified according to the following operation:

        new / ( white - old )

- TCOD::BKGND\_COLOR\_BURN

    The cell's background color is modified according to the following operation:

        white - ( white - old ) / new

- TCOD::BKGND\_ADD

    The new color is added to the cell's background.

- TCOD::BKGND\_ADDALPHA

    Use this as a macro with a float parameter between 0 and 1. The cell's
    background color is modified according to the following operation:

        old + alpha * new

- TCOD::BKGND\_BURN

    The cell's background color is modified according to the following operation:

        old + new - white

- TCOD::BKGND\_OVERLAY

    The cell's background color is modified according to the following operation:

        2 * new * old                                 # if the component is >= 128
        white - 2 * ( white - new ) * ( white - old ) # if the component is <  128

- TCOD::BKGND\_ALPHA

    Use this as a macro with a float parameter between 0 and 1. The cell's
    background color is modified according to the following operation:

        ( 1 - alpha ) * old + alpha * ( new - old )

- TCOD::BKGND\_DEFAULT

    Use the console's default background flag. See
    [TCOD::Console::set\_background\_flag](https://metacpan.org/pod/TCOD%3A%3AConsole#set_background_flag).

## ColorControl

- TCOD::COLCTRL\_1
- TCOD::COLCTRL\_2
- TCOD::COLCTRL\_3
- TCOD::COLCTRL\_4
- TCOD::COLCTRL\_5
- TCOD::COLCTRL\_NUMBER
- TCOD::COLCTRL\_FORE\_RGB
- TCOD::COLCTRL\_BACK\_RGB
- TCOD::COLCTRL\_STOP

## Keycode

- TCOD::K\_NONE
- TCOD::K\_ESCAPE
- TCOD::K\_BACKSPACE
- TCOD::K\_TAB
- TCOD::K\_ENTER
- TCOD::K\_SHIFT
- TCOD::K\_CONTROL
- TCOD::K\_ALT
- TCOD::K\_PAUSE
- TCOD::K\_CAPSLOCK
- TCOD::K\_PAGEUP
- TCOD::K\_PAGEDOWN
- TCOD::K\_END
- TCOD::K\_HOME
- TCOD::K\_UP
- TCOD::K\_LEFT
- TCOD::K\_RIGHT
- TCOD::K\_DOWN
- TCOD::K\_PRINTSCREEN
- TCOD::K\_INSERT
- TCOD::K\_DELETE
- TCOD::K\_LWIN
- TCOD::K\_RWIN
- TCOD::K\_APPS
- TCOD::K\_0
- TCOD::K\_1
- TCOD::K\_2
- TCOD::K\_3
- TCOD::K\_4
- TCOD::K\_5
- TCOD::K\_6
- TCOD::K\_7
- TCOD::K\_8
- TCOD::K\_9
- TCOD::K\_KP0
- TCOD::K\_KP1
- TCOD::K\_KP2
- TCOD::K\_KP3
- TCOD::K\_KP4
- TCOD::K\_KP5
- TCOD::K\_KP6
- TCOD::K\_KP7
- TCOD::K\_KP8
- TCOD::K\_KP9
- TCOD::K\_KPADD
- TCOD::K\_KPSUB
- TCOD::K\_KPDIV
- TCOD::K\_KPMUL
- TCOD::K\_KPDEC
- TCOD::K\_KPENTER
- TCOD::K\_F1
- TCOD::K\_F2
- TCOD::K\_F3
- TCOD::K\_F4
- TCOD::K\_F5
- TCOD::K\_F6
- TCOD::K\_F7
- TCOD::K\_F8
- TCOD::K\_F9
- TCOD::K\_F10
- TCOD::K\_F11
- TCOD::K\_F12
- TCOD::K\_NUMLOCK
- TCOD::K\_SCROLLLOCK
- TCOD::K\_SPACE
- TCOD::K\_CHAR
- TCOD::K\_TEXT

## Char

- TCOD::CHAR\_HLINE
- TCOD::CHAR\_VLINE
- TCOD::CHAR\_NE
- TCOD::CHAR\_NW
- TCOD::CHAR\_SE
- TCOD::CHAR\_SW
- TCOD::CHAR\_TEEW
- TCOD::CHAR\_TEEE
- TCOD::CHAR\_TEEN
- TCOD::CHAR\_TEES
- TCOD::CHAR\_CROSS
- TCOD::CHAR\_DHLINE
- TCOD::CHAR\_DVLINE
- TCOD::CHAR\_DNE
- TCOD::CHAR\_DNW
- TCOD::CHAR\_DSE
- TCOD::CHAR\_DSW
- TCOD::CHAR\_DTEEW
- TCOD::CHAR\_DTEEE
- TCOD::CHAR\_DTEEN
- TCOD::CHAR\_DTEES
- TCOD::CHAR\_DCROSS
- TCOD::CHAR\_BLOCK1
- TCOD::CHAR\_BLOCK2
- TCOD::CHAR\_BLOCK3
- TCOD::CHAR\_ARROW\_N
- TCOD::CHAR\_ARROW\_S
- TCOD::CHAR\_ARROW\_E
- TCOD::CHAR\_ARROW\_W
- TCOD::CHAR\_ARROW2\_N
- TCOD::CHAR\_ARROW2\_S
- TCOD::CHAR\_ARROW2\_E
- TCOD::CHAR\_ARROW2\_W
- TCOD::CHAR\_DARROW\_H
- TCOD::CHAR\_DARROW\_V
- TCOD::CHAR\_CHECKBOX\_UNSET
- TCOD::CHAR\_CHECKBOX\_SET
- TCOD::CHAR\_RADIO\_UNSET
- TCOD::CHAR\_RADIO\_SET
- TCOD::CHAR\_SUBP\_NW
- TCOD::CHAR\_SUBP\_NE
- TCOD::CHAR\_SUBP\_N
- TCOD::CHAR\_SUBP\_SE
- TCOD::CHAR\_SUBP\_DIAG
- TCOD::CHAR\_SUBP\_E
- TCOD::CHAR\_SUBP\_SW
- TCOD::CHAR\_SMILIE
- TCOD::CHAR\_SMILIE\_INV
- TCOD::CHAR\_HEART
- TCOD::CHAR\_DIAMOND
- TCOD::CHAR\_CLUB
- TCOD::CHAR\_SPADE
- TCOD::CHAR\_BULLET
- TCOD::CHAR\_BULLET\_INV
- TCOD::CHAR\_MALE
- TCOD::CHAR\_FEMALE
- TCOD::CHAR\_NOTE
- TCOD::CHAR\_NOTE\_DOUBLE
- TCOD::CHAR\_LIGHT
- TCOD::CHAR\_EXCLAM\_DOUBLE
- TCOD::CHAR\_PILCROW
- TCOD::CHAR\_SECTION
- TCOD::CHAR\_POUND
- TCOD::CHAR\_MULTIPLICATION
- TCOD::CHAR\_FUNCTION
- TCOD::CHAR\_RESERVED
- TCOD::CHAR\_HALF
- TCOD::CHAR\_ONE\_QUARTER
- TCOD::CHAR\_COPYRIGHT
- TCOD::CHAR\_CENT
- TCOD::CHAR\_YEN
- TCOD::CHAR\_CURRENCY
- TCOD::CHAR\_THREE\_QUARTERS
- TCOD::CHAR\_DIVISION
- TCOD::CHAR\_GRADE
- TCOD::CHAR\_UMLAUT
- TCOD::CHAR\_POW1
- TCOD::CHAR\_POW3
- TCOD::CHAR\_POW2
- TCOD::CHAR\_BULLET\_SQUARE

## FontFlag

- TCOD::FONT\_LAYOUT\_ASCII\_INCOL
- TCOD::FONT\_LAYOUT\_ASCII\_INROW
- TCOD::FONT\_TYPE\_GREYSCALE
- TCOD::FONT\_TYPE\_GRAYSCALE
- TCOD::FONT\_LAYOUT\_TCOD
- TCOD::FONT\_LAYOUT\_CP437

## FOV

- TCOD::FOV\_BASIC
- TCOD::FOV\_DIAMOND
- TCOD::FOV\_SHADOW
- TCOD::FOV\_PERMISSIVE\_0
- TCOD::FOV\_PERMISSIVE\_1
- TCOD::FOV\_PERMISSIVE\_2
- TCOD::FOV\_PERMISSIVE\_3
- TCOD::FOV\_PERMISSIVE\_4
- TCOD::FOV\_PERMISSIVE\_5
- TCOD::FOV\_PERMISSIVE\_6
- TCOD::FOV\_PERMISSIVE\_7
- TCOD::FOV\_PERMISSIVE\_8
- TCOD::FOV\_RESTRICTIVE
- TCOD::FOV\_SYMMETRIC\_SHADOWCAST
- TCOD::NB\_FOV\_ALGORITHMS

## RandomAlgo

- TCOD::RNG\_MT
- TCOD::RNG\_CMWC

## Distribution

These values are used by [TCOD::Random](https://metacpan.org/pod/TCOD%3A%3ARandom) to generate random numbers.

- TCOD::DISTRIBUTION\_LINEAR

    This is the default distribution. It will return a number from a range
    min-max. The numbers will be evenly distributed, ie, each number from the
    range has the exact same chance of being selected.

- TCOD::DISTRIBUTION\_GAUSSIAN

    This distribution does not have minimum and maximum values. Instead, a mean
    and a standard deviation are used. The mean is the central value. It will
    appear with the greatest frequency. The farther away from the mean, the less
    the probability of appearing the possible results have. Although extreme
    values are possible, 99.7% of the results will be within the radius of 3
    standard deviations from the mean. So, if the mean is 0 and the standard
    deviation is 5, the numbers will mostly fall in the (-15,15) range.

- TCOD::DISTRIBUTION\_GAUSSIAN\_RANGE

    This one takes minimum and maximum values. Under the hood, it computes the
    mean (which falls right between the minimum and maximum) and the standard
    deviation and applies a standard Gaussian distribution to the values. The
    difference is that the result is always guaranteed to be in the min-max
    range.

- TCOD::DISTRIBUTION\_GAUSSIAN\_INVERSE

    Essentially, this is the same as `TCOD::DISTRIBUTION_GAUSSIAN`. The
    difference is that the values near +3 and -3 standard deviations from the
    mean have the highest possibility of appearing, while the mean has the lowest.

- TCOD::DISTRIBUTION\_GAUSSIAN\_RANGE\_INVERSE

    Essentially, this is the same as `TCOD::DISTRIBUTION_GAUSSIAN_RANGE`, but
    the min and max values have the greatest probability of appearing, while the
    values between them, the lowest.

## NoiseType

- TCOD::NOISE\_PERLIN
- TCOD::NOISE\_SIMPLEX
- TCOD::NOISE\_WAVELET
- TCOD::NOISE\_DEFAULT

## Event

- TCOD::EVENT\_NONE
- TCOD::EVENT\_KEY\_PRESS
- TCOD::EVENT\_KEY\_RELEASE
- TCOD::EVENT\_MOUSE\_MOVE
- TCOD::EVENT\_MOUSE\_PRESS
- TCOD::EVENT\_MOUSE\_RELEASE
- TCOD::EVENT\_KEY
- TCOD::EVENT\_MOUSE
- TCOD::EVENT\_ANY

# SHARE DATA

This distribution bundles some data to make development simpler.

You can make use of this data with a distribution like [File::Share](https://metacpan.org/pod/File%3A%3AShare),
like in this example:

    use File::Share 'dist_file';
    my $path = dist_file TCOD => 'fonts/dejavu10x10_gs_tc.png';

The `fonts` directory contains antialiased fonts that can be used with
TCOD. The names of the font files are of the form:

    <font_name><font_size>_<type>_<layout>.png

    <type>   : aa 32 bits png with alpha channel
               gs 24 bits or greyscale PNG

    <layout> : as standard ASCII layout
               ro standard ASCII layout in row
               tc TCOD layout

The `terminal8x8` font is provided is every possible format as en example.

The structure of shared files is reproduced below.

    share
    └── fonts
        ├── dejavu10x10_gs_tc.png
        ├── dejavu12x12_gs_tc.png
        ├── dejavu16x16_gs_tc.png
        ├── dejavu8x8_gs_tc.png
        ├── dejavu_wide12x12_gs_tc.png
        ├── dejavu_wide16x16_gs_tc.png
        ├── terminal10x10_gs_tc.png
        ├── terminal10x16_gs_ro.png
        ├── terminal10x16_gs_tc.png
        ├── terminal10x18_gs_ro.png
        ├── terminal12x12_gs_ro.png
        ├── terminal16x16_gs_ro.png
        ├── terminal7x7_gs_tc.png
        ├── terminal8x12_gs_ro.png
        ├── terminal8x12_gs_tc.png
        ├── terminal8x14_gs_ro.png
        ├── terminal8x8_aa_ro.png
        ├── terminal8x8_aa_tc.png
        ├── terminal8x8_gs_ro.png
        ├── terminal8x8_gs_tc.png
        └── ucs-fonts
            └── 4x6.bdf

# SEE ALSO

- [TCOD::Color](https://metacpan.org/pod/TCOD%3A%3AColor)
- [TCOD::ColorRGBA](https://metacpan.org/pod/TCOD%3A%3AColorRGBA)
- [TCOD::Console](https://metacpan.org/pod/TCOD%3A%3AConsole)
- [TCOD::Context](https://metacpan.org/pod/TCOD%3A%3AContext)
- [TCOD::Dijkstra](https://metacpan.org/pod/TCOD%3A%3ADijkstra)
- [TCOD::Event](https://metacpan.org/pod/TCOD%3A%3AEvent)
- [TCOD::Image](https://metacpan.org/pod/TCOD%3A%3AImage)
- [TCOD::Key](https://metacpan.org/pod/TCOD%3A%3AKey)
- [TCOD::Map](https://metacpan.org/pod/TCOD%3A%3AMap)
- [TCOD::Mouse](https://metacpan.org/pod/TCOD%3A%3AMouse)
- [TCOD::Noise](https://metacpan.org/pod/TCOD%3A%3ANoise)
- [TCOD::Path](https://metacpan.org/pod/TCOD%3A%3APath)
- [TCOD::Random](https://metacpan.org/pod/TCOD%3A%3ARandom)
- [TCOD::Sys](https://metacpan.org/pod/TCOD%3A%3ASys)
- [TCOD::Tileset](https://metacpan.org/pod/TCOD%3A%3ATileset)

Also, these other external resources might be useful:

- [libtcod](https://github.com/libtcod/libtcod)
- [rogueliketutorials.com](https://rogueliketutorials.com)
- [/r/roguelikedev](https://www.reddit.com/r/roguelikedev)
- [RogueBasin](http://roguebasin.com)

# COPYRIGHT AND LICENSE

Copyright 2021 José Joaquín Atria

This library is free software; you can redistribute it and/or modify it under
the Artistic License 2.0.
