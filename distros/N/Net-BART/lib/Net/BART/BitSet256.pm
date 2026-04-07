package Net::BART::BitSet256;

use strict;
use warnings;

our $VERSION = '0.01';

# A 256-bit bitset stored as 4 x 64-bit unsigned integers.
# Bit layout: word 0 = bits 0-63, word 1 = bits 64-127,
#             word 2 = bits 128-191, word 3 = bits 192-255.

# Precomputed byte popcount table (0..255)
my @BYTE_POPCNT;
for my $i (0 .. 255) {
    my $c = 0;
    my $v = $i;
    while ($v) { $v &= ($v - 1); $c++ }
    $BYTE_POPCNT[$i] = $c;
}

# Precomputed bit_len for bytes (0..255)
my @BYTE_LEN;
$BYTE_LEN[0] = 0;
for my $i (1 .. 255) {
    $BYTE_LEN[$i] = $BYTE_LEN[$i >> 1] + 1;
}

sub new {
    return bless [0, 0, 0, 0], $_[0];
}

sub clone {
    return bless [@{$_[0]}], ref($_[0]);
}

sub set {
    $_[0]->[$_[1] >> 6] |= (1 << ($_[1] & 63));
}

sub clear {
    $_[0]->[$_[1] >> 6] &= ~(1 << ($_[1] & 63));
}

sub test {
    return ($_[0]->[$_[1] >> 6] & (1 << ($_[1] & 63))) ? 1 : 0;
}

sub is_empty {
    return !($_[0]->[0] | $_[0]->[1] | $_[0]->[2] | $_[0]->[3]);
}

# Fast popcount using byte lookup table
sub _popcount64 {
    my $x = $_[0];
    return $BYTE_POPCNT[ $x        & 0xFF] +
           $BYTE_POPCNT[($x >>  8) & 0xFF] +
           $BYTE_POPCNT[($x >> 16) & 0xFF] +
           $BYTE_POPCNT[($x >> 24) & 0xFF] +
           $BYTE_POPCNT[($x >> 32) & 0xFF] +
           $BYTE_POPCNT[($x >> 40) & 0xFF] +
           $BYTE_POPCNT[($x >> 48) & 0xFF] +
           $BYTE_POPCNT[($x >> 56) & 0xFF];
}

# Rank: count of set bits in positions 0..idx (inclusive).
# Fully inlined for speed - this is the hottest function.
sub rank {
    my $self = $_[0];
    my $idx  = $_[1];
    my $word = $idx >> 6;
    my $bit  = $idx & 63;

    my $count = 0;

    # Unrolled loop for words before target
    if ($word > 0) {
        my $x = $self->[0];
        $count += $BYTE_POPCNT[ $x        & 0xFF] + $BYTE_POPCNT[($x >>  8) & 0xFF] +
                  $BYTE_POPCNT[($x >> 16) & 0xFF] + $BYTE_POPCNT[($x >> 24) & 0xFF] +
                  $BYTE_POPCNT[($x >> 32) & 0xFF] + $BYTE_POPCNT[($x >> 40) & 0xFF] +
                  $BYTE_POPCNT[($x >> 48) & 0xFF] + $BYTE_POPCNT[($x >> 56) & 0xFF];
        if ($word > 1) {
            $x = $self->[1];
            $count += $BYTE_POPCNT[ $x        & 0xFF] + $BYTE_POPCNT[($x >>  8) & 0xFF] +
                      $BYTE_POPCNT[($x >> 16) & 0xFF] + $BYTE_POPCNT[($x >> 24) & 0xFF] +
                      $BYTE_POPCNT[($x >> 32) & 0xFF] + $BYTE_POPCNT[($x >> 40) & 0xFF] +
                      $BYTE_POPCNT[($x >> 48) & 0xFF] + $BYTE_POPCNT[($x >> 56) & 0xFF];
            if ($word > 2) {
                $x = $self->[2];
                $count += $BYTE_POPCNT[ $x        & 0xFF] + $BYTE_POPCNT[($x >>  8) & 0xFF] +
                          $BYTE_POPCNT[($x >> 16) & 0xFF] + $BYTE_POPCNT[($x >> 24) & 0xFF] +
                          $BYTE_POPCNT[($x >> 32) & 0xFF] + $BYTE_POPCNT[($x >> 40) & 0xFF] +
                          $BYTE_POPCNT[($x >> 48) & 0xFF] + $BYTE_POPCNT[($x >> 56) & 0xFF];
            }
        }
    }

    # Masked popcount of the target word
    my $masked = ($bit == 63) ? $self->[$word] : ($self->[$word] & ((1 << ($bit + 1)) - 1));
    $count += $BYTE_POPCNT[ $masked        & 0xFF] + $BYTE_POPCNT[($masked >>  8) & 0xFF] +
              $BYTE_POPCNT[($masked >> 16) & 0xFF] + $BYTE_POPCNT[($masked >> 24) & 0xFF] +
              $BYTE_POPCNT[($masked >> 32) & 0xFF] + $BYTE_POPCNT[($masked >> 40) & 0xFF] +
              $BYTE_POPCNT[($masked >> 48) & 0xFF] + $BYTE_POPCNT[($masked >> 56) & 0xFF];

    return $count;
}

