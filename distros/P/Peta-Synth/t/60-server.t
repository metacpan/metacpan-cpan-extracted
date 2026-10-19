use v5.36;
use Test::More;
use IO::Socket::INET;
use IO::Select;
use JSON::PP;
use Encode ();
use File::Temp qw(tempdir);
use Time::HiRes qw(time sleep);
use lib 'lib';
use Peta::Synth::Server;
use Peta::Synth::MIDI;

my $dir = tempdir(CLEANUP => 1);

# A free port: one the system gives, let go again.
my $port = do { my $probe = IO::Socket::INET->new(Listen => 1, LocalAddr => '127.0.0.1', LocalPort => 0) or die; $probe->sockport };

my $pid = fork // die "cannot fork: $!";
if (!$pid) {
    my $server = Peta::Synth::Server->new(port => $port, midi_dir => $dir, rate => 16000, partials => 8,
        engine => 'perl', bank => "$dir/bank.json", log => sub { });
    $SIG{TERM} = sub { $server->stop };
    alarm 60;    # never outlive the test
    $server->run;
    exit 0;    # as a process ends (a coverage run writes what it saw); the test's END is the parent's
}
END { if ($pid) { kill 'TERM', $pid; waitpid $pid, 0 } }

my $up;
for (1 .. 50) { $up = IO::Socket::INET->new("127.0.0.1:$port") and last; sleep 0.1 }
ok($up, 'the server listens') or BAIL_OUT('no server');
close $up;

# A request, its connection closed after the answer (read to its end).
sub http ($request) {
    my $s = IO::Socket::INET->new("127.0.0.1:$port") or die "cannot connect: $!";
    print $s $request =~ s/\r\n/\r\nConnection: close\r\n/r;
    local $/;
    return scalar <$s>;
}

like(http("GET / HTTP/1.1\r\n\r\n"), qr{\AHTTP/1.1 200.*<title>Peta::Synth</title>}s, 'the page');
like(http("GET /app.js HTTP/1.1\r\n\r\n"), qr{\AHTTP/1.1 200}, 'its script');
like(http("GET /favicon.svg HTTP/1.1\r\n\r\n"), qr{\AHTTP/1.1 200.*image/svg\+xml.*<svg}s, 'its icon');
SKIP: {
    skip 'no node to check the script with', 1 unless grep { -x "$_/node" } split /:/, $ENV{PATH};
    is(system('node', '--check', 'lib/Peta/Synth/Server/web/app.js'), 0, 'the script parses');
}
like(http("GET /../Server.pm HTTP/1.1\r\n\r\n"), qr{\AHTTP/1.1 404}, 'nothing outside the page');

my $midi = Peta::Synth::MIDI->new(division => 96, tracks => [[
    { tick => 0, type => 'note_on', channel => 0, key => 60, velocity => 100 },
    { tick => 96, type => 'note_off', channel => 0, key => 60 } ]])->bytes;
like(http("POST /upload?name=tune.mid HTTP/1.1\r\nContent-Length: " . length($midi) . "\r\n\r\n$midi"), qr/"saved":"tune\.mid"/, 'a MIDI file uploaded');
like(http("POST /upload?name=evil.mid HTTP/1.1\r\nContent-Length: 4\r\n\r\nevil"), qr{\AHTTP/1.1 400}, 'what is not MIDI is refused');
like(http("POST /upload?name=..%2Fx.sh HTTP/1.1\r\nContent-Length: 4\r\n\r\nevil"), qr{\AHTTP/1.1 400}, 'a name that is not a MIDI file is refused');

# The WebSocket: the handshake of RFC 6455's example.
my $ws = IO::Socket::INET->new("127.0.0.1:$port") or die;
print $ws "GET /ws HTTP/1.1\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\n\r\n";
my $head = '';
sysread $ws, $head, 1, length $head until $head =~ /\r\n\r\n/;
like($head, qr/Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK\+xOo=/, 'the WebSocket handshake');

