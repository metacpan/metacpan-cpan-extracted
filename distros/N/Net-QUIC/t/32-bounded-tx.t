use strict;
use warnings;

use FindBin ();
use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;
use Time::HiRes qw(sleep);

use Net::QUIC::Endpoint;

my $server_local = pack_sockaddr_in(4473, inet_aton('127.0.0.1'));
my $client_local = pack_sockaddr_in(4073, inet_aton('127.0.0.1'));
my $alpn = 'net-quic-bounded-tx-test';
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

my $connection = $client->connection;

ok($connection->ready, 'client handshake completes');
ok($accepted && $accepted->ready, 'server handshake completes');
ok(!defined($connection->send_buffer_limit), 'bounded transmit starts disabled');
is($connection->send_buffered_bytes, 0, 'connection starts with no retained TX bytes');

$connection->send_buffer_limit(4096);
is($connection->send_buffer_limit, 4096, 'connection send buffer limit is configurable');

my $sender = $connection->open_bidi_stream;

$sender->send('A' x 1024);
is($sender->send_buffered_bytes, 1024, 'ordinary send is included in retained TX accounting');
is($connection->send_buffered_bytes, 1024, 'connection retained TX accounting includes Stream data');

like(
    dies { $sender->send('B' x 3073) },
    qr/QUIC send buffer limit exceeded/,
    'ordinary send cannot exceed an explicitly enabled bound',
);
is($connection->send_buffered_bytes, 1024, 'rejected ordinary send changes no accounting');

my $accepted_bytes = $sender->send_some('B' x 5000);
is($accepted_bytes, 3072, 'send_some accepts only the remaining connection capacity');
is($sender->send_buffered_bytes, 4096, 'Stream retained bytes reach the configured limit');
is($connection->send_buffered_bytes, 4096, 'connection retained bytes reach the configured limit');
is($sender->send_some('C' x 100), 0, 'send_some returns zero while the buffer is full');
ok(
    $connection->send_buffered_bytes > 1024,
    'bounded producer can retain data beyond the peer stream flow-control window',
);

my $client_wakes = 0;
$connection->on_stream_activity(sub {
    ++$client_wakes;
});

my $receiver;
my $received = '';

for (1 .. 1000) {
    pump_pair();

    while (my $stream = $accepted->next_stream) {
        if ($stream->id == $sender->id) {
            $receiver = $stream;
        }
    }

    if ($receiver) {
        while (defined(my $chunk = $receiver->next_data)) {
            $received .= $chunk;
        }
    }

    last if $connection->send_buffered_bytes == 0
        && $client_wakes;
}

isa_ok($receiver, ['Net::QUIC::Stream']);
ok($client_wakes > 0, 'ACK progress wakes a bounded producer');
is($connection->send_buffered_bytes, 0, 'peer ACK releases retained connection bytes');
is($sender->send_buffered_bytes, 0, 'peer ACK releases retained Stream bytes');
is($received, ('A' x 1024) . ('B' x 3072), 'peer receives exactly the accepted prefix');

while (defined($connection->next_active_stream_id)) {
}

my $remaining = 5000 - $accepted_bytes;
is(
    $sender->send_some('B' x $remaining),
    $remaining,
    'producer can resume after ACK releases capacity',
);
$sender->finish;

for (1 .. 1000) {
    pump_pair();

    while (defined(my $chunk = $receiver->next_data)) {
        $received .= $chunk;
    }

    while (defined($connection->next_active_stream_id)) {
    }

    last if $connection->send_buffered_bytes == 0
        && $receiver->remote_finished;
}

is(
    $received,
    ('A' x 1024) . ('B' x 5000),
    'resumed producer completes the byte stream',
);
ok($receiver->remote_finished, 'bounded transmit preserves FIN');
is($connection->send_buffered_bytes, 0, 'completed bounded transfer releases all retained bytes');

my $first = $connection->open_bidi_stream;
my $second = $connection->open_bidi_stream;

is($first->send_some('D' x 3000), 3000, 'first Stream consumes shared connection capacity');
is($second->send_some('E' x 3000), 1096, 'second Stream is limited by remaining shared capacity');
is($first->send_buffered_bytes, 3000, 'first Stream reports its own retained bytes');
is($second->send_buffered_bytes, 1096, 'second Stream reports its own retained bytes');
is($connection->send_buffered_bytes, 4096, 'multiple Streams share one hard connection limit');

$first->reset(90);
is($first->send_buffered_bytes, 0, 'local reset releases retained Stream bytes immediately');
is($connection->send_buffered_bytes, 1096, 'local reset returns capacity to the Connection');
is($second->send_some('F' x 4000), 3000, 'another Stream can reuse capacity released by reset');
is($connection->send_buffered_bytes, 4096, 'reused capacity remains bounded');

$second->reset(91);
is($connection->send_buffered_bytes, 0, 'resetting remaining Stream clears shared accounting');

my $stop_sender = $connection->open_bidi_stream;
is($stop_sender->send_some('G' x 3000), 3000, 'STOP_SENDING test queues bounded data');

pump_pair();

my $stop_receiver;
while (my $stream = $accepted->next_stream) {
    if ($stream->id == $stop_sender->id) {
        $stop_receiver = $stream;
    }
}
isa_ok($stop_receiver, ['Net::QUIC::Stream']);
ok($connection->send_buffered_bytes > 0, 'unacknowledged data is retained before STOP_SENDING');

$stop_receiver->stop_sending(92);

for (1 .. 500) {
    pump_pair();
    last if defined($stop_sender->remote_stop_sending_code);
}

is($stop_sender->remote_stop_sending_code, 92, 'peer STOP_SENDING reaches bounded sender');
is($stop_sender->send_buffered_bytes, 0, 'STOP_SENDING discards retained Stream bytes');
is($connection->send_buffered_bytes, 0, 'STOP_SENDING returns discarded capacity to Connection');

$connection->send_buffer_limit(undef);
ok(!defined($connection->send_buffer_limit), 'bounded transmit can be disabled');

like(
    dies { $stop_sender->send_some('H') },
    qr/send_some requires a configured connection send_buffer_limit/,
    'send_some requires an explicit bound',
);

my $unbounded = $connection->open_bidi_stream;
$unbounded->send('I' x 5000);
is(
    $connection->send_buffered_bytes,
    5000,
    'ordinary send keeps original unbounded behavior when no limit is configured',
);

like(
    dies { $connection->send_buffer_limit(4096) },
    qr/send buffer limit cannot be smaller than currently buffered data/,
    'a new bound cannot be set below already retained data',
);
ok(!defined($connection->send_buffer_limit), 'failed limit change leaves bounded mode disabled');

$unbounded->reset(93);
is($connection->send_buffered_bytes, 0, 'reset clears unbounded data from accounting too');

$connection->send_buffer_limit(0);
is($connection->send_buffer_limit, 0, 'zero is a valid hard buffer limit');
is($connection->open_bidi_stream->send_some('J'), 0, 'zero limit accepts no bytes');

done_testing;
