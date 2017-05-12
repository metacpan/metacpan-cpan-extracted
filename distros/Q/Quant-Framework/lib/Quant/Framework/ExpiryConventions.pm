package Quant::Framework::ExpiryConventions;

use strict;
use warnings;

use Moose;
use DateTime;
use Date::Utility;
use Quant::Framework::Currency;
use List::Util qw(min);

has calendar => (
    is  => 'ro',
    isa => 'Quant::Framework::TradingCalendar',
);

has for_date => (
    is      => 'ro',
    isa     => 'Maybe[Date::Utility]',
    default => undef,
);

=head2 chronicle_reader

Used to work with Chronicle storage data (Holidays and Partial trading data)

=cut

has chronicle_reader => (
    is  => 'ro',
    isa => 'Data::Chronicle::Reader',
);

has is_forex_market => (
    is => 'ro',
);

=head2 symbol

What is the proper-cased symbol for our underlying?

=cut

has 'symbol' => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has quoted_currency => (
    is  => 'ro',
    isa => 'Maybe[Quant::Framework::Currency]',
);

has asset_symbol => (
    is         => 'ro',
    lazy_build => 1,
);

sub _build_asset_symbol {
    my $self   = shift;
    my $symbol = '';

    if ($self->symbol =~ /^FUT(\w+)_/) {
        $symbol = $1;
    }

    return $symbol;
}

has asset => (
    is => 'ro',
);

# This returns number of days after the trade date which determine the delivery
# and spot date. Except USDCAD which is 1 day, other are all 2 days.
has _days_for_settlement => (
    is      => 'ro',
    isa     => 'Int',
    lazy    => 1,
    builder => '_build__days_for_settlement',
);

sub _build__days_for_settlement {
    my $self = shift;
    my $days = 2;
    if ($self->symbol and $self->symbol eq 'frxUSDCAD') {
        $days = 1;
    }

    return $days;
}

sub _is_good_business_day {
    my ($self, $date) = @_;

    my $holiday_haver = (ref $self->asset =~ /Currency$/) ? $self->asset : $self->calendar;

    if (   $date->is_a_weekend
        or $holiday_haver->has_holiday_on($date)
        or $self->quoted_currency->has_holiday_on($date))
    {
        return;
    }

    return 1;
}

sub _is_good_expiry_day {
    my ($self, $date) = @_;

    if ($date->is_a_weekend or $date->date_ddmmmyy =~ /^(?:1\-Jan|25\-Dec)/) {
        return;
    }

    return 1;
}

sub _is_good_settlement_day {
    my ($self, $date) = @_;

    if (not $self->_is_good_business_day($date)) {
        return;
    }

    if (
        Quant::Framework::Currency->new({
                symbol           => 'USD',
                chronicle_reader => $self->chronicle_reader,
            }
        )->has_holiday_on($date))
    {
        return;
    }

    return 1;
}

sub _get_interim_date {
    my ($self, $date) = @_;

    my $interim_date = Date::Utility->new($date->epoch + 86400);
    if ($self->symbol !~ /USD/) {
        if (not $self->_is_good_business_day($interim_date)) {
            $interim_date = $self->_get_interim_date($interim_date);
        }
    } else {
        my $non_USD_currency =
            ($self->asset_symbol =~ /USD/)
            ? $self->quoted_currency
            : $self->asset;
        if (   $non_USD_currency->has_holiday_on($interim_date)
            or $interim_date->is_a_weekend)
        {
            $interim_date = $self->_get_interim_date($interim_date);
        }
    }

    return $interim_date;
}

# See Clark, Foreign exchange option pricing, p5 s1.4 for an explanation.
sub _spot_date {
    my ($self, $date) = @_;
    my $spot_date;
    my $interim_date;

    if ($self->_days_for_settlement == 1) {
        $spot_date = Date::Utility->new($date->epoch + 86400);
    } elsif ($self->_days_for_settlement == 2) {
        $interim_date = $self->_get_interim_date($date);
        $spot_date    = Date::Utility->new($interim_date->epoch + 86400);
    }

    while (not $self->_is_good_settlement_day($spot_date)) {
        $spot_date = Date::Utility->new($spot_date->epoch + 86400);
    }

    return $spot_date;
}

=head2 vol_expiry_date

 $underlying->vol_expiry_date({from => $date, term => '1W'});

