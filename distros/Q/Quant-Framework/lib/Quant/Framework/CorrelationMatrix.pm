package Quant::Framework::CorrelationMatrix;

=head1 NAME

Quant::Framework::CorrelationMatrix

=head1 DESCRIPTION

Correlations have an index, a currency, and duration that corresponds
to a correlation. An example of a correlation is SPC, AUD, 1M, with
a correlation of 0.42.

The values can be updated through backoffice's Quant Market Data page.

=cut

use Moose;
extends 'Quant::Framework::Utils::MarketData';

use namespace::autoclean;
use Math::Function::Interpolator;
use Date::Utility;

use Data::Chronicle::Reader;
use Data::Chronicle::Writer;

=head2 for_date

The date for which we wish data

=cut

has chronicle_reader => (
    is  => 'ro',
    isa => 'Data::Chronicle::Reader',
);

has chronicle_writer => (
    is  => 'ro',
    isa => 'Data::Chronicle::Writer',
);

has for_date => (
    is      => 'ro',
    isa     => 'Maybe[Date::Utility]',
    default => undef,
);

has document => (
    is         => 'rw',
    lazy_build => 1,
);

sub _build_document {
    my $self = shift;

    my $document = $self->chronicle_reader->get('correlation_matrices', $self->symbol);

    if ($self->for_date and $self->for_date->epoch < Date::Utility->new($document->{date})->epoch) {
        $document = $self->chronicle_reader->get_for('correlation_matrices', $self->symbol, $self->for_date->epoch);

        # This works around a problem with Volatility surfaces and negative dates to expiry.
        # We have to use the oldest available surface.. and we don't really know when it
        # was relative to where we are now.. so just say it's from the requested day.
        # We do not allow saving of historical surfaces, so this should be fine.
        $document //= {};
        $document->{date} = $self->for_date->datetime_iso8601;
    }

    return $document;
}

around _document_content => sub {
    my $orig = shift;
    my $self = shift;

    return {
        # symbol is not required
        date         => $self->recorded_date->datetime_iso8601,
        correlations => $self->correlations,
    };
};

=head3 C<< save >>

Saves the correlation matrix into Chronicle

=cut

sub save {
    my $self = shift;

    #if chronicle does not have this document, first create it because in document_content we will need it
    if (not defined $self->chronicle_reader->get('correlation_matrices', $self->symbol)) {
        $self->chronicle_writer->set('correlation_matrices', $self->symbol, {});
    }

    return $self->chronicle_writer->set('correlation_matrices', $self->symbol, $self->_document_content, $self->recorded_date);
}

has correlations => (
    is         => 'rw',
    isa        => 'HashRef',
    lazy_build => 1,
);

has _latest_correlations_reload => (
    is      => 'rw',
    isa     => 'Int',
    default => sub { time },
);

has reload_frequency => (
    is      => 'ro',
    isa     => 'Int',
    default => 20,
);

=head2 recorded_date

The date (and time) that the correlation matrix  was recorded, as a Date::Utility.

=cut

has recorded_date => (
    is         => 'ro',
    isa        => 'Date::Utility',
    lazy_build => 1,
);

sub _build_recorded_date {
    my $self = shift;
    return Date::Utility->new($self->document->{date});
}

# Instances of this class are able to auto-reload themselves to ensure
# that long-lived objects keep themselves up to date with change to the
# underlying data.
#
# This auto-reloading only occurs when the document is the
# live_document however, as if it is not, the instance is essentially
# representing a historical correlation matrix, which will never change.
#
# The correlations attr is a copy of the data->correlations HashRef as
# stored on the document. We reload the correlations attr if
# it has not changed from the original document value. If it
# has, we assume the user wishes to update the matrix, so we do not
# update (i.e. clear) the attr.
#
# We also assume that the user of the object will retrieve correlation
# data via the correlation attr.
before correlations => sub {
    my $self = shift;

    if ($self->_latest_correlations_reload + $self->reload_frequency < time) {
        $self->clear_correlations;
        $self->_latest_correlations_reload(time);
    }
};

sub _build_correlations {
    my $self = shift;

    return $self->document->{correlations};
}

=head3 C<< correlation_for >>

return correlation coefficient for given index, time-of-year and currency
You have to pass an instance of Quant::Framework::ExpiryConventions module
because it is needed in the calculations.

=cut

sub correlation_for {
    my ($self, $index, $payout_currency, $tiy, $expiry_conventions) = @_;

    # For synthetic, it will use the mapped underlying correlation
    if ($index =~ /^SYN(\w+)/) {
        $index = $1;
    }
    my $sought_expiry = $tiy * 365.0;
    my $data_points   = $self->correlations->{$index}->{$payout_currency};
    my $mapped_data;

    foreach my $tenor (keys %{$data_points}) {
        my $day = $expiry_conventions->vol_expiry_date({
                from => $self->recorded_date,
                term => $tenor,
            })->days_between($self->recorded_date);

        $mapped_data->{$day} = $data_points->{$tenor};
    }

    return ($sought_expiry) ? Math::Function::Interpolator->new(points => $mapped_data)->linear($sought_expiry) : 0;
}

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my @args = (scalar @_ == 1 and not ref $_[0]) ? {symbol => $_[0]} : @_;

    return $class->$orig(@args);
};

__PACKAGE__->meta->make_immutable;
1;
