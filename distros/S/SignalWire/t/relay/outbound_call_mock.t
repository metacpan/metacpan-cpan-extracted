#!/usr/bin/env perl
# Real-mock-backed tests for outbound calls (RelayClient::dial).
# Mirrors signalwire-python tests/unit/relay/test_outbound_call_mock.py.

use strict;
use warnings;
use Test::More;
use FindBin ();
use lib "$FindBin::Bin/../lib";
use Time::HiRes qw(sleep time);

use RelayMockTest;
use SignalWire::Relay::Client;

sub _connected_client {
    my $client = RelayMockTest::client(contexts => ['default']);
    $client->connect;
    return $client;
}

sub _phone_device {
    my (%args) = @_;
    return {
        type   => 'phone',
        params => {
            to_number   => $args{to}   // '+15551112222',
            from_number => $args{from} // '+15553334444',
        },
    };
}

# ---------------------------------------------------------------------------
# Happy-path dial
# ---------------------------------------------------------------------------

subtest 'dial resolves to call with winner id' => sub {
    my $client = _connected_client();
    RelayMockTest::arm_dial(
        tag            => 't-happy',
        winner_call_id => 'winner-1',
        states         => ['created', 'ringing', 'answered'],
        node_id        => 'node-mock-1',
        device         => _phone_device(),
        delay_ms       => 1,
    );
    my $call = $client->dial(
        devices => [[ _phone_device() ]],
        tag     => 't-happy',
        timeout => 5,
    );
    isa_ok($call, 'SignalWire::Relay::Call');
    is($call->call_id, 'winner-1',  'call_id is winner');
    is($call->tag,     't-happy',   'tag preserved');
    is($call->state,   'answered',  'state is answered');
    $client->disconnect;
};

subtest 'dial journal records calling.dial frame' => sub {
    my $client = _connected_client();
    RelayMockTest::arm_dial(
        tag            => 't-frame',
        winner_call_id => 'winner-frame',
        states         => ['created', 'answered'],
        node_id        => 'node-mock-1',
        device         => _phone_device(),
    );
    $client->dial(
        devices => [[ _phone_device() ]],
        tag     => 't-frame',
        timeout => 5,
    );
    my $entries = RelayMockTest::journal_recv(method => 'calling.dial');
    is(scalar @$entries, 1, 'one calling.dial entry');
    my $p = $entries->[0]{frame}{params};
    is($p->{tag}, 't-frame', 'tag on wire');
    ok(ref $p->{devices} eq 'ARRAY', 'devices is array');
    is($p->{devices}[0][0]{type}, 'phone', 'devices[0][0].type on wire');
    $client->disconnect;
};