=cut

sub vol_expiry_date {
    my ($self, $args) = @_;
    my ($from, $term) = @{$args}{qw(from term)};

    my $expiry_date;

    $term = '1D' if ($term =~ /^o\/?n$/i);

    if ($term =~ /(\d+)([DW])/) {
        my ($days, $unit) = ($1, $2);
        $days *= 7 if ($unit eq 'W');

        $expiry_date = Date::Utility->new($from->epoch + (86400 * $days));

        if (not $self->_is_good_expiry_day($expiry_date)) {
            $expiry_date = $self->vol_expiry_date({
                from => $expiry_date,
                term => '1D'
            });
        }
    } else {
        my $months = ($term =~ /^\s?(\d+)([MY])$/ and $2 eq 'M') ? $1 : $1 * 12;

        if ($self->is_forex_market) {
            $expiry_date = $self->_FX_month_and_year_term_vol_expiry_date({
                from   => $from,
                months => $months
            });
        } else {
            $expiry_date = $self->_EQ_month_and_year_term_vol_expiry_date({
                from   => $from,
                months => $months
            });
        }
    }

    return $expiry_date;
}

# When the term is expressed in months or years, the
# logic for FX and EQ differs. Here is the FX logic.
sub _FX_month_and_year_term_vol_expiry_date {
    my ($self, $args)   = @_;
    my ($from, $months) = @{$args}{qw(from months)};

    # Step 1: To obtain the valid forward delivery date
    my $forward_delivery_date = $self->_FX_forward_delivery_date({
        from   => $from,
        months => $months
    });
    my $delivery_date = $forward_delivery_date;

    # Step 2: To obtain the expiry date by shift the forward_delivery_date backward
    while (not $self->_is_good_expiry_day($forward_delivery_date)
        or $self->_spot_date($forward_delivery_date)->epoch > $delivery_date->epoch)
    {
        $forward_delivery_date = Date::Utility->new($forward_delivery_date->epoch - 86400);
    }

    my $expiry_date = $forward_delivery_date;

    return $expiry_date;
}

sub _FX_forward_delivery_date {
    my ($self, $args)   = @_;
    my ($from, $months) = @{$args}{qw(from months)};

    my $expiry_date;
    my $last_day_of_month_rule;

    # Step 1: Get the spot date
    my $spot_date = $self->_spot_date($from);

    # Step 2: Shift forward by the maturity days
    my $spot_month = $spot_date->month;
    my $spot_year  = $spot_date->year;
    my $spot_day   = $spot_date->day_of_month;

    my $forward_month = $spot_month + $months;
    my $forward_year  = $spot_year;
    my $forward_day   = $spot_day;

    while ($forward_month > 12) {
        $forward_month = $forward_month - 12;
        $forward_year  = $forward_year + 1;
    }

    # Step 3: To obtain the valid day_of_month for forward month

# 3.1: First check if the spot date itself is drop on last business day of the spot month, then the delivery date should set as last day of forward month
# Example: If the spot date is 31Jan2011, the 1M delivery date must set as 28-Feb-11 and not 31-Feb-11
    my $first_day_of_next_mth_after_spot_mth = Date::Utility->new('1-' . $spot_date->months_ahead(1));
    my $last_trading_day_of_spot_mth = $self->calendar->trade_date_before($first_day_of_next_mth_after_spot_mth, {lookback => 1});

# This is just to build the date for forward month so that we can obtain the last day of forward month
    my $forward_date = Date::Utility->new(
        DateTime->new(
            year  => $forward_year,
            month => $forward_month,
            day   => 1,
        ));

    my $last_day_of_forward_month = $forward_date->days_in_month;

    if ($spot_date->epoch == $last_trading_day_of_spot_mth->epoch) {
        $forward_day            = $last_day_of_forward_month;
        $last_day_of_month_rule = 1;
    }

# 3.2: Check if the days_of_month of spot month is greater than the last_days_of_month on forward month, then the forward deliver date should set on the last_days_of_month on forward month
# Example: If the spot date is 30Jan2011, the 1M delivery date must set as 28-Feb-11 and not 30-Feb-11

    if ($forward_day > $last_day_of_forward_month) {
        $forward_day            = $last_day_of_forward_month;
        $last_day_of_month_rule = 1;

    } elsif ($forward_day < $last_day_of_forward_month) {
        $last_day_of_month_rule = 0;
    }

    #Step 4: convert the forward date to Date::Utility date format
    $forward_date = Date::Utility->new(
        DateTime->new(
            year  => $forward_year,
            month => $forward_month,
            day   => $forward_day,
        )->epoch
    );
    my $forward_delivery_date =
        Date::Utility->new($forward_date->day_of_month . '-' . $forward_date->month_as_string . '-' . $forward_date->year_in_two_digit);

    # Step 5: To obtain valid delivery date
    if ($last_day_of_month_rule) {
        while (not $self->_is_good_settlement_day($forward_delivery_date)) {
            $forward_delivery_date = Date::Utility->new($forward_delivery_date->epoch - 86400);
        }
    } else {
        while (not $self->_is_good_settlement_day($forward_delivery_date)) {
            $forward_delivery_date = Date::Utility->new($forward_delivery_date->epoch + 86400);
        }

        # This is to make sure that the delivery date would be forward to next month
        if ($forward_delivery_date->month > $forward_month) {
            $forward_delivery_date = Date::Utility->new($forward_delivery_date->epoch - 86400);

            while (not $self->_is_good_settlement_day($forward_delivery_date)) {
                $forward_delivery_date = Date::Utility->new($forward_delivery_date->epoch - 86400);
            }
        }
    }

    return $forward_delivery_date;
}

