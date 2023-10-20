package Pheno::Ranker::Stats;

use strict;
use warnings;
use autodie;
use feature qw(say);
use Data::Dumper;
use Math::CDF qw(pnorm pbinom);
use Statistics::Descriptive;

use Exporter 'import';
our @EXPORT =
  qw(hd_fast jaccard_similarity estimate_hamming_stats z_score p_value_from_z_score _p_value add_stats);

use constant DEVEL_MODE => 0;

sub hd_fast {

    # Hamming Distance
    return ( $_[0] ^ $_[1] ) =~ tr/\001-\255//;
}

sub jaccard_similarity {

    my ( $str1, $str2 ) = @_;

    # NB: It does not take into account 0 --- 0
    my ( $intersection, $union ) = ( 0, 0 );
    for my $i ( 0 .. length($str1) - 1 ) {
        my $char1 = substr( $str1, $i, 1 );
        my $char2 = substr( $str2, $i, 1 );

        if ( $char1 eq '1' || $char2 eq '1' ) {
            $union++;
            $intersection++ if $char1 eq '1' && $char2 eq '1';
        }
    }
    return $union == 0 ? 0 : $intersection / $union;
}

sub estimate_hamming_stats {

    my $length               = shift;
    my $probability_mismatch = 0.5;
    my $estimated_average    = $length * $probability_mismatch;
    my $estimated_std_dev =
      sqrt( $length * $probability_mismatch * ( 1 - $probability_mismatch ) );
    return $estimated_average, $estimated_std_dev;
}

sub z_score {

    my ( $observed_value, $expected_value, $std_dev ) = @_;
    return 0 if $std_dev == 0;
    return ( $observed_value - $expected_value ) / $std_dev;
}

sub p_value_from_z_score {

    return pnorm(shift)    # One-tailed test
}

#sub _p_value {
#
#    my ( $hamming_distance, $string_length ) = @_;
#    my $probability_mismatch = 0.5;
#    return 2 * (1 - pbinom($hamming_distance - 1, $string_length, $probability_mismatch))
#}

sub add_stats {

    my $array = shift;
    my $hash_out;
    my $stat = Statistics::Descriptive::Full->new();
    $stat->add_data($array);
    $hash_out->{mean}   = $stat->mean();
    $hash_out->{sd}     = $stat->standard_deviation();
    $hash_out->{count}  = $stat->count();
    $hash_out->{per25}  = $stat->percentile(25);
    $hash_out->{per75}  = $stat->percentile(75);
    $hash_out->{min}    = $stat->min();
    $hash_out->{max}    = $stat->max();
    $hash_out->{median} = $stat->median();
    $hash_out->{sum}    = $stat->sum();

    return $hash_out;
}
1;
