use v5.36;
use Test::More;
use lib 'lib';
use Peta::Synth::Synth;
use Peta::Synth::Engine;
use Peta::Synth::MIDI;

# MIDI beyond notes: controllers, RPN and NRPN, system exclusive, modes.

my $rate = 24000;
my $engine = Peta::Synth::Engine::create('perl');
sub synth (%arg) { return Peta::Synth::Synth->new(rate => $rate, partials => 12, engine => $engine, %arg) }
sub cc ($s, $ch, $n, $v) { $s->play({ type => 'controller', channel => $ch, number => $n, value => $v }) }
sub on ($s, $ch, $key, $vel = 100) { $s->play({ type => 'note_on', channel => $ch, key => $key, velocity => $vel }) }
sub off ($s, $ch, $key, $vel = 64) { $s->play({ type => 'note_off', channel => $ch, key => $key, velocity => $vel }) }
sub sysex ($s, @bytes) { $s->play({ type => 'sysex', data => pack 'C*', @bytes }) }
sub voices ($s, $ch = 0) { return grep { $_->{channel} == $ch } @{ $s->{active} } }
sub rms ($x) { my $sum = 0; $sum += $_**2 for @$x; return sqrt($sum / @$x) }
# A voice's pitch now, in semitones from its key's: from its last block's frequency.
sub semis ($v) { return 12 * log($v->{w}[-1] / (6.283185307179586 * $v->{f0} / $rate)) / log(2) }
sub near ($got, $want, $tol, $name) { cmp_ok(abs($got - $want), '<', $tol, $name) or diag "got $got, want $want" }

# Single messages as a device sends them.
is_deeply(Peta::Synth::MIDI::message("\x91\x3c\x40"), { type => 'note_on', channel => 1, key => 60, velocity => 64 }, 'a note on');
is(Peta::Synth::MIDI::message("\x90\x3c\x00")->{type}, 'note_off', 'velocity 0 is a note off');
is_deeply(Peta::Synth::MIDI::message("\xd2\x55"), { type => 'channel_pressure', channel => 2, value => 85 }, 'channel pressure');
is(Peta::Synth::MIDI::message("\xe0\x00\x40")->{value}, 0, 'the bend centred');
is_deeply(Peta::Synth::MIDI::message("\xf0\x7e\x7f\x09\x01\xf7"), { type => 'sysex', data => "\x7e\x7f\x09\x01\xf7" }, 'system exclusive');
ok(!defined Peta::Synth::MIDI::message("\xf8"), 'the clock is no event');
ok(!defined Peta::Synth::MIDI::message("\x90\x3c"), 'a message cut short neither');

# Master volume (universal), balance; GS master volume; the reset.
my @level;
for my $volume (16383, 8192) {
    my $s = synth(limiter => 0);
    sysex($s, 0x7f, 0x7f, 0x04, 0x01, $volume & 0x7f, $volume >> 7, 0xf7);
    on($s, 0, 60);
    push @level, rms(($s->render_arrays(2048))[0]);
}
near($level[1] / $level[0], 8192 / 16383, 1e-6, 'master volume: half, half as loud');
my $s = synth(limiter => 0);
sysex($s, 0x7f, 0x7f, 0x04, 0x02, 0x7f, 0x7f, 0xf7);    # balance: right
on($s, 0, 60);
my ($l, $r) = $s->render_arrays(2048);
cmp_ok(rms($l), '<', 1e-3 * rms($r), 'balance to the right: the left silent');
$s = synth();
sysex($s, 0x41, 0x10, 0x42, 0x12, 0x40, 0x00, 0x04, 64, 0x3c, 0xf7);
near($s->{master}{volume}, 64 / 127, 1e-9, 'GS master volume');
cc($s, 3, 7, 20);
sysex($s, 0x7e, 0x7f, 0x09, 0x01, 0xf7);
is($s->channel(3)->{volume}, 100, 'GM System On resets the channels');
is($s->{master}{volume}, 1, 'and the master');
cc($s, 3, 7, 20);
sysex($s, 0x41, 0x10, 0x42, 0x12, 0x40, 0x00, 0x7f, 0x00, 0x41, 0xf7);
is($s->channel(3)->{volume}, 100, 'so does a GS reset');
cc($s, 3, 7, 20);
sysex($s, 0x43, 0x10, 0x4c, 0x00, 0x00, 0x7e, 0x00, 0xf7);
is($s->channel(3)->{volume}, 100, 'and XG System On');

