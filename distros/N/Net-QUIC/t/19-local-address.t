use strict;
use warnings;

use FindBin ();
use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;

use Net::QUIC::Driver;
use Net::QUIC::Endpoint;

my $cert_file = "$FindBin::Bin/data/server-cert.pem";
my $key_file = "$FindBin::Bin/data/server-key.pem";

my $wildcard_v4 = pack_sockaddr_in(
    4433,
    inet_aton('0.0.0.0'),
);

my $loopback_v4 = pack_sockaddr_in(
    4433,
    inet_aton('127.0.0.1'),
);

like(
    dies {
        Net::QUIC::Endpoint->client(
            local       => $wildcard_v4,
            peer        => $loopback_v4,
            alpn        => 'local-address-test',
            server_name => 'localhost',
            ca_file     => $cert_file,
        );
    },
    qr/local must be a concrete IPv4 or IPv6 address/,
    'client rejects an IPv4 wildcard as its QUIC local path',
);

my $server = Net::QUIC::Endpoint->server(
    alpn             => 'local-address-test',
    certificate_file => $cert_file,
    private_key_file => $key_file,
);

like(
    dies {
        $server->receive_datagram(
            "not a QUIC packet",
            $wildcard_v4,
            $loopback_v4,
        );
    },
    qr/local must be a concrete IPv4 or IPv6 address/,
    'server receive rejects an IPv4 wildcard local path',
);

ok(
    !dies {
        $server->receive_datagram(
            "not a QUIC packet",
            $loopback_v4,
            $loopback_v4,
        );
    },
    'server receive accepts a concrete IPv4 local path',
);

my $driver = Net::QUIC::Driver->server(
    alpn             => 'local-address-test',
    certificate_file => $cert_file,
    private_key_file => $key_file,
    send             => sub { 1 },
    set_timeout      => sub { return },
);

$driver->start;

like(
    dies {
        $driver->receive(
            "not a QUIC packet",
            $wildcard_v4,
            $loopback_v4,
        );
    },
    qr/local must be a concrete IPv4 or IPv6 address/,
    'Driver receive exposes the same concrete-local contract',
);

SKIP: {
    skip 'Socket IPv6 packing is unavailable', 2
        if !Socket->can('pack_sockaddr_in6')
        || !Socket->can('inet_pton')
        || !Socket->can('AF_INET6');

    my $af_inet6 = Socket::AF_INET6();
    my $wildcard_v6 = Socket::pack_sockaddr_in6(
        4433,
        Socket::inet_pton($af_inet6, '::'),
    );
    my $loopback_v6 = Socket::pack_sockaddr_in6(
        4433,
        Socket::inet_pton($af_inet6, '::1'),
    );

    like(
        dies {
            Net::QUIC::Endpoint->client(
                local       => $wildcard_v6,
                peer        => $loopback_v6,
                alpn        => 'local-address-test',
                server_name => 'localhost',
                ca_file     => $cert_file,
            );
        },
        qr/local must be a concrete IPv4 or IPv6 address/,
        'client rejects an IPv6 wildcard as its QUIC local path',
    );

    ok(
        !dies {
            my $ipv6_server = Net::QUIC::Endpoint->server(
                alpn             => 'local-address-test',
                certificate_file => $cert_file,
                private_key_file => $key_file,
            );

            $ipv6_server->receive_datagram(
                "not a QUIC packet",
                $loopback_v6,
                $loopback_v6,
            );
        },
        'server receive accepts a concrete IPv6 local path',
    );
}

done_testing;
