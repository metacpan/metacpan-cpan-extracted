use strict;
use warnings;

use FindBin ();
use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;
use Time::HiRes qw(sleep);

use Net::QUIC::Connection;
use Net::QUIC::Endpoint;

my $server_local = pack_sockaddr_in(4452, inet_aton('127.0.0.1'));
my $alpn = 'net-quic-0rtt-test';
my $cert_file = "$FindBin::Bin/data/server-cert.pem";
my $key_file = "$FindBin::Bin/data/server-key.pem";

sub pump_pair {
    my ($client, $server, $client_local) = @_;
    my $progress = 0;

    while (my $datagram = $server->_next_datagram) {
        ++$progress;
        $client->receive_datagram(
            $datagram->data,
            $client_local,
            $server_local,
        );
    }

    while (my $datagram = $client->next_datagram) {
        ++$progress;
        $server->_receive_datagram(
            $datagram->data,
            $server_local,
            $client_local,
        );
    }

    my $client_after = $client->timeout_after;
    if (defined($client_after) && $client_after <= 0) {
        ++$progress;
        $client->handle_timeout;
    }

    my $server_after = $server->_timeout_after;
    if (defined($server_after) && $server_after <= 0) {
        ++$progress;
        $server->_handle_timeout;
    }

    if (!$progress) {
        my $wait;

        for my $after ($client_after, $server_after) {
            next if !defined($after) || $after <= 0;
            $wait = $after if !defined($wait) || $after < $wait;
        }

        if (defined $wait) {
            my $nap = $wait > 0.01 ? 0.01 : $wait + 0.001;
            sleep($nap);
            ++$progress;

            $client_after = $client->timeout_after;
            if (defined($client_after) && $client_after <= 0) {
                $client->handle_timeout;
            }

            $server_after = $server->_timeout_after;
            if (defined($server_after) && $server_after <= 0) {
                $server->_handle_timeout;
            }
        }
    }

    return $progress;
}

sub new_client {
    my (%args) = @_;

    my %client_args = (
        local       => $args{local},
        peer        => $server_local,
        alpn        => $alpn,
        server_name => 'localhost',
        ca_file     => $cert_file,
    );

    $client_args{early_data} = $args{early_data}
        if defined $args{early_data};

    return Net::QUIC::Endpoint->client(%client_args);
}

sub new_server_connection {
    my ($client, $client_local, $server_tls) = @_;

    my $initial = $client->next_datagram;
    ok(defined($initial), 'client produces an Initial');

    my $server = Net::QUIC::Connection->_server_new(
        $initial->data,
        $server_local,
        $client_local,
        $alpn,
        $server_tls,
    );

    $server->_receive_datagram(
        $initial->data,
        $server_local,
        $client_local,
    );

    return $server;
}

my $server_tls = Net::QUIC::_ServerTLS->_new(
    $cert_file,
    $key_file,
    1,
);

my $first_local = pack_sockaddr_in(40031, inet_aton('127.0.0.1'));
my $first_client = new_client(local => $first_local);
my $first_server = new_server_connection(
    $first_client,
    $first_local,
    $server_tls,
);

for (1 .. 500) {
    pump_pair($first_client, $first_server, $first_local);
    last if $first_client->connection->ready
        && $first_server->ready
        && defined($first_client->connection->session_ticket);
}

ok($first_client->connection->ready, 'first client handshake completes');
ok($first_server->ready, 'first server handshake completes');

my $early_state = $first_client->connection->early_data_state;
ok(defined($early_state), 'first connection exports opaque early-data state');
cmp_ok(length($early_state), '>', 13, 'early-data state contains saved material');

my $second_local = pack_sockaddr_in(40032, inet_aton('127.0.0.1'));
my $second_client = new_client(
    local      => $second_local,
    early_data => $early_state,
);

is(
    $second_client->connection->early_data_status,
    'pending',
    '0-RTT attempt starts pending',
);
ok(!$second_client->connection->ready, '0-RTT client starts before handshake readiness');

