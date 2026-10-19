use v5.36;
use Test::More;
use lib 'lib';
use Peta::Synth::Arpeggiator;
use Peta::Synth::Synth;
use Peta::Synth::Engine;

# The arpeggiator: the keys held played one after another, in a pattern, in time.

my $rate = 48000;
sub arp (%settings) { return Peta::Synth::Arpeggiator->new(rate => $rate, settings => { on => 1, rate => '1/16', tempo => 120, %settings }) }
sub ons (@events) { return [ map { $_->[1]{key} } grep { $_->[1]{type} eq 'note_on' } @events ] }

# A chord of C major (pressed G, C, E), each pattern over its first steps.
my $arp;
my %want = (
    up           => [ 60, 64, 67, 60, 64, 67, 60 ],
    down         => [ 67, 64, 60, 67, 64, 60, 67 ],
    updown       => [ 60, 64, 67, 64, 60, 64, 67 ],
    downup       => [ 67, 64, 60, 64, 67, 64, 60 ],
    played       => [ 67, 60, 64, 67, 60, 64, 67 ],
    converge     => [ 60, 67, 64, 60, 67, 64, 60 ],
    diverge      => [ 64, 67, 60, 64, 67, 60, 64 ],
    pedal_up     => [ 60, 64, 60, 67, 60, 64, 60 ],
    pedal_down   => [ 67, 64, 67, 60, 67, 64, 67 ],
    pedal_updown => [ 60, 64, 60, 67, 64, 67, 60 ],
);
for my $mode (sort keys %want) {
    $arp = arp(mode => $mode);
    $arp->press($_, 100, 0) for 67, 60, 64;
    is_deeply(ons($arp->play(0, 7 * 6000)), $want{$mode}, "$mode");
}
$arp = arp(mode => 'random');
$arp->press($_, 100, 0) for 60, 64, 67;
my @random = @{ ons($arp->play(0, 40 * 6000)) };
is(scalar @random, 40, 'random: a note a step');
is_deeply([ sort { $a <=> $b } keys %{ { map { $_ => 1 } @random } } ], [ 60, 64, 67 ], 'every key, none other');

$arp = arp(mode => 'chord');
$arp->press($_, 100, 0) for 60, 64, 67;
my @chord = grep { $_->[1]{type} eq 'note_on' } $arp->play(0, 2 * 6000);
is_deeply([ map { $_->[0] } @chord ], [ 480, 480, 480, 6480, 6480, 6480 ], 'chord: every key at each step');

$arp = arp(octaves => 2);
$arp->press($_, 100, 0) for 60, 64, 67;
is_deeply(ons($arp->play(0, 7 * 6000)), [ 60, 64, 67, 72, 76, 79, 60 ], 'two octaves: the keys again an octave up');

# Timing: at 120 beats a minute, a sixteenth is 6000 samples; the note off
# a gate later; swing moves every second step.
$arp = arp(gate => 0.25);
$arp->press(60, 90, 100);
my @events = $arp->play(0, 12500);
is_deeply([ map { [ $_->[0], $_->[1]{type} ] } @events ],
    [ [ 580, 'note_on' ], [ 2080, 'note_off' ], [ 6580, 'note_on' ], [ 8080, 'note_off' ] ], 'a step each 6000 samples, from 10 ms after the key (its chord); a gate a quarter of it');
is($events[0][1]{velocity}, 90, "the key's velocity");
ok($events[0][1]{arp}, "marked as the arpeggiator's");

$arp = arp(swing => 0.5, rate => '1/8');
$arp->press(60, 100, 0);
is_deeply([ map { $_->[0] } grep { $_->[1]{type} eq 'note_on' } $arp->play(0, 48000) ], [ 480, 18480, 24480, 42480 ],
    'swung eighths: the second of each pair half a step later');

# The keys let go: it stops; latched, it goes on until another chord comes.
$arp = arp();
$arp->press(60, 100, 0);
$arp->play(0, 6000);
$arp->release(60, 6000);
is(scalar @{ ons($arp->play(6000, 60000)) }, 0, 'let go: no more steps');
$arp = arp(latch => 1);
$arp->press($_, 100, 0) for 60, 64;
$arp->release($_, 100) for 60, 64;
is_deeply(ons($arp->play(0, 4 * 6000)), [ 60, 64, 60, 64 ], 'latched: it goes on');
$arp->press(70, 100, 24000);
is_deeply(ons($arp->play(24000, 36000)), [ 70, 70 ], 'and another chord replaces it');

# The latch let go: what is no longer held down is forgotten, at once.
$arp = arp(latch => 1);
$arp->press($_, 100, 0) for 55, 59, 62;
$arp->release($_, 100) for 55, 59, 62;
$arp->play(0, 12000);
$arp->set(latch => 0);
$arp->press($_, 100, 12000) for 57, 60, 65;
is_deeply([ sort { $a <=> $b } @{ ons($arp->play(12000, 30000)) } ], [ 57, 60, 65 ], 'latch off: the latched chord gone, the keys held play');
$arp->release($_, 30000) for 57, 60, 65;
$arp->press($_, 100, 30000) for 59, 62, 67;
is_deeply([ sort { $a <=> $b } keys %{ { map { $_ => 1 } @{ ons($arp->play(30000, 60000)) } } } ], [ 59, 62, 67 ], 'and none of it comes back');

