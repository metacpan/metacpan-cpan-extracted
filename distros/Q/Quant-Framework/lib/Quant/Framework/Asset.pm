package Quant::Framework::Asset;

=head1 NAME

Quant::Framework::Asset

=head1 DESCRIPTION

This module saves/loads dividends data to/from Chronicle. 
To save dividends for a company:

my $corp_dividends = Quant::Framework::Asset->new(symbol => $symbol,
        rates => { 1 => 0, 2 => 1, 3=> 0.04 }
        discrete_points => { '2015-04-24' => 0, '2015-09-09' => 0.134 });
 $corp_dividends->save;

To read dividends information for a company:

 my $corp_dividends = Quant::Framework::Asset->new(symbol => $symbol);

 my $rates = $corp_dividends->rates;
 my $disc_points = $corp_dividends->discrete_points;

=cut

use Moose;
extends 'Quant::Framework::Utils::Rates';

use Data::Chronicle::Reader;
use Data::Chronicle::Writer;

=head2 underlying_config

Used for more advanced query of Dividen. For simple `rate_for` queries, 
this is not required.

=cut

has underlying_config => (
    is => 'ro',
);

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

has document => (
    is         => 'rw',
    lazy_build => 1,
);

sub _build_document {
    my $self = shift;

    my $document = $self->chronicle_reader->get('dividends', $self->symbol);

    if ($self->for_date and $self->for_date->epoch < Date::Utility->new($document->{date})->epoch) {
        $document = $self->chronicle_reader->get_for('dividends', $self->symbol, $self->for_date->epoch);

        $document //= {};
        $document->{date} = $self->for_date->datetime_iso8601;
    }

    return $document;
}
around _document_content => sub {
    my $orig = shift;
    my $self = shift;

    return {
        %{$self->$orig},
        rates           => $self->rates,
        discrete_points => $self->discrete_points,
        date            => $self->recorded_date->datetime_iso8601,
    };
};

=head2 save

Saves dividend data to the provided Chronicle storage

=cut

sub save {
    my $self = shift;

    #if chronicle does not have this document, first create it because in document_content we will need it
    if (not defined $self->chronicle_reader->get('dividends', $self->symbol)) {
        $self->chronicle_writer->set('dividends', $self->symbol, {});
    }

    return $self->chronicle_writer->set('dividends', $self->symbol, $self->_document_content, $self->recorded_date);
}

=head2 recorded_date

The date (and time) that the dividend  was recorded, as a Date::Utility.

=cut

has recorded_date => (
    is         => 'ro',
    isa        => 'Date::Utility',
    lazy_build => 1,
);

sub _build_recorded_date {
    my $self = shift;

    if (defined $self->document) {
        return Date::Utility->new($self->document->{date});
    }

    return Date::Utility->new(undef);
}

=head2 discrete_points

The discrete dividend points received from provider.

=cut

has discrete_points => (
    is         => 'ro',
    lazy_build => 1,
);

sub _build_discrete_points {
    my $self = shift;

    return if not defined $self->document;
    return $self->document->{discrete_points} || undef;
}

=head2 rate_for

Returns the rate for a particular timeinyears for symbol.
->rate_for(7/365)

=cut

sub rate_for {
    my ($self, $tiy) = @_;

    # Handle discrete dividend
    my ($nearest_yield_days_before, $nearest_yield_before) = (0, 0);
    my $days_to_expiry = $tiy * 365.0;
    my @sorted_expiries = sort { $a <=> $b } keys(%{$self->rates});
    foreach my $day (@sorted_expiries) {
        if ($day <= $days_to_expiry) {
            $nearest_yield_days_before = $day;
            $nearest_yield_before      = $self->rates->{$day};
            next;
        }
        last;
    }

    # Re-annualize
    my $discrete_points = $nearest_yield_before * $nearest_yield_days_before / 365;

    if ($days_to_expiry) {
        return $discrete_points * 365 / ($days_to_expiry * 100);
    }
    return 0;
}