# Drum parts by system exclusive: GS part 2 is channel 1; XG part 5 channel 5.
$s = synth();
sysex($s, 0x41, 0x10, 0x42, 0x12, 0x40, 0x12, 0x15, 0x01, 0x18, 0xf7);
ok($s->channel(1)->{drum}, 'GS: a part made a rhythm part');
sysex($s, 0x41, 0x10, 0x42, 0x12, 0x40, 0x10, 0x15, 0x00, 0x1b, 0xf7);
ok(!$s->channel(9)->{drum}, 'and part 10 made a normal one');
sysex($s, 0x43, 0x10, 0x4c, 0x08, 0x05, 0x07, 0x01, 0xf7);
ok($s->channel(5)->{drum}, 'XG: a part made a drum part');
cc($s, 5, 0, 121);
ok(!$s->channel(5)->{drum}, 'bank 121 is melodic again');

# Variations: the bank selected before a program change picks one; GS's
# bank where there is the variation, GM2's by its LSB, else the program.
is(Peta::Synth::Patch::variation(8, 0, 4),    8,  'GS: bank 8 of program 4 is a variation');
is(Peta::Synth::Patch::variation(8, 0, 0),    0,  'GS: no variation, the program');
is(Peta::Synth::Patch::variation(121, 1, 4),  8,  "GM2: LSB 1 of program 4 is GS's bank 8");
is(Peta::Synth::Patch::variation(121, 2, 25), 16, "GM2: LSB 2 of program 25 (mandolin) is GS's bank 16");
is(Peta::Synth::Patch::variation(0, 32, 4),   0,  "XG's: the program");
is(Peta::Synth::Patch::program_name(4, 8), 'Detuned EP 1', "a variation's name");
$s = synth();
cc($s, 0, 0, 8);
is($s->channel(0)->{variation}, 0, 'a bank select alone picks nothing');
$s->play({ type => 'program', channel => 0, program => 4 });
is($s->channel(0)->{variation}, 8, 'the program change after it does');
$s->program_patch(4, 8)->{level} = 0;
on($s, 0, 60);
is(rms(($s->render_arrays(2048))[0]), 0, "the variation's patch plays");
$s->play({ type => 'program', channel => 0, program => 0 });
is($s->channel(0)->{variation}, 0, 'the same bank, a program without a variation');
cc($s, 1, 0, 121);
cc($s, 1, 32, 1);
$s->play({ type => 'program', channel => 1, program => 6 });
is($s->channel(1)->{variation}, 8, 'GM2 by bank select');

# Drum kits: a program change on a drum channel; a kit's key it does not
# have as its own is the standard kit's.
is(Peta::Synth::Patch::kit(25), 25, 'the TR-808 kit');
is(Peta::Synth::Patch::kit(9),  8,  "GS's Room 2 is the room kit");
is(Peta::Synth::Patch::kit(56), 0,  'a kit not here: the standard kit');
$s->play({ type => 'program', channel => 9, program => 40 });
is($s->channel(9)->{kit}, 40, 'a drum channel picks a kit');
my %kits = %{ Peta::Synth::Patch::kits() };
my ($inherited) = grep { my $k = $_; !grep { $_ == $k } @{ $kits{40}{keys} } } 35 .. 81;
is($s->drum_patch($inherited, 40), $s->drum_patch($inherited), "a key the kit does not have: the standard kit's patch");
isnt($s->drum_patch(38, 40), $s->drum_patch(38), 'one it has: its own');
is(Peta::Synth::Patch::drum(58, 25)->{level}, 0, "the TR-808 kit has no vibraslap, as FluidR3's has none");
cmp_ok(abs(Peta::Synth::Patch::drum(41, 48)->{fixed} - 87.31), '<', 0.1, "the orchestra kit's timpani, F at key 41");

