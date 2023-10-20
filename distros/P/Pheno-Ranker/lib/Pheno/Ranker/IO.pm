package Pheno::Ranker::IO;

use strict;
use warnings;
use autodie;
use feature qw(say);
use Path::Tiny;
use File::Basename;
use File::Spec::Functions qw(catdir catfile);
use List::Util            qw(any);
use YAML::XS              qw(LoadFile DumpFile);
use JSON::XS;

#use Sort::Naturally qw(nsort);
use Exporter 'import';
our @EXPORT =
  qw(serialize_hashes write_alignment io_yaml_or_json read_json read_yaml write_json write_array2txt array2object validate_json write_poi coverage_stats append_and_rename_primary_key);
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

    # Checking only for qw(.yaml .yml .json)
    my @exts = qw(.yaml .yml .json);
    my $msg  = qq(Can't recognize <$file> extension. Extensions allowed are: )
      . join ',', @exts;
    my ( undef, undef, $ext ) = fileparse( $file, @exts );
    die $msg unless any { $_ eq $ext } @exts;

    # To simplify return values, we create a hash
    $ext =~ tr/a.//d;    # Unify $ext (delete 'a' and '.')
    my $return = {
        read  => { json => \&read_json,  yml => \&read_yaml },
        write => { json => \&write_json, yml => \&write_yaml }
    };

    # We return according to the mode (read or write) and format
    return $mode eq 'read'
      ? $return->{$mode}{$ext}->($file)
      : $return->{$mode}{$ext}->( { filepath => $file, data => $data } );
}

sub read_json {

    my $file = shift;

    # NB: hp.json is non-UTF8
    # malformed UTF-8 character in JSON string, at character offset 680 (before "\x{fffd}r"\n      },...")
    my $str =
      $file =~ /hp\.json/ ? path($file)->slurp : path($file)->slurp_utf8;
    return decode_json($str);    # Decode to Perl data structure
}

sub read_yaml {

    return LoadFile(shift);      # Decode to Perl data structure
}

sub write_json {

    my $arg       = shift;
    my $file      = $arg->{filepath};
    my $json_data = $arg->{data};

    # Note that canonical DOES not match the order of nsort from Sort:.Naturally
    my $json = JSON::XS->new->utf8->canonical->pretty->encode($json_data);
    path($file)->spew_utf8($json);
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
    path($file)->spew( join( "\n", @$data ) . "\n" );
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

    # Show error if any
    say_errors( \@errors ) and die if @errors;

    # return data if ok
    return $data;

}

sub say_errors {

    my $errors = shift;
    if ( @{$errors} ) {
        say join "\n", @{$errors};
    }
    return 1;
}

sub coverage_stats {

    use Data::Dumper;
    my $data     = shift;
    my $coverage = {};
    for my $item (@$data) {
        for my $key ( keys %$item ) {
            $coverage->{$key}++;
        }
    }
    return { cohort_size => scalar @$data, coverage_terms => $coverage };
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

    # NB: for is a bit faster than map
    my $count = 1;

    # We have to load into a new array data
    my $data;
    for my $item (@$ref_data) {

        my $prefix =
            $append_prefixes->[ $count - 1 ]
          ? $append_prefixes->[ $count - 1 ] . '_'
          : 'C' . $count . '_';

        # ARRAY
        if ( ref $item eq ref [] ) {
            for my $individual (@$item) {
                $individual->{$primary_key} =
                  $prefix . $individual->{$primary_key};
                push @$data, $individual;
            }
        }

        # Object
        else {
            $item->{$primary_key} = $prefix . $item->{$primary_key};
            push @$data, $item;
        }

        # Add $count
        $count++;
    }

    return $data;
}

1;
