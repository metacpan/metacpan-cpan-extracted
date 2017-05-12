package PDF::FromHTML::Template::Container::Header;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(PDF::FromHTML::Template::Container::Margin);

    use PDF::FromHTML::Template::Container::Margin;
}

sub enter_scope
{
    my $self = shift;
    my ($context) = @_;

    $self->SUPER::enter_scope( $context );

    @{$self}{qw/OLD_X OLD_Y/} = map { $context->get($self, $_) } qw(X Y);

    $context->{X} = 0;
    $context->{Y} = $context->get($self, 'PAGE_HEIGHT');

    return 1;
}

1;
__END__

=head1 NAME

PDF::FromHTML::Template::Container::Header

=head1 PURPOSE

To provide header text and to specify where the header starts, for looping.

=head1 NODE NAME

HEADER

=head1 INHERITANCE

PDF::FromHTML::Template::Container::Margin

=head1 ATTRIBUTES

=over 4

=item * HEADER_HEIGHT - the amount reserved for the header from the bottom of
the page.

=back

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

Rob Kinyon (rkinyon@columbus.rr.com)

=head1 SEE ALSO

ALWAYS, FOOTER, PAGEDEF

=cut
