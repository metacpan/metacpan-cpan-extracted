use strict;
use warnings;

use FindBin ();
use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;
use Time::HiRes qw(sleep);

use Net::QUIC::Endpoint;

my $server_local = pack_sockaddr_in(4490, inet_aton('127.0.0.1'));
my $alpn = 'net-quic-v2-cvn-test';
my $cert_file = "$FindBin::Bin/data/server-cert.pem";
my $key_file = "$FindBin::Bin/data/server-key.pem";

my $V1 = 0x00000001;
my $V2 = 0x6b3343cf;

sub wire_version {
    my ($datagram) = @_;
    return unpack('N', substr($datagram->data, 1, 4));
}

sub make_server {
    my (%extra) = @_;

    return Net::QUIC::Endpoint->server(
        alpn             => $alpn,
        certificate_file => $cert_file,
        private_key_file => $key_file,
        %extra,
    );
}

sub make_client {
    my ($local, %extra) = @_;

    return Net::QUIC::Endpoint->client(
        local       => $local,
        peer        => $server_local,
        alpn        => $alpn,
        server_name => 'localhost',
        ca_file     => $cert_file,
        %extra,
    );
}

sub pump_pair {
    my ($client, $server) = @_;
    my $progress = 0;

    while (my $datagram = $server->next_datagram) {
        ++$progress;
        $client->receive_datagram(
            $datagram->data,
            $datagram->peer,
            $datagram->local,
        );
    }

    while (my $datagram = $client->next_datagram) {
        ++$progress;
        $server->receive_datagram(
            $datagram->data,
            $datagram->peer,
            $datagram->local,
        );
    }

    my $client_after = $client->timeout_after;
    if (defined($client_after) && $client_after <= 0) {
        ++$progress;
        $client->handle_timeout;
    }

    my $server_after = $server->timeout_after;
    if (defined($server_after) && $server_after <= 0) {
        ++$progress;
        $server->handle_timeout;
    }

    if (!$progress) {
        my @wait = sort { $a <=> $b }
            grep { defined($_) && $_ > 0 }
            ($client_after, $server_after);

        if (@wait) {
            my $nap = $wait[0] > 0.01 ? 0.01 : $wait[0] + 0.001;
            sleep($nap);
            ++$progress;
        }
    }

    return $progress;
}

sub establish {
    my ($client, $server, $first) = @_;

    $server->receive_datagram(
        $first->data,
        $first->peer,
        $first->local,
    );

    my $accepted;

    for (1 .. 1200) {
        $accepted ||= $server->next_connection;

        last if $accepted
            && $client->connection->ready
            && $accepted->ready;

        pump_pair($client, $server);
    }

    return $accepted;
}

{
    my $server = make_server();
    my $client = make_client(
        pack_sockaddr_in(40400, inet_aton('127.0.0.1')),
    );

    my $first = $client->next_datagram;
    is(wire_version($first), $V1, 'default client first flight is QUIC v1');

    my $accepted = establish($client, $server, $first);
    ok($accepted, 'default v1 connection is accepted');
    ok($client->connection->ready, 'default v1 client is ready');
    is($client->connection->client_chosen_version, 1,
        'default client chose v1');
    is($client->connection->version, 1,
        'default connection negotiates v1');
    is($accepted->version, 1, 'server reports negotiated v1');
}

{
    my $server = make_server();
    my $client = make_client(
        pack_sockaddr_in(40401, inet_aton('127.0.0.1')),
        version => 2,
    );

    my $first = $client->next_datagram;
    is(wire_version($first), $V2, 'version => 2 sends a QUIC v2 Initial');

    my $accepted = establish($client, $server, $first);
    ok($accepted, 'direct v2 connection is accepted');
    ok($client->connection->ready, 'direct v2 client is ready');
    is($client->connection->client_chosen_version, 2,
        'direct v2 client chose v2');
    is($client->connection->version, 2,
        'direct connection negotiates v2');
    is($accepted->version, 2, 'server reports direct v2');
}

{
    my $server = make_server(preferred_version => 2);
    my $client = make_client(
        pack_sockaddr_in(40402, inet_aton('127.0.0.1')),
    );

    my $first = $client->next_datagram;
    is(wire_version($first), $V1,
        'compatible negotiation still starts with default v1 Initial');

    my $accepted = establish($client, $server, $first);
    ok($accepted, 'CVN connection is accepted');
    ok($client->connection->ready, 'CVN client is ready');
    is($client->connection->client_chosen_version, 1,
        'CVN preserves client-chosen v1');
    is($client->connection->version, 2,
        'server preference compatibly negotiates v2');
    is($accepted->client_chosen_version, 1,
        'server sees original client-chosen v1');
    is($accepted->version, 2,
        'server reports compatible negotiated v2');

    my $stream = $client->connection->open_bidi_stream;
    $stream->send("v2-after-cvn\n");
    $stream->finish;

    my $incoming;
    my $bytes;
    for (1 .. 500) {
        pump_pair($client, $server);
        $incoming ||= $accepted->next_stream;
        if ($incoming) {
            $bytes = $incoming->next_data;
            last if defined $bytes;
        }
    }

    is($bytes, "v2-after-cvn\n",
        'stream data works after compatible v1-to-v2 negotiation');
}

