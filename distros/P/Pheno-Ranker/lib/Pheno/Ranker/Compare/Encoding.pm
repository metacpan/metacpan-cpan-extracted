package Pheno::Ranker::Compare::Encoding;

use strict;
use warnings;

use Compress::Zlib qw(compress uncompress);
use MIME::Base64 qw(encode_base64 decode_base64);

use Exporter 'import';
our @EXPORT_OK =
  qw(create_binary_digit_string binary_to_base64 _base64_to_binary);

sub create_binary_digit_string {
    my ( $export, $weight, $glob_hash, $cmp_hash ) = @_;
    my %out_hash;

    # *** IMPORTANT ***
    # Being a nested for, keys %{$glob_hash} does not need sorting
    # BUT, we sort to follow the same order as serialized (sorted)
    my @sorted_keys_glob_hash = sort keys %{$glob_hash};

    # IDs of each indidividual
    for my $individual_id ( keys %{$cmp_hash} ) {    # no need to sort

        # One-hot encoding = Representing categorical data as numerical
        my ( $binary_str, $binary_str_weighted ) = ('') x 2;

        for my $key (@sorted_keys_glob_hash) {
            my $has_value = exists $cmp_hash->{$individual_id}{$key};
            $binary_str .= $has_value ? '1' : '0';
            if ( defined $weight ) {
                $binary_str_weighted .=
                  $has_value
                  ? ( '1' x $glob_hash->{$key} )
                  : ( '0' x $glob_hash->{$key} );
            }
        }

        # If weight is not defined, simply assign the unweighted string once.
        $binary_str_weighted = $binary_str unless defined $weight;

        $out_hash{$individual_id}{binary_digit_string} = $binary_str;
        $out_hash{$individual_id}{binary_digit_string_weighted} =
          $binary_str_weighted;

        if ( defined $export ) {

            # Convert string => raw bytes > zlib-compres => Base64
            $out_hash{$individual_id}{zlib_base64_binary_digit_string} =
              binary_to_base64($binary_str);

            $out_hash{$individual_id}{zlib_base64_binary_digit_string_weighted}
              = defined $weight
              ? binary_to_base64($binary_str_weighted)
              : $out_hash{$individual_id}{zlib_base64_binary_digit_string};
        }

    }
    return \%out_hash;
}

sub binary_to_base64 {
    my $binary_string = shift;

    # Convert binary string (e.g. "0010...") to raw bytes
    my $raw_data = pack( "B*", $binary_string );

  # Compress the raw data (note: compressing very short data may not save space)
    my $compressed = compress($raw_data);

    # Base64 encode the compressed data, without any newline breaks
    return encode_base64( $compressed, "" );
}

sub _base64_to_binary {
    my ( $b64_string, $original_length ) = @_;

    # Decode the Base64 encoded compressed data
    my $compressed_data = decode_base64($b64_string);

    # Decompress the data back to raw bytes
    my $raw_data = uncompress($compressed_data)
      or die "Decompression failed: $Compress::Zlib::gzerrno\n";

    # Convert the raw bytes back into a binary string (sequence of 0s and 1s)
    my $binary_string = unpack( "B*", $raw_data );

    # Trim the binary string to the original length to remove any padded bits
    return substr( $binary_string, 0, $original_length );
}

1;