# Edits of a variation, saved and applied as 'bank:program'.
$s = synth();
$s->program_patch(4, 8)->{cutoff} = 1234;
is($s->edits->{programs}{'8:4'}{cutoff}, 1234, "a variation's edit, as 'bank:program'");
is(synth()->apply_edits($s->edits)->program_patch(4, 8)->{cutoff}, 1234, 'and applied');
is(synth()->apply_edits($s->edits)->program_patch(4)->{cutoff}, Peta::Synth::Patch::program(4)->{cutoff}, 'not to the program');

# Scheduled from a file, system exclusive takes effect too.
$s = synth();
$s->schedule([ { time => 0, type => 'sysex', data => "\x7f\x7f\x04\x01\x00\x20\xf7" } ]);
$s->render_arrays(1024);
near($s->{master}{volume}, 32 * 128 / 16383, 1e-9, 'a scheduled system exclusive message');

# Tuning: master coarse and fine; RPN 1 and 2; with the bend.
$s = synth();
sysex($s, 0x7f, 0x7f, 0x04, 0x04, 0, 66, 0xf7);    # +2 semitones
sysex($s, 0x7f, 0x7f, 0x04, 0x03, 0, 0x60, 0xf7);  # +0.5
on($s, 0, 60);
$s->render_arrays(1024);
near(semis((voices($s))[0]), 2.5, 1e-6, 'master tuning: coarse and fine');
$s = synth();
cc($s, 0, 101, 0); cc($s, 0, 100, 2); cc($s, 0, 6, 61);    # coarse -3
cc($s, 0, 101, 0); cc($s, 0, 100, 1); cc($s, 0, 6, 0x60); cc($s, 0, 38, 0);    # fine +0.5
on($s, 0, 60);
$s->play({ type => 'pitch_bend', channel => 0, value => 4096 });    # +1 of the 2-semitone range
$s->render_arrays(1024);
near(semis((voices($s))[0]), -3 + 0.5 + 1, 1e-6, 'RPN tuning, with the bend');
cc($s, 0, 101, 127); cc($s, 0, 100, 127); cc($s, 0, 6, 0);
is($s->channel(0)->{tune}, -2.5, 'RPN null: data entry sets nothing');
cc($s, 0, 101, 0); cc($s, 0, 100, 0); cc($s, 0, 96, 0); cc($s, 0, 96, 0);
near($s->channel(0)->{range}, 2.02, 1e-9, 'data increment: the bend range by a cent');

# The modulation range (RPN 5) and the pressures deepen the vibrato.
$s = synth();
cc($s, 0, 101, 0); cc($s, 0, 100, 5); cc($s, 0, 6, 1); cc($s, 0, 38, 0);    # a semitone
cc($s, 0, 1, 127);
on($s, 0, 60);
my @w;
for (1 .. 30) { $s->render_arrays(1024); push @w, semis((voices($s))[0]) }
my ($lo, $hi) = (sort { $a <=> $b } @w)[ 0, -1 ];
cmp_ok($hi - $lo, '>', 1.2, 'RPN 5: a full wheel swings the pitch by about a semitone up and down');
$s = synth();
on($s, 0, 60);
$s->play({ type => 'channel_pressure', channel => 0, value => 127 });
@w = ();
for (1 .. 30) { $s->render_arrays(1024); push @w, semis((voices($s))[0]) }
($lo, $hi) = (sort { $a <=> $b } @w)[ 0, -1 ];
cmp_ok($hi - $lo, '>', 0.6, 'channel pressure deepens the vibrato');
$s = synth();
on($s, 0, 60); on($s, 0, 64);
$s->play({ type => 'key_pressure', channel => 0, key => 64, value => 127 });
my %by_key = map { $_->{key} => $_ } voices($s);
is($by_key{64}{pressure}, 1, 'key pressure: on its key');
is($by_key{60}{pressure}, 0, 'not on another');

