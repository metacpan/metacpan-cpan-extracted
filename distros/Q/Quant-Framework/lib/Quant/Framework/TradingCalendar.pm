package Quant::Framework::TradingCalendar;

=head1 NAME

Quant::Framework::TradingCalendar

=head1 DESCRIPTION

This module is responsible about everything related to time-based status of an exchange (whether exchange is open/closed, has holiday, is partially open, ...)
Plus all related helper modules (trading days between two days where exchange is open, trading breaks, DST effect, open/close time, ...).
One important feature of this module is that it is designed for READING information not writing.

=cut

=head1 USAGE

    my $calendar = Quant::Framework::TradingCalendar->new({
        symbol => 'LSE',
        chronicle_reader => $chronicle_r,
    });

=cut

use strict;
use warnings;
use feature 'state';

use Moose;
use DateTime;
use DateTime::TimeZone;
use List::Util qw(min max);
use Memoize;
use Carp;
use Scalar::Util qw(looks_like_number);
use File::ShareDir ();
use Data::Chronicle::Reader;

use Quant::Framework::Holiday;
use Quant::Framework::PartialTrading;
use Date::Utility;
use Memoize::HashKey::Ignore;
use Time::Duration::Concise;
use YAML::XS qw(LoadFile);
use Clone qw(clone);

# We're going to do this from time to time.
# I claim it's under control.
## no critic(TestingAndDebugging::ProhibitNoWarnings)
no warnings 'recursion';

=head1 ATTRIBUTES

=head2 symbol

The standard symbol used to reference this exchange

=cut

has symbol => (
    is  => 'ro',
    isa => 'Str',
);

=head2 underlying_config

UnderlyingConfig used for query on weighting of an underlying. Not required if this modules is not used for
that purpose.

=cut

has underlying_config => (
    is  => 'ro',
    isa => 'Quant::Framework::Utils::UnderlyingConfig',
);

=head2 chronicle_reader

Used to work with Chronicle storage data (Holidays and Partial trading data)

=cut

has chronicle_reader => (
    is  => 'ro',
    isa => 'Data::Chronicle::Reader',
);

=head2 for_date

for_date is to for historical search of holiday information

=cut

has for_date => (
    is => 'ro',
);

=head2 holidays

The hashref mapping of the days_since_epoch of all the holidays to their
descriptions or weights. If the weight is non-zero, the exchange still trades on
that day.

=cut

has holidays => (
    is         => 'ro',
    lazy_build => 1,
);

sub _build_holidays {
    my $self = shift;

    my $ref = Quant::Framework::Holiday::get_holidays_for($self->chronicle_reader, $self->symbol, $self->for_date);
    my %exchange_holidays = map { Date::Utility->new($_)->days_since_epoch => $ref->{$_} } keys %$ref;

    return \%exchange_holidays;
}

=head2 pseudo_holidays

These are holidays defined by us. During this period, market is still open but less volatile.

=cut

has pseudo_holidays => (
    is      => 'ro',
    lazy    => 1,
    builder => '_build_pseudo_holidays',
);

sub _build_pseudo_holidays {
    my $self = shift;

    # pseudo-holidays for exchanges are 1 week before and after Christmas Day.
    my $year            = $self->for_date ? $self->for_date->year : Date::Utility->new->year;
    my $christmas_day   = Date::Utility->new('25-Dec-' . $year);
    my $pseudo_start    = $christmas_day->minus_time_interval('7d');
    my %pseudo_holidays = map { $pseudo_start->plus_time_interval($_ . 'd')->days_since_epoch => 'pseudo-holiday' } (0 .. 14);

    return \%pseudo_holidays;
}

has [qw(early_closes late_opens)] => (
    is         => 'ro',
    lazy_build => 1,
);

sub _build_early_closes {
    my $self = shift;

    my $ref = Quant::Framework::PartialTrading->new({
            chronicle_reader => $self->chronicle_reader,
            type             => 'early_closes'
        })->get_partial_trading_for($self->symbol, $self->for_date);
    my %early_closes = map { Date::Utility->new($_)->days_since_epoch => $ref->{$_} } keys %$ref;

    return \%early_closes;
}

sub _build_late_opens {
    my $self = shift;

    my $ref = Quant::Framework::PartialTrading->new({
            chronicle_reader => $self->chronicle_reader,
            type             => 'late_opens'
        })->get_partial_trading_for($self->symbol, $self->for_date);
    my %late_opens = map { Date::Utility->new($_)->days_since_epoch => $ref->{$_} } keys %$ref;

    return \%late_opens;
}

## attribute market_times
#
# A hashref of human-readable times, which are converted to epochs for a given day
#
has market_times => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { return {}; },
);

has is_affected_by_dst => (
    is         => 'ro',
    isa        => 'Bool',
    lazy_build => 1,
);

=head2 trading_days

An exchange's trading day category. The list is enumerated in the exchanges_trading_days_aliases.yml file.

