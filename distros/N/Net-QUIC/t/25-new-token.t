use strict;
use warnings;

use FindBin ();
use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;
use Time::HiRes qw(sleep);

use Net::QUIC::Endpoint;

my $server_local = pack_sockaddr_in(4470, inet_aton('127.0.0.1'));
my $client_a = pack_sockaddr_in(40200, inet_aton('127.0.0.1'));
my $client_b = pack_sockaddr_in(40201, inet_aton('127.0.0.1'));
my $client_wrong_ip = pack_sockaddr_in(40202, inet_aton('127.0.0.2'));
my $alpn = 'net-quic-new-token-test';
my $cert_file = "$FindBin::Bin/data/server-cert.pem";
my $key_file = "$FindBin::Bin/data/server-key.pem";

my $server = Net::QUIC::Endpoint->server(
    alpn             => $alpn,
    certificate_file => $cert_file,
    private_key_file => $key_file,
    validate_address => 1,
);

my %client_for_local;
my @clients;

sub make_client {
    my ($local, $token) = @_;

    my %args = (
        local       => $local,
        peer        => $server_local,
        alpn        => $alpn,
        server_name => 'localhost',
        ca_file     => $cert_file,
    );

    $args{address_token} = $token if defined $token;

    my $client = Net::QUIC::Endpoint->client(%args);
    $client_for_local{$local} = $client;
    push @clients, $client;

    return $client;
}

sub route_server_datagram {
    my ($datagram) = @_;
    my $client = $client_for_local{$datagram->peer};

    return if !defined $client;

    $client->receive_datagram(
        $datagram->data,
        $datagram->peer,
        $datagram->local,
    );

    return 1;
}

sub pump_network {
    my $progress = 0;

    while (my $datagram = $server->next_datagram) {
        ++$progress;
        route_server_datagram($datagram);
    }

    for my $client (@clients) {
        while (my $datagram = $client->next_datagram) {
            ++$progress;
            $server->receive_datagram(
                $datagram->data,
                $datagram->peer,
                $datagram->local,
            );
        }
    }

    my @wait;

    my $server_after = $server->timeout_after;
    if (defined($server_after) && $server_after <= 0) {
        ++$progress;
        $server->handle_timeout;
    } elsif (defined($server_after) && $server_after > 0) {
        push @wait, $server_after;
    }

    for my $client (@clients) {
        my $after = $client->timeout_after;
        if (defined($after) && $after <= 0) {
            ++$progress;
            $client->handle_timeout;
        } elsif (defined($after) && $after > 0) {
            push @wait, $after;
        }
    }

    if (!$progress && @wait) {
        @wait = sort { $a <=> $b } @wait;
        my $nap = $wait[0] > 0.01 ? 0.01 : $wait[0] + 0.001;
        sleep($nap);
        ++$progress;
    }

    return $progress;
}

sub take_server_datagram_for {
    my ($peer) = @_;

    for (1 .. 100) {
        my $datagram = $server->next_datagram;
        return if !defined $datagram;
        return $datagram if $datagram->peer eq $peer;
        route_server_datagram($datagram);
    }

    return;
}

my $first = make_client($client_a);

my $initial = $first->next_datagram;
ok(defined($initial), 'first client produces Initial');

$server->receive_datagram(
    $initial->data,
    $initial->peer,
    $initial->local,
);

ok(
    !defined($server->next_connection),
    'first connection without address token requires Retry',
);

my $retry = take_server_datagram_for($client_a);
ok(defined($retry), 'server sends Retry to first client');

$first->receive_datagram(
    $retry->data,
    $retry->peer,
    $retry->local,
);

my $retried_initial = $first->next_datagram;
ok(defined($retried_initial), 'first client answers Retry');

$server->receive_datagram(
    $retried_initial->data,
    $retried_initial->peer,
    $retried_initial->local,
);

my $first_server = $server->next_connection;
ok(defined($first_server), 'Retry-validated first connection is accepted');

for (1 .. 800) {
    pump_network();
    last if $first->connection->ready
        && $first_server->ready
        && defined($first->connection->address_token);
}

ok($first->connection->ready, 'first client handshake completes');
ok($first_server->ready, 'first server handshake completes');

my $token = $first->connection->address_token;
ok(defined($token), 'client receives NEW_TOKEN after validated handshake');
cmp_ok(length($token), '>', 0, 'NEW_TOKEN is non-empty');

my $second = make_client($client_b, $token);
my $second_initial = $second->next_datagram;
ok(defined($second_initial), 'second client produces Initial with NEW_TOKEN');

$server->receive_datagram(
    $second_initial->data,
    $second_initial->peer,
    $second_initial->local,
);

my $second_server = $server->next_connection;
ok(
    defined($second_server),
    'valid NEW_TOKEN avoids Retry and allocates Connection on first Initial',
);

for (1 .. 800) {
    pump_network();
    last if $second->connection->ready
        && $second_server->ready
        && defined($second->connection->address_token);
}

ok($second->connection->ready, 'token-validated client handshake completes');
ok($second_server->ready, 'token-validated server handshake completes');

my $replacement = $second->connection->address_token;
ok(defined($replacement), 'server issues a fresh NEW_TOKEN');
cmp_ok(length($replacement), '>', 0, 'replacement NEW_TOKEN is non-empty');

my $wrong = make_client($client_wrong_ip, $token);
my $wrong_initial = $wrong->next_datagram;
ok(defined($wrong_initial), 'wrong-IP client offers saved NEW_TOKEN');

$server->receive_datagram(
    $wrong_initial->data,
    $wrong_initial->peer,
    $wrong_initial->local,
);

ok(
    !defined($server->next_connection),
    'NEW_TOKEN bound to another IP does not validate the new address',
);

my $wrong_retry = take_server_datagram_for($client_wrong_ip);
ok(
    defined($wrong_retry),
    'invalid NEW_TOKEN is treated as unvalidated and receives Retry',
);

$wrong->receive_datagram(
    $wrong_retry->data,
    $wrong_retry->peer,
    $wrong_retry->local,
);

my $wrong_retried_initial = $wrong->next_datagram;
ok(
    defined($wrong_retried_initial),
    'client can continue normally after NEW_TOKEN falls back to Retry',
);

$server->receive_datagram(
    $wrong_retried_initial->data,
    $wrong_retried_initial->peer,
    $wrong_retried_initial->local,
);

my $wrong_server = $server->next_connection;
ok(
    defined($wrong_server),
    'Retry validates the new IP after NEW_TOKEN rejection',
);

for (1 .. 800) {
    pump_network();
    last if $wrong->connection->ready && $wrong_server->ready;
}

ok($wrong->connection->ready, 'fallback client handshake completes');
ok($wrong_server->ready, 'fallback server handshake completes');

like(
    dies {
        make_client(
            pack_sockaddr_in(40203, inet_aton('127.0.0.1')),
            '',
        );
    },
    qr/address_token cannot be empty/,
    'empty address token is rejected',
);

done_testing;
