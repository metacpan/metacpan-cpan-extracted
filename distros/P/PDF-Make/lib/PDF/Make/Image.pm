package PDF::Make::Image;

use strict;
use warnings;

our $VERSION = '0.04';

# Load the XS code from PDF::Make
use PDF::Make ();

1;

__END__

=head1 NAME

PDF::Make::Image - Image embedding for PDF documents

=head1 SYNOPSIS

    use PDF::Make::Image;
    use PDF::Make::Document;
    use PDF::Make::Canvas;

    my $doc = PDF::Make::Document->new;
    my $page = $doc->add_page(612, 792);

    # Load an image
    my $img = PDF::Make::Image->from_file('photo.jpg');

    # Write image XObject to document
    my $obj_num = $img->write_to_doc($doc);

    # Register on page
    $page->add_image('Im0', $obj_num);

    # Draw on canvas
    my $canvas = PDF::Make::Canvas->new;
    $canvas->image('Im0', 72, 500, 200, 150);  # name, x, y, width, height

    $page->set_content($canvas->to_bytes);
    $doc->to_file('output.pdf');

=head1 DESCRIPTION

C<PDF::Make::Image> handles embedding JPEG and PNG images in PDF documents.

=over 4

=item * B<JPEG>: DCTDecode passthrough (raw JPEG bytes wrapped directly)

=item * B<PNG>: Decompressed, re-encoded with FlateDecode + PNG predictor.
Alpha channel emitted as a separate /SMask XObject.

=back

=head1 METHODS

=head2 from_file($path)

Load an image from a file path. Format auto-detected from magic bytes.

=head2 from_bytes($bytes)

Load an image from raw bytes. Format auto-detected.

=head2 width, height

Image dimensions in pixels.

=head2 format

Image format: 0 = JPEG, 1 = PNG, 2 = Raw.

=head2 components

Number of colour components (1=gray, 3=RGB, 4=CMYK).

=head2 has_alpha

True if the image has an alpha channel.

=head2 write_to_doc($doc)

Write the image as an /Image XObject to the document.
Returns the indirect object number.

=head1 SEE ALSO

L<PDF::Make::Document>, L<PDF::Make::Canvas>, L<PDF::Make::Page>

=cut