# IntersectionTop: find the highest set bit in (self AND other).
# Returns the bit index, or -1 if the intersection is empty.
sub intersection_top {
    my ($self, $other) = @_;
    my $w;

    $w = $self->[3] & $other->[3]; if ($w) { return 192 + _bit_len64($w) - 1 }
    $w = $self->[2] & $other->[2]; if ($w) { return 128 + _bit_len64($w) - 1 }
    $w = $self->[1] & $other->[1]; if ($w) { return  64 + _bit_len64($w) - 1 }
    $w = $self->[0] & $other->[0]; if ($w) { return       _bit_len64($w) - 1 }
    return -1;
}

# Intersects: returns true if (self AND other) is non-empty
sub intersects {
    return (($_[0]->[0] & $_[1]->[0]) |
            ($_[0]->[1] & $_[1]->[1]) |
            ($_[0]->[2] & $_[1]->[2]) |
            ($_[0]->[3] & $_[1]->[3])) ? 1 : 0;
}

# Number of bits needed to represent x (bits.Len64 equivalent).
# Uses byte lookup table for speed.
sub _bit_len64 {
    my $x = $_[0];
    return 0 unless $x;
    if ($x >> 32) {
        my $hi = $x >> 32;
        if ($hi >> 16) {
            return ($hi >> 24) ? 56 + $BYTE_LEN[$hi >> 24] : 48 + $BYTE_LEN[$hi >> 16];
        }
        return ($hi >> 8) ? 40 + $BYTE_LEN[$hi >> 8] : 32 + $BYTE_LEN[$hi];
    }
    if ($x >> 16) {
        return ($x >> 24) ? 24 + $BYTE_LEN[$x >> 24] : 16 + $BYTE_LEN[($x >> 16) & 0xFF];
    }
    return ($x >> 8) ? 8 + $BYTE_LEN[($x >> 8) & 0xFF] : $BYTE_LEN[$x & 0xFF];
}

# Iterate over set bits, calling $callback->($bit) for each
sub each_set_bit {
    my ($self, $callback) = @_;
    for my $i (0, 1, 2, 3) {
        my $w = $self->[$i];
        next unless $w;
        my $base = $i << 6;
        while ($w) {
            my $t = $w & (-$w);  # isolate lowest set bit
            $callback->($base + _bit_len64($t) - 1);
            $w &= ($w - 1);
        }
    }
}

# Total number of set bits
sub popcnt {
    return _popcount64($_[0]->[0]) + _popcount64($_[0]->[1]) +
           _popcount64($_[0]->[2]) + _popcount64($_[0]->[3]);
}

1;
