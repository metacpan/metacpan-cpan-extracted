use strict;
use warnings;

use FindBin ();
use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;
use Time::HiRes qw(sleep);

use Net::QUIC::Connection;
use Net::QUIC::Endpoint;

my $client_local = pack_sockaddr_in(40000, inet_aton('127.0.0.1'));
my $server_local = pack_sockaddr_in(4433, inet_aton('127.0.0.1'));
my $alpn = 'net-quic-test';
my $cert_file = "$FindBin::Bin/data/server-cert.pem";
my $key_file = "$FindBin::Bin/data/server-key.pem";

my $server_tls = Net::QUIC::_ServerTLS->_new($cert_file, $key_file);

ok(-f $cert_file, 'test server certificate exists');
ok(-f $key_file, 'test server private key exists');

my $client = Net::QUIC::Endpoint->client(
    local       => $client_local,
    peer        => $server_local,
    alpn        => $alpn,
    server_name => 'localhost',
    ca_file     => $cert_file,
);

my $initial = $client->next_datagram;
ok(defined($initial), 'client produces an Initial for the server proof');

my $server = Net::QUIC::Connection->_server_new(
    $initial->data,
    $server_local,
    $client_local,
    $alpn,
    $server_tls,
);

isa_ok($server, ['Net::QUIC::Connection'], 'private server connection is created');
undef $server_tls;
ok(!$client->connection->ready, 'client is not ready before packet exchange');
ok(!$server->ready, 'server is not ready before receiving the Initial');

$server->_receive_datagram(
    $initial->data,
    $server_local,
    $client_local,
);

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

for (1 .. 300) {
    last if $client->connection->ready && $server->ready;
    last if !pump_pair($client, $server);
}

ok($client->connection->ready, 'client completes the in-memory QUIC/TLS handshake');
ok($server->ready, 'server completes the in-memory QUIC/TLS handshake');

done_testing;
