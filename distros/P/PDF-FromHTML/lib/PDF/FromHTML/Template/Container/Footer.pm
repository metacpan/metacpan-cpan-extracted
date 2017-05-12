package PDF::FromHTML::Template::Container::Footer;

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

    $self->SUPER::enter_scope($context);

    @{$self}{qw/OLD_X OLD_Y/} = map { $context->get($self, $_) } qw(X Y);

    $context->{X} = 0;
    $context->{Y} = $context->get($self, 'FOOTER_HEIGHT');

    return 1;
}

1;
__END__

=head1 NAME

PDF::FromHTML::Template::Container::Footer

=head1 PURPOSE

To provide footer text and to specify where the footer starts, for looping.

=head1 NODE NAME

FOOTER

=head1 INHERITANCE

PDF::FromHTML::Template::Container::Margin

=head1 ATTRIBUTES

=over 4

=item * FOOTER_HEIGHT - the amount reserved for the footer from the bottom of
the page.

=back

=head1 CHILDREN

None

=head1 AFFECTS

Indicates to LOOP tags where to pagebreak.

=head1 DEPENDENCIES

None

=head1 USAGE

  <pagedef>
    ... Stuff here ...
    <footer footer_height="1i">
      ... Children here will render on every page ...
    </footer>
  </pagedef>

=head1 AUTHOR

Rob Kinyon (rkinyon@columbus.rr.com)

=head1 SEE ALSO

ALWAYS, HEADER, LOOP

=cut
