package SVG::Rasterize::Specification::ColorProfile;
use strict;
use warnings;

use Params::Validate qw(:types);

use SVG::Rasterize::Regexes qw(:attributes);

# $Id: ColorProfile.pm 6636 2011-04-30 00:17:34Z powergnom $

=head1 NAME

C<SVG::Rasterize::Specification::ColorProfile> - specification for class ColorProfile

=head1 VERSION

Version 0.003007

=cut

our $VERSION = '0.003007';

our %CHILDREN = ('color-profile' => {'desc'     => 1,
                                     'metadata' => 1,
                                     'title'    => 1});

our %ATTR_VAL = ('color-profile' => {'id'               => {'optional' => 1,
                                                            'type'     => SCALAR,
                                                            'regex'    => $RE_XML{p_NAME}},
                                     'local'            => {'optional' => 1,
                                                            'type'     => SCALAR,
                                                            'regex'    => qr/.?/},
                                     'name'             => {'optional' => 0,
                                                            'type'     => SCALAR,
                                                            'regex'    => qr/.?/},
                                     'rendering-intent' => {'default'  => 'auto',
                                                            'type'     => SCALAR,
                                                            'regex'    => qr/^(?:auto|perceptual|relative\-colorimetric|saturation|absolute\-colorimetric)$/},
                                     'xlink:actuate'    => {'default'  => 'onLoad',
                                                            'type'     => SCALAR,
                                                            'regex'    => qr/^(?:onLoad)$/},
                                     'xlink:arcrole'    => {'optional' => 1,
                                                            'type'     => SCALAR,
                                                            'regex'    => qr/.?/},
                                     'xlink:href'       => {'optional' => 1,
                                                            'type'     => SCALAR,
                                                            'regex'    => qr/.?/},
                                     'xlink:role'       => {'optional' => 1,
                                                            'type'     => SCALAR,
                                                            'regex'    => qr/.?/},
                                     'xlink:show'       => {'default'  => 'other',
                                                            'type'     => SCALAR,
                                                            'regex'    => qr/^(?:other)$/},
                                     'xlink:title'      => {'optional' => 1,
                                                            'type'     => SCALAR,
                                                            'regex'    => qr/.?/},
                                     'xlink:type'       => {'default'  => 'simple',
                                                            'type'     => SCALAR,
                                                            'regex'    => qr/^(?:simple)$/},
                                     'xml:base'         => {'optional' => 1,
                                                            'type'     => SCALAR,
                                                            'regex'    => qr/.?/},
                                     'xml:lang'         => {'optional' => 1,
                                                            'type'     => SCALAR,
                                                            'regex'    => $RE_XML{p_NMTOKEN}},
                                     'xml:space'        => {'optional' => 1,
                                                            'type'     => SCALAR,
                                                            'regex'    => qr/^(?:default|preserve)$/},
                                     'xmlns:xlink'      => {'default'  => 'http://www.w3.org/1999/xlink',
                                                            'type'     => SCALAR,
                                                            'regex'    => qr/.?/}});

our %ATTR_HINTS = ('color-profile' => {});

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
