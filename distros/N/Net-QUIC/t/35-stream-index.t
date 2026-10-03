use strict;
use warnings;

use FindBin ();
use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;
use Time::HiRes qw(sleep);

use Net::QUIC::Endpoint;

my $server_local = pack_sockaddr_in(4476, inet_aton('127.0.0.1'));
my $client_local = pack_sockaddr_in(4076, inet_aton('127.0.0.1'));
my $alpn = 'net-quic-stream-index-test';
my $cert_file = "$FindBin::Bin/data/server-cert.pem";
my $key_file = "$FindBin::Bin/data/server-key.pem";

my $server = Net::QUIC::Endpoint->server(
    alpn             => $alpn,
    certificate_file => $cert_file,
    private_key_file => $key_file,
    transport        => {
        max_bidi_streams => 2500,
        max_uni_streams  => 2500,
    },
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

my $accepted;

for (1 .. 1000) {
    pump_pair();
    $accepted ||= $server->next_connection;

    last if $accepted
        && $client->connection->ready
        && $accepted->ready;
}

ok($client->connection->ready, 'client handshake completes');
ok($accepted && $accepted->ready, 'server handshake completes');

my @streams;
for (1 .. 2000) {
    push @streams, $client->connection->open_bidi_stream;
}

is(
    $client->connection->_stream_state_count,
    2000,
    'two thousand local Stream states are present',
);

for my $index (0, 499, 999, 1499, 1999) {
    is(
        $streams[$index]->acked_offset,
        0,
        "indexed lookup finds Stream $index",
    );
}

$streams[1999]->send("indexed-tail\n");
$streams[1999]->finish;

my $incoming;
my $data = '';

for (1 .. 1000) {
    pump_pair();

    while (my $stream = $accepted->next_stream) {
        if ($stream->id == $streams[1999]->id) {
            $incoming = $stream;
        }
    }

    if ($incoming) {
        while (defined(my $chunk = $incoming->next_data)) {
            $data .= $chunk;
        }
    }

    last if $data eq "indexed-tail\n"
        && $streams[1999]->acked_offset == length("indexed-tail\n");
}

isa_ok($incoming, ['Net::QUIC::Stream']);
is($data, "indexed-tail\n", 'remote lookup finds a high Stream ID');
is(
    $streams[1999]->acked_offset,
    length("indexed-tail\n"),
    'ACK callback resolves the high Stream ID correctly',
);

for my $index (0, 499, 999, 1499) {
    $streams[$index]->reset(10 + $index);
}

for (1 .. 100) {
    pump_pair();
}

for my $index (0, 499, 999, 1499, 1999) {
    ok(
        !dies { $streams[$index]->closed },
        "Stream $index remains addressable after index removals and transport progress",
    );
}

done_testing;