=cut

has trading_days => (
    is      => 'ro',
    default => 'weekdays',
);

=head2 trading_days_list

List the trading day index which defined on exchanges_trading_days_aliases.yml

=cut

has trading_days_list => (
    is         => 'ro',
    isa        => 'ArrayRef',
    lazy_build => 1,
);

my $trading_days_aliases;

BEGIN {
    $trading_days_aliases = YAML::XS::LoadFile(File::ShareDir::dist_file('Quant-Framework', 'exchanges_trading_days_aliases.yml'));
}

sub _build_trading_days_list {

    my $self = shift;
    return \@{$trading_days_aliases->{$self->trading_days}};

}

=head2 trading_timezone


The timezone in which the exchange conducts business.

This should be a string which will allow the standard DateTime modules to find the proper information.

=cut

has [qw(trading_timezone)] => (
    is  => 'ro',
    isa => 'Maybe[Str]',
);

=head2 BUILDARGS

Internal method to pre-process construction arguments

=cut

my $exchanges;

BEGIN {
    $exchanges = YAML::XS::LoadFile(File::ShareDir::dist_file('Quant-Framework', 'exchange.yml'));
}

sub BUILDARGS {
    my ($class, $orig_params_ref) = @_;

    my $symbol = $orig_params_ref->{symbol};

    croak "Exchange symbol must be specified" unless $symbol;
    my $params_ref = clone($exchanges->{$symbol});
    $params_ref = {%$params_ref, %$orig_params_ref};

    foreach my $key (keys %{$params_ref->{market_times}}) {
        foreach my $trading_segment (keys %{$params_ref->{market_times}->{$key}}) {
            if ($trading_segment eq 'day_of_week_extended_trading_breaks') { next; }
            elsif ($trading_segment ne 'trading_breaks') {
                $params_ref->{market_times}->{$key}->{$trading_segment} = Time::Duration::Concise::Localize->new(
                    interval => $params_ref->{market_times}->{$key}->{$trading_segment},
                );
            } else {
                my $break_intervals = $params_ref->{market_times}->{$key}->{$trading_segment};
                my @converted;
                foreach my $int (@$break_intervals) {
                    my $open_int = Time::Duration::Concise::Localize->new(
                        interval => $int->[0],
                    );
                    my $close_int = Time::Duration::Concise::Localize->new(
                        interval => $int->[1],
                    );
                    push @converted, [$open_int, $close_int];
                }
                $params_ref->{market_times}->{$key}->{$trading_segment} = \@converted;
            }
        }
    }

    return $params_ref;
}

=head2 simple_weight_on

Returns the weight assigned to the day of a given Date::Utility object. Return 0
if the exchange does not trade on this day and 1 if there is no pseudo-holiday.

=cut

sub simple_weight_on {
    my ($self, $when) = @_;

    return 0   if not $self->trades_on($when);
    return 0.5 if exists $self->pseudo_holidays->{$when->days_since_epoch};
    return 1;
}

=head2 has_holiday_on

Returns true if the exchange has a holiday on the day of a given Date::Utility
object.

=cut

sub has_holiday_on {
    my ($self, $when) = @_;

    return $self->holidays->{$when->days_since_epoch};
}

=head2 trades_on

Returns true if trading is done on the day of a given Date::Utility.

=cut

sub trades_on {
    my ($self, $when) = @_;

    my $really_when = $self->trading_date_for($when);
    my $symbol      = $self->symbol;
    my $result      = (@{$self->trading_days_list}[$really_when->day_of_week] && !$self->has_holiday_on($really_when)) ? 1 : 0;

    return $result;
}

=head2 trade_date_after

Returns a Date::Utility for the date on which trading is open after the given Date::Utility

=cut

sub trade_date_after {
    my ($self, $when) = @_;

    my $date_next;
    my $counter = 1;
    my $begin   = $self->trading_date_for($when);

    while (not $date_next and $counter <= 15) {
        my $possible = $begin->plus_time_interval($counter . 'd');
        $date_next = ($self->trades_on($possible)) ? $possible : undef;
        $counter++;
    }

    return $date_next;
}

=head2 trading_date_for

The date on which trading is considered to be taking place even if it is not the same as the GMT date.

Returns a Date object representing midnight GMT of the trading date.

Note that this does not handle trading dates are offset forward beyond the next day (24h). It will need additional work if these are found to exist.

=cut

sub trading_date_for {
    my ($self, $date) = @_;

    return $date->truncate_to_day unless ($self->trading_date_can_differ);

    my $next_day = $date->plus_time_interval('1d')->truncate_to_day;
    my $open_ti =
        $self->market_times->{$self->_times_dst_key($next_day)}->{daily_open};

    return ($open_ti and $next_day->epoch + $open_ti->seconds <= $date->epoch)
        ? $next_day
        : $date->truncate_to_day;

}

