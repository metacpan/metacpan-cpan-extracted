package Net::BART::LPM;

use strict;
use warnings;
use Net::BART::BitSet256;
use Exporter 'import';

our $VERSION = '0.01';

our @EXPORT_OK = qw(@LOOKUP_TBL);

# Precomputed lookup table: for each base index [0..255], LOOKUP_TBL[idx]
# is a BitSet256 with idx and all its ancestors in the complete binary tree set.
#
# Ancestors are found by repeatedly right-shifting the index:
#   idx -> idx>>1 -> idx>>2 -> ... -> 1
#
# Used for O(1) longest-prefix-match at each trie node:
#   intersection_top(node.prefixes.bitset, LOOKUP_TBL[octet_to_idx(octet)])

our @LOOKUP_TBL;

sub _generate_lookup_tbl {
    for my $idx (0 .. 255) {
        my $bs = Net::BART::BitSet256->new;
        my $i = $idx;
        while ($i > 0) {
            $bs->set($i);
            $i >>= 1;
        }
        $LOOKUP_TBL[$idx] = $bs;
    }
}

_generate_lookup_tbl();

1;
