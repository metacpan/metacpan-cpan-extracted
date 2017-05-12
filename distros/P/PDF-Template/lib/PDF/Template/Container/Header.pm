package PDF::Template::Container::Header;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(PDF::Template::Container::Margin);

    use PDF::Template::Container::Margin;
}

sub enter_scope
{
    my $self = shift;
    my ($context) = @_;

    @{$self}{qw/OLD_X OLD_Y/} = map { $context->get($self, $_) } qw(X Y);

    $context->{X} = 0;
    $context->{Y} = $context->get($self, 'PAGE_HEIGHT');

    return $self->SUPER::enter_scope($context);
}

1;
__END__

=head1 NAME

PDF::Template::Container::Header

=head1 PURPOSE

To provide header text and to specify where the header starts, for looping.

=head1 NODE NAME

HEADER

=head1 INHERITANCE

PDF::Template::Container::Margin

=head1 ATTRIBUTES

=over 4

=item * HEADER_HEIGHT - the amount reserved for the header from the bottom of
the page.

=back 4

=head1 CHILDREN

None

=head1 AFFECTS

Indicates to the PAGEDEF tag where all children may start rendering.

=head1 DEPENDENCIES

None

=head1 USAGE

  <pagedef>
    <header header_height="1i">
      ... Children here will render on every page ...
    </header>
    ... Stuff here ...
  </pagedef>

=head1 AUTHOR

Rob Kinyon (rob.kinyon@gmail.com)

=head1 SEE ALSO

ALWAYS, FOOTER, PAGEDEF

=cut