my $json = JSON::PP->new->utf8;    # the frames are UTF-8
sub wsend ($data) {
    my $payload = $json->encode($data);
    my $length = length $payload;
    my $mask = 'm4sk';
    print $ws chr(0x81), ($length < 126 ? chr(0x80 | $length) : chr(0x80 | 126) . pack('n', $length)), $mask,
        $payload ^. substr($mask x ($length / 4 + 1), 0, $length);
}
my ($buffer, $frames, $peak, $listening, %last) = (q(), 0, 0, 1);
sub pump ($seconds) {
    my $until = time + $seconds;
    my $select = IO::Select->new($ws);
    while (time < $until) {
        sysread($ws, $buffer, 1 << 20, length $buffer) if $select->can_read(0.01);
        while (length $buffer >= 2) {
            my ($b0, $b1) = unpack 'C C', $buffer;
            my ($length, $at) = ($b1 & 127, 2);
            if    ($length == 126) { last if length $buffer < 4;  ($length, $at) = (unpack('x2 n', $buffer), 4) }
            elsif ($length == 127) { last if length $buffer < 10; ($length, $at) = (unpack('x6 N', $buffer), 10) }
            last if length $buffer < $at + $length;
            my $payload = substr $buffer, $at, $length;
            substr($buffer, 0, $at + $length) = '';
            if (($b0 & 15) == 2) {
                my @f = unpack 'f<*', $payload;
                $frames += @f / 2;
                for (@f) { $peak = abs $_ if abs $_ > $peak }
            }
            else { my $m = $json->decode($payload); $last{ $m->{type} } = $m }
        }
        wsend({ type => 'played', frames => $frames }) if $listening;    # a listener that plays at once
    }
}

wsend({ type => 'hello' });
pump(0.5);
is($last{init}{rate}, 16000, 'init: the rate');
is(scalar @{ $last{init}{programs} }, 128, 'init: the GM programs');
is_deeply($last{init}{files}, ['tune.mid'], 'init: the MIDI files');
is(scalar @{ $last{init}{variations} }, 30, 'init: the variations');
is($last{init}{kits}{25}{name}, 'TR-808', 'init: the kits');

wsend({ type => 'audio', on => 1 });
wsend({ type => 'note', on => 1, channel => 0, key => 64, velocity => 110 });
pump(1);
cmp_ok($frames, '>', 1000, 'sound arrives');
cmp_ok($peak, '>', 0.01, 'and it is not silent');

wsend({ type => 'patch_set', kind => 'program', number => 0, field => 'cutoff', value => 1e9 });
wsend({ type => 'patch_get', kind => 'program', number => 0 });
pump(0.3);
is($last{patch}{fields}{cutoff}, 16000, 'a patch field is set, within its range');
wsend({ type => 'patch_set', kind => 'program', number => 0, field => 'nonsense', value => 1 });
pump(0.3);
like($last{error}{message}, qr/nonsense/, 'an unknown field is an error');

wsend({ type => 'patch_set', kind => 'program', number => 0, field => 'formants', value => [ [ 500, 2, 0.5 ], [ 99999, 50, 0 ] ] });
wsend({ type => 'patch_set', kind => 'program', number => 1, field => 'partials', value => [ [ 1, 1, 1 ], [ 2.5, 0.5, 2 ] ] });
wsend({ type => 'patch_get', kind => 'program', number => 0 });
pump(0.3);
is_deeply($last{patch}{formants}, [ [ 500, 2, 0.5 ], [ 20000, 10, 0.05 ] ], 'formants set, held within their ranges');
wsend({ type => 'eq', band => 'high', what => 'gain', value => -5 });
wsend({ type => 'channel_eq', channel => 4, band => 'mid1', what => 'gain', value => 6 });
wsend({ type => 'bank_save' });
pump(0.3);
ok(-s "$dir/bank.json", 'the bank is saved');
my $saved = do { open my $in, '<', "$dir/bank.json" or die; local $/; JSON::PP->new->decode(<$in>) };
is($saved->{programs}{0}{cutoff}, 16000, 'the bank holds the change');
is($saved->{master}{eq}{high}{gain}, -5, 'and the equalizer');
is_deeply($saved->{programs}{1}{partials}, [ [ 1, 1, 1 ], [ 2.5, 0.5, 2 ] ], "and an instrument's own partials");
is($saved->{master}{channels}{4}{mid1}{gain}, 6, "and a channel's");

