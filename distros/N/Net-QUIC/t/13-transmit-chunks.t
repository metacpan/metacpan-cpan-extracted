use strict;
use warnings;

use FindBin ();
use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;
use Time::HiRes qw(sleep);

use Net::QUIC::Connection;
use Net::QUIC::Endpoint;
use Net::QUIC::Stream;

my $client_local = pack_sockaddr_in(40013, inet_aton('127.0.0.1'));
my $server_local = pack_sockaddr_in(4443, inet_aton('127.0.0.1'));
my $alpn = 'net-quic-transmit-chunk-test';
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
ok(defined($initial), 'client produces Initial for transmit chunk test');

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

my $stream = $client->connection->open_bidi_stream;
my $stream_id = $stream->id;

my $payload = ("0123456789abcdef" x (24 * 1024)) . ("tail" x 30) . "xyz";
my $payload_len = length $payload;
my $chunk_size = 16 * 1024;
my $expected_chunks = int(($payload_len + $chunk_size - 1) / $chunk_size);

$stream->send($payload);

my $stats = $client->connection->_stream_tx_stats($stream_id);
is($expected_chunks, 25, 'test payload spans 25 fixed-size chunks');
is($stats->[0], $expected_chunks, 'one large send is split into fixed-size chunks');
is($stats->[1], $payload_len, 'all queued bytes are accounted for');

my $server_stream;
my $partial_release = 0;
my $partial_stats;

for (1 .. 200) {
    pump_pair($client, $server);
    $server_stream ||= $server->next_stream;

    $stats = $client->connection->_stream_tx_stats($stream_id);
    if ($stats->[0] < $expected_chunks && $stats->[0] > 0) {
        $partial_release = 1;
        $partial_stats = [@$stats];
        last;
    }
}

ok($partial_release, 'ACKs release early chunks before the whole send is acknowledged');
cmp_ok(
    $partial_stats->[1],
    '<',
    $payload_len,
    'buffered transmit bytes fall before the original send is fully acknowledged',
);
cmp_ok(
    $partial_stats->[1],
    '>',
    0,
    'later chunks remain buffered while earlier chunks have been freed',
);
isa_ok($server_stream, ['Net::QUIC::Stream']);

my $received = '';

for (1 .. 1000) {
    if ($server_stream) {
        while (defined(my $chunk = $server_stream->next_data)) {
            $received .= $chunk;
        }
    }

    pump_pair($client, $server);
    $server_stream ||= $server->next_stream;

    $stats = $client->connection->_stream_tx_stats($stream_id);
    last if length($received) == $payload_len
        && $stats->[0] == 0
        && $stats->[1] == 0;
}

is(length($received), $payload_len, 'peer receives the entire large send');
is($received, $payload, 'chunking preserves exact byte ordering and contents');

$stats = $client->connection->_stream_tx_stats($stream_id);
is($stats->[0], 0, 'all data chunks are released after acknowledgement');
is($stats->[1], 0, 'no acknowledged application bytes remain buffered');
ok(!$stream->closed, 'data chunks can be released while the stream remains open');

$stream->finish;

for (1 .. 500) {
    pump_pair($client, $server);

    while (defined(my $chunk = $server_stream->next_data)) {
        $received .= $chunk;
    }

    last if $server_stream->remote_finished;
}

ok($server_stream->remote_finished, 'FIN still follows the final data offset');
is($received, $payload, 'FIN does not duplicate or lose chunked data');

$server_stream->finish;

for (1 .. 500) {
    pump_pair($client, $server);
    last if $stream->closed && $server_stream->closed;
}

ok($stream->closed, 'client stream closes normally after chunked send');
ok($server_stream->closed, 'server stream closes normally after chunked send');

done_testing;
