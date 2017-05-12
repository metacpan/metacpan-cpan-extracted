package PDF::FromHTML::Template::Container::Always;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(PDF::FromHTML::Template::Container);

    use PDF::FromHTML::Template::Container;
}

sub enter_scope
{
    my $self = shift;
    my ($context) = @_;

    $self->SUPER::enter_scope($context);

    $self->{OLD_TRIP} = $context->pagebreak_tripped;
    $context->reset_pagebreak;

    return 1;
}

sub exit_scope
{
    my $self = shift;
    my ($context) = @_;

    $context->pagebreak_tripped($self->{OLD_TRIP});

    $self->reset;

    return $self->SUPER::exit_scope($context);
}

sub mark_as_rendered {}

1;
__END__

=head1 NAME

PDF::FromHTML::Template::Container::Always

=head1 PURPOSE

To require that any child of this node will always render on every page.
Normally, a node will not render on a given page if a node before it has
triggered a pagebreak. ALWAYS nodes will always render on every page.

Primarily, this is used as a base class for HEADER and FOOTER. However, you
might want something to always render on every page outside the header and
footer areas. For example, a watermark.

=head1 NODE NAME

ALWAYS

=head1 INHERITANCE

PDF::FromHTML::Template::Container

=head1 ATTRIBUTES

None

=head1 CHILDREN

PDF::FromHTML::Template::Container::Margin

PDF::FromHTML::Template::Container::Header
PDF::FromHTML::Template::Container::Footer

=head1 AFFECTS

Nothing

=head1 DEPENDENCIES

None

=head1 USAGE

  <always>
    ... Children will render on every page ...
  </always>

=head1 AUTHOR

Rob Kinyon (rkinyon@columbus.rr.com)

=head1 SEE ALSO

HEADER, FOOTER

=cut
