package Test::HTTP2::HPACK;

use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(
    encode_headers
    encode_integer
    encode_string
);

our %EXPORT_TAGS = (all => \@EXPORT_OK);

# HPACK Static Table (RFC 7541 Appendix A)
# Index => [name, value]
my @STATIC_TABLE = (
    undef,  # Index 0 is unused
    [':authority', ''],
    [':method', 'GET'],
    [':method', 'POST'],
    [':path', '/'],
    [':path', '/index.html'],
    [':scheme', 'http'],
    [':scheme', 'https'],
    [':status', '200'],
    [':status', '204'],
    [':status', '206'],
    [':status', '304'],
    [':status', '400'],
    [':status', '404'],
    [':status', '500'],
    ['accept-charset', ''],
    ['accept-encoding', 'gzip, deflate'],
    ['accept-language', ''],
    ['accept-ranges', ''],
    ['accept', ''],
    ['access-control-allow-origin', ''],
    ['age', ''],
    ['allow', ''],
    ['authorization', ''],
    ['cache-control', ''],
    ['content-disposition', ''],
    ['content-encoding', ''],
    ['content-language', ''],
    ['content-length', ''],
    ['content-location', ''],
    ['content-range', ''],
    ['content-type', ''],
    ['cookie', ''],
    ['date', ''],
    ['etag', ''],
    ['expect', ''],
    ['expires', ''],
    ['from', ''],
    ['host', ''],
    ['if-match', ''],
    ['if-modified-since', ''],
    ['if-none-match', ''],
    ['if-range', ''],
    ['if-unmodified-since', ''],
    ['last-modified', ''],
    ['link', ''],
    ['location', ''],
    ['max-forwards', ''],
    ['proxy-authenticate', ''],
    ['proxy-authorization', ''],
    ['range', ''],
    ['referer', ''],
    ['refresh', ''],
    ['retry-after', ''],
    ['server', ''],
    ['set-cookie', ''],
    ['strict-transport-security', ''],
    ['transfer-encoding', ''],
    ['user-agent', ''],
    ['vary', ''],
    ['via', ''],
    ['www-authenticate', ''],
);

# Build index by name for faster lookup
my %STATIC_INDEX_BY_NAME;
my %STATIC_INDEX_BY_NAME_VALUE;
for my $i (1 .. $#STATIC_TABLE) {
    my ($name, $value) = @{$STATIC_TABLE[$i]};
    $STATIC_INDEX_BY_NAME{$name} //= $i;
    $STATIC_INDEX_BY_NAME_VALUE{"$name\0$value"} = $i if $value ne '';
}

# Encode an integer with a given prefix size (RFC 7541 Section 5.1)
sub encode_integer {
    my ($value, $prefix_bits) = @_;
    my $max_prefix = (1 << $prefix_bits) - 1;

    if ($value < $max_prefix) {
        return pack("C", $value);
    }

    my $result = pack("C", $max_prefix);
    $value -= $max_prefix;

    while ($value >= 128) {
        $result .= pack("C", ($value & 0x7F) | 0x80);
        $value >>= 7;
    }
    $result .= pack("C", $value);

    return $result;
}

# Encode a string (RFC 7541 Section 5.2)
# For simplicity, we use literal encoding (not Huffman)
sub encode_string {
    my ($string, $huffman) = @_;
    $huffman //= 0;

    if ($huffman) {
        # TODO: Implement Huffman encoding if needed
        die "Huffman encoding not implemented";
    }

    my $length = encode_integer(length($string), 7);
    return $length . $string;
}

# Encode a header field as "Literal Header Field without Indexing"
# (RFC 7541 Section 6.2.2)
sub encode_literal_header {
    my ($name, $value) = @_;

    # Check if name is in static table
    my $name_index = $STATIC_INDEX_BY_NAME{$name};

    if ($name_index) {
        # Use indexed name
        my $result = pack("C", 0x00);  # Literal without indexing, name index follows
        # Encode the name index with 4-bit prefix
        if ($name_index < 16) {
            $result = pack("C", $name_index);  # 0000xxxx
        } else {
            $result = encode_integer($name_index, 4);
        }
        $result .= encode_string($value);
        return $result;
    } else {
        # Literal name
        my $result = pack("C", 0x00);  # 0000 0000 = literal name follows
        $result .= encode_string($name);
        $result .= encode_string($value);
        return $result;
    }
}

# Encode a header using indexed representation if possible
sub encode_indexed_header {
    my ($name, $value) = @_;

    # Check for exact match in static table
    my $key = "$name\0$value";
    if (my $index = $STATIC_INDEX_BY_NAME_VALUE{$key}) {
        # Indexed Header Field (RFC 7541 Section 6.1)
        # 1xxxxxxx
        if ($index < 127) {
            return pack("C", 0x80 | $index);
        } else {
            my $result = pack("C", 0xFF);  # 0x80 | 0x7F
            my $remaining = $index - 127;
            while ($remaining >= 128) {
                $result .= pack("C", ($remaining & 0x7F) | 0x80);
                $remaining >>= 7;
            }
            $result .= pack("C", $remaining);
            return $result;
        }
    }

    # Use literal with indexing for common headers we want in dynamic table
    # Or literal without indexing for others
    return encode_literal_header($name, $value);
}

# Encode a list of headers to HPACK format
# Headers is an arrayref of [name, value] pairs
sub encode_headers {
    my ($headers, %opts) = @_;
    my $use_indexing = $opts{indexing} // 0;

    my $result = '';

    for my $header (@$headers) {
        my ($name, $value) = @$header;

        # Lowercase header names (HTTP/2 requirement)
        $name = lc($name);

        if ($use_indexing) {
            $result .= encode_indexed_header($name, $value);
        } else {
            $result .= encode_literal_header($name, $value);
        }
    }

    return $result;
}

1;

__END__

=head1 NAME

Test::HTTP2::HPACK - Simple HPACK encoder for testing

=head1 SYNOPSIS

    use Test::HTTP2::HPACK qw(encode_headers);

    my $header_block = encode_headers([
        [':method', 'GET'],
        [':path', '/'],
        [':scheme', 'https'],
        [':authority', 'example.com'],
    ]);

=head1 DESCRIPTION

This module provides a simple HPACK encoder for testing HTTP/2
implementations. It supports:

- Literal Header Field without Indexing
- Indexed Header Field (for static table entries)
- Integer encoding with arbitrary prefix sizes
- String encoding (literal, no Huffman)

This is NOT a full HPACK implementation and should only be used
for testing purposes.

=cut
