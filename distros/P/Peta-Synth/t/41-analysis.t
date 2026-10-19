use v5.36;
use Test::More;
use File::Temp qw(tempdir);
use lib 'lib';
use Peta::Synth::Analysis;
use Peta::Synth::FFT;
use Peta::Synth::Output;

use constant PI => 3.141592653589793;
my $rate = 48000;
my $dir = tempdir(CLEANUP => 1);

# The FFT is the DFT.
{
    my @re = map { sin(1.3 * $_) + 0.2 * cos(5.1 * $_ * $_) } 0 .. 63;
    my @im = map { 0.5 * cos(0.7 * $_) } 0 .. 63;
    my ($fr, $fi) = ([@re], [@im]);
    Peta::Synth::FFT::fft($fr, $fi);
    my $worst = 0;
    for my $k (0 .. 63) {
        my ($r, $i) = (0, 0);
        for my $n (0 .. 63) {
            my $w = -2 * PI * $k * $n / 64;
            $r += $re[$n] * cos($w) - $im[$n] * sin($w);
            $i += $re[$n] * sin($w) + $im[$n] * cos($w);
        }
        $worst = abs($r - $fr->[$k]) if abs($r - $fr->[$k]) > $worst;
        $worst = abs($i - $fi->[$k]) if abs($i - $fi->[$k]) > $worst;
    }
    cmp_ok($worst, '<', 1e-9, 'the FFT is the DFT');
    ok(!eval { Peta::Synth::FFT::fft([1, 2, 3], [0, 0, 0]); 1 }, 'not of three points');
}

# A stiff string's note, made of decaying partials of known level,
# frequency and decay: measured as it was made.
my ($f0, $B) = (220, 0.0005);
my @partial = map { { k => $_, amp => 0.3 / $_, freq => $_ * $f0 * sqrt(1 + $B * $_ * $_), decay => 3 * $_ } } 1 .. 10;
my $length = int(1.3 * $rate);
my @x = ((0.0) x $length);
for my $p (@partial) {
    my ($w, $g) = (2 * PI * $p->{freq} / $rate, 10**(-$p->{decay} / 20 / $rate));
    my ($amp, $phase) = ($p->{amp}, 0.37 * $p->{k});
    for my $i (0 .. $length - 1) {
        $x[$i] += $amp * sin($w * $i + $phase);
        $amp *= $g;
    }
}
my @times = (0.1, 0.5, 1.0);
my $m = Peta::Synth::Analysis::partials(\@x, rate => $rate, f0 => $f0, count => 10, times => \@times);
my $frame = 4096 / 2 / $rate;      # a frame's level is its middle's
my ($level, $cents, $decay) = (0, 0, 0);
for my $p (@partial) {
    for my $t (0 .. $#times) {
        my $truth = 20 * log($p->{amp}) / log(10) - $p->{decay} * ($times[$t] + $frame);
        $level = abs($m->{level}[ $p->{k} ][$t] - $truth) if abs($m->{level}[ $p->{k} ][$t] - $truth) > $level;
        my $off = abs(1200 * log($m->{freq}[ $p->{k} ][$t] / $p->{freq}) / log(2));
        $cents = $off if $off > $cents;
    }
    my $d = abs(Peta::Synth::Analysis::slope($m->{times}, $m->{level}[ $p->{k} ]) + $p->{decay}) / $p->{decay};
    $decay = $d if $d > $decay;
}
cmp_ok($level, '<', 0.3, "each partial's level, within 0.3 dB (worst $level)");
cmp_ok($cents, '<', 0.5, "its frequency, within half a cent (worst $cents)");
cmp_ok($decay, '<', 0.02, "its decay, within 2% (worst $decay)");
my ($b, $f) = Peta::Synth::Analysis::stretch(map { $_ && $_->[0] } @{ $m->{freq} });
cmp_ok(abs($b / $B - 1), '<', 0.02, "the stiffness B ($b)");
cmp_ok(abs($f / $f0 - 1), '<', 1e-4, "the fundamental ($f)");

# Levels and brightness of a sine of amplitude 0.5 at 1 kHz.
my @sine = map { 0.5 * sin(2 * PI * 1000 * $_ / $rate) } 0 .. $rate / 2 - 1;
my $envelope = Peta::Synth::Analysis::envelope(\@sine, $rate, 0.1);
is(scalar @$envelope, 5, 'an RMS level every 0.1 s');
cmp_ok(abs($envelope->[2] - 20 * log(0.5 / sqrt 2) / log(10)), '<', 0.01, 'RMS level of the sine');
cmp_ok(abs(Peta::Synth::Analysis::centroid(\@sine, $rate, 0) - 1000), '<', 30, 'its brightness is its frequency');

# WAV, as Peta::Synth::Output writes it: floats exactly, 16 bits within the dither.
my @left  = map { 0.6 * sin(0.01 * $_) } 0 .. 999;
my @right = map { -0.3 * cos(0.02 * $_) } 0 .. 999;
for my $bits (32, 24, 16) {
    my $file = "$dir/$bits.wav";
    Peta::Synth::Output->write_file($file, \@left, \@right, rate => 44100, bits => $bits);
    my $wav = Peta::Synth::Analysis::read_wav($file);
    my $worst = 0;
    for my $i (0 .. 999) {
        for ([ $left[$i], $wav->{channels}[0][$i] ], [ $right[$i], $wav->{channels}[1][$i] ]) {
            $worst = abs($_->[0] - $_->[1]) if abs($_->[0] - $_->[1]) > $worst;
        }
    }
    is($wav->{rate}, 44100, "$bits bits: the rate");
    cmp_ok($worst, '<', $bits == 32 ? 1e-7 : $bits == 24 ? 2 / 2**23 : 2 / 32768, "$bits bits: the samples");
}
is_deeply(Peta::Synth::Analysis::mono([1, 2], [3, 6]), [2, 4], 'mono: the mean');

