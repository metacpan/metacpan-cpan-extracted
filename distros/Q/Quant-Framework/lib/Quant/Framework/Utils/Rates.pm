package Quant::Framework::Utils::Rates;

use Moose;
extends 'Quant::Framework::Utils::MarketData';

use Date::Utility;

has rates => (
    is         => 'ro',
    lazy_build => 1,
);

sub _build_rates {
    my $self = shift;

    die 'No rates found for ' . $self->symbol if not defined $self->document;

    my $result = $self->document->{rates};

    return $result;
}

=head2 rate_for

Returns the rate for a particular timeinyears for symbol.
->rate_for(7/365)

=cut

sub rate_for {
    my ($self, $tiy) = @_;

    die "No rates found for " . $self->symbol if not defined $self->rates;

    my $interp = Math::Function::Interpolator->new(points => $self->rates);
    return $interp->linear($tiy * 365) / 100;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
