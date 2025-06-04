package Pheno::Ranker::Metrics;

use strict;
use warnings;
use autodie;
use feature qw(say);

#use Data::Dumper;
use File::HomeDir;
use File::Path            qw(make_path);
use File::Spec::Functions qw(catdir);
use Math::CDF             qw(pnorm pbinom);
use Statistics::Descriptive;

use Exporter 'import';
our @EXPORT =
  qw(hd_fast jaccard_similarity jaccard_similarity_formatted estimate_hamming_stats z_score p_value_from_z_score _p_value add_stats);

use constant DEVEL_MODE => 0;

# Define a hidden directory in the user's home for Inline's compiled code
my $inline_dir = catdir( File::HomeDir->my_home, '.Inline' );

# Create the directory if it does not exist
unless ( -d $inline_dir ) {
    make_path($inline_dir) or die "Cannot create directory $inline_dir: $!";
}

# Configure Inline C to use this directory
use Inline C => Config => directory => $inline_dir;

# Inline C implementation using XS style (old-style syntax)
use Inline C => <<'END_C';
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

SV* c_jaccard_similarity(char* str1, char* str2, int length) {
    int union_count = 0, intersection = 0, i;
    for(i = 0; i < length; i++){
        if(str1[i] == '1' || str2[i] == '1'){
            union_count++;
            if(str1[i] == '1' && str2[i] == '1')
                intersection++;
        }
    }
    double similarity = union_count ? ((double)intersection) / union_count : 0.0;
    
    /* Create a new array (AV) and push the two results */
    AV* av = newAV();
    av_push(av, newSVnv(similarity));  /* push similarity (double) */
    av_push(av, newSViv(intersection));  /* push intersection (int) */
    
    /* Wrap the array in a reference and increment the reference count.
       Do not call sv_2mortal on the resulting RV. */
    SV* rv = newRV_inc((SV*)av);
    return rv;
}

/* 
   This function computes the Hamming distance between two strings,
   assuming they are both composed of '0' and '1' characters and have equal length.
   It is defined as c_hd_fast to avoid a naming conflict with the Perl wrapper.
*/
int c_hd_fast(char* s1, char* s2, int len) {
    int diff = 0;
    int i;
    for(i = 0; i < len; i++){
        if (s1[i] != s2[i])
            diff++;
    }
    return diff;
}
END_C

###########
# HAMMING #
###########

# Perl wrapper: calls the Inline C function "c_hd_fast"
sub hd_fast {
    my ( $s1, $s2 ) = @_;
    die "Strings must be the same length" if length($s1) != length($s2);
    return c_hd_fast( $s1, $s2, length($s1) );
}

# Original
sub _hd_fast {

    # Hamming Distance
    return ( $_[0] ^ $_[1] ) =~ tr/\001-\255//;
}

###########
# JACCARD #
###########

# Perl wrapper: calls the Inline C function "c_jaccard_similarity"
sub jaccard_similarity {
    my ( $str1, $str2 ) = @_;
    my $len = length($str1);
    die "Strings must be of equal length" if $len != length($str2);
    my ( $jaccard, $intersection ) =
      @{ c_jaccard_similarity( $str1, $str2, $len ) };
    return ( $jaccard, $intersection );
}

# Original (using vec)
sub _jaccard_similarity {
    my ( $str1, $str2 ) = @_;
    my $len = length($str1);
    die "Strings must be of equal length" if $len != length($str2);
    my ( $intersection, $union ) = ( 0, 0 );
    for my $i ( 0 .. $len - 1 ) {
        my $b1 = vec( $str1, $i, 8 );
        my $b2 = vec( $str2, $i, 8 );
        if ( $b1 == ord('1') || $b2 == ord('1') ) {
            $union++;
            $intersection++ if ( $b1 == ord('1') && $b2 == ord('1') );
        }
    }
    return $union == 0 ? ( 0, 0 ) : ( $intersection / $union, $intersection );
}

sub jaccard_similarity_formatted {

# *** IMPORTANT ****
# mrueda Dec-27-23
# Direct formatting in jaccard_similarity adds minor overhead (verified by testing),
# but prevents errors on some CPAN FreeBSD architectures.
    my ( $result, undef ) = jaccard_similarity(@_);
    return sprintf( "%.6f", $result );
}

#########
# STATS #
#########

sub estimate_hamming_stats {

# Estimate Hamming stats using a binomial distribution model. Assumes each bit position
# in the binary strings has an independent 50% chance of mismatch, to calculate
# the mean and standard deviation of the Hamming distance.

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
#    my ( $hamming_distance, $string_length ) = @_;
#    my $probability_mismatch = 0.5;
#    return 2 * (1 - pbinom($hamming_distance - 1, $string_length, $probability_mismatch))
#}

sub add_stats {
    my $array = shift;
    my %hash_out;
    my $stat = Statistics::Descriptive::Full->new();
    $stat->add_data($array);
    $hash_out{mean}   = $stat->mean();
    $hash_out{sd}     = $stat->standard_deviation();
    $hash_out{count}  = $stat->count();
    $hash_out{per25}  = $stat->percentile(25);
    $hash_out{per75}  = $stat->percentile(75);
    $hash_out{min}    = $stat->min();
    $hash_out{max}    = $stat->max();
    $hash_out{median} = $stat->median();
    $hash_out{sum}    = $stat->sum();

    return \%hash_out;
}
1;