# Bands, wobble, vibrato and noise, on sounds made to measure.
{
    my $n = int(1.2 * $rate);
    my @two = map { 0.5 * sin(2 * PI * 1000 * $_ / $rate) + 0.05 * sin(2 * PI * 4000 * $_ / $rate) } 0 .. $n - 1;
    my %band = map { (sprintf('%.0f', $_->{centre}) => $_->{level}) } @{ Peta::Synth::Analysis::bands(\@two, $rate, from => 0.1, to => 1.1) };
    cmp_ok(abs($band{1000} - $band{4000} - 20), '<', 0.5, 'bands: two sines 20 dB apart');

    my @steady = map { 0.5 * sin(2 * PI * 440 * $_ / $rate) } 0 .. $n - 1;
    my @trem = map { (1 + 0.5 * sin(2 * PI * 5 * $_ / $rate)) * $steady[$_] } 0 .. $n - 1;
    my ($depth, $often) = Peta::Synth::Analysis::wobble(\@trem, $rate, 0.1, 1.1);
    ok($depth > 2 && abs($often - 5) < 0.6, "wobble: a tremolo of 5 Hz ($depth dB at $often Hz)");
    ($depth) = Peta::Synth::Analysis::wobble(\@steady, $rate, 0.1, 1.1);
    cmp_ok($depth, '<', 0.1, 'wobble: none in a steady sine');

    # +-20 cents at 5 Hz: an RMS of 14 cents, a little less through a 43 ms frame.
    my $phase = 0;
    my @vib = map { $phase += 2 * PI * 440 * 2**(20 / 1200 * sin(2 * PI * 5 * $_ / $rate)) / $rate; 0.5 * sin($phase) } 0 .. $n - 1;
    my $cents = Peta::Synth::Analysis::vibrato(\@vib, $rate, 440, 0.1, 1.1);
    ok($cents > 11 && $cents < 15, "vibrato: 20 cents at 5 Hz, $cents cents RMS");
    cmp_ok(Peta::Synth::Analysis::vibrato(\@steady, $rate, 440, 0.1, 1.1), '<', 0.5, 'vibrato: none in a steady sine');

    # Ten harmonics of 200 Hz (each 0.1) and white noise of a tenth their power.
    my $seed = 12345;
    my $noise = sqrt(3 * 0.1 * 10 * 0.1**2 / 2);     # uniform in +-a has a power of a^2/3
    my @mix = map {
        my $t = $_ / $rate;
        my $s = 0;
        $s += 0.1 * sin(2 * PI * 200 * $_ * $t + $_) for 1 .. 10;
        $seed = ($seed * 1103515245 + 12345) % 2147483648;
        $s + $noise * (2 * $seed / 2147483648 - 1);
    } 0 .. $n - 1;
    my $db = Peta::Synth::Analysis::noise(\@mix, $rate, 200, int(0.5 * $rate));
    cmp_ok(abs($db - 10 * log(0.1 / 1.1) / log(10)), '<', 1, "noise: a tenth of the partials' power ($db dB of the whole)");
}

# A body's response: sawtooth notes (harmonics 1/k) through a body that
# takes 12 dB from the third octave about 1 kHz (891 to 1122 Hz), and
# nothing elsewhere; each note has a harmonic there.
{
    my @notes;
    for my $f (110, 170, 200) {
        my @y = ((0.0) x int(0.6 * $rate));
        for my $k (1 .. 10) {
            my $amp = 0.1 / $k * ($k * $f > 891 && $k * $f < 1122 ? 0.25 : 1);
            my $w = 2 * PI * $k * $f / $rate;
            $y[$_] += $amp * sin($w * $_ + $k) for 0 .. $#y;
        }
        push @notes, [ \@y, $rate, $f ];
    }
    my $curve = Peta::Synth::Analysis::response(\@notes, count => 10, times => [ 0.2, 0.4 ]);
    my ($dip) = grep { abs($_->{centre} - 1000) < 1 } @$curve;
    ok($dip && abs($dip->{level} + 12) < 1, 'response: the body\'s dip, 12 dB') or diag(explain $curve);
    my $flat = 0;
    for (grep { abs($_->{centre} - 1000) >= 1 } @$curve) { $flat = abs $_->{level} if abs $_->{level} > $flat }
    cmp_ok($flat, '<', 0.5, 'response: flat elsewhere');
}

# FluidSynth, where it is.
SKIP: {
    require Peta::Synth::Fluid;
    my $why = Peta::Synth::Fluid::unavailable();
    skip "FluidSynth: $why", 2 if $why;
    my ($l, $r) = Peta::Synth::Fluid::render([
        { time => 0, type => 'program', channel => 0, program => 0 },
        { time => 0, type => 'note_on', channel => 0, key => 60, velocity => 100 },
        { time => 0.5, type => 'note_off', channel => 0, key => 60, velocity => 64 },
    ], rate => $rate, length => $rate);
    is(scalar @$l, $rate, 'FluidSynth: as long as asked');
    my $peak = 0;
    for (@$l, @$r) { $peak = abs $_ if abs $_ > $peak }
    cmp_ok($peak, '>', 0.01, 'FluidSynth: it sounds');
}

done_testing;
