package Peta::MP3::Encode::Psy;
# ABSTRACT: how much noise a granule's bands can take

# How much noise each scalefactor band of a granule can take unheard: the
# psychoacoustic model, a simple one. From the granule's own frequency
# lines (no separate FFT):
#
#   energy     per band (and, in a short block, per window)
#   spreading  every band's energy masks its neighbours, by Schroeder's
#              spreading function over the Bark scale
#   offset     the noise may come that far below the spread energy: for a
#              tone masking noise 14.5 dB plus the Bark, at most 25 dB; for
#              noise masking noise 8 dB (NOISE); between them by the
#              band's tonality
#   tonality   by the band's spectral flatness (the geometric mean of its
#              lines' energies against their mean): noise is at about -5
#              dB, a band holding a tone at -13 dB or less. Flatter than -6
#              dB is noise, below -16 dB a tone, linear between. A band of
#              fewer than eight lines cannot tell, and counts as a tone.
#   quiet      never below the threshold of hearing in quiet (Terhardt)
#
# In a short block each window is masked by its own energy only: the quiet
# windows before an attack keep their noise low, which is what short
# blocks are for.
#
# Also here: whether a granule has an attack, for choosing short blocks.
#
# A sine of full scale has an energy of about 1 in a long granule's lines,
# and is taken to sound at 92 dB SPL.

use v5.36;
use List::Util qw(max);
use Peta::Hearing;
use Peta::MP3::Encode::Tables;

our $VERSION = '0.2610180';

use constant FULL_SCALE_SPL => 92;     # dB SPL of a full-scale sine
use constant ATTACK         => 10;     # a segment this many times louder than those before it
use constant AUDIBLE        => 1e-6;   # and at least this loud (energy per sample)
use constant NOISE          => Peta::Hearing::NOISE_OFFSET;

use constant SHORT => 2;    # the block type of short blocks

sub new ($class, $rate) {
    my $bands = $Peta::MP3::Encode::Tables::BANDS{$rate} // die "no scalefactor bands for $rate Hz\n";

    # Long blocks have 576 lines; short ones 192 a window, each three times
    # as wide, where a sine's line has a third of the energy.
    return bless {
        long     => _bands($bands->{long},  $rate / 2 / 576, 1),
        short    => _bands($bands->{short}, $rate / 2 / 192, 1 / 3),
        energies => [ (0.0) x 8 ],    # the last eight segments', for attacks
        tail     => [],               # each channel's last sample
    }, $class;
}

# What the model needs of a set of scalefactor bands: their edges (in
# lines $width Hz wide), the threshold in quiet as an energy in the lines,
# the masking offset of a tone, and the spreading from every band to every
# other.
sub _bands ($edges, $width, $scale) {
    my (@bark, @quiet, @tone);
    for my $b (0 .. $#$edges - 1) {
        my $lo = $edges->[$b] * $width;
        my $hi = $edges->[$b + 1] * $width;
        push @bark, Peta::Hearing::bark(($lo + $hi) / 2);
        push @tone, Peta::Hearing::tone_offset($bark[-1]);

        # The quietest audible across the band.
        my $least = 1e9;
        for (my $f = $lo + $width / 2; $f < $hi; $f += $width) {
            my $db = Peta::Hearing::quiet($f);
            $least = $db if $db < $least;
        }
        push @quiet, $scale * 10**(($least - FULL_SCALE_SPL) / 10);
    }

    # The spreading from every band to every other: SPREAD[count to + from].
    my @spread;
    for my $to (0 .. $#bark) {
        push @spread, map { Peta::Hearing::spreading($bark[$to] - $_) } @bark;
    }

    return {
        edges  => $edges,
        count  => scalar @bark,
        quiet  => \@quiet,
        tone   => \@tone,
        spread => \@spread,
    };
}

sub _clamp ($x, $low, $high) {
    return $low  if $x < $low;
    return $high if $x > $high;
    return $x;
}

# The noise each band may take: an array reference, one per long band; in a
# short block one per band and window, 3 b + w.
sub allowed ($self, $xr, $type) {
    return _masked($self->{long}, $xr, 0, 1) if $type != SHORT;

    my @allowed;
    for my $w (0 .. 2) {
        my $one = _masked($self->{short}, $xr, $w, 3);
        $allowed[ 3 * $_ + $w ] = $one->[$_] for 0 .. $#$one;
    }
    return \@allowed;
}

