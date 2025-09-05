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

    say ansi_color('<red>+l20-s10', 'Lightened desaturated red');
    say ansi_color('hsl(240,100,50)=y70c', 'Blue set to 70% luminance then complemented');
    say ansi_color('lab(50,20,-30)+h60', 'Lab color with hue shifted 60 degrees');

<div>
    <p><img width="750" src="https://raw.githubusercontent.com/tecolicom/Term-ANSIColor-Concise/main/images/synopsis.png">
</div>

# VERSION

Version 3.01

# DESCRIPTION

This module provides a simple concise format to describe complicated
colors and effects for ANSI terminals.  These notations are supposed to
be used in command line option parameters.

This module used to be a part of [Getopt::EX::Colormap](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3AColormap) module, which
provides an easy handling interface for command line options.

## COLOR SPECIFICATIONS

Colors can be specified using various formats and color spaces:

### RGB Colors

- Hexadecimal format

        FF0000        # Red (6 digits)
        #F00          # Red (3 digits)
        #FF0000       # Red (with # prefix)

- Decimal format  

        rgb(255,0,0)  # Red using RGB values (0-255)
        (255,0,0)     # Red (rgb prefix optional)

### Other Color Spaces

- HSL (Hue, Saturation, Lightness)

        hsl(0,100,50)     # Red: hue=0°, saturation=100%, lightness=50%
        hsl(120,100,50)   # Green: hue=120°, saturation=100%, lightness=50%
        hsl(240,100,50)   # Blue: hue=240°, saturation=100%, lightness=50%

- LCH (Lightness, Chroma, Hue) - CIE LCHab

        lch(50,130,0)     # Red: lightness=50, chroma=130, hue=0°
        lch(87,119,136)   # Green: lightness=87, chroma=119, hue=136°
        lch(32,133,306)   # Blue: lightness=32, chroma=133, hue=306°

- Lab (Lightness, a\*, b\*) - CIE Lab

        lab(50,68,48)     # Red: L*=50, a*=68, b*=48
        lab(87,-79,80)    # Green: L*=87, a*=-79, b*=80  
        lab(32,79,-108)   # Blue: L*=32, a*=79, b*=-108

### Named Colors

    <red>             # Named color (see COLOR NAMES section)
    <lightblue>       # Color name with modifier
    <gray50>          # Grayscale levels

## 256 or 24bit COLORS

By default, this library produces ANSI 256 color sequence.  That is
eight standard colors, eight high intensity colors, 6x6x6 216 colors,
and gray scales in 24 steps.

Colors described by 12bit/24bit RGB values are converted to 6x6x6 216
colors, or 24 gray scales if all RGB values are the same.

