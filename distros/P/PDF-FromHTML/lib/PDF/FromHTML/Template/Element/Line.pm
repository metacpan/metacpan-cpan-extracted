package PDF::FromHTML::Template::Element::Line;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(PDF::FromHTML::Template::Element);

    use PDF::FromHTML::Template::Element;
}

sub render
{
    my $self = shift;
    my ($context) = @_;

    return 0 unless $self->should_render($context);

    return 1 if $context->{CALC_LAST_PAGE};

    my $p = $context->{PDF};
    $p->save_state;

    $self->set_color($context, 'COLOR', 'both');

    my $vals = $self->make_vals($context);

    my $width = $context->get($self, 'WIDTH') || 1;

    $p->linewidth($width);
    $p->move($vals->{X1}, $vals->{Y1});
    $p->line($vals->{X2}, $vals->{Y2});
    $p->stroke;

    $p->restore_state;

    return 1;
}

sub make_vals
{
    my $self = shift;
    my ($context) = @_;

    my ($x1, $x2, $y1, $y2) = map { $context->get($self, $_) } qw(X1 X2 Y1 Y2);

    my %vals;
    unless (defined $x1 && defined $x2)
    {
#GGG Is the use of W a potential bug here?
        my ($pw, $left, $right, $w) = map {
            $context->get($self, $_)
        } qw( PAGE_WIDTH LEFT_MARGIN RIGHT_MARGIN W );

        $w = $pw - $right - $left unless defined $w;

        if (defined $x1)
        {
            $x2 = $x1 + $w;
            $x2 = $right if $x2 > $right;
        }
        elsif (defined $x2)
        {
            $x1 = $x2 - $w;
            $x1 = $left if $x1 < $left;
        }
        else
        {
            $x1 = $left;
            $x2 = $x1 + $w;
        }
    }
    @vals{qw(X1 X2)} = ($x1, $x2);

    unless (defined $y1 && defined $y2)
    {
        if (defined $y1)
        {
            $y2 = $y1;
        }
        elsif (defined $y2)
        {
            $y1 = $y2;
        }
        else
        {
            $y1 = $y2 = $context->get($self, 'Y');
        }
    }
    @vals{qw(Y1 Y2)} = ($y1, $y2);

    $self->{VALS} = \%vals;

    return \%vals;
}

1;
__END__

=head1 NAME

PDF::FromHTML::Template::Element::Line

=head1 PURPOSE

To draw lines

=head1 NODE NAME

LINE

=head1 INHERITANCE

PDF::FromHTML::Template::Element

=head1 ATTRIBUTES

=over 4

=item * X1 / X2 / Y1 / Y2
The line is drawn from (X1,Y1) to (X2,Y2).

If neither X1 nor X2 are set, X1 is set to the lefthand margin and X2 is set
to X1 + W. If only one is set, the other is set to the first +/- W.

If either of the Y values is not set, it is set to the current Y value.

=item * W
This is the width of the line to be drawn. Used only in calculating X1/X2/Y1/Y2
and only if needed. (q.v. above) Defaults to the distance between the left and
right margins. (q.v. PAGEDEF for more information on these parameters.)

=item * WIDTH
This is the thickness of the line to be drawn. Defaults to 1 pixel.

=item * COLOR
This is the color to draw the line in. Defaults to black.

=back

=head1 CHILDREN

PDF::FromHTML::Template::Element::HorizontalRule

=head1 AFFECTS

Nothing

=head1 DEPENDENCIES

None

=head1 USAGE

  <line X1="1i" Y1="1i" X2="3i" Y2="2i" WIDTH="3" COLOR="0,0,255"/>

This will draw a blue line 3 pixels thick from the spot 1" in from the left and
top to the spot 3" from the left and 2" from the top.

=head1 AUTHOR

Rob Kinyon (rkinyon@columbus.rr.com)

=head1 SEE ALSO

PAGEDEF, HR

=cut