# The noise allowed in each band of one window: $windows 1 for a long
# block; for a short one 3, its windows' lines side by side, window $w of
# band b being lines 3 edge[b] + w width onwards.
sub _masked ($set, $xr, $w, $windows) {
    my @edges  = @{ $set->{edges} };
    my $count  = $set->{count};
    my @spread = @{ $set->{spread} };
    my @tone   = @{ $set->{tone} };
    my @energy = (0.0) x $count;
    my @offset = (0.0) x $count;
    for my $b (0 .. $count - 1) {
        my $width = $edges[$b + 1] - $edges[$b];
        my $lo    = $windows * $edges[$b] + $w * $width;
        my ($sum, $logs) = (0.0, 0.0);
        for my $i ($lo .. $lo + $width - 1) {
            my $e = $xr->[$i] * $xr->[$i];
            $sum  += $e;
            $logs += log($e + 1e-30) if $width >= 8;
        }
        $energy[$b] = $sum;

        # How tonal the band is, 0 (noise) to 1, from its flatness in dB.
        # A band too narrow to tell counts as a tone.
        my $tonal = 1.0;
        if ($width >= 8 && $sum > 0) {
            my $flat = 4.342944819032518 * ($logs / $width - log($sum / $width));
            $tonal = _clamp((-6 - $flat) / 10, 0.0, 1.0);
        }
        $offset[$b] = 10**(-($tonal * $tone[$b] + (1 - $tonal) * NOISE) / 10);
    }

    # Each band masked by the spread energy of all, never below quiet.
    my @quiet   = @{ $set->{quiet} };
    my @allowed = (0.0) x $count;
    for my $to (0 .. $count - 1) {
        my $masked = 0.0;
        my $row = $to * $count;
        for my $from (0 .. $count - 1) { $masked += $energy[$from] * $spread[ $row + $from ] }
        $masked *= $offset[$to];
        $allowed[$to] = $masked > $quiet[$to] ? $masked : $quiet[$to];
    }
    return \@allowed;
}

# Whether a granule's samples (one array reference per channel) have an
# attack: in segments of 64 samples, the energy of the changes from sample
# to sample (what is high in pitch, where pre-echo is heard), against the
# loudest of the eight segments before. Called once per granule, in order.
#
# Two answers: an attack early in the granule (its first 192 samples), and
# one later. The filterbank delays the sound by about 240 samples, and the
# short windows of the MDCT of granule k cover the samples from 624 before
# its start to 144 after it: an early attack is short granule k's own, a
# later one the next granule's.
sub attack ($self, @channels) {
    my @seen = @{ $self->{energies} };
    my $tail = $self->{tail};
    my ($early, $late) = (0, 0);
    for my $s (0 .. 8) {
        my $energy = 0.0;
        for my $c (0 .. $#channels) {
            my $samples = $channels[$c];
            my $previous = $s == 0 ? ($tail->[$c] // 0.0) : $samples->[ 64 * $s - 1 ];
            for my $i (64 * $s .. 64 * $s + 63) {
                my $d = $samples->[$i] - $previous;
                $energy += $d * $d;
                $previous = $samples->[$i];
            }
        }
        if ($energy > ATTACK * max(@seen) && $energy > AUDIBLE * 64) {
            if ($s < 3) { $early = 1 } else { $late = 1 }
        }
        shift @seen;
        push @seen, $energy;
    }
    $self->{energies} = \@seen;
    $tail->[$_] = $channels[$_][-1] for 0 .. $#channels;
    return ($early, $late);
}

1;

__END__

=encoding utf-8

=head1 NAME

Peta::MP3::Encode::Psy - how much noise a granule's bands can take

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    my $psy = Peta::MP3::Encode::Psy->new(44100);
    my $allowed = $psy->allowed($xr, $block_type);   # per band (and window)
    my ($early, $late) = $psy->attack(\@left, \@right);   # a granule's samples

=head1 DESCRIPTION

A simple psychoacoustic model on the granule's own frequency lines: the
bands' energies spread over the Bark scale, an offset below them, the
threshold of hearing in quiet as the floor; and an attack detector that
says where short blocks are needed.

=head1 METHODS

=head2 new

C<new($rate)>: a model for a sample rate, with no granule before.

=head2 allowed

C<allowed($xr, $type)>: the noise each band of a granule's lines may take: one per long band;
in a short block one per band and window (3 b + w).

=head2 attack

Whether a granule's samples (one array per channel) have an attack: two
answers, early in the granule (its first 192 samples: short granule k's
own) and later (the next granule's, as the filterbank delays the sound).
Called once per granule, in order.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
