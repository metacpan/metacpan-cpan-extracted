package SVG::Rasterize::Specification::Image;
use strict;
use warnings;

use Params::Validate qw(:types);

use SVG::Rasterize::Regexes qw(:attributes);

# $Id: Image.pm 6636 2011-04-30 00:17:34Z powergnom $

=head1 NAME

C<SVG::Rasterize::Specification::Image> - specification for class Image

=head1 VERSION

Version 0.003007

=cut

our $VERSION = '0.003007';

our %CHILDREN = ('image' => {'animate'          => 1,
                             'animateColor'     => 1,
                             'animateMotion'    => 1,
                             'animateTransform' => 1,
                             'desc'             => 1,
                             'metadata'         => 1,
                             'set'              => 1,
                             'title'            => 1});

our %ATTR_VAL = ('image' => {'class'                     => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/.?/},
                             'clip'                      => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/.?/},
                             'clip-path'                 => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/.?/},
                             'clip-rule'                 => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/^(?:nonzero|evenodd|inherit)$/},
                             'color'                     => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => $RE_PAINT{p_COLOR}},
                             'color-interpolation'       => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/^(?:auto|sRGB|linearRGB|inherit)$/},
                             'color-profile'             => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/.?/},
                             'color-rendering'           => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/^(?:auto|optimizeSpeed|optimizeQuality|inherit)$/},
                             'cursor'                    => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/.?/},
                             'display'                   => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/^(?:inline|block|list\-item|run\-in|compact|marker|table|inline\-table|table\-row\-group|table\-header\-group|table\-footer\-group|table\-row|table\-column\-group|table\-column|table\-cell|table\-caption|none|inherit)$/},
                             'externalResourcesRequired' => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/^(?:false|true)$/},
                             'fill-opacity'              => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/$RE_NUMBER{p_A_NUMBER}|^inherit$/},
                             'filter'                    => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/.?/},
                             'height'                    => {'optional' => 0,
                                                             'type'     => SCALAR,
                                                             'regex'    => $RE_LENGTH{p_A_LENGTH}},
                             'id'                        => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => $RE_XML{p_NAME}},
                             'image-rendering'           => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/^(?:auto|optimizeSpeed|optimizeQuality|inherit)$/},
                             'mask'                      => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/.?/},
                             'onactivate'                => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/.?/},
                             'onclick'                   => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/.?/},
                             'onfocusin'                 => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/.?/},
                             'onfocusout'                => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/.?/},
                             'onload'                    => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/.?/},
                             'onmousedown'               => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/.?/},
                             'onmousemove'               => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/.?/},
                             'onmouseout'                => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/.?/},
                             'onmouseover'               => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/.?/},
                             'onmouseup'                 => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/.?/},
                             'opacity'                   => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/$RE_NUMBER{p_A_NUMBER}|^inherit$/},
                             'overflow'                  => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/^(?:visible|hidden|scroll|auto|inherit)$/},
                             'pointer-events'            => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/^(?:visiblePainted|visibleFill|visibleStroke|visible|painted|fill|stroke|all|none|inherit)$/},
                             'preserveAspectRatio'       => {'default'  => 'xMidYMid meet',
                                                             'type'     => SCALAR,
                                                             'regex'    => $RE_VIEW_BOX{p_PAR}},
                             'requiredExtensions'        => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/.?/},
                             'requiredFeatures'          => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/.?/},
                             'shape-rendering'           => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/^(?:auto|optimizeSpeed|crispEdges|geometricPrecision|inherit)$/},
                             'stroke-opacity'            => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/$RE_NUMBER{p_A_NUMBER}|^inherit$/},
                             'style'                     => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/.?/},
                             'systemLanguage'            => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/.?/},
                             'text-rendering'            => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/^(?:auto|optimizeSpeed|optimizeLegibility|geometricPrecision|inherit)$/},
                             'transform'                 => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => $RE_TRANSFORM{p_TRANSFORM_LIST}},
                             'visibility'                => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/^(?:visible|hidden|inherit)$/},
                             'width'                     => {'optional' => 0,
                                                             'type'     => SCALAR,
                                                             'regex'    => $RE_LENGTH{p_A_LENGTH}},
                             'x'                         => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => $RE_LENGTH{p_A_LENGTH}},
                             'xlink:actuate'             => {'default'  => 'onLoad',
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/^(?:onLoad)$/},
                             'xlink:arcrole'             => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/.?/},
                             'xlink:href'                => {'optional' => 0,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/.?/},
                             'xlink:role'                => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/.?/},
                             'xlink:show'                => {'default'  => 'embed',
                                                             'type'     => SCALAR,
                                                             'regex'    => qr/^(?:embed)$/},
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
                             'y'                         => {'optional' => 1,
                                                             'type'     => SCALAR,
                                                             'regex'    => $RE_LENGTH{p_A_LENGTH}}});

our %ATTR_HINTS = ('image' => {'color'  => {'color'  => 1},
                               'height' => {'length' => 1},
                               'width'  => {'length' => 1},
                               'x'      => {'length' => 1},
                               'y'      => {'length' => 1}});

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
