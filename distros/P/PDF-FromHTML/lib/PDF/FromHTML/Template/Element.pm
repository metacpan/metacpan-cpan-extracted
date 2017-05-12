package PDF::FromHTML::Template::Element;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(PDF::FromHTML::Template::Base);

    use PDF::FromHTML::Template::Base;
}

sub set_color
{
    my $self = shift;
    my ($context, $attr, $mode, $depth) = @_;

    my $color = $context->get($self, $attr, $depth);

    return 1 unless $color;

    my @colors = map { $_ / 255 } split /,\s*/, $color, 3;
    $context->{PDF}->color($mode, 'rgb', @colors);

    return 1;
}

1;
__END__

=head1 NAME

PDF::FromHTML::Template::Element

=head1 PURPOSE

To provide a base class for all rendering nodes.

=head1 COLORS

This is the class that handles colors. Colors in PDF::FromHTML::Template are specified in
RGB format, comma-separated. Each number is from 0 to 255, with 0 being none and
255 being most. If a color is not specified, 0 is assumed. Thus, "255,0,0",
"255,0", and "255" will all result in a red color.

Colors should be used for all attributes that have the word "COLOR" in the name.
This includes (but may not be limited to):

=over 4

=item * COLOR

=item * FILLCOLOR

=back

=head1 SEE ALSO

=cut
