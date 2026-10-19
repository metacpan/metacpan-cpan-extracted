package Peta::Vorbis::Encode::MDCT;
# ABSTRACT: Vorbis' MDCT through an FFT

# The MDCT of a Vorbis block of n samples: n/2 coefficients,
#
#   X[k] = sum_t w[t] x[t] cos(2 pi / n (t + 1/2 + n/4)(k + 1/2)) * SCALE
#
# with Vorbis' window w (the sine of pi/2 times a squared sine), computed
# through a DCT-IV of n/2 points (the windowed block folded in half) and
# that through a complex FFT of n/4 points.
#
# SCALE makes the decoder's inverse give back the samples: 4 / n, as the
# inverse the decoders use is unscaled (measured with FFmpeg's decoder).

use v5.36;

our $VERSION = '0.2610180';

use constant PI => 3.141592653589793;

# The window of a long block lapping long blocks on both sides, or of a
# short one: the slope sin(pi/2 sin^2((t + 1/2) / n pi)) over the whole
# block. (Long blocks next to short ones have narrower slopes: window().)
sub window ($n, $left = $n, $right = $n) {
    my $l0 = $n / 4 - $left / 4;          # where the rising slope starts,
    my $ln = $left / 2;                   # and how long it is
    my $r0 = 3 * $n / 4 - $right / 4;     # the falling slope
    my $rn = $right / 2;

    my @w;
    for my $t (0 .. $n - 1) {
        push @w,
              $t < $l0       ? 0.0
            : $t < $l0 + $ln ? _slope(($t - $l0 + 0.5) / $ln * PI / 2)
            : $t < $r0       ? 1.0
            : $t < $r0 + $rn ? _slope(($t - $r0 + 0.5) / $rn * PI / 2 + PI / 2)
            :                  0.0;
    }
    return \@w;
}

# Vorbis' slope, the sine of pi/2 times a squared sine.
sub _slope ($angle) {
    my $s = sin($angle);
    return sin(PI / 2 * $s * $s);
}

# The angles of the DCT-IV's pre- and post-rotations, for a block of $n:
# n/4 of each.
sub pre_angles ($n)  { return map { -PI * (4 * $_ + 1) / (2 * $n) } 0 .. $n / 4 - 1 }
sub post_angles ($n) { return map { -PI * $_ / ($n / 2) } 0 .. $n / 4 - 1 }

sub new ($class, $n, $scale = 1.0) {
    my $q = $n / 4;
    my $bits = 0;
    $bits++ while (1 << $bits) < $q;

    # The rotations and twiddles as cosine and sine side by side.
    return bless {
        n       => $n,
        scale   => $scale,
        pre     => [ map { (cos($_), sin($_)) } pre_angles($n) ],
        post    => [ map { (cos($_), sin($_)) } post_angles($n) ],
        reverse => [ map { _reversed($_, $bits) } 0 .. $q - 1 ],    # the FFT's input order
        twiddle => [ map { (cos($_), sin($_)) } map { -2 * PI * $_ / $q } 0 .. $q / 2 - 1 ],
    }, $class;
}

# $v with its low $bits bits in reverse order.
sub _reversed ($v, $bits) {
    my $r = 0;
    for (1 .. $bits) {
        $r = ($r << 1) | ($v & 1);
        $v >>= 1;
    }
    return $r;
}

# The coefficients of each channel's block of n samples, all windowed with
# $w: one array reference per channel.
sub transform_all ($self, $channels, $w) { return map { $self->transform($_, $w) } @$channels }

