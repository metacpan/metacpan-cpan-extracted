# $Id$
package Prima::IPA::Misc;
use strict;
require Exporter;
require DynaLoader;

use vars qw(@ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw( split_channels combine_channels histogram);
%EXPORT_TAGS = ();

1;

__DATA__

=pod

=head1 NAME

Prima::IPA::Misc - miscellaneous uncategorized routines

=over

=item split_channels IMAGE, [ MODE = 'rgb' ]

Splits IMAGE onto channels, with the selected MODE, which
currently can be C<'rgb'> or C<'hsv'> string constants. 
Returns channels as anonymous array of image objects.

=over

=item rgb

Supported types: RGB .
Returns: 3 Byte images .

=item hsv

Supported types: RGB .
Returns: 3 float images - with hue, saturation, and value .
Ranges: hue: 0-360, saturation: 0-1, value: 0-1 .

=back

=item combine_channels [IMAGES], [ MODE = 'rgb' ]

Combines list of channel IMAGES into single image, with the selected 
MODE, which currently can be C<'rgb'> , C<'hsv'>, C<'alphaNUM'> string constants. 
Returns the combined image.

=over

=item rgb

Supported types: Byte .
Returns: RGB image . 

=item hsv

Supported types: Float .
Returns: RGB image .
Channel ranges: hue: 0-360, saturation: 0-1, value: 0-1

=item alphaNUM

Supported types: RGB, Byte .
Returns: Same type as input .
NUM range: 0 - 255 .

=back

=item histogram IMAGE

Returns array of 256 integers, each representing
number of pixels with the corresponding value for IMAGE.

Supported types: 8-bit

=back

=cut
