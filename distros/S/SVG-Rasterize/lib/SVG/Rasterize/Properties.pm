package SVG::Rasterize::Properties;
use strict;
use warnings;

use Exporter 'import';

# $Id: Properties.pm 5524 2010-05-10 09:26:04Z mullet $

=head1 NAME

C<SVG::Rasterize::Properties> - SVG styling properties

=head1 VERSION

Version 0.000009

=cut

our $VERSION = '0.000009';

our @EXPORT    = qw(%PROPERTIES);
our @EXPORT_OK = qw();

our %PROPERTIES =
    ('alignment-baseline'           => {default      => undef,
                                        inherited    => 0,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'baseline-shift'               => {default      => 'baseline',
                                        inherited    => 0,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'clip'                         => {default      => 'auto',
                                        inherited    => 0,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'clip-path'                    => {default      => 'none',
                                        inherited    => 0,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'clip-rule'                    => {default      => 'nonzero',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'color'                        => {default      => undef,
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'color-interpolation'          => {default      => 'sRGB',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'color-interpolation-filters'  => {default      => 'linearRGB',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'color-profile'                => {default      => 'auto',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'color-rendering'              => {default      => 'auto',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'cursor'                       => {default      => 'auto',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {interactive      => 1,
                                                         visual           => 1}},
     'direction'                    => {default      => 'ltr',
                                        inherited    => 1,
                                        animatable   => 0,
                                        media_groups => {visual           => 1}},
     'display'                      => {default      => 'inline',
                                        inherited    => 0,
                                        animatable   => 1,
                                        media_groups => {aural            => 1,
                                                         bitmap           => 1,
                                                         continuous       => 1,
                                                         grid             => 1,
                                                         interactive      => 1,
                                                         paged            => 1,
                                                         static           => 1,
                                                         tactile          => 1,
                                                         visual           => 1}},
     'dominant-baseline'            => {default      => 'auto',
                                        inherited    => 0,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'enable-background'            => {default      => 'accumulate',
                                        inherited    => 0,
                                        animatable   => 0,
                                        media_groups => {visual           => 1}},
     'fill'                         => {default      => 'black',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'fill-opacity'                 => {default      => '1',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'fill-rule'                    => {default      => 'nonzero',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'filter'                       => {default      => 'none',
                                        inherited    => 0,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'flood-color'                  => {default      => 'black',
                                        inherited    => 0,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'flood-opacity'                => {default      => '1',
                                        inherited    => 0,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'font'                         => {default      => undef,
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'font-family'                  => {default      => undef,
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'font-size'                    => {default      => 'medium',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'font-size-adjust'             => {default      => 'none',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'font-stretch'                 => {default      => 'normal',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'font-style'                   => {default      => 'normal',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'font-variant'                 => {default      => 'normal',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'font-weight'                  => {default      => 'normal',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'glyph-orientation-horizontal' => {default      => '0deg',
                                        inherited    => 1,
                                        animatable   => 0,
                                        media_groups => {visual           => 1}},
     'glyph-orientation-vertical'   => {default      => 'auto',
                                        inherited    => 1,
                                        animatable   => 0,
                                        media_groups => {visual           => 1}},
     'image-rendering'              => {default      => 'auto',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'kerning'                      => {default      => 'auto',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'letter-spacing'               => {default      => 'normal',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'lighting-color'               => {default      => 'white',
                                        inherited    => 0,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'marker'                       => {default      => undef,
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'marker-end'                   => {default      => 'none',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'marker-mid'                   => {default      => 'none',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'marker-start'                 => {default      => 'none',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'mask'                         => {default      => 'none',
                                        inherited    => 0,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'opacity'                      => {default      => '1',
                                        inherited    => 0,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'overflow'                     => {default      => undef,
                                        inherited    => 0,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'pointer-events'               => {default      => 'visiblePainted',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'shape-rendering'              => {default      => 'auto',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'stop-color'                   => {default      => 'black',
                                        inherited    => 0,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'stop-opacity'                 => {default      => '1',
                                        inherited    => 0,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'stroke'                       => {default      => 'none',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'stroke-dasharray'             => {default      => 'none',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'stroke-dashoffset'            => {default      => '0',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'stroke-linecap'               => {default      => 'butt',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'stroke-linejoin'              => {default      => 'miter',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'stroke-miterlimit'            => {default      => '4',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'stroke-opacity'               => {default      => '1',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'stroke-width'                 => {default      => '1',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'text-anchor'                  => {default      => 'start',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'text-decoration'              => {default      => 'none',
                                        inherited    => 0,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'text-rendering'               => {default      => 'auto',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'unicode-bidi'                 => {default      => 'normal',
                                        inherited    => 0,
                                        animatable   => 0,
                                        media_groups => {visual           => 1}},
     'visibility'                   => {default      => 'visible',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'word-spacing'                 => {default      => 'normal',
                                        inherited    => 1,
                                        animatable   => 1,
                                        media_groups => {visual           => 1}},
     'writing-mode'                 => {default      => 'lr-tb',
                                        inherited    => 1,
                                        animatable   => 0,
                                        media_groups => {visual           => 1}});

1;


__END__

=pod

=head1 DESCRIPTION

This file is automatically generated using the property table
under
L<http://www.w3.org/TR/SVG11/propidx.html>.

The data structures are used mainly by
L<SVG::Rasterize::State|SVG::Rasterize::State> for validation and
processing of the SVG input tree.

=head1 ACKNOWLEDGEMENTS

The parsing of the properties table in order to generate the data
structures in this module was done with
L<HTML::TokeParser|HTML::TokeParser> by Gisle Aas.

=head1 SEE ALSO

=over 4

=item * L<SVG::Rasterize|SVG::Rasterize>

=back


=head1 AUTHOR

Lutz Gehlen, C<< <perl at lutzgehlen.de> >>


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Lutz Gehlen.

This program is free software; you can redistribute it and/or modify
it under the terms of either: the GNU General Public License as
published by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut
