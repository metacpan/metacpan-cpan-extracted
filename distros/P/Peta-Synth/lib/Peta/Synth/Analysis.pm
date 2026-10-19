package Peta::Synth::Analysis;
# ABSTRACT: measuring sound: a note's partials, its level and brightness over time

# Measuring sound: what a note's partials are and do, how loud and how
# bright it is over time; to compare this synthesizer's instruments with
# recordings (and with what FluidSynth plays from a SoundFont, see
# Peta::Synth::Fluid) and with themselves.
#
# Sound is an array of samples (floats, full scale 1) at a rate. Levels are
# in dB of amplitude: a sine of amplitude 1 is 0 dB, as its partial and as
# its peak; RMS levels are of the samples (a sine of amplitude 1 is -3 dB).

use v5.36;
use Peta::Synth::FFT;

our $VERSION = '0.2610180';

use constant PI => 3.141592653589793;

# A WAV file's sample formats.
use constant {
    PCM        => 1,
    FLOAT      => 3,
    EXTENSIBLE => 0xfffe,    # its own format a few bytes further on
};

# A WAV file: { rate, channels => [ [samples], ... ] }. PCM of 8, 16, 24 or
# 32 bits, or floats of 32 or 64; WAVE_FORMAT_EXTENSIBLE as the format it
# extends.
sub read_wav ($file) {
    open my $fh, '<:raw', $file or die "cannot read '$file': $!\n";
    my $data = do { local $/; <$fh> };
    die "$file: not a WAV file\n" unless substr($data, 0, 4) eq 'RIFF' && substr($data, 8, 4) eq 'WAVE';

    my ($format, $count, $rate, $bits, $samples);
    my $pos = 12;
    while ($pos + 8 <= length $data) {
        my ($id, $size) = unpack 'a4 V', substr $data, $pos, 8;
        $size = length($data) - $pos - 8 if $pos + 8 + $size > length $data;    # a size never set (a pipe)
        if ($id eq 'fmt ') {
            ($format, $count, $rate, $bits) = unpack 'v v V x6 v', substr $data, $pos + 8, 16;
            $format = unpack 'v', substr $data, $pos + 32, 2 if $format == EXTENSIBLE;
        }
        elsif ($id eq 'data') {
            die "$file: data before the format\n" if !$format;
            $samples = _samples($format, $bits, substr($data, $pos + 8, $size))
                // die "$file: format $format with $bits bits is not read here\n";
        }
        $pos += 8 + $size + ($size & 1);
    }
    die "$file: no samples\n" if !$samples;

    my @channels = map { [] } 1 .. $count;
    for my $i (0 .. $#$samples) {
        push @{ $channels[ $i % $count ] }, $samples->[$i];
    }
    return { rate => $rate, channels => \@channels };
}

# The samples in a WAV file's data, interleaved, full scale 1; undef for a
# format not read here.
sub _samples ($format, $bits, $raw) {
    return $format == FLOAT && $bits == 32 ? [ unpack 'f<*', $raw ]
         : $format == FLOAT && $bits == 64 ? [ unpack 'd<*', $raw ]
         : $format == PCM   && $bits == 16 ? [ map { $_ / 32768 } unpack 's<*', $raw ]
         : $format == PCM   && $bits == 32 ? [ map { $_ / 2147483648 } unpack 'l<*', $raw ]
         : $format == PCM   && $bits == 8  ? [ map { ($_ - 128) / 128 } unpack 'C*', $raw ]
         : $format == PCM   && $bits == 24 ? [ map { unpack('l<', "\0$_") / 2147483648 } unpack '(a3)*', $raw ]
         :                                   undef;
}

# The channels' mean.
sub mono (@channels) {
    return $channels[0] if @channels == 1;

    my @sum = (0.0) x @{ $channels[0] };
    for my $channel (@channels) {
        for my $i (0 .. $#sum) {
            $sum[$i] += $channel->[$i];
        }
    }
    return [ map { $_ / @channels } @sum ];
}

# The magnitudes of a frame: $size samples from $at under a Hann window,
# zero-padded $pad times; a sine of amplitude A peaks at A. Returns the
# magnitudes (up to half the rate) and the Hz a bin is.
sub spectrum ($x, $rate, $at, $size, $pad = 4) {
    my $n = $size * $pad;
    die "a frame of $size, padded $pad times: not a power of two\n" if $n & ($n - 1);

    my @re = (0.0) x $n;
    my @im = (0.0) x $n;
    for my $i (0 .. $size - 1) {
        my $s = $x->[ $at + $i ] // 0;
        $re[$i] = $s * (0.5 - 0.5 * cos(2 * PI * $i / $size));
    }
    Peta::Synth::FFT::fft(\@re, \@im);

    my $scale = 4 / $size;
    return ([ map { $scale * sqrt($re[$_]**2 + $im[$_]**2) } 0 .. $n / 2 ], $rate / $n);
}

# The strongest peak between two frequencies: its frequency and amplitude,
# both from a parabola through the three bins about it (in dB).
sub peak ($magnitudes, $bin, $low, $high) {
    my $from = int($low / $bin) + 1;
    my $to   = int($high / $bin);
    $from = 1                  if $from < 1;
    $to   = $#$magnitudes - 1  if $to > $#$magnitudes - 1;
    return (($low + $high) / 2, 0) if $to < $from;

    my $best = $from;
    for my $i ($from .. $to) {
        $best = $i if $magnitudes->[$i] > $magnitudes->[$best];
    }
    my ($l, $m, $r) = map { _db($magnitudes->[$_] || 1e-12) } $best - 1, $best, $best + 1;
    my $d = $l - 2 * $m + $r;
    my $p = $d < 0 ? 0.5 * ($l - $r) / $d : 0;
    # At a range's edge the parabola can reach further: the peak is within
    # half a bin of its bin.
    $p = -0.5 if $p < -0.5;
    $p = 0.5  if $p > 0.5;
    return (($best + $p) * $bin, 10**(($m - 0.25 * ($l - $r) * $p) / 20));
}

# A note's partials over time: count partials of a note of about f0 Hz,
# each at the times given (seconds into the sound; a frame of size samples
# from each), each found as the strongest peak within 0.4 f0 of where the
# partials below it say it is (a stiff string's are sharp). Returns
# { times, freq => [k][t], level => [k][t] (dB) }, k from 1.
sub partials ($x, %opt) {
    my ($rate, $f0) = @opt{qw(rate f0)};
    my $count = $opt{count} // 16;
    my $size  = $opt{size}  // 4096;
    my @times = @{ $opt{times} // [ 0.02, 0.1, 0.3, 1, 2.5 ] };

    my (@freq, @level);
    for my $t (0 .. $#times) {
        my $at = int($times[$t] * $rate);
        last if $at + $size > @$x;

        my ($magnitudes, $bin) = spectrum($x, $rate, $at, $size);
        my ($f1)  = peak($magnitudes, $bin, $f0 * 0.97, $f0 * 1.03);
        my $ratio = 1;    # the last partial's frequency over k f1
        for my $k (1 .. $count) {
            my $centre = $k * $f1 * $ratio;
            my ($f, $amp) = peak($magnitudes, $bin, $centre - 0.4 * $f1, $centre + 0.4 * $f1);
            $freq[$k][$t]  = $f;
            $level[$k][$t] = _db($amp || 1e-12);
            $ratio = $f / ($k * $f1) if $amp > 0;
        }
    }
    return { times => [ @times[ 0 .. $#{ $freq[1] // [] } ] ], freq => \@freq, level => \@level };
}

# The stiffness that the partials' frequencies say: f_k = k f sqrt(1 + B k^2),
# fitted to (f_k / k)^2 = f^2 + f^2 B k^2 by least squares. Returns (B, f).
sub stretch (@freq) {
    my @k = grep { defined $freq[$_] && $freq[$_] > 0 } 1 .. $#freq;
    return (0, $freq[1] // 0) if @k < 2;

    my ($slope, $f2) = _line([ map { $_ * $_ } @k ], [ map { ($freq[$_] / $_)**2 } @k ]);
    return $f2 > 0 ? ($slope / $f2, sqrt $f2) : (0, 0);
}

# A level's slope over time, dB a second, by least squares.
sub slope ($times, $levels) {
    my @i = grep { defined $levels->[$_] } 0 .. $#$times;
    return 0 if @i < 2;

    my ($slope) = _line([ @$times[@i] ], [ @$levels[@i] ]);
    return $slope;
}

# The straight line through points by least squares: (slope, intercept),
# the slope 0 where the x are all the same.
sub _line ($x, $y) {
    my $n = @$x;
    my ($sx, $sy, $sxx, $sxy) = (0, 0, 0, 0);
    for my $i (0 .. $n - 1) {
        $sx  += $x->[$i];
        $sy  += $y->[$i];
        $sxx += $x->[$i] * $x->[$i];
        $sxy += $x->[$i] * $y->[$i];
    }
    my $d     = $n * $sxx - $sx * $sx;
    my $slope = $d ? ($n * $sxy - $sx * $sy) / $d : 0;
    return ($slope, ($sy - $slope * $sx) / $n);
}

# The RMS level (dB) of every step seconds.
sub envelope ($x, $rate, $step = 0.05) {
    my $n = int($step * $rate);
    my @levels;
    for (my $at = 0; $at + $n <= @$x; $at += $n) {
        my $e = 0;
        $e += $_ * $_ for @$x[ $at .. $at + $n - 1 ];
        push @levels, _power_db($e / $n + 1e-24);
    }
    return \@levels;
}

# How bright a frame is: its spectral centroid (Hz), the magnitudes as weights.
sub centroid ($x, $rate, $at, $size = 4096) {
    my ($magnitudes, $bin) = spectrum($x, $rate, $at, $size, 1);
    my ($sum, $weighted) = (0, 0);
    for my $i (1 .. $#$magnitudes) {
        $sum      += $magnitudes->[$i];
        $weighted += $magnitudes->[$i] * $i * $bin;
    }
    return $sum ? $weighted / $sum : 0;
}

# The spectrum's power in bands (per an octave, centred on 1 kHz and its
# octaves), frames of size samples every half frame from $from to $to
# seconds averaged; up to half the rate, from 20 Hz. Returns [ { centre,
# level (dB) } ], low to high, bands with nothing in them left out.
sub bands ($x, $rate, %opt) {
    my $size = $opt{size} // 4096;
    my $per  = $opt{per}  // 1;
    my $from = int(($opt{from} // 0) * $rate);
    my $to   = int(($opt{to} // @$x / $rate) * $rate);
    $to = @$x if $to > @$x;

    my (%power, $frames);
    for (my $at = $from; $at + $size <= $to; $at += $size / 2) {
        my ($m, $bin) = spectrum($x, $rate, $at, $size, 1);
        for my $i (1 .. $#$m) {
            my $f = $i * $bin;
            next if $f < 20;
            $power{ _band($f, $per) } += $m->[$i]**2;
        }
        $frames++;
    }
    return [] if !$frames;

    my @bands = sort { $a <=> $b } keys %power;
    return [ map { { centre => _centre($_, $per), level => _power_db($power{$_} / $frames + 1e-30) } } @bands ];
}

# How much a sound's level moves (tremolo, beating), from $from to $to
# seconds: its level every 10 ms less the straight line through it, the
# RMS of what is left (dB) and how often it goes up and down (Hz).
sub wobble ($x, $rate, $from, $to) {
    my $levels = envelope([ @$x[ int($from * $rate) .. int($to * $rate) - 1 ] ], $rate, 0.01);
    my @t      = map { $_ * 0.01 } 0 .. $#$levels;
    return (0, 0) if @t < 4;

    my $slope = slope(\@t, $levels);
    my ($mt, $ml) = (0, 0);
    $mt += $_ / @t for @t;
    $ml += $_ / @t for @$levels;
    my @rest = map { $levels->[$_] - $ml - $slope * ($t[$_] - $mt) } 0 .. $#t;

    my ($sum, $crossings) = (0, 0);
    $sum       += $_ * $_ for @rest;
    $crossings += ($rest[$_ - 1] < 0) != ($rest[$_] < 0) for 1 .. $#rest;
    return (sqrt($sum / @rest), $crossings / 2 / ($t[-1] || 1));
}

# How much a note's pitch moves (vibrato), from $from to $to seconds: the
# strongest of its first four partials followed every 20 ms, the RMS of its
# frequency about its mean, in cents.
sub vibrato ($x, $rate, $f0, $from, $to) {
    my $size = 2048;
    my ($m, $bin) = spectrum($x, $rate, int($from * $rate), $size);
    my ($k, $best) = (1, 0);
    for my $j (1 .. 4) {
        my (undef, $amp) = peak($m, $bin, ($j - 0.3) * $f0, ($j + 0.3) * $f0);
        ($k, $best) = ($j, $amp) if $amp > $best;
    }

    my $end  = int($to * $rate);
    $end = @$x if $end > @$x;
    my $step = int(0.02 * $rate);
    my @cents;
    for (my $at = int($from * $rate); $at + $size <= $end; $at += $step) {
        my ($mm, $b) = spectrum($x, $rate, $at, $size);
        my ($f, $amp) = peak($mm, $b, ($k - 0.3) * $f0, ($k + 0.3) * $f0);
        push @cents, 1200 * log($f / ($k * $f0)) / log(2) if $amp > 0;
    }
    return 0 if @cents < 2;

    my $mean = 0;
    $mean += $_ / @cents for @cents;
    my $sum = 0;
    $sum += ($_ - $mean)**2 for @cents;
    return sqrt($sum / @cents);
}

# How much of a frame is not the note's partials (breath, bow, hammer,
# noise), in dB of the whole: the partials found as partials() finds them,
# where a peak stands out of its window, each with the bins of its peak (a
# Hann window's main lobe).
sub noise ($x, $rate, $f0, $at, $size = 4096) {
    my ($m, $bin) = spectrum($x, $rate, $at, $size, 1);
    my $whole = 0;
    $whole += $m->[$_]**2 for 1 .. $#$m;
    return 0 if !$whole;

    my %taken;
    my ($f1)  = peak($m, $bin, $f0 * 0.97, $f0 * 1.03);
    my $ratio = 1;
    for my $k (1 .. int(0.45 * $rate / $f1)) {
        my $low  = ($k * $ratio - 0.4) * $f1;
        my $high = ($k * $ratio + 0.4) * $f1;
        my ($f, $amp) = peak($m, $bin, $low, $high);

        # A partial stands out of what is about it: 12 dB over the window's
        # median. (A slice past the end, grepped, would lengthen @$m.)
        my $last   = int($high / $bin);
        $last = $#$m if $last > $#$m;
        my @window = sort { $a <=> $b } @$m[ int($low / $bin) + 1 .. $last ];
        next if !@window || $amp < 4 * $window[ $#window / 2 ];

        $ratio = $f / ($k * $f1);
        my $i = int($f / $bin + 0.5);
        $taken{$_} = 1 for grep { $_ >= 1 && $_ <= $#$m } $i - 2 .. $i + 2;
    }

    my $rest = 0;
    $rest += $m->[$_]**2 for grep { !$taken{$_} } 1 .. $#$m;
    return _power_db($rest / $whole + 1e-12);
}

# What a body (a violin's, a reed's chamber) does to the source's harmonics,
# from notes across a range: each note's partials (their power averaged over
# the times), less the source's own fall (k^-slope: 1 for a bowed or blown
# sawtooth), the note's whole level taken out; then by frequency, averaged
# in bands (per octave), the loudest band 0 dB. Notes: [ [\@x, $rate, $f0], ... ].
# Options: count (16), times ([0.5, 1]), slope (1), per (3 bands an octave).
# Returns [ { centre (Hz), level (dB), count (partials) }, ... ], low to high.
sub response ($notes, %opt) {
    my $count = $opt{count} // 16;
    my $times = $opt{times} // [ 0.5, 1 ];
    my $slope = $opt{slope} // 1;
    my $per   = $opt{per}   // 3;

    my (%sum, %n);
    for my $note (@$notes) {
        my ($x, $rate, $f0) = @$note;
        my $p = partials($x, rate => $rate, f0 => $f0, count => $count, times => $times);

        # Each partial's power, averaged over the times.
        my (@k, @power);
        for my $k (1 .. $count) {
            my @levels = grep { defined } @{ $p->{level}[$k] // [] };
            next if !@levels || $k * $f0 > 0.45 * $rate;
            my $power = 0;
            $power += 10**($_ / 10) for @levels;
            push @k,     $k;
            push @power, $power / @levels;
        }
        next if !@k;

        my $whole = 0;
        $whole += $_ for @power;
        for my $i (0 .. $#k) {
            my $level = _power_db($power[$i] / $whole + 1e-30) + 20 * $slope * log($k[$i]) / log(10);
            my $band  = _band($k[$i] * $f0, $per);
            $sum{$band} += $level;
            $n{$band}++;
        }
    }
    my @bands = sort { $a <=> $b } keys %sum;
    return [] if !@bands;

    my @curve = map { { centre => _centre($_, $per), level => $sum{$_} / $n{$_}, count => $n{$_} } } @bands;
    my ($top) = sort { $b <=> $a } map { $_->{level} } @curve;
    $_->{level} -= $top for @curve;
    return \@curve;
}

# dB of an amplitude, and of a power.
sub _db       ($amplitude) { return 20 * log($amplitude) / log(10) }
sub _power_db ($power)     { return 10 * log($power) / log(10) }

# The band, $per an octave, a frequency is nearest the centre of: band 0 is
# centred on 1 kHz, band $per an octave above it.
sub _band   ($f, $per)    { return int(log($f / 1000) / log(2) * $per + 1000.5) - 1000 }
sub _centre ($band, $per) { return 1000 * 2**($band / $per) }

1;

__END__

=head1 NAME

Peta::Synth::Analysis - measuring sound: a note's partials, its level and brightness over time

=head1 VERSION

version 0.2610180

=head1 SYNOPSIS

    use Peta::Synth::Analysis;
    my $wav = Peta::Synth::Analysis::read_wav('note.wav');
    my $x = Peta::Synth::Analysis::mono(@{ $wav->{channels} });
    my $p = Peta::Synth::Analysis::partials($x, rate => $wav->{rate}, f0 => 261.6, count => 16);
    my ($B, $f) = Peta::Synth::Analysis::stretch(map { $_ && $_->[0] } @{ $p->{freq} });

=head1 DESCRIPTION

What C<bin/peta-analyze> measures with: the tools to compare an instrument
of this synthesizer with a recording, or with itself after a change.
Sound is an array of samples (full scale 1) at a rate. Levels are in dB
of amplitude: a sine of amplitude 1 is 0 dB as a partial; RMS levels are
the samples' (that sine is -3 dB).

=head1 FUNCTIONS

=head2 read_wav

C<read_wav($file)>: C<< { rate, channels => [ \@samples, ... ] } >>; PCM of
8, 16, 24 or 32 bits, floats of 32 or 64.

=head2 mono

C<mono(@channels)>: their mean.

=head2 spectrum

C<spectrum(\@x, $rate, $at, $size, $pad = 4)>: the magnitudes of C<$size>
samples from C<$at> under a Hann window, zero-padded C<$pad> times (a sine
of amplitude A peaks at A), and the Hz of a bin.

=head2 peak

C<peak(\@magnitudes, $bin, $low, $high)>: the strongest peak between two
frequencies, its frequency and amplitude interpolated between the bins.

=head2 partials

C<< partials(\@x, rate => ..., f0 => ..., count => 16, size => 4096, times => [...]) >>:
each partial of a note at each time (seconds into the sound), found where
the partials below it say it is, so that a stiff string's are followed.
C<< { times, freq => [k][t], level => [k][t] } >>, k from 1, levels in dB.

=head2 stretch

C<stretch(@freq)> (indexed by k, from 1): the stiffness B and fundamental f
of C<f_k = k f sqrt(1 + B k^2)> that fit them best.

=head2 slope

C<slope(\@times, \@levels)>: dB a second, by least squares.

=head2 envelope

C<envelope(\@x, $rate, $step = 0.05)>: the RMS level of every step seconds.

=head2 centroid

C<centroid(\@x, $rate, $at, $size = 4096)>: the spectral centroid (Hz) of a frame.

=head2 bands

C<< bands(\@x, $rate, from => 0, to => ..., per => 1, size => 4096) >>: the
spectrum's power in bands (C<per> an octave, centred on 1 kHz's octaves),
averaged over frames from and to (seconds). C<< [ { centre, level } ] >>.

=head2 wobble

C<wobble(\@x, $rate, $from, $to)>: how much the level moves (tremolo,
beating): the RMS (dB) of the level every 10 ms about its straight line,
and how often it goes up and down (Hz).

=head2 vibrato

C<vibrato(\@x, $rate, $f0, $from, $to)>: how much the pitch moves: the RMS
in cents of the strongest of the first four partials, every 20 ms.

=head2 noise

C<noise(\@x, $rate, $f0, $at, $size = 4096)>: how much of a frame is not the
note's partials, in dB of the whole.

=head2 response

C<< response([ [\@x, $rate, $f0], ... ], count => 16, times => [0.5, 1], slope => 1, per => 3) >>:
what a body does to the harmonics of a source falling as k^-slope, from
notes across a range: the partials' levels less the source's fall, each
note's whole level taken out, averaged in bands by frequency.
C<< [ { centre, level, count }, ... ] >>, the loudest band 0 dB.

=head1 AUTHOR

PetaMem s.r.o. E<lt>info@petamem.comE<gt>

=head1 COPYRIGHT

Copyright (c) 2026 PetaMem s.r.o.

=head1 LICENSE

This package is free software, dual-licensed under the Artistic License 2.0
and the BSD 2-Clause License. See the LICENSE file of the distribution.

=cut
