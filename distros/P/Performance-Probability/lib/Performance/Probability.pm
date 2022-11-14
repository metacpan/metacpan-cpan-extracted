package Performance::Probability;

use 5.010;
use strict;
use warnings;

use Math::BivariateCDF;
use Math::Gauss::XS;
use Machine::Epsilon;

use Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(get_performance_probability);

our $VERSION = '0.06';

=head1 NAME

Performance::Probability - The performance probability is a likelihood measure of a client reaching his/her current profit and loss.

=head1 SYNOPSYS

  use Performance::Probability qw(get_performance_probability);

  my $probability = Performance::Probability::get_performance_probability(
                                   types        => [qw/CALL PUT/],
                                   payout       => [100, 100],
                                   bought_price => [75, 55],
                                   pnl          => 1000.0,
                                   underlying   => [qw/EURUSD EURUSD/],
                                   start_time   => [1461847439, 1461930839], #time in epoch
                                   sell_time    => [1461924960, 1461931561], #time in epoch
                                   );

=head1 DESCRIPTION

The performance probability is a likelihood measure of a client reaching his/her current profit and loss.

=cut

#Profit in case of winning. ( Payout minus bought price ).
sub _build_wk {

    my $bought_price = shift;
    my $payout       = shift;

    my @w_k;

    my $i;

    for ($i = 0; $i < @{$payout}; ++$i) {
        my $tmp_w_k = $payout->[$i] - $bought_price->[$i];
        push @w_k, $tmp_w_k;
    }

    return \@w_k;
}

#Loss in case of losing. (Minus bought price).
sub _build_lk {

    my $bought_price = shift;
    my @l_k;

    my $i;

    for ($i = 0; $i < @{$bought_price}; ++$i) {
        push @l_k, 0 - $bought_price->[$i];
    }

    return \@l_k;
}

#Winning probability. ( Bought price / Payout ).
sub _build_pk {

    my $bought_price = shift;
    my $payout       = shift;

    my @p_k;

    my $i;

    for ($i = 0; $i < @{$bought_price}; ++$i) {
        my $tmp_pk = $bought_price->[$i] / $payout->[$i];
        push @p_k, $tmp_pk;
    }

    return \@p_k;
}

#Sigma( profit * winning probability + loss * losing probability ).
sub _mean {

    my $pk = shift;
    my $lk = shift;
    my $wk = shift;

    my $i;
    my $sum = 0;

    for ($i = 0; $i < @{$wk}; ++$i) {
        $sum = $sum + ($wk->[$i] * $pk->[$i]) + ($lk->[$i] * (1 - $pk->[$i]));
    }

    return $sum;
}

#Sigma( (profit**2) * winning probability + (loss**2) * losing probability ).
sub _variance_x_square {

    my $pk = shift;
    my $lk = shift;
    my $wk = shift;

    my $sum = 0;
    my $i;

    for ($i = 0; $i < @{$wk}; ++$i) {
        $sum = $sum + (($wk->[$i]**2) * $pk->[$i]) + (($lk->[$i]**2) * (1 - $pk->[$i]));
    }

    return $sum;
}

#Sum of Covariance(i,j). See the documentation for the details.
#Covariance(i, j) is the covariance between contract i and j with time overlap.
sub _covariance {

    my ($start_time, $sell_time, $underlying, $types, $pk, $lk, $wk, $exit_tick_epoch, $barriers) = @_;
    my ($i, $j);
    my $covariance = 0;

    for ($i = 0; $i < @{$types}; ++$i) {
        if ($types->[$i] =~ /^CALL/ or $types->[$i] =~ /^PUT/) {

            for ($j = 0; $j < @{$sell_time}; ++$j) {
                if ($i != $j and $underlying->[$i] eq $underlying->[$j]) {

                    #check for time overlap.
                    my $min_end_time   = $sell_time->[$i] < $sell_time->[$j]   ? $sell_time->[$i]  : $sell_time->[$j];
                    my $max_start_time = $start_time->[$i] > $start_time->[$j] ? $start_time->[$i] : $start_time->[$j];
                    my $b_interval     = $min_end_time - $max_start_time;

                    if ($b_interval > 0) {

                        #calculate first and second contracts durations. please see the documentation for details

                        my $first_contract_duration  = ($sell_time->[$i] - $start_time->[$i]);
                        my $second_contract_duration = ($sell_time->[$j] - $start_time->[$j]);

                        my $i_strike = 0.0 - Math::Gauss::XS::inv_cdf($pk->[$i]);
                        my $j_strike = 0.0 - Math::Gauss::XS::inv_cdf($pk->[$j]);

                        my $corr_ij = $b_interval / (sqrt($first_contract_duration) * sqrt($second_contract_duration));

                        if ($types->[$i] ne $types->[$j]) {
                            $corr_ij = -1 * $corr_ij;
                        }

                        if ($corr_ij < -1 or $corr_ij > 1) {
                            next;
                        }

                        my $p_ij = Math::BivariateCDF::bivnor($i_strike, $j_strike, $corr_ij);

                        my $covariance_ij =
                            ($p_ij - $pk->[$i] * $pk->[$j]) * ($wk->[$i] - $lk->[$i]) * ($wk->[$j] - $lk->[$j]);
                        $covariance = $covariance + $covariance_ij;
                    }
                }
            }
        } elsif ($types->[$i] =~ /^DIGIT/) {
            for ($j = 0; $j < @{$exit_tick_epoch}; ++$j) {
                if ($i != $j and $underlying->[$i] eq $underlying->[$j] and $exit_tick_epoch->[$i] == $exit_tick_epoch->[$j]) {

                    my $p_ij = get_shared_winning_probability({
                            type_1    => $types->[$i],
                            type_2    => $types->[$j],
                            barrier_1 => $barriers->[$i],
                            barrier_2 => $barriers->[$j]});

                    my $covariance_ij = ($p_ij - $pk->[$i] * $pk->[$j]) * ($wk->[$i] - $lk->[$i]) * ($wk->[$j] - $lk->[$j]);
                    $covariance = $covariance + $covariance_ij;

                }
            }
        } else {

            next;
        }
    }
    return $covariance;
}

