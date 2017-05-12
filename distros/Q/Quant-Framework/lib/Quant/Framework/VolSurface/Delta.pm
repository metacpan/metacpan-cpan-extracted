package Quant::Framework::VolSurface::Delta;

=head1 NAME

Quant::Framework::VolSurface::Delta

=head1 DESCRIPTION

Represents a volatility surface, built from market implied volatilities.

=head1 SYNOPSIS

    my $surface = Quant::Framework::VolSurface::Delta->new({underlying_config => $underlying_config});

=cut

use Moose;

extends 'Quant::Framework::VolSurface';

use Math::Business::BlackScholes::Binaries;
use Number::Closest::XS qw(find_closest_numbers_around);
use List::Util qw(min);
use List::MoreUtils qw(any);
use Date::Utility;
use VolSurface::Utils qw( get_delta_for_strike get_strike_for_moneyness get_strike_for_spot_delta );
use Math::Function::Interpolator;

=head1 ATTRIBUTES

=head2 type

Return the surface type

=cut

has '+type' => (
    default => 'delta',
);

has atm_spread_point => (
    is      => 'ro',
    isa     => 'Num',
    default => '50',
);

=head2 variance_table

A variance surface. Converted from raw volatility input surface.

=cut

has variance_table => (
    is         => 'ro',
    lazy_build => 1,
);

sub _build_variance_table {
    my $self = shift;

    my $raw_surface    = $self->surface;
    my $effective_date = $self->effective_date;
    # New York 10:00
    my $ny_offset_from_gmt     = $effective_date->timezone_offset('America/New_York')->hours;
    my $seconds_after_midnight = $effective_date->plus_time_interval(10 - $ny_offset_from_gmt . 'h')->seconds_after_midnight;

    # keys are tenor in epoch, values are associated variances.
    my %table = ($self->recorded_date->epoch => {map { $_ => 0 } @{$self->smile_points}});
    foreach my $tenor (@{$self->original_term_for_smile}) {
        my $epoch = $effective_date->plus_time_interval($tenor . 'd' . $seconds_after_midnight . 's')->epoch;
        foreach my $delta (@{$self->smile_points}) {
            my $volatility = $raw_surface->{$tenor}{smile}{$delta};
            $table{$epoch}{$delta} = $volatility**2 * $tenor if defined $volatility;
        }
    }

    return \%table;
}

=head2 surface_data

The original surface data.

=cut

has surface_data => (
    is         => 'ro',
    lazy_build => 1,
);

sub _build_surface_data {
    my $self = shift;

    # For backward compatibility
    my $surface = $self->document->{surface} // $self->document->{surfaces}{'New York 10:00'};
    die('surface data not found for ' . $self->symbol) unless $surface;

    return $self->_clean($surface);
}

=head2 get_volatility

Expects 3 mandatory arguments as input.

1) from - Date::Utility object
2) to - Date::Utility object
3) delta | strike | moneyness.

Calculates volatility from the surface based input parameters.

USAGE:

  my $from = Date::Utility->new('2016-06-01 10:00:00');
  my $to   = Date::Utility->new('2016-06-01 15:00:00');
  my $vol  = $s->get_volatility({delta => 25, from => $from, to => $to});
  my $vol  = $s->get_volatility({strike => $bet->barrier, from => $from, to => $to});
  my $vol  = $s->get_volatility({delta => 50, from => $from, to => $to});

=cut