has trading_date_can_differ => (
    is         => 'ro',
    isa        => 'Bool',
    lazy_build => 1,
    init_arg   => undef,
);

# This presumes we only ever move on the open side, never past the end of a day.
sub _build_trading_date_can_differ {
    my $self = shift;
    my @premidnight_opens =
        grep { $_->seconds < 0 }
        map  { $self->market_times->{$_}->{daily_open} }
        grep { exists $self->market_times->{$_}->{daily_open} }
        keys %{$self->market_times};
    return (scalar @premidnight_opens) ? 1 : 0;
}

=head2 calendar_days_to_trade_date_after

Returns the number of calendar days between a given Date::Utility
and the next day on which trading is open.

=cut

sub calendar_days_to_trade_date_after {
    my ($self, $when) = @_;

    return $self->trade_date_after($when)->days_between($when);
}
Memoize::memoize('calendar_days_to_trade_date_after', NORMALIZER => '_normalize_on_dates');

=head2 trade_date_before

Returns a Date::Utility representing the trading day before a given Date::Utility

If given the additional arg 'lookback', will look back X number of
trading days, rather than just one.

=cut

sub trade_date_before {
    my ($self, $when, $additional_args) = @_;

    my $begin = $self->trading_date_for($when);
    my $lookback = (ref $additional_args) ? $additional_args->{'lookback'} : 1;

    my $date_behind;
    my $counter = 0;

    while (not $date_behind and $counter < 15) {
        my $possible = $begin->minus_time_interval(($lookback + $counter) . 'd');
        $date_behind =
            ($self->trades_on($possible) and $self->trading_days_between($possible, $when) == $lookback - 1) ? $possible : undef;
        $counter++;
    }

    return $date_behind;
}

sub _days_between {

    my ($self, $begin, $end) = @_;

    my @days_between = ();

    # Don't include start and end days.
    my $current = $begin->truncate_to_day->plus_time_interval('1d');
    $end = $end->truncate_to_day->minus_time_interval('1d');

    # Generate all days between.
    while (not $current->is_after($end)) {
        push @days_between, $current;
        $current = $current->plus_time_interval('1d');    # Next day, please!
    }

    return \@days_between;
}
Memoize::memoize('_days_between', NORMALIZER => '_normalize_on_dates');

=head2 trading_days_between

Returns the number of trading days _between_ two given dates.

    $exchange->trading_days_between(Date::Utility->new('4-May-10'),Date::Utility->new('5-May-10'));

=cut

sub trading_days_between {
    my ($self, $begin, $end) = @_;

    # Count up how many are trading days.
    return scalar grep { $self->trades_on($_) } @{$self->_days_between($begin, $end)};
}
Memoize::memoize('trading_days_between', NORMALIZER => '_normalize_on_dates');

=head2 holiday_days_between

Returns the number of holidays _between_ two given dates.

    $exchange->trading_days_between(Date::Utility->new('4-May-10'),Date::Utility->new('5-May-10'));

=cut

sub holiday_days_between {
    my ($self, $begin, $end) = @_;

    # Count up how many are trading days.
    return scalar grep { $self->has_holiday_on($_) } @{$self->_days_between($begin, $end)};
}
Memoize::memoize('holiday_days_between', NORMALIZER => '_normalize_on_dates');

=head1 OPEN/CLOSED QUESTIONS ETC.

Quant::Framework::TradingCalendar can be questioned about various things related to opening/closing.
The following shows all these questions via code examples:

=head2 is_open

    if ($self->is_open)

=cut

sub is_open {
    my $self = shift;
    return $self->is_open_at(time);
}

=head2 is_open_at

    if ($self->is_open_at($epoch))

=cut

sub is_open_at {
    my ($self, $when) = @_;

    my $open;
    my $date = (ref $when) ? $when : Date::Utility->new($when);
    if (my $opening = $self->opening_on($date)) {
        $open = 1
            if (not $date->is_before($opening)
            and not $date->is_after($self->closing_on($date)));
        if ($self->is_in_trading_break($date)) {
            $open = undef;
        }
    }

    return $open;
}

=head2 will_open

    if ($self->will_open)

=cut

sub will_open {
    my $self = shift;
    return $self->will_open_after(time);
}

=head2 will_open_after

    if ($self->will_open_after($epoch))

=cut

sub will_open_after {
    my ($self, $epoch) = @_;

    # basically, if open is "0", but not undef. Annoying _market_opens logic
    if (defined $self->_market_opens($epoch)->{'open'}
        and not $self->_market_opens($epoch)->{'open'})
    {
        return 1;
    }
    return;
}

=head2 seconds_since_open_at

    my $seconds = $self->seconds_since_open_at($epoch);

=cut

sub seconds_since_open_at {
    my ($self, $epoch) = @_;
    return $self->_market_opens($epoch)->{'opened'};
}

=head2 seconds_since_close_at

    my $seconds = $self->seconds_since_close_at($epoch);

=cut

