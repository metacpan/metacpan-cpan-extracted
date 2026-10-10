package Pheno::Ranker::Compare::Remap;

use strict;
use warnings;

use Digest::SHA qw(sha1_hex);
use Hash::Fold fold => { array_delimiter => ':' };
use List::Util qw(first);
use Pheno::Ranker::Compare::Ontology qw(add_hpo_ascendants);
use Pheno::Ranker::Compare::Prune
  qw(prune_excluded_included set_excluded_phenotypicFeatures);

use Exporter 'import';
our @EXPORT_OK =
  qw(remap_hash add_id2key guess_label normalize_nested_array_indexes remap_leaf_is_usable);

sub remap_hash {
    my $arg          = shift;
    my $hash         = $arg->{hash};
    my $weight       = $arg->{weight};
    my $self         = $arg->{self};            # $self from $arg
    my $nomenclature = $arg->{nomenclature} || {};
    my $nodes        = $self->{nodes};
    my $edges        = $self->{edges};
    my $format       = $self->{format};
    my $switch       = $self->{retain_excluded_phenotypicFeatures};
    my %out_hash;

    # Do some pruning excluded / included
    prune_excluded_included( $hash, $self );

    # *** IMPORTANT ***
    # The user may include a term that:
    # 1 - may not exist in any individual
    # 2 - does not exist in some individuals
    # If the term does not exist in a individual
    #  - a) -include-terms contains ANOTHER TERM THAT EXISTS
    #        %$hash will contain keys => OK
    #  - b) -include-terms only includes the term/terms not present
    #        %$hash  = 0 , then we return {}, to avoid trouble w/ Fold.pm
    return {} unless %$hash;

    # Remapping pipeline:
    # 1. Apply include/exclude pruning before identities are generated.
    # 2. Normalize nested arrays before folding. Deeper arrays are converted
    #    to hashes keyed by deterministic content signatures, so order-only
    #    nested index differences disappear.
    # 3. Fold with Hash::Fold. NB: Hash::Fold keeps white spaces on keys.
    # 4. Replace first-level array indexes after folding.
    #
    # First-level arrays intentionally use the fold-then-remap path. This keeps
    # the documented CURIE-style replacement separate from the content-derived
    # signatures used for deeper nested arrays.
    set_excluded_phenotypicFeatures( $hash, $switch, $format );
    normalize_nested_array_indexes( $hash, $self );
    $hash = fold($hash);

    # Now we proceed for each key
    for my $key ( keys %{$hash} ) {

        # Load values
        my $val = $hash->{$key};

        next unless remap_leaf_is_usable( $key, $val, $self );

        # Add IDs to key
        my $id_key = add_id2key( $key, $hash, $self );

        # Finally add value to id_key
        my $tmp_key_at_variable_level = $id_key . '.' . $val;

        # Add HPO ascendants
        if ( defined $edges && $val =~ /^HP:/ ) {
            my $ascendants = add_hpo_ascendants(
                $tmp_key_at_variable_level,
                $nodes, $edges,
                $nomenclature
            );
            $out_hash{$_} = 1 for @$ascendants;    # weight 1 for now
        }

        ##################
        # Assign weights #
        ##################

   # NB: mrueda (04-12-23) - it's ok if $weight == undef => NO AUTOVIVIFICATION!
   # NB: We don't warn if user selection does not exist, just assign 1

        my $tmp_key_at_term_level = $tmp_key_at_variable_level;

        # If variable has . then capture $1
        if ( $tmp_key_at_term_level =~ m/\./ ) {

            # NB: For long str regex is faster than (split /\./, $foo)[0]
            $tmp_key_at_term_level =~ m/^(\w+)\./;
            $tmp_key_at_term_level = $1;
        }

        if ( defined $weight ) {

            # *** IMPORTANT ***
            # ORDER MATTERS !!!!
            # We allow for assigning weights by TERM (e.g., 1D)
            # but VARIABLE level takes precedence to TERM

            $out_hash{$tmp_key_at_variable_level} =

              # VARIABLE LEVEL
              # NB: exists stringifies the weights
              exists $weight->{$tmp_key_at_variable_level}
              ? $weight->{$tmp_key_at_variable_level} + 0   # coercing to number

              # TERM LEVEL
              : exists $weight->{$tmp_key_at_term_level}
              ? $weight->{$tmp_key_at_term_level} + 0       # coercing to number

              # NO WEIGHT
              : 1;

        }
        else {

            # Assign a weight of 1 if no users weights
            $out_hash{$tmp_key_at_variable_level} = 1;

        }

        ##############
        # label Hash #
        ##############

        # Finally we load the Nomenclature hash
        my $label = $key;
        $label =~ s/id/label/;
        $nomenclature->{$tmp_key_at_variable_level} = $hash->{$label}
          if defined $hash->{$label};
    }

    # *** IMPORTANT ***
    # We have to return an object {} when undef
    return \%out_hash // {};
}

