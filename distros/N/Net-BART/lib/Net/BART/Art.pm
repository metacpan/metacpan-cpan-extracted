package Net::BART::Art;

use strict;
use warnings;
use Exporter 'import';

our $VERSION = '0.01';

our @EXPORT_OK = qw(
    pfx_to_idx
    octet_to_idx
    idx_to_pfx
    pfx_bits
    prefix_decompose
);

# Map a prefix (octet + prefix length within stride 1..7) to a base index [1..255].
sub pfx_to_idx {
    my ($octet, $pfx_len) = @_;
    return ($octet >> (8 - $pfx_len)) + (1 << $pfx_len);
}

# Map a full octet to its /7 index [128..255] for LPM lookup.
sub octet_to_idx {
    my ($octet) = @_;
    return ($octet >> 1) + 128;
}

# Inverse: from base index [1..255] back to (octet, pfx_len).
sub idx_to_pfx {
    my ($idx) = @_;
    my $pfx_len = _bit_len8($idx) - 1;
    my $octet = ($idx - (1 << $pfx_len)) << (8 - $pfx_len);
    return ($octet, $pfx_len);
}

# Total prefix bits at a given trie depth and base index.
sub pfx_bits {
    my ($depth, $idx) = @_;
    return $depth * 8 + (_bit_len8($idx) - 1);
}

# Decompose a prefix length into:
#   $strides  - number of full 8-bit octets consumed
#   $lastbits - remaining prefix bits (0..7) in the final octet
#
# strides = floor(prefix_len / 8), lastbits = prefix_len % 8
#
# If lastbits > 0: traverse strides octets, store prefix at depth strides
# If lastbits == 0 and prefix_len > 0: it's a "fringe" (stride-aligned)
#   traverse strides-1 octets, store fringe child at depth strides-1
# If prefix_len == 0: default route, store at root index 1
sub prefix_decompose {
    my ($prefix_len) = @_;
    return (int($prefix_len / 8), $prefix_len % 8);
}

sub _bit_len8 {
    my ($x) = @_;
    my $n = 0;
    if ($x & 0xF0) { $n += 4; $x >>= 4; }
    if ($x & 0x0C) { $n += 2; $x >>= 2; }
    if ($x & 0x02) { $n += 1; $x >>= 1; }
    $n += $x;
    return $n;
}

1;
