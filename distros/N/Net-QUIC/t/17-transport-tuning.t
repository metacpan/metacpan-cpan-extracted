use strict;
use warnings;

use FindBin ();
use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;
use Time::HiRes qw(sleep time);

use Net::QUIC::Endpoint;

my $server_local = pack_sockaddr_in(4451, inet_aton('127.0.0.1'));
my $client_local = pack_sockaddr_in(40051, inet_aton('127.0.0.1'));
my $alpn = 'net-quic-transport-tuning-test';
my $cert_file = "$FindBin::Bin/data/server-cert.pem";
my $key_file = "$FindBin::Bin/data/server-key.pem";

sub make_client {
    my (%extra) = @_;

    return Net::QUIC::Endpoint->client(
        local       => $client_local,
        peer        => $server_local,
        alpn        => $alpn,
        server_name => 'localhost',
        ca_file     => $cert_file,
        %extra,
    );
}

my $default_client = make_client();
my $defaults = $default_client->connection->_transport_info;

is(
    $defaults,
    {
        idle_timeout_ms             => 30_000,
        connection_window           => 1024 * 1024,
        stream_window_bidi_local    => 256 * 1024,
        stream_window_bidi_remote   => 256 * 1024,
        stream_window_uni           => 256 * 1024,
        max_bidi_streams            => 100,
        max_uni_streams             => 100,
        active_connection_id_limit  => 4,
        disable_active_migration    => 1,
    },
    'default QUIC transport policy is explicit and stable',
);

my $custom_client = make_client(
    transport => {
        handshake_timeout => 2.5,
        idle_timeout      => 12.5,
        connection_window => 2 * 1024 * 1024,
        stream_window     => 512 * 1024,
        max_bidi_streams  => 7,
        max_uni_streams   => 3,
    },
);

is(
    $custom_client->connection->_transport_info,
    {
        idle_timeout_ms             => 12_500,
        connection_window           => 2 * 1024 * 1024,
        stream_window_bidi_local    => 512 * 1024,
        stream_window_bidi_remote   => 512 * 1024,
        stream_window_uni           => 512 * 1024,
        max_bidi_streams            => 7,
        max_uni_streams             => 3,
        active_connection_id_limit  => 4,
        disable_active_migration    => 1,
    },
    'transport overrides reach ngtcp2',
);

like(
    dies { make_client(transport => 'not-a-hash') },
    qr/transport must be a hash reference/,
    'transport must be a hash reference',
);

like(
    dies { make_client(transport => { mystery => 1 }) },
    qr/unknown transport option: mystery/,
    'unknown transport option is rejected',
);

like(
    dies { make_client(transport => { handshake_timeout => 0 }) },
    qr/handshake_timeout must be greater than zero/,
    'zero handshake timeout is rejected',
);

like(
    dies { make_client(transport => { max_bidi_streams => -1 }) },
    qr/max_bidi_streams must be a non-negative integer/,
    'negative stream count is rejected',
);

my $short_handshake = make_client(
    transport => {
        handshake_timeout => 0.02,
    },
);

my $hard_deadline = time() + 1;

while (!defined($short_handshake->connection->close_info)
       && time() < $hard_deadline) {
    my $after = $short_handshake->timeout_after;

    if (!defined $after) {
        sleep(0.001);
        next;
    }

    sleep($after) if $after > 0;
    $short_handshake->handle_timeout;
}

is(
    $short_handshake->connection->close_info->{type},
    'handshake',
    'configured handshake timeout becomes a handshake close outcome',
);

my $server = Net::QUIC::Endpoint->server(
    alpn             => $alpn,
    certificate_file => $cert_file,
    private_key_file => $key_file,
    transport        => {
        max_bidi_streams => 1,
        max_uni_streams  => 1,
    },
);

my $client = make_client();
my $accepted;

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

for (1 .. 500) {
    pump_pair();
    $accepted ||= $server->next_connection;

    last if $accepted
        && $client->connection->ready
        && $accepted->ready;
}

ok($client->connection->ready, 'limited client handshake completes');
ok($accepted && $accepted->ready, 'limited server handshake completes');

my $bidi = $client->connection->open_bidi_stream;
isa_ok($bidi, ['Net::QUIC::Stream'], 'first bidirectional stream is allowed');
ok(
    !defined($client->connection->open_bidi_stream),
    'second bidirectional stream is blocked by configured peer limit',
);

my $uni = $client->connection->open_uni_stream;
isa_ok($uni, ['Net::QUIC::Stream'], 'first unidirectional stream is allowed');
ok(
    !defined($client->connection->open_uni_stream),
    'second unidirectional stream is blocked by configured peer limit',
);

done_testing;
