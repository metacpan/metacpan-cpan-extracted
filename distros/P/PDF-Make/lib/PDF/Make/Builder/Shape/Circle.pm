package PDF::Make::Builder::Shape::Circle;
use strict;
use warnings;
use Object::Proto;

BEGIN {
    Object::Proto::define('PDF::Make::Builder::Shape::Circle',
        'fill_colour:Str:default(#000)',
        'x:Num:required',
        'y:Num:required',
        'r:Num:required',
    );
    Object::Proto::import_accessors('PDF::Make::Builder::Shape::Circle');
}

# Bezier control point ratio for circle approximation
use constant K => 0.5522847498;

sub add {
    my ($self, $builder) = @_;
    my $page = $builder->page;
    my $canvas = $page->canvas;
    my $font = $builder->font;

    my $cx = $self->x;
    my $cy = $self->y;
    my $radius = $self->r;
    my ($cr, $cg, $cb) = $font->hex_to_rgb(fill_colour $self);

    my $k = $radius * K;

    $canvas->q->rg($cr, $cg, $cb);

    # 4 cubic Bezier curves forming a circle
    $canvas->m($cx + $radius, $cy)
           ->c($cx + $radius, $cy + $k, $cx + $k, $cy + $radius, $cx, $cy + $radius)
           ->c($cx - $k, $cy + $radius, $cx - $radius, $cy + $k, $cx - $radius, $cy)
           ->c($cx - $radius, $cy - $k, $cx - $k, $cy - $radius, $cx, $cy - $radius)
           ->c($cx + $k, $cy - $radius, $cx + $radius, $cy - $k, $cx + $radius, $cy)
           ->f->Q;

    return $self;
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Builder::Shape::Circle - Filled circle for PDF::Make

=head1 SYNOPSIS

    $builder->add_shape(circle => {
        fill_colour => '#f00',
        x           => 200,
        y           => 300,
        r           => 50,
    });

=head1 DESCRIPTION

Draws a filled circle on the current page canvas using cubic Bezier curve
approximation.

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

=back

=head1 METHODS

=over 4

=item B<add($builder)>

Renders the circle onto the current page canvas.  Returns C<$self>.

=back

=head1 SEE ALSO

L<PDF::Make::Builder>, L<PDF::Make::Builder::Shape::Ellipse>

=cut