{
    my $server = make_server(
        preferred_version => 2,
        validate_address  => 1,
        accept_early_data => 1,
    );
    my $local_a = pack_sockaddr_in(40403, inet_aton('127.0.0.1'));
    my $client = make_client($local_a);

    my $first = $client->next_datagram;
    is(wire_version($first), $V1,
        'credential-producing connection starts with v1');

    $server->receive_datagram(
        $first->data,
        $first->peer,
        $first->local,
    );

    ok(!defined($server->next_connection),
        'address validation still requires Retry before first connection');

    my $retry = $server->next_datagram;
    ok(defined($retry), 'server sends Retry');

    $client->receive_datagram(
        $retry->data,
        $retry->peer,
        $retry->local,
    );

    my $retried = $client->next_datagram;
    ok(defined($retried), 'client answers Retry');

    my $accepted = establish($client, $server, $retried);
    ok($accepted, 'validated CVN connection is accepted');

    for (1 .. 1000) {
        last if defined($client->connection->session_ticket)
            && defined($client->connection->address_token);
        pump_pair($client, $server);
    }

    is($client->connection->version, 2,
        'credential-producing connection negotiated v2');

    my $ticket = $client->connection->session_ticket;
    my $token = $client->connection->address_token;
    my $early = $client->connection->early_data_state;

    ok(defined($ticket), 'v2 connection receives session ticket');
    ok(defined($token), 'v2 connection receives address token');
    ok(defined($early), 'v2 connection exports early-data state');
    is(substr($ticket, 0, 4), 'NQST',
        'session ticket remains opaque but version-tagged internally');
    is(substr($token, 0, 4), 'NQAT',
        'address token remains opaque but version-tagged internally');

    like(
        dies {
            make_client(
                pack_sockaddr_in(40404, inet_aton('127.0.0.1')),
                version        => 1,
                session_ticket => $ticket,
            );
        },
        qr/saved QUIC state belongs to version 2, not version 1/,
        'v2 session ticket cannot be explicitly reused as v1',
    );

    like(
        dies {
            make_client(
                pack_sockaddr_in(40405, inet_aton('127.0.0.1')),
                version       => 1,
                address_token => $token,
            );
        },
        qr/saved QUIC state belongs to version 2, not version 1/,
        'v2 NEW_TOKEN cannot be explicitly reused as v1',
    );

    like(
        dies {
            make_client(
                pack_sockaddr_in(40406, inet_aton('127.0.0.1')),
                version    => 1,
                early_data => $early,
            );
        },
        qr/saved QUIC state belongs to version 2, not version 1/,
        'v2 early-data state cannot be explicitly reused as v1',
    );

    my $resumed = make_client(
        pack_sockaddr_in(40407, inet_aton('127.0.0.1')),
        session_ticket => $ticket,
        address_token  => $token,
    );

    my $resumed_first = $resumed->next_datagram;
    is(wire_version($resumed_first), $V2,
        'saved v2 state automatically locks the next first flight to v2');

    $server->receive_datagram(
        $resumed_first->data,
        $resumed_first->peer,
        $resumed_first->local,
    );

    my $resumed_server = $server->next_connection;
    ok($resumed_server,
        'valid v2 address token avoids Retry on the resumed connection');

    my %client_for_peer = (
        $local_a => $client,
        pack_sockaddr_in(40407, inet_aton('127.0.0.1')) => $resumed,
    );

    for (1 .. 1000) {
        last if $resumed->connection->ready
            && $resumed_server->ready;

        my $progress = 0;

        while (my $datagram = $server->next_datagram) {
            ++$progress;
            my $target = $client_for_peer{$datagram->peer};
            next if !defined $target;

            $target->receive_datagram(
                $datagram->data,
                $datagram->peer,
                $datagram->local,
            );
        }

        for my $target ($client, $resumed) {
            while (my $datagram = $target->next_datagram) {
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

        for my $target ($client, $resumed) {
            my $after = $target->timeout_after;
            if (defined($after) && $after <= 0) {
                ++$progress;
                $target->handle_timeout;
            } elsif (defined($after) && $after > 0) {
                push @wait, $after;
            }
        }

        if (!$progress && @wait) {
            @wait = sort { $a <=> $b } @wait;
            my $nap = $wait[0] > 0.01 ? 0.01 : $wait[0] + 0.001;
            sleep($nap);
        }
    }

    ok($resumed->connection->ready, 'version-locked resumed client is ready');
    is($resumed->connection->client_chosen_version, 2,
        'saved v2 state makes v2 the client-chosen version');
    is($resumed->connection->version, 2,
        'saved v2 state resumes on v2');
    ok($resumed->connection->resumed,
        'version-locked v2 session ticket actually resumes TLS');
}

like(
    dies {
        make_server(preferred_version => 3);
    },
    qr/preferred_version must be 1 or 2/,
    'invalid server preferred_version is rejected',
);

like(
    dies {
        make_client(
            pack_sockaddr_in(40408, inet_aton('127.0.0.1')),
            version => 3,
        );
    },
    qr/version must be 1 or 2/,
    'invalid client version is rejected',
);

done_testing;
