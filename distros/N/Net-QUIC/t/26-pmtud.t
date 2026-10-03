use strict;
use warnings;

use FindBin ();
use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;
use Time::HiRes qw(sleep);

use Net::QUIC::Connection;
use Net::QUIC::Endpoint;

my $client_a = pack_sockaddr_in(40300, inet_aton('127.0.0.1'));
my $client_b = pack_sockaddr_in(40301, inet_aton('127.0.0.1'));
my $server_local = pack_sockaddr_in(4480, inet_aton('127.0.0.1'));
my $alpn = 'net-quic-pmtud-test';
my $cert_file = "$FindBin::Bin/data/server-cert.pem";
my $key_file = "$FindBin::Bin/data/server-key.pem";

my $server_tls = Net::QUIC::_ServerTLS->_new($cert_file, $key_file);

my $client = Net::QUIC::Endpoint->client(
    local       => $client_a,
    peer        => $server_local,
    alpn        => $alpn,
    server_name => 'localhost',
    ca_file     => $cert_file,
);

is(
    $client->connection->path_max_udp_payload_size,
    1200,
    'new path starts at the QUIC minimum UDP payload size',
);

my $initial = $client->next_datagram;
ok(defined($initial), 'client produces Initial');

my $server = Net::QUIC::Connection->_server_new(
    $initial->data,
    $server_local,
    $client_a,
    $alpn,
    $server_tls,
);

$server->_receive_datagram(
    $initial->data,
    $server_local,
    $client_a,
);

sub pump_pair {
    my (%args) = @_;
    my $progress = 0;

    while (my $datagram = $server->_next_datagram) {
        ++$progress;
        $client->receive_datagram(
            $datagram->data,
            $datagram->peer,
            $datagram->local,
        );
    }

    while (my $datagram = $client->next_datagram) {
        ++$progress;

        if ($args{drop_large_b}
            && $datagram->local eq $client_b
            && length($datagram->data) > 1200) {
            next;
        }

        $server->_receive_datagram(
            $datagram->data,
            $datagram->peer,
            $datagram->local,
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
        my @wait = sort { $a <=> $b }
            grep { defined($_) && $_ > 0 }
            ($client_after, $server_after);

        if (@wait) {
            my $nap = $wait[0] > 0.01 ? 0.01 : $wait[0] + 0.001;
            sleep($nap);
            ++$progress;
        }
    }

    return $progress;
}

for (1 .. 600) {
    pump_pair();
    last if $client->connection->ready && $server->ready;
}

ok($client->connection->ready, 'client handshake completes');
ok($server->ready, 'server handshake completes');

my $discovered_a = $client->connection->path_max_udp_payload_size;

for (1 .. 1000) {
    last if $discovered_a > 1200;
    pump_pair();
    $discovered_a = $client->connection->path_max_udp_payload_size;
}

cmp_ok(
    $discovered_a,
    '>',
    1200,
    'ngtcp2 PMTUD raises the path A UDP payload ceiling',
);
cmp_ok(
    $discovered_a,
    '<=',
    1452,
    'discovered payload ceiling respects the default transmit maximum',
);

$client->connection->migrate($client_b);

for (1 .. 1000) {
    pump_pair(drop_large_b => 1);
    last if $client->connection->path_validation_status eq 'succeeded';
}

is(
    $client->connection->path_validation_status,
    'succeeded',
    'path B validates while oversized probe traffic is withheld',
);
is(
    $client->connection->path->{local},
    $client_b,
    'client switches to path B',
);

is(
    $client->connection->path_max_udp_payload_size,
    1200,
    'newly validated path B restarts at the QUIC minimum',
);

my $discovered_b = $client->connection->path_max_udp_payload_size;

for (1 .. 1000) {
    last if $discovered_b > 1200;
    pump_pair();
    $discovered_b = $client->connection->path_max_udp_payload_size;
}

cmp_ok(
    $discovered_b,
    '>',
    1200,
    'PMTUD restarts and raises the payload ceiling on path B',
);
cmp_ok(
    $discovered_b,
    '<=',
    1452,
    'path B discovery also respects the transmit maximum',
);

done_testing;
