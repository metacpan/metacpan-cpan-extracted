use strict;
use warnings;

use FindBin ();
use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;
use Time::HiRes qw(sleep);

use Net::QUIC::Endpoint;

my $server_local = pack_sockaddr_in(4471, inet_aton('127.0.0.1'));
my $client_local = pack_sockaddr_in(4071, inet_aton('127.0.0.1'));
my $alpn = 'net-quic-acked-offset-test';
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

my $sender = $client->connection->open_bidi_stream;
my $payload = join '', map { "ack-progress-$_\n" } 1 .. 9000;

is($sender->acked_offset, 0, 'acknowledgement offset starts at zero');

$sender->send($payload);
$sender->finish;

my $receiver;
my $received = '';
my $previous = 0;
my $monotonic = 1;
my $saw_progress = 0;

for (1 .. 3000) {
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

    my $current = $sender->acked_offset;
    $monotonic = 0 if $current < $previous;
    $saw_progress = 1 if $current > 0;
    $previous = $current;

    last if $current == length($payload)
        && $received eq $payload;
}

ok($saw_progress, 'acknowledgement offset advances after peer ACKs data');
ok($monotonic, 'acknowledgement offset never moves backward');
is(
    $sender->acked_offset,
    length($payload),
    'acked_offset reaches the complete transmitted byte length',
);
is($received, $payload, 'peer receives the complete acknowledged payload');

done_testing;
