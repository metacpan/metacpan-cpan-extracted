use strict;
use warnings;

use FindBin ();
use Socket qw(inet_aton pack_sockaddr_in);
use Test2::V0;
use Time::HiRes qw(sleep);

use Net::QUIC::Endpoint;

my $cert_file = "$FindBin::Bin/data/server-cert.pem";
my $key_file = "$FindBin::Bin/data/server-key.pem";
my $alpn = 'net-quic-ecn-test';

sub make_pair {
    my ($client_port, $server_port) = @_;

    my $client_local = pack_sockaddr_in(
        $client_port,
        inet_aton('127.0.0.1'),
    );
    my $server_local = pack_sockaddr_in(
        $server_port,
        inet_aton('127.0.0.1'),
    );

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

    return ($client, $server);
}

sub pump {
    my ($client, $server, %args) = @_;
    my $progress = 0;
    my $accepted = $args{accepted};
    my $client_marks = $args{client_marks};
    my $server_marks = $args{server_marks};
    my $strip = $args{strip} ? 1 : 0;

    while (my $datagram = $server->next_datagram) {
        ++$progress;
        push @$server_marks, $datagram->ecn if $server_marks;

        $client->receive_datagram(
            $datagram->data,
            $datagram->peer,
            $datagram->local,
            $strip ? 0 : $datagram->ecn,
        );
    }

    while (my $datagram = $client->next_datagram) {
        ++$progress;
        push @$client_marks, $datagram->ecn if $client_marks;

        $server->receive_datagram(
            $datagram->data,
            $datagram->peer,
            $datagram->local,
            $strip ? 0 : $datagram->ecn,
        );
    }

    $$accepted ||= $server->next_connection if $accepted;

    my @wait;

    my $client_after = $client->timeout_after;
    if (defined($client_after) && $client_after <= 0) {
        ++$progress;
        $client->handle_timeout;
    } elsif (defined($client_after) && $client_after > 0) {
        push @wait, $client_after;
    }

    my $server_after = $server->timeout_after;
    if (defined($server_after) && $server_after <= 0) {
        ++$progress;
        $server->handle_timeout;
    } elsif (defined($server_after) && $server_after > 0) {
        push @wait, $server_after;
    }

    if (!$progress && @wait) {
        @wait = sort { $a <=> $b } @wait;
        my $nap = $wait[0] > 0.01 ? 0.01 : $wait[0] + 0.001;
        sleep($nap);
        ++$progress;
    }

    return $progress;
}

{
    my ($client, $server) = make_pair(40500, 4500);
    my (@client_marks, @server_marks);
    my $accepted;

    for (1 .. 1000) {
        pump(
            $client,
            $server,
            accepted     => \$accepted,
            client_marks => \@client_marks,
            server_marks => \@server_marks,
        );

        last if $accepted
            && $client->connection->ready
            && $accepted->ready;
    }

    ok($accepted, 'ECN-preserving server accepts connection');
    ok($client->connection->ready, 'ECN-preserving client handshake completes');
    ok($accepted->ready, 'ECN-preserving server handshake completes');

    ok(
        scalar(grep { $_ == 2 } @client_marks),
        'client emits ECT(0) while validating ECN',
    );
    ok(
        scalar(grep { $_ == 2 } @server_marks),
        'server emits ECT(0) while validating ECN',
    );

    my $stream = $client->connection->open_bidi_stream;
    isa_ok($stream, ['Net::QUIC::Stream']);
    $stream->send('x' x 131072);
    $stream->finish;

    @client_marks = ();
    @server_marks = ();

    for (1 .. 1500) {
        pump(
            $client,
            $server,
            accepted     => \$accepted,
            client_marks => \@client_marks,
            server_marks => \@server_marks,
        );

        last if @client_marks >= 20 && @server_marks >= 5;
    }

    ok(
        scalar(grep { $_ == 2 } @client_marks),
        'client continues ECT(0) after successful ECN feedback',
    );
    ok(
        !scalar(grep { $_ < 0 || $_ > 3 } @client_marks),
        'all client transmit ECN values are valid wire codepoints',
    );
    ok(
        !scalar(grep { $_ < 0 || $_ > 3 } @server_marks),
        'all server transmit ECN values are valid wire codepoints',
    );

    like(
        dies {
            $client->receive_datagram(
                "x",
                pack_sockaddr_in(40500, inet_aton('127.0.0.1')),
                pack_sockaddr_in(4500, inet_aton('127.0.0.1')),
                4,
            );
        },
        qr/ECN codepoint must be an integer from 0 through 3/,
        'invalid received ECN codepoint is rejected',
    );
}

{
    my ($client, $server) = make_pair(40501, 4501);
    my (@client_marks, @server_marks);
    my $accepted;

    for (1 .. 1000) {
        pump(
            $client,
            $server,
            accepted     => \$accepted,
            client_marks => \@client_marks,
            server_marks => \@server_marks,
            strip        => 1,
        );

        last if $accepted
            && $client->connection->ready
            && $accepted->ready;
    }

    ok($accepted, 'ECN-stripping server accepts connection');
    ok($client->connection->ready, 'ECN-stripping client handshake completes');
    ok(
        scalar(grep { $_ == 2 } @client_marks),
        'client initially attempts ECT(0) on stripping path',
    );

    my $stream = $client->connection->open_bidi_stream;
    $stream->send('y' x 131072);
    $stream->finish;

    @client_marks = ();

    for (1 .. 2000) {
        pump(
            $client,
            $server,
            accepted     => \$accepted,
            client_marks => \@client_marks,
            strip        => 1,
        );

        last if @client_marks >= 20
            && !scalar(grep { $_ == 2 } @client_marks[-5 .. -1]);
    }

    cmp_ok(
        scalar(@client_marks),
        '>=',
        5,
        'client emits enough packets to observe ECN fallback',
    );

    my @tail = @client_marks >= 5
        ? @client_marks[-5 .. -1]
        : @client_marks;

    ok(
        @tail && !scalar(grep { $_ != 0 } @tail),
        'ngtcp2 falls back to Not-ECT when the path strips ECN feedback',
    );
}

done_testing;
