package PDF::Make::Builder::Shape::Box;
use strict;
use warnings;
use Object::Proto;

BEGIN {
    Object::Proto::define('PDF::Make::Builder::Shape::Box',
        'fill_colour:Str:default(#000)',
        'x:Num', 'y:Num',
        'w:Num', 'h:Num',
    );
    Object::Proto::import_accessors('PDF::Make::Builder::Shape::Box');
}

sub add {
    my ($self, $builder) = @_;
    my $page = $builder->page;
    my $canvas = $page->canvas;
    my $font = $builder->font;

    my $bx = $self->x // $page->content_x;
    my $bw = $self->w // $page->width;
    my $bh = $self->h // 50;

    my $by = $self->y;
    if (!defined $by) {
        $by = $page->cursor_y - $bh;
    }

    my $colour = fill_colour $self;
    my ($r, $g, $b) = $font->hex_to_rgb($colour);

    $canvas->q;
    if ($colour eq 'transparent') {
        $canvas->w(1)->RG($r, $g, $b)->re($bx, $by, $bw, $bh)->S;
    } else {
        $canvas->rg($r, $g, $b)->re($bx, $by, $bw, $bh)->f;
    }
    $canvas->Q;

    # Advance cursor
    $page->advance_y($bh + 5);

    return $self;
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Builder::Shape::Box - Filled or stroked rectangle for PDF::Make

=head1 SYNOPSIS

    $builder->add_shape(box => {
        fill_colour => '#eee',
        x           => 50,
        y           => 100,
        w           => 200,
        h           => 80,
    });

=head1 DESCRIPTION

Draws a rectangle on the current page canvas, either filled or stroked
(when C<fill_colour> is C<'transparent'>).

=head1 PROPERTIES

=over 4

=item B<fill_colour> (Str, default C<'#000'>)

Fill colour as a hex string.  Use C<'transparent'> for a stroked outline only.

=item B<x> (Num)

Left edge X coordinate.  Defaults to the content area's left edge.

=item B<y> (Num)

Bottom edge Y coordinate (bottom-left origin).  Defaults to the current
cursor minus box height.

=item B<w> (Num)

Width in points.  Defaults to the full content width.

=item B<h> (Num)

Height in points.  Defaults to 50.

=back

=head1 METHODS

=over 4

=item B<add($builder)>

Renders the rectangle onto the current page canvas.  Returns C<$self>.

=back

=head1 SEE ALSO

L<PDF::Make::Builder>, L<PDF::Make::Builder::Shape::Line>

=cut
