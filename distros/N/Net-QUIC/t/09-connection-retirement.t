use strict;
use warnings;

use FindBin ();
use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;
use Time::HiRes qw(sleep);

use Net::QUIC::Endpoint;

my $server_local = pack_sockaddr_in(4439, inet_aton('127.0.0.1'));
my $client_local = pack_sockaddr_in(40008, inet_aton('127.0.0.1'));
my $alpn = 'net-quic-connection-retirement-test';
my $cert_file = "$FindBin::Bin/data/server-cert.pem";
my $key_file = "$FindBin::Bin/data/server-key.pem";

my $server = Net::QUIC::Endpoint->server(
    alpn             => $alpn,
    certificate_file => $cert_file,
    private_key_file => $key_file,
);

my $client = Net::QUIC::Endpoint->client(
    local       => $client_local,
    peer        => $server_local,
    alpn        => $alpn,
    server_name => 'localhost',
    ca_file     => $cert_file,
);

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
        }
    }

    return $progress;
}

my $initial = $client->next_datagram;
ok(defined($initial), 'client produces Initial');

$server->receive_datagram(
    $initial->data,
    $server_local,
    $client_local,
);

my $accepted = $server->next_connection;
ok(defined($accepted), 'server accepts one connection');

for (1 .. 500) {
    last if $client->connection->ready && $accepted->ready;
    last if !pump_pair();
}

ok($client->connection->ready, 'client handshake completes');
ok($accepted->ready, 'server handshake completes');
is($server->_managed_connection_count, 1, 'server manages one connection');
ok($server->_route_count >= 1, 'server has CID routes for the connection');

my $stream = $client->connection->open_bidi_stream;
$stream->send('r' x 256);
$stream->finish;

my $retired_probe;
for (1 .. 500) {
    while (my $server_datagram = $server->next_datagram) {
        $client->receive_datagram(
            $server_datagram->data,
            $client_local,
            $server_local,
        );
    }

    my $datagram = $client->next_datagram;
    if (defined $datagram) {
        if (
            (ord(substr($datagram->data, 0, 1)) & 0x80) == 0
            && length($datagram->data) >= 37
        ) {
            $retired_probe = $datagram;
        }

        $server->receive_datagram(
            $datagram->data,
            $server_local,
            $client_local,
        );

        last if defined $retired_probe;
        next;
    }

    my $server_after = $server->timeout_after;
    my $client_after = $client->timeout_after;

    $server->handle_timeout
        if defined($server_after) && $server_after <= 0;
    $client->handle_timeout
        if defined($client_after) && $client_after <= 0;

    my @wait = sort { $a <=> $b }
        grep { defined($_) && $_ > 0 }
        ($server_after, $client_after);

    last if !@wait;

    my $nap = $wait[0] > 0.01 ? 0.01 : $wait[0] + 0.001;
    sleep($nap);
}

ok(
    defined($retired_probe),
    'captured a reset-eligible packet for a server-issued CID',
);

$client->connection->close(42);
ok(!$client->connection->closed, 'local close begins a closing period');
is(
    $client->connection->close_info,
    {
        type      => 'application',
        initiator => 'local',
        code      => 42,
    },
    'local application close is recorded',
);

my $close_datagram = $client->next_datagram;
ok(defined($close_datagram), 'local close produces a CONNECTION_CLOSE datagram');

$server->receive_datagram(
    $close_datagram->data,
    $server_local,
    $client_local,
);

ok(!$accepted->closed, 'peer close begins a draining period');
is(
    $accepted->close_info,
    {
        type      => 'application',
        initiator => 'peer',
        code      => 42,
    },
    'peer application close is recorded',
);
is(
    $server->_managed_connection_count,
    1,
    'server keeps connection during draining period',
);
ok(
    $server->_route_count >= 1,
    'CID routes remain during draining period',
);

for (1 .. 1000) {
    last if $accepted->closed && $client->connection->closed;
    pump_pair();
}

ok($accepted->closed, 'server connection retires after draining period');
ok($client->connection->closed, 'client connection retires after closing period');
is($server->_managed_connection_count, 0, 'retired connection leaves server ownership');
is($server->_route_count, 0, 'all CID routes are removed at retirement');
ok(!defined($server->timeout_after), 'retired server connection no longer needs a timer');

$server->receive_datagram(
    $retired_probe->data,
    $server_local,
    $client_local,
);

my $reset = $server->next_datagram;
ok(defined($reset), 'replayed retired CID receives a stateless reset');
ok(
    length($reset->data) < length($retired_probe->data),
    'retired-CID reset is smaller than the triggering packet',
);
is(
    ord(substr($reset->data, 0, 1)) & 0xc0,
    0x40,
    'retired-CID reset has QUIC short-header fixed bits',
);
is(
    $server->_managed_connection_count,
    0,
    'replaying packet for retired CID does not recreate connection',
);
is($server->_route_count, 0, 'replayed retired CID does not recreate a route');
ok(!defined($server->next_connection), 'replayed packet does not create an accept event');

done_testing;