my $early_stream = $second_client->connection->open_bidi_stream;
isa_ok($early_stream, ['Net::QUIC::Stream']);
$early_stream->send("zero-rtt\n");
$early_stream->finish;

my $second_server = new_server_connection(
    $second_client,
    $second_local,
    $server_tls,
);

while (my $datagram = $second_client->next_datagram) {
    $second_server->_receive_datagram(
        $datagram->data,
        $server_local,
        $second_local,
    );
}

ok(
    !$second_server->ready,
    'server receives 0-RTT before the handshake is complete',
);

my $server_early_stream = $second_server->next_stream;
isa_ok(
    $server_early_stream,
    ['Net::QUIC::Stream'],
    'server sees the 0-RTT stream before handshake completion',
);
ok(
    $server_early_stream->early_data,
    'server stream retains its 0-RTT origin',
);
is(
    $server_early_stream->next_data,
    "zero-rtt\n",
    'server receives application bytes in 0-RTT',
);

for (1 .. 500) {
    pump_pair($second_client, $second_server, $second_local);
    last if $second_client->connection->ready && $second_server->ready;
}

ok($second_client->connection->ready, '0-RTT client handshake completes');
ok($second_server->ready, '0-RTT server handshake completes');
ok($second_client->connection->resumed, '0-RTT connection resumes TLS');
is(
    $second_client->connection->early_data_status,
    'accepted',
    'client reports accepted 0-RTT',
);

my $third_local = pack_sockaddr_in(40033, inet_aton('127.0.0.1'));
my $third_client = new_client(
    local      => $third_local,
    early_data => $early_state,
);

my $rejected_stream = $third_client->connection->open_bidi_stream;
my $rejected_stream_id = $rejected_stream->id;
$rejected_stream->send("must-not-survive\n");
$rejected_stream->finish;

my $third_server = new_server_connection(
    $third_client,
    $third_local,
    $server_tls,
);

while (my $datagram = $third_client->next_datagram) {
    $third_server->_receive_datagram(
        $datagram->data,
        $server_local,
        $third_local,
    );
}

ok(
    !defined($third_server->next_stream),
    'server does not expose replayed 0-RTT data',
);

for (1 .. 500) {
    pump_pair($third_client, $third_server, $third_local);
    last if $third_client->connection->ready
        && $third_server->ready
        && $third_client->connection->early_data_status eq 'rejected';
}

ok($third_client->connection->ready, 'fallback client handshake completes');
ok($third_server->ready, 'fallback server handshake completes');
is(
    $third_client->connection->early_data_status,
    'rejected',
    'client reports rejected 0-RTT',
);
ok(
    $third_client->connection->resumed,
    'replayed ticket still permits ordinary TLS resumption',
);

like(
    dies { $rejected_stream->send("stale\n") },
    qr/unknown QUIC stream/,
    'stream object from replay-rejected 0-RTT is invalidated',
);

my $retry_stream = $third_client->connection->open_bidi_stream;
isa_ok($retry_stream, ['Net::QUIC::Stream']);
is(
    $retry_stream->id,
    $rejected_stream_id,
    'rejected 0-RTT stream ID is reusable after rollback',
);
$retry_stream->send("after-rejection\n");
$retry_stream->finish;

my $retry_incoming;
for (1 .. 500) {
    pump_pair($third_client, $third_server, $third_local);
    $retry_incoming ||= $third_server->next_stream;
    last if $retry_incoming;
}

ok(defined($retry_incoming), 'server sees replacement stream after rejection');
if ($retry_incoming) {
    my $bytes;
    for (1 .. 500) {
        $bytes = $retry_incoming->next_data;
        last if defined $bytes;
        pump_pair($third_client, $third_server, $third_local);
    }

    is(
        $bytes,
        "after-rejection\n",
        'application can resend on a new stream after rejection',
    );
}

like(
    dies {
        new_client(
            local      => pack_sockaddr_in(40034, inet_aton('127.0.0.1')),
            early_data => "not-a-valid-state",
        );
    },
    qr/early_data|early-data state/i,
    'malformed early-data state is rejected',
);

done_testing;
