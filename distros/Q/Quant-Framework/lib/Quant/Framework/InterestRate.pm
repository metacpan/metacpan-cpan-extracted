package Quant::Framework::InterestRate;

use Data::Chronicle::Reader;
use Data::Chronicle::Writer;

=head1 NAME

Quant::Framework::InterestRate - A module to save/load interest rates for currencies

=head1 DESCRIPTION

This module saves/loads interest rate data to/from Chronicle. 

 my $ir_data = Quant::Framework::InterestRate->new(symbol => 'USD',
        rates => { 7 => 0.5, 30 => 1.2, 90 => 2.4 });
 $ir_data->save;

To read interest rates for a currency:

 my $ir_data = Quant::MarketData::InterestRate->new(symbol => 'USD');

 my $rates = $ir_data->rates;

=cut

use Moose;
extends 'Quant::Framework::Utils::Rates';

use Math::Function::Interpolator;

=head2 for_date

The date for which we wish data

=cut

has for_date => (
    is      => 'ro',
    isa     => 'Maybe[Date::Utility]',
    default => undef,
);

=head2 underlying_config

UnderlyingConfig used to create/initialize Q::F modules

=cut

has underlying_config => (
    is  => 'ro',
    isa => 'Quant::Framework::Utils::UnderlyingConfig',
);

around _document_content => sub {
    my $orig = shift;
    my $self = shift;

    return {
        %{$self->$orig},
        type  => $self->type,
        rates => $self->rates
    };
};

has chronicle_reader => (
    is  => 'ro',
    isa => 'Data::Chronicle::Reader',
);

has chronicle_writer => (
    is  => 'ro',
    isa => 'Data::Chronicle::Writer',
);

=head2 document

The document that this object is tied to.

=cut

has document => (
    is         => 'rw',
    lazy_build => 1,
);

sub _build_document {
    my $self = shift;

    my $document = $self->chronicle_reader->get('interest_rates', $self->symbol);

    if ($self->for_date and $self->for_date->epoch < Date::Utility->new($document->{date})->epoch) {
        $document = $self->chronicle_reader->get_for('interest_rates', $self->symbol, $self->for_date->epoch);

        #Assume empty data in case there is nothing in the database
        $document //= {};
    }

    return $document;
}

=head2 save

Save the document in the Chronicle data storage

=cut

sub save {
    my $self = shift;

    if (not defined $self->chronicle_reader->get('interest_rates', $self->symbol)) {
        $self->chronicle_writer->set('interest_rates', $self->symbol, {});
    }

    return $self->chronicle_writer->set('interest_rates', $self->symbol, $self->_document_content, $self->recorded_date);
}

has type => (
    is      => 'ro',
    isa     => 'qf_interest_rate_type',
    default => 'market',
);

=head2 interest_rate_for

Get the interest rate for this underlying over a given time period (expressed in timeinyears.)

=cut

sub interest_rate_for {
    my ($self, $tiy) = @_;

    # timeinyears cannot be undef
    $tiy ||= 0;

    return 0 unless $self->underlying_config->quoted_currency_symbol;

    my $quoted_currency = Quant::Framework::Currency->new({
        symbol           => $self->underlying_config->quoted_currency_symbol,
        for_date         => $self->for_date,
        chronicle_reader => $self->chronicle_reader,
        chronicle_writer => $self->chronicle_writer,
    });

    my $rate;
    if ($self->underlying_config->uses_implied_rate_for_quoted_currency) {
        $rate = $quoted_currency->rate_implied_from($self->underlying_config->rate_to_imply_from, $tiy);
    } else {
        $rate = $quoted_currency->rate_for($tiy);
    }

    return $rate;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