sub get_volatility {
    my ($self, $args) = @_;

    # args validity checks
    die("Must pass exactly one of delta, strike or moneyness to get_volatility.")
        if (scalar(grep { defined $args->{$_} } qw(delta strike moneyness)) != 1);

    die "Must pass two dates [from, to] to get volatility." if (not($args->{from} and $args->{to}));

    die 'Inverted dates[from=' . $args->{from}->datetime . ' to= ' . $args->{to}->datetime . '] to get volatility.'
        if $args->{from}->epoch > $args->{to}->epoch;

    # This sanity check prevents negative variance
    # This will happen when we are trying to price a contract that has expired but not settled.
    if ($args->{from}->epoch < $self->recorded_date->epoch || $args->{from}->epoch == $args->{to}->epoch) {
        $self->validation_error('Invalid request for get volatility. Surface recorded date ['
                . $self->recorded_date->datetime
                . '] requested period ['
                . $args->{from}->datetime . ' to '
                . $args->{to}->datetime
                . ']');
        return 0.01;    # return a 1% volatility but we will not sell on this volatility.
    }

    my $delta =
          (defined $args->{delta})  ? $args->{delta}
        : (defined $args->{strike}) ? $self->_convert_strike_to_delta($args)
        :                             $self->_convert_moneyness_to_delta($args);

    die 'Delta cannot be zero or negative.' if $delta < 0;

    my $smile = $self->get_smile($args->{from}, $args->{to});

    return $smile->{$delta} if $smile->{$delta};

    return $self->interpolate({
        smile        => $smile,
        sought_point => $delta,
    });
}

=head2 get_smile

Calculate the requested smile from volatility surface.

=cut

sub get_smile {
    my ($self, $from, $to) = @_;

    # each smile is calculated on the fly.
    my $number_of_days = ($to->epoch - $from->epoch) / 86400;
    my $variances_from = $self->get_variances($from);
    my $variances_to   = $self->get_variances($to);
    my $smile;

    foreach my $delta (@{$self->smile_points}) {
        $smile->{$delta} = sqrt(($variances_to->{$delta} - $variances_from->{$delta}) / $number_of_days);
    }

    if (not $self->_is_valid_volatility_smile($smile)) {
        $self->validation_error(
            "Invalid smile volatility on smile calculated from[" . $from->datetime . "] to[" . $to->datetime . "] for " . $self->symbol);
    }

    return $smile;
}

=head2 get_variances

Calculate the variance for a given date based on volatility surface data.

=cut

sub get_variances {
    my ($self, $date) = @_;

    my $epoch = $date->epoch;
    my $table = $self->variance_table;

    return $table->{$epoch} if $table->{$epoch};

    my @available_tenors = sort { $a <=> $b } keys %{$table};
    my @closest = map { Date::Utility->new($_) } @{find_closest_numbers_around($date->epoch, \@available_tenors, 2)};
    my $weight = $self->get_weight($closest[0], $date);
    my $weight2 = $weight + $self->get_weight($date, $closest[1]);

    my %variances;
    foreach my $delta (@{$self->smile_points}) {
        my $var1 = $table->{$closest[0]->epoch}{$delta};
        my $var2 = $table->{$closest[1]->epoch}{$delta};
        $variances{$delta} = $var1 + ($var2 - $var1) / $weight2 * $weight;
    }

    return \%variances;
}

=head2 get_weight

Get the weight between to given dates.

=cut

# We sliced the weight of a given into 4-hour period for easier manipulation in the future.
# We might incorporate seasonality into weights.
# A 4-hour interval for weight calculation is good enough for now.
my $weight_interval = 4 * 3600;

sub get_weight {
    my ($self, $date1, $date2) = @_;

    my $same_day      = !$date2->days_between($date1);
    my $diff          = $date2->epoch - $date1->epoch;
    my $next_interval = Date::Utility->new($date1->epoch - ($date1->epoch % $weight_interval) + $weight_interval);

    my @dates;
    if ($same_day) {
        @dates = ($diff < $weight_interval) ? ($date1->epoch, $date2->epoch) : ($date1->epoch, $self->_break($next_interval, $date2));
    } else {
        my $next_day = $date1->plus_time_interval('1d')->truncate_to_day;
        @dates =
              ($next_interval->epoch < $next_day->epoch)
            ? ($date1->epoch, $self->_break($next_interval, $date2))
            : ($date1->epoch, $self->_break($next_day, $date2));
    }

    my $calendar     = $self->calendar;
    my $total_weight = 0;
    for (my $i = 0; $i < $#dates; $i++) {
        my $dt = $dates[$i + 1] - $dates[$i];
        $total_weight += $calendar->weight_on(Date::Utility->new($dates[$i])) * $dt / 86400;
    }

    return $total_weight;
}

