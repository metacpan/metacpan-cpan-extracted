use strict;
use warnings;

use FindBin ();
use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;
use Time::HiRes qw(sleep);

use Net::QUIC::Endpoint;

my $server_local = pack_sockaddr_in(4450, inet_aton('127.0.0.1'));
my $client_local = pack_sockaddr_in(40050, inet_aton('127.0.0.1'));
my $alpn = 'net-quic-stream-limit-test';
my $cert_file = "$FindBin::Bin/data/server-cert.pem";
my $key_file = "$FindBin::Bin/data/server-key.pem";

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

like(
    dies { $client->connection->open_bidi_stream },
    qr/before the handshake is ready/,
    'opening before handshake remains an actual error',
);

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

            $server_after = $server->timeout_after;
            $server->handle_timeout
                if defined($server_after) && $server_after <= 0;

            $client_after = $client->timeout_after;
            $client->handle_timeout
                if defined($client_after) && $client_after <= 0;
        }
    }

    return $progress;
}

my $accepted;

for (1 .. 500) {
    pump_pair();
    $accepted ||= $server->next_connection;

    last if $accepted
        && $client->connection->ready
        && $accepted->ready;
}

ok($client->connection->ready, 'client handshake is ready');
ok($accepted && $accepted->ready, 'server handshake is ready');

my @available;
my %replacement;

$client->connection->on_stream_available(sub {
    my ($connection, $type) = @_;

    push @available, $type;

    if ($type eq 'bidi') {
        $replacement{bidi} = $connection->open_bidi_stream;
    } elsif ($type eq 'uni') {
        $replacement{uni} = $connection->open_uni_stream;
    }

    return;
});

like(
    dies {
        $client->connection->on_stream_available('not-a-callback');
    },
    qr/must be a coderef/,
    'stream availability callback is validated',
);

my @uni;
my $uni_blocked = 0;

for (1 .. 1000) {
    my $stream = $client->connection->open_uni_stream;

    if (!defined $stream) {
        $uni_blocked = 1;
        last;
    }

    push @uni, $stream;
}

ok($uni_blocked, 'unidirectional stream limit returns undef');
ok(@uni > 0, 'peer initially allows unidirectional streams');
ok(@uni < 1000, 'unidirectional limit is finite');
is(\@available, [], 'limit exhaustion alone does not fake availability');

my $released_uni_id = $uni[0]->id;
$uni[0]->finish;

my $server_uni;

for (1 .. 1000) {
    pump_pair();

    while (my $stream = $accepted->next_stream) {
        if ($stream->id == $released_uni_id) {
            $server_uni = $stream;
        }
    }

    if ($server_uni) {
        1 while defined $server_uni->next_data;
    }

    last if $replacement{uni};
}

ok($server_uni, 'server observes the released unidirectional stream');
ok(
    scalar(grep { $_ eq 'uni' } @available),
    'peer MAX_STREAMS increase reports unidirectional availability',
);
isa_ok(
    $replacement{uni},
    ['Net::QUIC::Stream'],
    'availability callback can immediately open a unidirectional stream',
);

my @bidi;
my $bidi_blocked = 0;

for (1 .. 1000) {
    my $stream = $client->connection->open_bidi_stream;

    if (!defined $stream) {
        $bidi_blocked = 1;
        last;
    }

    push @bidi, $stream;
}

ok($bidi_blocked, 'bidirectional stream limit returns undef');
ok(@bidi > 0, 'peer initially allows bidirectional streams');
ok(@bidi < 1000, 'bidirectional limit is finite');

my $released_bidi_id = $bidi[0]->id;
$bidi[0]->finish;

my $server_bidi;
my $server_bidi_finished = 0;

for (1 .. 1500) {
    pump_pair();

    while (my $stream = $accepted->next_stream) {
        if ($stream->id == $released_bidi_id) {
            $server_bidi = $stream;
        }
    }

    if ($server_bidi) {
        1 while defined $server_bidi->next_data;

        if ($server_bidi->remote_finished && !$server_bidi_finished) {
            $server_bidi->finish;
            $server_bidi_finished = 1;
        }
    }

    1 while defined $bidi[0]->next_data;

    last if $replacement{bidi};
}

ok($server_bidi, 'server observes the released bidirectional stream');
ok($server_bidi_finished, 'server closes its half of the bidirectional stream');
ok(
    scalar(grep { $_ eq 'bidi' } @available),
    'peer MAX_STREAMS increase reports bidirectional availability',
);
isa_ok(
    $replacement{bidi},
    ['Net::QUIC::Stream'],
    'availability callback can immediately open a bidirectional stream',
);

$client->connection->on_stream_available(undef);

done_testing;
