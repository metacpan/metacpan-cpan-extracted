use v5.36;
use Test::More;
use lib 'lib';
use Peta::Synth::Synth;
use Peta::Synth::Engine;

# Noise in bands, each with its own envelope; noise on the partials.

my $rate = 24000;
my $engine = Peta::Synth::Engine::create('perl');
sub near ($got, $want, $tol, $name) { cmp_ok(abs($got - $want), '<=', $tol, $name) or diag "got $got, want $want" }

# A note of a patch of noise only (no partials), its first 0.5 s.
sub take (%fields) {
    my $s = Peta::Synth::Synth->new(rate => $rate, partials => 8, engine => $engine, limiter => 0);
    $s->reverb->set(on => 0);
    $s->apply_edits({ programs => { 0 => { partials => [], noise => 0, %fields } } });
    $s->play({ type => 'note_on', channel => 0, key => 60, velocity => 100 });
    my @x;
    push @x, @{ ($s->render_arrays(1024))[0] } for 1 .. 12;
    return (\@x, $s->{active}[0]);
}
sub rms ($x, $from = 0, $to = $#$x) { my $sum = 0; $sum += $x->[$_]**2 for $from .. $to; return sqrt($sum / ($to - $from + 1)) }
# How much of a signal is high: the RMS of its differences over its own.
sub highness ($x) { return rms([ map { $x->[$_] - $x->[ $_ - 1 ] } 1 .. $#$x ]) / rms($x) }

my ($low, $lv)   = take(noise2 => 0.5, noise2_mode => 'low',  noise2_center => 300,  noise2_sustain => 1);
my ($high, $hv)  = take(noise3 => 0.5, noise3_mode => 'high', noise3_center => 6000, noise3_sustain => 1);
my ($band, $bv)  = take(noise => 0.5, noise_center => 1500, noise_q => 4, noise_sustain => 1);
is($lv->{noise}, 1, 'one band');
is($lv->{bands}[0]{mode}, 2, 'a low-pass');
cmp_ok(highness($low), '<', 0.2, 'a low-pass band: little that is high');
cmp_ok(highness($high), '>', 1.2, 'a high-pass band: much');
cmp_ok(highness($band), '>', highness($low), 'a band-pass between');
cmp_ok(highness($band), '<', highness($high), '...');
near(rms($low, 6000), rms($high, 6000), 0.5 * rms($high, 6000), 'levels independent of the band, within a factor of two');

# Each band its own envelope: one that decays, one that stays.
my ($both, $v) = take(noise => 0.5, noise_center => 3000, noise_decay => 40, noise_sustain => 0,
    noise2 => 0.5, noise2_mode => 'low', noise2_center => 200, noise2_sustain => 1);
is($v->{noise}, 2, 'two bands');
cmp_ok($v->{bands}[0]{env}[-1], '<', 1e-6 * $v->{bands}[0]{level}, 'the first decayed away');
near($v->{bands}[1]{env}[-1], $v->{bands}[1]{level}, 1e-12, 'the second held');
cmp_ok(highness([ @$both[ 0 .. 2000 ] ]), '>', 2 * highness([ @$both[ 10000 .. 12000 ] ]), 'so the sound goes from high to low');

# Four poles: twice as steep, about as loud.
# How much is far above: second differences weigh a frequency as its square,
# so that what a two-pole low-pass lets through above it counts as much as
# what it passes.
sub farness ($x) { return rms([ map { $x->[$_] - 2 * $x->[ $_ - 1 ] + $x->[ $_ - 2 ] } 2 .. $#$x ]) / rms($x) }
my ($low4) = take(noise2 => 0.5, noise2_mode => 'low', noise2_center => 300, noise2_sustain => 1, noise2_poles => 4);
cmp_ok(farness($low4), '<', 0.5 * farness($low), 'a low-pass of four poles: far less that is far above');
my ($band4) = take(noise => 0.5, noise_center => 1500, noise_q => 4, noise_sustain => 1, noise_poles => 4);
near(rms($band4, 6000), rms($band, 6000), 0.4 * rms($band, 6000), 'a band-pass of four poles about as loud as of two');

# Grains: bursts at random moments, the level moving between them, as loud
# on the whole as the band steady.
sub moving ($x) {
    my @window = map { rms($x, $_, $_ + 239) } map { 6000 + 240 * $_ } 0 .. 20;    # 10 ms each
    my $mean = 0;
    $mean += $_ / @window for @window;
    my $var = 0;
    $var += ($_ - $mean)**2 / @window for @window;
    return sqrt($var) / $mean;
}
my ($steady) = take(noise => 0.5, noise_center => 1500, noise_sustain => 1);
my ($grains) = take(noise => 0.5, noise_center => 1500, noise_sustain => 1, noise_grains => 30, noise_grain_decay => 80);
cmp_ok(moving($steady), '<', 0.25, 'steady: the level stays');
cmp_ok(moving($grains), '>', 0.5, 'in grains: it moves');
near(rms($grains, 6000), rms($steady, 6000), 0.4 * rms($steady, 6000), 'as loud on the whole');

# Noise on the partials: a steady tone's amplitude moves.
sub tone (%fields) {
    my $s = Peta::Synth::Synth->new(rate => $rate, partials => 4, engine => $engine, limiter => 0);
    $s->reverb->set(on => 0);
    $s->apply_edits({ programs => { 0 => { partials => [ [ 1, 1, 0 ] ], unison => 1, attack => 0.001, sustain => 1, %fields } } });
    $s->play({ type => 'note_on', channel => 0, key => 69, velocity => 100 });
    my @x;
    push @x, @{ ($s->render_arrays(1024))[0] } for 1 .. 8;
    # The amplitude, period by period (440 Hz: about 55 samples a period).
    my @peaks;
    for (my $i = 2000; $i + 55 < @x; $i += 55) {
        my $p = 0;
        for ($i .. $i + 54) { $p = abs $x[$_] if abs $x[$_] > $p }
        push @peaks, $p;
    }
    my $mean = 0;
    $mean += $_ for @peaks;
    $mean /= @peaks;
    my $var = 0;
    $var += ($_ - $mean)**2 for @peaks;
    return sqrt($var / @peaks) / $mean;
}
cmp_ok(tone(), '<', 0.01, 'without: a steady amplitude');
my $moved = tone(rough => 0.3, rough_rate => 30);
cmp_ok($moved, '>', 0.1, 'with: it moves');
cmp_ok($moved, '<', 0.6, 'about as deep as asked');

done_testing;
