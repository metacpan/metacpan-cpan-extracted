package PDF::FromHTML::Template::Container::Row;

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

    $context->{X} = $context->get($self, 'LEFT_MARGIN');

    return 1;
}

sub deltas
{
    my $self = shift;
    my ($context) = @_;

    return {
        X => $context->get($self, 'X') * -1 + $context->get($self, 'LEFT_MARGIN'),
        Y => -1 * $self->max_of($context, 'H'),
    };
}

sub total_of
{
    my $self = shift;
    my ($context, $attr) = @_;

    return $self->max_of($context, $attr) if $attr eq 'H';

    return $self->SUPER::total_of($context, $attr);
}

1;
__END__

=head1 NAME

PDF::FromHTML::Template::Container::Row

=head1 PURPOSE

To specify a row of text and provide typewriter-like carriage returns at the
end.

=head1 NODE NAME

ROW

=head1 INHERITANCE

PDF::FromHTML::Template::Container

=head1 ATTRIBUTES

=over 4

=item * H - the height the row will consume when it is done.

=item * LEFT_MARGIN - If specifed, the row will start rendering here. Otherwise,
it will default to the PAGEDEF's LEFT_MARGIN.

=back

=head1 CHILDREN

None

=head1 AFFECTS

TEXTBOX

=head1 DEPENDENCIES

None

=head1 USAGE

  <row h="8">
    <textbox w="50%" justify="right" text"Hello,"/>
    <textbox w="50%" justify="left" text"World"/>
  </row>

=head1 AUTHOR

Rob Kinyon (rkinyon@columbus.rr.com)

=head1 SEE ALSO

PAGEDEF, TEXTBOX

=cut
