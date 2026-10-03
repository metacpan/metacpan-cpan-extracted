use strict;
use warnings;

use FindBin ();
use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;
use Time::HiRes qw(sleep);

use Net::QUIC::Endpoint;

my $server_local = pack_sockaddr_in(4470, inet_aton('127.0.0.1'));
my $client_local = pack_sockaddr_in(4070, inet_aton('127.0.0.1'));
my $alpn = 'net-quic-protocol-rx-test';
my $cert_file = "$FindBin::Bin/data/server-cert.pem";
my $key_file = "$FindBin::Bin/data/server-key.pem";

my $server = Net::QUIC::Endpoint->server(
    alpn             => $alpn,
    certificate_file => $cert_file,
    private_key_file => $key_file,
    transport        => {
        connection_window => 64 * 1024,
        stream_window     => 2048,
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

my $sender = $client->connection->open_bidi_stream;
my $payload = join '', map { "explicit-rx-$_\n" } 1 .. 700;

$sender->send($payload);
$sender->finish;

my $receiver;
my @held;
my $held_bytes = 0;

for (1 .. 500) {
    pump_pair();
    $receiver ||= $accepted->next_stream;

    if ($receiver) {
        while (my $event = $receiver->next_data_chunk) {
            push @held, $event;
            $held_bytes += length($event->[0]);
        }
    }

    last if $receiver && $held_bytes >= 2048;
}

isa_ok($receiver, ['Net::QUIC::Stream']);
ok($held_bytes > 0, 'advanced receive delivers bytes');
ok(
    $held_bytes < length($payload),
    'sender is flow-control blocked before the whole payload arrives',
);
ok(
    $held_bytes <= 2048,
    'advanced receive does not silently extend the configured stream window',
);

like(
    dies { $receiver->next_data },
    qr/cannot use next_data after explicit QUIC stream receive consumption/,
    'ordinary receive cannot be mixed after advanced receive starts',
);

my $unexpected = 0;
for (1 .. 100) {
    pump_pair();

    while (my $event = $receiver->next_data_chunk) {
        $unexpected += length($event->[0]);
        push @held, $event;
    }
}
is(
    $unexpected,
    0,
    'taking advanced receive chunks does not return flow-control credit',
);

ok(
    !dies { $receiver->consume(0) },
    'zero-byte explicit consumption is valid',
);

for (1 .. 50) {
    pump_pair();
}
ok(
    !defined($receiver->next_data_chunk),
    'zero-byte consumption does not release more receive credit',
);

my $first_consume = int($held_bytes / 2);
$receiver->consume($first_consume);

like(
    dies {
        $receiver->consume(
            $held_bytes - $first_consume + 1
        );
    },
    qr/cannot consume more QUIC stream data than has been delivered/,
    'explicit consumption cannot exceed delivered unconsumed bytes',
);

$receiver->consume($held_bytes - $first_consume);

my $received = join '', map { $_->[0] } @held;
my $saw_fin = grep { $_->[1] } @held;

for (1 .. 1000) {
    pump_pair();

    while (my $event = $receiver->next_data_chunk) {
        $received .= $event->[0];
        $saw_fin ||= $event->[1];
        $receiver->consume(length($event->[0]));
    }

    last if $saw_fin && $received eq $payload;
}

is($received, $payload, 'explicit consumption releases credit and transfer resumes');
ok($saw_fin, 'advanced receive preserves FIN');
ok($receiver->remote_finished, 'remote_finished remains correct in explicit mode');

my $ordinary_sender = $client->connection->open_bidi_stream;
$ordinary_sender->send("ordinary-mode\n");
$ordinary_sender->finish;

my $ordinary_receiver;
my $ordinary_data;

for (1 .. 500) {
    pump_pair();

    while (my $stream = $accepted->next_stream) {
        if ($stream->id == $ordinary_sender->id) {
            $ordinary_receiver = $stream;
        }
    }

    if ($ordinary_receiver && !defined $ordinary_data) {
        $ordinary_data = $ordinary_receiver->next_data;
    }

    last if defined $ordinary_data;
}

is($ordinary_data, "ordinary-mode\n", 'ordinary next_data behavior still works');
like(
    dies { $ordinary_receiver->next_data_chunk },
    qr/cannot use next_data_chunk after automatic QUIC stream receive consumption/,
    'advanced receive cannot be mixed after ordinary receive starts',
);

my $fin_sender = $client->connection->open_bidi_stream;
my $fin_payload = "fin-with-partial-consumption\n";
$fin_sender->send($fin_payload);
$fin_sender->finish;

my $fin_receiver;
my $fin_data = '';
my $fin_seen = 0;

for (1 .. 500) {
    pump_pair();

    while (my $stream = $accepted->next_stream) {
        if ($stream->id == $fin_sender->id) {
            $fin_receiver = $stream;
        }
    }

    if ($fin_receiver) {
        while (my $event = $fin_receiver->next_data_chunk) {
            $fin_data .= $event->[0];
            $fin_seen ||= $event->[1];
        }
    }

    last if $fin_seen;
}

is($fin_data, $fin_payload, 'FIN stream data is delivered completely');
ok($fin_seen, 'FIN is represented on the advanced receive path');

$fin_receiver->consume(1);
ok(
    $fin_receiver->remote_finished,
    'FIN state remains visible while delivered bytes are only partly consumed',
);
$fin_receiver->consume(length($fin_payload) - 1);

my $reset_sender = $client->connection->open_bidi_stream;
my $reset_payload = "buffered-before-reset\n" x 40;
$reset_sender->send($reset_payload);

my $reset_receiver;
for (1 .. 100) {
    pump_pair();

    while (my $stream = $accepted->next_stream) {
        if ($stream->id == $reset_sender->id) {
            $reset_receiver = $stream;
        }
    }

    last if $reset_receiver;
}

isa_ok($reset_receiver, ['Net::QUIC::Stream']);

for (1 .. 20) {
    pump_pair();
}

$reset_sender->reset(66);

for (1 .. 500) {
    pump_pair();
    last if defined($reset_receiver->remote_reset_code);
}

is(
    $reset_receiver->remote_reset_code,
    66,
    'remote reset state is visible while receive data remains buffered',
);

my $reset_data = '';
my $reset_delivered = 0;
while (my $event = $reset_receiver->next_data_chunk) {
    $reset_data .= $event->[0];
    $reset_delivered += length($event->[0]);
}

is(
    $reset_data,
    $reset_payload,
    'data buffered before RESET_STREAM remains available to the protocol engine',
);
ok(
    !dies { $reset_receiver->consume($reset_delivered) },
    'explicit receive credit can be returned after RESET_STREAM',
);

done_testing;
