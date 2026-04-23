package PGPLOTx::Constants;

# ABSTRACT: Constants for use with PGPLOT

use strict;
use warnings;

use CXC::Exporter::Util ':all';
use parent 'Exporter::Tiny';

#<<<
our $VERSION = '0.03';
#>>>

my %Constants = (
    ARROWHEAD_FILL_STYLES => {
        SOLID   => 1,
        FILLED  => 1,
        OUTLINE => 2,
    },

    COLORS => {
        BACKGROUND   => 0,
        BLACK        => 0,
        FOREGROUND   => 1,
        WHITE        => 1,
        RED          => 2,
        GREEN        => 3,
        BLUE         => 4,
        CYAN         => 5,
        MAGENTA      => 6,
        YELLOW       => 7,
        ORANGE       => 8,
        GREEN_YELLOW => 9,
        GREEN_CYAN   => 10,
        BLUE_CYAN    => 11,
        BLUE_MAGENTA => 12,
        RED_MAGENTA  => 13,
        DARK_GRAY    => 14,
        LIGHT_GRAY   => 15,
        DARKGRAY     => 14,
        LIGHTGRAY    => 15,
    },

    AREA_FILL_STYLES => {
        SOLID         => 1,
        FILLED        => 1,
        OUTLINE       => 2,
        HATCHED       => 3,
        CROSS_HATCHED => 4,
    },

    FONTS => {
        NORMAL => 1,
        ROMAN  => 2,
        ITALIC => 3,
        SCRIPT => 4,
    },

    LINE_STYLES => {
        FULL              => 1,
        DASHED            => 2,
        DOT_DASH_DOT_DASH => 3,
        DOTTED            => 4,
        DASH_DOT_DOT_DOT  => 5,
    },

    PLOT_UNITS => {
        NORMALIZED_DEVICE_COORDINATES => 0,
        NDC                           => 0,
        INCHES                        => 1,
        IN                            => 1,
        MILLIMETERS                   => 2,
        MM                            => 2,
        PIXELS                        => 3,
        WORLD_COORDINATES             => 4,
        WC                            => 4,
    },

    SYMBOLS => {
        DOICOSAGON   => -22,
        HENICOSAGON  => -21,
        ICOSAGON     => -20,
        ENNEADECAGON => -19,
        OCTADECAGON  => -18,
        HEPTADECAGON => -17,
        HEXADECAGON  => -16,
        PENTADECAGON => -15,
        TETRADECAGON => -14,
        TRIDECAGON   => -13,
        DODECAGON    => -12,
        HENDECAGON   => -11,
        DECAGON      => -10,
        NONAGON      => -9,
        ENNEAGON     => -9,
        OCTAGON      => -8,
        HEPTAGON     => -7,
        HEXAGON      => -6,
        PENTAGON     => -5,
        DIAMOND      => -4,
        TRIANGLE     => -3,
        DOT0         => -2,
        DOT1         => -1,
        OPENSQUARE   => 0,
        DOT          => 1,
        PLUS         => 2,
        ASTERISK     => 3,
        OPENCIRCLE   => 4,
        CROSS        => 5,
        OPENSQUARE1  => 6,
        OPENTRIANGLE => 7,
        EARTH        => 8,
        SUN          => 9,
        CURVESQUARE  => 10,
        OPENDIAMOND  => 11,
        OPENSTAR     => 12,
        TRIANGLE1    => 13,
        OPENPLUS     => 14,
        STARDAVID    => 15,
        SQUARE       => 16,
        CIRCLE       => 17,
        STAR         => 18,
        BIGOSQUARE   => 19,
        OPENCIRC0    => 20,
        OPENCIRC1    => 21,
        OPENCIRC2    => 22,
        OPENCIRC3    => 23,
        OPENCIRC4    => 24,
        OPENCIRC5    => 25,
        OPENCIRC6    => 26,
        OPENCIRC7    => 27,
        BACKARROW    => 28,
        FWDARROW     => 29,
        UPARROW      => 30,
        DOWNARROW    => 31
    },

    XAXIS_OPTIONS => { map { ( "XAXIS_OPT_$_" => $_ ) } qw( A B C G I L N P M T S ) },

    YAXIS_OPTIONS => { map { ( "YAXIS_OPT_$_" => $_ ) } qw( A B C G I L N P M T S V ) },
);

