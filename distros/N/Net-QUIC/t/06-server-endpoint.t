use strict;
use warnings;

use FindBin ();
use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;
use Time::HiRes qw(sleep);

use Net::QUIC::Endpoint;

my $server_local = pack_sockaddr_in(4436, inet_aton('127.0.0.1'));
my @client_local = (
    pack_sockaddr_in(40003, inet_aton('127.0.0.1')),
    pack_sockaddr_in(40004, inet_aton('127.0.0.1')),
);
my $alpn = 'net-quic-server-endpoint-test';
my $cert_file = "$FindBin::Bin/data/server-cert.pem";
my $key_file = "$FindBin::Bin/data/server-key.pem";

my $server = Net::QUIC::Endpoint->server(
    alpn             => $alpn,
    certificate_file => $cert_file,
    private_key_file => $key_file,
);

$server->receive_datagram(
    "not a QUIC packet",
    $server_local,
    $client_local[0],
);
ok(!defined($server->next_connection), 'invalid datagram does not create a connection');

my @client = map {
    Net::QUIC::Endpoint->client(
        local       => $_,
        peer        => $server_local,
        alpn        => $alpn,
        server_name => 'localhost',
        ca_file     => $cert_file,
    )
} @client_local;

my %client_for_peer = map {
    $client_local[$_] => $client[$_]
} 0 .. $#client;

sub pump_all {
    my $progress = 0;

    while (my $datagram = $server->next_datagram) {
        ++$progress;

        my $client = $client_for_peer{$datagram->peer};
        die "server produced datagram for unknown client"
            if !defined $client;

        $client->receive_datagram(
            $datagram->data,
            $datagram->peer,
            $server_local,
        );
    }

    for my $i (0 .. $#client) {
        while (my $datagram = $client[$i]->next_datagram) {
            ++$progress;
            $server->receive_datagram(
                $datagram->data,
                $server_local,
                $client_local[$i],
            );
        }
    }

    my @timeouts;
    my $server_after = $server->timeout_after;
    push @timeouts, [$server_after, sub { $server->handle_timeout }]
        if defined $server_after;

    for my $client (@client) {
        my $after = $client->timeout_after;
        push @timeouts, [$after, sub { $client->handle_timeout }]
            if defined $after;
    }

    for my $timer (@timeouts) {
        if ($timer->[0] <= 0) {
            ++$progress;
            $timer->[1]->();
        }
    }

    if (!$progress) {
        my @positive = sort { $a <=> $b }
            map { $_->[0] }
            grep { $_->[0] > 0 } @timeouts;

        if (@positive) {
            my $nap = $positive[0] > 0.01 ? 0.01 : $positive[0] + 0.001;
            sleep($nap);
            ++$progress;

            $server_after = $server->timeout_after;
            $server->handle_timeout
                if defined($server_after) && $server_after <= 0;

            for my $client (@client) {
                my $after = $client->timeout_after;
                $client->handle_timeout
                    if defined($after) && $after <= 0;
            }
        }
    }

    return $progress;
}

for my $i (0 .. $#client) {
    my $initial = $client[$i]->next_datagram;
    ok(defined($initial), "client $i produces Initial");

    $server->receive_datagram(
        $initial->data,
        $server_local,
        $client_local[$i],
    );
}

my @accepted;
while (my $connection = $server->next_connection) {
    push @accepted, $connection;
}

is(scalar(@accepted), 2, 'one server Endpoint accepts two connections');

for (1 .. 500) {
    last if $client[0]->connection->ready
        && $client[1]->connection->ready
        && $accepted[0]->ready
        && $accepted[1]->ready;

    last if !pump_all();
}

ok($client[0]->connection->ready, 'first client handshake completes');
ok($client[1]->connection->ready, 'second client handshake completes');
ok($accepted[0]->ready, 'first server connection handshake completes');
ok($accepted[1]->ready, 'second server connection handshake completes');

my @payload = (
    "first-client-stream\n" . ("A" x 5000),
    "second-client-stream\n" . ("B" x 7000),
);
my @client_stream;

for my $i (0 .. $#client) {
    $client_stream[$i] = $client[$i]->connection->open_bidi_stream;
    $client_stream[$i]->send($payload[$i]);
    $client_stream[$i]->finish;
}

my %received;
my %server_stream;

for (1 .. 500) {
    pump_all();

    for my $connection (@accepted) {
        while (my $stream = $connection->next_stream) {
            $server_stream{$stream->id . ':' . "$connection"} = $stream;
        }

        for my $key (keys %server_stream) {
            next if $key !~ /:\Q$connection\E\z/;
            my $stream = $server_stream{$key};

            while (defined(my $chunk = $stream->next_data)) {
                $received{$key} .= $chunk;
            }
        }
    }

    last if scalar(grep { /first-client-stream/ } values %received)
        && scalar(grep { /second-client-stream/ } values %received);
}

my @bodies = values %received;
ok(
    scalar(grep { $_ eq $payload[0] } @bodies),
    'server routes first client stream to a connection',
);
ok(
    scalar(grep { $_ eq $payload[1] } @bodies),
    'server routes second client stream to a different connection',
);

like(
    dies { $server->connection },
    qr/server endpoint manages multiple connections/,
    'server endpoint does not pretend to have one connection',
);

done_testing;