sub seconds_since_close_at {
    my ($self, $epoch) = @_;
    return $self->_market_opens($epoch)->{'closed'};
}

## PRIVATE _market_opens
#
# PARAMETERS :
# - time   : the time as a timestamp
#
# RETURNS    : A reference to a hash with the following keys:
# - open   : is set to 1 if the market is currently open, 0 if market is closed
#            but will open, 'undef' if market is closed and will not open again
#            today.
# - closed : undefined if market has not been open yet, otherwise contains the
#            seconds for how long the market was closed.
# - opens  : undefined if market is currently open and does not open anymore today,
#            otherwise the market will open in 'opens' seconds.
# - closes : undefined if open is undef, otherwise market will close in 'closes' seconds.
# - opened : undefined if market is closed, contains the seconds the market has
#            been open.
#
#
########
sub _market_opens {
    my ($self, $time) = @_;

    # Date::Utility should handle this, but let's not bother;
    my $when = (ref $time) ? $time : Date::Utility->new($time);
    my $date = $when;

    # Figure out which "trading day" we are on
    # even if it differs from the GMT calendar day.
    my $next_day  = $date->plus_time_interval('1d')->truncate_to_day;
    my $next_open = $self->opening_on($next_day);
    $date = $next_day if ($next_open and not $date->is_before($next_open));

    my $open  = $self->opening_on($date);
    my $close = $self->closing_on($date);

    if (not $open) {

        # date is not a trading day: will not and has not been open today
        my $next_open = $self->opening_on($self->trade_date_after($when));
        return {
            open   => undef,
            opens  => $next_open->epoch - $when->epoch,
            opened => undef,
            closes => undef,
            closed => undef,
        };
    }

    my $breaks = $self->trading_breaks($when);
    # not trading breaks
    if (not $breaks) {
        # Past closing time: opens next trading day, and has been open today
        if ($close and not $when->is_before($close)) {
            return {
                open   => undef,
                opens  => undef,
                opened => $when->epoch - $open->epoch,
                closes => undef,
                closed => $when->epoch - $close->epoch,
            };
        } elsif ($when->is_before($open)) {
            return {
                open   => 0,
                opens  => $open->epoch - $when->epoch,
                opened => undef,
                closes => $close->epoch - $when->epoch,
                closed => undef,
            };
        } elsif ($when->is_same_as($open) or ($when->is_after($open) and $when->is_before($close)) or $when->is_same_same($close)) {
            return {
                open   => 1,
                opens  => undef,
                opened => $when->epoch - $open->epoch,
                closes => $close->epoch - $when->epoch,
                closed => undef,
            };
        }
    } else {
        my @breaks = @$breaks;
        # Past closing time: opens next trading day, and has been open today
        if ($close and not $when->is_before($close)) {
            return {
                open   => undef,
                opens  => undef,
                opened => $when->epoch - $breaks[-1][1]->epoch,
                closes => undef,
                closed => $when->epoch - $close->epoch,
            };
        } elsif ($when->is_before($open)) {
            return {
                open   => 0,
                opens  => $open->epoch - $when->epoch,
                opened => undef,
                closes => $breaks[0][0]->epoch - $when->epoch,
                closed => undef,
            };
        } else {
            my $current_open = $open;
            for (my $i = 0; $i <= $#breaks; $i++) {
                my $int_open  = $breaks[$i][0];
                my $int_close = $breaks[$i][1];
                my $next_open = exists $breaks[$i + 1] ? $breaks[$i + 1][0] : $close;

                if ($when->is_after($current_open) and $when->is_before($int_open)) {
                    return {
                        open   => 1,
                        opens  => undef,
                        opened => $when->epoch - $current_open->epoch,
                        closes => $int_open->epoch - $when->epoch,
                        closed => undef,
                    };
                } elsif ($when->is_same_as($int_open)
                    or ($when->is_after($int_open) and $when->is_before($int_close))
                    or $when->is_same_as($int_close))
                {
                    return {
                        open   => 0,
                        opens  => $int_close->epoch - $when->epoch,
                        opened => undef,
                        closes => $close->epoch - $when->epoch,       # we want to know seconds to official close
                        closed => $when->epoch - $int_open->epoch,
                    };
                } elsif ($when->is_after($int_close) and $when->is_before($next_open)) {
                    return {
                        open   => 1,
                        opens  => undef,
                        opened => $when->epoch - $int_close->epoch,
                        closes => $next_open->epoch - $when->epoch,
                        closed => undef,
                    };
                }
            }

        }
    }

    return;
}

=head1 OPENING TIMES

The following methods tell us when the exchange opens/closes on a given date.

=head2 opening_on

Returns the opening time (Date::Utility) of the exchange for a given Date::Utility.

    my $opening_epoch = $exchange->opening_on(Date::Utility->new('25-Dec-10')); # returns undef (given Xmas is a holiday)

=cut