=head2 get_shared_winning_probability

Calculate probability that a pair of digit contracts winning together.

The outcome of a digit contract pairs are correlated if they expire at same time( same digit).

The probability of a digit contract pair expiring at same digit is equal to the number of shared winning digits of the pair divied by 10.

Example:
i. The shared winning digits for a DIGITEVEN and a DIGITOVER 2 are: 4,6, and 8. The probability would be equal to 3/10.

ii. For a DIGITOVER 3 and a DIGITUNDER 9: 4,5,6,7, and 8. The probability would be equal to 5/10.

=cut

sub get_shared_winning_probability {

    my $params           = shift;
    my $c1_type          = $params->{type_1};
    my $c2_type          = $params->{type_2};
    my $c1_choosen_digit = $params->{barrier_1};
    my $c2_choosen_digit = $params->{barrier_2};

    my @c1_winning_digits = get_winning_digits($c1_type, $c1_choosen_digit);
    my @c2_winning_digits = get_winning_digits($c2_type, $c2_choosen_digit);

    my %c2_winning_digits = map { $_ => 1 } @c2_winning_digits;

    my @shared_winning_digits = grep { $c2_winning_digits{$_} } @c1_winning_digits;

    return scalar(@shared_winning_digits) / 10;

}

=head2 get_winning_digits

Return the digits that contribute to a winning contract.

Example:DIGITEVEN : 0, 2, 4, 6, 8.
DIGITODD: 1, 3, 5,7,9

=cut

sub get_winning_digits {

    my ($type, $digit) = @_;

    my @winning_digits;
    my @all_digit = (0 .. 9);

    if ($type eq 'DIGITEVEN') {

        @winning_digits = (0, 2, 4, 6, 8);

    } elsif ($type eq 'DIGITODD') {

        @winning_digits = (1, 3, 5, 7, 9);
    } elsif ($type eq 'DIGITDIFF' or $type eq 'DIGITMATCH') {

        @winning_digits = $type eq 'DIGITDIFF' ? grep { $all_digit[$_] != $digit } @all_digit : grep { $all_digit[$_] == $digit } @all_digit;

    } elsif ($type eq 'DIGITOVER' or $type eq 'DIGITUNDER') {

        @winning_digits = $type eq 'DIGITOVER' ? grep { $all_digit[$_] > $digit } @all_digit : grep { $all_digit[$_] < $digit } @all_digit;

    }

    return @winning_digits;

}

=head2 get_performance_probability

Calculate performance probability ( modified sharpe ratio )

=cut

sub get_performance_probability {

    my $params = shift;

    my $pnl = $params->{pnl};

    if (not defined $pnl) {
        die "pnl is a required parameter.";
    }

    #Below variables are all arrays.
    my $start_time      = $params->{start_time};
    my $sell_time       = $params->{sell_time};
    my $types           = $params->{types};
    my $underlying      = $params->{underlying};
    my $bought_price    = $params->{bought_price};
    my $payout          = $params->{payout};
    my $exit_tick_epoch = $params->{exit_tick_epoch};
    my $barriers        = $params->{barriers};

    if (
        grep { $_ != scalar(@$start_time) } (
            scalar(@$sell_time), scalar(@$types),           scalar(@$underlying), scalar(@$bought_price),
            scalar(@$payout),    scalar(@$exit_tick_epoch), scalar(@$barriers)))
    {
        die "start_time, sell_time, types, underlying, bought_price and payout are required parameters and need to be arrays of same lengths.";
    }

    my $i = 0;
    for ($i = 0; $i < @{$start_time}; ++$i) {
        if ($sell_time->[$i] - $start_time->[$i] == 0) {
            die "Contract duration ( sell_time minus start_time ) cannot be zero.";
        }
    }

    my $pk = _build_pk($bought_price, $payout);
    my $lk = _build_lk($bought_price);
    my $wk = _build_wk($bought_price, $payout);

    my $mean = _mean($pk, $lk, $wk);

    my $variance = _variance_x_square($pk, $lk, $wk);

    my $covariance = _covariance($start_time, $sell_time, $underlying, $types, $pk, $lk, $wk, $exit_tick_epoch, $barriers);

    #Calculate the performance probability here.
    my $prob = 0;

    my $epsilon = machine_epsilon();

    $prob = $pnl - $mean;
    $prob = $prob / (sqrt(($variance - ($mean**2.0)) + $covariance) + $epsilon);

    $prob = 1.0 - Math::Gauss::XS::cdf($prob, 0.0, 1.0);

    return $prob;
}

1;
