package Pheno::Ranker::Align;

use strict;
use warnings;
use autodie;
use feature qw(say);
use List::Util qw(any shuffle first);

#use List::MoreUtils qw(duplicates);
use Data::Dumper;
use Sort::Naturally qw(nsort);
use Hash::Fold fold => { array_delimiter => ':' };
use Pheno::Ranker::Stats;

use Exporter 'import';
our @EXPORT =
  qw(check_format cohort_comparison compare_and_rank create_glob_and_ref_hashes randomize_variables remap_hash create_binary_digit_string parse_hpo_json);

use constant DEVEL_MODE => 0;

our %nomenclature = ();

sub check_format {

    my $data = shift;
    return exists $data->[0]{subject} ? 'PXF' : 'BFF';
}

sub cohort_comparison {

    my ( $ref_binary_hash, $self ) = @_;
    my $out_file = $self->{out_file};

    say "Performing COHORT comparison"
      if ( $self->{debug} || $self->{verbose} );

    # *** IMPORTANT ***
    # The ids/cohorts are naturally sorted (it won't match --append-prefixes!!!)
    my @sorted_keys_ref_binary_hash = nsort( keys %{$ref_binary_hash} );

    # Print to  $out_file
    #
    open( my $fh, ">", $out_file );
    say $fh "\t", join "\t", @sorted_keys_ref_binary_hash;

    # NB: It's a symmetric matrix so we could just compute
    #     triangle. However,  R needs the whole matrix

    # Initialize the 2D matrix
    my @matrix;

    # I elements
    for my $i ( 0 .. $#sorted_keys_ref_binary_hash ) {
        say "Calculating <"
          . $sorted_keys_ref_binary_hash[$i]
          . "> against the cohort..."
          if $self->{verbose};
        my $str1 = $ref_binary_hash->{ $sorted_keys_ref_binary_hash[$i] }
          {binary_digit_string_weighted};
        print $fh $sorted_keys_ref_binary_hash[$i] . "\t";

        # J elements
        for my $j ( 0 .. $#sorted_keys_ref_binary_hash ) {
            my $str2 = $ref_binary_hash->{ $sorted_keys_ref_binary_hash[$j] }
              {binary_digit_string_weighted};
            my $distance;

            if ( $j < $i ) {

                # Use the distance from the lower triangle
                $distance = $matrix[$j][$i];
            }
            elsif ( $j == $i ) {
                $distance = 0;    # Diagonal element
            }
            else {
                # Compute the distance and store it in the matrix
                $distance = hd_fast( $str1, $str2 );
                $matrix[$i][$j] = $distance;
            }

            # Fill out the other triangle
            $matrix[$j][$i] = $distance;

            print $fh $distance . "\t";
        }

        print $fh "\n";
    }

    close $fh;
    say "Matrix saved to <$out_file>" if ( $self->{debug} || $self->{verbose} );
    return 1;
}

