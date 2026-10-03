use strict;
use warnings;

use FindBin ();
use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;
use Time::HiRes qw(sleep);

use Net::QUIC::Endpoint;

my $server_local = pack_sockaddr_in(4475, inet_aton('127.0.0.1'));
my $client_local = pack_sockaddr_in(4075, inet_aton('127.0.0.1'));
my $alpn = 'net-quic-protocol-engine-v2-test';
my $cert_file = "$FindBin::Bin/data/server-cert.pem";
my $key_file = "$FindBin::Bin/data/server-key.pem";

my $server = Net::QUIC::Endpoint->server(
    alpn             => $alpn,
    certificate_file => $cert_file,
    private_key_file => $key_file,
    transport        => {
        connection_window => 64 * 1024,
        stream_window     => 1024,
    },
);

my $client = Net::QUIC::Endpoint->client(
    local       => $client_local,
    peer        => $server_local,
    alpn        => $alpn,
    server_name => 'localhost',
    ca_file     => $cert_file,
    version     => 2,
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

for (1 .. 1200) {
    pump_pair();
    $accepted ||= $server->next_connection;

    last if $accepted
        && $client->connection->ready
        && $accepted->ready;
}

my $connection = $client->connection;

ok($connection->ready, 'QUIC v2 client handshake completes');
ok($accepted && $accepted->ready, 'QUIC v2 server handshake completes');
is($connection->version, 2, 'client negotiated QUIC v2');
is($accepted->version, 2, 'server negotiated QUIC v2');

my $server_wakes = 0;
my $client_wakes = 0;

$accepted->on_stream_activity(sub {
    ++$server_wakes;
});
$connection->on_stream_activity(sub {
    ++$client_wakes;
});

$connection->send_buffer_limit(4096);

my $sender = $connection->open_bidi_stream;
my $payload = join '', map { "v2-protocol-$_\n" } 1 .. 280;

my $accepted_bytes = $sender->send_some($payload);
is($accepted_bytes, 4096, 'QUIC v2 bounded send accepts only configured capacity');
is($connection->send_buffered_bytes, 4096, 'QUIC v2 retained TX accounting reaches its bound');

my $receiver;
my $received = '';
my $delivered = 0;

for (1 .. 1000) {
    pump_pair();

    while (my $stream = $accepted->next_stream) {
        if ($stream->id == $sender->id) {
            $receiver = $stream;
        }
    }

    if ($receiver) {
        while (my $event = $receiver->next_data_chunk) {
            $received .= $event->[0];
            $delivered += length($event->[0]);
        }
    }

    last if $receiver && $delivered >= 1024;
}

isa_ok($receiver, ['Net::QUIC::Stream']);
ok($server_wakes > 0, 'QUIC v2 receive activity wakes protocol engine');
ok($delivered > 0, 'QUIC v2 advanced receive delivers data');
ok($delivered <= 1024, 'QUIC v2 advanced receive withholds flow-control credit');

for (1 .. 50) {
    pump_pair();
}

my $before_consume = length($received);
while (my $event = $receiver->next_data_chunk) {
    $received .= $event->[0];
    $delivered += length($event->[0]);
}
is(
    length($received),
    $before_consume,
    'QUIC v2 does not advance receive window before explicit consumption',
);

$receiver->consume($delivered);

my $remaining = substr($payload, $accepted_bytes);

for (1 .. 1200) {
    pump_pair();

    while (my $event = $receiver->next_data_chunk) {
        $received .= $event->[0];
        $receiver->consume(length($event->[0]));
    }

    while (defined($connection->next_active_stream_id)) {
    }

    last if $connection->send_buffered_bytes == 0;
}

ok($sender->acked_offset > 0, 'QUIC v2 exposes acknowledgement progress');
ok($client_wakes > 0, 'QUIC v2 ACK progress wakes bounded producer');
is($connection->send_buffered_bytes, 0, 'QUIC v2 ACKs release retained TX capacity');

my $second_accept = $sender->send_some($remaining);
is(
    $second_accept,
    length($remaining),
    'QUIC v2 bounded producer resumes after ACK frees capacity',
);
$sender->finish;

for (1 .. 2000) {
    pump_pair();

    while (my $event = $receiver->next_data_chunk) {
        $received .= $event->[0];
        $receiver->consume(length($event->[0]));
    }

    while (defined($connection->next_active_stream_id)) {
    }

    last if $receiver->remote_finished
        && $received eq $payload
        && $connection->send_buffered_bytes == 0;
}

is($received, $payload, 'QUIC v2 advanced API preserves complete byte stream');
ok($receiver->remote_finished, 'QUIC v2 advanced receive preserves FIN');
is($sender->acked_offset, length($payload), 'QUIC v2 ACK offset reaches final byte length');
is($connection->send_buffered_bytes, 0, 'QUIC v2 final ACK releases all retained TX bytes');

done_testing;