sub opening_on {
    my ($self, $when) = @_;

    return $self->opens_late_on($when) // $self->_get_exchange_open_times($when, 'daily_open');
}

=head2 closing_on

Similar to opening_on.

    my $closing_epoch = $exchange->closing_on(Date::Utility->new('25-Dec-10')); # returns undef (given Xmas is a holiday)

=cut

sub closing_on {
    my ($self, $when) = @_;

    return $self->closes_early_on($when) // $self->_get_exchange_open_times($when, 'daily_close');
}

=head2 standard_closing_on

This is used to fetch regular non dst closing time for an exchange.

=cut

sub standard_closing_on {
    my ($self, $when) = @_;

    $when = $self->trading_date_for($when);

    return $self->closes_early_on($when) if (($self->symbol eq 'FOREX' or $self->symbol eq 'METAL') and $when->day_of_week == 5);
    return $when->truncate_to_day->plus_time_interval($self->market_times->{standard}->{daily_close});
}

=head2 settlement_on

Similar to opening_on.

    my $settlement_epoch = $exchange->settlement_on(Date::Utility->new('25-Dec-10')); # returns undef (given Xmas is a holiday)

=cut

sub settlement_on {
    my ($self, $when) = @_;

    return $self->_get_exchange_open_times($when, 'daily_settlement');
}

=head2 trading_breaks

Defines the breaktime for this exchange.

=cut

sub trading_breaks {
    my ($self, $when) = @_;
    return $self->_get_exchange_open_times($when, 'trading_breaks');
}

=head2 is_in_trading_break

Given an epoch returns true if exchange in in break time

=cut

sub is_in_trading_break {
    my ($self, $when) = @_;

    $when = Date::Utility->new($when);
    my $in_trading_break = 0;
    if (my $breaks = $self->trading_breaks($when)) {
        foreach my $break_interval (@{$breaks}) {
            if ($when->epoch >= $break_interval->[0]->epoch and $when->epoch <= $break_interval->[1]->epoch) {
                $in_trading_break++;
                last;
            }
        }
    }

    return $in_trading_break;
}

=head2 closes_early_on

Returns true if the exchange closes early on the given date.

=cut

sub closes_early_on {
    my ($self, $when) = @_;

    my $closes_early;
    if ($self->trades_on($when)) {
        my $listed = $self->early_closes->{$when->days_since_epoch};
        if ($listed) {
            $closes_early = $when->truncate_to_day->plus_time_interval($listed);
        } elsif (my $scheduled_changes = $self->regularly_adjusts_trading_hours_on($when)) {
            $closes_early = $when->truncate_to_day->plus_time_interval($scheduled_changes->{daily_close}->{to})
                if ($scheduled_changes->{daily_close});
        }
    }

    return $closes_early;
}

=head2 opens_late_on

Returns true if the exchange opens late on the given date.

=cut

sub opens_late_on {
    my ($self, $when) = @_;

    my $opens_late;
    if ($self->trades_on($when)) {
        my $listed = $self->late_opens->{$when->days_since_epoch};
        if ($listed) {
            $opens_late = $when->truncate_to_day->plus_time_interval($listed);
        } elsif (my $scheduled_changes = $self->regularly_adjusts_trading_hours_on($when)) {
            $opens_late = $when->truncate_to_day->plus_time_interval($scheduled_changes->{daily_open}->{to})
                if ($scheduled_changes->{daily_open});
        }
    }

    return $opens_late;
}

sub _get_exchange_open_times {
    my ($self, $date, $which) = @_;

    my $when = (ref $date) ? $date : Date::Utility->new($date);
    my $that_midnight = $self->trading_date_for($when);
    my $requested_time;
    if ($self->trades_on($that_midnight)) {
        my $dst_key = $self->_times_dst_key($that_midnight);
        my $ti      = $self->market_times->{$dst_key}->{$which};
        my $extended_lunch_hour;
        if ($which eq 'trading_breaks') {
            my $extended_trading_breaks = $self->market_times->{$dst_key}->{day_of_week_extended_trading_breaks};
            $extended_lunch_hour = ($extended_trading_breaks and $when->day_of_week == $extended_trading_breaks) ? 1 : 0;
        }
        if ($ti) {
            if (ref $ti eq 'ARRAY') {
                my $trading_breaks = $extended_lunch_hour ? @$ti[1] : @$ti[0];
                my $start_of_break = $that_midnight->plus_time_interval($trading_breaks->[0]);
                my $end_of_break   = $that_midnight->plus_time_interval($trading_breaks->[1]);
                push @{$requested_time}, [$start_of_break, $end_of_break];
            } else {
                $requested_time = $that_midnight->plus_time_interval($ti);
            }
        }
    }
    return $requested_time;    # returns null on no trading days.
}

=head2 trades_normal_hours_on

Boolean which indicates if the exchange is trading in its normal hours on a given Date::Utility

=cut