install_CONSTANTS( \%Constants );
install_EXPORTS( { subs => [qw(coerce_constant list_constants)] } );

sub _croak {
    require Carp;
    goto \&Carp::croak;
}

my %Coerce;

for my $tag ( keys %Constants ) {

    my $coerce = $Coerce{ lc $tag } = {};
    for my $const ( keys %{ $Constants{$tag} } ) {
        my $ref = \$Constants{$tag}{$const};
        $coerce->{$const} = $coerce->{ lc $const } = $ref;
        $const =~ s/_/-/g;
        $coerce->{$const} = $coerce->{ lc $const } = $ref;
    }

}

sub _exporter_validate_opts {
    my ( $class, $globals ) = @_;

    if ( exists $globals->{as} && !ref $globals->{as} && $globals->{as} eq 'lc' ) {
        $globals->{as} = sub { lc $_[0] }
    }
}

sub _exporter_merge_opts {
    my $class    = shift;
    my $tag_opts = shift;

    $tag_opts = {} unless ref( $tag_opts ) eq q(HASH);
    if ( exists $tag_opts->{-as} && !ref $tag_opts->{-as} && $tag_opts->{-as} eq 'lc' ) {
        $tag_opts = { %{$tag_opts}, -as => sub { lc $_[0] } };
    }

    return $class->SUPER::_exporter_merge_opts( $tag_opts, @_ );
}


















sub coerce_constant {
    my ( $tag, $label ) = @_;

    _croak( "unknown constant '$tag:$label'" )
      unless exists $Coerce{$tag}
      && exists $Coerce{$tag}{$label};

    return ${ $Coerce{$tag}{$label} };
}










sub list_constants {
    my ( $tag ) = @_;

    _croak( "unknown constant tag '$tag'" )
      unless exists $Coerce{$tag};

    return ( sort keys %{ $Coerce{$tag} } );
}

1;

#
# This file is part of PGPLOTx-Constants
#
# This software is Copyright (c) 2026 by Smithsonian Astrophysical Observatory.
#
# This is free software, licensed under:
#
#   The GNU General Public License, Version 3, June 2007
#

__END__

=pod

=for :stopwords Diab Jerius Smithsonian Astrophysical Observatory PGPLOT XAxis YAxis

=head1 NAME

PGPLOTx::Constants - Constants for use with PGPLOT

=head1 VERSION

version 0.03

=head1 SYNOPSIS

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

=head1 DESCRIPTION

This module provides constants for use with the L<PGPLOT> plotting
package, as well as utilities to simplify interfacing with users
(rather than code).

L<Exporter::Tiny> is used to provide the exported
symbols, so its facilities can be used to customize the import
experience.

=head1 SUBROUTINES

=head2 coerce_constant

     $value = coerce_constant( $tag, $name );

If C<$name> is a recognized name or alias for constants associated
with the tag C<$tag>, return the constant's value, otherwise throw an
exception.

Aliases include the lower-cased name, and names with underscores
replaced with hyphens.  For example,  the following names are accepted
for the C<color> constant C<GREEN_YELLOW>:

  GREEN_YELLOW  GREEN-YELLOW
  green_yellow  green-yellow

=head2 list_constants

  @names = list_constants( $tag )

Return all names accepted by L</coerce_constant> for the specified
tag.  Throws if C<$tag> is not recognized.

=head1 CONSTANTS

The constants can be imported individually, or as sets via associated
tags.

The following sets of constants are available:

=over

=item Colors

The C<colors> tag imports all of the following constants:

  BACKGROUND  CYAN          BLUE_MAGENTA
  BLACK       MAGENTA       RED_MAGENTA
  FOREGROUND  YELLOW        DARK_GRAY
  WHITE       ORANGE        LIGHT_GRAY
  RED         GREEN_YELLOW  DARKGRAY
  GREEN       GREEN_CYAN    LIGHTGRAY
  BLUE        BLUE_CYAN

=over

=item *

The C<COLORS> subroutine returns a list of the constants' values.

=item *

The C<COLORS_NAMES> subroutine returns a list of the constants' names.

=back