# The sound controllers, on new notes: attack, release, brightness, resonance.
$s = synth();
cc($s, 0, 73, 96);    # attack twice as long ...
cc($s, 0, 72, 48);    # release half as long
on($s, 0, 60);
my $v = (voices($s))[0];
my ($attack) = $v->_envelope;
near($attack, 4 * $v->{patch}{attack}, 1e-12, 'CC73: the attack four times as long (two steps of 16)');
near($v->{shape}{release}, 0.5, 1e-12, 'CC72: the release half');
my @spectra;
for my $bright (32, 64, 96) {
    my $t = synth();
    cc($t, 0, 74, $bright);
    on($t, 0, 48);
    my $voice = (voices($t))[0];
    my $high = 0;
    $high += $voice->{amp}[$_]**2 for grep { $voice->{ratio}[$_] > 6 } 0 .. $#{ $voice->{amp} };
    push @spectra, $high;
}
ok($spectra[0] < $spectra[1] && $spectra[1] < $spectra[2], 'CC74: brighter, more in the high partials');
$s = synth();
cc($s, 0, 71, 127);
on($s, 0, 48);
my $res = (voices($s))[0];
my $plain = do { my $p = synth(); on($p, 0, 48); (voices($p))[0] };
isnt(join(',', @{ $res->{amp} }), join(',', @{ $plain->{amp} }), 'CC71: resonance changes the spectrum');

# Vibrato depth (CC77), on a patch with vibrato of its own (violin).
my @swing = map {
    my $p = synth();
    $p->play({ type => 'program', channel => 0, program => 40 });
    cc($p, 0, 77, $_);
    on($p, 0, 60);
    my @pitch;
    for (1 .. 40) { $p->render_arrays(1024); push @pitch, semis((voices($p))[0]) }
    my ($low, $high) = (sort { $a <=> $b } @pitch)[ 0, -1 ];
    $high - $low;
} 64, 96;
cmp_ok($swing[0], '>', 0.02, 'the violin has a vibrato');
near($swing[1] / $swing[0], 4, 0.6, 'CC77: two steps of 16, four times as deep');

# The soft pedal: new notes quieter.
my @soft = map {
    my $p = synth();
    cc($p, 0, 67, $_);
    on($p, 0, 60);
    (voices($p))[0]{level};
} 0, 127;
near($soft[1] / $soft[0], 0.7, 1e-12, 'the soft pedal: 0.7 of the level');

# Note-off velocity: the release.
$s = synth();
on($s, 0, 60);
off($s, 0, 60, 127);
near((voices($s))[0]{rfactor}, 2**(-63 / 128), 1e-12, 'a fast note off: a shorter release');
$s = synth();
on($s, 0, 60);
off($s, 0, 60, 0);
is((voices($s))[0]{rfactor}, 1, 'velocity 0 says nothing');

# Portamento: from the last key, in the time CC5 says.
$s = synth();
cc($s, 0, 65, 127); cc($s, 0, 5, 64);
on($s, 0, 60); off($s, 0, 60);
on($s, 0, 67);
$v = (grep { $_->{key} == 67 } voices($s))[0];
$s->render_arrays(256);
cmp_ok(semis($v), '<', -3, 'portamento: the new note starts near the old key');
$s->render_arrays(1024) for 1 .. 10;
near(semis($v), 0, 1e-9, 'and arrives');
$s = synth();
cc($s, 0, 84, 48);
on($s, 0, 60);
$v = (voices($s))[0];
is($v->{glide}[0], -12, 'CC84: the next note glides from that key');

# Mono: one voice; a key over a held one takes over legato; let go, back.
$s = synth();
cc($s, 0, 126, 1);
on($s, 0, 60);
$s->render_arrays(1024);
on($s, 0, 64);
my @live = grep { !defined $_->{killed} } voices($s);
is(scalar @live, 1, 'mono: one voice');
is($live[0]{key}, 64, 'the new key');
ok($live[0]{legato}, 'legato: it takes over');
is(($live[0]->_envelope)[0], 0, 'without an attack');
off($s, 0, 64);
@live = grep { !defined $_->{killed} && !defined $_->{released} } voices($s);
is($live[0]{key}, 60, 'let go: the key still held sounds again');
off($s, 0, 60);
ok(!grep({ !defined $_->{killed} && !defined $_->{released} } voices($s)), 'let go too: silence');
cc($s, 0, 127, 0);
on($s, 0, 60); on($s, 0, 64);
is(scalar(grep { !defined $_->{killed} && !defined $_->{released} } voices($s)), 2, 'poly again: both');
$s = synth();
cc($s, 0, 68, 127);
on($s, 0, 60); on($s, 0, 64);
is(scalar(grep { !defined $_->{killed} } voices($s)), 1, 'the legato pedal: mono legato');

