use strict;
use warnings;

use FindBin ();
use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;
use Time::HiRes qw(sleep);
use Net::QUIC::Endpoint;

# Standalone QUIC Stream test: no HTTP library or event-loop dependency.
my $server_local = pack_sockaddr_in(4491, inet_aton('127.0.0.1'));
my $client_local = pack_sockaddr_in(4091, inet_aton('127.0.0.1'));
my $alpn = 'net-quic-credit-limited-send';
my $cert_file = "$FindBin::Bin/data/server-cert.pem";
my $key_file = "$FindBin::Bin/data/server-key.pem";

my $server = Net::QUIC::Endpoint->server(
    alpn => $alpn,
    certificate_file => $cert_file,
    private_key_file => $key_file,
    transport => {
        connection_window => 8192,
        stream_window => 1024,
    },
);
my $client = Net::QUIC::Endpoint->client(
    local => $client_local, peer => $server_local, alpn => $alpn,
    server_name => 'localhost', ca_file => $cert_file,
);

sub pump_pair {
    my $progress = 0;
    while (my $d = $server->next_datagram) {
        $progress++;
        $client->receive_datagram(
            $d->data, $client_local, $server_local,
        );
    }
    while (my $d = $client->next_datagram) {
        $progress++;
        $server->receive_datagram(
            $d->data, $server_local, $client_local,
        );
    }
    my $server_after = $server->timeout_after;
    if (defined($server_after) && $server_after <= 0) {
        $server->handle_timeout;
        $progress++;
    }
    my $client_after = $client->timeout_after;
    if (defined($client_after) && $client_after <= 0) {
        $client->handle_timeout;
        $progress++;
    }
    if (!$progress) {
        my @wait = sort { $a <=> $b }
            grep { defined($_) && $_ > 0 }
            ($server_after, $client_after);
        sleep($wait[0] > .01 ? .01 : $wait[0] + .001) if @wait;
    }
}

my $accepted;
for (1 .. 1000) {
    pump_pair();
    $accepted ||= $server->next_connection;
    last if $accepted && $client->connection->ready && $accepted->ready;
}
ok($accepted && $accepted->ready, 'server QUIC handshake ready');
ok($client->connection->ready, 'client QUIC handshake ready');

my $connection = $client->connection;
$connection->send_buffer_limit(2048);
my $capacity_wake_calls = 0;
$connection->on_stream_activity(sub { $capacity_wake_calls++ });
my @tx = map { $connection->open_bidi_stream } 1 .. 3;
my %rx;
my @bytes = ('', '', '');
my $collect = sub {
    while (my $stream = $accepted->next_stream) {
        $rx{$stream->id} = $stream;
    }
    for my $i (0 .. 2) {
        my $stream = $rx{$tx[$i]->id} or next;
        while (my $chunk = $stream->next_data_chunk) {
            $bytes[$i] .= $chunk->[0];
        }
    }
};

is($tx[0]->send_some('A' x 4096, limit_to_credit => 1), 1024,
    'first stream accepts only peer receive credit');
is($tx[1]->send_some('B' x 4096, limit_to_credit => 1), 1024,
    'second stream accepts only its own receive credit');
is($tx[2]->send_some('C' x 4096, limit_to_credit => 1), 0,
    'connection shared buffer still remains a hard cap');
is($connection->send_buffered_bytes, 2048,
    'two streams account for all shared retained bytes');

for (1 .. 1000) {
    pump_pair();
    $collect->();
    last if $bytes[0] eq 'A' x 1024
        && $bytes[1] eq 'B' x 1024
        && $connection->send_buffered_bytes == 0;
}
is($bytes[0], 'A' x 1024, 'first receiver gets exact credited prefix');
is($bytes[1], 'B' x 1024, 'second receiver gets exact credited prefix');
is($connection->send_buffered_bytes, 0, 'ACKs release bounded send memory');
my @capacity_woken;
while (defined(my $id = $connection->next_active_stream_id)) {
    push @capacity_woken, $id;
}
ok(scalar(grep { $_ == $tx[2]->id } @capacity_woken),
    'a Stream with no queued bytes is awakened by a sibling ACK freeing capacity');
ok($capacity_wake_calls > 0, 'shared capacity wake uses the existing activity callback');

is($tx[0]->send_some('D' x 1024, limit_to_credit => 1), 0,
    'consumed send credit is not counted a second time');
is($tx[1]->send_some('E' x 1024, limit_to_credit => 1), 0,
    'second stream cannot queue beyond peer credit in opt-in mode');
is($tx[2]->send_some('C' x 1024, limit_to_credit => 1), 1024,
    'third writable stream is admitted after earlier send ACKs');

for (1 .. 1000) {
    pump_pair();
    $collect->();
    last if $bytes[2] eq 'C' x 1024;
}
is($bytes[2], 'C' x 1024,
    'flow blocked siblings do not prevent independent stream delivery');

my $credit_wakes = 0;
$connection->on_stream_activity(sub { $credit_wakes++ });
while (defined($connection->next_active_stream_id)) {}
$rx{$tx[0]->id}->consume(1024);
my $saw_credit = 0;
for (1 .. 1000) {
    pump_pair();
    while (defined(my $id = $connection->next_active_stream_id)) {
        $saw_credit++ if $id == $tx[0]->id;
    }
    last if $saw_credit;
}
ok($saw_credit, 'peer MAX_STREAM_DATA credit update wakes existing activity API');
is($tx[0]->send_some('D' x 1024, limit_to_credit => 1), 1024,
    'producer resumes when the peer consumes Reader credit');

for (1 .. 1000) {
    pump_pair();
    $collect->();
    last if $bytes[0] eq ('A' x 1024) . ('D' x 1024);
}
is($bytes[0], ('A' x 1024) . ('D' x 1024),
    'credited stream resumes in exact byte order');

# Original default remains intentionally different, even in this connection.
# Wait for the prior credited write to be ACKed so the full hard limit is free.
for (1 .. 1000) {
    pump_pair();
    $collect->();
    last if $connection->send_buffered_bytes == 0;
}
is($connection->send_buffered_bytes, 0, 'prior credited bytes were ACKed');
is($tx[1]->send_some('Z' x 2048), 2048,
    'default send_some still accepts data beyond peer flow credit');
is($connection->send_buffered_bytes >= 2048, 1,
    'uncredited default bytes are retained under the existing contract');

my $reset_waiter = $connection->open_bidi_stream;
is($reset_waiter->send_some('Q' x 128, limit_to_credit => 1), 0,
    'a fourth Stream waits for full shared buffer before reset');
while (defined($connection->next_active_stream_id)) {}
$tx[1]->reset(90);
my @reset_woken;
while (defined(my $id = $connection->next_active_stream_id)) {
    push @reset_woken, $id;
}
ok(scalar(grep { $_ == $reset_waiter->id } @reset_woken),
    'resetting sibling frees memory and wakes the waiting Stream');
is($reset_waiter->send_some('Q' x 128, limit_to_credit => 1), 128,
    'waiting Stream uses capacity released by sibling reset');
$reset_waiter->reset(90);

for my $stream (@tx) {
    $stream->reset(90);
}
done_testing;
