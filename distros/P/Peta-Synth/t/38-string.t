use v5.36;
use Test::More;
use lib 'lib';
use Peta::Synth::Synth;
use Peta::Synth::Engine;

# The plucked string (Karplus-Strong): its pitch, its decay, its damping,
# where it is plucked, how hard.

my $rate = 48000;
my $engine = Peta::Synth::Engine::create('perl');
sub near ($got, $want, $tol, $name) { cmp_ok(abs($got - $want), '<=', $tol, $name) or diag "got $got, want $want" }

# A string alone, its first $quanta of 1024 samples.
sub pluck ($key, %fields) {
    my $quanta = delete $fields{quanta} // 24;
    my $velocity = delete $fields{velocity} // 100;
    my $s = Peta::Synth::Synth->new(rate => $rate, partials => 8, engine => $engine, limiter => 0);
    $s->reverb->set(on => 0);
    $s->apply_edits({ programs => { 0 => { partials => [], unison => 1, string => 1, string_key => 0, sustain => 1, attack => 0.0005,
        %fields } } });
    $s->play({ type => 'note_on', channel => 0, key => $key, velocity => $velocity });
    my @x;
    push @x, @{ ($s->render_arrays(1024))[0] } for 1 .. $quanta;
    return \@x;
}
sub rms ($x, $from, $length) { my $s = 0; $s += $x->[$_]**2 for $from .. $from + $length - 1; return sqrt($s / $length) }
# The energy at a frequency: a DFT's bin, over a stretch.
sub at ($x, $hz, $from, $length) {
    my ($re, $im) = (0, 0);
    for my $i (0 .. $length - 1) {
        my $a = 6.283185307179586 * $hz * $i / $rate;
        $re += $x->[ $from + $i ] * cos $a;
        $im += $x->[ $from + $i ] * sin $a;
    }
    return sqrt($re * $re + $im * $im) / $length;
}
# The fundamental: the strongest bin within a semitone of where it should be, refined.
sub pitch ($x, $want) {
    my ($best, $f) = (0, $want);
    for (my $hz = $want * 0.97; $hz <= $want * 1.03; $hz += $want * 0.0005) {
        my $e = at($x, $hz, 4800, 19200);
        ($best, $f) = ($e, $hz) if $e > $best;
    }
    return $f;
}
sub cents ($got, $want) { return 1200 * log($got / $want) / log(2) }

for my $key (40, 69, 88) {
    my $want = 440 * 2**(($key - 69) / 12);
    my $x = pluck($key, string_damp => 0.2);
    near(cents(pitch($x, $want), $want), 0, 2, "key $key: in tune");
}
my $x = pluck(57, string_damp => 0, string_decay => 2, quanta => 40);
near(20 * log(rms($x, 33600, 4800) / rms($x, 4800, 4800)) / log(10), -60 * 0.6 / 2, 1, 'undamped: 60 dB in the time asked');
# How much of a stretch is high: the RMS of its differences over its own.
sub highness ($x, $from) { my @d = map { $x->[$_] - $x->[ $_ - 1 ] } $from + 1 .. $from + 2400; return rms(\@d, 0, 2400) / rms($x, $from, 2400) }
$x = pluck(57, string_damp => 0.6, string_decay => 4, quanta => 40);
cmp_ok(highness($x, 24000), '<', 0.7 * highness($x, 2400), 'damped: the highs die sooner');
$x = pluck(57, string_damp => 0, string_decay => 4, quanta => 40);
cmp_ok(highness($x, 24000), '>', 0.9 * highness($x, 2400), 'undamped: they stay');

# Plucked in the middle: no even harmonics.
$x = pluck(57, string_pick => 0.5, string_damp => 0.1);
cmp_ok(at($x, 440, 2400, 9600), '<', 0.1 * at($x, 220, 2400, 9600), 'plucked in the middle: hardly a second harmonic');
$x = pluck(57, string_pick => 0.13, string_damp => 0.1);
cmp_ok(at($x, 440, 2400, 9600), '>', 0.2 * at($x, 220, 2400, 9600), 'near the end: a strong one');

