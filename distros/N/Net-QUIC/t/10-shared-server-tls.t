use strict;
use warnings;

use File::Temp qw(tempdir);
use FindBin ();
use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;
use Time::HiRes qw(sleep);

use Net::QUIC::Endpoint;

my $server_local = pack_sockaddr_in(4440, inet_aton('127.0.0.1'));
my @client_local = (
    pack_sockaddr_in(40009, inet_aton('127.0.0.1')),
    pack_sockaddr_in(40010, inet_aton('127.0.0.1')),
);
my $alpn = 'net-quic-shared-server-tls-test';
my $source_cert = "$FindBin::Bin/data/server-cert.pem";
my $source_key = "$FindBin::Bin/data/server-key.pem";

sub copy_file {
    my ($source, $dest) = @_;

    open my $in, '<:raw', $source
        or die "cannot open $source: $!";
    open my $out, '>:raw', $dest
        or die "cannot create $dest: $!";

    while (1) {
        my $read = read($in, my $buf, 8192);
        die "cannot read $source: $!"
            if !defined $read;
        last if !$read;

        print {$out} $buf
            or die "cannot write $dest: $!";
    }

    close $out or die "cannot close $dest: $!";
    close $in or die "cannot close $source: $!";
    return;
}

my $dir = tempdir(CLEANUP => 1);
my $cert_file = "$dir/server-cert.pem";
my $key_file = "$dir/server-key.pem";

copy_file($source_cert, $cert_file);
copy_file($source_key, $key_file);

my $server = Net::QUIC::Endpoint->server(
    alpn             => $alpn,
    certificate_file => $cert_file,
    private_key_file => $key_file,
);

ok(unlink($cert_file), 'certificate file can be removed after server construction');
ok(unlink($key_file), 'private key file can be removed after server construction');

my @client = map {
    Net::QUIC::Endpoint->client(
        local       => $_,
        peer        => $server_local,
        alpn        => $alpn,
        server_name => 'localhost',
        ca_file     => $source_cert,
    )
} @client_local;

my %client_for_peer = map {
    $client_local[$_] => $client[$_]
} 0 .. $#client;

sub pump_all {
    my $progress = 0;

    while (my $datagram = $server->next_datagram) {
        ++$progress;
        my $client = $client_for_peer{$datagram->peer};
        die "server produced datagram for unknown client"
            if !defined $client;

        $client->receive_datagram(
            $datagram->data,
            $datagram->peer,
            $server_local,
        );
    }

    for my $i (0 .. $#client) {
        while (my $datagram = $client[$i]->next_datagram) {
            ++$progress;
            $server->receive_datagram(
                $datagram->data,
                $server_local,
                $client_local[$i],
            );
        }
    }

    my @timeouts;

    my $server_after = $server->timeout_after;
    push @timeouts, [$server_after, sub { $server->handle_timeout }]
        if defined $server_after;

    for my $client (@client) {
        my $after = $client->timeout_after;
        push @timeouts, [$after, sub { $client->handle_timeout }]
            if defined $after;
    }

    for my $timer (@timeouts) {
        if ($timer->[0] <= 0) {
            ++$progress;
            $timer->[1]->();
        }
    }

    if (!$progress) {
        my @positive = sort { $a <=> $b }
            map { $_->[0] }
            grep { $_->[0] > 0 } @timeouts;

        if (@positive) {
            my $nap = $positive[0] > 0.01 ? 0.01 : $positive[0] + 0.001;
            sleep($nap);
            ++$progress;
        }
    }

    return $progress;
}

for my $i (0 .. $#client) {
    my $initial = $client[$i]->next_datagram;
    ok(defined($initial), "client $i produces Initial");

    $server->receive_datagram(
        $initial->data,
        $server_local,
        $client_local[$i],
    );
}

my @accepted;
while (my $connection = $server->next_connection) {
    push @accepted, $connection;
}

is(scalar(@accepted), 2, 'server accepts two connections after credential files are gone');

for (1 .. 500) {
    last if $client[0]->connection->ready
        && $client[1]->connection->ready
        && $accepted[0]->ready
        && $accepted[1]->ready;

    last if !pump_all();
}

ok($client[0]->connection->ready, 'first client handshake completes');
ok($client[1]->connection->ready, 'second client handshake completes');
ok($accepted[0]->ready, 'first server connection uses shared TLS context');
ok($accepted[1]->ready, 'second server connection uses shared TLS context');

like(
    dies {
        Net::QUIC::Endpoint->server(
            alpn             => $alpn,
            certificate_file => "$dir/missing-cert.pem",
            private_key_file => "$dir/missing-key.pem",
        );
    },
    qr/unable to load Picotls server certificate/,
    'missing certificate fails when Endpoint is constructed',
);

my $valid_cert = "$dir/valid-cert.pem";
copy_file($source_cert, $valid_cert);

like(
    dies {
        Net::QUIC::Endpoint->server(
            alpn             => $alpn,
            certificate_file => $valid_cert,
            private_key_file => "$dir/missing-key.pem",
        );
    },
    qr/unable to open Picotls server private key/,
    'missing private key fails when Endpoint is constructed',
);

done_testing;