=item Area Fill Styles

The C<area_fill_styles> tag imports all of the following constants:

  SOLID  FILLED  OUTLINE  HATCHED   CROSS_HATCHED

=over

=item *

The C<AREA_FILL_STYLES> subroutine returns a list of the constants' values.

=item *

The C<AREA_FILL_STYLES_NAMES> subroutine returns a list of the constants' names.

=back

=item Arrowhead Fill Styles

The C<arrowhead_fill_styles> tag imports all of the following constants:

  SOLID  FILLED  OUTLINE

=over

=item *

The C<ARROWHEAD_FILL_STYLES> subroutine returns a list of the constants' values.

=item *

The C<ARROWHEAD_FILL_STYLES_NAMES> subroutine returns a list of the constants' names.

=back

=item Fonts

The C<fonts> tag imports all of the following constants;

  NORMAL  ROMAN  ITALIC  SCRIPT

=over

=item *

The C<FONTS> subroutine returns a list of the constants' values.

=item *

The C<FONTS_NAMES> subroutine returns a list of the constants' names.

=back

=item Line Styles

The C<line_styles> tag imports all of the following constants:

  FULL  DASHED  DOT_DASH_DOT_DASH  DOTTED  DASH_DOT_DOT_DOT

=over

=item *

The C<LINE_STYLES> subroutine returns a list of the constants' values.

=item *

The C<LINE_STYLES_NAMES> subroutine returns a list of the constants' names.

=back

=item Plot Units

The C<plot_units> tag imports all of the following constants:

  NDC NORMALIZED_DEVICE_COORDINATES
  IN  INCHES
  MM  MILLIMETERS
  PIXELS
  WC  WORLD_COORDINATES

=over

=item *

The C<PLOT_UNITS> subroutine returns a list of the constants' values.

=item *

The C<PLOT_UNITS_NAMES> subroutine returns a list of the constants' names.

=back

=item Symbols

The C<symbols> tag imports all of the following constants:

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

=over

=item *

The C<SYMBOLS> subroutine returns a list of the constants' values.

=item *

The C<SYMBOLS_NAMES> subroutine returns a list of the constants' names.

=back

=item XAxis Options

The C<xaxis_options> tag imports all of the following constants:

  XAXIS_OPT_A  XAXIS_OPT_G  XAXIS_OPT_N  XAXIS_OPT_S
  XAXIS_OPT_B  XAXIS_OPT_I  XAXIS_OPT_P  XAXIS_OPT_T
  XAXIS_OPT_C  XAXIS_OPT_L  XAXIS_OPT_M

=over

=item *

The C<XAXIS_OPTIONS> subroutine returns a list of the constants' values.

=item *

The C<XAXIS_OPTIONS_NAMES> subroutine returns a list of the constants' names.

=back

=item YAxis Options

The C<yaxis_options> tag imports all of the following constants:

  YAXIS_OPT_A  YAXIS_OPT_G  YAXIS_OPT_N  YAXIS_OPT_S
  YAXIS_OPT_B  YAXIS_OPT_I  YAXIS_OPT_P  YAXIS_OPT_T
  YAXIS_OPT_C  YAXIS_OPT_L  YAXIS_OPT_M  YAXIS_OPT_V

=over

=item *

The C<YAXIS_OPTIONS> subroutine returns a list of the constants' values.

=item *

The C<YAXIS_OPTIONS_NAMES> subroutine returns a list of the constants' names.

=back

=back

=head1 SUPPORT

=head2 Bugs

Please report any bugs or feature requests to bug-pgplotx-constants@rt.cpan.org  or through the web interface at: L<https://rt.cpan.org/Public/Dist/Display.html?Name=PGPLOTx-Constants>

=head2 Source

Source is available at

  https://codeberg.org/djerius/p5-PGPLOTx-Constants

and may be cloned from

  https://codeberg.org/djerius/p5-PGPLOTx-Constants.git

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<PGPLOT|PGPLOT>

=item *

L<Types::PGPLOT|Types::PGPLOT>

=back

=head1 AUTHOR

Diab Jerius <djerius@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Smithsonian Astrophysical Observatory.

This is free software, licensed under:

  The GNU General Public License, Version 3, June 2007

=cut
