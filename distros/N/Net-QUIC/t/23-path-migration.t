use strict;
use warnings;

use FindBin ();
use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;
use Time::HiRes qw(sleep time);

use Net::QUIC::Connection;
use Net::QUIC::Endpoint;

my $client_a = pack_sockaddr_in(40100, inet_aton('127.0.0.1'));
my $client_b = pack_sockaddr_in(40101, inet_aton('127.0.0.1'));
my $client_c = pack_sockaddr_in(40102, inet_aton('127.0.0.1'));
my $server_local = pack_sockaddr_in(4460, inet_aton('127.0.0.1'));
my $alpn = 'net-quic-migration-test';
my $cert_file = "$FindBin::Bin/data/server-cert.pem";
my $key_file = "$FindBin::Bin/data/server-key.pem";

sub deliver_client_to_server {
    my ($client, $server) = @_;
    my $count = 0;

    while (my $datagram = $client->next_datagram) {
        ++$count;
        $server->_receive_datagram(
            $datagram->data,
            $datagram->peer,
            $datagram->local,
        );
    }

    return $count;
}

sub deliver_server_to_client {
    my ($server, $client) = @_;
    my $count = 0;

    while (my $datagram = $server->_next_datagram) {
        ++$count;
        $client->receive_datagram(
            $datagram->data,
            $datagram->peer,
            $datagram->local,
        );
    }

    return $count;
}

sub pump_pair {
    my ($client, $server) = @_;
    my $progress = 0;

    $progress += deliver_server_to_client($server, $client);
    $progress += deliver_client_to_server($client, $server);

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
                $client->handle_timeout;
            }

            $server_after = $server->_timeout_after;
            if (defined($server_after) && $server_after <= 0) {
                $server->_handle_timeout;
            }
        }
    }

    return $progress;
}

my $server_tls = Net::QUIC::_ServerTLS->_new($cert_file, $key_file);

my $client = Net::QUIC::Endpoint->client(
    local       => $client_a,
    peer        => $server_local,
    alpn        => $alpn,
    server_name => 'localhost',
    ca_file     => $cert_file,
);

my $initial = $client->next_datagram;
ok(defined($initial), 'client produces Initial on path A');
is($initial->local, $client_a, 'Initial source is path A');
is($initial->peer, $server_local, 'Initial destination is server');

my $server = Net::QUIC::Connection->_server_new(
    $initial->data,
    $server_local,
    $client_a,
    $alpn,
    $server_tls,
);

$server->_receive_datagram(
    $initial->data,
    $server_local,
    $client_a,
);

for (1 .. 500) {
    pump_pair($client, $server);
    last if $client->connection->ready && $server->ready;
}

ok($client->connection->ready, 'client handshake completes on path A');
ok($server->ready, 'server handshake completes on path A');

my $initial_path = $client->connection->path;
is($initial_path->{local}, $client_a, 'client current path begins on A');
is($initial_path->{peer}, $server_local, 'client current peer is server');
is(
    $client->connection->path_validation_status,
    'none',
    'no path validation has run before migration',
);

my $client_stream = $client->connection->open_bidi_stream;
isa_ok($client_stream, ['Net::QUIC::Stream']);
$client_stream->send("before-migration\n");

my $server_stream;
my $before;
for (1 .. 500) {
    pump_pair($client, $server);

    $server_stream ||= $server->next_stream;
    if ($server_stream) {
        $before = $server_stream->next_data;
        last if defined $before;
    }
}

isa_ok($server_stream, ['Net::QUIC::Stream']);
is($before, "before-migration\n", 'stream works before migration');

$client->connection->migrate($client_b);

is(
    $client->connection->path_validation_status,
    'validating',
    'new path starts validating',
);
my $started = $client->connection->path_validation;
is(ref($started), 'HASH', 'migration exposes detailed path-validation state');
is($started->{local}, $client_b, 'validation targets path B');
is($started->{peer}, $server_local, 'validation keeps the same server peer');

my $saw_path_b_datagram = 0;
for (1 .. 1000) {
    while (my $datagram = $client->next_datagram) {
        $saw_path_b_datagram = 1
            if $datagram->local eq $client_b;

        $server->_receive_datagram(
            $datagram->data,
            $datagram->peer,
            $datagram->local,
        );
    }

    deliver_server_to_client($server, $client);

    last if $client->connection->path_validation_status eq 'succeeded';

    pump_pair($client, $server);
}

ok($saw_path_b_datagram, 'client emits path-validation traffic from path B');

is(
    $client->connection->path_validation_status,
    'succeeded',
    'path B validates successfully',
);
my $validated = $client->connection->path_validation;
is(ref($validated), 'HASH', 'validation result remains observable');
is($validated->{local}, $client_b, 'successful validation records path B');

my $migrated_path = $client->connection->path;
is($migrated_path->{local}, $client_b, 'client current path switches to B');
is($migrated_path->{peer}, $server_local, 'server peer is unchanged after migration');

$client_stream->send("after-migration\n");
$client_stream->finish;

my $after;
for (1 .. 500) {
    pump_pair($client, $server);
    $after = $server_stream->next_data;
    last if defined $after;
}

is($after, "after-migration\n", 'existing stream continues after migration');

$server_stream->send("reply-on-b\n");
$server_stream->finish;

my $reply;
my $saw_server_reply_to_b = 0;
for (1 .. 500) {
    while (my $datagram = $server->_next_datagram) {
        $saw_server_reply_to_b = 1
            if $datagram->peer eq $client_b;

        $client->receive_datagram(
            $datagram->data,
            $datagram->peer,
            $datagram->local,
        );
    }

    deliver_client_to_server($client, $server);

    $reply = $client_stream->next_data;
    last if defined $reply;

    pump_pair($client, $server);
}

ok($saw_server_reply_to_b, 'server sends post-migration traffic to path B');
is($reply, "reply-on-b\n", 'same bidirectional stream receives on path B');

like(
    dies { $client->connection->migrate($client_b) },
    qr/different local network path|another path transition/i,
    'migrating to the current local path is rejected',
);

$client->connection->migrate($client_c);
is(
    $client->connection->path_validation_status,
    'validating',
    'unreachable path C starts validating',
);

my $failure_deadline = time() + 8;
my $dropped_c_packets = 0;

while (
    $client->connection->path_validation_status eq 'validating'
    && time() < $failure_deadline
) {
    my $progress = 0;

    while (my $datagram = $client->next_datagram) {
        ++$progress;

        if ($datagram->local eq $client_c) {
            ++$dropped_c_packets;
            next;
        }

        $server->_receive_datagram(
            $datagram->data,
            $datagram->peer,
            $datagram->local,
        );
    }

    $progress += deliver_server_to_client($server, $client);

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
        my @wait = sort { $a <=> $b }
            grep { defined($_) && $_ > 0 }
            ($client_after, $server_after);

        sleep($wait[0] > 0.01 ? 0.01 : $wait[0] + 0.001)
            if @wait;
    }
}

ok($dropped_c_packets, 'test drops validation traffic for path C');
is(
    $client->connection->path_validation_status,
    'failed',
    'unreachable path validation reports failure',
);

my $fallback_path = $client->connection->path;
is($fallback_path->{local}, $client_b, 'failed validation keeps path B active');
is($fallback_path->{peer}, $server_local, 'failed validation keeps server peer');

like(
    dies { $server->migrate($server_local) },
    qr/only a QUIC client can initiate active migration/,
    'server cannot initiate active migration',
);

done_testing;
