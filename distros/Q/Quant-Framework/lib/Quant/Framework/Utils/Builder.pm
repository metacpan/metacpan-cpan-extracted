package Quant::Framework::Utils::Builder;
use 5.010;

use strict;
use warnings;

use Moose;

use List::Util qw( min );
use Quant::Framework::TradingCalendar;
use Quant::Framework::InterestRate;
use Quant::Framework::Currency;
use Quant::Framework::Asset;
use Quant::Framework::ExpiryConventions;
use Quant::Framework::Spot;
use Quant::Framework::Spot::DatabaseAPI;
use Quant::Framework::Utils::UnderlyingConfig;

=head2 for_date

The date for which we wish data

=cut

has for_date => (
    is      => 'ro',
    isa     => 'Maybe[Date::Utility]',
    default => undef,
);

=head2 chronicle_reader

Instance of Data::Chronicle::Reader for reading data

=cut

has chronicle_reader => (
    is  => 'ro',
    isa => 'Data::Chronicle::Reader',
);

=head2 chronicle_writer

Instance of Data::Chronicle::Writer to write data to

=cut

has chronicle_writer => (
    is  => 'ro',
    isa => 'Data::Chronicle::Writer',
);

=head2 underlying_config

UnderlyingConfig used to create/initialize Q::F modules

=cut

has underlying_config => (
    is  => 'ro',
    isa => 'Quant::Framework::Utils::UnderlyingConfig',
);

=head2 build_expiry_conventions

Creates a default instance of ExpiryConventions according to current parameters (chronicle, for_date, underlying_config)

=cut

sub build_expiry_conventions {
    my $self = shift;

    my $quoted_currency = Quant::Framework::Currency->new({
        symbol           => $self->underlying_config->quoted_currency_symbol,
        for_date         => $self->for_date,
        chronicle_reader => $self->chronicle_reader,
        chronicle_writer => $self->chronicle_writer,
    });

    return Quant::Framework::ExpiryConventions->new({
        chronicle_reader => $self->chronicle_reader,
        is_forex_market  => $self->underlying_config->market_name eq 'forex',
        symbol           => $self->underlying_config->symbol,
        for_date         => $self->for_date,
        asset            => $self->build_asset,
        quoted_currency  => $quoted_currency,
        asset_symbol     => $self->underlying_config->asset_symbol,
        calendar         => $self->build_trading_calendar,
    });
}

=head2 build_trading_calendar

Creates a default instance of TradingCalendar according to current parameters (chronicle, for_date, underlying_config)

=cut

sub build_trading_calendar {
    my $self = shift;

    return Quant::Framework::TradingCalendar->new({
        symbol            => $self->underlying_config->exchange_name,
        chronicle_reader  => $self->chronicle_reader,
        for_date          => $self->for_date,
        underlying_config => $self->underlying_config,
    });
}

=head2 build_interest_rate

Creates an instance of InterestRate module using current configuration

=cut

sub build_interest_rate {
    my $self = shift;

    return Quant::Framework::InterestRate->new({
        symbol            => $self->underlying_config->symbol,
        underlying_config => $self->underlying_config,
        for_date          => $self->for_date,
        chronicle_reader  => $self->chronicle_reader,
        chronicle_writer  => $self->chronicle_writer,
    });
}

=head2 build_dividend

Creates a default instance of Dividend according to current parameters (chronicle, for_date, underlying_config)

=cut

sub build_dividend {
    my $self = shift;

    return Quant::Framework::Asset->new({
        symbol            => $self->underlying_config->symbol,
        underlying_config => $self->underlying_config,
        for_date          => $self->for_date,
        chronicle_reader  => $self->chronicle_reader,
        chronicle_writer  => $self->chronicle_writer,
    });
}

=head2 build_asset

Creates a default instance of Asset/Currency according to current parameters (chronicle, for_date, underlying_config)

=cut

sub build_asset {
    my $self = shift;

    return unless $self->underlying_config->asset_symbol;
    my $type = $self->underlying_config->asset_class;

    my $which = $type eq 'currency' ? 'Quant::Framework::Currency' : 'Quant::Framework::Asset';

    return $which->new({
        symbol           => $self->underlying_config->asset_symbol,
        for_date         => $self->for_date,
        chronicle_reader => $self->chronicle_reader,
        chronicle_writer => $self->chronicle_writer,
    });
}

=head2 build_currency

Creates a default instance of Currency according to current parameters (chronicle, for_date, underlying_config)

=cut

sub build_currency {
    my $self = shift;

    return Quant::Framework::Currency->new({
        symbol           => $self->underlying_config->asset_symbol,
        for_date         => $self->for_date,
        chronicle_reader => $self->chronicle_reader,
        chronicle_writer => $self->chronicle_writer,
    });
}

=head2 build_feed_api

Returns an instance of Quant::Framework::Spot::DatabaseAPI which can be used
to read historical spot values

=cut

sub build_feed_api {
    my $self = shift;

    return Quant::Framework::Spot::DatabaseAPI->new($self->underlying_config->spot_db_args);
}

=head2 build_spot

Returns an instance of Quant::Framework::Spot which can be used to read live or historical
spot

=cut

sub build_spot {
    my $self = shift;

    return Quant::Framework::Spot->new({
        for_date          => $self->for_date,
        underlying_config => $self->underlying_config,
        calendar          => $self->build_trading_calendar,
        feed_api          => $self->build_feed_api,
    });
}

1;