=head2 dividend_rate_for

Get the dividend rate for this underlying over a given time period (expressed in timeinyears.)

=cut

sub dividend_rate_for {
    my ($self, $tiy) = @_;

    die 'Attempting to get dividend rate on an undefined asset symbol for ' . $self->underlying_config->symbol
        unless (defined $self->underlying_config->asset_symbol);

    return $self->underlying_config->default_dividend_rate if defined $self->underlying_config->default_dividend_rate;

    my $rate;

    # timeinyears cannot be undef
    $tiy ||= 0;
    my $type = $self->underlying_config->asset_class;

    my $which = $type eq 'currency' ? 'Quant::Framework::Currency' : 'Quant::Framework::Asset';

    my $asset = $which->new({
        symbol           => $self->underlying_config->asset_symbol,
        for_date         => $self->for_date,
        chronicle_reader => $self->chronicle_reader,
        chronicle_writer => $self->chronicle_writer,
    });

    if ($self->underlying_config->uses_implied_rate_for_asset) {
        $rate = $asset->rate_implied_from($self->underlying_config->rate_to_imply_from, $tiy);
    } else {
        $rate = $asset->rate_for($tiy);
    }

    return $rate;
}

=head2 get_discrete_dividend_for_period

Returns discrete dividend for the given (start,end) dates and dividend recorded date for the underlying specified using `underlying_config`

=cut

sub get_discrete_dividend_for_period {
    my ($self, $args) = @_;

    my ($start, $end) =
        map { Date::Utility->new($_) } @{$args}{'start', 'end'};

    my %valid_dividends;
    my $discrete_points        = $self->discrete_points;
    my $dividend_recorded_date = $self->recorded_date;

    if ($discrete_points and %$discrete_points) {
        my @sorted_dates =
            sort { $a->epoch <=> $b->epoch }
            map  { Date::Utility->new($_) } keys %$discrete_points;

        foreach my $dividend_date (@sorted_dates) {
            if (    not $dividend_date->is_before($start)
                and not $dividend_date->is_after($end))
            {
                my $date = $dividend_date->date_yyyymmdd;
                $valid_dividends{$date} = $discrete_points->{$date};
            }
        }
    }

    return ($dividend_recorded_date, \%valid_dividends);
}

=head2 dividend_adjustments_for_period

Returns dividend adjustments for given start/end period

=cut

sub dividend_adjustments_for_period {
    my ($self, $args) = @_;

    my ($dividend_recorded_date, $applicable_dividends) =
        ($self->underlying_config->market_prefer_discrete_dividend)
        ? $self->get_discrete_dividend_for_period($args)
        : {};

    my ($start, $end) = @{$args}{'start', 'end'};
    my $duration_in_sec = $end->epoch - $start->epoch;

    my ($dS, $dK) = (0, 0);
    foreach my $date (keys %$applicable_dividends) {
        my $adjustment           = $applicable_dividends->{$date};
        my $effective_date       = Date::Utility->new($date);
        my $sec_away_from_action = ($effective_date->epoch - $start->epoch);
        my $duration_in_year     = $sec_away_from_action / (86400 * 365);

        my $ir = Quant::Framework::InterestRate->new({
            symbol            => $self->symbol,
            underlying_config => $self->underlying_config,
            chronicle_reader  => $self->chronicle_reader,
            chronicle_writer  => $self->chronicle_writer
        });

        #TODO: rewrite this using an instance of InterestRate
        my $r_rate = $ir->interest_rate_for($duration_in_year);

        my $adj_present_value = $adjustment * exp(-$r_rate * $duration_in_year);
        my $s_adj = ($duration_in_sec - $sec_away_from_action) / ($duration_in_sec) * $adj_present_value;
        $dS -= $s_adj;
        my $k_adj = ($sec_away_from_action / ($duration_in_sec)) * $adj_present_value;
        $dK += $k_adj;
    }

    return {
        barrier       => $dK,
        spot          => $dS,
        recorded_date => $dividend_recorded_date,
    };
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