sub normalize_nested_array_indexes {
    my ( $data, $self ) = @_;
    _normalize_nested_arrays( $data, $self, '', 0 );
    return $data;
}

sub _normalize_nested_arrays {
    my ( $data, $self, $path, $array_depth ) = @_;

    if ( ref $data eq 'HASH' ) {
        for my $key ( keys %{$data} ) {
            my $child_path = length $path ? "$path.$key" : $key;
            my $value      = $data->{$key};

            if ( ref $value eq 'ARRAY' ) {
                if ($array_depth) {
                    $data->{$key} =
                      _normalize_nested_array( $value, $self, $child_path,
                        $array_depth );
                }
                else {
                    for my $i ( 0 .. $#{$value} ) {
                        _normalize_nested_arrays( $value->[$i], $self,
                            "$child_path:$i", $array_depth + 1 );
                    }
                }
            }
            else {
                _normalize_nested_arrays( $value, $self, $child_path,
                    $array_depth );
            }
        }
    }
    elsif ( ref $data eq 'ARRAY' ) {
        for my $i ( 0 .. $#{$data} ) {
            _normalize_nested_arrays( $data->[$i], $self, "$path:$i",
                $array_depth + 1 );
        }
    }

    return $data;
}

sub _normalize_nested_array {
    my ( $array, $self, $path, $array_depth ) = @_;
    my %normalized;
    my @unidentified;

    for my $i ( 0 .. $#{$array} ) {
        my $item = $array->[$i];
        _normalize_nested_arrays( $item, $self, "$path:$i", $array_depth + 1 );

        my $signature = _nested_item_signature( "$path:$i", $item, $self );
        if ( defined $signature ) {
            $normalized{$signature} = $item;
        }
        else {
            push @unidentified, $item;
        }
    }

    # If any item lacks usable content, preserve the original array. Keeping
    # numeric indexes is safer than inventing identities from ignored fields.
    return $array if @unidentified;
    return \%normalized;
}

sub _nested_item_signature {
    my ( $prefix, $item, $self ) = @_;
    my $folded =
        ref $item eq 'HASH' ? fold($item)
      : ref $item          ? {}
      :                      { '__value__' => $item };

    my @items;
    for my $relative ( sort keys %{$folded} ) {
        my $value = $folded->{$relative};
        next if ref $value;
        my $key = $relative eq '__value__' ? $prefix : "$prefix.$relative";
        next unless remap_leaf_is_usable( $key, $value, $self );
        push @items, "$relative=$value";
    }

    return unless @items;
    return 'idx_' . substr( sha1_hex( join "\x1e", @items ), 0, 12 );
}

sub _nested_array_signature {
    my ( $prefix, $hash, $self ) = @_;
    my @items;

    # Used for generic JSON first-level array default identity inference from
    # already-folded hashes. Pre-fold nested array normalization uses
    # _nested_item_signature().
    for my $key ( sort keys %{$hash} ) {
        next unless $key eq $prefix || index( $key, "$prefix." ) == 0;
        my $value = $hash->{$key};
        next if ref $value;
        next unless remap_leaf_is_usable( $key, $value, $self );

        my $relative =
          $key eq $prefix ? '__value__' : substr( $key, length($prefix) + 1 );
        push @items, "$relative=$value";
    }

    return unless @items;
    return 'idx_' . substr( sha1_hex( join "\x1e", @items ), 0, 12 );
}

sub remap_leaf_is_usable {
    my ( $key, $val, $self ) = @_;

    return 0 unless defined $val;

    my $exclude_variables_regex_qr = $self->{exclude_variables_regex_qr};

    # Discard low-quality keys. Some can be rescued by adding ontology data,
    # but labels/info/metaData should not affect either variables or signatures.
    return 0
      if defined $exclude_variables_regex_qr
      && $key =~ $exclude_variables_regex_qr;

    my $format = $self->{format} || '';
    return 0
      if ( ( $format eq 'PXF' || $format eq 'BFF' )
        && $key =~ m/\.age(?!nt)|onset/i
        && !$self->{age} );

    return 0 if ref($val) eq 'HASH'  && !keys %{$val};
    return 0 if ref($val) eq 'ARRAY' && !@{$val};

    return 1 if ref $val;

    my %exclude_values =
      map { $_ => 1 }
      ( 'NA', 'NaN', 'Fake', 'None:No matching concept', 'Not Available' );
    return 0 if exists $exclude_values{$val};

    my $misc_regex_qr =
      qr/1900-01-01|NA0000|NCIT:C126101|P999Y|P9999Y|phenopacket_id/;
    return 0 if $val =~ $misc_regex_qr;

    return 1;
}

