package SVG::Rasterize::Specification::Gradient;
use strict;
use warnings;

use Params::Validate qw(:types);

use SVG::Rasterize::Regexes qw(:attributes);

# $Id: Gradient.pm 6636 2011-04-30 00:17:34Z powergnom $

=head1 NAME

C<SVG::Rasterize::Specification::Gradient> - specification for class Gradient

=head1 VERSION

Version 0.003007

=cut

our $VERSION = '0.003007';

our %CHILDREN = ('linearGradient' => {'animate'          => 1,
                                      'animateTransform' => 1,
                                      'desc'             => 1,
                                      'metadata'         => 1,
                                      'set'              => 1,
                                      'stop'             => 1,
                                      'title'            => 1},
                 'radialGradient' => {'animate'          => 1,
                                      'animateTransform' => 1,
                                      'desc'             => 1,
                                      'metadata'         => 1,
                                      'set'              => 1,
                                      'stop'             => 1,
                                      'title'            => 1});

our %ATTR_VAL = ('linearGradient' => {'class'                     => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/.?/},
                                      'color'                     => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => $RE_PAINT{p_COLOR}},
                                      'color-interpolation'       => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/^(?:auto|sRGB|linearRGB|inherit)$/},
                                      'color-rendering'           => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/^(?:auto|optimizeSpeed|optimizeQuality|inherit)$/},
                                      'externalResourcesRequired' => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/^(?:false|true)$/},
                                      'gradientTransform'         => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => $RE_TRANSFORM{p_TRANSFORM_LIST}},
                                      'gradientUnits'             => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/^(?:userSpaceOnUse|objectBoundingBox)$/},
                                      'id'                        => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => $RE_XML{p_NAME}},
                                      'spreadMethod'              => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/^(?:pad|reflect|repeat)$/},
                                      'stop-color'                => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/.?/},
                                      'stop-opacity'              => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/$RE_NUMBER{p_A_NUMBER}|^inherit$/},
                                      'style'                     => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/.?/},
                                      'x1'                        => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => $RE_LENGTH{p_A_LENGTH}},
                                      'x2'                        => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => $RE_LENGTH{p_A_LENGTH}},
                                      'xlink:actuate'             => {'default'  => 'onLoad',
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/^(?:onLoad)$/},
                                      'xlink:arcrole'             => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/.?/},
                                      'xlink:href'                => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/.?/},
                                      'xlink:role'                => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/.?/},
                                      'xlink:show'                => {'default'  => 'other',
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/^(?:other)$/},
                                      'xlink:title'               => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/.?/},
                                      'xlink:type'                => {'default'  => 'simple',
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/^(?:simple)$/},
                                      'xml:base'                  => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/.?/},
                                      'xml:lang'                  => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => $RE_XML{p_NMTOKEN}},
                                      'xml:space'                 => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/^(?:default|preserve)$/},
                                      'xmlns:xlink'               => {'default'  => 'http://www.w3.org/1999/xlink',
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/.?/},
                                      'y1'                        => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => $RE_LENGTH{p_A_LENGTH}},
                                      'y2'                        => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => $RE_LENGTH{p_A_LENGTH}}},
                 'radialGradient' => {'class'                     => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/.?/},
                                      'color'                     => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => $RE_PAINT{p_COLOR}},
                                      'color-interpolation'       => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/^(?:auto|sRGB|linearRGB|inherit)$/},
                                      'color-rendering'           => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/^(?:auto|optimizeSpeed|optimizeQuality|inherit)$/},
                                      'cx'                        => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => $RE_LENGTH{p_A_LENGTH}},
                                      'cy'                        => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => $RE_LENGTH{p_A_LENGTH}},
                                      'externalResourcesRequired' => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/^(?:false|true)$/},
                                      'fx'                        => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => $RE_LENGTH{p_A_LENGTH}},
                                      'fy'                        => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => $RE_LENGTH{p_A_LENGTH}},
                                      'gradientTransform'         => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => $RE_TRANSFORM{p_TRANSFORM_LIST}},
                                      'gradientUnits'             => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/^(?:userSpaceOnUse|objectBoundingBox)$/},
                                      'id'                        => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => $RE_XML{p_NAME}},
                                      'r'                         => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => $RE_LENGTH{p_A_LENGTH}},
                                      'spreadMethod'              => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/^(?:pad|reflect|repeat)$/},
                                      'stop-color'                => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/.?/},
                                      'stop-opacity'              => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/$RE_NUMBER{p_A_NUMBER}|^inherit$/},
                                      'style'                     => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/.?/},
                                      'xlink:actuate'             => {'default'  => 'onLoad',
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/^(?:onLoad)$/},
                                      'xlink:arcrole'             => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/.?/},
                                      'xlink:href'                => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/.?/},
                                      'xlink:role'                => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/.?/},
                                      'xlink:show'                => {'default'  => 'other',
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/^(?:other)$/},
                                      'xlink:title'               => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/.?/},
                                      'xlink:type'                => {'default'  => 'simple',
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/^(?:simple)$/},
                                      'xml:base'                  => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/.?/},
                                      'xml:lang'                  => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => $RE_XML{p_NMTOKEN}},
                                      'xml:space'                 => {'optional' => 1,
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/^(?:default|preserve)$/},
                                      'xmlns:xlink'               => {'default'  => 'http://www.w3.org/1999/xlink',
                                                                      'type'     => SCALAR,
                                                                      'regex'    => qr/.?/}});

our %ATTR_HINTS = ('linearGradient' => {'color' => {'color'  => 1},
                                        'x1'    => {'length' => 1},
                                        'x2'    => {'length' => 1},
                                        'y1'    => {'length' => 1},
                                        'y2'    => {'length' => 1}},
                   'radialGradient' => {'color' => {'color'  => 1},
                                        'cx'    => {'length' => 1},
                                        'cy'    => {'length' => 1},
                                        'fx'    => {'length' => 1},
                                        'fy'    => {'length' => 1},
                                        'r'     => {'length' => 1}});

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
