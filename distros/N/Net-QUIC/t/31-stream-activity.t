use strict;
use warnings;

use FindBin ();
use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;
use Time::HiRes qw(sleep);

use Net::QUIC::Endpoint;

my $server_local = pack_sockaddr_in(4472, inet_aton('127.0.0.1'));
my $client_local = pack_sockaddr_in(4072, inet_aton('127.0.0.1'));
my $alpn = 'net-quic-stream-activity-test';
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

my $server_wakes = 0;
my $client_wakes = 0;

$accepted->on_stream_activity(sub {
    ++$server_wakes;
});

$client->connection->on_stream_activity(sub {
    ++$client_wakes;
});

my $sender = $client->connection->open_bidi_stream;
my $first_payload = "activity-one\n" x 8000;
$sender->send($first_payload);

pump_pair();

is($server_wakes, 1, 'many receive events coalesce into one wake-up');

my @active;
while (defined(my $id = $accepted->next_active_stream_id)) {
    push @active, $id;
}

is(
    \@active,
    [$sender->id],
    'one Stream ID represents the coalesced receive activity',
);

my $receiver = $accepted->next_stream;
isa_ok($receiver, ['Net::QUIC::Stream']);
is($receiver->id, $sender->id, 'activity ID matches peer-created Stream');

my $received = '';
while (defined(my $chunk = $receiver->next_data)) {
    $received .= $chunk;
}
ok(length($received) > 0, 'activity wake leads to currently readable data');

for (1 .. 1000) {
    last if $received eq $first_payload;

    pump_pair();

    my @round_active;
    while (defined(my $id = $accepted->next_active_stream_id)) {
        push @round_active, $id;
    }

    ok(
        !@round_active
            || scalar(grep { $_ == $sender->id } @round_active) == 1,
        'each service round coalesces activity for the Stream',
    ) if @round_active;

    while (defined(my $chunk = $receiver->next_data)) {
        $received .= $chunk;
    }
}

is($received, $first_payload, 'repeated wake/service cycles deliver all data');

while (defined($client->connection->next_active_stream_id)) {
}

my $second_payload = "activity-two\n";
my $server_wake_before_second = $server_wakes;
$sender->send($second_payload);

for (1 .. 500) {
    pump_pair();
    last if $server_wakes > $server_wake_before_second;
}

ok(
    $server_wakes > $server_wake_before_second,
    'new activity wakes again after the queue was drained',
);
is(
    $accepted->next_active_stream_id,
    $sender->id,
    'same Stream can become active again later',
);
ok(
    !defined($accepted->next_active_stream_id),
    'activity queue is empty after draining the repeated event',
);

while (defined(my $chunk = $receiver->next_data)) {
    $received .= $chunk;
}
is(
    $received,
    $first_payload . $second_payload,
    'repeated activity does not disturb Stream byte order',
);

while (defined($client->connection->next_active_stream_id)) {
}

my $ack_sender = $client->connection->open_bidi_stream;
my $ack_id = $ack_sender->id;
my $ack_payload = "ack-activity\n" x 400;
my $client_wake_before_ack = $client_wakes;

$ack_sender->send($ack_payload);

my $ack_receiver;
for (1 .. 1000) {
    pump_pair();

    while (my $stream = $accepted->next_stream) {
        if ($stream->id == $ack_id) {
            $ack_receiver = $stream;
        }
    }

    if ($ack_receiver) {
        while (defined($ack_receiver->next_data)) {
        }
    }

    last if $client_wakes > $client_wake_before_ack
        && $ack_sender->acked_offset > 0;
}

ok(
    $client_wakes > $client_wake_before_ack,
    'transmit acknowledgement progress wakes the sending connection',
);

my @client_active;
while (defined(my $id = $client->connection->next_active_stream_id)) {
    push @client_active, $id;
}
ok(
    scalar(grep { $_ == $ack_id } @client_active),
    'ACK progress marks the sending Stream active',
);
ok($ack_sender->acked_offset > 0, 'ACK wake exposes acknowledgement progress');

while (defined($client->connection->next_active_stream_id)) {
}

my $client_wake_before_stop = $client_wakes;
$receiver->stop_sending(55);

for (1 .. 500) {
    pump_pair();
    last if defined($sender->remote_stop_sending_code);
}

is(
    $sender->remote_stop_sending_code,
    55,
    'STOP_SENDING state reaches the sending Stream',
);
ok(
    $client_wakes > $client_wake_before_stop,
    'STOP_SENDING generates Stream activity',
);

my @stop_active;
while (defined(my $id = $client->connection->next_active_stream_id)) {
    push @stop_active, $id;
}
ok(
    scalar(grep { $_ == $sender->id } @stop_active),
    'STOP_SENDING activity identifies the affected Stream',
);

while (defined($accepted->next_active_stream_id)) {
}

my $reset_sender = $client->connection->open_bidi_stream;
my $reset_id = $reset_sender->id;
my $server_wake_before_reset = $server_wakes;

$reset_sender->reset(77);

my $reset_receiver;
for (1 .. 500) {
    pump_pair();

    while (my $stream = $accepted->next_stream) {
        if ($stream->id == $reset_id) {
            $reset_receiver = $stream;
        }
    }

    last if $reset_receiver
        && defined($reset_receiver->remote_reset_code);
}

isa_ok($reset_receiver, ['Net::QUIC::Stream']);
is($reset_receiver->remote_reset_code, 77, 'RESET_STREAM state is retained');
ok(
    $server_wakes > $server_wake_before_reset,
    'RESET_STREAM generates Stream activity',
);

my @reset_active;
while (defined(my $id = $accepted->next_active_stream_id)) {
    push @reset_active, $id;
}
ok(
    scalar(grep { $_ == $reset_id } @reset_active),
    'RESET_STREAM activity identifies the affected Stream',
);

my $wake_before_disable = $server_wakes;
$accepted->on_stream_activity(undef);

my $disabled_sender = $client->connection->open_bidi_stream;
$disabled_sender->send("tracking-disabled\n");

for (1 .. 100) {
    pump_pair();
}

is(
    $server_wakes,
    $wake_before_disable,
    'disabling activity tracking stops wake-up callbacks',
);
ok(
    !defined($accepted->next_active_stream_id),
    'disabled activity tracking does not retain pending Stream IDs',
);

done_testing;