# Harder, brighter.
my @bright = map {
    my $p = pluck(57, string_damp => 0.1, string_bright => 0.3, string_vel => 2, velocity => $_);
    at($p, 220 * 10, 1200, 2400) / at($p, 220, 1200, 2400);
} 40, 127;
cmp_ok($bright[1], '>', 2 * $bright[0], 'a harder pluck has more of its tenth harmonic');

# Struck: the harmonics do not fall as a pluck's do (1/k); the nodes the same.
my %fifth = map {
    my $p = pluck(57, string_excite => $_, string_damp => 0.1, string_bright => 1, string_noise => 0);
    $_ => at($p, 220 * 5, 1200, 9600) / at($p, 220, 1200, 9600);
} qw(pluck strike);
cmp_ok($fifth{strike}, '>', 3 * $fifth{pluck}, 'struck: the fifth harmonic some five times stronger than plucked');
$x = pluck(57, string_excite => 'strike', string_pick => 0.5, string_damp => 0.1, string_noise => 0);
cmp_ok(at($x, 440, 2400, 9600), '<', 0.1 * at($x, 220, 2400, 9600), 'struck in the middle: hardly a second harmonic');

# Stiff: harmonic k at k sqrt(1 + B k^2) / sqrt(1 + B), the fundamental in tune.
# The strongest frequency within 3 % of where it should be, over a second
# (a struck string's harmonics are strong all round; a shorter stretch
# leans towards them): steps of 0.1 %, then of 0.005 % round the best.
sub peak ($x, $want) {
    my ($best, $f) = (0, $want);
    for my $step ([ $want * 0.97, $want * 1.03, $want * 0.001 ], [ undef, undef, $want * 0.00005 ]) {
        my ($from, $to, $by) = @$step;
        ($from, $to) = ($f - 20 * $by, $f + 20 * $by) unless defined $from;
        for (my $hz = $from; $hz <= $to; $hz += $by) {
            my $e = at($x, $hz, 4800, 48000);
            ($best, $f) = ($e, $hz) if $e > $best;
        }
    }
    return $f;
}
my $B = 0.0004;
$x = pluck(45, string_stiff => $B, string_damp => 0.1, string_decay => 8, string_excite => 'strike', string_noise => 0, quanta => 52);
near(cents(peak($x, 110), 110), 0, 1, 'stiff: the fundamental in tune');
for my $k (4, 8) {
    my $want = 110 * $k * sqrt((1 + $B * $k * $k) / (1 + $B));
    near(cents(peak($x, $want), $want), 0, 3, "harmonic $k stretched " . sprintf('%.0f', cents($want, 110 * $k)) . ' cents');
}
$x = pluck(45, string_damp => 0.1, string_decay => 8, string_excite => 'strike', string_noise => 0, quanta => 52);
near(cents(peak($x, 880), 880), 0, 2, 'not stiff: harmonic 8 where it is');
for my $key (40, 69, 88) {
    my $want = 440 * 2**(($key - 69) / 12);
    near(cents(pitch(pluck($key, string_damp => 0.2, string_stiff => 0.002), $want), $want), 0, 2, "key $key, stiff: in tune");
}

# Bent, it follows.
my $s = Peta::Synth::Synth->new(rate => $rate, partials => 8, engine => $engine, limiter => 0);
$s->reverb->set(on => 0);
$s->apply_edits({ programs => { 0 => { partials => [], string => 1, string_key => 0, string_damp => 0.2, sustain => 1 } } });
$s->play({ type => 'note_on', channel => 0, key => 57, velocity => 100 });
$s->play({ type => 'pitch_bend', channel => 0, value => 8191 });
my @b;
push @b, @{ ($s->render_arrays(1024))[0] } for 1 .. 24;
near(cents(pitch(\@b, 220 * 2**(2 / 12)), 220 * 2**(2 / 12)), 0, 3, 'bent two semitones up: there');

done_testing;
