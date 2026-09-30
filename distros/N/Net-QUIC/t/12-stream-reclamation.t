use strict;
use warnings;

use FindBin ();
use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;
use Time::HiRes qw(sleep);

use Net::QUIC::Connection;
use Net::QUIC::Endpoint;
use Net::QUIC::Stream;

my $client_local = pack_sockaddr_in(40012, inet_aton('127.0.0.1'));
my $server_local = pack_sockaddr_in(4442, inet_aton('127.0.0.1'));
my $alpn = 'net-quic-stream-reclamation-test';
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
ok(defined($initial), 'client produces Initial for reclamation test');

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
is($client->connection->_stream_state_count, 0, 'client starts with no stream state');
is($server->_stream_state_count, 0, 'server starts with no stream state');

my $client_stream = $client->connection->open_bidi_stream;
is($client->connection->_stream_state_count, 1, 'public client Stream retains native state');

my $request = "reclamation-request\n";
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
is($server_received, $request, 'server receives request before close');
is($server->_stream_state_count, 1, 'server Stream retains its native state');

my $response = "reclamation-response\n";
$server_stream->send($response);
$server_stream->finish;

my $client_received = '';

for (1 .. 500) {
    pump_pair($client, $server);

    while (defined(my $chunk = $client_stream->next_data)) {
        $client_received .= $chunk;
    }

    last if $client_received eq $response
        && $client_stream->closed
        && $server_stream->closed;
}

is($client_received, $response, 'client receives response before reclamation');
ok($client_stream->closed, 'client stream reaches native closed state');
ok($server_stream->closed, 'server stream reaches native closed state');
ok($client_stream->remote_finished, 'closed client Stream keeps final peer state');
ok($server_stream->remote_finished, 'closed server Stream keeps final peer state');
is(
    $client->connection->_stream_state_count,
    1,
    'closed client native state remains while Perl Stream exists',
);
is(
    $server->_stream_state_count,
    1,
    'closed server native state remains while Perl Stream exists',
);

undef $client_stream;
is(
    $client->connection->_stream_state_count,
    0,
    'closed client state is reclaimed when Perl Stream is released',
);

undef $server_stream;
is(
    $server->_stream_state_count,
    0,
    'closed server state is reclaimed when Perl Stream is released',
);

my $queued_client = $client->connection->open_uni_stream;
my $queued_id = $queued_client->id;
$queued_client->send("queued-before-next-stream\n");
$queued_client->finish;

my $queued_seen = 0;
my $queued_closed = 0;
for (1 .. 500) {
    pump_pair($client, $server);

    if ($server->_stream_state_count != 0) {
        $queued_seen = 1;
        $queued_closed = $server->_stream_closed($queued_id);
    }

    last if $queued_closed;
}

ok($queued_seen, 'server creates native state for queued incoming stream');
ok($queued_closed, 'incoming stream can close before next_stream is called');
is(
    $server->_stream_state_count,
    1,
    'pending incoming queue keeps a closed stream alive',
);

my $queued_server = $server->next_stream;
isa_ok($queued_server, ['Net::QUIC::Stream']);
is($queued_server->id, $queued_id, 'next_stream returns the queued closed stream');
is(
    $server->_stream_state_count,
    1,
    'queue ownership transfers to the returned Perl Stream',
);

my $queued_received = '';
while (defined(my $chunk = $queued_server->next_data)) {
    $queued_received .= $chunk;
}

is(
    $queued_received,
    "queued-before-next-stream\n",
    'buffered data remains available after native stream close',
);
ok($queued_server->remote_finished, 'queued closed stream keeps peer FIN state');
ok($queued_server->closed, 'returned queued stream still reports closed');

undef $queued_server;
is(
    $server->_stream_state_count,
    0,
    'queued closed stream is reclaimed after the returned object is released',
);

for (1 .. 300) {
    last if $queued_client->closed;
    pump_pair($client, $server);
}

ok($queued_client->closed, 'local unidirectional stream also reaches closed state');
is(
    $client->connection->_stream_state_count,
    1,
    'local closed stream stays while its Perl object exists',
);

undef $queued_client;
is(
    $client->connection->_stream_state_count,
    0,
    'local closed stream is reclaimed after its object is released',
);

my $detached_client = $client->connection->open_uni_stream;
my $detached_id = $detached_client->id;
$detached_client->send("released-before-close\n");
$detached_client->finish;

undef $detached_client;
is(
    $client->connection->_stream_state_count,
    1,
    'unclosed native state survives after its Perl Stream is released',
);

my $detached_server;
my $detached_received = '';

for (1 .. 500) {
    pump_pair($client, $server);
    $detached_server ||= $server->next_stream;

    if ($detached_server) {
        while (defined(my $chunk = $detached_server->next_data)) {
            $detached_received .= $chunk;
        }
    }

    last if $client->connection->_stream_state_count == 0
        && $detached_server
        && $detached_server->remote_finished
        && $detached_received eq "released-before-close\n";
}

is(
    $detached_received,
    "released-before-close\n",
    'dropping the local Stream does not discard queued transmit data',
);
is(
    $client->connection->_stream_state_count,
    0,
    'native state is reclaimed when a later close arrives with no Stream owner',
);
isa_ok($detached_server, ['Net::QUIC::Stream']);
is($detached_server->id, $detached_id, 'peer still discovers the detached stream');

for (1 .. 300) {
    last if $detached_server->closed;
    pump_pair($client, $server);
}

ok($detached_server->closed, 'peer side of detached stream closes normally');
undef $detached_server;
is(
    $server->_stream_state_count,
    0,
    'peer native state is reclaimed after its Stream object is released',
);

done_testing;