# Drums: the closed hi-hat cuts the open one; GS/XG drum key NRPNs.
$s = synth();
on($s, 9, 46);
on($s, 9, 42);
my ($open) = grep { $_->{key} == 46 } voices($s, 9);
ok(defined $open->{killed}, 'the closed hi-hat cuts the open one');
on($s, 9, 46);
($open) = grep { $_->{key} == 46 && !defined $_->{killed} } voices($s, 9);
on($s, 9, 36);
ok(!defined $open->{killed}, 'a kick cuts nothing');
$s = synth();
for ([ 0x18, 64 + 5 ], [ 0x1a, 64 ], [ 0x1c, 0 ], [ 0x1d, 0 ]) {
    cc($s, 9, 99, $_->[0]); cc($s, 9, 98, 38); cc($s, 9, 6, $_->[1]);
}
on($s, 9, 38);
on($s, 9, 40);
my ($snare) = grep { $_->{key} == 38 } voices($s, 9);
my ($other) = grep { $_->{key} == 40 } voices($s, 9);
near($snare->{f0} / Peta::Synth::Voice->new($s->drum_patch(38), key => 38, velocity => 100, rate => $rate)->{f0}, 2**(5 / 12), 1e-9,
    'NRPN: a drum key\'s pitch');
near($snare->{level} / $other->{level} / ($s->drum_patch(38)->{level} / $s->drum_patch(40)->{level}), (64 / 127)**2, 1e-9, 'its level');
is($snare->{pan}, -1, 'its pan');
is($snare->{send}, 0, 'its reverb');
ok(!$other->{pan}, 'another key as it was');
$s->render_arrays(1024);
cmp_ok($snare->{gr}[-1], '<', 1e-12, 'panned left: nothing on the right');
$s = synth();
cc($s, 0, 99, 1); cc($s, 0, 98, 0x20); cc($s, 0, 6, 80);
is($s->channel(0)->{sound}{74}, 80, 'NRPN: GS/XG cutoff, as CC74');

# Reset all controllers: what GM2 says, not the volume.
$s = synth();
cc($s, 0, 7, 50); cc($s, 0, 1, 100); cc($s, 0, 64, 127); cc($s, 0, 67, 127); cc($s, 0, 101, 0); cc($s, 0, 100, 0);
$s->play({ type => 'channel_pressure', channel => 0, value => 50 });
cc($s, 0, 121, 0);
my $c = $s->channel(0);
is_deeply([ @$c{qw(volume mod sustain soft pressure param)} ], [ 50, 0, 0, 0, 0, undef ], 'CC121');

# GM2's controller destinations: F0 7F dd 09 01 (channel pressure) / 02 (key
# pressure) / 03 (a controller) channel [cc] [parameter range] ...
sub pressure ($s, $ch, $v) { $s->play({ type => 'channel_pressure', channel => $ch, value => $v }) }
$s = synth();
sysex($s, 0x7f, 0x7f, 0x09, 0x01, 0, 0, 66, 0xf7);    # pressure: pitch +2 semitones at full
on($s, 0, 60);
pressure($s, 0, 127);
$s->render_arrays(1024);
($v) = voices($s);
near(semis($v), 2, 1e-9, 'channel pressure to pitch: +2 semitones at full');
pressure($s, 0, 64);
$s->render_arrays(1024);
near(semis($v), 2 * 64 / 127, 1e-9, 'in proportion to the pressure; and no vibrato of it any more');
sysex($s, 0x7f, 0x7f, 0x09, 0x01, 0, 0, 0x7f, 0xf7);
is($s->channel(0)->{dest}{chp}[0], 88, 'pitch held to +24 semitones');
sysex($s, 0x7e, 0x7f, 0x09, 0x01, 0xf7);
is_deeply($s->channel(0)->{dest}, {}, 'GM System On clears them');

