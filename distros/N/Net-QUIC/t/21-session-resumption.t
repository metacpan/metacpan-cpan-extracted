use strict;
use warnings;

use FindBin ();
use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;
use Time::HiRes qw(sleep);

use Net::QUIC::Connection;
use Net::QUIC::Endpoint;

my $server_local = pack_sockaddr_in(4451, inet_aton('127.0.0.1'));
my $alpn = 'net-quic-session-resumption-test';
my $cert_file = "$FindBin::Bin/data/server-cert.pem";
my $key_file = "$FindBin::Bin/data/server-key.pem";

sub pump_pair {
    my ($client, $server, $client_local) = @_;
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

sub connect_pair {
    my (%args) = @_;
    my $client_local = $args{client_local};
    my $server_tls = $args{server_tls};

    my %client_args = (
        local       => $client_local,
        peer        => $server_local,
        alpn        => $alpn,
        server_name => 'localhost',
        ca_file     => $cert_file,
    );

    $client_args{session_ticket} = $args{session_ticket}
        if defined $args{session_ticket};

    my $client = Net::QUIC::Endpoint->client(%client_args);
    my $initial = $client->next_datagram;

    ok(defined($initial), 'client produces an Initial');

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

    for (1 .. 500) {
        pump_pair($client, $server, $client_local);

        last if $client->connection->ready
            && $server->ready
            && defined($client->connection->session_ticket);
    }

    return ($client, $server);
}

my $server_tls = Net::QUIC::_ServerTLS->_new($cert_file, $key_file);

my $first_local = pack_sockaddr_in(40021, inet_aton('127.0.0.1'));
my ($first_client, $first_server) = connect_pair(
    client_local => $first_local,
    server_tls   => $server_tls,
);

ok($first_client->connection->ready, 'first client handshake completes');
ok($first_server->ready, 'first server handshake completes');
ok(!$first_client->connection->resumed, 'first client handshake is not resumed');
ok(!$first_server->resumed, 'first server handshake is not resumed');

my $ticket = $first_client->connection->session_ticket;
ok(defined($ticket), 'first connection receives a TLS session ticket');
cmp_ok(length($ticket), '>', 0, 'session ticket is non-empty');

my $second_local = pack_sockaddr_in(40022, inet_aton('127.0.0.1'));
my ($second_client, $second_server) = connect_pair(
    client_local   => $second_local,
    server_tls     => $server_tls,
    session_ticket => $ticket,
);

ok($second_client->connection->ready, 'resumed client handshake completes');
ok($second_server->ready, 'resumed server handshake completes');
ok($second_client->connection->resumed, 'client reports TLS session resumption');
ok($second_server->resumed, 'server reports TLS session resumption');

my $replacement_ticket = $second_client->connection->session_ticket;
ok(defined($replacement_ticket), 'resumed connection receives a fresh ticket');
cmp_ok(length($replacement_ticket), '>', 0, 'replacement ticket is non-empty');

my $fresh_server_tls = Net::QUIC::_ServerTLS->_new($cert_file, $key_file);
my $third_local = pack_sockaddr_in(40023, inet_aton('127.0.0.1'));
my ($third_client, $third_server) = connect_pair(
    client_local   => $third_local,
    server_tls     => $fresh_server_tls,
    session_ticket => $ticket,
);

ok($third_client->connection->ready, 'fallback client handshake completes');
ok($third_server->ready, 'fallback server handshake completes');
ok(!$third_client->connection->resumed,
    'client falls back to full handshake when ticket key changed');
ok(!$third_server->resumed,
    'server reports full handshake after ticket-key mismatch');

like(
    dies {
        Net::QUIC::Endpoint->client(
            local          => $first_local,
            peer           => $server_local,
            alpn           => $alpn,
            server_name    => 'localhost',
            ca_file        => $cert_file,
            session_ticket => '',
        );
    },
    qr/session_ticket cannot be empty/,
    'empty session ticket is rejected',
);

done_testing;
