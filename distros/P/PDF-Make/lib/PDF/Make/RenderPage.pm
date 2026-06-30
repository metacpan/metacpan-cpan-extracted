package PDF::Make::RenderPage;

use strict;
use warnings;
use Carp qw(croak);
use PDF::Make ();  # load XS so SCALE_*/ROTATE_* constants are defined

our $VERSION = '0.05';

=head1 NAME

PDF::Make::RenderPage - Render PDF pages to pixel buffers

=head1 SYNOPSIS

    use PDF::Make::Reader;
    use PDF::Make::RenderPage;

    # Open a PDF
    my $reader = PDF::Make::Reader->open('document.pdf');

    # Get page dimensions
    my ($width, $height) = PDF::Make::RenderPage::get_page_render_size(
        $reader, 0, 150  # page 0 at 150 DPI
    );

    # Render the page
    my $result = PDF::Make::RenderPage::render_page($reader, 0, {
        dpi        => 150,
        background => 0xFFFFFFFF,  # White background
        antialias  => 1,
    });

    # Access the rendered data
    my $pixels = $result->{pixels};  # Raw RGBA data
    my $width  = $result->{width};
    my $height = $result->{height};

    # Render a region
    my $region = PDF::Make::RenderPage::render_page_region(
        $reader, 0,
        100, 100, 200, 200,  # x, y, w, h in PDF units
        { dpi => 150 }
    );

=head1 DESCRIPTION

PDF::Make::RenderPage provides the render pipeline for converting PDF pages
to rasterized pixel output. It integrates the content stream interpreter
with the path rendering engine to produce accurate visual representations
of PDF pages.

=head1 FUNCTIONS

=head2 get_page_render_size($reader, $page_num, $dpi)

Returns the pixel dimensions (width, height) that a page will have when
rendered at the specified DPI.

=head2 render_page($reader, $page_num, \%options)

Render a page to a pixel buffer. Returns a hashref containing:

    {
        pixels         => $raw_rgba_data,
        width          => $pixel_width,
        height         => $pixel_height,
        render_time_ms => $milliseconds,
        effective_dpi  => $actual_dpi,
        path_objects   => $path_count,
        text_objects   => $text_count,
        image_objects  => $image_count,
        error          => $error_message,  # if any
    }

=head2 render_page_region($reader, $page_num, $x, $y, $w, $h, \%options)

Render only a portion of a page. Coordinates are in PDF user space units.

=head1 OPTIONS

=over 4

=item dpi

Dots per inch for rendering. Default is 72 (1:1 with PDF units).

=item scale_mode

Scaling algorithm for images: SCALE_NEAREST, SCALE_BILINEAR, SCALE_BICUBIC.

=item rotation

Page rotation: ROTATE_0, ROTATE_90, ROTATE_180, ROTATE_270.

=item antialias

Enable antialiasing (1) or disable (0). Default is 1.

=item background

Background color as 0xAARRGGBB. Default is white (0xFFFFFFFF).

=item clip_x, clip_y, clip_w, clip_h

Render only a clipped region in pixel coordinates.

=item render_text

Render text objects (1) or skip them (0). Default is 1.

=item render_images

Render image XObjects (1) or skip them (0). Default is 1.

=item render_vectors

Render vector paths (1) or skip them (0). Default is 1.

=back

=head1 CONSTANTS

=head2 Scale Modes

    SCALE_NEAREST   = 0
    SCALE_BILINEAR  = 1
    SCALE_BICUBIC   = 2

=head2 Rotation

    ROTATE_0   = 0
    ROTATE_90  = 90
    ROTATE_180 = 180
    ROTATE_270 = 270

=cut

# SCALE_*, ROTATE_*, and the render_page/render_page_region/get_page_render_size
# functions are all provided by the XS loaded above.

1;

__END__

=head1 SEE ALSO

L<PDF::Make>, L<PDF::Make::Reader>, L<PDF::Make::Render>

=head1 AUTHOR

LNATION E<lt>email@lnation.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
