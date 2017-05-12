package PDF::Template::Element::HorizontalRule;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(PDF::Template::Element::Line);

    use PDF::Template::Element::Line;
}

sub deltas
{
    my $self = shift;
    my ($context) = @_;

    my $y_shift = $self->{Y2} - $self->{Y1};
    $y_shift = -1 * ($context->get($self, 'H') || 0) unless $y_shift;

    return {
        Y => $y_shift,
    };
}

1;
__END__

=head1 NAME

PDF::Template::Element::HorizontalRule

=head1 PURPOSE

To create a horizontal rule across the page

=head1 NODE NAME

HR

=head1 INHERITANCE

PDF::Template::Element::Line

=head1 ATTRIBUTES

=head1 CHILDREN

None

=head1 AFFECTS

Nothing

=head1 DEPENDENCIES

None

=head1 USAGE

  <hr/>

That will create a line across the page at the current Y-position.

=head1 AUTHOR

Rob Kinyon (rob.kinyon@gmail.com)

=head1 SEE ALSO

LINE

=cut
