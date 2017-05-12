package Quant::Framework::Spot;

use 5.006;
use strict;
use warnings;

use Moose;
use Scalar::Util qw( looks_like_number );
use Cache::RedisDB;
use Quant::Framework::Spot::Tick;
use Quant::Framework::Spot::DatabaseAPI;

=head1 NAME

Quant::Framework::Spot - Used to store/retrieve spot prices into/from local Redis storage

=cut

has for_date => (
    is => 'ro',
);

has underlying_config => (
    is       => 'ro',
    required => 1,
);

has calendar => (
    is => 'ro',
);

has feed_api => (
    is => 'ro',
);

has default_redis_key => (
    is      => 'ro',
    default => 'QUOTE',
);

=head1 SYNOPSIS

Used to store/retrieve spot prices into/from local Redis storage
You will need to provide the module with a code reference which will be used
in exception cases where local redis is empty and a request to read spot price
is received. In this case, module will use the given code references to fetch
spot price from a secondary storage (this can be a database).
If you omit for_date parameter, you will fetch latest spot price.

    use Quant::Framework::Spot;

    my $foo = Quant::Framework::Spot->new({
        symbol => 'GDAXI',
        for_date => Date::Utility->new('2016-09-11 12:29:10')
    });

    ...

=head1 SUBROUTINES/METHODS

=head2 $self->spot_tick

Get last tick value for symbol from Redis or feed database. It will rebuild value from
feed db if it is not present in cache.

This method will fall back to database if no data is found in Redis cache. In this case,
Redis will be populated with the data read from db.

=cut

sub spot_tick {
    my $self = shift;

    return $self->tick_at($self->for_date->epoch, {allow_inconsistent => 1}) if $self->for_date;

    my $value = Cache::RedisDB->get($self->default_redis_key, $self->underlying_config->symbol);
    my $tick;
    if ($value) {
        $tick = Quant::Framework::Spot::Tick->new($value);
    } else {
        $tick = $self->tick_at(time, {allow_inconsistent => 1});
        if ($tick) {
            $self->set_spot_tick($tick);
        }
    }

    return $tick;
}

=head2 spot_tick_hash      

 Returns a hash reference denoting available fields in the spot_tick       

=cut      

sub spot_tick_hash {
    my $self = shift;

    my $tick = $self->spot_tick;

    return ($tick) ? $tick->as_hash : undef;
}

=head2 tick_at

This method receives a timestamp and an option for inconsistency.
Returns the tick for current symbol at the given time. If inconssitency is enabled
and there is no tick at that moment, the latest tick before that time is 
returned.
`allow_inconsistent` parameters determines how the case should be handled when there is no tick at the 
exact requested timestamp. If value of this parameter is `1`, then the code will return tick at or before the given timestamp.
If it is passed as `0`, the code will return any tick at or after given timestamp.

=cut

sub tick_at {
    my ($self, $timestamp, $allow_inconsistent_hash) = @_;

    my $inconsistent_price;
    # get official close for previous trading day
    if (defined $allow_inconsistent_hash->{allow_inconsistent}
        and $allow_inconsistent_hash->{allow_inconsistent} == 1)
    {
        $inconsistent_price = 1;
    }

    my $pricing_date = Date::Utility->new($timestamp);
    my $tick;

    if ($self->underlying_config->use_official_ohlc
        and not $self->calendar->trades_on($pricing_date))
    {
        my $last_trading_day = $self->calendar->trade_date_before($pricing_date);
        $tick = $self->closing_tick_on($last_trading_day->date_ddmmmyy);
    } else {
        my $request_hash = {};
        $request_hash->{end_time} = $timestamp;
        $request_hash->{allow_inconsistent} = 1 if ($inconsistent_price);

        $tick = $self->feed_api->tick_at($request_hash);
    }

    return $tick;
}

=head2 closing_tick_on

Get the market closing tick for a given date.

Example : $underlying->closing_tick_on("10-Jan-00");

=cut

sub closing_tick_on {
    my ($self, $date) = @_;

    die 'must pass in a date for closing_tick_on' unless $date;
    $date = Date::Utility->new($date);

    my $closing = $self->calendar->closing_on($date);
    if (not $closing or time <= $closing->epoch) {
        ##no critic (ProhibitExplicitReturnUndef)
        return undef;
    }

    my $ohlc = $self->feed_api->ohlc_start_end({
        start_time         => $date,
        end_time           => $date,
        aggregation_period => 86400,
    });

    if (@$ohlc > 0) {
        # We need a tick, but we can only get an OHLC
        # The epochs for these are set to be the START of the period.
        # So we also need to change it to the closing time. Meh.
        my $not_tick = $ohlc->[0];
        return Quant::Framework::Spot::Tick->new({
            symbol => $self->underlying_config->symbol,
            epoch  => $closing->epoch,
            quote  => $not_tick->close,
        });
    }

    ##no critic (ProhibitExplicitReturnUndef)
    return undef;
}

=head2 $self->set_spot_tick($value)

Save last tick value for symbol in Redis. Returns true if operation was
successfull, false overwise. Tick value should be a hash reference like this:

{
    epoch => $unix_timestamp,
    quote => $last_price,
}

You will need to provide the module with a code reference which will be used
in exception cases where local redis is empty and a request to read spot price
is received. In this case, module will use the given code references to fetch
spot price from a secondary storage (this can be a database).

=cut

sub set_spot_tick {
    my ($self, $value) = @_;

    my $tick;
    if (ref $value eq 'Quant::Framework::Spot::Tick') {
        $tick  = $value;
        $value = $value->as_hash;
    } else {
        $tick = Quant::Framework::Spot::Tick->new($value);
    }
    Cache::RedisDB->set_nw($self->default_redis_key, $self->underlying_config->symbol, $value);
    return $tick;
}

=head2 spot_quote

What is the current spot price for this underlying?

=cut

sub spot_quote {
    my $self = shift;
    my $last_price;

    my $last_tick = $self->spot_tick;
    $last_price = $last_tick->quote if $last_tick;

    return $last_price;
}

=head2 spot_time

The epoch timestamp of the latest recorded tick in the system

=cut

sub spot_time {
    my $self      = shift;
    my $last_tick = $self->spot_tick;
    return $last_tick && $last_tick->epoch;
}

=head2 spot_age

The age in seconds of the latest tick

=cut

sub spot_age {
    my $self      = shift;
    my $tick_time = $self->spot_time;
    return defined $tick_time && time - $tick_time;
}

1;    # End of Quant::Framework::Spot
