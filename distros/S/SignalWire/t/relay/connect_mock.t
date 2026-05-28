#!/usr/bin/env perl
# Real-mock-backed tests for SignalWire::Relay::Client connect/authenticate.
#
# Mirrors signalwire-python tests/unit/relay/test_connect_mock.py — boots the
# shared mock_relay WebSocket server and drives the actual Perl SDK against
# it. No mock of the WebSocket transport: the SDK speaks ws:// to the mock
# the same way it speaks wss:// to production.
#
# Each test verifies BOTH:
#   1. Behavioral — what the SDK exposed back to the developer.
#   2. Wire — what the mock journaled (the SDK's exact wire shape).

use strict;
use warnings;
use Test::More;
use FindBin ();
use lib "$FindBin::Bin/../lib";

use RelayMockTest;
use SignalWire::Relay::Client;
use SignalWire::Relay::Constants qw(PROTOCOL_VERSION);

# ---------------------------------------------------------------------------
# Connect — happy path
# ---------------------------------------------------------------------------

subtest 'connect returns protocol string' => sub {
    my $client = RelayMockTest::client(contexts => ['default']);
    $client->connect;
    ok($client->connected, 'client is connected');
    like($client->relay_protocol, qr/^signalwire_/,
         'protocol string starts with signalwire_');
    $client->disconnect;
};

subtest 'connect journal records exactly one signalwire.connect frame' => sub {
    my $client = RelayMockTest::client(contexts => ['default']);
    $client->connect;
    my $entries = RelayMockTest::journal_recv(method => 'signalwire.connect');
    is(scalar @$entries, 1,
       'exactly one signalwire.connect frame in journal')
       or diag explain $entries;
    $client->disconnect;
};

subtest 'connect journal carries project and token' => sub {
    my $client = RelayMockTest::client(contexts => ['default']);
    $client->connect;
    my $entries = RelayMockTest::journal_recv(method => 'signalwire.connect');
    is(scalar @$entries, 1, 'one entry');
    my $auth = $entries->[0]{frame}{params}{authentication};
    is($auth->{project}, 'test_proj', 'auth.project on wire');
    is($auth->{token},   'test_tok',  'auth.token on wire');
    $client->disconnect;
};

subtest 'connect journal carries contexts' => sub {
    my $client = RelayMockTest::client(contexts => ['default']);
    $client->connect;
    my $entries = RelayMockTest::journal_recv(method => 'signalwire.connect');
    is_deeply($entries->[0]{frame}{params}{contexts}, ['default'],
              'contexts list on wire');
    $client->disconnect;
};

subtest 'connect journal carries agent and version' => sub {
    my $client = RelayMockTest::client(contexts => ['default']);
    $client->connect;
    my $entries = RelayMockTest::journal_recv(method => 'signalwire.connect');
    my $params = $entries->[0]{frame}{params};
    like($params->{agent}, qr{^signalwire-agents-perl/}, 'agent string set');
    is_deeply($params->{version}, {
        major    => PROTOCOL_VERSION->{major},
        minor    => PROTOCOL_VERSION->{minor},
        revision => PROTOCOL_VERSION->{revision},
    }, 'protocol version on wire');
    $client->disconnect;
};

subtest 'connect journal sends event_acks=true' => sub {
    my $client = RelayMockTest::client(contexts => ['default']);
    $client->connect;
    my $entries = RelayMockTest::journal_recv(method => 'signalwire.connect');
    # JSON true unmarshals to JSON::PP::Boolean or 1; truthiness check.
    ok($entries->[0]{frame}{params}{event_acks},
       'event_acks is truthy on wire');
    $client->disconnect;
};

# ---------------------------------------------------------------------------
# Reconnect with stored protocol → session resume
# ---------------------------------------------------------------------------

