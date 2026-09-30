use strict;
use warnings;

use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;

use Net::QUIC::Connection;
use Net::QUIC::Datagram;
use Net::QUIC::Endpoint;

my $local = pack_sockaddr_in(40000, inet_aton('127.0.0.1'));
my $peer  = pack_sockaddr_in(4433, inet_aton('127.0.0.1'));

my $endpoint = Net::QUIC::Endpoint->client(
    local       => $local,
    peer        => $peer,
    alpn        => 'net-quic-test',
    server_name => 'localhost',
);

isa_ok($endpoint, ['Net::QUIC::Endpoint'], 'client endpoint is created');

my $connection = $endpoint->connection;
isa_ok($connection, ['Net::QUIC::Connection'], 'client endpoint owns a connection');
ok(!$connection->ready, 'new connection is not ready before the handshake');

my $datagram = $endpoint->next_datagram;
isa_ok($datagram, ['Net::QUIC::Datagram'], 'client produces an initial datagram');

ok(length($datagram->data) >= 1200, 'initial QUIC datagram is at least 1200 bytes');
is($datagram->local, $local, 'outbound datagram keeps the local address');
is($datagram->peer, $peer, 'outbound datagram keeps the peer address');

my $after = $endpoint->timeout_after;
ok(defined($after), 'client reports a timer after initial transmission');
ok($after >= 0, 'timer delay is non-negative');

like(
    dies { Net::QUIC::Endpoint->client(local => $local, peer => $peer) },
    qr/missing required alpn argument/,
    'client constructor explains a missing required argument',
);

done_testing;
