use strict;
use warnings;

use FindBin ();
use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;
use Time::HiRes qw(sleep);

use Net::QUIC::Endpoint;

my $client_local = pack_sockaddr_in(40110, inet_aton('127.0.0.1'));
my $server_initial = pack_sockaddr_in(4461, inet_aton('127.0.0.1'));
my $server_preferred = pack_sockaddr_in(4462, inet_aton('127.0.0.1'));
my $alpn = 'net-quic-preferred-address-test';
my $cert_file = "$FindBin::Bin/data/server-cert.pem";
my $key_file = "$FindBin::Bin/data/server-key.pem";

my $saw_client_to_preferred = 0;
my $saw_server_from_preferred = 0;

my $server = Net::QUIC::Endpoint->server(
    alpn              => $alpn,
    certificate_file  => $cert_file,
    private_key_file  => $key_file,
    preferred_address => $server_preferred,
);

my $client = Net::QUIC::Endpoint->client(
    local       => $client_local,
    peer        => $server_initial,
    alpn        => $alpn,
    server_name => 'localhost',
    ca_file     => $cert_file,
);

sub pump_pair {
    my $progress = 0;

    while (my $datagram = $server->next_datagram) {
        ++$progress;
        ++$saw_server_from_preferred
            if $datagram->local eq $server_preferred;
        $client->receive_datagram(
            $datagram->data,
            $datagram->peer,
            $datagram->local,
        );
    }

    while (my $datagram = $client->next_datagram) {
        ++$progress;
        ++$saw_client_to_preferred
            if $datagram->peer eq $server_preferred;
        $server->receive_datagram(
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

    my $server_after = $server->timeout_after;
    if (defined($server_after) && $server_after <= 0) {
        ++$progress;
        $server->handle_timeout;
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

my $accepted;

for (1 .. 1200) {
    while (my $datagram = $server->next_datagram) {
        ++$saw_server_from_preferred
            if $datagram->local eq $server_preferred;

        $client->receive_datagram(
            $datagram->data,
            $datagram->peer,
            $datagram->local,
        );
    }

    while (my $datagram = $client->next_datagram) {
        ++$saw_client_to_preferred
            if $datagram->peer eq $server_preferred;

        $server->receive_datagram(
            $datagram->data,
            $datagram->peer,
            $datagram->local,
        );
    }

    $accepted ||= $server->next_connection;

    last if $accepted
        && $client->connection->ready
        && $accepted->ready
        && $client->connection->path_validation_status eq 'succeeded'
        && $client->connection->path->{peer} eq $server_preferred;

    pump_pair();
}

ok($accepted, 'server accepts the connection');
ok($client->connection->ready, 'client handshake completes');
ok($accepted && $accepted->ready, 'server handshake completes');

is(
    $client->connection->path_validation_status,
    'succeeded',
    'preferred path validates successfully',
);

my $validation = $client->connection->path_validation;
ok($validation->{preferred_address}, 'validation is marked as preferred-address work');
is($validation->{local}, $client_local, 'preferred path keeps client local address');
is($validation->{peer}, $server_preferred, 'preferred path targets advertised server address');

my $client_path = $client->connection->path;
is($client_path->{local}, $client_local, 'client local path remains unchanged');
is($client_path->{peer}, $server_preferred, 'client switches to server preferred address');

ok($saw_client_to_preferred, 'client sends validation traffic to preferred address');

my $stream = $client->connection->open_bidi_stream;
isa_ok($stream, ['Net::QUIC::Stream']);
$stream->send("through-preferred-address\n");
$stream->finish;

my $incoming;
my $bytes;
for (1 .. 500) {
    pump_pair();
    $incoming ||= $accepted->next_stream;

    if ($incoming) {
        $bytes = $incoming->next_data;
        last if defined $bytes;
    }
}

isa_ok($incoming, ['Net::QUIC::Stream']);
is(
    $bytes,
    "through-preferred-address\n",
    'server Endpoint routes stream traffic on preferred CID/path',
);
ok(
    $saw_server_from_preferred,
    'server sends post-selection traffic from preferred address',
);

my $server_path = $accepted->path;
is($server_path->{local}, $server_preferred, 'server current local path becomes preferred address');
is($server_path->{peer}, $client_local, 'server current peer remains client');

done_testing;
