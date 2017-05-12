package Plucene::SearchEngine::Index::Image;
use strict;
use warnings;
use base 'Plucene::SearchEngine::Index::Base';
use Image::Info qw(image_info dim);
use Time::Piece;
use Date::Parse;

our $VERSION = '0.01';

__PACKAGE__->register_handler(qw( 
    image/bmp           .bmp 
    image/gif           .gif
    image/jpeg          jpeg jpg jpe
    image/png           png
    image/x-portable-bitmap     pbm
    image/x-portable-graymap    pgm
    image/x-portable-pixmap     ppm
    image/svg+xml           svg
    image/tiff          tiff tif
    image/x-xbitmap         xbm
    image/x-xpixmap         xpm
));

sub gather_data_from_file {
    my ($self, $filename) = @_;
    my $info = image_info($filename);
    return if $info->{error};
    $self->add_data("size", "Text", scalar dim($info));
    $self->add_data("text", "UnStored", $info->{Comment});
    $self->add_data("subtype", "Text", $info->{file_ext});
    $self->add_data("created", "Date", Time::Piece->new(str2time($info->{LastModificationTime})));
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Plucene::SearchEngine::Index::Image - Backend for mining data about images

=head1 DESCRIPTION

Upon installation, this acts as a handler for images, using
C<Image::Info> to populate the following Plucene fields:

=over 3

=item size

The dimensions of the image.

=item text

Any comments found in the image.

=item subtype

The type of image. (C<jpg>, C<png>, etc.)

=item created

A Plucene data field representing the last modified date encoded in the
image itself.

=back

=head1 SEE ALSO

L<Plucene::SearchEngine::Index>

=head1 AUTHOR

Simon Cozens, E<lt>simon@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Simon Cozens

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
