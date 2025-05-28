package Pheno::Ranker::IO;

use strict;
use warnings;
use autodie;
use feature qw(say);
use Path::Tiny;
use File::Basename;
use File::Spec::Functions qw(catdir catfile);
use List::Util qw(any);
use Hash::Util qw(lock_hash);
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use YAML::XS qw(Load LoadFile DumpFile);
use JSON::XS;
#use Data::Dumper;

#use Sort::Naturally qw(nsort);
use Exporter 'import';
our @EXPORT =
  qw(serialize_hashes write_alignment io_yaml_or_json read_json read_yaml write_json write_array2txt array2object validate_json write_poi coverage_stats check_existence_of_include_terms append_and_rename_primary_key restructure_pxf_interpretations);
use constant DEVEL_MODE => 0;

#########################
#########################
#  SUBROUTINES FOR I/O  #
#########################
#########################

sub serialize_hashes {
    my $arg             = shift;
    my $data            = $arg->{data};
    my $export_basename = $arg->{export_basename};
    write_json(
        { data => $data->{$_}, filepath => qq/$export_basename.$_.json/ } )
      for keys %{$data};
    return 1;
}

sub write_alignment {
    my $arg       = shift;
    my $basename  = $arg->{align};
    my $ascii     = $arg->{ascii};
    my $dataframe = $arg->{dataframe};
    my $csv       = $arg->{csv};
    my %hash      = (
        '.txt'        => $ascii,
        '.csv'        => $dataframe,
        '.target.csv' => $csv
    );

    for my $key ( keys %hash ) {
        my $output = $basename . $key;
        write_array2txt( { filepath => $output, data => $hash{$key} } );
    }
    return 1;
}

