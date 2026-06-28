package PDF::Make::Builder::Shape::Line;
use strict;
use warnings;
use Object::Proto;

BEGIN {
    Object::Proto::define('PDF::Make::Builder::Shape::Line',
        'fill_colour:Str:default(#000)',
        'x:Num', 'y:Num',
        'ex:Num', 'ey:Num',
        'type:Str:default(solid)',
        'dash:ArrayRef',
    );
    Object::Proto::import_accessors('PDF::Make::Builder::Shape::Line');
}

sub add {
    my ($self, $builder) = @_;
    my $page = $builder->page;
    my $canvas = $page->canvas;
    my $font = $builder->font;

    my $lx  = $self->x  // $page->content_x;
    my $lex = ex($self) // ($page->content_x + $page->width);
    my $ly  = $self->y;
    my $ley = ey($self);

    if (!defined $ly) {
        $ly = $page->cursor_y;
    }
    $ley = defined $ley ? $ley : $ly;

    my ($r, $g, $b) = $font->hex_to_rgb(fill_colour $self);

    $canvas->q->w(1)->RG($r, $g, $b);

    my $tp = type $self;
    my $d = dash $self;
    if ($d) {
        $canvas->d($d, 0);
    } elsif ($tp eq 'dashed') {
        $canvas->d([6, 3], 0);
    } elsif ($tp eq 'dots') {
        $canvas->J(1)->d([0, 4], 0);
    }

    $canvas->m($lx, $ly)->l($lex, $ley)->S->Q;

    # Advance cursor
    $page->advance_y(2);

    return $self;
}

1;

__END__

=encoding UTF-8

=head1 NAME

PDF::Make::Builder::Shape::Line - Line shape for PDF::Make

=head1 SYNOPSIS

    $builder->add_shape(line => {
        fill_colour => '#000',
        x           => 50,
        y           => 100,
        ex          => 500,
        ey          => 100,
        type        => 'dashed',
    });

=head1 DESCRIPTION

Draws a straight line between two points on the current page canvas.  Supports
solid, dashed, and dotted line styles.

=head1 PROPERTIES

=over 4

=item B<fill_colour> (Str, default C<'#000'>)

Stroke colour as a hex string.

=item B<x> (Num)

Start X coordinate.  Defaults to the content area's left edge.

=item B<y> (Num)

Start Y coordinate (bottom-left origin).  Defaults to the current cursor.

=item B<ex> (Num)

End X coordinate.  Defaults to the right edge of the content area.

=item B<ey> (Num)

End Y coordinate (bottom-left origin).  Defaults to the same as C<y>.

=item B<type> (Str, default C<'solid'>)

Line style: C<'solid'>, C<'dashed'>, or C<'dotted'>.

=item B<dash> (ArrayRef)

Custom dash pattern passed directly to the PDF dash operator.  Overrides
C<type> when set.

=back

=head1 METHODS

=over 4

=item B<add($builder)>

Renders the line onto the current page canvas.  Returns C<$self>.

=back

=head1 SEE ALSO

L<PDF::Make::Builder>, L<PDF::Make::Builder::Shape::Box>

=cut