sub _EQ_month_and_year_term_vol_expiry_date {
    my ($self, $args)   = @_;
    my ($from, $months) = @{$args}{qw(from months)};

    my $last_day;
    my $expiry_month  = $from->months_ahead($months);
    my $days_in_month = Date::Utility->new('1-' . $expiry_month)->days_in_month;
    my $day_str       = min($days_in_month, $from->day_of_month);
    my $expiry_date   = Date::Utility->new($day_str . '-' . $from->months_ahead($months));

    # Blatant abuse of holes in Date::Utility integrity.
    if ($expiry_date->days_in_month <= $expiry_date->day_of_month) {
        $expiry_date = Date::Utility->new($expiry_date->days_in_month . '-' . $expiry_date->months_ahead(0));
        $last_day++;
    }

    # No weekends.
    if ($expiry_date->is_a_weekend) {
        $expiry_date =
              $last_day
            ? $self->calendar->trade_date_before($expiry_date)
            : $self->calendar->trade_date_after($expiry_date);
    }

    return $expiry_date;
}

=head2 forward_expiry_date

$underlying->forward_expiry_date({from => $date, term => '1W'});

For Forward, the expiry date is calculated forward from the spot date. 
Example: On 4-Jul-12, the expiry date for 1W is 13-Jul-12.
         - Spot date is 6-Jul-12, 7 days forward from this 6-Jul-12 is 13-Jul-12

=cut

sub forward_expiry_date {
    my ($self, $args) = @_;
    my ($from, $term) = @{$args}{qw(from term)};

    my $expiry_date;
    my $days;
    if ($term =~ /^o\/?n$/i or $term eq '1D') {
        $days = 1;
        $expiry_date = Date::Utility->new($from->epoch + (86400 * $days));
        if (not $self->_is_good_settlement_day($expiry_date)) {
            $expiry_date = $self->forward_expiry_date({
                from => $expiry_date,
                term => '1D'
            });
        }
    } elsif ($term =~ /(\d+)([DW])/ and $term ne '1D') {

        my $days = ($term =~ /^(\d)([DW])$/ and $2 eq 'W') ? $1 * 7 : $1;

        # Step 1: Get the spot date
        my $spot_date = $self->_spot_date($from);

        # Step 2: Shift forward by the maturity days
        my $forward_date = Date::Utility->new($spot_date->epoch + $days * 86400);

        while (not $self->_is_good_settlement_day($forward_date)) {
            $forward_date = Date::Utility->new($forward_date->epoch + 86400);
        }

        $expiry_date = $forward_date;

    } elsif ($term =~ /(\d+)([MY])/) {

        my $months = ($term =~ /^(\d+)([MY])$/ and $2 eq 'M') ? $1 : $1 * 12;

        $expiry_date = $self->_FX_forward_delivery_date({
            from   => $from,
            months => $months
        });

    }

    return $expiry_date;
}

1;
