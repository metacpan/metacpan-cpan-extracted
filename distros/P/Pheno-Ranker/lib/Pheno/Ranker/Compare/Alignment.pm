package Pheno::Ranker::Compare::Alignment;

use strict;
use warnings;

use Exporter 'import';
our @EXPORT_OK = qw(create_alignment recreate_array);

sub create_alignment {

    # NB: The alignment will use the weighted string
    my $arg                   = shift;
    my $ref_key               = $arg->{ref_key};
    my $binary_string1        = $arg->{ref_str_weighted};
    my $binary_string2        = $arg->{tar_str_weighted};
    my $sorted_keys_glob_hash = $arg->{sorted_keys_glob_hash};
    my $labels                = $arg->{labels};
    my $glob_hash             = $arg->{glob_hash};
    my $length1               = length($binary_string1);
    my $length2               = length($binary_string2);

    # Check that l1 = l2
    die "The binary strings must have the same length"
      if ( $length1 != $length2 );

    # Expand array to have weights as N-elements
    my $recreated_array = recreate_array( $glob_hash, $sorted_keys_glob_hash );

    # Initialize some variables
    my $out_ascii = "REF -- TAR\n";
    my @out_csv;
    my $cum_distance = 0;
    my $n_00         = 0;

    # For loop with 2 variables
    # i index for weighted
    # j the number of variables
    my ( $i, $j ) = ( 0, 0 );
    for ( $i = 0 ; $i < $length1 ; $i++, $j++ ) {

        # Load key and value
        my $key = $recreated_array->[$i];
        my $val = sprintf( "%3d", $glob_hash->{$key} );

        # We have to keep track with $j
        my $sorted_key = $sorted_keys_glob_hash->[$j];
        my $label      = $labels->[$j];

        # Load chars
        my $char1 = substr( $binary_string1, $i, 1 );
        my $char2 = substr( $binary_string2, $i, 1 );
        $n_00++ if ( $char1 == 0 && $char2 == 0 );

        # Correct $i index by adding weights
        $i = $i + $glob_hash->{$key} - 1;

        # Load metrics
        $cum_distance += $glob_hash->{$key} if $char1 ne $char2;
        my $cum_distance_pretty = sprintf( "%3d", $cum_distance );
        my $distance            = $char1 eq $char2 ? 0 : $glob_hash->{$key};
        my $distance_pretty     = sprintf( "%3d", $distance );

        # w = weight, d = distance, cd = cumul distance
        my %format = (
            '11' => '-----',
            '10' => 'xxx--',
            '01' => '--xxx',
            '00' => '     '
        );
        $out_ascii .=
qq/$char1 $format{ $char1 . $char2 } $char2 | (w:$val|d:$distance_pretty|cd:$cum_distance_pretty|) $sorted_key ($label)\n/;
        push @out_csv,
qq/$ref_key;$char1;$format{ $char1 . $char2 };$char2;$glob_hash->{$key};$distance;$sorted_key;$label/;

#REF(107:week_0_arm_1);indicator;TAR(125:week_0_arm_1);weight;hamming-distance;json-path
#0;;0;1;0;diseases.ageOfOnset.ageRange.end.iso8601duration.P16Y
#0;;0;1;0;diseases.ageOfOnset.ageRange.end.iso8601duration.P24Y
#1;-----;1;1;0;diseases.ageOfOnset.ageRange.end.iso8601duration.P39Y
    }
    return $n_00, \$out_ascii, \@out_csv;
}

sub recreate_array {
    my ( $glob_hash, $sorted_keys_glob_hash ) = @_;
    my @recreated_array;
    foreach my $key (@$sorted_keys_glob_hash) {
        for ( my $i = 0 ; $i < $glob_hash->{$key} ; $i++ ) {
            push @recreated_array, $key;
        }
    }
    return \@recreated_array;
}

1;
