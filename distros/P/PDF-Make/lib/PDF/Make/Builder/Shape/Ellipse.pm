package PDF::Make::Builder::Shape::Ellipse;
use strict;
use warnings;
use Object::Proto;

BEGIN {
    Object::Proto::define('PDF::Make::Builder::Shape::Ellipse',
        'fill_colour:Str:default(#000)',
        'x:Num:required',
        'y:Num:required',
        'w:Num:required',
        'h:Num:required',
    );
    Object::Proto::import_accessors('PDF::Make::Builder::Shape::Ellipse');
}

use constant K => 0.5522847498;

sub add {
    my ($self, $builder) = @_;
    my $page = $builder->page;
    my $canvas = $page->canvas;
    my $font = $builder->font;

    my $cx = $self->x;
    my $cy = $self->y;
    my $rx = ($self->w) / 2;
    my $ry = ($self->h) / 2;
    my ($cr, $cg, $cb) = $font->hex_to_rgb(fill_colour $self);

    my $kx = $rx * K;
    my $ky = $ry * K;

    $canvas->q->rg($cr, $cg, $cb);

    $canvas->m($cx + $rx, $cy)
           ->c($cx + $rx, $cy + $ky, $cx + $kx, $cy + $ry, $cx, $cy + $ry)
           ->c($cx - $kx, $cy + $ry, $cx - $rx, $cy + $ky, $cx - $rx, $cy)
           ->c($cx - $rx, $cy - $ky, $cx - $kx, $cy - $ry, $cx, $cy - $ry)
           ->c($cx + $kx, $cy - $ry, $cx + $rx, $cy - $ky, $cx + $rx, $cy)
           ->f->Q;

    return $self;
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Builder::Shape::Ellipse - Filled ellipse for PDF::Make

=head1 SYNOPSIS

    $builder->add_shape(ellipse => {
        fill_colour => '#0a0',
        x           => 200,
        y           => 300,
        w           => 120,
        h           => 80,
    });

=head1 DESCRIPTION

Draws a filled ellipse on the current page canvas using cubic Bezier curve
approximation.

=head1 PROPERTIES

=over 4

=item B<fill_colour> (Str, default C<'#000'>)

Fill colour as a hex string.

=item B<x> (Num, required)

Centre X coordinate.

=item B<y> (Num, required)

Centre Y coordinate (bottom-left origin).

=item B<w> (Num, required)

Full width of the ellipse (diameter along the X axis).

=item B<h> (Num, required)

Full height of the ellipse (diameter along the Y axis).

=back

=head1 METHODS

=over 4

=item B<add($builder)>

Renders the ellipse onto the current page canvas.  Returns C<$self>.

=back

=head1 SEE ALSO

L<PDF::Make::Builder>, L<PDF::Make::Builder::Shape::Circle>

=cut
