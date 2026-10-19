use v5.36;
use Test::More;
use lib 'lib';
use Peta::Synth::Synth;
use Peta::Synth::Engine;
use Peta::Synth::Patch;
use Peta::Synth::Voice;

# The filter that moves, the second envelope, the LFOs, the routes.

my $rate = 24000;
my $engine = Peta::Synth::Engine::create('perl');
sub near ($got, $want, $tol, $name) { cmp_ok(abs($got - $want), '<=', $tol, $name) or diag "got $got, want $want" }
sub gain (@args) { return Peta::Synth::Voice::filter_gain(@args) }

# The filter's gains: what each mode is.
near(gain(1, 4, 1), 4, 1e-12, 'low-pass, 12 dB: Q at the cutoff');
near(gain(0.01, 4, 1), 1, 1e-3, 'and 1 far below');
near(20 * log(gain(10, 0.7071, 1)) / log(10), -40, 0.1, 'and 12 dB an octave above (40 a decade)');
near(20 * log(gain(10, 0.7071, 2)) / log(10), -80, 0.1, '24 dB an octave: 80 a decade');
near(gain(100, 2, 3), 1, 1e-3, 'high-pass: 1 far above');
near(gain(0.1, 0.7071, 3), 0.01, 1e-4, 'and 12 dB an octave below');
near(gain(1, 5, 5), 1, 1e-12, 'band-pass: 1 at the centre');
cmp_ok(gain(2, 5, 5), '<', 0.2, 'and narrow at a Q of 5');
is(gain(3, 1, 0), 1, 'no filter: 1');

sub synth (%bank) {
    my $s = Peta::Synth::Synth->new(rate => $rate, partials => 16, engine => $engine, limiter => 0);
    $s->apply_edits({ programs => { 0 => {%bank} } });
    return $s;
}
sub play_note ($s, $key = 60) {
    $s->play({ type => 'note_on', channel => 0, key => $key, velocity => 100 });
    return $s->{active}[-1];
}

# The filter's controls: the fundamental over the cutoff, the Q.
my $s = synth(filter => 'lp12', filter_cutoff => 1000, filter_q => 3, filter_track => 0);
my $v = play_note($s, 69);
$s->render_arrays(1024);
near($v->{fx}[-1], 440 / 1000, 1e-9, 'fx: the fundamental over the cutoff');
near($v->{fq}[-1], 3, 1e-12, 'fq: the Q');
near($v->{boost}, 3, 1e-12, 'a resonance counts in how loud the voice may get');
$s = synth(filter => 'lp12', filter_cutoff => 1000, filter_track => 1);
$v = play_note($s, 72);
$s->render_arrays(1024);
near($v->{fx}[-1], 523.2511306 / (1000 * 523.2511306 / 261.6), 1e-6, 'tracking the key: the same ratio an octave up');
$s = synth();
$v = play_note($s);
ok(!$v->{fmode} && !$v->{mod}, 'a patch without filter or routes: none of it');

# The second envelope sweeps the cutoff: up in the attack, down to sustain.
$s = synth(filter => 'lp24', filter_cutoff => 500, filter_track => 0, filter_env => 3, env2_attack => 0.02, env2_decay => 0.02, env2_sustain => 0);
$v = play_note($s, 69);
my @fx;
for (1 .. 40) { $s->render_arrays(128); push @fx, $v->{fx}[-1] }
my ($low) = sort { $a <=> $b } @fx;
near($low, 440 / (500 * 8), 0.02, 'at the envelope\'s peak, three octaves up');
near($fx[-1], 440 / 500, 0.01, 'and back at the cutoff once it has decayed');

# Brightness (CC74) and resonance (CC71) move a sounding note's filter.
$s = synth(filter => 'lp12', filter_cutoff => 1000, filter_track => 0);
$v = play_note($s, 69);
$s->render_arrays(256);
$s->play({ type => 'controller', channel => 0, number => 74, value => 80 });
$s->play({ type => 'controller', channel => 0, number => 71, value => 88 });
$s->render_arrays(256);
near($v->{fx}[-1], 0.44 / 2, 1e-9, 'CC74: 16 steps up, an octave up');
near($v->{fq}[-1], 0.71 * 2, 1e-9, 'CC71: 24 steps up, twice the Q');

# The LFOs' shapes, from the note's start.
my $lv = Peta::Synth::Voice->new(Peta::Synth::Patch::program(0), key => 60, velocity => 100, rate => $rate, seed => 7);
near($lv->_lfo([ 2, 0, 0 ], 0.125, 1), 1, 1e-12, 'sine: its top a quarter period in');
near($lv->_lfo([ 2, 1, 0 ], 0.125, 1), 1, 1e-12, 'triangle: the same');
near($lv->_lfo([ 2, 1, 0 ], 0.0625, 1), 0.5, 1e-12, 'and straight up to it');
is($lv->_lfo([ 2, 2, 0 ], 0.1, 1), 1, 'square: up the first half');
is($lv->_lfo([ 2, 2, 0 ], 0.3, 1), -1, 'down the second');
near($lv->_lfo([ 2, 3, 0 ], 0.25, 1), 0, 1e-12, 'saw: rising through 0 half way');
my ($r1, $r2, $r3) = map { $lv->_lfo([ 2, 4, 0 ], $_, 1) } 0.1, 0.4, 0.6;
is($r1, $r2, 'random: held through a period');
isnt($r2, $r3, 'another the next');
ok(abs($r3) <= 1, 'within -1 .. 1');
near($lv->_lfo([ 2, 0, 1 ], 0.125, 1), 0.125, 1e-12, 'a delay fades it in');

# Routes: an LFO on the pitch, velocity on the level, an LFO on the pan.
$s = synth(mods => [ [ 'lfo1', 'pitch', 1 ] ], lfo1_rate => 4, lfo1_shape => 'square');
$v = play_note($s, 69);
my @semis;
for (1 .. 12) { $s->render_arrays(256); push @semis, 12 * log($v->{w}[-1] / (6.283185307179586 * 440 / $rate)) / log(2) }
my ($down, $up) = (sort { $a <=> $b } @semis)[ 0, -1 ];
near($up, 1, 1e-9, 'an LFO on the pitch: a semitone up ...');
near($down, -1, 1e-9, '... and down');
my @levels = map {
    my $t = synth(mods => [ [ 'velocity', 'level', $_ ] ]);
    my $voice = play_note($t);
    $t->render_arrays(1024);
    $voice->{env}[-1];
} 0, -0.5;
near($levels[1] / $levels[0], 1 - 0.5 * 100 / 127, 1e-9, 'velocity on the level');
$s = synth(mods => [ [ 'lfo1', 'pan', 1 ] ], lfo1_rate => 2, lfo1_shape => 'square');
$v = play_note($s);
$s->render_arrays(1024);
cmp_ok($v->{gl}[-1], '<', 1e-9, 'an LFO on the pan: all to one side (its first half, right)');
$s = synth(mods => [ [ 'wheel', 'cutoff', 2 ] ], filter => 'bp', filter_cutoff => 1000, filter_track => 0);
$v = play_note($s, 69);
$s->play({ type => 'controller', channel => 0, number => 1, value => 127 });
$s->render_arrays(256);
near($v->{fx}[-1], 0.44 / 4, 1e-9, 'the wheel on the cutoff: two octaves at full');

# What is not a source or destination is refused.
ok(!eval { synth(mods => [ [ 'nonsense', 'pitch', 1 ] ]) && play_note(synth(mods => [ [ 'nonsense', 'pitch', 1 ] ])); 1 }, 'an unknown source dies');
like($@, qr/nonsense/, 'saying which');

done_testing;