eval { arp(mode => 'sideways') };
like($@, qr/no arpeggiator mode/, 'an unknown mode dies');

# In the synthesizer: the channel's keys go to it, and it plays them.
my $synth = Peta::Synth::Synth->new(rate => 24000, partials => 8, engine => Peta::Synth::Engine::create('perl'), limiter => 0);
$synth->set_arpeggiator(0, on => 1, mode => 'up', rate => '1/8', tempo => 120);
my %started;
my $count = 0;
{
    no warnings 'redefine';
    my $voice = \&Peta::Synth::Synth::_voice;
    local *Peta::Synth::Synth::_voice = sub ($self, $c, $key, @rest) {
        $count++;
        $started{$key}++;
        return $voice->($self, $c, $key, @rest);
    };
    $synth->play({ type => 'note_on', channel => 0, key => $_, velocity => 100 }) for 60, 67;
    $synth->render_arrays(512) for 1 .. 46;    # 0.98 s
    is($count, 4, 'four eighths a second at 120 beats a minute');
    is_deeply(\%started, { 60 => 2, 67 => 2 }, 'the keys in turn, not the keys themselves besides');

    $synth->set_arpeggiator(0, on => 0);
    $synth->render_arrays(512) for 1 .. 60;
    is($count, 4, 'turned off: it stops');
    ok(!grep({ !defined $_->{released} } @{ $synth->{active} }), 'and lets go what it played');
}
is($synth->edits->{master}{arps}{0}{rate}, '1/8', 'saved with the bank');
my $again = Peta::Synth::Synth->new(rate => 24000, partials => 8, engine => Peta::Synth::Engine::create('perl'));
$again->apply_edits($synth->edits);
is($again->arpeggiator(0)->params->{tempo}, 120, 'and applied');
ok(!exists $synth->edits->{master}{arps}{1}, 'the others as they were');

# Steered by MIDI: NRPN 0x7D and data entry, CC 80 and 81, a file's tempo.
my $s = Peta::Synth::Synth->new(rate => 24000, partials => 8, engine => Peta::Synth::Engine::create('perl'));
my $cc = sub ($number, $value) { $s->play({ type => 'controller', channel => 2, number => $number, value => $value }) };
my $nrpn = sub ($setting, $msb, $lsb = undef) {
    $cc->(99, 0x7d);
    $cc->(98, $setting);
    $cc->(6, $msb);
    $cc->(38, $lsb) if defined $lsb;
};
$nrpn->(0, 127);
$nrpn->(1, 9);
$nrpn->(2, 2);
$nrpn->(3, 1, 12);
$nrpn->(4, 3);
$nrpn->(5, 64);
$nrpn->(6, 127);
is_deeply($s->arpeggiator(2)->params, { on => 1, mode => 'pedal_up', rate => '1/8T', tempo => 140, octaves => 3,
    gate => 64 / 127, swing => 0.5, latch => 0 }, 'NRPN 0x7D: on, pattern, rate, tempo of 14 bits, octaves, gate, swing');
$nrpn->(1, 99);
is($s->arpeggiator(2)->params->{mode}, 'pedal_up', 'a pattern out of range changes nothing');
$cc->(81, 127);
ok($s->arpeggiator(2)->params->{latch}, 'CC 81: latch');
$cc->(80, 0);
ok(!$s->arpeggiator(2)->on, 'CC 80: off');

$s->schedule([ { time => 0, type => 'tempo', usec => 500_000 * 120 / 96 } ]);
$s->render_arrays(512);
is($s->arpeggiator(2)->params->{tempo}, 96, "a file's tempo: the arpeggiators'");
is($s->arpeggiator(5)->params->{tempo}, 96, 'and that of one made after it');

# What a file sets lasts until a reset (a file played from a point, the
# next file): then the arpeggiator is as its own settings are, which the
# bank keeps.
$s->set_arpeggiator(4, mode => 'down', rate => '1/8');
$s->schedule([ map { { time => 0, type => 'controller', channel => 4, %$_ } }
    { number => 80, value => 127 }, { number => 99, value => 0x7d }, { number => 98, value => 1 }, { number => 6, value => 2 } ]);
$s->render_arrays(512);
is_deeply([ @{ $s->arpeggiator(4)->params }{qw(on mode rate)} ], [ 1, 'updown', '1/8' ], "the file's switch and pattern");
is_deeply([ map { $_->{mode} // '' } @{ $s->edits->{master}{arps} }{ 2, 4 } ], [ '', 'down' ], 'the bank: the own settings, not the file\'s');
$s->reset_channels;
is_deeply([ @{ $s->arpeggiator(4)->params }{qw(on mode rate tempo)} ], [ 0, 'down', '1/8', 120 ], 'reset: its own settings again');
ok(!$s->arpeggiator(2)->on, 'one the file alone turned on is off');

done_testing;
