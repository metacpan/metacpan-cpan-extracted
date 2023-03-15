[![Actions Status](https://github.com/tecolicom/Term-ANSIColor-Concise/workflows/test/badge.svg)](https://github.com/tecolicom/Term-ANSIColor-Concise/actions) [![MetaCPAN Release](https://badge.fury.io/pl/Term-ANSIColor-Concise.svg)](https://metacpan.org/release/Term-ANSIColor-Concise)
# NAME

Term::ANSIColor::Concise - Produce ANSI terminal sequence by concise notation

# SYNOPSIS

    use v5.14;
    use Term::ANSIColor::Concise qw(ansi_color);

    say ansi_color('R', 'This is Red');

    say ansi_color('SDG', 'This is Reverse Bold Green');

    say ansi_color('FUDI<Gold>/L10E',
                   'Flashing Underlined Bold Italic Gold on Gray10 Bar');

<div>
    <p><img width="750" src="https://raw.githubusercontent.com/tecolicom/Term-ANSIColor-Concise/main/images/synopsis.png">
</div>

# VERSION

Version 2.0201

# DESCRIPTION

This module provides a simple concise format to describe complicated
colors and effects for ANSI terminals.  These notations are supposed to
be used in command line option parameters.

This module used to be a part of [Getopt::EX::Colormap](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3AColormap) module, which
provide easy handling interface for command line options.

## 256 or 24bit COLORS

By default, this library produces ANSI 256 color sequence.  That is
eight standard colors, eight high intensity colors, 6x6x6 216 colors,
and gray scales in 24 steps.

Color described by 12bit/24bit RGB values are converted to 6x6x6 216
colors, or 24 gray scales if all RGB values are same.

For a terminal which can display 24bit colors, full-color sequence can
be produced.  See ["ENVIRONMENT"](#environment) section.

# FUNCTION

- **ansi\_color**(_spec_, _text_)

    Return colorized version of given text.  Produces 256 or 24bit colors
    depending on the setting.

    In the result, given _text_ is enclosed by appropriate open/close
    sequences.  Close sequence can vary according to the open sequence.
    See ["RESET SEQUENCE"](#reset-sequence) section.

    If the _text_ already includes colored regions, they remain untouched
    and only non-colored parts are colored.

    Actually, _spec_ and _text_ pair can be repeated as many as
    possible.  It is same as calling the function multiple times with
    single pair and join results.

- **ansi\_color**(\[ _spec1_, _spec2_, ... \], _text_)

    If _spec_ parameter is ARRAYREF, multiple _spec_s can be specified
    at once.  This is not useful for color spec because they can be simply
    joined, but may be useful when mixed with ["FUNCTION SPEC"](#function-spec).

- **ansi\_color\_24**(_spec_, _text_)
- **ansi\_color\_24**(\[ _spec1_, _spec2_, ... \], _text_)

    Function **ansi\_color\_24** always produces 24bit color sequence for
    12bit/24bit color spec.

- **cached\_ansi\_color**(_cache_, _spec_, _text_)

    Backend interface for **ansi\_color**.  First parameter is a hash object
    used to cache data.  If you concern about cache mismatch situation,
    use this interface with original cache.

- **ansi\_pair**(_color\_spec_)

    Produces introducer and recover sequences for given spec.

    Additional third value indicates if the introducer includes Erase Line
    sequence.  It gives a hint the sequence is necessary for empty string.
    See ["RESET SEQUENCE"](#reset-sequence).

- **ansi\_code**(_color\_spec_)

    Produces introducer sequence for given spec.  Reset code can be taken
    by **ansi\_code("Z")**.

- **csi\_code**(_name_, _params_)

    Produce CSI (Control Sequence Introducer) sequence by name with
    numeric parameters.  Parameter _name_ is one of standard (CUU, CUD,
    CUF, CUB, CNL, CPL, CHA, CUP, ED, EL, SU, SD, HVP, SGR, SCP, RCP) or
    non-standard (RIS, DECSC, DECRC).

# COLOR SPEC

At first the color is considered as foreground, and slash (`/`)
switches foreground and background.  You can declare any number of
components in arbitrary order, and sequences will be produced in the
order of their presence.  So if they conflicts, the later one
overrides the earlier.

Color specification is a combination of following components:

## BASIC 8+8

Single uppercase character representing 8 colors, and alternative
(usually brighter) colors in lowercase :

    R  r  Red
    G  g  Green
    B  b  Blue
    C  c  Cyan
    M  m  Magenta
    Y  y  Yellow
    K  k  Black
    W  w  White

## EFFECTS and CONTROLS

Single case-insensitive character for special effects :

    N    None
    Z  0 Zero (reset)
    D  1 Double strike (boldface)
    P  2 Pale (dark)
    I  3 Italic
    U  4 Underline
    F  5 Flash (blink: slow)
    Q  6 Quick (blink: rapid)
    S  7 Stand out (reverse video)
    H  8 Hide (conceal)
    X  9 Cross out

    E    Erase Line (fill by background color)

    ;    No effect
    /    Toggle foreground/background
    ^    Reset to foreground
    ~    Cancel following effect

Tilde (`~`) negates following effect; `~S` reset the effect of `S`.
There is a discussion about negation of `D` (Track Wikipedia link in
SEE ALSO), and Apple\_Terminal (v2.10 433) does not reset at least.

Single `E` is an abbreviation for `{EL}` (Erase Line).  This is
different from other attributes, but have an effect of painting the
rest of line by background color.

## 6x6x6 216 COLORS

Combination of 0..5 for 216 RGB values :

    Deep          Light
    <----------------->
    000 111 222 333 444 : Black
    500 511 522 533 544 : Red
    050 151 252 353 454 : Green
    005 115 225 335 445 : Blue
    055 155 255 355 455 : Cyan
    505 515 525 535 545 : Magenta
    550 551 552 553 554 : Yellow
    555 444 333 222 111 : White

## 24 GRAY SCALES + 2

24 gray scales are described by `L01` (dark) to `L24` (bright).
Black and White can be described as `L00` and `L25`, those are
aliases for `000` and `555`.

    L00 : Level  0 (Black)
    L01 : Level  1
     :
    L24 : Level 24
    L25 : Level 25 (White)

## RGB

12bit/24bit RGB :

    (255,255,255)      : 24bit decimal RGB colors
    #000000 .. #FFFFFF : 24bit hex RGB colors
    #000    .. #FFF    : 12bit hex RGB 4096 colors

> Beginning `#` can be omitted in 24bit hex RGB notation.  So 6
> consecutive digits means 24bit color, and 3 digits means 6x6x6 color,
> if they do not begin with `#`.

## COLOR NAMES

Color names enclosed by angle bracket :

    <red> <blue> <green> <cyan> <magenta> <yellow>
    <aliceblue> <honeydew> <hotpink> <moccasin>
    <medium_aqua_marine>

These colors are defined in 24bit RGB.  Names are case insensitive and
underscore (`_`) is ignored, but space and punctuation are not
allowed.  So `<aliceblue>`, `<AliceBlue>`, `<ALICE_BLUE>` are all valid but `<Alice Blue>` is not.  See ["COLOR NAMES"](#color-names)
section for detail.

## CSI SEQUENCES and OTHERS

Native CSI (Control Sequence Introducer) sequences in the form of
`{NAME}`.

    CUU n   Cursor up
    CUD n   Cursor Down
    CUF n   Cursor Forward
    CUB n   Cursor Back
    CNL n   Cursor Next Line
    CPL n   Cursor Previous line
    CHA n   Cursor Horizontal Absolute
    CUP n,m Cursor Position
    ED  n   Erase in Display (0 after, 1 before, 2 entire, 3 w/buffer)
    EL  n   Erase in Line (0 after, 1 before, 2 entire)
    SU  n   Scroll Up
    SD  n   Scroll Down
    HVP n,m Horizontal Vertical Position
    SGR n*  Select Graphic Rendition
    SCP     Save Cursor Position
    RCP     Restore Cursor Position

These names can be followed by optional numerical parameters, using
comma (`,`) or semicolon (`;`) to separate multiple ones, with
optional parentheses.  For example, color spec `DK/544` can be
described as `{SGR1;30;48;5;224}` or more readable
`{SGR(1,30,48,5,224)}`.

Some other escape sequences are supported in the form of `{NAME}`.
These sequences do not start with CSI, and do not take parameters.
VT100 compatible terminal usually support these, and does not support
`SCP` and `RCP` CSI code.

    RIS     Reset to Initial State
    DECSC   DEC Save Cursor
    DECRC   DEC Restore Cursor

## EXAMPLES

    8+8  6x6x6    12bit      24bit            names
    ===  =======  =========  =============    ==================
    B    005      #00F       (0,0,255)        <blue>
     /M     /505      /#F0F     /(255,0,255)  /<magenta>
    K/W  000/555  #000/#FFF  #000000/#FFFFFF  <black>/<white>
    R/G  500/050  #F00/#0F0  #FF0000/#00FF00  <red>/<green>
    W/w  L03/L20  #333/#ccc  #333333/#cccccc  <gray20>/<gray80>

# COLOR NAMES

Color names listed in [Graphics::ColorNames::X](https://metacpan.org/pod/Graphics%3A%3AColorNames%3A%3AX) module can be used.
See [https://en.wikipedia.org/wiki/X11\_color\_names](https://en.wikipedia.org/wiki/X11_color_names).

    aliceblue antiquewhite aqua aquamarine azure beige bisque black
    blanchedalmond blue blueviolet brown burlywood cadetblue
    chartreuse chocolate coral cornflowerblue cornsilk crimson cyan
    darkolivegreen dimgray dimgrey dodgerblue firebrick floralwhite
    forestgreen fuchsia gainsboro ghostwhite gold goldenrod gray green
    greenyellow grey honeydew hotpink indianred indigo ivory khaki
    lavender lavenderblush lawngreen lemonchiffon lightgoldenrodyellow
    lime limegreen linen magenta maroon midnightblue mintcream
    mistyrose moccasin navajowhite navy navyblue oldlace olive
    olivedrab orange orangered orchid papayawhip peachpuff peru pink
    plum powderblue purple rebeccapurple red rosybrown royalblue
    saddlebrown salmon sandybrown seagreen seashell sienna silver
    skyblue slateblue slategray slategrey snow springgreen steelblue
    tan teal thistle tomato turquoise violet violetred webgray
    webgreen webgrey webmaroon webpurple wheat white whitesmoke
    x11gray x11green x11grey x11maroon x11purple yellow yellowgreen

In the above list, next colors have variants with prefix of `dark`,
`light`, `medium`, `pale`, `deep`.

    aquamarine   medium_aquamarine
    blue         dark_blue light_blue medium_blue
    coral        light_coral
    cyan         dark_cyan light_cyan
    goldenrod    dark_goldenrod light_goldenrod pale_goldenrod
    gray         dark_gray light_gray
    green        dark_green light_green pale_green
    grey         dark_grey light_grey
    khaki        dark_khaki
    magenta      dark_magenta
    orange       dark_orange
    orchid       dark_orchid medium_orchid
    pink         deep_pink light_pink
    purple       medium_purple
    red          dark_red
    salmon       dark_salmon light_salmon
    seagreen     dark_seagreen light_seagreen medium_seagreen
    skyblue      deep_skyblue light_skyblue
    slateblue    dark_slateblue light_slateblue medium_slateblue
    slategray    dark_slategray light_slategray
    slategrey    dark_slategrey light_slategrey
    springgreen  medium_springgreen
    steelblue    light_steelblue
    turquoise    dark_turquoise medium_turquoise pale_turquoise
    violet       dark_violet
    violetred    medium_violetred pale_violetred
    yellow       light_yellow

Next colors have four variants.  For example, color `brown` has
`brown1`, `brown2`, `brown3`, `brown4`.

    antiquewhite aquamarine azure bisque blue brown burlywood
    cadetblue chartreuse chocolate coral cornsilk cyan darkgoldenrod
    darkolivegreen darkorange darkorchid darkseagreen darkslategray
    deeppink deepskyblue dodgerblue firebrick gold goldenrod green
    honeydew hotpink indianred ivory khaki lavenderblush lemonchiffon
    lightblue lightcyan lightgoldenrod lightpink lightsalmon
    lightskyblue lightsteelblue lightyellow magenta maroon
    mediumorchid mediumpurple mistyrose navajowhite olivedrab orange
    orangered orchid palegreen paleturquoise palevioletred peachpuff
    pink plum purple red rosybrown royalblue salmon seagreen seashell
    sienna skyblue slateblue slategray snow springgreen steelblue tan
    thistle tomato turquoise violetred wheat yellow

`gray` and `grey` have 100 steps of variants.

    gray gray0 .. gray100
    grey grey0 .. grey100

See [https://en.wikipedia.org/wiki/X11\_color\_names#Color\_variations](https://en.wikipedia.org/wiki/X11_color_names#Color_variations)
for detail.

# FUNCTION SPEC

Color spec can be CODEREF or object.  If it is a CODEREF, that code is
called with text as an argument, and return the result.

If it is an object which has method `call`, it is called with the
variable `$_` set as target text.

# RESET SEQUENCE

This module produces _RESET_ and _Erase Line_ sequence to recover
from colored text.  This is preferable to clear background color set
by scrolling in the middle of colored text at the bottom of the
terminal.

However, on some terminal, including Apple\_Terminal, _Erase Line_
sequence clear the text on the cursor position when it is at the
rightmost column of the screen.  In other words, rightmost character
sometimes mysteriously disappear when it is the last character in the
colored region.  If you do not like this behavior, set module variable
`$NO_RESET_EL` or `ANSICOLOR_NO_RESET_EL` environment.

_Erase Line_ sequence `{EL}` clears the line from cursor position to
the end of the line, which means filling the area by background color.
When _Erase Line_ is explicitly found in the start sequence, it is
copied to just before (not after) ending reset sequence, with
preceding sequence if necessary, to keep the effect of filling line
even if the text is wrapped to multiple lines.

See ["ENVIRONMENT"](#environment) section.

## LESS

Because _Erase Line_ sequence end with `K`, it is a good idea to
tell **less** command so, if you want to see the output using it.

    LESS=-cR
    LESSANSIENDCHARS=mK

# ENVIRONMENT

If the environment variable `NO_COLOR` is set, regardless of its
value, colorization interface in this module never produce color
sequence.  Primitive function such as `ansi_code` is not the case.
See [https://no-color.org/](https://no-color.org/).

Function **ansi\_color** produces 256 or 24bit colors depending on the
value of `$RGB24` module variable.  Also 24bit mode is enabled when
environment `ANSICOLOR_RGB24` is set or `COLORTERM` is `truecolor`.

If the module variable `$NO_RESET_EL` set, or
`ANSICOLOR_NO_RESET_EL` environment, _Erase Line_ sequence is not
produced with RESET code.  See ["RESET SEQUENCE"](#reset-sequence).

# COLOR TABLE

Color table can be shown by other module
[Term::ANSIColor::Concise::Table](https://metacpan.org/pod/Term%3A%3AANSIColor%3A%3AConcise%3A%3ATable).  Next command will show table of
256 colors.

    $ perl -MTerm::ANSIColor::Concise::Table=:all -e colortable

<div>
    <p><img width="750" src="https://raw.githubusercontent.com/tecolicom/Term-ANSIColor-Concise/main/images/colortable-s.png">
</div>

<div>
    <p><img width="750" src="https://raw.githubusercontent.com/tecolicom/Term-ANSIColor-Concise/main/images/colortable-rev-s.png">
</div>

# SEE ALSO

## [Getopt::EX::Colormap](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3AColormap)

This module is originally implemented in [Getopt::EX::Colormap](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3AColormap)
module.  It provides an easy way to maintain labeled and indexed list
for color handling in command line option.

You can take care of user option like this:

    use Getopt::Long;
    my @opt_colormap;
    GetOptions('colormap|cm:s' => @opt_colormap);
    
    require Getopt::EX::Colormap;
    my %label = ( FILE => 'DR', LINE => 'Y', TEXT => '' );
    my @index = qw( /544 /545 /445 /455 /545 /554 );
    my $cm = Getopt::EX::Colormap
        ->new(HASH => \%label, LIST => \@index)
        ->load_params(@opt_colormap);  

And then program can use it in two ways:

    print $cm->color('FILE', $filename);

    print $cm->index_color($index, $pattern);

This interface provides a simple uniform way to handle coloring
options for various tools.

## [App::ansiecho](https://metacpan.org/pod/App%3A%3Aansiecho)

To use this module's function directly from a command line,
[App::ansiecho](https://metacpan.org/pod/App%3A%3Aansiecho) is a good one.  You can apply colors and effects for
echoing argument.

## [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

This code and [Getopt::EX](https://metacpan.org/pod/Getopt%3A%3AEX) was implemented as a part of
[App::Greple](https://metacpan.org/pod/App%3A%3AGreple) command originally.  It is still a intensive user of
this module capability and would be a good use-case.

## OTHERS

[https://en.wikipedia.org/wiki/ANSI\_escape\_code](https://en.wikipedia.org/wiki/ANSI_escape_code)

[Graphics::ColorNames::X](https://metacpan.org/pod/Graphics%3A%3AColorNames%3A%3AX)

[https://en.wikipedia.org/wiki/X11\_color\_names](https://en.wikipedia.org/wiki/X11_color_names)

[https://no-color.org/](https://no-color.org/)

https://www.ecma-international.org/wp-content/uploads/ECMA-48\_5th\_edition\_june\_1991.pdf

# AUTHOR

Kazumasa Utashiro

# COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright 2015-2023 Kazumasa Utashiro

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
