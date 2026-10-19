package Peta::Hearing;
# ABSTRACT: the Bark scale, the threshold in quiet, masking

# What the encoders' psychoacoustic models share: the Bark scale, the
# threshold of hearing in quiet, how far masking spreads, and how far below
# a masker noise stays unheard.

use v5.36;

our $VERSION = '0.2610180';

# The offset for noise masking noise, in dB. ISO's model 2 has 6 dB; 2 dB
# more, as quantization rounds much of a noise band to nothing (energy
# lost, not noise added), which 8 dB keeps to about a dB.
use constant NOISE_OFFSET => 8;

# A frequency (Hz) on the Bark scale (Zwicker and Terhardt).
sub bark ($f) {
    return 13 * atan2(0.00076 * $f, 1) + 3.5 * atan2(($f / 7500)**2, 1);
}

# The threshold of hearing in quiet at a frequency, in dB SPL (Terhardt);
# held below 20 Hz and above 16 kHz.
sub quiet ($f) {
    my $k = ($f < 20 ? 20 : $f > 16000 ? 16000 : $f) / 1000;
    return 3.64 * $k**-0.8 - 6.5 * exp(-0.6 * ($k - 3.3)**2) + 0.001 * $k**4;
}

# How much of a masker's energy reaches $dz Bark above it (below, for
# $dz < 0), as an energy factor: Schroeder's spreading function, nothing
# under -60 dB.
sub spreading ($dz) {
    $dz += 0.474;
    my $db = 15.81 + 7.5 * $dz - 17.5 * sqrt(1 + $dz * $dz);
    return $db < -60 ? 0.0 : 10**($db / 10);
}

# How far below a tone at $z Bark noise stays unheard, in dB: 14.5 plus the
# Bark, at most 25.
sub tone_offset ($z) {
    my $db = 14.5 + $z;
    return $db > 25 ? 25 : $db;
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::Hearing - the Bark scale, the threshold in quiet, masking

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    use Peta::Hearing;

    my $z     = Peta::Hearing::bark(1000);           # 8.5
    my $db    = Peta::Hearing::quiet(4000);          # dB SPL, about -5
    my $share = Peta::Hearing::spreading($z1 - $z0); # an energy factor

=head1 DESCRIPTION

The pieces of psychoacoustics that L<Peta::MP3::Encode::Psy> and
L<Peta::Vorbis::Encode::Psy> both build their models from.

=head2 bark

C<bark($hz)>: the frequency on the Bark scale.

=head2 quiet

C<quiet($hz)>: the threshold of hearing in quiet, dB SPL (Terhardt), held
below 20 Hz and above 16 kHz.

=head2 spreading

C<spreading($dz)>: the share of a masker's energy that masks $dz Bark
away from it (Schroeder's spreading function).

=head2 tone_offset

C<tone_offset($z)>: how many dB below a tone at $z Bark noise stays
unheard. C<NOISE_OFFSET> is the same for noise masking noise.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