sub _break {
    my ($self, $d1, $d2) = @_;

    my ($e1, $e2) = ($d1->epoch, $d2->epoch);
    my @dates;
    while ($e1 <= $e2) {
        push @dates, $e1;
        my $diff = $e2 - $e1;
        last if $diff == 0;
        $e1 += min($e2 - $e1, $weight_interval);
    }

    return @dates;
}

=head2 interpolate

Quadratic interpolation to interpolate across smile
->interpolate({smile => $smile, sought_point => $sought_point});

=cut

sub interpolate {
    my ($self, $args) = @_;

    return Math::Function::Interpolator->new(points => $args->{smile})->quadratic($args->{sought_point});
}

=head2 get_market_rr_bf

Returns the rr and bf values for a given day

=cut

sub get_market_rr_bf {
    my ($self, $days) = @_;

    my $smile = $self->get_surface_smile($days);

    return $self->get_rr_bf_for_smile($smile);
}

=head2 get_smile_expiries

An array reference of that contains expiry dates for smiles on the volatility surface.

=cut

sub get_smile_expiries {
    my $self = shift;

    return [map { Date::Utility->new($_) } sort { $a <=> $b } keys %{$self->variance_table}];
}

# PRIVATE #

sub _convert_moneyness_to_delta {
    my ($self, $args) = @_;

    $args->{strike} = get_strike_for_moneyness({
        moneyness => $args->{moneyness},
        spot      => $self->builder->build_spot->spot_quote,
    });

    delete $args->{moneyness};
    my $delta = $self->_convert_strike_to_delta($args);

    return $delta;
}

sub _convert_strike_to_delta {
    my ($self, $args) = @_;

    my $conversion_args = $self->_ensure_conversion_args($args);

    return 100 * get_delta_for_strike($conversion_args);
}

sub _ensure_conversion_args {
    my ($self, $args) = @_;

    my %new_args          = %{$args};
    my $underlying_config = $self->underlying_config;

    $new_args{t} ||= ($args->{to}->epoch - $args->{from}->epoch) / (365 * 86400);
    $new_args{spot}             ||= $self->builder->build_spot->spot_quote;
    $new_args{premium_adjusted} ||= $underlying_config->{market_convention}->{delta_premium_adjusted};
    $new_args{r_rate}           ||= $self->builder->build_interest_rate->interest_rate_for($new_args{t});
    $new_args{q_rate}           ||= $self->builder->build_dividend->dividend_rate_for($new_args{t});

    $new_args{atm_vol} ||= $self->get_volatility({
        delta => 50,
        from  => $args->{from},
        to    => $args->{to},
    });

    return \%new_args;
}

sub _max_allowed_term {
    return 380;
}

sub _max_difference_between_smile_points {
    return 30;
}