sub compare_and_rank {

    my $arg             = shift;
    my $glob_hash       = $arg->{glob_hash};
    my $ref_binary_hash = $arg->{ref_binary_hash};
    my $tar_binary_hash = $arg->{tar_binary_hash};
    my $weight          = $arg->{weight};
    my $self            = $arg->{self};
    my $sort_by         = $self->{sort_by};
    my $align           = $self->{align};
    my $max_out         = $self->{max_out};

    say "Performing COHORT(REF)-PATIENT(TAR) comparison"
      if ( $self->{debug} || $self->{verbose} );

    # Hash for compiling distances
    my $score;

    # Hash for stats
    my $stat;

    # Load TAR binary string
    my ($tar) = keys %{$tar_binary_hash};
    my $tar_str_weighted =
      $tar_binary_hash->{$tar}{binary_digit_string_weighted};

    for my $key ( keys %{$ref_binary_hash} ) {    # No need to sort

        # Load REF binary string
        my $ref_str_weighted =
          $ref_binary_hash->{$key}{binary_digit_string_weighted};
        say "Comparing <id:$key> --- <id:$tar>" if $self->{verbose};
        say "REF:$ref_str_weighted\nTAR:$tar_str_weighted\n"
          if ( defined $self->{debug} && $self->{debug} > 1 );
        $score->{$key}{hamming} =
          hd_fast( $ref_str_weighted, $tar_str_weighted );
        $score->{$key}{jaccard} =
          jaccard_similarity( $ref_str_weighted, $tar_str_weighted );

        # Add values
        push @{ $stat->{hamming_data} }, $score->{$key}{hamming};
        push @{ $stat->{jaccard_data} }, $score->{$key}{jaccard};
    }
    $stat->{hamming_stats} = add_stats( $stat->{hamming_data} );
    $stat->{jaccard_stats} = add_stats( $stat->{jaccard_data} );

    # Initialize a few variables
    my @headers = (
        'RANK',             'REFERENCE(ID)',
        'TARGET(ID)',       'FORMAT',
        'LENGTH',           'WEIGHTED',
        'HAMMING-DISTANCE', 'DISTANCE-Z-SCORE',
        'DISTANCE-P-VALUE', 'DISTANCE-Z-SCORE(RAND)',
        'JACCARD-INDEX',    'JACCARD-Z-SCORE',
        'JACCARD-P-VALUE'
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
    my @labels = map { exists $nomenclature{$_} ? $nomenclature{$_} : $_ }
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
      ( split //, $tar_binary_hash->{$tar}{binary_digit_string} );    # Add Target

    # Sort %score by value and load results
    my $count = 1;
    $max_out++;                                                       # to be able to start w/ ONE

    # Start loop
    for my $key (
        sort {
            $sort_by eq 'jaccard'                                    #
              ? $score->{$b}{$sort_by} <=> $score->{$a}{$sort_by}    # 1 to 0 (similarity)
              : $score->{$a}{$sort_by} <=> $score->{$b}{$sort_by}    # 0 to N (distance)
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
            };

        }

        $count++;
        last if $count == $max_out;
    }

    return \@results, \%info, \@alignments_ascii, \@dataframe, \@alignments_csv;
}

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

sub create_glob_and_ref_hashes {

    my ( $array, $weight, $self ) = @_;
    my $primary_key = $self->{primary_key};
    my $glob_hash   = {};
    my $ref_hash_flattened;

    for my $i ( @{$array} ) {

        # For consistency, we obtain the primary_key for both BFF/PXF
        # from $_->{id} (not from subject.id)
        my $id = $i->{$primary_key};
        say "Flattening and remapping <id:$id> ..." if $self->{verbose};
        my $ref_hash = remap_hash(
            {
                hash   => $i,
                weight => $weight,
                self   => $self
            }
        );
        $ref_hash_flattened->{$id} = $ref_hash;

        # The idea is to create a $glob_hash with unique key-values
        # Duplicates will be automatically merged
        $glob_hash = { %$glob_hash, %$ref_hash };
    }
    return ( $glob_hash, $ref_hash_flattened );
}

sub randomize_variables {

    my ( $glob_hash, $self ) = @_;
    my $max  = $self->{max_number_var};
    my $seed = $self->{seed};

    # set random seed
    srand($seed);

    # Randomize
    # NB:keys have to be sorted for srand to work!!!!
    # perl -MList::Util=shuffle -E 'srand 123; say shuffle 1 .. 5'
    my @items = ( shuffle sort keys %$glob_hash )[ 0 .. $max - 1 ];

    # Create a new hash with a hash slice
    my %new_glob_hash;
    @new_glob_hash{@items} = @{$glob_hash}{@items};

    # return reference
    return \%new_glob_hash;
}

sub prune_excluded_included {

    my ( $hash, $self ) = @_;
    my @included = @{ $self->{include_terms} };
    my @excluded = @{ $self->{exclude_terms} };

    # Die if we have both options at the same time
    die "Sorry, <--include> and <--exclude> are mutually exclusive\n"
      if ( @included && @excluded );

    # *** IMPORTANT ***
    # Original $hash is modified

    # INCLUDED
    if (@included) {
        for my $key ( keys %$hash ) {
            delete $hash->{$key} unless any { $_ eq $key } @included;
        }
    }

    # EXCLUDED
    if (@excluded) {
        for my $key (@excluded) {
            delete $hash->{$key} if exists $hash->{$key};
        }
    }

    # We will do nothing if @included = @excluded = [] (DEFAULT)
    return 1;
}

sub undef_excluded_phenotypicFeatures {

    my $hash = shift;

    # Setting the property to undef (it will be discarded later)
    if ( exists $hash->{phenotypicFeatures} ) {
        @{ $hash->{phenotypicFeatures} } =
          map { $_->{excluded} ? undef : $_ } @{ $hash->{phenotypicFeatures} };
    }

    # *** IMPORTANT ***
    # Because of setting to undef the excludd properties, it can happen that in
    # the stats file we have phenotypicFeatures = 100% but t hen it turns out
    # that some individuals have phenotypicFeatures = {} (all excluded)
    return $hash;
}

sub remap_hash {

    my $arg    = shift;
    my $hash   = $arg->{hash};
    my $weight = $arg->{weight};
    my $self   = $arg->{self};
    my $nodes  = $self->{nodes};
    my $edges  = $self->{edges};
    my $out_hash;

    # Do some pruning excluded / included
    prune_excluded_included( $hash, $self );

    # *** IMPORTANT ***
    # The user may include a term that:
    # A - may not exist in any individual
    # B - does not exist in some individuals
    # If the term does not exist in a invidual
    #  - a) -include-terms contains ANOTHER TERM THAT EXISTS
    #        %$hash will contain keys => OK
    #  - b) -include-terms only includes the term/terms not present
    #        %$hash  = 0 , then we return {}, to avoid trouble w/ Fold.pm
    #print Dumper $hash;
    return {} unless %$hash;

    # A bit more pruning plus collapsing
    # NB: Hash::Fold keeps white spaces on keys
    $hash = fold( undef_excluded_phenotypicFeatures($hash) );

    # Load the hash that points to the hierarchy for ontology
    #  *** IMPORTANT ***
    # - phenotypicFeatures.featureType.id => BFF
    # - phenotypicFeatures.type.id        => PXF
    my $id_correspondence = $self->{id_correspondence};

    # Now we proceed for each key
    for my $key ( keys %{$hash} ) {

        # To see which ones were discarded
        #say $key if !defined $hash->{$key};

        # Discard undefined
        next unless defined $hash->{$key};

        # Discarding lines with 'low quality' keys (Time of regex profiled with :NYTProf: ms time)
        # Some can be "rescued" by adding the ontology as ($1)
        # NB1: We discard _labels too!!
        # NB2: info|metaData are always discarded

        my $regex = $self->{exclude_properties_regex};
        next
          if ( $regex && $key =~ m/$regex/ );    # $regex has to be defined and be != ''

        # The user can turn on age related values
        next if ( $key =~ m/age(?!nt)|onset/i && !$self->{age} );    # $self->{age} [0|1]

        # Load values
        my $val = $hash->{$key};

        # Discarding lines with val (Time profiled with :NYTProf: ms time)
        next
          if ( $val eq 'NA'
            || $val eq 'Fake'
            || $val eq 'None:No matching concept'
            || $val =~ m/1900-01-01|NA0000|P999Y|P9999Y|ARRAY|phenopacket_id/ );

        # Add IDs to key
        my $id_key = add_id2key( $key, $hash, $self );

        # Finally add value to id_key
        my $tmp_key = $id_key . '.' . $val;

        # Add HPO ascendants
        if ( defined $edges && $val =~ /^HP:/ ) {
            my $ascendants = add_hpo_ascendants( $tmp_key, $nodes, $edges );
            $out_hash->{$_} = 1 for @$ascendants;    # weight 1 for now
        }

        ##################
        # Assign weights #
        ##################
        # NB: mrueda (04-12-23) - it's ok if $weight == undef => NO AUTOVIVIFICATION!
        # NB: We don't warn if it does not exist, just assign 1
        # *** IMPORTANT *** 07-26-2023
        # We allow for assigning weights by TERM (e.g., 1D)
        # but VARIABLE level takes precedence to TERM

        my $tmp_key_at_term_level = $tmp_key;

        # If variable has . then capture $1
        if ( $tmp_key_at_term_level =~ m/\./ ) {

            # NB: For long str regex is faster than (split /\./, $foo)[0]
            $tmp_key_at_term_level =~ m/^(\w+)\./;
            $tmp_key_at_term_level = $1;
        }

        # ORDER MATTERS !!!!
        $out_hash->{$tmp_key} =

          # VARIABLE LEVEL
          exists $weight->{$tmp_key}
          ? $weight->{$tmp_key}

          # TERM LEVEL
          : exists $weight->{$tmp_key_at_term_level}
          ? $weight->{$tmp_key_at_term_level}

          # NO WEIGHT
          : 1;

        # Finally we load the Nomenclature hash
        my $label = $key;
        $label =~ s/id/label/;
        $nomenclature{$tmp_key} = $hash->{$label} if defined $hash->{$label};
    }

    # *** IMPORTANT ***
    # We have to return an object {} when undef
    return $out_hash // {};
}

sub add_hpo_ascendants {

    my ( $key, $nodes, $edges ) = @_;

    # First we obtain the ontology (0000539) from HP:0000539
    $key =~ m/HP:(\w+)$/;
    my $ontology = $1;

    # We'll use it to build a string equivalent to a key from $edges
    my $hpo_url = 'http://purl.obolibrary.org/obo/HP_';
    my $hpo_key = $hpo_url . $ontology;

    # We will include all ascendants in an array
    my @ascendants;
    for my $parent_id ( @{ $edges->{$hpo_key} } ) {

        # We have to create a copy to not modify the original $parent_id
        # as it can appear in multiple individuals
        my $copy_parent_id = $parent_id;
        $copy_parent_id =~ m/\/(\w+)$/;
        $copy_parent_id = $1;
        $copy_parent_id =~ tr/_/:/;

        # *** IMPORTANT ***
        # We cannot add any label to the ascendants, otherwise they will
        # not be matched by an indv down the tree
        # Myopia
        # Mild Myopia
        # We want that 'Mild Myopia' matches 'Myopia', thus we can not add a label from 'Mild Myopia'
        # Use the labels only for debug
        my $asc_key = DEVEL_MODE ? $key . '.HPO_asc_DEBUG_ONLY' : $key;
        $asc_key =~ s/HP:$ontology/$copy_parent_id/g;
        push @ascendants, $asc_key;

        # We finally add the label to %nomenclature
        my $hpo_asc_str = $hpo_url . $copy_parent_id;    # 'http://purl.obolibrary.org/obo/HP_HP:0000539
        $hpo_asc_str =~ s/HP://;                         # 0000539
        $nomenclature{$asc_key} = $nodes->{$hpo_asc_str}{lbl};
    }
    return \@ascendants;
}

sub add_id2key {

    my ( $key, $hash, $self ) = @_;
    my $id_correspondence = $self->{id_correspondence}{ $self->{format} };
    my $array_terms_str   = join '|', @{ $self->{array_terms} };
    my $array_regex       = $self->{array_regex};

    #############
    # OBJECTIVE #
    #############

    # This subroutine is important as it replaces the index (numeric) for a given
    # array element for selected ontology. It's done for all subkeys on that element

    #"interventionsOrProcedures" : [
    #     {
    #        "bodySite" : {
    #           "id" : "NCIT:C12736",
    #           "label" : "intestine"
    #        },
    #        "procedureCode" : {
    #           "id" : "NCIT:C157823",
    #           "label" : "Colon Resection"
    #        }
    #     },
    #   {
    #        "bodySite" : {
    #           "id" : "NCIT:C12736",
    #           "label" : "intestine"
    #        },
    #        "procedureCode" : {
    #           "id" : "NCIT:C86074",
    #           "label" : "Hemicolectomy"
    #        }
    #     },
    #]
    #
    # Will become:
    #
    #"interventionsOrProcedures.NCIT:C157823.bodySite.id.NCIT:C12736" : 1,
    #"interventionsOrProcedures.NCIT:C157823.procedureCode.id.NCIT:C157823" : 1,
    #"interventionsOrProcedures.NCIT:C86074.bodySite.id.NCIT:C12736" : 1,
    #"interventionsOrProcedures.NCIT:C86074.procedureCode.id.NCIT:C86074" : 1,
    #
    # To make the replecament we use $id_correspondence, after we perform a regex
    # to fetch the key parts

    # Only proceed if $key is one of the array_terms
    if ( $key =~ /$array_terms_str/ ) {

        # Now we use $array_regex to capture $1, $2 and $3 for BFF/PXF
        # NB: For others (e.g., MXF) we will have only $1 and $2
        $key =~ m/$array_regex/;
        #say "<$1> <$2> <$3>";

        my ( $tmp_key, $val );

        # Normal behaviour for BFF/PXF
        if ( defined $3 ) {

            # If id_correspondence is an array (e.g., medicalActions) we have to grep the right match
            my $correspondence;
            if ( ref $id_correspondence->{$1} eq ref [] ) {

                #       $1         $2                 $3
                # <medicalActions> <0> <treatment.routeOfAdministration.id>
                my $subkey = ( split /\./, $3 )[0];    # treatment
                $correspondence =
                  first { $_ =~ m/^$subkey/ } @{ $id_correspondence->{$1} };   # treatment.agent.id
            }
            else {
                $correspondence = $id_correspondence->{$1};
            }

            # Now that we know which is the term we use to find key-val in $hash
            $tmp_key = $1 . ':' . $2 . '.' . $correspondence;    # medicalActions.0.treatment.agent.id
            $val     = $hash->{$tmp_key};                        # DrugCentral:257
            $key     = join '.', $1, $val, $3;                   # medicalActions.DrugCentral:257.treatment.routeOfAdministration.id
        }

        # MXF or similar (...we haven't encountered other regex yet)
        else {

            $tmp_key = $1 . ':' . $2;
            $val     = $hash->{$tmp_key};
            $key     = $1;
        }
    }
    return $key;
}

sub create_binary_digit_string {

    my ( $glob_hash, $cmp_hash ) = @_;
    my $out_hash;

    # *** IMPORTANT ***
    # Being a nested for, keys %{$glob_hash} does not need sorting
    # BUT, we sort to follow the same order as serialized (sorted)
    my @sorted_keys_glob_hash = sort keys %{$glob_hash};

    # IDs of each indidividual
    for my $individual_id ( keys %{$cmp_hash} ) {    # no need to sort

        # One-hot encoding = Representing categorical data as numerical
        my ( $binary_str, $binary_str_weighted ) = ('') x 2;
        for my $key (@sorted_keys_glob_hash) {
            my $ones  = (1) x $glob_hash->{$key};
            my $zeros = (0) x $glob_hash->{$key};
            $binary_str .= exists $cmp_hash->{$individual_id}{$key} ? 1 : 0;
            $binary_str_weighted .=
              exists $cmp_hash->{$individual_id}{$key} ? $ones : $zeros;
        }
        $out_hash->{$individual_id}{binary_digit_string} = $binary_str;
        $out_hash->{$individual_id}{binary_digit_string_weighted} =
          $binary_str_weighted;
    }
    return $out_hash;
}

sub parse_hpo_json {

    my $data = shift;

    # The <hp.json> file is a structured representation of the Human Phenotype Ontology (HPO) in JSON format.
    # The HPO is structured into a directed acyclic graph (DAG)
    # Here's a brief overview of the structure of the hpo.json file:
    # - graphs: This key contains an array of ontology graphs. In the case of HPO, there is only one graph. The graph has two main keys:
    # - nodes: An array of objects, each representing an HPO term. Each term object has the following keys:
    # - id: The identifier of the term (e.g., "HP:0000118").
    # - lbl: The label (name) of the term (e.g., "Phenotypic abnormality").
    # - meta: Metadata associated with the term, including definition, synonyms, and other information.
    # - type: The type of the term, usually "CLASS".
    # - edges: An array of objects, each representing a relationship between two HPO terms. Each edge object has the following keys:
    # - sub: The subject (child) term ID (e.g., "HP:0000924").
    # - obj: The object (parent) term ID (e.g., "HP:0000118").
    # - pred: The predicate that describes the relationship between the subject and object terms, typically "is_a" in HPO.
    # - meta: This key contains metadata about the HPO ontology as a whole, such as version information, description, and other details.

    my $graph = $data->{graphs}->[0];
    my %nodes = map { $_->{id} => $_ } @{ $graph->{nodes} };
    my %edges = ();

    for my $edge ( @{ $graph->{edges} } ) {
        my $child_id  = $edge->{sub};
        my $parent_id = $edge->{obj};
        push @{ $edges{$child_id} }, $parent_id;
    }
    return \%nodes, \%edges;
}
1;