sub trades_normal_hours_on {
    my ($self, $when) = @_;

    my $trades_normal_hours =
        ($self->trades_on($when) and not $self->closes_early_on($when) and not $self->opens_late_on($when));

    return $trades_normal_hours;
}

=head2 regularly_adjusts_trading_hours_on

Does this Exchange always shift from regular trading hours on Dates "like"
the provided Date?

=cut

sub regularly_adjusts_trading_hours_on {

    my ($self, $when) = @_;

    my $changes;

    if ($when->day_of_week == 5) {
        my $rule = 'Fridays';
        if ($self->symbol eq 'FOREX' or $self->symbol eq 'METAL') {
            $changes = {
                'daily_close' => {
                    to   => '21h',
                    rule => $rule,
                }};
        } elsif ($self->symbol eq 'JSC') {
            $changes = {
                'morning_close' => {
                    to   => '4h30m',
                    rule => $rule,
                },
                'afternoon_open' => {
                    to   => '7h',
                    rule => $rule
                }};
        }
    }

    return $changes;
}

=head2 is_in_dst_at

Is this exchange trading on daylight savings times for the given epoch?

=cut

sub is_in_dst_at {
    my ($self, $epoch) = @_;

    my $in_dst = 0;

    if ($self->is_affected_by_dst) {
        my $dt = DateTime->from_epoch(epoch => $epoch);
        $dt->set_time_zone($self->trading_timezone);
        $in_dst = $dt->is_dst;
    }

    return $in_dst;
}
Memoize::memoize(
    'is_in_dst_at',
    NORMALIZER => '_normalize_on_symbol_and_args',
);

sub _times_dst_key {
    my ($self, $when) = @_;

    my $epoch = (ref $when) ? $when->epoch : $when;

    return ($self->is_in_dst_at($epoch)) ? 'dst' : 'standard';
}

=head2 seconds_of_trading_between_epochs

Get total number of seconds of trading time between two epochs accounting for breaks.

=cut

my $full_day = 86400;

sub seconds_of_trading_between_epochs {
    my ($self, $start_epoch, $end_epoch) = @_;

    my $result = 0;

    # step 1: calculate non-cached incomplete start-day and end_dates
    my $day_start = $start_epoch - ($start_epoch % $full_day);
    my $day_end   = $end_epoch -   ($end_epoch % $full_day);
    if (($day_start != $start_epoch) && ($start_epoch < $end_epoch)) {
        $result += $self->_computed_trading_seconds($start_epoch, min($day_start + 86399, $end_epoch));
        $start_epoch = $day_start + $full_day;
    }
    if (($day_end != $end_epoch) && ($start_epoch < $end_epoch)) {
        $result += $self->_computed_trading_seconds(max($start_epoch, $day_end), $end_epoch);
        $end_epoch = $day_end;
    }

    # step 2: calculate intermediated values (which are guaranteed to be day-boundary)
    # with cache-aware way
    if ($start_epoch < $end_epoch) {
        $result += $self->_seconds_of_trading_between_epochs_days_boundary($start_epoch, $end_epoch);
    }

    return $result;
}

my %cached_seconds_for_interval;    # key ${epoch1}-${epoch2}, value: seconds

# there is a strict assumption, that start and end epoch are day boundaries
sub _seconds_of_trading_between_epochs_days_boundary {
    my ($self, $start_epoch, $end_epoch) = @_;
    my $cache_key = join('-', $self->symbol, $start_epoch, $end_epoch);
    my $result = $cached_seconds_for_interval{$cache_key} //= do {
        my $head = $self->_computed_trading_seconds($start_epoch, $start_epoch + 86399);
        if ($end_epoch - $start_epoch > $full_day - 1) {
            my $tail = $self->_seconds_of_trading_between_epochs_days_boundary($start_epoch + $full_day, $end_epoch);
            $head + $tail;
        }
    };
    return $result;
}