subtest 'dial auto-generates UUID tag when omitted' => sub {
    # Drive a separate Perl process that watches for the dial frame and
    # pushes the answer; meanwhile the test process runs $client->dial
    # with no tag. We can't fork in-process because the WebSocket socket
    # is shared (the child write would corrupt the parent's stream).
    my $client = _connected_client();

    my $watcher_script = <<'PERLEOF';
use strict;
use warnings;
use HTTP::Tiny;
use JSON qw(encode_json decode_json);
use Time::HiRes qw(sleep);
my $base = $ENV{RMT_HTTP_URL};
my $ua = HTTP::Tiny->new(timeout => 5);
my $tag;
for my $i (1..400) {
    my $r = $ua->get("$base/__mock__/journal");
    if ($r->{success}) {
        for my $e (@{ decode_json($r->{content}) }) {
            if (($e->{direction}//'') eq 'recv'
                && ($e->{method}//'') eq 'calling.dial') {
                $tag = $e->{frame}{params}{tag};
                last;
            }
        }
    }
    last if $tag;
    sleep 0.025;
}
exit 1 unless $tag;
my $body = encode_json({
    frame => {
        jsonrpc => '2.0',
        id      => 'auto-tag-evt',
        method  => 'signalwire.event',
        params  => {
            event_type => 'calling.call.dial',
            params     => {
                tag        => $tag,
                node_id    => 'node-mock-1',
                dial_state => 'answered',
                call       => {
                    call_id    => 'auto-tag-winner',
                    node_id    => 'node-mock-1',
                    tag        => $tag,
                    device     => { type => 'phone',
                                    params => { to_number => '+15551112222',
                                                from_number => '+15553334444' } },
                    dial_winner => JSON::true,
                },
            },
        },
    },
});
$ua->post("$base/__mock__/push",
    { content => $body, headers => { 'Content-Type' => 'application/json' } });
exit 0;
PERLEOF

    my $tmp = "/tmp/rmt_watcher_$$.pl";
    open my $fh, '>', $tmp or die "open: $!";
    print $fh $watcher_script;
    close $fh;

    local $ENV{RMT_HTTP_URL} = $RelayMockTest::HTTP_URL;
    my $pid = fork();
    if ($pid == 0) {
        # Use exec to fully detach (no shared sockets, no Moo state, etc.)
        exec('perl', $tmp) or do { exit 127; };
    }

    my $call;
    eval {
        $call = $client->dial(
            devices => [[ _phone_device() ]],
            timeout => 5,
        );
    };
    waitpid($pid, 0);
    unlink $tmp;
    isa_ok($call, 'SignalWire::Relay::Call');
    is($call->call_id, 'auto-tag-winner', 'auto-tag winner');
    like($call->tag,
         qr/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/,
         'tag is UUID-shaped');
    $client->disconnect;
};

# ---------------------------------------------------------------------------
# Failure paths
# ---------------------------------------------------------------------------

subtest 'dial timeout when no dial event' => sub {
    my $client = _connected_client();
    # Don't arm any scenario. The dial event never arrives — the SDK
    # returns undef once the dial timeout elapses (Perl variant; Python
    # raises RelayError). We assert the journal still recorded the
    # calling.dial frame: the SDK actually attempted the call.
    my $call;
    eval {
        $call = $client->dial(
            devices => [[ _phone_device() ]],
            tag     => 't-timeout',
            timeout => 0.5,
        );
    };
    ok(!defined $call, 'dial returns undef on timeout');
    my $entries = RelayMockTest::journal_recv(method => 'calling.dial');
    is(scalar @$entries, 1,
       'calling.dial frame still landed even though no answer came');
    is($entries->[0]{frame}{params}{tag}, 't-timeout',
       'tag preserved on the wire');
    $client->disconnect;
};

# ---------------------------------------------------------------------------
# Devices shape
# ---------------------------------------------------------------------------

subtest 'dial devices serial two legs on wire' => sub {
    my $client = _connected_client();
    RelayMockTest::arm_dial(
        tag            => 't-serial',
        winner_call_id => 'WIN-SER',
        states         => ['created', 'answered'],
        node_id        => 'node-mock-1',
        device         => _phone_device(),
    );
    my $devs = [
        [
            _phone_device(to => '+15551110001'),
            _phone_device(to => '+15551110002'),
        ],
    ];
    $client->dial(devices => $devs, tag => 't-serial', timeout => 5);
    my $entries = RelayMockTest::journal_recv(method => 'calling.dial');
    is(scalar @$entries, 1, 'one entry');
    is(scalar @{ $entries->[0]{frame}{params}{devices} }, 1, 'one outer leg');
    is(scalar @{ $entries->[0]{frame}{params}{devices}[0] }, 2, 'two devices');
    is($entries->[0]{frame}{params}{devices}[0][0]{params}{to_number},
       '+15551110001', 'first device to_number');
    $client->disconnect;
};

subtest 'dial devices parallel two legs on wire' => sub {
    my $client = _connected_client();
    RelayMockTest::arm_dial(
        tag            => 't-par',
        winner_call_id => 'WIN-PAR',
        states         => ['created', 'answered'],
        node_id        => 'node-mock-1',
        device         => _phone_device(),
    );
    my $devs = [
        [ _phone_device(to => '+15551110001') ],
        [ _phone_device(to => '+15551110002') ],
    ];
    $client->dial(devices => $devs, tag => 't-par', timeout => 5);
    my $entries = RelayMockTest::journal_recv(method => 'calling.dial');
    is(scalar @{ $entries->[0]{frame}{params}{devices} }, 2,
       'two parallel legs');
    $client->disconnect;
};

# ---------------------------------------------------------------------------
# State transitions during dial
# ---------------------------------------------------------------------------

subtest 'dial records call state progression on winner' => sub {
    my $client = _connected_client();
    RelayMockTest::arm_dial(
        tag            => 't-prog',
        winner_call_id => 'WIN-PROG',
        states         => ['created', 'ringing', 'answered'],
        node_id        => 'node-mock-1',
        device         => _phone_device(),
    );
    my $call = $client->dial(
        devices => [[ _phone_device() ]],
        tag     => 't-prog',
        timeout => 5,
    );
    isa_ok($call, 'SignalWire::Relay::Call');
    is($call->state, 'answered', 'final state is answered');
    my $sends = RelayMockTest::journal_send(event_type => 'calling.call.state');
    my @winner_states = map {
        $_->{frame}{params}{params}{call_state} // ''
    } grep {
        ($_->{frame}{params}{params}{call_id} // '') eq 'WIN-PROG'
    } @$sends;
    ok((grep { $_ eq 'created' }  @winner_states), 'created state seen');
    ok((grep { $_ eq 'ringing' }  @winner_states), 'ringing state seen');
    ok((grep { $_ eq 'answered' } @winner_states), 'answered state seen');
    $client->disconnect;
};

# ---------------------------------------------------------------------------
# After dial — call object is usable
# ---------------------------------------------------------------------------

subtest 'dialed call can hangup' => sub {
    my $client = _connected_client();
    RelayMockTest::arm_dial(
        tag            => 't-after',
        winner_call_id => 'WIN-AFTER',
        states         => ['created', 'answered'],
        node_id        => 'node-mock-1',
        device         => _phone_device(),
    );
    my $call = $client->dial(
        devices => [[ _phone_device() ]],
        tag     => 't-after',
        timeout => 5,
    );
    $call->hangup;
    my $ends = RelayMockTest::journal_recv(method => 'calling.end');
    ok(scalar @$ends, 'calling.end in journal');
    is($ends->[-1]{frame}{params}{call_id}, 'WIN-AFTER',
       'hangup carries winner call_id');
    $client->disconnect;
};

subtest 'dialed call can play' => sub {
    my $client = _connected_client();
    RelayMockTest::arm_dial(
        tag            => 't-play',
        winner_call_id => 'WIN-PLAY',
        states         => ['created', 'answered'],
        node_id        => 'node-mock-1',
        device         => _phone_device(),
    );
    my $call = $client->dial(
        devices => [[ _phone_device() ]],
        tag     => 't-play',
        timeout => 5,
    );
    $call->play(play => [{ type => 'tts', params => { text => 'hi' } }]);
    my $plays = RelayMockTest::journal_recv(method => 'calling.play');
    ok(scalar @$plays, 'calling.play in journal');
    my $p = $plays->[-1]{frame}{params};
    is($p->{call_id}, 'WIN-PLAY', 'play call_id matches winner');
    is($p->{play}[0]{type}, 'tts', 'play[0].type on wire');
    $client->disconnect;
};

# ---------------------------------------------------------------------------
# Tag preservation
# ---------------------------------------------------------------------------

subtest 'dial preserves explicit tag' => sub {
    my $client = _connected_client();
    RelayMockTest::arm_dial(
        tag            => 'my-very-explicit-tag-99',
        winner_call_id => 'WIN-T',
        states         => ['created', 'answered'],
        node_id        => 'node-mock-1',
        device         => _phone_device(),
    );
    my $call = $client->dial(
        devices => [[ _phone_device() ]],
        tag     => 'my-very-explicit-tag-99',
        timeout => 5,
    );
    is($call->tag, 'my-very-explicit-tag-99', 'explicit tag preserved');
    $client->disconnect;
};

# ---------------------------------------------------------------------------
# Wire envelope
# ---------------------------------------------------------------------------

subtest 'dial uses jsonrpc 2.0' => sub {
    my $client = _connected_client();
    RelayMockTest::arm_dial(
        tag            => 't-rpc',
        winner_call_id => 'W',
        states         => ['created', 'answered'],
        node_id        => 'n',
        device         => _phone_device(),
    );
    $client->dial(
        devices => [[ _phone_device() ]],
        tag     => 't-rpc',
        timeout => 5,
    );
    my $entries = RelayMockTest::journal_recv(method => 'calling.dial');
    is(scalar @$entries, 1, 'one entry');
    is($entries->[0]{frame}{jsonrpc}, '2.0', 'jsonrpc 2.0');
    is($entries->[0]{frame}{method},  'calling.dial', 'method');
    ok($entries->[0]{frame}{id},      'id present');
    ok(ref $entries->[0]{frame}{params}, 'params present');
    $client->disconnect;
};

done_testing();
