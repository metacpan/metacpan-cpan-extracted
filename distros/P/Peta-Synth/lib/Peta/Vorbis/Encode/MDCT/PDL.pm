package Peta::Vorbis::Encode::MDCT::PDL;
# ABSTRACT: Vorbis' MDCT with PDL

# The MDCT of Peta::Vorbis::Encode::MDCT in PDL: the same steps, as
# whole-array operations on all channels of a block at once.
#
#   fold       the windowed block's quarters, reversed where they must be,
#              added into the DCT-IV's n/2 inputs
#   rotate     those as n/4 complex values, times the pre-rotation
#   FFT        PDL::FFT's, of n/4 points
#   rotate     times the post-rotation, even outputs forward, odd ones back

use v5.36;

# PDL exports dozens of functions into a package; they go to one of their
# own, and this one calls PDL by name.
{
    package Peta::Vorbis::Encode::MDCT::PDL::Imports;
    use PDL::LiteF;
    use PDL::FFT ();
}

use Peta::Vorbis::Encode::MDCT;

our $VERSION = '0.2610180';

sub new ($class, $n, $scale = 1.0) {
    my @pre  = Peta::Vorbis::Encode::MDCT::pre_angles($n);
    my @post = Peta::Vorbis::Encode::MDCT::post_angles($n);
    my $pdl  = sub (@list) { PDL->pdl(PDL::double(), \@list) };

    return bless {
        n       => $n,
        scale   => $scale,
        pre_c   => $pdl->(map { cos $_ } @pre),
        pre_s   => $pdl->(map { sin $_ } @pre),
        post_c  => $pdl->(map { cos($_) * $scale } @post),
        post_s  => $pdl->(map { sin($_) * $scale } @post),
        windows => {},    # each window's piddle, by its array
    }, $class;
}

# The coefficients of a block of n samples, windowed with $w.
sub transform ($self, $x, $w) { return ($self->transform_all([$x], $w))[0] }

# The coefficients of each channel's block of n samples, all windowed with
# $w: one array reference per channel.
sub transform_all ($self, $channels, $w) {
    my $n = $self->{n};
    my $m = $n / 2;
    my $h = $m / 2;
    # Windows kept by the array they came from (held, so its address is not
    # another's later).
    my $window = ($self->{windows}{$w} //= [ $w, PDL->pdl(PDL::double(), $w) ])->[1];
    my $y = PDL->pdl(PDL::double(), $channels) * $window;    # (n, channels)

    my $v = PDL->zeroes(PDL::double(), $m, scalar @$channels);
    $v->slice('0:' . ($h - 1)) .= -$y->slice((3 * $h - 1) . ':' . (2 * $h)) - $y->slice((3 * $h) . ':' . ($n - 1));
    $v->slice("$h:" . ($m - 1)) .= $y->slice('0:' . ($h - 1)) - $y->slice((2 * $h - 1) . ":$h");

    my $a = $v->slice('0:' . ($m - 2) . ':2');
    my $b = $v->slice(($m - 1) . ':1:-2');
    my $re = $a * $self->{pre_c} - $b * $self->{pre_s};
    my $im = $a * $self->{pre_s} + $b * $self->{pre_c};
    PDL::FFT::fft($re, $im);

    my $out = PDL->zeroes(PDL::double(), $m, scalar @$channels);
    $out->slice('0:' . ($m - 2) . ':2') .= $re * $self->{post_c} - $im * $self->{post_s};
    $out->slice(($m - 1) . ':1:-2') .= -($re * $self->{post_s} + $im * $self->{post_c});
    my @all = $out->list;
    return map { [ @all[ $_ * $m .. ($_ + 1) * $m - 1 ] ] } 0 .. $#$channels;
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::Vorbis::Encode::MDCT::PDL - Vorbis' MDCT with PDL

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    my $mdct = Peta::Vorbis::Encode::MDCT::PDL->new(2048, $scale);
    my ($left, $right) = $mdct->transform_all([ \@left, \@right ], $window);

=head1 DESCRIPTION

What L<Peta::Vorbis::Encode::MDCT> computes, through PDL::FFT; the same
coefficients to rounding. C<transform_all> transforms several channels'
blocks in one go.

=head1 METHODS

=head2 new, transform, transform_all

As L<Peta::Vorbis::Encode::MDCT>'s.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
