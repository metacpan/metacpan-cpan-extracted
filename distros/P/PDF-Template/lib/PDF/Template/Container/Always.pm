package PDF::Template::Container::Always;

use strict;

BEGIN {
    use vars qw(@ISA);
    @ISA = qw(PDF::Template::Container);

    use PDF::Template::Container;
}

sub enter_scope
{
    my $self = shift;
    my ($context) = @_;

    $self->{OLD_TRIP} = $context->pagebreak_tripped;
    $context->reset_pagebreak;

    return $self->SUPER::enter_scope($context);
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

PDF::Template::Container::Always

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

PDF::Template::Container

=head1 ATTRIBUTES

None

=head1 CHILDREN

PDF::Template::Container::Margin

PDF::Template::Container::Header
PDF::Template::Container::Footer

=head1 AFFECTS

Nothing

=head1 DEPENDENCIES

None

=head1 USAGE

  <always>
    ... Children will render on every page ...
  </always>

=head1 AUTHOR

Rob Kinyon (rob.kinyon@gmail.com)

=head1 SEE ALSO

HEADER, FOOTER

=cut
