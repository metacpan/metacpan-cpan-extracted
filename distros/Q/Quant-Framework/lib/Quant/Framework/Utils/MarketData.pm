package Quant::Framework::Utils::MarketData;

=head1 NAME

Quant::Framework::Utils::MarketData - Base class for market-data

=head1 SYNOPSYS


=head1 DESCRIPTION

=cut

use Moose;
use Quant::Framework::Utils::Types;

has symbol => (
    is       => 'ro',
    required => 1,
);

has recorded_date => (
    is         => 'ro',
    isa        => 'qf_date_object',
    coerce     => 1,
    lazy_build => 1,
);

sub _build_recorded_date {
    my $self = shift;
    return Date::Utility->new($self->document->{date});
}

has _document_content => (
    is         => 'ro',
    lazy_build => 1,
);

sub _build__document_content {
    my $self = shift;

    return {
        symbol => $self->symbol,
        date   => $self->recorded_date->datetime_iso8601,
    };
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