sub _validate_smile_consistency {
    my $self = shift;

    my $surface_hash_ref = $self->surface;
    my @days = sort { $a <=> $b } keys %$surface_hash_ref;
    my @prev_smile;

    foreach my $day (grep { exists $surface_hash_ref->{$_}->{smile} } @days) {
        my $smile = $surface_hash_ref->{$day}->{smile};
        my @current_smile = sort { $a <=> $b } keys %{$smile};

        if (not @prev_smile) {
            @prev_smile = @current_smile;
            next;
        }

        if (@prev_smile != @current_smile || (any { $prev_smile[$_] != $current_smile[$_] } (0 .. $#current_smile))) {
            die(      'Deltas['
                    . join(',', @current_smile)
                    . "] for maturity[$day], underlying["
                    . $self->symbol
                    . '] are not the same as deltas for rest of surface['
                    . join(',', @prev_smile)
                    . '].');
        }
    }

    return;
}

#
# To ensure that the volatility is arbitrage-free, the total implied variance must be strictly
# increasing by forward moneyness.
#       As proven by Fengler, 2005 "Arbitrage-free smoothing of the implied volatility surface"
#       p.10, Proposition 2.1
#
# We check the surface market points. This is usually done at startup when volsurface object is
# being created.
#
# Forward Moneyness = K/F_T
sub _validate_termstructure_for_calendar_arbitrage {
    my $self = shift;

    my @sorted_expiries = @{$self->original_term_for_smile};
    for (my $i = 1; $i < scalar(@sorted_expiries); $i++) {
        my $smile      = $self->surface->{$sorted_expiries[$i]}->{smile};
        my $smile_prev = $self->surface->{$sorted_expiries[$i - 1]}->{smile};
        my $vol        = $smile->{50};
        my $vol_prev   = $smile_prev->{50};
        my $T          = $sorted_expiries[$i];
        my $T_prev     = $sorted_expiries[$i - 1];
        if (((($vol)**2) * $T) < (($vol_prev**2) * $T_prev)) {
            die('Negative variance found on ' . $self->symbol . ' for maturity ' . $sorted_expiries[$i - 1] . ' for ATM');
        }
    }

    return;
}

sub _admissible_check {
    my $self = shift;

    my $underlying_config = $self->underlying_config;
    my $builder           = $self->builder;
    my $S                 = $self->builder->build_spot->spot_quote;
    my $premium_adjusted  = $underlying_config->{market_convention}->{delta_premium_adjusted};
    my @expiries          = @{$self->get_smile_expiries};
    my @tenors            = @{$self->original_term_for_smile};
    my $now               = Date::Utility->new;

    for (my $i = 1; $i <= $#expiries; $i++) {
        my $day    = $tenors[$i - 1];
        my $expiry = $expiries[$i];

        die("Invalid tenor[$day] with expiry[" . $expiry->date . "] on surface. Current date[" . $now->date . ']')
            if ($expiry->days_between($now) <= 0);

        my $adjustment;
        if ($underlying_config->market_prefer_discrete_dividend) {
            $adjustment = $builder->build_dividend->dividend_adjustments_for_period({
                start => $now,
                end   => $expiry,
            });
            $S += $adjustment->{spot};
        }

        my $t     = ($expiry->epoch - $now->epoch) / (365 * 86400);
        my $r     = $builder->build_interest_rate->interest_rate_for($t);
        my $q     = ($underlying_config->market_prefer_discrete_dividend) ? 0 : $builder->build_dividend->dividend_rate_for($t);
        my $smile = $self->surface->{$day}->{smile};

        my @volatility_level = sort { $a <=> $b } keys %{$smile};
        my $first_vol_level  = $volatility_level[0];
        my $last_vol_level   = $volatility_level[-1];

        my %prev;

        foreach my $vol_level (@volatility_level) {
            my $vol = $smile->{$vol_level};
            # Temporarily get the Call strike via the Put side of the algorithm,
            # as it seems not to go crazy at the extremities. Should give the same barrier.
            my $conversion_args = {
                atm_vol          => $vol,
                t                => $t,
                r_rate           => $r,
                q_rate           => $q,
                spot             => $S,
                premium_adjusted => $premium_adjusted
            };

            if ($vol_level > 50) {
                $conversion_args->{delta}       = exp(-$r * $t) - $vol_level / 100;
                $conversion_args->{option_type} = 'VANILLA_PUT';
            } else {
                $conversion_args->{delta}       = $vol_level / 100;
                $conversion_args->{option_type} = 'VANILLA_CALL';
            }
            my $barrier = get_strike_for_spot_delta($conversion_args);

            if ($underlying_config->market_prefer_discrete_dividend) {
                $barrier += $adjustment->{barrier};
            }
            my $prob = Math::Business::BlackScholes::Binaries::vanilla_call($S, $barrier, $t, $r, $r - $q, $vol);
            my $slope;

            if (exists $prev{prob}) {
                $slope = ($prob - $prev{prob}) / ($vol_level - $prev{vol_level});
                # Admissible Check 1.
                # For delta surface, the strike(prob) is decreasing(increasing) across delta point, hence the slope is positive
                if ($slope <= 0) {
                    die(      "Admissible check 1 failure for symbol["
                            . $self->symbol
                            . "] maturity[$day]. BS digital call price decreases between $prev{vol_level} and "
                            . $vol_level);
                }
            }

            %prev = (
                slope     => $slope,
                prob      => $prob,
                vol_level => $vol_level,
            );
        }
    }

    return;
}

sub _validation_methods {
    return
        qw(_validate_age _validate_structure _validate_smile_consistency _validate_identical_surface _validate_volatility_jumps _validate_termstructure_for_calendar_arbitrage _admissible_check);
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
