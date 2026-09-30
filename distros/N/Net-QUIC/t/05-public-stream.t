use strict;
use warnings;

use FindBin ();
use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;
use Time::HiRes qw(sleep);

use Net::QUIC::Connection;
use Net::QUIC::Endpoint;
use Net::QUIC::Stream;

my $client_local = pack_sockaddr_in(40002, inet_aton('127.0.0.1'));
my $server_local = pack_sockaddr_in(4435, inet_aton('127.0.0.1'));
my $alpn = 'net-quic-public-stream-test';
my $cert_file = "$FindBin::Bin/data/server-cert.pem";
my $key_file = "$FindBin::Bin/data/server-key.pem";

my $server_tls = Net::QUIC::_ServerTLS->_new($cert_file, $key_file);

sub pump_pair {
    my ($client, $server) = @_;
    my $progress = 0;

    while (my $datagram = $server->_next_datagram) {
        ++$progress;
        $client->receive_datagram(
            $datagram->data,
            $client_local,
            $server_local,
        );
    }

    while (my $datagram = $client->next_datagram) {
        ++$progress;
        $server->_receive_datagram(
            $datagram->data,
            $server_local,
            $client_local,
        );
    }

    my $client_after = $client->timeout_after;
    if (defined($client_after) && $client_after <= 0) {
        ++$progress;
        $client->handle_timeout;
    }

    my $server_after = $server->_timeout_after;
    if (defined($server_after) && $server_after <= 0) {
        ++$progress;
        $server->_handle_timeout;
    }

    if (!$progress) {
        my $wait;

        for my $after ($client_after, $server_after) {
            next if !defined($after) || $after <= 0;
            $wait = $after if !defined($wait) || $after < $wait;
        }

        if (defined $wait) {
            my $nap = $wait > 0.01 ? 0.01 : $wait + 0.001;
            sleep($nap);
            ++$progress;

            $client_after = $client->timeout_after;
            if (defined($client_after) && $client_after <= 0) {
                ++$progress;
                $client->handle_timeout;
            }

            $server_after = $server->_timeout_after;
            if (defined($server_after) && $server_after <= 0) {
                ++$progress;
                $server->_handle_timeout;
            }
        }
    }

    return $progress;
}

my $client = Net::QUIC::Endpoint->client(
    local       => $client_local,
    peer        => $server_local,
    alpn        => $alpn,
    server_name => 'localhost',
    ca_file     => $cert_file,
);

my $initial = $client->next_datagram;
ok(defined($initial), 'client produces Initial for public stream test');

my $server = Net::QUIC::Connection->_server_new(
    $initial->data,
    $server_local,
    $client_local,
    $alpn,
    $server_tls,
);

$server->_receive_datagram(
    $initial->data,
    $server_local,
    $client_local,
);

for (1 .. 100) {
    last if $client->connection->ready && $server->ready;
    last if !pump_pair($client, $server);
}

ok($client->connection->ready, 'client handshake is ready');
ok($server->ready, 'server handshake is ready');

my $client_stream = $client->connection->open_bidi_stream;
isa_ok($client_stream, ['Net::QUIC::Stream']);
ok($client_stream->local_initiated, 'client stream is locally initiated');
ok($client_stream->bidirectional, 'client stream is bidirectional');
ok($client_stream->can_send, 'client bidi stream can send');
ok($client_stream->can_receive, 'client bidi stream can receive');

my $request = join '', map { "public-request-$_\n" } 1 .. 900;
$client_stream->send($request);
$client_stream->finish;

my $server_stream;
my $server_received = '';
for (1 .. 300) {
    pump_pair($client, $server);
    $server_stream ||= $server->next_stream;

    if ($server_stream) {
        while (defined(my $chunk = $server_stream->next_data)) {
            $server_received .= $chunk;
        }
    }

    last if $server_stream
        && $server_stream->remote_finished
        && $server_received eq $request;
}

isa_ok($server_stream, ['Net::QUIC::Stream']);
is($server_stream->id, $client_stream->id, 'peer sees the same stream ID');
ok(!$server_stream->local_initiated, 'server sees a remote stream');
ok($server_stream->bidirectional, 'server sees a bidirectional stream');
is($server_received, $request, 'public stream receives the full request');
ok($server_stream->remote_finished, 'public stream reports peer FIN');