## PRIVATE method _computed_trading_seconds
#
# This one ACTUALLY does the heavy lifting of determining the number of trading seconds in an intraday period.
#
sub _computed_trading_seconds {
    my ($self, $start, $end) = @_;

    my $total_trading_time = 0;
    my $when               = Date::Utility->new($start);

    if ($self->trades_on($when)) {

        # Do the full computation.
        my $opening_epoch = $self->opening_on($when)->epoch;
        my $closing_epoch = $self->closing_on($when)->epoch;

# Total trading time left in interval. This is always between 0 to $period_secs_basis.
# This will automatically take care of early close because market close will just be the early close time.
        my $total_trading_time_including_lunchbreaks =
            max(min($closing_epoch, $end), $opening_epoch) - min(max($opening_epoch, $start), $closing_epoch);

        my $total_lunch_break_time = 0;

# Now take care of lunch breaks. But handle early close properly. It could be that
# the early close already wipes out the need to handle lunch breaks.
# Handle early close. For example on 24 Dec 2009, HKSE opens at 2:00, and stops
# for lunch at 4:30 and never reopens. In that case the value of $self->closing_on($thisday)
# is 4:30, and lunch time between 4:30 to 6:00 is no longer relevant.
        if (my $breaks = $self->trading_breaks($when)) {
            for my $break_interval (@{$breaks}) {
                my $interval_open  = $break_interval->[0];
                my $interval_close = $break_interval->[1];
                my $close_am       = min($interval_open->epoch, $closing_epoch);
                my $open_pm        = min($interval_close->epoch, $closing_epoch);

                $total_lunch_break_time = max(min($open_pm, $end), $close_am) - min(max($close_am, $start), $open_pm);

                if ($total_lunch_break_time < 0) {
                    die 'Total lunch break time between ' . $start . '] and [' . $end . '] for exchange[' . $self->symbol . '] is negative';
                }
            }
        }

        $total_trading_time = $total_trading_time_including_lunchbreaks - $total_lunch_break_time;
        if ($total_trading_time < 0) {
            croak 'Total trading time (minus lunch) between ' . $start . '] and [' . $end . '] for exchange[' . $self->symbol . '] is negative.';
        }
    }

    return $total_trading_time;
}

=head2 is_affected_by_dst

Tells whether the exchange's opening times change due to daylight savings
at some point in the year.

=cut

sub _build_is_affected_by_dst {
    my $self = shift;

    my $tz = DateTime::TimeZone->new(name => $self->trading_timezone);

    # This returns some incomprehensible number... so make it a nice bool.
    return ($tz->has_dst_changes) ? 1 : 0;
}

# PRIVATE method
# Takes a two arguments: an epoch timestamp and which switch to find 'next' or 'prev'
sub _find_dst_switch {
    my ($self, $epoch, $direction) = @_;

    $direction = 'next'
        if (not defined $direction
        or scalar grep { $direction ne $_ } qw(next prev));

# Assumption: there is exactly one switch (each way) per year and no period is over 250 days long.
# If we limit our search in this way, we'll definitely find the closest switch
    my $SEARCHWIDTH = 250 * 24 * 60 * 60;
    my $low_time    = ($direction eq 'next') ? $epoch : $epoch - $SEARCHWIDTH;
    my $high_time   = ($direction eq 'next') ? $epoch + $SEARCHWIDTH : $epoch;

    # Now we need to find out the unswitched state of DST.
    # This will let us know which way to continue the search when we miss.
    my $unswitched_state = $self->is_in_dst_at($epoch);

    my $ret_val;    # Presume failure.
    my $continue_search = 1;

    while ($continue_search and $high_time > $low_time) {
        my $mid_time = int $low_time + ($high_time - $low_time) / 2;
        my $mid_state = $self->is_in_dst_at($mid_time);

        # Do we have the epoch where the switch happens?
        # If so, it should be different a second earlier.
        if ($mid_state != $self->is_in_dst_at($mid_time - 1)) {
            $continue_search = 0;
            $ret_val         = $mid_time;
        } elsif (($direction eq 'next' and $mid_state == $unswitched_state)
            or ($direction eq 'prev' and $mid_state != $unswitched_state))
        {
            # We're in the past of the switch.
            $low_time = $mid_time + 1;
        } else {
            # We're in the future from the switch
            $high_time = $mid_time;
        }
    }

    return $ret_val;
}

=head2 closed_for_the_day

Syntatic sugar to easily identify if the exchange is closed(already closed for the day or holiday or weekend).
We are not expecting any more activity in this exchange for today.

=cut

sub closed_for_the_day {
    my $self = shift;
    my $now  = Date::Utility->new;
    return (not $self->trades_on($now) or (not $self->is_open and $self->will_open));
}

=head2 last_trading_period

Returns the last_trading_period as { begin => ..., end => ... }
=cut

sub last_trading_period {
    my $self = shift;

    my $now              = Date::Utility->new;
    my $last_trading_day = $now;
    $last_trading_day = $self->trade_date_before($last_trading_day);

    my $open  = $self->opening_on($last_trading_day);
    my $close = $self->closing_on($last_trading_day);

    #For ASX, NSX and TSE Indices that can wrap around
    if ($close->is_before($open)) {
        $open = $open->minus_time_interval('1d');
    }

    return {
        begin => $open,
        end   => $close,
    };
}

=head2 regular_trading_day_after

a trading day that has no late open or early close

=cut

sub regular_trading_day_after {
    my ($self, $when) = @_;

    return if $self->closing_on($when);

    my $counter             = 0;
    my $regular_trading_day = $self->trade_date_after($when);
    while ($counter <= 10) {
        my $possible = $regular_trading_day->plus_time_interval($counter . 'd');
        if (    not $self->closes_early_on($possible)
            and not $self->opens_late_on($possible)
            and $self->trades_on($possible))
        {
            $regular_trading_day = $possible;
            last;
        }
        $counter++;
    }

    return $regular_trading_day;
}

