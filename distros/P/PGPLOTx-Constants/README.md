# NAME

PGPLOTx::Constants - Constants for use with PGPLOT

# VERSION

version 0.03

# SYNOPSIS

    # import GREEN
    use PGPLOTx::Constants 'GREEN';

    # import GREEN as green, so your code doesn't shout.
    use PGPLOTx::Constants 'GREEN' => { -as => 'green' } ;

    # import all of the colors
    use PGPLOTx::Constants -colors;

    # import all of the colors, lower case theem so your code doesn't
    # shout, and import the fonts but don't lower case them
    use PGPLOTx::Constants -colors, { -as => 'lc' }, -fonts ;

    # lower case everything that is imported
    use PGPLOTx::Constants { as => 'lc' }, -colors, -fonts ;

    # support for user interfaces
    use PGPLOTx::Constants qw( list_constants coerce_constant )

    if ( $color eq '-list' ) {
      say join "\n", list_constants( 'colors' );
      exit 0;
    }

    $color = coerce_constant( colors => $color );

# DESCRIPTION

This module provides constants for use with the [PGPLOT](https://metacpan.org/pod/PGPLOT) plotting
package, as well as utilities to simplify interfacing with users
(rather than code).

[Exporter::Tiny](https://metacpan.org/pod/Exporter%3A%3ATiny) is used to provide the exported
symbols, so its facilities can be used to customize the import
experience.

# SUBROUTINES

## coerce\_constant

     $value = coerce_constant( $tag, $name );

If `$name` is a recognized name or alias for constants associated
with the tag `$tag`, return the constant's value, otherwise throw an
exception.

Aliases include the lower-cased name, and names with underscores
replaced with hyphens.  For example,  the following names are accepted
for the `color` constant `GREEN_YELLOW`:

    GREEN_YELLOW  GREEN-YELLOW
    green_yellow  green-yellow

## list\_constants

    @names = list_constants( $tag )

Return all names accepted by ["coerce\_constant"](#coerce_constant) for the specified
tag.  Throws if `$tag` is not recognized.

# CONSTANTS

The constants can be imported individually, or as sets via associated
tags.

The following sets of constants are available:

- Colors

    The `colors` tag imports all of the following constants:

        BACKGROUND  CYAN          BLUE_MAGENTA
        BLACK       MAGENTA       RED_MAGENTA
        FOREGROUND  YELLOW        DARK_GRAY
        WHITE       ORANGE        LIGHT_GRAY
        RED         GREEN_YELLOW  DARKGRAY
        GREEN       GREEN_CYAN    LIGHTGRAY
        BLUE        BLUE_CYAN

    - The `COLORS` subroutine returns a list of the constants' values.
    - The `COLORS_NAMES` subroutine returns a list of the constants' names.

- Area Fill Styles

    The `area_fill_styles` tag imports all of the following constants:

        SOLID  FILLED  OUTLINE  HATCHED   CROSS_HATCHED

    - The `AREA_FILL_STYLES` subroutine returns a list of the constants' values.
    - The `AREA_FILL_STYLES_NAMES` subroutine returns a list of the constants' names.

- Arrowhead Fill Styles

    The `arrowhead_fill_styles` tag imports all of the following constants:

        SOLID  FILLED  OUTLINE

    - The `ARROWHEAD_FILL_STYLES` subroutine returns a list of the constants' values.
    - The `ARROWHEAD_FILL_STYLES_NAMES` subroutine returns a list of the constants' names.

- Fonts

    The `fonts` tag imports all of the following constants;

        NORMAL  ROMAN  ITALIC  SCRIPT

    - The `FONTS` subroutine returns a list of the constants' values.
    - The `FONTS_NAMES` subroutine returns a list of the constants' names.

- Line Styles

    The `line_styles` tag imports all of the following constants:

        FULL  DASHED  DOT_DASH_DOT_DASH  DOTTED  DASH_DOT_DOT_DOT

    - The `LINE_STYLES` subroutine returns a list of the constants' values.
    - The `LINE_STYLES_NAMES` subroutine returns a list of the constants' names.

- Plot Units

    The `plot_units` tag imports all of the following constants:

        NDC NORMALIZED_DEVICE_COORDINATES
        IN  INCHES
        MM  MILLIMETERS
        PIXELS
        WC  WORLD_COORDINATES

    - The `PLOT_UNITS` subroutine returns a list of the constants' values.
    - The `PLOT_UNITS_NAMES` subroutine returns a list of the constants' names.

- Symbols

    The `symbols` tag imports all of the following constants:

        DOICOSAGON     HENDECAGON  DOT1          CURVESQUARE  OPENCIRC1
        HENICOSAGON    DECAGON     OPENSQUARE    OPENDIAMOND  OPENCIRC2
        ICOSAGON       NONAGON     DOT           OPENSTAR     OPENCIRC3
        ENNEADECAGON   ENNEAGON    PLUS          TRIANGLE1    OPENCIRC4
        OCTADECAGON    OCTAGON     ASTERISK      OPENPLUS     OPENCIRC5
        HEPTADECAGON   HEPTAGON    OPENCIRCLE    STARDAVID    OPENCIRC6
        HEXADECAGON    HEXAGON     CROSS         SQUARE       OPENCIRC7
        PENTADECAGON   PENTAGON    OPENSQUARE1   CIRCLE       BACKARROW
        TETRADECAGON   DIAMOND     OPENTRIANGLE  STAR         FWDARROW
        TRIDECAGON     TRIANGLE    EARTH         BIGOSQUARE   UPARROW
        DODECAGON      DOT0        SUN           OPENCIRC0    DOWNARROW

    - The `SYMBOLS` subroutine returns a list of the constants' values.
    - The `SYMBOLS_NAMES` subroutine returns a list of the constants' names.

- XAxis Options

    The `xaxis_options` tag imports all of the following constants:

        XAXIS_OPT_A  XAXIS_OPT_G  XAXIS_OPT_N  XAXIS_OPT_S
        XAXIS_OPT_B  XAXIS_OPT_I  XAXIS_OPT_P  XAXIS_OPT_T
        XAXIS_OPT_C  XAXIS_OPT_L  XAXIS_OPT_M

    - The `XAXIS_OPTIONS` subroutine returns a list of the constants' values.
    - The `XAXIS_OPTIONS_NAMES` subroutine returns a list of the constants' names.

- YAxis Options

    The `yaxis_options` tag imports all of the following constants:

        YAXIS_OPT_A  YAXIS_OPT_G  YAXIS_OPT_N  YAXIS_OPT_S
        YAXIS_OPT_B  YAXIS_OPT_I  YAXIS_OPT_P  YAXIS_OPT_T
        YAXIS_OPT_C  YAXIS_OPT_L  YAXIS_OPT_M  YAXIS_OPT_V

    - The `YAXIS_OPTIONS` subroutine returns a list of the constants' values.
    - The `YAXIS_OPTIONS_NAMES` subroutine returns a list of the constants' names.

# SUPPORT

## Bugs

Please report any bugs or feature requests to bug-pgplotx-constants@rt.cpan.org  or through the web interface at: [https://rt.cpan.org/Public/Dist/Display.html?Name=PGPLOTx-Constants](https://rt.cpan.org/Public/Dist/Display.html?Name=PGPLOTx-Constants)

## Source

Source is available at

    https://codeberg.org/djerius/p5-PGPLOTx-Constants

and may be cloned from

    https://codeberg.org/djerius/p5-PGPLOTx-Constants.git

# SEE ALSO

Please see those modules/websites for more information related to this module.

- [PGPLOT](https://metacpan.org/pod/PGPLOT)
- [Types::PGPLOT](https://metacpan.org/pod/Types%3A%3APGPLOT)

# AUTHOR

Diab Jerius <djerius@cpan.org>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

    The GNU General Public License, Version 3, June 2007