my $response = "public-stream-response\n";
$server_stream->send($response);
$server_stream->finish;

my $client_received = '';
for (1 .. 200) {
    pump_pair($client, $server);

    while (defined(my $chunk = $client_stream->next_data)) {
        $client_received .= $chunk;
    }

    last if $client_stream->remote_finished
        && $client_received eq $response;
}

is($client_received, $response, 'public stream sends a response');
ok($client_stream->remote_finished, 'client sees response FIN');

my @client_multi = map { $client->connection->open_bidi_stream } 1 .. 2;
my @payload = (
    ("A" x 9000) . "\n",
    ("B" x 7000) . "\n",
);

for my $i (0 .. $#client_multi) {
    $client_multi[$i]->send($payload[$i]);
    $client_multi[$i]->finish;
}

my %server_multi;
my %multi_received;
for (1 .. 400) {
    pump_pair($client, $server);

    while (my $stream = $server->next_stream) {
        $server_multi{$stream->id} = $stream;
    }

    for my $id (keys %server_multi) {
        while (defined(my $chunk = $server_multi{$id}->next_data)) {
            $multi_received{$id} .= $chunk;
        }
    }

    my $done = 1;
    for my $i (0 .. $#client_multi) {
        my $id = $client_multi[$i]->id;
        $done = 0 if !exists $server_multi{$id};
        $done = 0 if ($multi_received{$id} // '') ne $payload[$i];
        $done = 0 if exists($server_multi{$id})
            && !$server_multi{$id}->remote_finished;
    }
    last if $done;
}

for my $i (0 .. $#client_multi) {
    my $id = $client_multi[$i]->id;
    ok(exists($server_multi{$id}), "peer discovers concurrent stream $i");
    is($multi_received{$id}, $payload[$i], "concurrent stream $i data is intact");
    ok($server_multi{$id}->remote_finished, "concurrent stream $i receives FIN");
}

my $client_uni = $client->connection->open_uni_stream;
ok(!$client_uni->bidirectional, 'local unidirectional stream is marked uni');
ok($client_uni->can_send, 'local unidirectional stream can send');
ok(!$client_uni->can_receive, 'local unidirectional stream cannot receive');

$client_uni->send("one-way\n");
$client_uni->finish;

my $server_uni;
my $uni_received = '';
for (1 .. 200) {
    pump_pair($client, $server);

    while (my $stream = $server->next_stream) {
        if ($stream->id == $client_uni->id) {
            $server_uni = $stream;
        }
    }

    if ($server_uni) {
        while (defined(my $chunk = $server_uni->next_data)) {
            $uni_received .= $chunk;
        }
    }

    last if $server_uni
        && $server_uni->remote_finished
        && $uni_received eq "one-way\n";
}

isa_ok($server_uni, ['Net::QUIC::Stream']);
ok(!$server_uni->local_initiated, 'received unidirectional stream is remote');
ok(!$server_uni->bidirectional, 'received stream remains unidirectional');
ok(!$server_uni->can_send, 'received unidirectional stream cannot send');
ok($server_uni->can_receive, 'received unidirectional stream can receive');
is($uni_received, "one-way\n", 'unidirectional data is delivered');
like(
    dies { $server_uni->send('not allowed') },
    qr/cannot send on this unidirectional QUIC stream/,
    'send is rejected on receive-only unidirectional stream',
);

my $reset_client = $client->connection->open_bidi_stream;
my $reset_id = $reset_client->id;
ok(!defined($reset_client->local_reset_code), 'local reset code starts undefined');
$reset_client->reset(77);
is($reset_client->local_reset_code, 77, 'local stream reset code is retained');

my $reset_server;
for (1 .. 200) {
    pump_pair($client, $server);

    while (my $stream = $server->next_stream) {
        if ($stream->id == $reset_id) {
            $reset_server = $stream;
        }
    }

    last if $reset_server
        && defined $reset_server->remote_reset_code;
}

isa_ok($reset_server, ['Net::QUIC::Stream']);
is($reset_server->remote_reset_code, 77, 'peer receives stream reset error code');
ok(!defined($reset_server->local_reset_code), 'peer stream was not reset locally');

done_testing;
