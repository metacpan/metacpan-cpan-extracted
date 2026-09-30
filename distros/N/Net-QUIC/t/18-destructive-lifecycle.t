use strict;
use warnings;

use FindBin ();
use Scalar::Util qw(refaddr weaken);
use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;
use Time::HiRes qw(sleep time);

use Net::QUIC::Driver;
use Net::QUIC::Endpoint;

my $cert_file = "$FindBin::Bin/data/server-cert.pem";
my $key_file = "$FindBin::Bin/data/server-key.pem";

sub pump_pair {
    my ($client, $server, $client_local, $server_local) = @_;
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

sub make_ready_pair {
    my ($port, $name) = @_;

    my $server_local = pack_sockaddr_in($port, inet_aton('127.0.0.1'));
    my $client_local = pack_sockaddr_in($port + 10000, inet_aton('127.0.0.1'));
    my $alpn = "net-quic-lifecycle-$name";

    my $server = Net::QUIC::Endpoint->server(
        alpn             => $alpn,
        certificate_file => $cert_file,
        private_key_file => $key_file,
    );

    my $client = Net::QUIC::Endpoint->client(
        local       => $client_local,
        peer        => $server_local,
        alpn        => $alpn,
        server_name => 'localhost',
        ca_file     => $cert_file,
    );

    my $accepted;

    for (1 .. 1000) {
        pump_pair($client, $server, $client_local, $server_local);
        $accepted ||= $server->next_connection;

        last if $accepted
            && $client->connection->ready
            && $accepted->ready;
    }

    die "lifecycle test handshake did not complete"
        if !$accepted
        || !$client->connection->ready
        || !$accepted->ready;

    return (
        $client,
        $server,
        $accepted,
        $client_local,
        $server_local,
    );
}

subtest 'object destruction order' => sub {
    my ($client, $server, $accepted, $client_local, $server_local) =
        make_ready_pair(4460, 'drop-order-one');

    my @discarded;
    my @timeouts;

    my $driver = Net::QUIC::Driver->new(
        endpoint => $client,

        send => sub {
            my ($datagram) = @_;
            push @discarded, $datagram;
            return 1;
        },

        set_timeout => sub {
            push @timeouts, $_[0];
            return;
        },
    );

    my $connection = $driver->connection;
    my $stream = $connection->open_uni_stream;

    my $weak_driver = $driver;
    my $weak_endpoint = $client;
    my $weak_connection = $connection;

    weaken($weak_driver);
    weaken($weak_endpoint);
    weaken($weak_connection);

    undef $driver;
    ok(!defined($weak_driver), 'Driver can be destroyed before its Connection');

    undef $client;
    ok(!defined($weak_endpoint), 'Endpoint can be destroyed while Stream keeps Connection alive');

    undef $connection;
    ok(defined($weak_connection), 'Stream strongly retains its Connection');

    ok(
        !dies {
            $stream->send("survives-owner-drop\n");
            $stream->finish;
        },
        'Stream remains safe after Driver and Endpoint are gone',
    );

    undef $stream;
    ok(!defined($weak_connection), 'dropping final Stream releases remaining Connection');

    undef $accepted;
    undef $server;

    ($client, $server, $accepted, $client_local, $server_local) =
        make_ready_pair(4461, 'drop-order-two');

    $connection = $client->connection;
    $stream = $connection->open_bidi_stream;

    $weak_endpoint = $client;
    $weak_connection = $connection;
    weaken($weak_endpoint);
    weaken($weak_connection);

    undef $stream;
    ok(defined($weak_connection), 'dropping Stream first leaves Connection owned by Endpoint');

    undef $connection;
    ok(defined($weak_connection), 'dropping caller Connection reference leaves Endpoint ownership');

    undef $client;
    ok(!defined($weak_endpoint), 'Endpoint is destroyed after caller releases it');
    ok(!defined($weak_connection), 'Endpoint destruction releases its Connection');

    undef $accepted;
    undef $server;
};

subtest 'close while Driver output is backpressured' => sub {
    my ($client, $server, $accepted, $client_local, $server_local) =
        make_ready_pair(4462, 'backpressure-close');

    my @wire;
    my @scheduled;
    my $blocked = 1;

    my $driver = Net::QUIC::Driver->new(
        endpoint => $client,

        send => sub {
            my ($datagram) = @_;
            push @wire, $datagram;
            return $blocked ? 0 : 1;
        },

        set_timeout => sub {
            push @scheduled, $_[0];
            return;
        },
    );

    my $connection = $driver->connection;
    $driver->start;

    my $stream = $connection->open_bidi_stream;
    $stream->send('x' x (128 * 1024));
    $stream->finish;

    is(scalar(@wire), 1, 'Driver stops draining after adapter reports backpressure');

    $connection->close(91);
    is(
        scalar(@wire),
        1,
        'Connection close does not bypass Driver backpressure',
    );

    $blocked = 0;
    $driver->writable;

    ok(@wire >= 2, 'writable resumes draining pending QUIC output');
    ok(@scheduled, 'Driver continues maintaining the QUIC timer while blocked');

    for my $datagram (@wire) {
        $server->receive_datagram(
            $datagram->data,
            $server_local,
            $client_local,
        );
    }

    is(
        $accepted->close_info,
        {
            type      => 'application',
            initiator => 'peer',
            code      => 91,
        },
        'peer receives the close that was queued behind backpressure',
    );

    ok(
        !defined($client->next_datagram),
        'Driver writable pass leaves no pending client datagram behind',
    );

    undef $stream;
    undef $connection;
    undef $driver;
    undef $accepted;
    undef $server;
    undef $client;
};

sub pump_many {
    my ($server, $clients, $locals, $server_local) = @_;
    my $progress = 0;
    my %client_for;

    for my $i (0 .. $#$clients) {
        $client_for{$locals->[$i]} = $clients->[$i];

        while (my $datagram = $clients->[$i]->next_datagram) {
            ++$progress;
            $server->receive_datagram(
                $datagram->data,
                $server_local,
                $locals->[$i],
            );
        }
    }

    while (my $datagram = $server->next_datagram) {
        my $client = $client_for{$datagram->peer};
        die "server produced datagram for unknown lifecycle client"
            if !defined $client;

        ++$progress;
        $client->receive_datagram(
            $datagram->data,
            $datagram->peer,
            $server_local,
        );
    }

    my $server_after = $server->timeout_after;
    if (defined($server_after) && $server_after <= 0) {
        ++$progress;
        $server->handle_timeout;
    }

    my @client_after;
    for my $client (@$clients) {
        my $after = $client->timeout_after;
        push @client_after, $after;

        if (defined($after) && $after <= 0) {
            ++$progress;
            $client->handle_timeout;
        }
    }

    if (!$progress) {
        my @wait = sort { $a <=> $b }
            grep { defined($_) && $_ > 0 }
            ($server_after, @client_after);

        if (@wait) {
            my $nap = $wait[0] > 0.01 ? 0.01 : $wait[0] + 0.001;
            sleep($nap);
            ++$progress;
        }
    }

    return $progress;
}

subtest 'staggered multi-connection retirement' => sub {
    my $server_local = pack_sockaddr_in(4463, inet_aton('127.0.0.1'));
    my $alpn = 'net-quic-lifecycle-many';

    my $server = Net::QUIC::Endpoint->server(
        alpn             => $alpn,
        certificate_file => $cert_file,
        private_key_file => $key_file,
    );

    my @locals = map {
        pack_sockaddr_in(41000 + $_, inet_aton('127.0.0.1'))
    } 0 .. 2;

    my @clients = map {
        Net::QUIC::Endpoint->client(
            local       => $locals[$_],
            peer        => $server_local,
            alpn        => $alpn,
            server_name => 'localhost',
            ca_file     => $cert_file,
        )
    } 0 .. 2;

    my @accepted;

    for (1 .. 2000) {
        pump_many($server, \@clients, \@locals, $server_local);

        while (my $connection = $server->next_connection) {
            push @accepted, $connection;
        }

        last if @accepted == 3
            && !(grep { !$_->connection->ready } @clients)
            && !(grep { !$_->ready } @accepted);
    }

    is(scalar(@accepted), 3, 'server accepts all three lifecycle clients');
    ok(!(grep { !$_->connection->ready } @clients), 'all clients are ready');
    ok(!(grep { !$_->ready } @accepted), 'all server Connections are ready');
    is($server->_managed_connection_count, 3, 'server manages three live Connections');
    ok($server->_route_count >= 3, 'live Connections have CID routes');

    my @client_streams;
    for my $i (0 .. 2) {
        my $stream = $clients[$i]->connection->open_bidi_stream;
        $stream->send("lifecycle-client-$i\n");
        $stream->finish;
        push @client_streams, $stream;
    }

    my @server_for;
    my %server_stream_for;
    my %server_finished;
    my %received_for;

    for (1 .. 2000) {
        pump_many($server, \@clients, \@locals, $server_local);

        for my $connection (@accepted) {
            my $key = refaddr($connection);
            my $stream = $server_stream_for{$key};

            if (!$stream) {
                $stream = $connection->next_stream;
                $server_stream_for{$key} = $stream if $stream;
            }

            next if !$stream;

            while (defined(my $chunk = $stream->next_data)) {
                $received_for{$key} .= $chunk;
            }

            if ($stream->remote_finished
                && $received_for{$key} =~ /lifecycle-client-(\d+)\n/) {
                my $index = 0 + $1;

                $server_for[$index] = $connection;

                if (!$server_finished{$key}) {
                    $stream->finish;
                    $server_finished{$key} = 1;
                }
            }
        }

        last if !(grep { !defined $_ } @server_for)
            && !(grep { !$_->closed } @client_streams)
            && !(grep { !$_->closed } values %server_stream_for);
    }

    ok(!(grep { !defined $_ } @server_for), 'server Connections are matched to their clients');
    ok(!(grep { !$_->closed } @client_streams), 'all lifecycle streams close normally');

    for my $connection (@accepted) {
        my $key = refaddr($connection);
        my $stream = $server_stream_for{$key};
        undef $stream;
        delete $server_stream_for{$key};
    }

    @client_streams = ();

    for my $client (@clients) {
        is(
            $client->connection->_stream_state_count,
            0,
            'client has no leftover native stream state before connection close',
        );
    }

    for my $connection (@accepted) {
        is(
            $connection->_stream_state_count,
            0,
            'server has no leftover native stream state before connection close',
        );
    }

    for my $i (0 .. 2) {
        my $client_connection = $clients[$i]->connection;
        my $server_connection = $server_for[$i];

        $client_connection->close(120 + $i);

        for (1 .. 3000) {
            last if $client_connection->closed
                && $server_connection->closed;

            pump_many($server, \@clients, \@locals, $server_local);
        }

        ok($client_connection->closed, "client $i retires after close");
        ok($server_connection->closed, "server Connection $i retires after drain");
        is(
            $server_connection->close_info,
            {
                type      => 'application',
                initiator => 'peer',
                code      => 120 + $i,
            },
            "server Connection $i retains its close outcome",
        );

        my $remaining = 2 - $i;
        is(
            $server->_managed_connection_count,
            $remaining,
            "server ownership drops to $remaining Connections",
        );

        if ($remaining) {
            ok($server->_route_count > 0, 'remaining Connections keep live CID routes');
            ok(defined($server->timeout_after), 'remaining Connections keep an endpoint timer');
        }
    }

    is($server->_route_count, 0, 'all CID routes disappear after final retirement');
    ok(!defined($server->timeout_after), 'no server timer remains after final retirement');
    ok(!defined($server->next_connection), 'no stale pending accept remains');

    for my $client (@clients) {
        ok(!defined($client->timeout_after), 'retired client no longer needs a timer');
    }

    my @weak_clients = map { $_->connection } @clients;
    my @weak_servers = @accepted;
    weaken($_) for @weak_clients;
    weaken($_) for @weak_servers;

    @server_for = ();
    %server_stream_for = ();
    %server_finished = ();
    %received_for = ();
    @accepted = ();
    @clients = ();

    ok(!(grep { defined $_ } @weak_clients), 'dropping client Endpoints destroys retired Connections');
    ok(!(grep { defined $_ } @weak_servers), 'retired server Connections have no hidden Endpoint ownership');

    my $weak_server = $server;
    weaken($weak_server);
    undef $server;

    ok(!defined($weak_server), 'server Endpoint destroys cleanly after all retirement');
};

done_testing;
