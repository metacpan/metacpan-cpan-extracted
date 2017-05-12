package Quant::Framework::Spot::OHLC;

=head1 NAME

Quant::Framework::Spot::OHLC

=head1 SYNOPSYS

    my $ohlc = Quant::Framework::Spot::OHLC->new({
        epoch   => 1340871449,
        open    => 2.1,
        high    => 2.2,
        low     => 2.1,
        close   => 2.2,
    });

=head1 DESCRIPTION

This class represents OHLC data

=head1 ATTRIBUTES

=cut

use Moose;
use MooseX::StrictConstructor;
use namespace::autoclean;

=head2 epoch

represent starting time in epoch of the OHLC interval

=cut

has 'epoch' => (
    is       => 'ro',
    required => 1,
    isa      => 'Int',
);

=head2 open

represents the value of the underying at the open of the interval

=head2 high

represents the highest value of the underying in interval

=head2 low

represents the lowest value of the underying in interval

=head2 close

represents the value of the underying at the close of the interval

=cut

has [qw(open high low close)] => (
    is       => 'rw',
    required => 1,
    isa      => 'Num',
);

has 'official' => (
    is      => 'ro',
    isa     => 'Bool',
    default => undef,
);

=head2 invert_values

Invert values of OHL and C in-place.

=cut

sub invert_values {
    my $self = shift;

    my $high = $self->high;
    $self->open(1 / $self->open);
    $self->close(1 / $self->close);
    $self->high(1 / $self->low);
    $self->low(1 / $high);

    return $self;
}

__PACKAGE__->meta->make_immutable;

1;


