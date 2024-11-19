package STIX::Observable::Extension::RasterImage;

use 5.010001;
use strict;
use warnings;
use utf8;

use Types::Standard qw(Int HashRef);

use Moo;
use namespace::autoclean;

extends 'STIX::Object';

use constant PROPERTIES => (qw[
    image_height
    image_width
    bits_per_pixel
    exif_tags
]);

use constant EXTENSION_TYPE => 'raster-image-ext';

has image_height   => (is => 'rw', isa => Int);
has image_width    => (is => 'rw', isa => Int);
has bits_per_pixel => (is => 'rw', isa => Int);
has exif_tags      => (is => 'rw', isa => HashRef);

1;

=encoding utf-8

=head1 NAME

STIX::Observable::Extension::RasterImage - STIX Cyber-observable Object (SCO) - Raster Image File Extension

=head1 SYNOPSIS

    use STIX::Observable::Extension::RasterImage;

    my $raster_image_ext = STIX::Observable::Extension::RasterImage->new();


=head1 DESCRIPTION

The Raster Image file extension specifies a default extension for
capturing properties specific to image files.

=head2 METHODS

L<STIX::Observable::Extension::RasterImage> inherits all methods from L<STIX::Object>
and implements the following new ones.

=over

=item STIX::Observable::Extension::RasterImage->new(%properties)

Create a new instance of L<STIX::Observable::Extension::RasterImage>.

=item $raster_image->image_height

Specifies the height of the image in the image file, in pixels.

=item $raster_image->image_width

Specifies the width of the image in the image file, in pixels.

=item $raster_image->bits_per_pixel

Specifies the sum of bits used for each color channel in the image in the image file,
and thus the total number of pixels used for expressing the color depth of the image.

=item $raster_image->exif_tags

Specifies the set of EXIF tags found in the image file, as a dictionary.
Each key/value pair in the dictionary represents the name/value of a single EXIF tag.

=back


=head2 HELPERS

=over

=item $raster_image_ext->TO_JSON

Helper for JSON encoders.

=item $raster_image_ext->to_hash

Return the object HASH.

=item $raster_image_ext->to_string

Encode the object in JSON.

=item $raster_image_ext->validate

Validate the object using JSON Schema (see L<STIX::Schema>).

=back


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-STIX/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-STIX>

    git clone https://github.com/giterlizzi/perl-STIX.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2024 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
