use strict;
use warnings;

use FindBin ();
use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;
use Time::HiRes qw(sleep);

use Net::QUIC::Endpoint;

my $server_local = pack_sockaddr_in(4441, inet_aton('127.0.0.1'));
my $client_local = pack_sockaddr_in(40010, inet_aton('127.0.0.1'));
my $alpn = 'net-quic-stateless-reset-test';
my $cert_file = "$FindBin::Bin/data/server-cert.pem";
my $key_file = "$FindBin::Bin/data/server-key.pem";

sub make_server {
    return Net::QUIC::Endpoint->server(
        alpn             => $alpn,
        certificate_file => $cert_file,
        private_key_file => $key_file,
    );
}

sub make_client {
    return Net::QUIC::Endpoint->client(
        local       => $client_local,
        peer        => $server_local,
        alpn        => $alpn,
        server_name => 'localhost',
        ca_file     => $cert_file,
    );
}

sub pump_pair {
    my ($server, $client) = @_;
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

my $policy_server = make_server();

my $small_short = chr(0x40) . ('s' x 16) . ('x' x 19);
is(length($small_short), 36, 'small short-header probe is below reset threshold');

$policy_server->receive_datagram(
    $small_short,
    $server_local,
    $client_local,
);

ok(
    !defined($policy_server->next_datagram),
    'undersized unknown short-header packet is silently dropped',
);
ok(
    !defined($policy_server->next_connection),
    'undersized unknown packet does not allocate a Connection',
);

my $long_unknown =
      pack('C N C', 0xe0, 1, 16)
    . ('l' x 16)
    . pack('C', 8)
    . ('p' x 8)
    . ('z' x 80);

$policy_server->receive_datagram(
    $long_unknown,
    $server_local,
    $client_local,
);

ok(
    !defined($policy_server->next_datagram),
    'unknown long-header packet is silently dropped',
);
ok(
    !defined($policy_server->next_connection),
    'unknown long-header packet does not allocate a Connection',
);

my $large_short = chr(0x40) . ('u' x 16) . ('q' x 80);

$policy_server->receive_datagram(
    $large_short,
    $server_local,
    $client_local,
);

my $unknown_reset = $policy_server->next_datagram;
ok(defined($unknown_reset), 'large unknown short-header packet gets a stateless reset');
ok(
    length($unknown_reset->data) < length($large_short),
    'stateless reset is smaller than the packet that triggered it',
);
is(
    ord(substr($unknown_reset->data, 0, 1)) & 0xc0,
    0x40,
    'stateless reset has QUIC short-header fixed bits',
);
ok(
    !defined($policy_server->next_connection),
    'stateless reset does not allocate a Connection',
);

my $server = make_server();
my $client = make_client();

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
    last if !pump_pair($server, $client);
}

ok($client->connection->ready, 'client handshake completes');
ok($accepted->ready, 'server handshake completes');

my $stream = $client->connection->open_bidi_stream;
$stream->send('r' x 256);
$stream->finish;

my $probe;
for (1 .. 500) {
    while (my $server_datagram = $server->next_datagram) {
        $client->receive_datagram(
            $server_datagram->data,
            $client_local,
            $server_local,
        );
    }

    my $datagram = $client->next_datagram;
    if (defined($datagram)) {
        if (
            (ord(substr($datagram->data, 0, 1)) & 0x80) == 0
            && length($datagram->data) >= 37
        ) {
            $probe = $datagram;
            last;
        }

        $server->receive_datagram(
            $datagram->data,
            $server_local,
            $client_local,
        );
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

ok(defined($probe), 'client produces a reset-eligible short-header packet');

my $issued_cid = $server->_packet_dcid(
    $probe->data,
    $server->{cid_length},
);

ok(defined($issued_cid), 'probe contains a server-issued destination CID');
ok(exists($server->{routes}{$issued_cid}), 'issued CID is routed before simulated state loss');

@{$server->{connections}} = ();
@{$server->{pending_connections}} = ();
%{$server->{routes}} = ();
$server->{tx_cursor} = 0;
undef $accepted;

is(
    $server->_managed_connection_count,
    0,
    'simulated state loss removes the server Connection before reset',
);
is($server->_route_count, 0, 'simulated state loss removes all CID routes');

$server->receive_datagram(
    $probe->data,
    $server_local,
    $client_local,
);

my $known_reset = $server->next_datagram;
ok(defined($known_reset), 'lost Connection state for issued CID gets a stateless reset');
ok(
    length($known_reset->data) < length($probe->data),
    'issued-CID reset is smaller than its triggering packet',
);
is(
    $server->_managed_connection_count,
    0,
    'stateless reset path does not recreate the lost Connection',
);
ok(
    !defined($server->next_connection),
    'stateless reset path does not create another accept event',
);

$client->receive_datagram(
    $known_reset->data,
    $client_local,
    $server_local,
);

$client->connection->close(77);

ok(
    !defined($client->next_datagram),
    'client recognizes issued-CID reset and sends no CONNECTION_CLOSE',
);

done_testing;
