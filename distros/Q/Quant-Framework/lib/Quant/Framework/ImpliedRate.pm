package Quant::Framework::ImpliedRate;

use Data::Chronicle::Reader;
use Data::Chronicle::Writer;

=head1 NAME

Quant::Framework::ImpliedRate - A module to save/load implied interest rates for currencies

=head1 DESCRIPTION

This module saves/loads implied interest rate data to/from Chronicle. 

 my $ir_data = Quant::Framework::ImpliedRate->new(symbol => 'USD-EUR',
        rates => { 7 => 0.5, 30 => 1.2, 90 => 2.4 });
 $ir_data->save;

To read implied interest rates for a currency:

 my $ir_data = Quant::Framework::ImpliedRate->new(symbol => 'USD-EUR');

 my $rates = $ir_data->rates;

=cut

use Moose;
extends 'Quant::Framework::Utils::Rates';

=head2 for_date

The date for which we wish data

=cut

has for_date => (
    is      => 'ro',
    isa     => 'Maybe[Date::Utility]',
    default => undef,
);

has chronicle_reader => (
    is  => 'ro',
    isa => 'Data::Chronicle::Reader',
);

has chronicle_writer => (
    is  => 'ro',
    isa => 'Data::Chronicle::Writer',
);

around _document_content => sub {
    my $orig = shift;
    my $self = shift;

    my @symbols = split '-', $self->symbol;

    return {
        %{$self->$orig},
        rates => $self->rates,
        type  => $self->type,
        info  => $symbols[0] . ' rates implied from ' . $symbols[1],
    };
};

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

Save the document into Chronicle data-store

=cut

sub save {
    my $self = shift;

    if (not defined $self->chronicle_reader->get('interest_rates', $self->symbol)) {
        $self->chronicle_writer->set('interest_rates', $self->symbol, {});
    }

    return $self->chronicle_writer->set('interest_rates', $self->symbol, $self->_document_content);
}

has type => (
    is      => 'ro',
    isa     => 'qf_interest_rate_type',
    default => 'implied',
);

no Moose;
__PACKAGE__->meta->make_immutable;
1;
