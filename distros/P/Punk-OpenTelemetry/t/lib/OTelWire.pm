package OTelWire;

use 5.010;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(pb_parse pb_field pb_fields pb_str pb_varint_of);

# A generic protobuf wire-format reader, written from the wire spec alone.
#
# It deliberately shares NO code with the encoder and knows NOTHING about the
# OTLP schema: it walks tag/wire-type/length and hands back what it finds. A
# decoder built out of the encoder's own tables would agree with the encoder's
# own bugs, which is the failure mode this exists to avoid. If these two ever
# disagree, exactly one of them is wrong and the test says which field.
#
# Returns { field_number => [ value, ... ] }, values being:
#   wire 0 (varint)  -> an integer
#   wire 1 (fixed64) -> an 8-byte string, little endian
#   wire 2 (bytes)   -> the raw bytes (parse again for a nested message)
#   wire 5 (fixed32) -> a 4-byte string

sub _varint {
    my ($buf, $pos) = @_;
    my ($v, $shift) = (0, 0);
    while (1) {
        die "truncated varint at $$pos" if $$pos >= length $$buf;
        my $b = ord substr $$buf, $$pos++, 1;
        $v |= ($b & 0x7f) << $shift;
        last unless $b & 0x80;
        $shift += 7;
        die "varint too long at $$pos" if $shift > 63;
    }
    return $v;
}

sub pb_parse {
    my ($buf) = @_;
    my %out;
    my $pos = 0;
    while ($pos < length $buf) {
        my $tag   = _varint(\$buf, \$pos);
        my $field = $tag >> 3;
        my $wire  = $tag & 0x7;
        my $val;
        if    ($wire == 0) { $val = _varint(\$buf, \$pos) }
        elsif ($wire == 1) { $val = substr $buf, $pos, 8; $pos += 8 }
        elsif ($wire == 5) { $val = substr $buf, $pos, 4; $pos += 4 }
        elsif ($wire == 2) {
            my $len = _varint(\$buf, \$pos);
            die "truncated field $field: want $len, have "
                . (length($buf) - $pos) if $pos + $len > length $buf;
            $val = substr $buf, $pos, $len;
            $pos += $len;
        }
        else { die "unknown wire type $wire for field $field" }
        push @{ $out{$field} }, $val;
    }
    return \%out;
}

# the single value of a field, or undef
sub pb_field {
    my ($msg, $field) = @_;
    return undef unless $msg->{$field};
    return $msg->{$field}[0];
}

# every value of a field, as a list
sub pb_fields {
    my ($msg, $field) = @_;
    return @{ $msg->{$field} || [] };
}

# a fixed64 as an integer (little endian)
sub pb_str {
    my ($eight) = @_;
    return undef unless defined $eight && length($eight) == 8;
    my ($lo, $hi) = unpack 'V2', $eight;
    return $hi * 4294967296 + $lo;
}

# encode a varint independently, for the golden vectors
sub pb_varint_of {
    my ($v) = @_;
    my $out = '';
    while ($v >= 0x80) { $out .= chr(($v & 0x7f) | 0x80); $v >>= 7 }
    return $out . chr($v);
}

1;
