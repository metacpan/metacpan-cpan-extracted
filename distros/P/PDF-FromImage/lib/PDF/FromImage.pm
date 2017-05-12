package PDF::FromImage;
use 5.008001;
use Moose;

our $VERSION = '0.000003';

use PDF::API2;
use Imager;

use PDF::FromImage::Image;

has images => (
    is      => 'rw',
    isa     => 'ArrayRef',
    lazy    => 1,
    default => sub { [] },
);

=head1 NAME

PDF::FromImage - Create PDF slide from images

=head1 SYNOPSIS
    
    use PDF::FromImage;
    
    my $pdf = PDF::FromImage->new;
    
    $pdf->load_images(
        'page1.png',
        'page2.png',
        :
    );
    
    $pdf->write_file('output.pdf');

=head1 DESCRIPTION

This module create simple pdf image slide from multiple images.

=head1 METHODS

=head2 load_image($filename)

Load a image file.

Supported format are jpeg, tiff, pnm, png, and gif.

=cut

sub load_image {
    my ($self, $image) = @_;

    my $imager = Imager->new;
    $imager->read( file => $image )
        or confess $imager->errstr;

    my $format    = $imager->tags( name => 'i_format' );
    my $supported = grep { $_ eq $format } qw/jpeg tiff pnm png gif/;

    confess qq{This module doen't support "$format"} unless $supported;

    my $image_object = PDF::FromImage::Image->new(
        src    => $image,
        format => $format,
        width  => $imager->getwidth,
        height => $imager->getheight,
    );

    push @{ $self->images }, $image_object;
}

=head2 load_images(@filenames)

Load multiple images.

=cut

sub load_images {
    my $self = shift;
    $self->load_image($_) for @_;
}

=head2 write_file($filename)

Generate pdf from loaded images, and write it to file.

=cut

sub write_file {
    my ($self, $filename) = @_;
    confess 'no image is loaded' unless @{ $self->images };

    my $pdf = PDF::API2->new;

    for my $image (@{ $self->images }) {
        my $page = $pdf->page;
        $page->mediabox( $image->width, $image->height );

        my $loader = 'image_' . $image->format;
        my $img = $pdf->$loader($image->src);

        my $gfx = $page->gfx;
        $gfx->image( $img, 0, 0 );
    }

    $pdf->saveas($filename);
    $pdf->end;
}

=head1 AUTHOR

Daisuke Murase <typester@cpan.org>

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;
