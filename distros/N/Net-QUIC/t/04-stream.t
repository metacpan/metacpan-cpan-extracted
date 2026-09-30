use strict;
use warnings;

use FindBin ();
use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;
use Time::HiRes qw(sleep);

use Net::QUIC::Connection;
use Net::QUIC::Endpoint;

my $client_local = pack_sockaddr_in(40001, inet_aton('127.0.0.1'));
my $server_local = pack_sockaddr_in(4434, inet_aton('127.0.0.1'));
my $alpn = 'net-quic-stream-test';
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
ok(defined($initial), 'client produces Initial for stream proof');

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

ok($client->connection->ready, 'client is ready for stream proof');
ok($server->ready, 'server is ready for stream proof');

my $stream_id = $client->connection->_open_bidi_stream;
ok($stream_id >= 0, 'client opens a real bidirectional QUIC stream');
$client->connection->_stream_retain($stream_id);

my $request = join '', map { "request-$_\n" } 1 .. 1200;
$client->connection->_queue_stream_data($stream_id, $request, 1);

my $server_received = '';
my $server_fin = 0;
my $server_stream_id;
for (1 .. 200) {
    pump_pair($client, $server);

    while (my $event = $server->_take_stream_data) {
        $server_stream_id = $event->[0];
        $server_received .= $event->[1];
        $server_fin ||= $event->[2];
    }

    last if $server_fin;
}

is($server_stream_id, $stream_id, 'server receives the opened stream id');
is($server_received, $request, 'server receives the complete multi-packet payload');
ok($server_fin, 'server receives client FIN');

my $response = "stream-response\n";
$server->_queue_stream_data($stream_id, $response, 1);

my $client_received = '';
my $client_fin = 0;
my $client_stream_id;
for (1 .. 200) {
    pump_pair($client, $server);

    while (my $event = $client->connection->_take_stream_data) {
        $client_stream_id = $event->[0];
        $client_received .= $event->[1];
        $client_fin ||= $event->[2];
    }

    last if $client_fin;
}

is($client_stream_id, $stream_id, 'client response stays on the same bidi stream');
is($client_received, $response, 'client receives the response bytes');
ok($client_fin, 'client receives server FIN');

$client->connection->_stream_release($stream_id);

done_testing;