# The listener stops listening: the server renders no further ahead than it
# was told to, so the file is still playing when the state comes.
$listening = 0;
wsend({ type => 'play', file => 'tune.mid' });
pump(0.5);
is($last{state}{playing}{file}, 'tune.mid', 'a file plays');

# A file's instruments from its start: what selects them before a
# channel's first note, moved to the start or to a reset before it.
{
    my $reset = "\x7e\x7f\x09\x01\xf7";
    my @file = (
        { time => 0,   type => 'note_on',    channel => 0, key => 60, velocity => 100 },
        { time => 1,   type => 'sysex',      data => $reset },
        { time => 2,   type => 'controller', channel => 1, number => 0, value => 8 },
        { time => 2,   type => 'program',    channel => 1, program => 33 },
        { time => 3,   type => 'note_on',    channel => 1, key => 40, velocity => 100 },
        { time => 4,   type => 'program',    channel => 1, program => 34 },
        { time => 5,   type => 'program',    channel => 0, program => 5 },
        { time => 6,   type => 'program',    channel => 2, program => 40 },
    );
    my @got = map { "$_->{time} $_->{type}" . ($_->{program} // '') } @{ Peta::Synth::Server::_instruments_first(\@file) };
    is_deeply(\@got, [ '0 note_on', '1 sysex', '1 controller', '1 program33', '1 program40', '3 note_on', '4 program34', '5 program5' ],
        "each channel's instrument from the start: after the reset, before its first note");
}

# Paused, the file holds; sought, it goes on from there.
my $long = Peta::Synth::MIDI->new(division => 96, tracks => [[
    map { ({ tick => $_ * 192, type => 'note_on', channel => 0, key => 60, velocity => 100 },
           { tick => $_ * 192 + 96, type => 'note_off', channel => 0, key => 60 }) } 0 .. 299 ]])->bytes;
like(http("POST /upload?name=long.mid HTTP/1.1\r\nContent-Length: " . length($long) . "\r\n\r\n$long"), qr/"saved":"long\.mid"/, 'a longer file');
# The listener plays at once, so the server renders as fast as it can:
# what is waited for is a state, not a time.
sub playing () { return $last{state}{playing} // {} }
sub wait_for ($done) {
    my $until = time + 3;
    pump(0.05) until $done->() || time > $until;
    return;
}
$listening = 1;
wsend({ type => 'play', file => 'long.mid', position => 10 });
wait_for(sub { (playing->{file} // '') eq 'long.mid' });
cmp_ok(playing->{position}, '>=', 10, 'played from a position');
wsend({ type => 'pause', on => 1 });
wait_for(sub { playing->{paused} });
my $held = playing->{position};
is(playing->{paused}, 1, 'paused');
pump(0.5);
is(playing->{position}, $held, 'it holds');
wsend({ type => 'seek', position => 30 });
wait_for(sub { playing->{position} == 30 });
is(playing->{position}, 30, 'sought while paused');
wsend({ type => 'pause', on => 0 });
wait_for(sub { !playing->{paused} && playing->{position} > 30 });
is(playing->{paused}, 0, 'it goes on');
cmp_ok(playing->{position}, '>', 30, 'from there');
wsend({ type => 'seek', position => 5 });
wait_for(sub { playing->{position} < 30 });
cmp_ok(playing->{position}, '<', 30, 'sought back while it plays');
wsend({ type => 'stop' });
wait_for(sub { !$last{state}{playing} });
ok(!$last{state}{playing}, 'stopped');

# A recording: what is played live, into a MIDI file.
wsend({ type => 'record', on => 0 });
wsend({ type => 'record', on => 1 });
wsend({ type => 'program', channel => 1, program => 33 });
wsend({ type => 'note', on => 1, channel => 1, key => 40, velocity => 90 });
pump(0.3);
ok(defined $last{state}{recording}, 'recording');
wsend({ type => 'note', on => 0, channel => 1, key => 40 });
wsend({ type => 'midi', data => [ 0x91, 43, 80 ] });
pump(0.2);
wsend({ type => 'record', on => 0 });
pump(0.3);
my $recorded = $last{recorded}{file} // '';
like($recorded, qr/\Arecording-\d{8}-\d{6}\.mid\z/, 'recorded into a file');
ok(!defined $last{state}{recording}, 'and no longer recording');
my @took = grep { $_->{type} ne 'tempo' } @{ Peta::Synth::MIDI->read("$dir/$recorded")->timeline };
my @notes = map { "$_->{type} $_->{key}" } grep { $_->{type} eq 'note_on' || $_->{type} eq 'note_off' } @took;
is_deeply(\@notes, [ 'note_on 40', 'note_off 40', 'note_on 43', 'note_off 43' ], 'the keys, a held one let go at the end');
my ($program) = grep { $_->{type} eq 'program' } @took;
is($program->{program}, 0, 'the channel as it was when the recording began');
cmp_ok($notes[0] && $took[-1]{time}, '>', 0.3, 'at the times they came');
ok((grep { $_ eq $recorded } @{ $last{files}{files} }), 'the page is told the files');
wsend({ type => 'record', on => 1 });
wsend({ type => 'record', on => 0 });
pump(0.3);
like($last{error}{message}, qr/nothing was played/, 'nothing played: no file');
$listening = 0;

# A channel's arpeggiator: settings held to what they may be.
is($last{init}{arp}{channels}[0]{mode}, 'up', "init: the arpeggiators' settings");
wsend({ type => 'arp', channel => 3, name => 'mode', value => 'pedal_up' });
wsend({ type => 'arp', channel => 3, name => 'tempo', value => 999 });
wsend({ type => 'arp', channel => 3, name => 'mode', value => 'sideways' });
pump(0.3);
like($last{error}{message}, qr/sideways/, 'an unknown pattern is an error');
wsend({ type => 'hello' });
pump(0.3);
is($last{init}{arp}{channels}[3]{mode}, 'pedal_up', 'a pattern set');
is($last{init}{arp}{channels}[3]{tempo}, 300, 'a tempo held within its range');
is($last{state}{arps}[3]{mode}, 'pedal_up', 'the state: the arpeggiators as they are');

# Fidelity: mid for playing, unless set.
is($last{init}{synth}{fidelity}, 'mid', 'fidelity: mid');
wsend({ type => 'synth', name => 'fidelity', value => 'low' });
wsend({ type => 'synth', name => 'fidelity', value => 'ultra' });
wsend({ type => 'hello' });
pump(0.3);
is($last{init}{synth}{fidelity}, 'low', 'set low');
like($last{error}{message}, qr/no fidelity 'ultra'/, 'an unknown one is an error');

# What the page sets is held against the file; let go, one or all.
is_deeply($last{state}{channels}[3]{held}, [ 'arp mode', 'arp tempo' ], 'held against the file');
wsend({ type => 'let_go', channel => 3, what => 'arp tempo' });
pump(0.5);
is_deeply($last{state}{channels}[3]{held}, [ 'arp mode' ], 'one let go');
wsend({ type => 'let_go', channel => 3 });
wsend({ type => 'let_go', channel => 3, what => 'cc 7' });
pump(0.5);
is_deeply($last{state}{channels}[3]{held}, [], 'all let go');
like($last{error}{message}, qr/does not hold 'cc 7'/, 'what is not held cannot be let go');

# A variation: a program with its bank; its patch by the bank.
wsend({ type => 'program', channel => 2, program => 25, bank => 16 });
wsend({ type => 'patch_get', kind => 'program', number => 25, bank => 16 });
pump(0.3);
is($last{state}{channels}[2]{variation}, 16, 'a variation chosen');
is($last{patch}{name}, 'Mandolin', 'its patch');
wsend({ type => 'patch_get', kind => 'program', number => 0, bank => 16 });
pump(0.3);
is($last{patch}{bank}, 0, 'a program without that variation: the program');

# The filter, a choice of more than two; routes of modulation.
wsend({ type => 'patch_set', kind => 'program', number => 2, field => 'filter', value => 'lp24' });
wsend({ type => 'patch_set', kind => 'program', number => 2, field => 'mods', value => [ [ 'lfo1', 'cutoff', 99 ], [ 'env2', 'q', 1 ] ] });
wsend({ type => 'patch_get', kind => 'program', number => 2 });
pump(0.3);
is($last{patch}{fields}{filter}, 'lp24', 'a filter chosen');
is_deeply($last{patch}{mods}, [ [ 'lfo1', 'cutoff', 24 ], [ 'env2', 'q', 1 ] ], 'routes set, the amounts held within range');
ok(grep({ $_->{name} eq 'lfo1' } @{ $last{init}{mod}{sources} }), 'the page is told the sources');
wsend({ type => 'patch_set', kind => 'program', number => 2, field => 'mods', value => [ [ 'nonsense', 'q', 1 ] ] });
pump(0.3);
like($last{error}{message}, qr/no source 'nonsense'/, 'an unknown source is an error');
wsend({ type => 'patch_set', kind => 'program', number => 2, field => 'filter', value => 'lp36' });
pump(0.3);
like($last{error}{message}, qr/lp36/, 'so is an unknown filter');

# A device's messages as Web MIDI passes them: bytes.
wsend({ type => 'midi', data => [ 0xb3, 7, 33 ] });
pump(0.5);
is($last{state}{channels}[3]{volume}, 33, 'a controller from a device');
wsend({ type => 'midi', data => [ 0xf0, 0x7e, 0x7f, 0x09, 0x01, 0xf7 ] });
pump(0.5);
is($last{state}{channels}[3]{volume}, 100, 'system exclusive: GM System On');

# A file's name of any characters but a path's and a hidden file's: kept as
# text, listed and played by it.
my $odd     = "A & B \x{2013} Dvo\x{159}\x{e1}k (mix).mid";
my $escaped = join '', map { /[A-Za-z0-9.]/ ? $_ : sprintf '%%%02X', ord } split //, Encode::encode('UTF-8', $odd);
like(http("POST /upload?name=$escaped HTTP/1.1\r\nContent-Length: " . length($midi) . "\r\n\r\n$midi"), qr{\AHTTP/1.1 200}, 'a name with &, a dash, accents');
like(http("POST /upload?name=.hidden.mid HTTP/1.1\r\nContent-Length: " . length($midi) . "\r\n\r\n$midi"), qr{\AHTTP/1.1 400}, 'a hidden one is refused');
wsend({ type => 'files' });
pump(0.3);
ok((grep { $_ eq $odd } @{ $last{files}{files} }), 'listed by its name');
wsend({ type => 'play', file => $odd });
pump(0.5);
is($last{state}{playing}{file}, $odd, 'and played');

# Reset: all as the server started, the instruments as changed.
wsend({ type => 'cc', channel => 1, number => 7, value => 30 });
wsend({ type => 'mute', channel => 1, on => 1 });
wsend({ type => 'reverb', name => 'time', value => 9 });
wsend({ type => 'synth', name => 'fidelity', value => 'high' });
wsend({ type => 'reset' });
pump(0.5);
is_deeply([ @{ $last{init}{channels}[1] }{qw(volume mute)}, $last{init}{reverb}{time}, $last{init}{synth}{fidelity}, $last{state}{playing} ],
    [ 100, 0, 2.2, 'mid', undef ], 'reset: the channels, the reverb, the fidelity as at the start, nothing playing');
wsend({ type => 'patch_get', kind => 'program', number => 0 });
pump(0.3);
is($last{patch}{fields}{cutoff}, 16000, 'the instruments as changed');

done_testing;
