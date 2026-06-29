package PDF::Make::Render;

use strict;
use warnings;
use Carp qw(croak);

our $VERSION = '0.04';

# Load the XS module
require PDF::Make;

=head1 NAME

PDF::Make::Render - Native path rendering for PDF content

=head1 SYNOPSIS

    use PDF::Make::Render;

    # Create a render context
    my $ctx = PDF::Make::Render->new(800, 600);

    # Set up graphics state
    $ctx->save;
    $ctx->set_fill_color(1, 0, 0);  # Red
    $ctx->set_stroke_color(0, 0, 0);
    $ctx->set_line_width(2);

    # Build a path
    $ctx->move_to(100, 100);
    $ctx->line_to(200, 100);
    $ctx->line_to(200, 200);
    $ctx->close_path;

    # Render
    $ctx->fill;

    $ctx->restore;

    # Get pixel data
    my $pixels = $ctx->get_pixels;

=head1 DESCRIPTION

PDF::Make::Render provides a native path rendering engine for PDF content.
It implements PDF's imaging model including paths, fills, strokes, clipping,
and transformations.

=head1 METHODS

=head2 new($width, $height)

Create a new render context with the specified dimensions.

=head2 width / height

Get the dimensions of the render context.

=head2 clear($r, $g, $b, $a)

Clear the context to the specified color.

=head2 save / restore

Save or restore graphics state.

=head2 Path Building

=over 4

=item move_to($x, $y)

Begin a new subpath.

=item line_to($x, $y)

Add a line segment.

=item curve_to($x1, $y1, $x2, $y2, $x3, $y3)

Add a cubic Bezier curve.

=item close_path

Close the current subpath.

=item rectangle($x, $y, $w, $h)

Add a rectangle to the path.

=back

=head2 Path Painting

=over 4

=item fill

Fill the current path using non-zero winding rule.

=item stroke

Stroke the current path.

=item fill_stroke

Fill and stroke the current path.

=item clip

Clip to the current path.

=back

=head2 Color

=over 4

=item set_fill_color($r, $g, $b, $a)

Set the fill color.

=item set_stroke_color($r, $g, $b, $a)

Set the stroke color.

=back

=head2 Line Properties

=over 4

=item set_line_width($width)

Set the line width.

=item set_line_cap($cap)

Set line cap style (0=butt, 1=round, 2=square).

=item set_line_join($join)

Set line join style (0=miter, 1=round, 2=bevel).

=item set_miter_limit($limit)

Set the miter limit.

=back

=head2 Transformations

=over 4

=item set_matrix($a, $b, $c, $d, $e, $f)

Set the current transformation matrix.

=item concat_matrix($a, $b, $c, $d, $e, $f)

Concatenate a matrix with the current CTM.

=back

=head2 Output

=over 4

=item get_pixels

Get the raw pixel data as a scalar (RGBA format).

=item get_pixel($x, $y)

Get a single pixel as ($r, $g, $b, $a).

=back

=head1 CONSTANTS

=head2 Line Cap

    PDFMAKE_LINE_CAP_BUTT   = 0
    PDFMAKE_LINE_CAP_ROUND  = 1
    PDFMAKE_LINE_CAP_SQUARE = 2

=head2 Line Join

    PDFMAKE_LINE_JOIN_MITER = 0
    PDFMAKE_LINE_JOIN_ROUND = 1
    PDFMAKE_LINE_JOIN_BEVEL = 2

=cut

# Export constants
use constant {
    LINE_CAP_BUTT   => 0,
    LINE_CAP_ROUND  => 1,
    LINE_CAP_SQUARE => 2,
    
    LINE_JOIN_MITER => 0,
    LINE_JOIN_ROUND => 1,
    LINE_JOIN_BEVEL => 2,
    
    FILL_RULE_NONZERO => 0,
    FILL_RULE_EVENODD => 1,
};

# Nothing else needed - XS provides all the methods

1;

__END__

=head1 SEE ALSO

L<PDF::Make>, L<PDF::Make::RenderPage>

=head1 AUTHOR

LNATION E<lt>email@lnation.orgE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
