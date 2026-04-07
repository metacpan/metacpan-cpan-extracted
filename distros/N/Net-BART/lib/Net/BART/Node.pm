package Net::BART::Node;

use strict;
use warnings;
use Net::BART::SparseArray256;

our $VERSION = '0.01';

use Net::BART::Art qw(pfx_to_idx octet_to_idx idx_to_pfx pfx_bits prefix_decompose);

# --- LeafNode: path-compressed leaf storing a full prefix + value ---
# Structure: bless [$addr, $prefix_len, $value], 'Net::BART::Node::Leaf'
# Constants for field access:
use constant { LEAF_ADDR => 0, LEAF_PFXLEN => 1, LEAF_VALUE => 2 };

package Net::BART::Node::Leaf {
    sub new {
        my ($class, %args) = @_;
        return bless [$args{addr}, $args{prefix_len}, $args{value}], $class;
    }

    sub contains_ip {
        my ($self, $ip_bytes) = @_;
        my $pfx = $self->[0];  # addr
        my $pfx_len = $self->[1];
        my $full_bytes = $pfx_len >> 3;  # int($pfx_len / 8)
        for my $i (0 .. $full_bytes - 1) {
            return 0 if $pfx->[$i] != $ip_bytes->[$i];
        }
        my $remaining = $pfx_len & 7;
        if ($remaining) {
            my $mask = (0xFF << (8 - $remaining)) & 0xFF;
            return 0 if ($pfx->[$full_bytes] & $mask) != ($ip_bytes->[$full_bytes] & $mask);
        }
        return 1;
    }

    sub matches_prefix {
        my ($self, $addr, $prefix_len) = @_;
        return 0 if $self->[1] != $prefix_len;
        my $pfx = $self->[0];
        my $full_bytes = $prefix_len >> 3;
        for my $i (0 .. $full_bytes - 1) {
            return 0 if $pfx->[$i] != $addr->[$i];
        }
        my $remaining = $prefix_len & 7;
        if ($remaining) {
            my $mask = (0xFF << (8 - $remaining)) & 0xFF;
            return 0 if ($pfx->[$full_bytes] & $mask) != ($addr->[$full_bytes] & $mask);
        }
        return 1;
    }
}

# --- FringeNode: stride-aligned prefix, value only ---
# Structure: bless [$value], 'Net::BART::Node::Fringe'

package Net::BART::Node::Fringe {
    sub new {
        my ($class, %args) = @_;
        return bless [$args{value}], $class;
    }
}

# --- BartNode: internal trie node ---
# Structure: bless [$prefixes_sparse_array, $children_sparse_array], 'Net::BART::Node::Bart'
use constant { BART_PFX => 0, BART_CHD => 1 };

package Net::BART::Node::Bart {
    sub new {
        return bless [Net::BART::SparseArray256->new, Net::BART::SparseArray256->new], $_[0];
    }

    # Prefix operations - delegate to sparse array
    sub insert_prefix { return $_[0]->[0]->insert_at($_[1], $_[2]) }
    sub delete_prefix { return $_[0]->[0]->delete_at($_[1]) }
    sub get_prefix    { return $_[0]->[0]->get($_[1]) }

    # Child operations
    sub get_child    { return $_[0]->[1]->get($_[1]) }
    sub set_child    { return $_[0]->[1]->insert_at($_[1], $_[2]) }
    sub delete_child { return $_[0]->[1]->delete_at($_[1]) }

    # Longest-prefix-match at this node for the given octet.
    # Returns (value, 1) if found, (undef, 0) if not.
    sub lpm {
        my $self = $_[0];
        my $idx = ($_[1] >> 1) + 128;  # octet_to_idx inlined
        my $pfx_bs = $self->[0][0];    # prefixes sparse array -> bitset
        my $lut = $Net::BART::LPM::LOOKUP_TBL[$idx];

        # intersection_top inlined
        my $w;
        $w = $pfx_bs->[3] & $lut->[3]; if ($w) { return $self->[0]->get(192 + Net::BART::BitSet256::_bit_len64($w) - 1) }
        $w = $pfx_bs->[2] & $lut->[2]; if ($w) { return $self->[0]->get(128 + Net::BART::BitSet256::_bit_len64($w) - 1) }
        $w = $pfx_bs->[1] & $lut->[1]; if ($w) { return $self->[0]->get( 64 + Net::BART::BitSet256::_bit_len64($w) - 1) }
        $w = $pfx_bs->[0] & $lut->[0]; if ($w) { return $self->[0]->get(      Net::BART::BitSet256::_bit_len64($w) - 1) }
        return (undef, 0);
    }

    # Check if any prefix at this node matches the given octet.
    sub lpm_test {
        my $pfx_bs = $_[0]->[0][0];    # prefixes -> bitset
        my $lut = $Net::BART::LPM::LOOKUP_TBL[($_[1] >> 1) + 128];
        return (($pfx_bs->[0] & $lut->[0]) |
                ($pfx_bs->[1] & $lut->[1]) |
                ($pfx_bs->[2] & $lut->[2]) |
                ($pfx_bs->[3] & $lut->[3])) ? 1 : 0;
    }

    sub is_empty {
        return !@{$_[0]->[0][1]} && !@{$_[0]->[1][1]};
    }
}

1;
