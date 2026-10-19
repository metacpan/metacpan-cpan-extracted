package Peta::Vorbis::Encode::Psy;
# ABSTRACT: how coarsely each MDCT bin may be quantized

# How much noise each MDCT bin of a block can take unheard, as a
# quantization step: the step s whose noise (s^2 / 12) is what the bin may
# take. The model of Peta::MP3::Encode::Psy, on Vorbis' bins:
#
#   bands      the bins grouped by Bark, one band per Bark
#   spreading  every band's energy masks its neighbours (Schroeder)
#   offset     the noise may come that far below the spread energy: for a
#              tone masking noise 14.5 dB plus the Bark, at most 25 dB; for
#              noise masking noise 8 dB; between them by the band's
#              tonality; plus 2 dB per step of quality above 5 (less below)
#   tonality   by the band's spectral flatness (the geometric mean of its
#              bins' energies against their mean): noise is at about -5 dB,
#              a band holding a tone at -15 dB or less. Flatter than -6 dB
#              is noise, below -16 dB a tone, linear between. A band of
#              fewer than eight bins cannot tell (a tone in four bins often
#              looks as flat as noise), and counts as a tone.
#   quiet      never below the threshold of hearing in quiet (Terhardt)
#
# The level of a full-scale sine in this transform's units is measured by
# the encoder, not assumed, and taken to sound at 92 dB SPL.

use v5.36;
use Peta::Hearing;

our $VERSION = '0.2610180';

use constant FULL_SCALE_SPL => 92;
use constant NOISE          => Peta::Hearing::NOISE_OFFSET;

# $bins bins of a block at $rate; $full the energy of a full-scale sine in them.
sub new ($class, $rate, $bins, $quality, $full) {
    my $width = $rate / 2 / $bins;
    my @band  = map { int Peta::Hearing::bark(($_ + 0.5) * $width) } 0 .. $bins - 1;
    my $count = $band[-1] + 1;

    # Each band's bins, lo .. hi - 1. A band no bin falls in (none at these
    # rates) is kept, empty.
    my (@lo, @hi);
    for my $i (0 .. $bins - 1) {
        $lo[ $band[$i] ] //= $i;
        $hi[ $band[$i] ] = $i + 1;
    }
    for my $b (0 .. $count - 1) {
        $lo[$b] //= $hi[$b - 1] // 0;
        $hi[$b] //= $lo[$b];
    }

    # The quietest audible across each band, as an energy in the bins; a
    # tone's masking offset at its middle; the spreading from every band to
    # every other, SPREAD[count to + from].
    my (@quiet, @tone);
    for my $b (0 .. $count - 1) {
        my $least = 1e9;
        for my $i ($lo[$b] .. $hi[$b] - 1) {
            my $db = Peta::Hearing::quiet(($i + 0.5) * $width);
            $least = $db if $db < $least;
        }
        push @quiet, $full * 10**(($least - FULL_SCALE_SPL) / 10);
        push @tone, Peta::Hearing::tone_offset($b + 0.5);
    }
    my @spread;
    for my $to (0 .. $count - 1) {
        push @spread, map { Peta::Hearing::spreading($to - $_) } 0 .. $count - 1;
    }

    return bless {
        bins   => $bins,
        count  => $count,
        lo     => \@lo,
        hi     => \@hi,
        quiet  => \@quiet,
        tone   => \@tone,
        spread => \@spread,
        adjust => 2 * ($quality - 5),    # dB more or less below the masking
    }, $class;
}

# The step each bin may be quantized with: an array reference.
sub steps ($self, $x) {
    my $count  = $self->{count};
    my $adjust = $self->{adjust};
    my @lo     = @{ $self->{lo} };
    my @hi     = @{ $self->{hi} };
    my @tone   = @{ $self->{tone} };
    my @energy = (0.0) x $count;
    my @offset = (0.0) x $count;

    for my $b (0 .. $count - 1) {
        my ($sum, $logs) = (0.0, 0.0);
        my $k = $hi[$b] - $lo[$b];
        for my $i ($lo[$b] .. $hi[$b] - 1) {
            my $e = $x->[$i] * $x->[$i];
            $sum  += $e;
            $logs += log($e + 1e-30) if $k >= 8;
        }
        $energy[$b] = $sum;

        # How tonal the band is, 0 (noise) to 1, from its flatness in dB.
        my $tonal = 1.0;
        if ($k >= 8 && $sum > 0) {
            my $flat = 4.342944819032518 * ($logs / $k - log($sum / $k));
            $tonal = (-6 - $flat) / 10;
            $tonal = 0.0 if $tonal < 0;
            $tonal = 1.0 if $tonal > 1;
        }

        my $db = $tonal * $tone[$b] + (1 - $tonal) * NOISE + $adjust;
        $db = 0 if $db < 0;    # never noise louder than what masks it
        $offset[$b] = 10**(-$db / 10);
    }

    # Each band masked by the spread energy of all, never below quiet; its
    # step shared by its bins.
    my @spread = @{ $self->{spread} };
    my @quiet  = @{ $self->{quiet} };
    my @step   = (0.0) x $self->{bins};
    for my $b (0 .. $count - 1) {
        my $masked = 0.0;
        my $row    = $b * $count;
        for my $from (0 .. $count - 1) { $masked += $energy[$from] * $spread[ $row + $from ] }
        $masked *= $offset[$b];
        $masked = $quiet[$b] if $masked < $quiet[$b];

        my $width = $hi[$b] - $lo[$b] || 1;
        my $s     = sqrt(12 * $masked / $width);
        $step[$_] = $s for $lo[$b] .. $hi[$b] - 1;
    }
    return \@step;
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::Vorbis::Encode::Psy - how coarsely each MDCT bin may be quantized

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    my $psy  = Peta::Vorbis::Encode::Psy->new(48000, 1024, $quality, $full_scale_energy);
    my $step = $psy->steps($coefficients);

=head1 DESCRIPTION

A simple psychoacoustic model on a block's own MDCT bins, made from the
pieces in L<Peta::Hearing>: the steps the quantization may take, bin by
bin.

=head1 METHODS

=head2 new

C<new($rate, $bins, $quality, $full)>: the model for blocks of C<$bins>
bins at C<$rate>, C<$full> the energy of a full-scale sine in them.

=head2 steps

C<steps(\@bins)>: the step each bin may be quantized with.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
