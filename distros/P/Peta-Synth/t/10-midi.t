use v5.36;
use Test::More;
use lib 'lib';
use Peta::Synth::MIDI;

# A file written and read back holds the same events.
my $midi = Peta::Synth::MIDI->new(division => 480, tracks => [
    [ { tick => 0, type => 'tempo', usec => 500_000 },
      { tick => 960, type => 'tempo', usec => 250_000 } ],
    [ { tick => 0,    type => 'program',    channel => 2, program => 40 },
      { tick => 0,    type => 'note_on',    channel => 2, key => 60, velocity => 100 },
      { tick => 480,  type => 'note_off',   channel => 2, key => 60, velocity => 64 },
      { tick => 480,  type => 'controller', channel => 2, number => 64, value => 127 },
      { tick => 960,  type => 'pitch_bend', channel => 2, value => -8192 },
      { tick => 1440, type => 'note_on',    channel => 2, key => 62, velocity => 90 },
      { tick => 1920, type => 'note_off',   channel => 2, key => 62, velocity => 0 } ],
]);
my $again = Peta::Synth::MIDI->parse($midi->bytes);
is($again->format, 1, 'format');
is($again->division, 480, 'division');
is(scalar @{ $again->tracks }, 2, 'tracks');
my @events = grep { $_->{type} ne 'meta' } @{ $again->tracks->[1] };
is_deeply([ map { [ @$_{qw(tick type)} ] } @events ],
    [ [ 0, 'program' ], [ 0, 'note_on' ], [ 480, 'note_off' ], [ 480, 'controller' ], [ 960, 'pitch_bend' ],
      [ 1440, 'note_on' ], [ 1920, 'note_off' ] ], 'events come back in order');
is($events[4]{value}, -8192, 'pitch bend keeps its sign');

# The tempo map: 120 bpm for two beats (1 s), then 240 bpm.
my %time = map { ("$_->{type}$_->{tick}" => $_->{time}) } @{ $again->timeline };
cmp_ok(abs($time{note_off480} - 0.5), '<', 1e-9, 'a beat at 120 bpm is half a second');
cmp_ok(abs($time{note_on1440} - 1.25), '<', 1e-9, 'after the tempo change a beat is a quarter second');

# At the same tick, what the file says first happens first: a note off and a
# pedal mean different things in the two orders.
for my $order ([qw(note_off controller)], [qw(controller note_off)]) {
    my @track = ({ tick => 0, type => 'note_on', channel => 0, key => 60, velocity => 100 },
        map { { tick => 96, type => $_, channel => 0, key => 60, number => 64, value => 127 } } @$order);
    my $file = Peta::Synth::MIDI->parse(Peta::Synth::MIDI->new(division => 96, tracks => [ \@track ])->bytes);
    my @got = map { $_->{type} } grep { $_->{tick} == 96 && $_->{type} ne 'meta' } @{ $file->timeline };
    is_deeply(\@got, $order, "@$order: kept in the order of the file");
}

# Running status, and a note on with velocity 0 read as a note off.
my $track = "\x00\x90\x3c\x64" . "\x60\x3c\x00" . "\x00\x40\x50" . "\x60\x40\x00" . "\x00\xff\x2f\x00";
my $bytes = pack('a4 N n n n', 'MThd', 6, 0, 1, 96) . pack('a4 N', 'MTrk', length $track) . $track;
my @parsed = grep { $_->{type} ne 'meta' } @{ Peta::Synth::MIDI->parse($bytes)->tracks->[0] };
is_deeply([ map { [ @$_{qw(tick type key)} ] } @parsed ],
    [ [ 0, 'note_on', 60 ], [ 96, 'note_off', 60 ], [ 96, 'note_on', 64 ], [ 192, 'note_off', 64 ] ],
    'running status and velocity 0');

# Format 2: the sequences one after another.
my $two = Peta::Synth::MIDI->new(format => 2, division => 96, tracks => [
    [ { tick => 0, type => 'note_on', channel => 0, key => 60, velocity => 1 }, { tick => 96, type => 'note_off', channel => 0, key => 60 } ],
    [ { tick => 0, type => 'note_on', channel => 0, key => 62, velocity => 1 }, { tick => 96, type => 'note_off', channel => 0, key => 62 } ],
]);
my ($second) = grep { $_->{type} eq 'note_on' && $_->{key} == 62 } @{ $two->timeline };
cmp_ok(abs($second->{time} - 0.5), '<', 1e-9, 'the second sequence of a format 2 file follows the first');

ok(!eval { Peta::Synth::MIDI->parse('not a midi file') }, 'not a MIDI file: dies');

done_testing;
