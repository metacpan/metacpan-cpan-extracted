package Quant::Framework::Spot::Tick;

=head1 NAME

Quant::Framework::Spot::Tick

=head1 SYNOPSYS

    my $tick = Quant::Framework::Spot::Tick->new({
            symbol => 'frxRMBMNT',
            epoch  => 1340871449,
            bid    => 2.01,
            ask    => 2.03,
            quote  => 2.02,
    });

=head1 DESCRIPTION

This class represents tick data

=head1 ATTRIBUTES

=cut

use Moose;
use namespace::autoclean;

=head2 epoch

represent time in epoch of a tick

=cut

has 'epoch' => (
    is       => 'ro',
    required => 1,
);

=head2 symbol

underlying symbol

=cut

has 'symbol' => (
    is => 'ro',
);

=head2 quote

represents the quote price

=cut

has quote => (
    is       => 'rw',
    required => 1,
);

=head2 bid

represents the bid price

=head2 ask

represents the ask price

=cut

has [qw(bid ask)] => (
    is => 'rw',
);

=head1 METHIODS

=cut

=head2 $self->close

Returns quote, for backward compatibility

=cut

## no critic (ProhibitBuiltinHomonyms)
sub close { return shift->quote; }

=head2 $self->invert_values

Invert quote, ask, and bid values

=cut

sub invert_values {
    my $self = shift;

    $self->quote(1 / $self->quote);
    $self->bid(1 / $self->bid) if $self->bid;
    $self->ask(1 / $self->ask) if $self->ask;

    return $self;
}

=head2 $self->as_hash

Returns tick as a hash

=cut

sub as_hash {
    my $self = shift;

    return +{map { $_ => $self->$_ } grep { defined $self->$_ } qw(epoch quote symbol bid ask)};
}

__PACKAGE__->meta->make_immutable;

1;