$s = synth();
sysex($s, 0x7f, 0x7f, 0x09, 0x03, 2, 16, 0, 52, 0xf7);    # CC16 on channel 2: pitch -12
sysex($s, 0x7f, 0x7f, 0x09, 0x03, 2, 40, 0, 76, 0xf7);    # CC40: no source
ok(!$s->channel(2)->{dest}{40}, 'a controller outside 1-31, 64-95 is no source');
on($s, 2, 60);
cc($s, 2, 16, 127);
$s->render_arrays(1024);
($v) = voices($s, 2);
near(semis($v), -12, 1e-9, 'a controller to pitch');

# Key pressure: the key's voice alone.
$s = synth();
sysex($s, 0x7f, 0x7f, 0x09, 0x02, 0, 0, 76, 0xf7);
on($s, 0, 60); on($s, 0, 64);
$s->play({ type => 'key_pressure', channel => 0, key => 64, value => 127 });
$s->render_arrays(1024);
my %semis = map { $_->{key} => semis($_) } voices($s);
near($semis{64}, 12, 1e-9, 'key pressure to pitch: the key pressed');
near($semis{60}, 0, 1e-9, 'not the others');

# Amplitude: 0 silences at full, 127 is 127/64 times.
my %level;
for my $range (64, 0, 127) {
    my $s = synth(limiter => 0);
    sysex($s, 0x7f, 0x7f, 0x09, 0x01, 0, 2, $range, 0xf7);
    on($s, 0, 60);
    pressure($s, 0, 127);
    $level{$range} = rms(($s->render_arrays(2048))[0]);
}
cmp_ok($level{0}, '<', 1e-6 * $level{64}, 'amplitude 0: silent at full pressure');
near($level{127} / $level{64}, 127 / 64, 1e-6, 'amplitude 127: 127/64 times');

# The cutoff: a patch without a filter gets one; -9600 cents at full.
$s = synth(limiter => 0);
sysex($s, 0x7f, 0x7f, 0x09, 0x01, 0, 1, 0, 0xf7);
cc($s, 0, 91, 0);    # no reverb: its tail would outlast the cutoff's fall
on($s, 0, 60);
($v) = voices($s);
is($v->{fmode}, 1, 'a cutoff destination: a low-pass for a patch without a filter');
$s->render_arrays(1024);
my $unfiltered = rms(($s->render_arrays(1024))[0]);
near($v->{fx}[-1], $v->{f0} / ($rate / 2), 1e-9, 'at half the rate while the pressure is 0');
pressure($s, 0, 127);
$s->render_arrays(1024);
near($v->{fx}[-1], $v->{f0} / ($rate / 2 / 256), 1e-9, 'eight octaves down at full');
cmp_ok(rms(($s->render_arrays(1024))[0]), '<', 0.03 * $unfiltered, 'and it is all but gone');

# The LFO: its depth on pitch (600 cents at 127), on amplitude.
$s = synth();
sysex($s, 0x7f, 0x7f, 0x09, 0x01, 0, 3, 127, 5, 127, 0xf7);
on($s, 0, 60);
pressure($s, 0, 127);
my ($low, $high, $least, $most) = (0, 0, 1, 0);
for (1 .. 24) {
    $s->render_arrays(1024);
    ($v) = voices($s);
    for my $w (@{ $v->{w} }) {
        my $p = 12 * log($w / (6.283185307179586 * $v->{f0} / $rate)) / log(2);
        $low = $p if $p < $low;
        $high = $p if $p > $high;
    }
    for (@{ $v->{env} }) { my $e = $_ / $v->{level}; $least = $e if $e < $least }    # the piano's envelope holds at 1
}
cmp_ok($high, '>', 5, 'LFO pitch depth: up to 6 semitones up');
cmp_ok($low, '<', -5, 'and down');
cmp_ok($least, '<', 0.2, 'LFO amplitude depth: down to nothing');

# The wheel's vibrato, unless a destination says what the wheel does: the
# channel as a sounding note sees it.
$s = synth();
on($s, 0, 60);
cc($s, 0, 1, 127);
$s->render_arrays(1024);
cmp_ok($s->{state}[0]{mod}, '>', 0, 'the wheel: vibrato');
sysex($s, 0x7f, 0x7f, 0x09, 0x03, 0, 1, 0, 64, 0xf7);
$s->render_arrays(1024);
is($s->{state}[0]{mod}, 0, 'given a destination: what it says');

done_testing;