For a terminal which can display 24bit colors, full-color sequence can
be produced.  See ["ENVIRONMENT"](#environment) section.

# FUNCTION

- **ansi\_color**(_spec_, _text_, ...)

    Returns the colorized version of the given text.  Produces 256 or 24bit colors
    depending on the setting.

    In the result, the given _text_ is enclosed by appropriate open/close
    sequences.  The close sequence can vary according to the open sequence.
    See ["RESET SEQUENCE"](#reset-sequence) section.

    If _text_ already contains colored areas, the color specifications
    are applied accumulatively. For example, if an underline instruction
    is given for a string of red text, both specifications will be in
    effect.

    The _spec_ and _text_ pairs can be repeated any number of times. In
    scalar context, the results from each pair are returned as a
    concatenated string. When used in array context, results are
    returned as a list.

- **ansi\_color**(\[ _spec1_, _spec2_, ... \], _text_)

    If the _spec_ parameter is an ARRAYREF, multiple _spec_s can be specified
    at once.  This is not useful for text color specs because they can be
    simply joined, but may be useful when mixed with ["FUNCTION SPEC"](#function-spec).

- **ansi\_color\_24**(_spec_, _text_)
- **ansi\_color\_24**(\[ _spec1_, _spec2_, ... \], _text_)

    Function **ansi\_color\_24** always produces 24bit color sequences for
    12bit/24bit color specs.

- **cached\_ansi\_color**(_cache_, _spec_, _text_)

    Backend interface for **ansi\_color**.  The first parameter is a hash object
    used to cache data.  If you are concerned about cache mismatch situations,
    use this interface with an original cache.

- **ansi\_pair**(_color\_spec_)

    Produces introducer and recovery sequences for the given spec.

    An additional third value indicates if the introducer includes an Erase Line
    sequence.  This gives a hint that the sequence is necessary for empty strings.
    See ["RESET SEQUENCE"](#reset-sequence).

- **ansi\_code**(_color\_spec_)

    Produces introducer sequence for the given spec.  Reset code can be obtained
    by **ansi\_code("Z")**.

- **csi\_code**(_name_, _params_)

    Produce CSI (Control Sequence Introducer) sequence by name with
    numeric parameters.  Parameter _name_ is one of standard (ICH, CUU,
    CUD, CUF, CUB, CNL, CPL, CHA, CUP, ED, EL, IL, DL, DCH, SU, SD, ECH,
    VPA, VPR, HVP, SGR, DSR, SCP, RCP) or non-standard (CPR, STBM, CSI,
    OSC, RIS, DECSC, DECRC, DECEC, DECDC).

- **csi\_report**(_name_, _n_, _string_)

    Extracts parameters from the response string returned from the
    terminal.  _n_ specifies the number of parameters included in the
    response.

    Currently, only `CPR` (Cursor Position Report) is effective as
    _name_.  The current cursor position can be obtained from the
    response string resulting from the `DSR` (Device Status Report)
    sequence as follows.

        my($line, $column) = csi_report('CPR', 2, $answer);

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

    ICH n   Insert Character
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
    IL  n   Insert Line
    DL  n   Delete Line
    DCH n   Delete Character (scroll rest to left)
    SU  n   Scroll Up
    SD  n   Scroll Down
    ECH n   Erase Character
    VPA n   Vertical Position Absolute
    VPR n   Vertical Position Relative
    HVP n,m Horizontal Vertical Position
    SGR n*  Select Graphic Rendition
    DSR n   Device Status Report (6 cursor position)
    SCP     Save Cursor Position
    RCP     Restore Cursor Position

And there are some non-standard CSI sequences.

    CPR  n,m Cursor Position Report – VT100 to Host
    STBM n,m Set Top and Bottom Margins
    SLRM n,m Set Left Right Margins

These names can be followed by optional numerical parameters, using
comma (`,`) or semicolon (`;`) to separate multiple ones, with
optional parentheses.  For example, color spec `DK/544` can be
described as `{SGR1;30;48;5;224}` or more readable
`{SGR(1,30,48,5,224)}`.

Some other escape sequences are supported in the form of `{NAME}`.
These sequences do not start with CSI, and do not take parameters.
VT100 compatible terminals usually support these, and do not support
`SCP` and `RCP` CSI codes.

    CSI      Control Sequence Introducer
    OSC      Operating System Command
    RIS      Reset to Initial State
    DECSC    DEC Save Cursor
    DECRC    DEC Restore Cursor
    DECEC    DEC Enable Cursor
    DECDC    DEC Disable Cursor
    DECELRM  DEC Enable Left Right Margin Mode
    DECDLRM  DEC Disable Left Right Margin Mode

## EXAMPLES

    8+8  6x6x6    12bit      24bit            names
    ===  =======  =========  =============    ==================
    B    005      #00F       (0,0,255)        <blue>
     /M     /505      /#F0F     /(255,0,255)  /<magenta>
    K/W  000/555  #000/#FFF  #000000/#FFFFFF  <black>/<white>
    R/G  500/050  #F00/#0F0  #FF0000/#00FF00  <red>/<green>
    W/w  L03/L20  #333/#ccc  #333333/#cccccc  <gray20>/<gray80>

# COLOR ADJUSTMENT

Colors can be dynamically adjusted using modifier characters appended after 
color specifications. These modifiers allow you to adjust various color 
properties such as luminance, lightness, saturation, and hue.

## MODIFIER SYNTAX

Color modifiers use the format: `[OPERATION][PARAMETER][VALUE]`

- **Operations**
    - `+` - Add value (relative adjustment)
    - `-` - Subtract value (relative adjustment)  
    - `=` - Set absolute value
    - `*` - Multiply by percentage (value/100)
    - `%` - Modulo operation

## ADJUSTABLE PARAMETERS

- **l** - Lightness (HSL lightness: 0-100)

        <red>+l10     # Increase red lightness by 10
        <green>-l15   # Decrease green lightness by 15
        <blue>=l75    # Set blue lightness to 75
        <orange>*l120 # Multiply orange lightness by 1.2

- **y** - Luminance (brightness perception: 0-100)

        <red>+y10     # Increase red luminance by 10
        <blue>-y20    # Decrease blue luminance by 20
        <green>=y50   # Set green luminance to 50

- **s** - Saturation (HSL saturation: 0-100)

        <red>+s20     # Increase red saturation by 20
        <yellow>-s30  # Decrease yellow saturation by 30
        <magenta>=s0  # Set magenta saturation to 0 (grayscale)

- **h** - Hue (HSL hue shift in degrees: 0-360)

        <red>+h60     # Shift red hue by 60 degrees
        <cyan>-h120   # Shift cyan hue by -120 degrees
        <purple>=h180 # Set purple hue to 180 degrees

- **c** - Complement (180 degree hue shift)

        <red>c        # Get complement of red (cyan)

- **r** - Rotate Hue (LCH hue rotation, preserving luminance)

        <red>+r60     # Rotate red hue by 60 degrees in LCH space
        <blue>=r180   # Rotate to 180 degrees (complement with luminance preserved)

- **i** - Inverse (RGB inversion)

        <red>i        # Invert red to cyan
        <blue>i       # Invert blue to yellow

- **g** - Luminance Grayscale (convert to grayscale using luminance)

        <red>g        # Convert red to luminance-based grayscale

- **G** - Lightness Grayscale (convert to grayscale using lightness)

        <red>G        # Convert red to lightness-based grayscale

The color adjustment functionality is implemented through the 
[Term::ANSIColor::Concise::Transform](https://metacpan.org/pod/Term%3A%3AANSIColor%3A%3AConcise%3A%3ATransform) module and uses 
[Term::ANSIColor::Concise::ColorObject](https://metacpan.org/pod/Term%3A%3AANSIColor%3A%3AConcise%3A%3AColorObject) for color space conversions.

# COLOR NAMES

Color names listed in [Graphics::ColorNames::X](https://metacpan.org/pod/Graphics%3A%3AColorNames%3A%3AX) module can be used in
the form of `<NAME>`.

    aliceblue      antiquewhite   aqua         aquamarine
    azure          beige          bisque       black
    blanchedalmond blue           blueviolet   brown
    burlywood      cadetblue      chartreuse   chocolate
    coral          cornflowerblue cornsilk     crimson
    cyan           darkolivegreen dimgray      dimgrey
    dodgerblue     firebrick      floralwhite  forestgreen
    fuchsia        gainsboro      ghostwhite   gold
    goldenrod      gray           green        greenyellow
    grey           honeydew       hotpink      indianred
    indigo         ivory          khaki        lavender
    lavenderblush  lawngreen      lemonchiffon lightgoldenrodyellow
    lime           limegreen      linen        magenta
    maroon         midnightblue   mintcream    mistyrose
    moccasin       navajowhite    navy         navyblue
    oldlace        olive          olivedrab    orange
    orangered      orchid         papayawhip   peachpuff
    peru           pink           plum         powderblue
    purple         rebeccapurple  red          rosybrown
    royalblue      saddlebrown    salmon       sandybrown
    seagreen       seashell       sienna       silver
    skyblue        slateblue      slategray    slategrey
    snow           springgreen    steelblue    tan
    teal           thistle        tomato       turquoise
    violet         violetred      webgray      webgreen
    webgrey        webmaroon      webpurple    wheat
    white          whitesmoke     x11gray      x11green
    x11grey        x11maroon      x11purple    yellow
    yellowgreen

In the above list, next colors have variants with prefix of `dark`,
`light`, `medium`, `pale`, `deep`.

    aquamarine   medium_aquamarine
    blue         dark_blue      light_blue       medium_blue
    coral                       light_coral
    cyan         dark_cyan      light_cyan
    goldenrod    dark_goldenrod light_goldenrod  pale_goldenrod
    gray         dark_gray      light_gray
    green        dark_green     light_green      pale_green
    grey         dark_grey      light_grey
    khaki        dark_khaki
    magenta      dark_magenta
    orange       dark_orange
    orchid       dark_orchid                     medium_orchid
    pink         deep_pink      light_pink
    purple                                       medium_purple
    red          dark_red
    salmon       dark_salmon    light_salmon
    seagreen     dark_seagreen  light_seagreen   medium_seagreen
    skyblue      deep_skyblue   light_skyblue
    slateblue    dark_slateblue light_slateblue  medium_slateblue
    slategray    dark_slategray light_slategray
    slategrey    dark_slategrey light_slategrey
    springgreen                                  medium_springgreen
    steelblue                   light_steelblue
    turquoise    dark_turquoise medium_turquoise pale_turquoise
    violet       dark_violet
    violetred                   medium_violetred pale_violetred
    yellow                      light_yellow

The following colors have four variants.  For example, color `brown` has
`brown1`, `brown2`, `brown3`, `brown4`.

    antiquewhite   aquamarine     azure          bisque
    blue           brown          burlywood      cadetblue
    chartreuse     chocolate      coral          cornsilk
    cyan           darkgoldenrod  darkolivegreen darkorange
    darkorchid     darkseagreen   darkslategray  deeppink
    deepskyblue    dodgerblue     firebrick      gold
    goldenrod      green          honeydew       hotpink
    indianred      ivory          khaki          lavenderblush
    lemonchiffon   lightblue      lightcyan      lightgoldenrod
    lightpink      lightsalmon    lightskyblue   lightsteelblue
    lightyellow    magenta        maroon         mediumorchid
    mediumpurple   mistyrose      navajowhite    olivedrab
    orange         orangered      orchid         palegreen
    paleturquoise  palevioletred  peachpuff      pink
    plum           purple         red            rosybrown
    royalblue      salmon         seagreen       seashell
    sienna         skyblue        slateblue      slategray
    snow           springgreen    steelblue      tan
    thistle        tomato         turquoise      violetred
    wheat          yellow

`gray` and `grey` have 100 steps of variants.

    gray gray0 .. gray100
    grey grey0 .. grey100

See [https://en.wikipedia.org/wiki/X11\_color\_names#Color\_variations](https://en.wikipedia.org/wiki/X11_color_names#Color_variations)
for detail.

# FUNCTION SPEC

Color spec can be a CODEREF or object.  If it is a CODEREF, that code is
called with text as an argument, and returns the result.

If it is an object which has a method `call`, it is called with the
variable `$_` set as the target text.

# RESET SEQUENCE

This module produces _RESET_ and _Erase Line_ sequence to recover
from colored text.  This is preferable to clear background color set
by scrolling in the middle of colored text at the bottom of the
terminal.

However, on some terminals, including Apple\_Terminal, the _Erase Line_
sequence clears the text at the cursor position when it is at the
rightmost column of the screen.  In other words, the rightmost character
sometimes mysteriously disappears when it is the last character in the
colored region.  If you do not like this behavior, set the module variable
`$NO_RESET_EL` or the `ANSICOLOR_NO_RESET_EL` environment variable.

The _Erase Line_ sequence `{EL}` clears the line from the cursor position to
the end of the line, which means filling the area with the background color.
When _Erase Line_ is explicitly found in the start sequence, it is
copied to just before (not after) the ending reset sequence, with the
preceding sequence if necessary, to keep the effect of filling the line
even if the text is wrapped to multiple lines.

See ["ENVIRONMENT"](#environment) section.

## LESS

Because the _Erase Line_ sequence ends with `K`, it is a good idea to
tell the **less** command so, if you want to see the output using it.

    LESS=-cR
    LESSANSIENDCHARS=mK

# ENVIRONMENT

If the environment variable `NO_COLOR` is set, regardless of its
value, the colorization interface in this module will never produce color
sequences.  Primitive functions such as `ansi_code` are not affected.
See [https://no-color.org/](https://no-color.org/).

Function **ansi\_color** produces 256 or 24bit colors depending on the
value of the `$RGB24` module variable.  24bit mode is also enabled when
the environment variable `ANSICOLOR_RGB24` is set or `COLORTERM` is `truecolor`.

If the module variable `$NO_RESET_EL` is set, or the
`ANSICOLOR_NO_RESET_EL` environment variable is set, the _Erase Line_ sequence is not
produced with the RESET code.  See ["RESET SEQUENCE"](#reset-sequence).

# COLOR TABLE

The color table can be shown by the [Term::ANSIColor::Concise::Table](https://metacpan.org/pod/Term%3A%3AANSIColor%3A%3AConcise%3A%3ATable) module.  
The following command will show the table of 256 colors.

    $ perl -MTerm::ANSIColor::Concise::Table=:all -e colortable

<div>
    <p><img width="750" src="https://raw.githubusercontent.com/tecolicom/Term-ANSIColor-Concise/main/images/colortable-s.png">
</div>

<div>
    <p><img width="750" src="https://raw.githubusercontent.com/tecolicom/Term-ANSIColor-Concise/main/images/colortable-rev-s.png">
</div>

# SEE ALSO

## [Getopt::EX::Colormap](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3AColormap)

This module was originally implemented in the [Getopt::EX::Colormap](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3AColormap)
module.  It provides an easy way to maintain labeled and indexed lists
for color handling in command line options.

You can handle user options like this:

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

To use this module's functions directly from the command line,
[App::ansiecho](https://metacpan.org/pod/App%3A%3Aansiecho) is a good choice.  You can apply colors and effects to
echoed arguments.

## [App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

This code and [Getopt::EX](https://metacpan.org/pod/Getopt%3A%3AEX) were originally implemented as part of
the [App::Greple](https://metacpan.org/pod/App%3A%3AGreple) command.  It is still an intensive user of
this module's capabilities and would be a good use case.

## [Graphics::ColorObject](https://metacpan.org/pod/Graphics%3A%3AColorObject)

For detailed information about color spaces other than RGB (such as HSL, 
LCH, Lab, YIQ, etc.), refer to [Graphics::ColorObject](https://metacpan.org/pod/Graphics%3A%3AColorObject) which provides 
comprehensive color space conversion capabilities used by this module.

## OTHERS

[https://en.wikipedia.org/wiki/ANSI\_escape\_code](https://en.wikipedia.org/wiki/ANSI_escape_code)

[Graphics::ColorNames::X](https://metacpan.org/pod/Graphics%3A%3AColorNames%3A%3AX)

[https://en.wikipedia.org/wiki/X11\_color\_names](https://en.wikipedia.org/wiki/X11_color_names)

[https://no-color.org/](https://no-color.org/)

[https://www.ecma-international.org/wp-content/uploads/ECMA-48\_5th\_edition\_june\_1991.pdf](https://www.ecma-international.org/wp-content/uploads/ECMA-48_5th_edition_june_1991.pdf)

[https://vt100.net/docs/vt100-ug/](https://vt100.net/docs/vt100-ug/)

# AUTHOR

Kazumasa Utashiro

# COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright ©︎ 2015-2025 Kazumasa Utashiro

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
