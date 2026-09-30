use strict;
use warnings;

use FindBin ();
use IO::Select;
use IO::Socket::INET;
use Test2::V0;
use Time::HiRes qw(time);

use Net::QUIC::Driver;

my $alpn = 'net-quic-driver-loopback-test';
my $cert_file = "$FindBin::Bin/data/server-cert.pem";
my $key_file = "$FindBin::Bin/data/server-key.pem";

sub make_udp_socket {
    my $socket = IO::Socket::INET->new(
        LocalAddr => '127.0.0.1',
        LocalPort => 0,
        Proto     => 'udp',
    );

    die "could not create loopback UDP socket: $!"
        if !defined $socket;

    return $socket;
}

sub send_datagram {
    my ($socket, $datagram, $counter) = @_;

    my $bytes = $datagram->data;
    my $sent = send(
        $socket,
        $bytes,
        0,
        $datagram->peer,
    );

    die "loopback UDP send failed: $!"
        if !defined $sent;

    die "loopback UDP send was partial"
        if $sent != length($bytes);

    ++$$counter;
    return 1;
}

my $server_socket = make_udp_socket();
my $client_socket = make_udp_socket();

my $server_local = getsockname($server_socket);
my $client_local = getsockname($client_socket);

ok(defined($server_local), 'server UDP socket has a local address');
ok(defined($client_local), 'client UDP socket has a local address');

my ($server_deadline, $client_deadline);
my ($server_tx, $client_tx) = (0, 0);
my ($server_rx, $client_rx) = (0, 0);

my $server = Net::QUIC::Driver->server(
    alpn             => $alpn,
    certificate_file => $cert_file,
    private_key_file => $key_file,

    send => sub {
        my ($datagram) = @_;
        return send_datagram($server_socket, $datagram, \$server_tx);
    },

    set_timeout => sub {
        my ($after) = @_;
        $server_deadline = defined($after)
            ? time() + $after
            : undef;
        return;
    },
);

my $client = Net::QUIC::Driver->client(
    local       => $client_local,
    peer        => $server_local,
    alpn        => $alpn,
    server_name => 'localhost',
    ca_file     => $cert_file,

    send => sub {
        my ($datagram) = @_;
        return send_datagram($client_socket, $datagram, \$client_tx);
    },

    set_timeout => sub {
        my ($after) = @_;
        $client_deadline = defined($after)
            ? time() + $after
            : undef;
        return;
    },
);

my $client_connection = $client->connection;
my $selector = IO::Select->new($client_socket, $server_socket);

sub service_once {
    my ($hard_deadline) = @_;

    my $now = time();

    if (defined($server_deadline) && $server_deadline <= $now) {
        $server_deadline = undef;
        $server->timeout;
    }

    $now = time();

    if (defined($client_deadline) && $client_deadline <= $now) {
        $client_deadline = undef;
        $client->timeout;
    }

    $now = time();

    my $wait = 0.05;

    for my $deadline ($server_deadline, $client_deadline, $hard_deadline) {
        next if !defined $deadline;

        my $remaining = $deadline - $now;
        $remaining = 0 if $remaining < 0;
        $wait = $remaining if $remaining < $wait;
    }

    for my $socket ($selector->can_read($wait)) {
        my $bytes = '';
        my $peer = recv($socket, $bytes, 65535, 0);

        die "loopback UDP receive failed: $!"
            if !defined $peer;

        my $local = getsockname($socket);
        die "could not read loopback UDP local address: $!"
            if !defined $local;

        if (fileno($socket) == fileno($server_socket)) {
            ++$server_rx;
            $server->receive($bytes, $local, $peer);
        } else {
            ++$client_rx;
            $client->receive($bytes, $local, $peer);
        }
    }

    return;
}

sub run_until {
    my ($condition) = @_;

    my $hard_deadline = time() + 10;

    while (time() < $hard_deadline) {
        return 1 if $condition->();
        service_once($hard_deadline);
    }

    return $condition->() ? 1 : 0;
}

$server->start;
$client->start;

ok($server->started, 'server Driver is started');
ok($client->started, 'client Driver is started');

my $server_connection;

ok(
    run_until(sub {
        $server_connection ||= $server->next_connection;

        return $server_connection
            && $client_connection->ready
            && $server_connection->ready;
    }),
    'QUIC and TLS handshake completes through real UDP sockets',
);

isa_ok(
    $server_connection,
    ['Net::QUIC::Connection'],
    'server Driver exposes the accepted connection',
);

my $client_stream = $client_connection->open_bidi_stream;
my $request = "driver-loopback-request\n";

$client_stream->send($request);
$client_stream->finish;

my $server_stream;
my $server_received = '';

ok(
    run_until(sub {
        $server_stream ||= $server_connection->next_stream;

        if ($server_stream) {
            while (defined(my $chunk = $server_stream->next_data)) {
                $server_received .= $chunk;
            }
        }

        return $server_stream
            && $server_stream->remote_finished
            && $server_received eq $request;
    }),
    'stream request crosses kernel UDP and reaches the server',
);

is($server_received, $request, 'server receives the complete request');
ok($server_stream->remote_finished, 'server receives the request FIN');

my $response = "driver-loopback-response\n";
$server_stream->send($response);
$server_stream->finish;

my $client_received = '';

ok(
    run_until(sub {
        while (defined(my $chunk = $client_stream->next_data)) {
            $client_received .= $chunk;
        }

        return $client_stream->remote_finished
            && $client_received eq $response;
    }),
    'stream response crosses kernel UDP and reaches the client',
);

is($client_received, $response, 'client receives the complete response');
ok($client_stream->remote_finished, 'client receives the response FIN');

ok($client_tx > 0, 'client transmitted real UDP datagrams');
ok($server_rx > 0, 'server received real UDP datagrams');
ok($server_tx > 0, 'server transmitted real UDP datagrams');
ok($client_rx > 0, 'client received real UDP datagrams');

close $client_socket;
close $server_socket;

done_testing;
