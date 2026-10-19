use v5.36;
use Test::More;
use lib 'lib';
use Peta::MIDI::Device;
use Peta::MIDI::Decoder;

# MIDI devices as MIDI::RtMidi::FFI::Device has them, on the ALSA sequencer:
# an output with a virtual port, an input connected to it by name.

my $out = eval { Peta::MIDI::Device->new(type => 'out', name => 'peta test out') };
plan skip_all => "no ALSA sequencer here: $@" if !$out;

isa_ok($out, 'Peta::MIDI::Device::Out');
ok($out->open_virtual_port('virtual out'), 'a virtual port');
is($out->port_name, 'virtual out', 'its name');

my $in = Peta::MIDI::Device->new(type => 'in', name => 'peta test in');
isa_ok($in, 'Peta::MIDI::Device::In');
my %names = %{ $in->get_all_port_names };
my ($listed) = grep { /\Apeta test out:virtual out \d+:\d+\z/ } keys %names;
ok($listed, "listed as RtMidi names it: $listed");
is_deeply([ $in->get_ports_by_name($listed) ], [ $names{$listed} ], 'found by name');
is_deeply([ $in->get_ports_by_name([ qr/\Anothing/, qr/peta test out/ ]) ], [ $names{$listed} ], 'by a list of patterns');
is($in->get_port_name($names{$listed}), $listed, 'a number named');
ok(!grep({ /peta test in/ } keys %{ $out->get_all_port_names }), 'an output lists none it cannot write to');
ok($in->open_port_by_name(qr/peta test out:virtual out/, 'listening'), 'opened by a pattern');
is($in->connected_to_name, $listed, 'connected to it');
eval { $in->open_port_by_name('no such port') };
like($@, qr/No available device found/, 'a name of none dies');

# Bytes, and events by name: running status, more values, MIDI::Event's names.
sub gather ($in, $count) {
    my @got;
    for (1 .. 20) {
        $in->dispatch(0.05);
        while (defined(my $message = $in->get_message)) { push @got, $message }
        last if @got >= $count;
    }
    return [ map { join ' ', map { sprintf '%02x', $_ } unpack 'C*', $_ } @got ];
}
$out->send_message("\x90\x3c\x64");
$out->note_on(1, 62, 90);
$out->cc(2, 7, 100, 10, 64);
$out->program_change(3, 19);
$out->pitch_bend(4, -2048);
$out->send_event(sysex => "\x7e\x7f\x09\x01");    # ignored by default
$out->clock;                                        # so is timing
$out->send_event(polytouch => 5, 60, 33);
is_deeply(gather($in, 7), [ '90 3c 64', '91 3e 5a', 'b2 07 64', 'b2 0a 40', 'c3 13', 'e4 00 30', 'a5 3c 21' ],
    'messages whole; system exclusive and timing ignored');

$in->ignore_types(0, 0, 1);
$out->send_event(sysex => "\x7e\x7f\x09\x01");
$out->clock;
is_deeply(gather($in, 2), [ 'f0 7e 7f 09 01 f7', 'f8' ], 'not ignored: system exclusive whole, the clock');

$out->rpn(0, 0, 12 << 7);
is_deeply(gather($in, 6), [ 'b0 65 00', 'b0 64 00', 'b0 06 0c', 'b0 26 00', 'b0 65 7f', 'b0 64 7f' ], 'an RPN, then the null parameter');
$out->panic(9);
is_deeply(gather($in, 1), ['b9 7b 00'], 'panic: all notes off');

# Decoded: MIDI::Event's names by default.
$out->program_change(0, 5);
$in->dispatch(0.2);
is_deeply($in->get_event, [ patch_change => 0, 5 ], "an event, in MIDI::Event's names");
my $plain = Peta::MIDI::Device->new(type => 'in', remap_event_names => 0);
is_deeply($plain->decode("\xc0\x05"), [ program_change => 0, 5 ], "or MIDI::Stream's");

# Callbacks: while waiting in dispatch.
my @heard;
$in->set_callback_decoded(sub ($dt, $message, $event) { push @heard, [ $dt >= 0, $event ] });
$out->note_on(0, 60, 100);
$out->note_off(0, 60, 0);
$in->dispatch(0.3);
is_deeply([ map { $_->[1] } @heard ], [ [ note_on => 0, 60, 100 ], [ note_off => 0, 60, 0 ] ], 'a decoded callback, in dispatch');
ok($heard[1][0], 'each with the seconds since the one before');
is($in->get_message, undef, 'with a callback, nothing is queued');

SKIP: {
    skip 'no AnyEvent here', 3 if !eval { require AnyEvent; 1 };

    # In an event loop, as RtMidi's thread would.
    @heard = ();
    my $done = AnyEvent->condvar;
    $in->set_callback(sub ($dt, $message) { push @heard, $message; $done->send if @heard == 2 });
    my $send = AnyEvent->timer(after => 0.05, cb => sub { $out->note_on(0, 64, 1); $out->note_on(0, 67, 2) });
    my $give_up = AnyEvent->timer(after => 3, cb => sub { $done->send });
    $done->recv;
    is_deeply(\@heard, [ "\x90\x40\x01", "\x90\x43\x02" ], 'a callback, in the event loop');

    # A handle, for a loop of one's own.
    my $fh = $in->get_fh;
    my $bytes = '';
    my $read = AnyEvent->condvar;
    my $reader = AnyEvent->io(fh => $fh, poll => 'r', cb => sub { sysread $fh, $bytes, 64, length $bytes; $read->send if length $bytes >= 6 });
    $send = AnyEvent->timer(after => 0.05, cb => sub { $out->cc(0, 1, 2); $out->cc(0, 3, 4) });
    $give_up = AnyEvent->timer(after => 3, cb => sub { $read->send });
    $read->recv;
    is($bytes, "\xb0\x01\x02\xb0\x03\x04", 'get_fh: the bytes as they come');
    ok(!defined $in->{callback}, 'and no callback besides');
}

SKIP: {
    skip 'no Coro here', 1 if !eval { require Coro; require Coro::AnyEvent; 1 };

    # With Coro, a program that sleeps sees its callbacks run meanwhile.
    @heard = ();
    $in->set_callback(sub ($dt, $message) { push @heard, $message });
    Coro::async(sub { Coro::AnyEvent::sleep(0.05); $out->note_on(0, 70, 3) });
    Coro::AnyEvent::sleep(0.3);
    is_deeply(\@heard, ["\x90\x46\x03"], 'Coro: the callback runs while the program sleeps');
}

ok($in->close_port, 'closed');
is($in->connected_to, undef, 'connected to none');

done_testing;