sub add_id2key {
    my ( $key, $hash, $self ) = @_;
    my $id_correspondence =
        defined $self->{id_correspondence}
      && defined $self->{format}
      && exists $self->{id_correspondence}{ $self->{format} }
      ? $self->{id_correspondence}{ $self->{format} }
      : undef;
    my $array_regex_qr       = $self->{array_regex_qr};
    my $array_terms_regex_qr = $self->{array_terms_regex_qr};

    #############
    # OBJECTIVE #
    #############

# This subroutine is important as it replaces the index (numeric) for a given
# array element by a selected ontology. It's done for all subkeys on that element

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
    # To make the replacement we use $id_correspondence, then we perform a regex
    # to fetch the key parts

    # Only proceed if $key is one of the array_terms
    if ( $key =~ $array_terms_regex_qr ) {

        # Now we use $array_regex_qr to capture $1, $2 and $3 for object arrays.
        # For scalar arrays we will have only $1 and $2.
        $key =~ $array_regex_qr;

        #say "$array_regex_qr -- [$key] <$1> <$2> <$3>"; # $3 can be undefined

        my ( $tmp_key, $val );

        # Object arrays. Explicit identity_paths take precedence. Generic JSON
        # can fall back to direct id-like fields or content signatures.
        if ( defined $3 ) {

            my $correspondence;
            if ( defined $id_correspondence && ref $id_correspondence->{$1} eq ref [] ) {

                #       $1         $2                 $3
                # <medicalActions> <0> <treatment.routeOfAdministration.id>
                my $subkey = ( split /\./, $3 )[0];    # treatment
                $correspondence =
                  first { $_ =~ m/^$subkey/ }
                  @{ $id_correspondence->{$1} };       # treatment.agent.id
            }
            elsif ( defined $id_correspondence && exists $id_correspondence->{$1} ) {
                $correspondence = $id_correspondence->{$1};
            }

            if ( defined $correspondence ) {

                # Now that we know which is the term we use to find key-val in $hash
                $tmp_key =
                    $1 . ':'
                  . $2 . '.'
                  . $correspondence;    # medicalActions.0.treatment.agent.id
                $val = $hash->{$tmp_key};    # DrugCentral:257
            }
            elsif ( _uses_json_default_identity($self) ) {
                $val = _default_json_array_identity( $1, $2, $hash, $self );
            }
            else {
                die
"<$1> contains object array elements but has no identity path in <$self->{config_file}>. Please add it under <identity_paths>.\n";
            }

            $key = join '.', $1, $val, $3
              ; # medicalActions.DrugCentral:257.treatment.routeOfAdministration.id
        }

        # Generic JSON scalar arrays.
        else {

            $tmp_key = $1 . ':' . $2;
            $val     = $hash->{$tmp_key};
            $key     = $1;
        }
    }

    # $key = 'Bar:1' means that we have array but the user either:
    #  a) Made a mistake in the config
    #  b) Is not using the right config file
    else {
        die
"<$1> contains array elements but is not defined as an array in <$self->{config_file}>. Please check your syntax and configuration file.\n"
          if $key =~ m/^(\w+):/;
    }

    return $key;
}

sub _uses_json_default_identity {
    my $self = shift;
    return defined $self->{format} && $self->{format} eq 'JSON';
}

sub _default_json_array_identity {
    my ( $term, $index, $hash, $self ) = @_;
    my $prefix = "$term:$index";

    for my $path (qw(id identifier code name title value)) {
        my $key = "$prefix.$path";
        return $hash->{$key}
          if exists $hash->{$key}
          && remap_leaf_is_usable( $key, $hash->{$key}, $self );
    }

    my $signature = _nested_array_signature( $prefix, $hash, $self );
    die
"<$term> contains object array elements but no usable default identity could be inferred. Please add <identity_paths> in <$self->{config_file}>.\n"
      unless defined $signature;

    return $signature;
}

sub guess_label {
    my $input_string = shift;

    if (
        $input_string =~ /\.      # Match a literal dot
                       ([^\.]+)  # Match and capture everything except a dot
                       $        # Anchor to the end of the string
                      /x
      )
    {
        return $1;
    }

    # If no dot is found, return the original string
    return $input_string;
}

1;
