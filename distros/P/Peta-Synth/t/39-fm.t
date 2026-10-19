use v5.36;
use Test::More;
use lib 'lib';
use Peta::Synth::Synth;
use Peta::Synth::Engine;

# FM: four operators, their algorithms, feedback, envelopes, velocity.

my $rate = 48000;
my $engine = Peta::Synth::Engine::create('perl');
sub near ($got, $want, $tol, $name) { cmp_ok(abs($got - $want), '<=', $tol, $name) or diag "got $got, want $want" }

# FM alone (no partials), flat envelopes unless asked; its first $quanta.
sub fm (%fields) {
    my $quanta   = delete $fields{quanta} // 12;
    my $velocity = delete $fields{velocity} // 127;
    my $key      = delete $fields{key} // 57;
    my $s = Peta::Synth::Synth->new(rate => $rate, partials => 8, engine => $engine, limiter => 0);
    $s->reverb->set(on => 0);
    my %flat = map { ("op${_}_attack" => 0.0005, "op${_}_sustain" => 1, "op${_}_vel" => 0, "op${_}_level" => 0) } 1 .. 4;
    $s->apply_edits({ programs => { 0 => { partials => [], unison => 1, fm => 1, attack => 0.0005, sustain => 1, %flat, %fields } } });
    $s->play({ type => 'note_on', channel => 0, key => $key, velocity => $velocity });
    my @x;
    push @x, @{ ($s->render_arrays(1024))[0] } for 1 .. $quanta;
    return \@x;
}
# A component's amplitude: a DFT bin over a whole number of the note's periods.
sub at ($x, $hz, $from = 2400, $length = 9600) {
    my ($re, $im) = (0, 0);
    for my $i (0 .. $length - 1) {
        my $a = 6.283185307179586 * $hz * $i / $rate;
        $re += $x->[ $from + $i ] * cos $a;
        $im += $x->[ $from + $i ] * sin $a;
    }
    return 2 * sqrt($re * $re + $im * $im) / $length;
}
# Bessel's J_k(x), by its series.
sub bessel ($k, $x) {
    my ($sum, $term) = (0, ($x / 2)**$k);
    $term /= $_ for 1 .. $k;
    for my $m (0 .. 30) {
        $sum += $term;
        $term *= -($x / 2)**2 / (($m + 1) * ($m + $k + 1));
    }
    return $sum;
}

my $f = 220;
# One carrier, no modulation: a sine of the note.
my $x = fm(fm_alg => 1, op1_level => 1);
cmp_ok(at($x, 2 * $f), '<', 1e-4 * at($x, $f), 'a carrier alone: a sine');
$x = fm(fm_alg => 1, op1_level => 1, op1_ratio => 2);
cmp_ok(at($x, 2 * $f), '>', 1e3 * at($x, $f), 'at twice the note when its ratio is 2');

# Carrier at 4, modulator at 1, index 1: the sidebands as Bessel says.
$x = fm(fm_alg => 1, op1_level => 1, op1_ratio => 4, op2_level => 1, op2_ratio => 1);
my $j0 = at($x, 4 * $f);
near(at($x, 5 * $f) / $j0, bessel(1, 1) / bessel(0, 1), 0.01, 'the first sideband: J1(1) / J0(1)');
near(at($x, 6 * $f) / $j0, bessel(2, 1) / bessel(0, 1), 0.01, 'the second: J2(1) / J0(1)');
near(at($x, 3 * $f) / $j0, bessel(1, 1) / bessel(0, 1), 0.01, 'and below, the same');

# The algorithms route: 4 > 3 > 2 > 1 modulates through; all carriers do not.
my $chain = fm(fm_alg => 1, op1_level => 1, op2_level => 1, op3_level => 1, op4_level => 1);
my $flat  = fm(fm_alg => 8, op1_level => 1, op2_level => 1, op3_level => 1, op4_level => 1);
cmp_ok(at($chain, 3 * $f), '>', 0.05 * at($chain, $f), 'algorithm 1: a chain, rich');
cmp_ok(at($flat, 3 * $f), '<', 1e-4 * at($flat, $f), 'algorithm 8: four sines of the note');
near(at($flat, $f) / (4 * at(fm(fm_alg => 8, op1_level => 1), $f)), 1, 1e-4, 'their sum');

# Feedback: one operator on itself, from a sine towards a saw.
my $plain = fm(fm_alg => 8, op4_level => 1);
my $fed   = fm(fm_alg => 8, op4_level => 1, fm_fb => 0.3);
cmp_ok(at($plain, 2 * $f), '<', 1e-4 * at($plain, $f), 'no feedback: a sine');
cmp_ok(at($fed, 2 * $f), '>', 0.1 * at($fed, $f), 'feedback: harmonics');

# A modulator's envelope: the brightness falls as it decays.
$x = fm(fm_alg => 1, op1_level => 1, op2_level => 2, op2_decay => 0.05, op2_sustain => 0, quanta => 16);
cmp_ok(at($x, 2 * $f, 12000, 2400), '<', 0.2 * at($x, 2 * $f, 960, 2400), 'the modulator decays: the harmonics with it');

# Velocity on a modulator: a softer note, a smaller index.
my @index = map {
    my $v = fm(fm_alg => 1, op1_level => 1, op1_ratio => 4, op2_level => 1, op2_vel => 1, velocity => $_);
    at($v, 5 * $f) / at($v, 4 * $f);
} 127, 64;
cmp_ok($index[1], '<', 0.7 * $index[0], 'velocity moves the index');

# Modulation's fm: the index by octaves.
my $up = fm(fm_alg => 1, op1_level => 1, op1_ratio => 4, op2_level => 0.5, mods => [ [ 'velocity', 'fm', 1 ] ]);
near(at($up, 5 * $f) / at($up, 4 * $f), bessel(1, 1) / bessel(0, 1), 0.01, 'an index of 0.5 an octave up: as one of 1');

done_testing;