## PRIVATE static method _normalize_on_dates
#
# Many of these functions don't change their results if asked for the
# same dates many times.  Let's exploit that for time over space
#
# This actually comes up in our pricing where we have to do many interpolations
# over the same ranges on different values.
#
# This attaches to the static method on the class for the lifetime of this instance.
# Since we only want the cache for our specific symbol, we need to include an identifier.

sub _normalize_on_dates {
    my ($self, @dates) = @_;

    return join '|', ($self->symbol, map { $_->days_since_epoch } @dates);
}

## PRIVATE static method _normalize_on_symbol_and_args
#
# Normalize on the args, but don't take the self part too seriously.

sub _normalize_on_symbol_and_args {
    my ($self, @other_args) = @_;

    return join ',', ($self->symbol, @other_args);
}

=head2 trading_period

Given an epoch returns the period of trading of the exchange in that day

=cut

sub trading_period {
    my ($self, $when) = @_;

    return [] if not $self->trades_on($when);
    my $open   = $self->opening_on($when);
    my $close  = $self->closing_on($when);
    my $breaks = $self->trading_breaks($when);

    my @times = ($open);
    if (defined $breaks) {
        push @times, @{$_} for @{$breaks};
    }
    push @times, $close;

    my @periods;
    for (my $i = 0; $i < $#times; $i += 2) {
        push @periods,
            {
            open  => $times[$i]->epoch,
            close => $times[$i + 1]->epoch
            };
    }

    return \@periods;
}

=head2 weighted_days_in_period

Returns the sum of the weights we apply to each day in the requested period.

=cut

sub weighted_days_in_period {
    my ($self, $begin, $end) = @_;

    state %cache;
    state $cache_init_time = time;

    my $key =
          $begin->epoch
        . $end->epoch
        . $self->underlying_config->quoted_currency_symbol
        . $self->underlying_config->asset_symbol
        . $self->symbol
        . ($self->for_date ? $self->for_date->epoch : 0);

    #empty cache after 5-minute so upon updating related data, the cache will be refreshed
    if (time - $cache_init_time > 300) {
        $cache_init_time = time;
        %cache           = ();
    }

    return $cache{$key} if defined $cache{$key};

    $end = $end->truncate_to_day;
    my $current = $begin->truncate_to_day->plus_time_interval('1d');
    my $days    = 0.0;

    while (not $current->is_after($end)) {
        $days += $self->weight_on($current);
        $current = $current->plus_time_interval('1d');
    }

    $cache{$key} = $days;

    return $days;
}

sub _build_asset {
    my $self = shift;

    return unless $self->underlying_config->asset_symbol;
    my $type = $self->underlying_config->asset_class;

    my $which = $type eq 'currency' ? 'Quant::Framework::Currency' : 'Quant::Framework::Asset';

    return $which->new({
        symbol           => $self->underlying_config->asset_symbol,
        for_date         => $self->for_date,
        chronicle_reader => $self->chronicle_reader,
    });
}

=head2 weight_on

Returns the weight for a given day (given as a Date::Utility object).
Returns our closed weight for days when the market is closed.

=cut

sub weight_on {
    my ($self, $date) = @_;

    state %cache;
    state $cache_init_time = time;

    my $current_time = time;
    # clears cache after 5 minutes
    if ($current_time - $cache_init_time > 300) {
        $cache_init_time = $current_time;
        %cache           = ();
    }

    my $epoch = $date->truncate_to_day->epoch;

    return $cache{$self->symbol}{$epoch} if exists $cache{$self->symbol}{$epoch};

    my $base      = $self->_build_asset;
    my $numeraire = Quant::Framework::Currency->new({
        symbol           => $self->underlying_config->quoted_currency_symbol,
        for_date         => $self->for_date,
        chronicle_reader => $self->chronicle_reader,
    });

    my $weight = $self->simple_weight_on($date) || $self->closed_weight;
    if ($self->underlying_config->market_name eq 'forex') {
        my $currency_weight =
            0.5 * ($base->weight_on($date) + $numeraire->weight_on($date));

        # If both have a holiday, set to 0.25
        if (!$currency_weight) {
            $currency_weight = 0.25;
        }

        $weight = min($weight, $currency_weight);
    } elsif ($self->symbol eq 'METAL') {
        my $usd = Quant::Framework::Currency->new({
            symbol           => 'USD',
            for_date         => $self->for_date,
            chronicle_reader => $self->chronicle_reader,
        });
        my $commodities_weight = $usd->has_holiday_on($date) ? 0.5 : 1;
        $weight = min($weight, $commodities_weight);
    }

    $cache{$self->symbol}{$epoch} = $weight;

    return $weight;
}

=head2 closed_weight

Weights assigned for days when the markets are closed, based on empirical study and industry standards.

=cut

sub closed_weight {
    my $self = shift;

    return ($self->underlying_config->market_name eq 'indices') ? 0.55 : 0.06;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
