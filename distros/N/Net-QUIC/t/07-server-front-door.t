use strict;
use warnings;

use FindBin ();
use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;
use Time::HiRes qw(sleep);

use Net::QUIC::Endpoint;

my $server_local = pack_sockaddr_in(4437, inet_aton('127.0.0.1'));
my $client_local = pack_sockaddr_in(40005, inet_aton('127.0.0.1'));
my $wrong_client_local = pack_sockaddr_in(40006, inet_aton('127.0.0.1'));
my $alpn = 'net-quic-front-door-test';
my $cert_file = "$FindBin::Bin/data/server-cert.pem";
my $key_file = "$FindBin::Bin/data/server-key.pem";

sub make_client {
    return Net::QUIC::Endpoint->client(
        local       => $client_local,
        peer        => $server_local,
        alpn        => $alpn,
        server_name => 'localhost',
        ca_file     => $cert_file,
    );
}

my $vn_server = Net::QUIC::Endpoint->server(
    alpn             => $alpn,
    certificate_file => $cert_file,
    private_key_file => $key_file,
);

my $vn_client = make_client();
my $initial = $vn_client->next_datagram;
ok(defined($initial), 'client produces Initial for version negotiation test');

my $unsupported = $initial->data;
substr($unsupported, 1, 4, pack('N', 0x1a2a3a4a));

$vn_server->receive_datagram(
    $unsupported,
    $server_local,
    $client_local,
);

ok(
    !defined($vn_server->next_connection),
    'unsupported version does not allocate a Connection',
);

my $vn = $vn_server->next_datagram;
ok(defined($vn), 'unsupported version produces a stateless response');
is(
    $vn->local,
    $server_local,
    'Version Negotiation preserves the concrete local destination address',
);
is(
    unpack('N', substr($vn->data, 1, 4)),
    0,
    'stateless response is a Version Negotiation packet',
);
my $vn_data = $vn->data;
my $offset = 5;
my $dcid_len = unpack('C', substr($vn_data, $offset, 1));
$offset += 1 + $dcid_len;
my $scid_len = unpack('C', substr($vn_data, $offset, 1));
$offset += 1 + $scid_len;
my @versions = unpack('N*', substr($vn_data, $offset));

ok(
    scalar(grep { $_ == 1 } @versions),
    'Version Negotiation advertises QUIC v1',
);
ok(
    !defined($vn_server->next_datagram),
    'Version Negotiation response is drained from stateless queue',
);

my $server = Net::QUIC::Endpoint->server(
    alpn             => $alpn,
    certificate_file => $cert_file,
    private_key_file => $key_file,
    validate_address => 1,
);
my $client = make_client();

$initial = $client->next_datagram;
ok(defined($initial), 'client produces Initial for Retry test');

$server->receive_datagram(
    $initial->data,
    $server_local,
    $client_local,
);

ok(
    !defined($server->next_connection),
    'first Initial does not allocate a Connection when address validation is enabled',
);

my $retry = $server->next_datagram;
ok(defined($retry), 'server answers first Initial with Retry');
is(
    $retry->local,
    $server_local,
    'Retry preserves the concrete local destination address',
);

$client->receive_datagram(
    $retry->data,
    $client_local,
    $server_local,
);

my $retried_initial = $client->next_datagram;
ok(defined($retried_initial), 'client answers Retry with another Initial');

$server->receive_datagram(
    $retried_initial->data,
    $server_local,
    $wrong_client_local,
);

ok(
    !defined($server->next_connection),
    'Retry token cannot be replayed from a different peer address',
);

my $invalid_token_response = $server->next_datagram;
ok(
    defined($invalid_token_response),
    'invalid address-bound Retry token gets a stateless rejection',
);
is(
    $invalid_token_response->peer,
    $wrong_client_local,
    'stateless rejection is addressed to the peer that used the bad token',
);
is(
    $invalid_token_response->local,
    $server_local,
    'stateless rejection preserves the concrete local destination address',
);

$server->receive_datagram(
    $retried_initial->data,
    $server_local,
    $client_local,
);

my $accepted = $server->next_connection;
ok(defined($accepted), 'validated Retry token allows Connection creation');
ok(!defined($server->next_connection), 'only one Connection is accepted');

sub pump_pair {
    my $progress = 0;

    while (my $datagram = $server->next_datagram) {
        ++$progress;
        $client->receive_datagram(
            $datagram->data,
            $client_local,
            $server_local,
        );
    }

    while (my $datagram = $client->next_datagram) {
        ++$progress;
        $server->receive_datagram(
            $datagram->data,
            $server_local,
            $client_local,
        );
    }

    my $server_after = $server->timeout_after;
    if (defined($server_after) && $server_after <= 0) {
        ++$progress;
        $server->handle_timeout;
    }

    my $client_after = $client->timeout_after;
    if (defined($client_after) && $client_after <= 0) {
        ++$progress;
        $client->handle_timeout;
    }

    if (!$progress) {
        my @wait = sort { $a <=> $b }
            grep { defined($_) && $_ > 0 }
            ($server_after, $client_after);

        if (@wait) {
            my $nap = $wait[0] > 0.01 ? 0.01 : $wait[0] + 0.001;
            sleep($nap);
            ++$progress;

            $server_after = $server->timeout_after;
            $server->handle_timeout
                if defined($server_after) && $server_after <= 0;

            $client_after = $client->timeout_after;
            $client->handle_timeout
                if defined($client_after) && $client_after <= 0;
        }
    }

    return $progress;
}

for (1 .. 500) {
    last if $client->connection->ready && $accepted->ready;
    last if !pump_pair();
}

ok($client->connection->ready, 'client handshake completes after Retry');
ok($accepted->ready, 'server handshake completes after Retry');

my $stream = $client->connection->open_bidi_stream;
$stream->send("validated-stream\n");
$stream->finish;

my $server_stream;
my $received = '';

for (1 .. 300) {
    pump_pair();

    $server_stream ||= $accepted->next_stream;
    if ($server_stream) {
        while (defined(my $chunk = $server_stream->next_data)) {
            $received .= $chunk;
        }
    }

    last if $server_stream
        && $server_stream->remote_finished
        && $received eq "validated-stream\n";
}

is($received, "validated-stream\n", 'stream traffic works after Retry validation');
ok($server_stream->remote_finished, 'FIN works after Retry validation');

done_testing;
