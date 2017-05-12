package Selenium::Screenshot::CanPad;
$Selenium::Screenshot::CanPad::VERSION = '0.08';
use Scalar::Util qw/blessed/;
use Carp qw/croak/;
# ABSTRACT: Provides subs for coercing two images to the exact width and height
use Moo::Role;



sub coerce_image_size {
    my ($self, $image1, $image2) = @_;

    foreach ( $image1, $image2 ) {
        croak 'Expected two Imager objects' unless blessed $_ && $_->isa('Imager');
    }

    my $coerce_dims = _get_largest_dimensions( $image1, $image2 );

    if ( _is_smaller( $image1, $coerce_dims ) ) {
        $image1 = _pad_image( $image1, $coerce_dims );
    }

    if ( _is_smaller( $image2, $coerce_dims ) ) {
        $image2 = _pad_image( $image2, $coerce_dims );
    }

    return ( $image1, $image2 );
}


sub cmp_image_dims {
    my ($self, $image1, $image2) = @_;

    foreach ( $image1, $image2 ) {
        croak 'Expected two Imager objects'
          unless blessed $_ && $_->isa('Imager');
    }

    return $image1->getheight == $image2->getheight &&
      $image1->getwidth == $image2->getwidth;
}

sub _get_largest_dimensions {
    my ($image1, $image2) = @_;

    my $max_width = $image1->getwidth >= $image2->getwidth
      ? $image1->getwidth
      : $image2->getwidth;

    my $max_height = $image1->getheight >= $image2->getheight
      ? $image1->getheight
      : $image2->getheight;

    my $dimensions = {
        width => $max_width,
        height => $max_height
    };

    return $dimensions
}

sub _is_smaller {
    my ($image, $dimensions) = @_;

    return $image->getwidth < $dimensions->{width} ||
      $image->getheight < $dimensions->{height};
}

sub _pad_image {
    my ($image, $dimensions) = @_;

    my $padded_image = Imager->new(
        xsize => $dimensions->{width},
        ysize => $dimensions->{height},
        channels => $image->getchannels
    );

    $padded_image->paste(
        left => 0,
        top => 0,
        img => $image
    );

    return $padded_image;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Selenium::Screenshot::CanPad - Provides subs for coercing two images to the exact width and height

=head1 VERSION

version 0.08

=head1 SYNOPSIS

    my $tall = Imager->new( xsize => 10, ysize => 20 );
    my $wide = Imager->new( xsize => 20, ysize => 10 );

    my ($square1, $square2) = Selenium::Screenshot::CanPad->coerce_image_size(
        $tall, $wide
    );

    is( $square1->getwidth , $square2->getwidth , 'Same width'  );
    is( $square1->getheight, $square2->getheight, 'Same height' );

=head1 DESCRIPTION

For L<Selenium::Screenshot/compare> to be able to compare two Imager
objects, the objects must be exactly the same height and width. This
package provides a function L</coerce_image_size> that does exactly
that: given two Imager objects, it returns an ARRAY of two Imager
objects that are the same size.

It does this by getting the largest width and height from either
image, and adding blck padding to the bottom and/or right of either
image if necessary.

=head1 METHODS

=head2 coerce_image_size ( $image1, $image2 )

This sub has two required arguments: two Imager objects. It uses the
largest width and height of either image, and pad both of them until
both images are the same size as the largest image. The example in the
synopsis is probably most helpful: given a 10x20 image and a 20x10
image, this sub would return two 20x20 images, each padded
accordingly.

=head2 cmp_image_dims ( $image1, $image2 );

This sub has two required arguments: two Imager objects. If both
images have the exact same height and width, it will return truthy;
otherwise it will return falsy.

This is a public function because of the way Selenium::Screenshot is
set up - its L<Selenium::Screenshot/_set_opponent> subroutine needs to
know whether or not it should be overwriting the C<png> attr of the
object, as it's a C<isa => 'rwp'> attribute. If we were keep this sub
private to this role, the consuming role would have to overwrite its
attribute unnecessarily.

=head1 SEE ALSO

Please see those modules/websites for more information related to this module.

=over 4

=item *

L<Selenium::Screenshot|Selenium::Screenshot>

=back

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/gempesaw/Selenium-Screenshot/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

Daniel Gempesaw <gempesaw@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Daniel Gempesaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