subtest 'reconnect with protocol string includes protocol in frame' => sub {
    my $c1 = RelayMockTest::client(contexts => ['c1']);
    $c1->connect;
    my $issued = $c1->relay_protocol;
    ok($issued, 'first connect issued a protocol');
    $c1->disconnect;

    # Build a second client carrying the issued protocol — should resume.
    my $c2 = SignalWire::Relay::Client->new(
        project  => 'test_proj',
        token    => 'test_tok',
        host     => "127.0.0.1:$RelayMockTest::WS_PORT",
        scheme   => 'ws',
        path     => '',
        contexts => ['c1'],
    );
    $c2->protocol($issued);
    $c2->connect;
    $c2->disconnect;

    # The second connect frame must carry that protocol field.
    my $entries = RelayMockTest::journal_recv(method => 'signalwire.connect');
    my @resume = grep { ($_->{frame}{params}{protocol} // '') eq $issued } @$entries;
    ok(scalar @resume, 'resume connect frame carries the protocol')
        or diag "saw protocols: "
            . join(',', map { defined $_->{frame}{params}{protocol}
                              ? $_->{frame}{params}{protocol} : '(none)' } @$entries);
};

subtest 'reconnect with protocol preserves protocol value' => sub {
    my $c1 = RelayMockTest::client();
    $c1->connect;
    my $issued = $c1->relay_protocol;
    $c1->disconnect;

    my $c2 = SignalWire::Relay::Client->new(
        project => 'test_proj',
        token   => 'test_tok',
        host    => "127.0.0.1:$RelayMockTest::WS_PORT",
        scheme  => 'ws',
        path    => '',
    );
    $c2->protocol($issued);
    $c2->connect;
    is($c2->relay_protocol, $issued, 'server confirms the same protocol on resume');
    $c2->disconnect;
};

# ---------------------------------------------------------------------------
# Auth failure paths
# ---------------------------------------------------------------------------

subtest 'connect rejects empty creds at constructor' => sub {
    # No mock involved — pure SDK guard.
    eval {
        my $c = SignalWire::Relay::Client->new(
            project => '',
            token   => '',
            host    => 'anywhere',
        );
        $c->connect;
    };
    like($@, qr/project and token are required/i,
         'connect with empty creds raises');
};

subtest 'unauthenticated raw connect rejected by mock' => sub {
    # Bypass the SDK guard: send a raw WebSocket frame with empty creds.
    # Use Protocol::WebSocket directly.
    require IO::Socket::INET;
    require Protocol::WebSocket::Client;
    require JSON;

    # Reset journal so this test only sees its own connect.
    RelayMockTest::journal_reset();

    my $sock = IO::Socket::INET->new(
        PeerHost => '127.0.0.1',
        PeerPort => $RelayMockTest::WS_PORT,
        Proto    => 'tcp',
        Timeout  => 5,
    );
    ok($sock, 'raw TCP connect to mock');

    my $ws = Protocol::WebSocket::Client->new(
        url => "ws://127.0.0.1:$RelayMockTest::WS_PORT/",
    );

    my @inbound;
    $ws->on(read => sub { push @inbound, $_[1] });
    $ws->on(write => sub {
        my (undef, $buf) = @_;
        syswrite($sock, $buf);
    });
    $ws->on(error => sub { fail("WS error: $_[1]") });

    $ws->connect;
    # Pump until handshake is done.
    {
        my $buf = '';
        while (my $bytes = sysread($sock, $buf, 4096, length($buf))) {
            $ws->read($buf);
            $buf = '';
            last if $ws->{hs}->is_done;
        }
    }

    # Send a signalwire.connect with empty creds.
    my $req_id = sprintf('%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
        int(rand(0xffff)), int(rand(0xffff)), int(rand(0xffff)),
        int(rand(0xffff)), int(rand(0xffff)),
        int(rand(0xffff)), int(rand(0xffff)), int(rand(0xffff)));
    my $req = JSON::encode_json({
        jsonrpc => '2.0',
        id      => $req_id,
        method  => 'signalwire.connect',
        params  => {
            version        => {
                major    => PROTOCOL_VERSION->{major},
                minor    => PROTOCOL_VERSION->{minor},
                revision => PROTOCOL_VERSION->{revision},
            },
            agent          => 'signalwire-agents-perl/1.0',
            authentication => { project => '', token => '' },
        },
    });
    $ws->write($req);

    # Read the response.
    my $deadline = time() + 5;
    while (!@inbound && time() < $deadline) {
        my $buf = '';
        my $ready = '';
        vec($ready, fileno($sock), 1) = 1;
        if (select($ready, undef, undef, 0.1)) {
            my $bytes = sysread($sock, $buf, 4096);
            $ws->read($buf) if $bytes;
        }
    }

    ok(@inbound, 'received a response');
    my $resp = JSON::decode_json($inbound[0]);
    ok($resp->{error}, 'response is an error');
    is($resp->{error}{data}{signalwire_error_code}, 'AUTH_REQUIRED',
       'signalwire_error_code is AUTH_REQUIRED');

    close($sock);
};

# ---------------------------------------------------------------------------
# JWT path
# ---------------------------------------------------------------------------

subtest 'connect with jwt carries jwt on wire' => sub {
    RelayMockTest::journal_reset();
    my $client = SignalWire::Relay::Client->new(
        project   => '',
        token     => '',
        jwt_token => 'fake-jwt-eyJ.AaaA.BbB',
        host      => "127.0.0.1:$RelayMockTest::WS_PORT",
        scheme    => 'ws',
        path      => '',
    );
    $client->connect;
    $client->disconnect;

    my $entries = RelayMockTest::journal_recv(method => 'signalwire.connect');
    is(scalar @$entries, 1, 'one connect frame');
    my $auth = $entries->[0]{frame}{params}{authentication};
    is($auth->{jwt_token}, 'fake-jwt-eyJ.AaaA.BbB', 'jwt_token on wire');
    ok(!$auth->{token},   'no token field with JWT');
    ok(!$auth->{project}, 'no project field with JWT');
};

done_testing();
