package PDF::Make::Builder::Image;
use strict;
use warnings;
use Object::Proto;
use PDF::Make::Image;

BEGIN {
    Object::Proto::define('PDF::Make::Builder::Image',
        'image:Str:required',
        'mime:Str',
        'align:Str',
        'x:Num', 'y:Num', 'w:Num', 'h:Num',
    );
    Object::Proto::import_accessors('PDF::Make::Builder::Image');
}

sub add {
    my ($self, $builder) = @_;
    my $page = $builder->page;
    my $canvas = $page->canvas;

    # Load the image
    my $img = PDF::Make::Image->from_file($self->image);
    my $img_w = $img->width;
    my $img_h = $img->height;

    # Write image XObject to document
    my $doc = $builder->doc;
    my $obj_num = $img->write_to_doc($doc);

    # Generate unique resource name
    my $res_name = 'Im' . $obj_num;
    $page->xs_page->add_image($res_name, $obj_num);

    # Determine placement dimensions
    my $draw_w = $self->w // $page->width;
    my $draw_h = $self->h;

    # Maintain aspect ratio if only one dimension given
    if (!defined $draw_h) {
        $draw_h = $draw_w * ($img_h / $img_w);
    }

    # Position
    my $draw_x = $self->x // $page->content_x;
    my $draw_y = $self->y;

    if (!defined $draw_y) {
        $draw_y = $page->cursor_y - $draw_h;
    }

    # Center alignment
    if ($self->align && $self->align eq 'center') {
        $draw_x = $page->content_x + ($page->width - $draw_w) / 2;
    }

    # Draw
    $canvas->image($res_name, $draw_x, $draw_y, $draw_w, $draw_h);

    # Advance cursor
    $page->advance_y($draw_h + 5);

    return $self;
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Builder::Image - Image embedding for PDF::Make

=head1 SYNOPSIS

    $builder->add_image(
        image => '/path/to/photo.jpg',
        w     => 300,
        align => 'center',
    );

=head1 DESCRIPTION

Embeds a raster image (JPEG, PNG, etc.) onto the current page, maintaining
aspect ratio when only one dimension is specified.

=head1 PROPERTIES

=over 4

=item B<image> (Str, required)

File path to the image.

=item B<mime> (Str)

MIME type override.  Normally auto-detected from the file.

=item B<align> (Str)

Horizontal alignment: C<'center'> to centre the image in the content area.

=item B<x> (Num)

Left edge X coordinate.  Defaults to the content area's left edge.

=item B<y> (Num)

Bottom edge Y coordinate (bottom-left origin).  Defaults to the current
cursor minus image height.

=item B<w> (Num)

Display width in points.  Defaults to the full content width.

=item B<h> (Num)

Display height in points.  When omitted, calculated from C<w> to preserve the
image's aspect ratio.

=back

=head1 METHODS

=over 4

=item B<add($builder)>

Embeds and renders the image onto the builder's current page, advancing the
cursor.  Returns C<$self>.

=back

=head1 SEE ALSO

L<PDF::Make::Builder>, L<PDF::Make::Image>

=cut
