package Pheno::Ranker::Compare::Rank;

use strict;
use warnings;
use feature qw(say);

use JSON::XS;
use Pheno::Ranker::Metrics;
use Pheno::Ranker::Compare::Alignment qw(create_alignment);
use Pheno::Ranker::Compare::Remap qw(guess_label);

use Exporter 'import';
our @EXPORT_OK = qw(compare_and_rank);

sub compare_and_rank {
    my $arg             = shift;
    my $glob_hash       = $arg->{glob_hash};
    my $ref_hash        = $arg->{ref_hash};
    my $tar_hash        = $arg->{tar_hash};
    my $ref_binary_hash = $arg->{ref_binary_hash};
    my $tar_binary_hash = $arg->{tar_binary_hash};
    my $weight          = $arg->{weight};
    my $self            = $arg->{self};
    my $nomenclature    = $arg->{nomenclature} || {};
    my $sort_by         = $self->{sort_by};
    my $align           = $self->{align};
    my $max_out         = $self->{max_out};

    say "Performing COHORT(REF)-PATIENT(TAR) comparison"
      if ( $self->{debug} || $self->{verbose} );

    # Hash for compiling metrics
    my $score;

    # Hash for stats
    my $stat;

    # Load TAR binary string
    my ($tar) = keys %{$tar_binary_hash};
    my $tar_str_weighted =
      $tar_binary_hash->{$tar}{binary_digit_string_weighted};

    # Load TAR number of vars
    my $target_vars = keys %{ $tar_hash->{$tar} };

    for my $key ( keys %{$ref_binary_hash} ) {    # No need to sort

        # Load REF binary string
        my $ref_str_weighted =
          $ref_binary_hash->{$key}{binary_digit_string_weighted};
        say "Comparing <id:$key> --- <id:$tar>" if $self->{verbose};
        say "REF:$ref_str_weighted\nTAR:$tar_str_weighted\n"
          if ( defined $self->{debug} && $self->{debug} > 1 );

        # Hamming
        $score->{$key}{hamming} =
          hd_fast( $ref_str_weighted, $tar_str_weighted );

        # Intersect and Jaccard
        ( $score->{$key}{jaccard}, $score->{$key}{intersect} ) =
          jaccard_similarity( $ref_str_weighted, $tar_str_weighted );

        # Load REF number of vars
        $score->{$key}{reference_vars} = keys %{ $ref_hash->{$key} };

        # Add values
        push @{ $stat->{hamming_data} }, $score->{$key}{hamming};
        push @{ $stat->{jaccard_data} }, $score->{$key}{jaccard};
    }

    # Stats are only computed once (no overhead)
    $stat->{hamming_stats} = add_stats( $stat->{hamming_data} );
    $stat->{jaccard_stats} = add_stats( $stat->{jaccard_data} );

    # Initialize a few variables
    my @headers = (
        'RANK',              'REFERENCE(ID)',
        'TARGET(ID)',        'FORMAT',
        'LENGTH',            'WEIGHTED',
        'HAMMING-DISTANCE',  'DISTANCE-Z-SCORE',
        'DISTANCE-P-VALUE',  'DISTANCE-Z-SCORE(RAND)',
        'JACCARD-INDEX',     'JACCARD-Z-SCORE',
        'JACCARD-P-VALUE',   'REFERENCE-VARS',
        'TARGET-VARS',       'INTERSECT',
        'INTERSECT-RATE(%)', 'COMPLETENESS(%)'
    );
    my $header  = join "\t", @headers;
    my @results = $header;
    my %info;
    my $length_align = length($tar_str_weighted);
    my $weight_bool  = $weight ? 'True' : 'False';
    my @alignments_ascii;
    my $alignment_str_csv;
    my @alignments_csv = join ';',
      qw/id ref indicator tar weight hamming-distance json-path label/;

    # The dataframe will have two header lines
    # *** IMPORTANT ***
    # nsort does not yield same results as canonical from JSON::XS
    # NB: we're sorting here and in create_binary_digit_string()
    my @sort_keys_glob_hash = sort keys %{$glob_hash};

    # Creating @labels array from {id,label}, or guess_label()
    my @labels =
      map { exists $nomenclature->{$_} ? $nomenclature->{$_} : guess_label($_) }
      @sort_keys_glob_hash;

    # Die if #elements in arrays differ
    die "Mismatch between variables and labels"
      if @sort_keys_glob_hash != @labels;

    # Labels
    # NB: there is a comma in 'Serum Glutamic Pyruvic Transaminase, CTCAE'
    my @dataframe = join ';', 'Id', @labels;

    # Variables (json path)
    push @dataframe, join ';', 'Id', @sort_keys_glob_hash;

    # 0/1
    push @dataframe, join ';', qq/T|$tar/,
      ( split //, $tar_binary_hash->{$tar}{binary_digit_string} );  # Add Target

    # Sort %score by value and load results
    my $count = 1;
    $max_out++;    # to be able to start w/ ONE

    # Start loop
    for my $key (
        sort {
            $sort_by eq 'jaccard'           #
              ? $score->{$b}{$sort_by}
              <=> $score->{$a}{$sort_by}    # 1 to 0 (similarity)
              : $score->{$a}{$sort_by}
              <=> $score->{$b}{$sort_by}    # 0 to N (distance)
        } keys %$score
      )
    {

        say "$count: Creating alignment <id:$key>" if $self->{verbose};

        # Create ASCII alignment
        # NB: We need it here to get $n_00
        my ( $n_00, $alignment_str_ascii, $alignment_arr_csv ) =
          create_alignment(
            {
                ref_key          => $key,
                ref_str_weighted =>
                  $ref_binary_hash->{$key}{binary_digit_string_weighted},
                tar_str_weighted      => $tar_str_weighted,
                glob_hash             => $glob_hash,
                sorted_keys_glob_hash => \@sort_keys_glob_hash,
                labels                => \@labels
            }
          );

     # *** IMPORTANT ***
     # The LENGTH of the alignment is based on the #variables in the REF-COHORT
     # Compute estimated av and dev for binary_string of L = length_align - n_00
     # Corrected length_align L = length_align - n_00
        my $length_align_corrected = $length_align - $n_00;

        #$estimated_average, $estimated_std_dev
        ( $stat->{hamming_stats}{mean_rnd}, $stat->{hamming_stats}{sd_rnd} ) =
          estimate_hamming_stats($length_align_corrected);

        # Compute a few stats
        my $hamming_z_score = z_score(
            $score->{$key}{hamming},
            $stat->{hamming_stats}{mean},
            $stat->{hamming_stats}{sd}
        );
        my $hamming_z_score_from_random = z_score(
            $score->{$key}{hamming},
            $stat->{hamming_stats}{mean_rnd},
            $stat->{hamming_stats}{sd_rnd}
        );

        #my $hamming_p_value =
        #  p_value( $score->{$key}{hamming}, $length_align_corrected );
        my $hamming_p_value_from_z_score =
          p_value_from_z_score($hamming_z_score);
        my $jaccard_z_score = z_score(
            $score->{$key}{jaccard},
            $stat->{jaccard_stats}{mean},
            $stat->{jaccard_stats}{sd}
        );
        my $jaccard_p_value_from_z_score =
          p_value_from_z_score( 1 - $jaccard_z_score );

        # Compute Intersect-Rate (I/T) * 100
        #         Completeness   (T/R) * 100
        my $reference_vars = $score->{$key}{reference_vars};
        my $intersect      = $score->{$key}{intersect};
        my $intersect_rate =
          ( $target_vars == 0 ) ? 0 : ( $intersect / $target_vars ) * 100;
        my $completeness =
          ( $reference_vars == 0 ) ? 0 : ( $intersect / $reference_vars ) * 100;

        # Create a hash with formats
        my $format = {
            'RANK'          => { value => $count,          format => undef },
            'REFERENCE(ID)' => { value => $key,            format => undef },
            'TARGET(ID)'    => { value => $tar,            format => undef },
            'FORMAT'        => { value => $self->{format}, format => undef },
            'WEIGHTED'      => { value => $weight_bool,    format => undef },
            'LENGTH' => { value => $length_align_corrected, format => '%6d' },
            'HAMMING-DISTANCE' =>
              { value => $score->{$key}{hamming}, format => '%4d' },
            'DISTANCE-Z-SCORE' =>
              { value => $hamming_z_score, format => '%7.3f' },
            'DISTANCE-P-VALUE' =>
              { value => $hamming_p_value_from_z_score, format => '%12.7f' },
            'DISTANCE-Z-SCORE(RAND)' =>
              { value => $hamming_z_score_from_random, format => '%8.4f' },
            'JACCARD-INDEX' =>
              { value => $score->{$key}{jaccard}, format => '%7.3f' },
            'JACCARD-Z-SCORE' =>
              { value => $jaccard_z_score, format => '%7.3f' },
            'JACCARD-P-VALUE' =>
              { value => $jaccard_p_value_from_z_score, format => '%12.7f' },
            'REFERENCE-VARS' => { value => $reference_vars, format => '%6d' },
            'TARGET-VARS'    => { value => $target_vars,    format => '%6d' },
            'INTERSECT'      => { value => $intersect,      format => '%6d' },
            'INTERSECT-RATE(%)' =>
              { value => $intersect_rate, format => '%8.2f' },
            'COMPLETENESS(%)' => { value => $completeness, format => '%8.2f' }
        };

        # Serialize results
        my $tmp_str = join "\t", map {
            defined $format->{$_}{format}
              ? sprintf( $format->{$_}{format}, $format->{$_}{value} )
              : $format->{$_}{value}
        } @headers;
        push @results, $tmp_str;

        # To save memory only load if --align
        if ( defined $align ) {

            # Add all of the above to @alignments_ascii
            my $sep = ('-') x 80;
            push @alignments_ascii,
              qq/#$header\n$tmp_str\n$sep\n$$alignment_str_ascii/;

            # Add all of the above to @alignments_csv
            push @alignments_csv, @$alignment_arr_csv;

            # Add data to dataframe
            push @dataframe, join ';', qq/R|$key/,
              ( split //, $ref_binary_hash->{$key}{binary_digit_string} );

            # Add values to info
            $info{$key} = {
                  weighted => $weight_bool eq 'True'
                ? JSON::XS::true
                : JSON::XS::false,
                reference_id            => $key,
                target_id               => $tar,
                reference_binary_string =>
                  $ref_binary_hash->{$key}{binary_digit_string},
                target_binary_string =>
                  $tar_binary_hash->{$key}{binary_digit_string},
                reference_binary_string_weighted =>
                  $ref_binary_hash->{$key}{binary_digit_string_weighted},
                target_binary_string_weighted =>
                  $tar_binary_hash->{$key}{binary_digit_string_weighted},
                alignment_length   => $length_align_corrected,
                hamming_distance   => $score->{$key}{hamming},
                hamming_z_score    => $hamming_z_score,
                hamming_p_value    => $hamming_p_value_from_z_score,
                jaccard_similarity => $score->{$key}{jaccard},
                jaccard_z_score    => $jaccard_z_score,
                jaccard_p_value    => $jaccard_p_value_from_z_score,
                jaccard_distance   => 1 - $score->{$key}{jaccard},
                format             => $self->{format},
                alignment          => $$alignment_str_ascii,
                reference_vars     => $reference_vars,
                target_vars        => $target_vars,
                intersect          => $intersect,
                intersect_rate     => $intersect_rate,
                completeness       => $completeness
            };

        }

        $count++;
        last if $count == $max_out;
    }

    return \@results, \%info, \@alignments_ascii, \@dataframe, \@alignments_csv;
}

1;
