package Peta::Synth::FFT;
# ABSTRACT: the discrete Fourier transform: radix 2, in place

# The discrete Fourier transform, for measuring sound (Peta::Synth::Analysis)
# and for making it (Peta::Synth::Wavetable).

use v5.36;

our $VERSION = '0.2610180';

use constant PI => 3.141592653589793;

my %PLAN;    # a plan for each size the transform has been asked for

# What a size of transform needs: the order the input is taken in (each
# index with its bits reversed), and the twiddles, cos and sin of
# -2 pi k / n for k below n / 2.
sub _plan ($n) {
    my $bits = 0;
    $bits++ while (1 << $bits) < $n;
    my @order = map { _reversed($_, $bits) } 0 .. $n - 1;
    my @cos   = map { cos(-2 * PI * $_ / $n) } 0 .. $n / 2 - 1;
    my @sin   = map { sin(-2 * PI * $_ / $n) } 0 .. $n / 2 - 1;
    return [ \@order, \@cos, \@sin ];
}

# $k's lowest $bits bits in the reverse order.
sub _reversed ($k, $bits) {
    my $r = 0;
    for (1 .. $bits) {
        $r = ($r << 1) | ($k & 1);
        $k >>= 1;
    }
    return $r;
}

# The discrete Fourier transform, in place, of a power of two of complex
# numbers (real parts, imaginary parts): radix 2, iterative. The order and
# the twiddles are worked out once a size; the butterflies run on plain
# arrays (what pperl's JIT compiles).
sub fft ($re, $im) {
    my $n = @$re;
    die "an FFT of $n points: not a power of two\n" if $n & ($n - 1);
    my ($order, $cos, $sin) = @{ $PLAN{$n} //= _plan($n) };
    my @o  = @$order;
    my @c  = @$cos;
    my @s  = @$sin;
    my @r  = @$re;
    my @i  = @$im;
    my @pr = (0.0) x $n;
    my @pi = (0.0) x $n;
    for my $k (0 .. $n - 1) {
        $pr[ $o[$k] ] = $r[$k];
        $pi[ $o[$k] ] = $i[$k];
    }
    my $len = 2;
    while ($len <= $n) {
        my $half   = int($len / 2);
        my $stride = int($n / $len);
        my $start  = 0;
        while ($start < $n) {
            my $k = 0;
            while ($k < $half) {
                my $p  = $start + $k;
                my $q  = $p + $half;
                my $wr = $c[ $k * $stride ];
                my $wi = $s[ $k * $stride ];
                my $tr = $pr[$q] * $wr - $pi[$q] * $wi;
                my $ti = $pr[$q] * $wi + $pi[$q] * $wr;
                $pr[$q] = $pr[$p] - $tr;
                $pi[$q] = $pi[$p] - $ti;
                $pr[$p] += $tr;
                $pi[$p] += $ti;
                $k++;
            }
            $start += $len;
        }
        $len *= 2;
    }
    @$re = @pr;
    @$im = @pi;
    return;
}

1;

__END__

=head1 NAME

Peta::Synth::FFT - the discrete Fourier transform: radix 2, in place

=head1 VERSION

version 0.2610180

=head1 FUNCTIONS

=head2 fft

C<fft(\@re, \@im)>: the discrete Fourier transform, in place, of a power of
two of complex numbers (their real and imaginary parts).

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
