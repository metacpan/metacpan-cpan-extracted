use strict;
use warnings;

use FindBin ();
use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;
use Time::HiRes qw(sleep);

use Net::QUIC::Connection;
use Net::QUIC::Endpoint;
use Net::QUIC::Stream;

my $client_local = pack_sockaddr_in(40020, inet_aton('127.0.0.1'));
my $server_local = pack_sockaddr_in(4450, inet_aton('127.0.0.1'));
my $alpn = 'net-quic-directional-stream-abort-test';
my $cert_file = "$FindBin::Bin/data/server-cert.pem";
my $key_file = "$FindBin::Bin/data/server-key.pem";

my $server_tls = Net::QUIC::_ServerTLS->_new($cert_file, $key_file);

sub pump_pair {
    my ($client, $server) = @_;
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
                ++$progress;
                $client->handle_timeout;
            }

            $server_after = $server->_timeout_after;
            if (defined($server_after) && $server_after <= 0) {
                ++$progress;
                $server->_handle_timeout;
            }
        }
    }

    return $progress;
}

my $client = Net::QUIC::Endpoint->client(
    local       => $client_local,
    peer        => $server_local,
    alpn        => $alpn,
    server_name => 'localhost',
    ca_file     => $cert_file,
);

my $initial = $client->next_datagram;
ok(defined($initial), 'client produces Initial');

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

for (1 .. 100) {
    last if $client->connection->ready && $server->ready;
    last if !pump_pair($client, $server);
}

ok($client->connection->ready, 'client handshake is ready');
ok($server->ready, 'server handshake is ready');

my $reset_client = $client->connection->open_bidi_stream;
my $reset_id = $reset_client->id;

ok(!defined($reset_client->local_reset_code),
    'local reset code starts undefined');

$reset_client->send("queued-before-reset\n");
my $before_reset_stats = $client->connection->_stream_tx_stats($reset_id);
cmp_ok(
    $before_reset_stats->[1],
    '>',
    0,
    'RESET_STREAM test begins with queued transmit bytes',
);

$reset_client->reset(77);
is($reset_client->local_reset_code, 77,
    'reset records the local RESET_STREAM code');

$reset_client->reset(78);
is(
    $reset_client->local_reset_code,
    77,
    'repeated reset preserves the first RESET_STREAM code',
);

my $after_reset_stats = $client->connection->_stream_tx_stats($reset_id);
is(
    $after_reset_stats->[1],
    0,
    'RESET_STREAM immediately releases queued transmit bytes',
);

my $reset_server;
for (1 .. 200) {
    pump_pair($client, $server);

    while (my $stream = $server->next_stream) {
        $reset_server = $stream if $stream->id == $reset_id;
    }

    last if $reset_server
        && defined $reset_server->remote_reset_code;
}

isa_ok($reset_server, ['Net::QUIC::Stream']);
is($reset_server->remote_reset_code, 77,
    'peer receives the RESET_STREAM code');

my $after_reset = "receive-side-still-open\n";
$reset_server->send($after_reset);
$reset_server->finish;

my $after_reset_received = '';
for (1 .. 200) {
    pump_pair($client, $server);

    while (defined(my $chunk = $reset_client->next_data)) {
        $after_reset_received .= $chunk;
    }

    last if $reset_client->remote_finished
        && $after_reset_received eq $after_reset;
}

is($after_reset_received, $after_reset,
    'RESET_STREAM does not close the opposite receive direction');
ok($reset_client->remote_finished,
    'peer can finish the opposite direction after RESET_STREAM');

my $stop_client = $client->connection->open_bidi_stream;
my $stop_id = $stop_client->id;
$stop_client->send("data-that-will-be-discarded\n");

my $stop_server;
for (1 .. 200) {
    pump_pair($client, $server);

    while (my $stream = $server->next_stream) {
        $stop_server = $stream if $stream->id == $stop_id;
    }

    last if $stop_server;
}

isa_ok($stop_server, ['Net::QUIC::Stream']);

my $before_stop_stats = $client->connection->_stream_tx_stats($stop_id);
cmp_ok(
    $before_stop_stats->[1],
    '>',
    0,
    'client still retains unacknowledged transmit bytes before STOP_SENDING',
);

ok(!defined($stop_server->local_stop_sending_code),
    'local STOP_SENDING code starts undefined');

$stop_server->stop_sending(88);
is($stop_server->local_stop_sending_code, 88,
    'stop_sending records the local STOP_SENDING code');

$stop_server->stop_sending(89);
is(
    $stop_server->local_stop_sending_code,
    88,
    'repeated stop_sending preserves the first STOP_SENDING code',
);

ok(!defined($stop_server->next_data),
    'stop_sending discards unread receive data');

for (1 .. 300) {
    pump_pair($client, $server);

    last if defined($stop_client->remote_stop_sending_code)
        && defined($stop_server->remote_reset_code);
}

is($stop_client->remote_stop_sending_code, 88,
    'peer observes the STOP_SENDING code');
ok(!defined($stop_client->local_reset_code),
    'peer STOP_SENDING does not masquerade as an explicit local reset');
is($stop_server->remote_reset_code, 88,
    'STOP_SENDING endpoint receives the matching RESET_STREAM when required');

my $after_stop_stats = $client->connection->_stream_tx_stats($stop_id);
is(
    $after_stop_stats->[1],
    0,
    'stopped send side releases retained transmit bytes after packet processing',
);

like(
    dies { $stop_client->send('more data') },
    qr/(?:shut|shutdown|queue QUIC stream data)/i,
    'peer cannot continue sending after STOP_SENDING',
);

my $after_stop = "send-side-still-open\n";
$stop_server->send($after_stop);
$stop_server->finish;

my $after_stop_received = '';
for (1 .. 200) {
    pump_pair($client, $server);

    while (defined(my $chunk = $stop_client->next_data)) {
        $after_stop_received .= $chunk;
    }

    last if $stop_client->remote_finished
        && $after_stop_received eq $after_stop;
}

is($after_stop_received, $after_stop,
    'STOP_SENDING does not close the opposite send direction');
ok($stop_client->remote_finished,
    'opposite direction can finish after STOP_SENDING');

my $local_uni = $client->connection->open_uni_stream;
like(
    dies { $local_uni->stop_sending(1) },
    qr/cannot stop the receive side/,
    'local unidirectional stream cannot send STOP_SENDING',
);

$local_uni->send("uni-direction-check\n");

my $remote_uni;
for (1 .. 200) {
    pump_pair($client, $server);

    while (my $stream = $server->next_stream) {
        $remote_uni = $stream if $stream->id == $local_uni->id;
    }

    last if $remote_uni;
}

isa_ok($remote_uni, ['Net::QUIC::Stream']);
like(
    dies { $remote_uni->reset(1) },
    qr/cannot reset the send side/,
    'remote unidirectional stream cannot send RESET_STREAM',
);

done_testing;