sub io_yaml_or_json {
    my $arg  = shift;
    my $file = $arg->{filepath};
    my $mode = $arg->{mode};
    my $data = $mode eq 'write' ? $arg->{data} : undef;

    # Check if the file is gzipped
    my $is_gz = $file =~ /\.gz$/ ? 1 : 0;

    # Remove .gz for extension recognition if present
    my $file_for_ext = $is_gz ? ($file =~ s/\.gz$//r) : $file;

    # Allowed extensions
    my @exts = qw(.yaml .yml .json);

    # Use fileparse on the file name without the .gz suffix
    my ( undef, undef, $ext ) = fileparse( $file_for_ext, @exts );
    my $msg = qq(Can't recognize <$file> extension. Extensions allowed are: )
              . join ',', @exts;
    die $msg unless any { $_ eq $ext } @exts;

    # Unify extension by removing "a" and "."
    $ext =~ tr/a.//d;  # so ".yaml" or ".yml" become "yml" and ".json" becomes "json"

    # Dispatch table for read/write operations
    my $return = {
        read  => { json => \&read_json,  yml => \&read_yaml },
        write => { json => \&write_json, yml => \&write_yaml },
    };

    # Call the appropriate function based on the mode and extension
    return $mode eq 'read'
      ? $return->{$mode}{$ext}->($file)
      : $return->{$mode}{$ext}->({ filepath => $file, data => $data });
}

sub read_json {
    my $file = shift;
    my $str;
    if ($file =~ /\.gz$/) {
        gunzip $file => \$str
          or die "gunzip failed for $file: $GunzipError\n";
    }
    else {
        $str = path($file)->slurp;
    }
    return decode_json($str);
}

sub read_yaml {
    my $file = shift;
    my $data;

    # Check if the file ends with .gz
    if ($file =~ /\.gz$/) {
        my $yaml_str;
        gunzip $file => \$yaml_str
            or die "gunzip failed for $file: $GunzipError\n";
        # Decode the YAML from the string
        $data = Load($yaml_str);
    }
    else {
        # Directly load from the file
        $data = LoadFile($file);
    }
    return $data;
}

sub write_json {
    my $arg       = shift;
    my $file      = $arg->{filepath};
    my $json_data = $arg->{data};

    # Note that canonical DOES not match the order of nsort from Sort::Naturally
    my $json = JSON::XS->new->utf8->canonical->pretty->encode($json_data);
    path($file)->spew($json);
    return 1;
}

sub write_yaml {
    my $arg       = shift;
    my $file      = $arg->{filepath};
    my $json_data = $arg->{data};
    local $YAML::XS::Boolean = 'JSON::PP';
    DumpFile( $file, $json_data );
    return 1;
}

sub write_array2txt {
    my $arg  = shift;
    my $file = $arg->{filepath};
    my $data = $arg->{data};

    # Watch out for RAM usage!!!
    path($file)->spew_utf8( join( "\n", @$data ) . "\n" );
    return 1;
}

sub write_poi {
    my $arg         = shift;
    my $ref_data    = $arg->{ref_data};
    my $poi         = $arg->{poi};
    my $poi_out_dir = $arg->{poi_out_dir};
    my $primary_key = $arg->{primary_key};
    my $verbose     = $arg->{verbose};
    for my $name (@$poi) {
        my ($match) = grep { $name eq $_->{$primary_key} } @$ref_data;
        if ($match) {
            my $out = catfile( $poi_out_dir, "$name.json" );
            say "Writting <$out>" if $verbose;
            write_json( { filepath => $out, data => $match } );
        }
        else {
            warn
"No individual found for <$name>. Are you sure you used the right prefix?\n";
        }
    }
    return 1;
}

sub array2object {
    my $data = shift;
    if ( ref $data eq ref [] ) {
        my $n = @$data;
        if ( $n == 1 ) {
            $data = $data->[0];
        }
        else {
            die
"Sorry, your file has $n patients but only 1 patient is allowed with <-t>\n";
        }
    }
    return $data;
}

sub validate_json {
    my $file = shift;
    my $data = ( $file && -f $file ) ? read_yaml($file) : undef;

    # Premature return with undef if the file does not exist
    return undef unless defined $data;    #perlcritic severity 5

    # schema for the weights file
    my $schema = {
        '$schema'           => 'http://json-schema.org/draft-07/schema#',
        'type'              => 'object',
        'patternProperties' => {
            '^\w+([.:\w]*\w+)?$' => {
                'type' => 'integer',
            },
        },
        'additionalProperties' => JSON::XS::false,
    };

    # Load at runtime
    require JSON::Validator;

    # Create object and load schema
    my $jv = JSON::Validator->new;

    # Load schema in object
    $jv->schema($schema);

    # Validate data
    my @errors = $jv->validate($data);

    # Show error(s) if any + die
    if (@errors) {
        my $msg = join "\n", @errors;
        die qq/$msg\n/;
    }

    # Lock config data (keys+values)
    lock_hash(%$data);

    # return data if ok
    return $data;

}

sub coverage_stats {
    my $data     = shift;
    my $coverage = {};

    for my $item (@$data) {
        for my $key ( keys %$item ) {

            # Initialize key in coverage with 0 if not already present
            $coverage->{$key} //= 0;

            # Increment count only if value is not undef, not an empty hash, not an empty array,
            # and not equal to 'NA' or 'NaN'
            unless (
                   !defined $item->{$key}
                || ( ref $item->{$key} eq 'HASH'  && !%{ $item->{$key} } )
                || ( ref $item->{$key} eq 'ARRAY' && !@{ $item->{$key} } )
                || $item->{$key} eq 'NA'    # Check for 'NA'
                || $item->{$key} eq 'NaN'
              )                             # Check for 'NaN'
            {
                $coverage->{$key}++;
            }
        }
    }
    return {
        cohort_size    => scalar @$data,
        coverage_terms => $coverage
    };
}

sub check_existence_of_include_terms {
    my ( $coverage, $include_terms ) = @_;

    # Return true if include_terms is empty
    return 1 unless @$include_terms;

    # Check for the existence of any term in include_terms within coverage
    # Returns true if any term exists, false otherwise
    return any { exists $coverage->{coverage_terms}{$_} } @$include_terms;
}

sub append_and_rename_primary_key {
    my $arg             = shift;
    my $ref_data        = $arg->{ref_data};
    my $append_prefixes = $arg->{append_prefixes};
    my $primary_key     = $arg->{primary_key};

    # Premature return if @$ref_data == 1 (only 1 cohort)
    # *** IMPORTANT ***
    # $ref_data->[0] can be ARRAY or HASH
    # We force HASH to be ARRAY
    return ref $ref_data->[0] eq ref {} ? [ $ref_data->[0] ] : $ref_data->[0]
      if @$ref_data == 1;

    # Count for prefixes
    my $prefix_count = 1;

    # We have to load into a new array data
    # NB: for is a bit faster than map
    my $data;
    for my $item (@$ref_data) {

        # Get prefix
        my $prefix =
            $append_prefixes->[ $prefix_count - 1 ]
          ? $append_prefixes->[ $prefix_count - 1 ] . '_'
          : 'C' . $prefix_count . '_';

        # ARRAY
        my $item_count = 1;
        if ( ref $item eq ref [] ) {
            for my $individual (@$item) {
                my $id = $individual->{$primary_key};
                check_null_primary_key(
                    {
                        count       => $item_count,
                        primary_key => $primary_key,
                        id          => $id,
                        prefix      => $prefix
                    }
                );
                $individual->{$primary_key} = $prefix . $id;
                push @$data, $individual;
                $item_count++;
            }
        }

        # Object
        else {

            # Check if primary_key is defined
            my $id = $item->{$primary_key};
            check_null_primary_key(
                {
                    count       => $item_count,
                    primary_key => $primary_key,
                    id          => $id,
                    prefix      => $prefix
                }
            );
            $item->{$primary_key} = $prefix . $id;
            push @$data, $item;
            $item_count++;
        }
        $prefix_count++;
    }
    return $data;
}

sub check_null_primary_key {
    my $arg         = shift;
    my $id          = $arg->{id};
    my $count       = $arg->{count};
    my $primary_key = $arg->{primary_key};
    my $prefix      = $arg->{prefix};
    die
"Sorry but the JSON document ${prefix}[$count] does not have the primary_key <$primary_key> defined\n"
      unless defined $id;
    return 1;
}

sub restructure_pxf_interpretations {
    my ( $data, $self ) = @_;

    # Premature return if the format is not 'PXF'
    return unless $self->{format} eq 'PXF';

    # Premature return if "interpretations" is excluded
    return if (grep { $_ eq 'interpretations' } @{ $self->{exclude_terms} });

    say "Restructuring <interpretations> in PXFs..." if defined $self->{verbose};

    # Function to restructure individual interpretation
    my $restructure_interpretation = sub {
        my $interpretation     = shift;
        my $disease_id         = $interpretation->{diagnosis}{disease}{id};
        my $new_interpretation = {
            progressStatus         => $interpretation->{progressStatus},
            genomicInterpretations => {}
        };

        foreach my $genomic_interpretation (
            @{ $interpretation->{diagnosis}{genomicInterpretations} } )
        {
            my $gene_id;
            my $interpretation_data;

            if ( exists $genomic_interpretation->{variantInterpretation} ) {
                my $variant_interpretation =
                  $genomic_interpretation->{variantInterpretation};

                # Check if geneContext with valueId exists
                if (
                    exists $variant_interpretation->{variationDescriptor}
                    {geneContext}{valueId} )
                {
                    $gene_id = $variant_interpretation->{variationDescriptor}
                      {geneContext}{valueId};
                }

                # Check if id within variationDescriptor exists as an alternative
                elsif (
                    exists $variant_interpretation->{variationDescriptor}{id} )
                {
                    $gene_id =
                      $variant_interpretation->{variationDescriptor}{id};
                }

                $interpretation_data = $variant_interpretation;
            }
            elsif ( exists $genomic_interpretation->{geneDescriptor} ) {
                $gene_id = $genomic_interpretation->{geneDescriptor}{valueId};
                $interpretation_data =
                  $genomic_interpretation->{geneDescriptor};
            }

            $new_interpretation->{genomicInterpretations}{$gene_id} = {
                interpretationStatus =>
                  $genomic_interpretation->{interpretationStatus},
                (
                    exists $genomic_interpretation->{variantInterpretation}
                    ? ( variantInterpretation => $interpretation_data )
                    : ( geneDescriptor => $interpretation_data )
                )
            };
        }

        return ( $disease_id, $new_interpretation );
    };

    # Helper function to process a data structure
    my $process_data = sub {
        my $data = shift;
        return unless exists $data->{interpretations};

        my $new_data = {};

        foreach my $interpretation ( @{ $data->{interpretations} } ) {
            my ( $disease_id, $new_interpretation ) =
              $restructure_interpretation->($interpretation);
            $new_data->{$disease_id} = $new_interpretation;
        }

        $data->{interpretations} = $new_data;
    };

    # Process $data if it's an array or a single object
    if ( ref($data) eq 'ARRAY' ) {
        foreach my $entry (@$data) {
            $process_data->($entry) if ref($entry) eq 'HASH';
        }
    }
    elsif ( ref($data) eq 'HASH' ) {
        $process_data->($data);
    }

    return 1;
}