# The coefficients of a block of n samples, windowed with $w.
sub transform ($self, $x, $w) {
    my $n = $self->{n};
    my $m = $n / 2;
    my $h = $m / 2;    # = n/4
    my $scale = $self->{scale};

    # Windowed, and folded into the DCT-IV's m inputs.
    my @v = (0.0) x $m;
    for my $t (0 .. $h - 1) {
        my $a = 3 * $h - 1 - $t;
        my $b = 3 * $h + $t;
        $v[$t] = -$x->[$a] * $w->[$a] - $x->[$b] * $w->[$b];
    }
    for my $t ($h .. $m - 1) {
        my $a = $t - $h;
        my $b = 3 * $h - 1 - $t;
        $v[$t] = $x->[$a] * $w->[$a] - $x->[$b] * $w->[$b];
    }

    # Pre-rotation into n/4 complex values, in bit-reversed order.
    my @pre = @{ $self->{pre} };
    my @rev = @{ $self->{reverse} };
    my @re = (0.0) x $h;
    my @im = (0.0) x $h;
    for my $k (0 .. $h - 1) {
        my $a = $v[ 2 * $k ];
        my $b = $v[ $m - 1 - 2 * $k ];
        my $c = $pre[ 2 * $k ];
        my $s = $pre[ 2 * $k + 1 ];
        my $at = $rev[$k];
        $re[$at] = $a * $c - $b * $s;
        $im[$at] = $a * $s + $b * $c;
    }

    # The FFT: each stage one flat loop over its butterflies.
    my @tw = @{ $self->{twiddle} };
    for (my $len = 2; $len <= $h; $len *= 2) {
        my $half = $len / 2;
        my $stride = $h / $len;
        my ($s, $k) = (0, 0);
        for my $i (0 .. $h / 2 - 1) {
            my $a = $s + $k;
            my $b = $a + $half;
            my $wr = $tw[ 2 * $k * $stride ];
            my $wi = $tw[ 2 * $k * $stride + 1 ];
            my $tr = $re[$b] * $wr - $im[$b] * $wi;
            my $ti = $re[$b] * $wi + $im[$b] * $wr;
            $re[$b] = $re[$a] - $tr;
            $im[$b] = $im[$a] - $ti;
            $re[$a] += $tr;
            $im[$a] += $ti;
            $k++;
            if ($k == $half) { $k = 0; $s += $len }
        }
    }

    # Post-rotation: the DCT-IV's outputs, even ones forward, odd ones back.
    my @post = @{ $self->{post} };
    my @out = (0.0) x $m;
    for my $k (0 .. $h - 1) {
        my $c = $post[ 2 * $k ];
        my $s = $post[ 2 * $k + 1 ];
        $out[ 2 * $k ]          = ($re[$k] * $c - $im[$k] * $s) * $scale;
        $out[ $m - 1 - 2 * $k ] = -($re[$k] * $s + $im[$k] * $c) * $scale;
    }
    return \@out;
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::Vorbis::Encode::MDCT - Vorbis' MDCT through an FFT

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    my $mdct = Peta::Vorbis::Encode::MDCT->new(2048, $scale);
    my $w    = Peta::Vorbis::Encode::MDCT::window(2048);
    my $x    = $mdct->transform(\@samples, $w);    # 1024 coefficients
    my ($l, $r) = $mdct->transform_all([ \@left, \@right ], $w);

=head1 DESCRIPTION

The modified DCT of Vorbis I, as a DCT-IV through a complex FFT of a
quarter of the block, its coefficients scaled by C<$scale>.
L<Peta::Vorbis::Encode::MDCT::PDL> computes the same with PDL::FFT.

=head1 METHODS

=head2 new

C<new($n, $scale = 1)>: the transform of blocks of C<$n> samples.

=head2 transform, transform_all

C<transform(\@x, $w)>: the C<$n / 2> coefficients of a block of C<$n>
samples, windowed with C<$w>; C<transform_all(\@channels, $w)>: those of
each channel's block, one array reference each.

=head1 FUNCTIONS

=head2 window

C<window($n, $left = $n, $right = $n)>: the window of a block of C<$n>,
its slopes C<sin(pi/2 sin^2((t + 1/2) / n pi))> as wide as the blocks it
laps on each side (narrower next to short blocks).

=head2 pre_angles, post_angles

The angles of the DCT-IV's pre- and post-rotations for a block of C<$n>,
C<$n / 4> of each.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
