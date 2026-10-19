use v5.36;
use Test::More;
use Time::HiRes qw(sleep);
use lib 'lib';
use Peta::MIDI::Decoder;
use Peta::MIDI::Encoder;

# MIDI bytes into events and back (Peta::MIDI::Decoder, ::Encoder).

sub decoded (@strings) {
    my $decoder = Peta::MIDI::Decoder->new;
    $decoder->decode(@strings);
    return [ map { $_->as_arrayref } $decoder->events ];
}

is_deeply(decoded("\x91\x3c\x64\x40\x50"), [ [ note_on => 1, 60, 100 ], [ note_on => 1, 64, 80 ] ], 'running status');
is_deeply(decoded("\x90\x3c\x00"), [ [ note_off => 0, 60, 0 ] ], 'a note on of velocity 0 is a note off');
is_deeply(decoded("\xb0\x07", "\xf8", "\x50"), [ ['clock'], [ control_change => 0, 7, 80 ] ], 'a clock tick inside a message, the message whole after it');
is_deeply(decoded("\xf0\x7e\x7f", "\x09\x01\xf7\xc2\x05"), [ [ sysex => "\x7e\x7f\x09\x01" ], [ program_change => 2, 5 ] ], 'system exclusive in pieces, and what follows');
is_deeply(decoded("\xf0\x43\x10\x90\x3c\x64"), [ [ sysex => "\x43\x10" ], [ note_on => 0, 60, 100 ] ], 'a status byte ends system exclusive');
is_deeply(decoded("\xe3\x00\x40\xe3\x00\x00"), [ [ pitch_bend => 3, 0 ], [ pitch_bend => 3, -8192 ] ], 'pitch bend, centred at 0');
is_deeply(decoded("\xf2\x10\x02\xfa\xf6"), [ [ song_position => 272 ], ['start'], ['tune_request'] ], 'system common and real time');
is_deeply(decoded("\x40\x50\xf4\x40"), [], 'data without a status, and after an undefined one, are dropped');

my $decoder = Peta::MIDI::Decoder->new(enable_14bit_cc => 1);
$decoder->decode("\xb0\x01\x10\xb0\x21\x05\xb0\x40\x7f");
is_deeply([ map { $_->as_arrayref } $decoder->events ], [ [ control_change => 0, 1, 16 * 128 + 5 ], [ control_change => 0, 64, 127 ] ],
    '14 bits: the coarse part kept back, given with the fine; the others as they are');

$decoder = Peta::MIDI::Decoder->new;
$decoder->decode("\x92\x40\x30");
my $event = $decoder->fetch_one_event;
is($event->name, 'note_on', 'an event: its name');
is($event->channel, 2, 'its channel');
is($event->bytes, "\x92\x40\x30", 'its bytes');
is_deeply($event->as_hashref, { name => 'note_on', channel => 2, note => 64, velocity => 48 }, 'as a hash');
is(Peta::MIDI::Event::name_to_midi_event('program_change'), 'patch_change', "MIDI::Event's names");

# Callbacks: by name, pattern and all; stop ends the others.
my @heard;
$decoder = Peta::MIDI::Decoder->new(retain_events => 0);
$decoder->attach_callback(qr/^note/ => sub ($e) { push @heard, "note:" . $e->name; return });
$decoder->attach_callback(all => sub ($e) { push @heard, 'all'; return $e->name eq 'clock' ? $decoder->stop : () });
$decoder->attach_callback(clock => sub ($e) { push @heard, 'clock' });
$decoder->decode("\x90\x3c\x64\xf8");
is_deeply(\@heard, [ 'all', 'note:note_on', 'all' ], 'callbacks by pattern and all; stop ends the rest');
is($decoder->decode(''), 0, 'retain_events 0: none kept');

# The tempo from the clock: 24 ticks a beat.
$decoder = Peta::MIDI::Decoder->new;
for (1 .. 13) {
    $decoder->decode("\xf8");
    sleep 0.02;
}
my $tempo = $decoder->tempo;
ok($tempo > 90 && $tempo < 130, "the clock's tempo: about 125 a minute ($tempo)");

# Encoding.
my $encoder = Peta::MIDI::Encoder->new;
is_deeply([ $encoder->encode([ note_on => 1, 60, 100 ]) ], [ "\x91\x3c\x64" ], 'a note on');
is_deeply([ $encoder->encode([ control_change => 0, 7, 100, 10, 64 ]) ], [ "\xb0\x07\x64", "\xb0\x0a\x40" ], 'more values: more messages');
is_deeply([ $encoder->encode([ pitch_wheel_change => 0, -2048 ]) ], [ "\xe0\x00\x30" ], "pitch bend, by MIDI::Event's name");
is_deeply([ $encoder->encode([ sysex => "\x7e\x7f\x09\x01" ]) ], [ "\xf0\x7e\x7f\x09\x01\xf7" ], 'system exclusive, F0 and F7 added');
is_deeply([ $encoder->encode([ sysex => [ 0x41, 0x10, 0xf7 ] ]) ], [ "\xf0\x41\x10\xf7" ], 'from numbers');
is_deeply([ $encoder->encode({ name => 'program_change', channel => 9, program => 25 }) ], [ "\xc9\x19" ], 'from a hash');
is_deeply([ $encoder->encode(['clock']) ], [ "\xf8" ], 'real time');

$encoder = Peta::MIDI::Encoder->new(enable_running_status => 1);
is(join('', $encoder->encode_events([ note_on => 0, 60, 100 ], [ note_on => 0, 64, 90 ], ['clock'], [ note_off => 0, 60, 0 ], [ note_on => 1, 60, 1 ])),
    "\x90\x3c\x64\x40\x5a\xf8\x3c\x00\x91\x3c\x01", 'running status: through the clock; a note off of velocity 0 as a note on');

$encoder = Peta::MIDI::Encoder->new(enable_14bit_cc => 1);
is_deeply([ map { $encoder->encode([ control_change => 0, 1, $_ ]) } 2053, 2054 ], [ "\xb0\x01\x10", "\xb0\x21\x05", "\xb0\x21\x06" ],
    '14 bits: the coarse part when it changes, the fine part always');

# There and back: every kind of event.
my @events = ([ note_on => 0, 60, 100 ], [ note_off => 15, 61, 64 ], [ polytouch => 2, 62, 30 ], [ control_change => 3, 74, 99 ],
    [ program_change => 4, 127 ], [ aftertouch => 5, 7 ], [ pitch_bend => 6, 8191 ], [ sysex => "\x43\x10\x4c" ], [ timecode => 33 ],
    [ song_position => 16383 ], [ song_select => 3 ], ['tune_request'], ['clock'], ['start'], ['continue'], ['stop'],
    ['active_sensing'], ['system_reset']);
is_deeply(decoded(Peta::MIDI::Encoder->new(enable_running_status => 1)->encode_events(@events)), \@events, 'encoded and decoded: the same');

done_testing;
