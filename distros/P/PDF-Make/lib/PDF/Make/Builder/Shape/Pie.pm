package PDF::Make::Builder::Shape::Pie;
use strict;
use warnings;
use Object::Proto;
use POSIX qw(floor);

BEGIN {
    Object::Proto::define('PDF::Make::Builder::Shape::Pie',
        'fill_colour:Str:default(#000)',
        'x:Num:required',
        'y:Num:required',
        'r:Num:required',
        'rx:Num:required',
        'ry:Num:required',
    );
    Object::Proto::import_accessors('PDF::Make::Builder::Shape::Pie');
}

use constant PI => 3.14159265358979323846;

sub add {
    my ($self, $builder) = @_;
    my $page = $builder->page;
    my $canvas = $page->canvas;
    my $font = $builder->font;

    my $cx = $self->x;
    my $cy = $self->y;
    my $radius = $self->r;
    my $start_deg = $self->rx;
    my $end_deg = $self->ry;
    my ($cr, $cg, $cb) = $font->hex_to_rgb(fill_colour $self);

    my $start = $start_deg * PI / 180;
    my $end   = $end_deg * PI / 180;

    $canvas->q->rg($cr, $cg, $cb);

    # Move to center, line to arc start
    $canvas->m($cx, $cy);
    $canvas->l($cx + $radius * cos($start), $cy + $radius * sin($start));

    # Approximate arc with Bezier segments (max 90 degrees each)
    my $angle = $end - $start;
    $angle += 2 * PI if $angle < 0;
    my $segments = int($angle / (PI / 2)) + 1;
    my $seg_angle = $angle / $segments;

    my $a = $start;
    for (1 .. $segments) {
        my $a2 = $a + $seg_angle;
        my $alpha = 4.0 / 3.0 * (1 - cos($seg_angle / 2)) / sin($seg_angle / 2);

        my $x1 = $cx + $radius * cos($a);
        my $y1 = $cy + $radius * sin($a);
        my $x4 = $cx + $radius * cos($a2);
        my $y4 = $cy + $radius * sin($a2);

        my $cpx1 = $x1 - $alpha * $radius * sin($a);
        my $cpy1 = $y1 + $alpha * $radius * cos($a);
        my $cpx2 = $x4 + $alpha * $radius * sin($a2);
        my $cpy2 = $y4 - $alpha * $radius * cos($a2);

        $canvas->c($cpx1, $cpy1, $cpx2, $cpy2, $x4, $y4);
        $a = $a2;
    }

    $canvas->h->f->Q;

    return $self;
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Builder::Shape::Pie - Pie (arc wedge) shape for PDF::Make

=head1 SYNOPSIS

    $builder->add_shape(pie => {
        fill_colour => '#36f',
        x           => 200,
        y           => 300,
        r           => 80,
        rx          => 0,
        ry          => 90,
    });

=head1 DESCRIPTION

Draws a filled pie wedge (arc sector) on the current page canvas, useful for
pie charts.  The arc runs from angle C<rx> to C<ry> (in degrees).

=head1 PROPERTIES

=over 4

=item B<fill_colour> (Str, default C<'#000'>)

Fill colour as a hex string.

=item B<x> (Num, required)

Centre X coordinate.

=item B<y> (Num, required)

Centre Y coordinate (bottom-left origin).

=item B<r> (Num, required)

Radius in points.

=item B<rx> (Num, required)

Start angle in degrees.

=item B<ry> (Num, required)

End angle in degrees.

=back

=head1 METHODS

=over 4

=item B<add($builder)>

Renders the pie wedge onto the current page canvas.  Returns C<$self>.

=back

=head1 SEE ALSO

L<PDF::Make::Builder>, L<PDF::Make::Builder::Shape::Circle>

=cut
