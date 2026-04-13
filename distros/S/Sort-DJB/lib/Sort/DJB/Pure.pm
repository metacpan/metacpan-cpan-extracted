package Sort::DJB::Pure;

use strict;
use warnings;

our $VERSION = '0.2';

# Pure Perl implementation of the djbsort bitonic sorting network algorithm.
# This is a direct translation of djbsort's portable4/sort.c.

sub _minmax {
    # Swap so that $_[0] <= $_[1]
    if ($_[0] > $_[1]) {
        @_[0, 1] = @_[1, 0];
    }
}

sub _int_sort {
    my ($x) = @_;
    my $n = scalar @$x;

    return if $n < 2;

    my $top = 1;
    while ($top < $n - $top) {
        $top += $top;
    }

    for (my $p = $top; $p >= 1; $p >>= 1) {
        my $i = 0;
        while ($i + 2 * $p <= $n) {
            for (my $j = $i; $j < $i + $p; ++$j) {
                _minmax($x->[$j], $x->[$j + $p]);
            }
            $i += 2 * $p;
        }
        for (my $j = $i; $j < $n - $p; ++$j) {
            _minmax($x->[$j], $x->[$j + $p]);
        }

        $i = 0;
        my $j = 0;
        QLOOP:
        for (my $q = $top; $q > $p; $q >>= 1) {
            if ($j != $i) {
                for (;;) {
                    last QLOOP if $j == $n - $q;
                    my $a = $x->[$j + $p];
                    for (my $r = $q; $r > $p; $r >>= 1) {
                        if ($a > $x->[$j + $r]) {
                            ($a, $x->[$j + $r]) = ($x->[$j + $r], $a);
                        }
                    }
                    $x->[$j + $p] = $a;
                    ++$j;
                    if ($j == $i + $p) {
                        $i += 2 * $p;
                        last;
                    }
                }
            }
            while ($i + $p <= $n - $q) {
                for (my $jj = $i; $jj < $i + $p; ++$jj) {
                    my $a = $x->[$jj + $p];
                    for (my $r = $q; $r > $p; $r >>= 1) {
                        if ($a > $x->[$jj + $r]) {
                            ($a, $x->[$jj + $r]) = ($x->[$jj + $r], $a);
                        }
                    }
                    $x->[$jj + $p] = $a;
                }
                $i += 2 * $p;
            }
            # now i + p > n - q
            $j = $i;
            while ($j < $n - $q) {
                my $a = $x->[$j + $p];
                for (my $r = $q; $r > $p; $r >>= 1) {
                    if ($a > $x->[$j + $r]) {
                        ($a, $x->[$j + $r]) = ($x->[$j + $r], $a);
                    }
                }
                $x->[$j + $p] = $a;
                ++$j;
            }
        }
    }
}

sub sort_int32 {
    my ($aref) = @_;
    my @copy = @$aref;
    # Clamp to int32 range
    for my $v (@copy) {
        $v = int($v);
        $v = -2147483648 if $v < -2147483648;
        $v =  2147483647 if $v >  2147483647;
    }
    _int_sort(\@copy);
    return \@copy;
}

sub sort_int32down {
    my ($aref) = @_;
    my @copy = @$aref;
    for my $v (@copy) {
        $v = int($v);
        $v = -2147483648 if $v < -2147483648;
        $v =  2147483647 if $v >  2147483647;
    }
    # XOR with -1 (bitwise NOT) to reverse order, sort, then undo
    # In Perl we just reverse the comparison by negating
    $_ = ~$_ & 0xFFFFFFFF for @copy;
    # Treat as signed int32 after XOR
    for my $v (@copy) {
        $v = $v - 4294967296 if $v >= 2147483648;
    }
    _int_sort(\@copy);
    # Undo: XOR with -1 again
    for my $v (@copy) {
        $v = ($v < 0 ? $v + 4294967296 : $v);
        $v = ~$v & 0xFFFFFFFF;
        $v = $v - 4294967296 if $v >= 2147483648;
    }
    return \@copy;
}

sub sort_uint32 {
    my ($aref) = @_;
    my @copy = @$aref;
    for my $v (@copy) {
        $v = int($v) & 0xFFFFFFFF;
        # XOR with sign bit to convert to signed for sorting
        $v ^= 0x80000000;
        $v = $v - 4294967296 if $v >= 2147483648;
    }
    _int_sort(\@copy);
    # Undo conversion
    for my $v (@copy) {
        $v = ($v < 0 ? $v + 4294967296 : $v);
        $v ^= 0x80000000;
    }
    return \@copy;
}

sub sort_uint32down {
    my ($aref) = @_;
    my @copy = @$aref;
    for my $v (@copy) {
        $v = int($v) & 0xFFFFFFFF;
        # XOR with sign bit, then XOR with -1 for descending
        $v ^= 0x80000000;
        $v = ~$v & 0xFFFFFFFF;
        $v = $v - 4294967296 if $v >= 2147483648;
    }
    _int_sort(\@copy);
    # Undo
    for my $v (@copy) {
        $v = ($v < 0 ? $v + 4294967296 : $v);
        $v = ~$v & 0xFFFFFFFF;
        $v ^= 0x80000000;
    }
    return \@copy;
}

sub sort_int64 {
    my ($aref) = @_;
    my @copy = @$aref;
    for my $v (@copy) {
        $v = int($v);
    }
    _int_sort(\@copy);
    return \@copy;
}

sub sort_int64down {
    my ($aref) = @_;
    my @copy = map { int($_) } @$aref;
    # Negate to reverse, sort, negate back
    $_ = -$_ - 1 for @copy;
    _int_sort(\@copy);
    $_ = -$_ - 1 for @copy;
    return \@copy;
}

sub sort_uint64 {
    my ($aref) = @_;
    # For uint64, use numeric sort since Perl handles big numbers
    my @copy = map { int($_) } @$aref;
    _int_sort(\@copy);
    return \@copy;
}

sub sort_uint64down {
    my ($aref) = @_;
    my @copy = map { -int($_) - 1 } @$aref;
    _int_sort(\@copy);
    $_ = -$_ - 1 for @copy;
    return \@copy;
}

sub sort_float64 {
    my ($aref) = @_;
    my @copy = map { $_ + 0.0 } @$aref;
    _int_sort(\@copy);
    return \@copy;
}

sub sort_float64down {
    my ($aref) = @_;
    my @copy = map { -($_ + 0.0) } @$aref;
    _int_sort(\@copy);
    $_ = -$_ for @copy;
    return \@copy;
}

sub sort_float32 {
    my ($aref) = @_;
    # Perl doesn't have native float32; use float64 comparison (same order)
    my @copy = map { $_ + 0.0 } @$aref;
    _int_sort(\@copy);
    return \@copy;
}

sub sort_float32down {
    my ($aref) = @_;
    my @copy = map { -($_ + 0.0) } @$aref;
    _int_sort(\@copy);
    $_ = -$_ for @copy;
    return \@copy;
}

1;

__END__

=head1 NAME

Sort::DJB::Pure - Pure Perl implementation of the djbsort bitonic sorting network

=head1 DESCRIPTION

This module implements the same bitonic sorting network algorithm used by
djbsort, but entirely in Perl. It is useful for portability (no C compiler
needed) and for benchmarking comparisons against the C implementation.

The algorithm is O(n log^2 n) comparisons using a sorting network derived
from bitonic merge-exchange (Lang 1998).

=cut
