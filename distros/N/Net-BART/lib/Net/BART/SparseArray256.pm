package Net::BART::SparseArray256;

use strict;
use warnings;
use Net::BART::BitSet256;

our $VERSION = '0.01';

# A popcount-compressed sparse array with 256 possible indices.
# Uses a BitSet256 to track which indices are occupied,
# and a compact array holding only the occupied values.
#
# Structure: [$bitset, $items_arrayref]
# Using array-based object for speed over hash.

sub new {
    return bless [Net::BART::BitSet256->new, []], $_[0];
}

sub clone {
    return bless [$_[0]->[0]->clone, [@{$_[0]->[1]}]], ref($_[0]);
}

# Get value at index $i. Returns (value, 1) if present, (undef, 0) if not.
sub get {
    my $bs = $_[0]->[0];
    if ($bs->[$_[1] >> 6] & (1 << ($_[1] & 63))) {
        return ($_[0]->[1][$bs->rank($_[1]) - 1], 1);
    }
    return (undef, 0);
}

# Insert or update value at index $i. Returns 1 if new, 0 if updated.
sub insert_at {
    my ($self, $i, $value) = @_;
    my $bs = $self->[0];
    if ($bs->[$i >> 6] & (1 << ($i & 63))) {
        # Update existing
        $self->[1][$bs->rank($i) - 1] = $value;
        return 0;
    }
    # Insert new
    $bs->set($i);
    my $rank = $bs->rank($i);
    splice(@{$self->[1]}, $rank - 1, 0, $value);
    return 1;
}

# Delete value at index $i. Returns (old_value, 1) or (undef, 0).
sub delete_at {
    my ($self, $i) = @_;
    my $bs = $self->[0];
    if (!($bs->[$i >> 6] & (1 << ($i & 63)))) {
        return (undef, 0);
    }
    my $rank = $bs->rank($i);
    my $old = splice(@{$self->[1]}, $rank - 1, 1);
    $bs->clear($i);
    return ($old, 1);
}

# Test if index $i is occupied (inlined bitset test).
sub test {
    return ($_[0]->[0]->[$_[1] >> 6] & (1 << ($_[1] & 63))) ? 1 : 0;
}

sub len {
    return scalar @{$_[0]->[1]};
}

sub is_empty {
    return !@{$_[0]->[1]};
}

# Iterate over occupied (index, value) pairs in ascending order.
sub each_pair {
    my ($self, $callback) = @_;
    my $items = $self->[1];
    my $pos = 0;
    my $bs = $self->[0];
    for my $i (0, 1, 2, 3) {
        my $w = $bs->[$i];
        next unless $w;
        my $base = $i << 6;
        while ($w) {
            my $t = $w & (-$w);
            $callback->($base + Net::BART::BitSet256::_bit_len64($t) - 1, $items->[$pos]);
            $pos++;
            $w &= ($w - 1);
        }
    }
}

# Direct access to the bitset (for LPM operations).
sub bitset { return $_[0]->[0] }

# Direct access to items array.
sub items { return $_[0]->[1] }

1;
