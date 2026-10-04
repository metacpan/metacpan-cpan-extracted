use strict;
use warnings;

use FindBin ();
use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;
use Time::HiRes qw(sleep);

use Net::QUIC::Endpoint;

my $server_local = pack_sockaddr_in(4474, inet_aton('127.0.0.1'));
my $client_local = pack_sockaddr_in(4074, inet_aton('127.0.0.1'));
my $alpn = 'net-quic-rx-reclaim-credit-test';
my $cert_file = "$FindBin::Bin/data/server-cert.pem";
my $key_file = "$FindBin::Bin/data/server-key.pem";

my $server = Net::QUIC::Endpoint->server(
    alpn             => $alpn,
    certificate_file => $cert_file,
    private_key_file => $key_file,
    transport        => {
        connection_window => 1024,
        stream_window     => 1024,
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

my $first_sender = $client->connection->open_uni_stream;
my $first_payload = 'A' x 1024;
$first_sender->send($first_payload);
$first_sender->finish;

my $first_receiver;
for (1 .. 1000) {
    pump_pair();

    $first_receiver ||= $accepted->next_stream;

    last if $first_receiver
        && $first_receiver->remote_finished
        && $first_receiver->closed;
}

isa_ok($first_receiver, ['Net::QUIC::Stream']);
ok($first_receiver->remote_finished, 'first unidirectional Stream receives FIN');
ok($first_receiver->closed, 'first unidirectional Stream is transport-closed');

my $held = '';
while (my $event = $first_receiver->next_data_chunk) {
    $held .= $event->[0];
}

is($held, $first_payload, 'first Stream data is delivered without consuming credit');

my $state_before_drop = $accepted->_stream_state_count;
undef $first_receiver;

is(
    $accepted->_stream_state_count,
    $state_before_drop - 1,
    'dropping the closed Stream reclaims its native state',
);

for (1 .. 20) {
    pump_pair();
}

my $second_sender = $client->connection->open_uni_stream;
my $second_payload = 'B' x 1024;
$second_sender->send($second_payload);
$second_sender->finish;

my $second_receiver;
my $second_data = '';

for (1 .. 1000) {
    pump_pair();

    while (my $stream = $accepted->next_stream) {
        if ($stream->id == $second_sender->id) {
            $second_receiver = $stream;
        }
    }

    if ($second_receiver) {
        while (defined(my $chunk = $second_receiver->next_data)) {
            $second_data .= $chunk;
        }
    }

    last if $second_data eq $second_payload;
}

isa_ok($second_receiver, ['Net::QUIC::Stream']);
is(
    $second_data,
    $second_payload,
    'discarding unconsumed data from a dropped closed Stream restores connection credit',
);

undef $second_receiver;

my $third_sender = $client->connection->open_uni_stream;
my $third_payload = 'C' x 1024;
$third_sender->send($third_payload);

my $third_receiver;
my $third_held = '';

for (1 .. 1000) {
    pump_pair();

    $third_receiver ||= $accepted->next_stream;

    if ($third_receiver) {
        while (my $event = $third_receiver->next_data_chunk) {
            $third_held .= $event->[0];
        }
    }

    last if $third_held eq $third_payload;
}

isa_ok($third_receiver, ['Net::QUIC::Stream']);
is(
    $third_held,
    $third_payload,
    'third Stream data is delivered explicitly before FIN',
);
ok(
    !$third_receiver->closed,
    'third Stream remains open while explicit receive bytes are unconsumed',
);

my $third_state_before_drop = $accepted->_stream_state_count;
undef $third_receiver;

is(
    $accepted->_stream_state_count,
    $third_state_before_drop,
    'dropping an open Stream leaves its native state until transport close',
);

$third_sender->finish;

for (1 .. 1000) {
    pump_pair();
    last if $accepted->_stream_state_count < $third_state_before_drop;
}

cmp_ok(
    $accepted->_stream_state_count,
    '<',
    $third_state_before_drop,
    'native Stream is reclaimed after FIN arrives without a Perl Stream object',
);

for (1 .. 20) {
    pump_pair();
}

my $fourth_sender = $client->connection->open_uni_stream;
my $fourth_payload = 'D' x 1024;
$fourth_sender->send($fourth_payload);
$fourth_sender->finish;

my $fourth_receiver;
my $fourth_data = '';

for (1 .. 1000) {
    pump_pair();

    while (my $stream = $accepted->next_stream) {
        if ($stream->id == $fourth_sender->id) {
            $fourth_receiver = $stream;
        }
    }

    if ($fourth_receiver) {
        while (defined(my $chunk = $fourth_receiver->next_data)) {
            $fourth_data .= $chunk;
        }
    }

    last if $fourth_data eq $fourth_payload;
}

isa_ok($fourth_receiver, ['Net::QUIC::Stream']);
is(
    $fourth_data,
    $fourth_payload,
    'deferred reclamation restores connection credit for the next Stream',
);

done_testing;
