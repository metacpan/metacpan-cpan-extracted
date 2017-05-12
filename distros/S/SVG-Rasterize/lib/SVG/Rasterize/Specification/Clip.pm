package SVG::Rasterize::Specification::Clip;
use strict;
use warnings;

use Params::Validate qw(:types);

use SVG::Rasterize::Regexes qw(:attributes);

# $Id: Clip.pm 6636 2011-04-30 00:17:34Z powergnom $

=head1 NAME

C<SVG::Rasterize::Specification::Clip> - specification for class Clip

=head1 VERSION

Version 0.003007

=cut

our $VERSION = '0.003007';

our %CHILDREN = ('clipPath' => {'altGlyphDef'      => 1,
                                'animate'          => 1,
                                'animateColor'     => 1,
                                'animateMotion'    => 1,
                                'animateTransform' => 1,
                                'circle'           => 1,
                                'desc'             => 1,
                                'ellipse'          => 1,
                                'line'             => 1,
                                'metadata'         => 1,
                                'path'             => 1,
                                'polygon'          => 1,
                                'polyline'         => 1,
                                'rect'             => 1,
                                'set'              => 1,
                                'text'             => 1,
                                'title'            => 1,
                                'use'              => 1});

our %ATTR_VAL = ('clipPath' => {'alignment-baseline'           => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/^(?:auto|baseline|before\-edge|text\-before\-edge|middle|central|after\-edge|text\-after\-edge|ideographic|alphabetic|hanging|mathematical|inherit)$/},
                                'baseline-shift'               => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/.?/},
                                'class'                        => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/.?/},
                                'clip-path'                    => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/.?/},
                                'clip-rule'                    => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/^(?:nonzero|evenodd|inherit)$/},
                                'clipPathUnits'                => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/^(?:userSpaceOnUse|objectBoundingBox)$/},
                                'color'                        => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => $RE_PAINT{p_COLOR}},
                                'color-interpolation'          => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/^(?:auto|sRGB|linearRGB|inherit)$/},
                                'color-rendering'              => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/^(?:auto|optimizeSpeed|optimizeQuality|inherit)$/},
                                'cursor'                       => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/.?/},
                                'direction'                    => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/^(?:ltr|rtl|inherit)$/},
                                'display'                      => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/^(?:inline|block|list\-item|run\-in|compact|marker|table|inline\-table|table\-row\-group|table\-header\-group|table\-footer\-group|table\-row|table\-column\-group|table\-column|table\-cell|table\-caption|none|inherit)$/},
                                'dominant-baseline'            => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/^(?:auto|use\-script|no\-change|reset\-size|ideographic|alphabetic|hanging|mathematical|central|middle|text\-after\-edge|text\-before\-edge|inherit)$/},
                                'externalResourcesRequired'    => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/^(?:false|true)$/},
                                'fill'                         => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => $RE_PAINT{p_PAINT}},
                                'fill-opacity'                 => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/$RE_NUMBER{p_A_NUMBER}|^inherit$/},
                                'fill-rule'                    => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/^(?:nonzero|evenodd|inherit)$/},
                                'filter'                       => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/.?/},
                                'font-family'                  => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/.?/},
                                'font-size'                    => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => $RE_TEXT{p_FONT_SIZE}},
                                'font-size-adjust'             => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/.?/},
                                'font-stretch'                 => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/^(?:normal|wider|narrower|ultra\-condensed|extra\-condensed|condensed|semi\-condensed|semi\-expanded|expanded|extra\-expanded|ultra\-expanded|inherit)$/},
                                'font-style'                   => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/^(?:normal|italic|oblique|inherit)$/},
                                'font-variant'                 => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/^(?:normal|small\-caps|inherit)$/},
                                'font-weight'                  => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/^(?:normal|bold|bolder|lighter|100|200|300|400|500|600|700|800|900|inherit)$/},
                                'glyph-orientation-horizontal' => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/.?/},
                                'glyph-orientation-vertical'   => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/.?/},
                                'id'                           => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => $RE_XML{p_NAME}},
                                'image-rendering'              => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/^(?:auto|optimizeSpeed|optimizeQuality|inherit)$/},
                                'kerning'                      => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/.?/},
                                'letter-spacing'               => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/.?/},
                                'mask'                         => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/.?/},
                                'opacity'                      => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/$RE_NUMBER{p_A_NUMBER}|^inherit$/},
                                'pointer-events'               => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/^(?:visiblePainted|visibleFill|visibleStroke|visible|painted|fill|stroke|all|none|inherit)$/},
                                'requiredExtensions'           => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/.?/},
                                'requiredFeatures'             => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/.?/},
                                'shape-rendering'              => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/^(?:auto|optimizeSpeed|crispEdges|geometricPrecision|inherit)$/},
                                'stroke'                       => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => $RE_PAINT{p_PAINT}},
                                'stroke-dasharray'             => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/$RE_DASHARRAY{p_DASHARRAY}|^inherit$|^none$/},
                                'stroke-dashoffset'            => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/$RE_LENGTH{p_A_LENGTH}|^inherit$/},
                                'stroke-linecap'               => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/^(?:butt|round|square|inherit)$/},
                                'stroke-linejoin'              => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/^(?:miter|round|bevel|inherit)$/},
                                'stroke-miterlimit'            => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/$RE_NUMBER{p_A_NNNUMBER}|^inherit$/},
                                'stroke-opacity'               => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/$RE_NUMBER{p_A_NUMBER}|^inherit$/},
                                'stroke-width'                 => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/$RE_LENGTH{p_A_LENGTH}|^inherit$/},
                                'style'                        => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/.?/},
                                'systemLanguage'               => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/.?/},
                                'text-anchor'                  => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/^(?:start|middle|end|inherit)$/},
                                'text-decoration'              => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/.?/},
                                'text-rendering'               => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/^(?:auto|optimizeSpeed|optimizeLegibility|geometricPrecision|inherit)$/},
                                'transform'                    => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => $RE_TRANSFORM{p_TRANSFORM_LIST}},
                                'unicode-bidi'                 => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/^(?:normal|embed|bidi\-override|inherit)$/},
                                'visibility'                   => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/^(?:visible|hidden|inherit)$/},
                                'word-spacing'                 => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/.?/},
                                'writing-mode'                 => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/^(?:lr\-tb|rl\-tb|tb\-rl|lr|rl|tb|inherit)$/},
                                'xml:base'                     => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/.?/},
                                'xml:lang'                     => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => $RE_XML{p_NMTOKEN}},
                                'xml:space'                    => {'optional' => 1,
                                                                   'type'     => SCALAR,
                                                                   'regex'    => qr/^(?:default|preserve)$/}});

our %ATTR_HINTS = ('clipPath' => {'color'        => {'color'  => 1},
                                  'fill'         => {'color'  => 1},
                                  'stroke'       => {'color'  => 1},
                                  'stroke-width' => {'length' => 1}});

1;


__END__

=pod

=head1 DESCRIPTION

This file was automatically generated using the SVG DTD available
under
L<http://www.w3.org/Graphics/SVG/1.1/DTD/svg11-flat-20030114.dtd>.

See L<SVG::Rasterize::Specification|SVG::Rasterize::Specification>
for more details.


=head1 AUTHOR

Lutz Gehlen, C<< <perl at lutzgehlen.de> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2010-2011 Lutz Gehlen.

This program is free software; you can redistribute it and/or modify
it under the terms of either: the GNU General Public License as
published by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
