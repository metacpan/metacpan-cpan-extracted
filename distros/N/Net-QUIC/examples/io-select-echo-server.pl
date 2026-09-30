#!/usr/bin/env perl

use strict;
use warnings;

use IO::Select;
use IO::Socket::INET;
use Scalar::Util qw(refaddr);
use Time::HiRes qw(time);

use Net::QUIC::Driver;

$| = 1;

my ($host, $port, $alpn, $cert_file, $key_file) = @ARGV;

$host      = '127.0.0.1'      if !defined $host;
$port      = 4433             if !defined $port;
$alpn      = 'net-quic-example' if !defined $alpn;
$cert_file = 't/data/server-cert.pem' if !defined $cert_file;
$key_file  = 't/data/server-key.pem'  if !defined $key_file;

die "this simple example requires a concrete bind address; "
    . "wildcard QUIC servers need destination-address packet info\n"
    if $host eq '0.0.0.0' || $host eq '::';

die "certificate file not found: $cert_file\n" if !-f $cert_file;
die "private key file not found: $key_file\n" if !-f $key_file;

my $socket = IO::Socket::INET->new(
    LocalAddr => $host,
    LocalPort => $port,
    Proto     => 'udp',
) or die "could not create UDP socket: $!\n";

$socket->blocking(0);

my $readable = IO::Select->new($socket);
my $writable = IO::Select->new;

my @udp_out;
my $deadline;
my $running = 1;
my $driver;

my @connections;
my %streams_for;
my %stream_finished;

sub flush_udp {
    while (@udp_out) {
        my $datagram = $udp_out[0];

        my $sent = send(
            $socket,
            $datagram->data,
            0,
            $datagram->peer,
        );

        if (!defined $sent) {
            return 0 if $!{EAGAIN} || $!{EWOULDBLOCK};
            die "UDP send failed: $!\n";
        }

        die "UDP send was partial\n"
            if $sent != length($datagram->data);

        shift @udp_out;
    }

    $writable->remove($socket);
    return 1;
}

sub service_application {
    while (my $connection = $driver->next_connection) {
        push @connections, $connection;
        $streams_for{refaddr($connection)} = [];
    }

    for my $connection (@connections) {
        my $connection_id = refaddr($connection);
        my $streams = $streams_for{$connection_id} ||= [];

        while (my $stream = $connection->next_stream) {
            push @$streams, $stream;
        }

        for my $stream (@$streams) {
            while (defined(my $bytes = $stream->next_data)) {
                $stream->send($bytes) if $stream->can_send;
            }

            if (
                $stream->remote_finished
                && $stream->can_send
                && !$stream_finished{refaddr($stream)}
            ) {
                $stream_finished{refaddr($stream)} = 1;
                $stream->finish;
            }
        }

        @$streams = grep {
            if ($_->closed) {
                delete $stream_finished{refaddr($_)};
                0;
            } else {
                1;
            }
        } @$streams;
    }

    @connections = grep {
        if ($_->closed) {
            delete $streams_for{refaddr($_)};
            0;
        } else {
            1;
        }
    } @connections;

    return;
}

$driver = Net::QUIC::Driver->server(
    alpn             => $alpn,
    certificate_file => $cert_file,
    private_key_file => $key_file,

    send => sub {
        my ($datagram) = @_;

        push @udp_out, $datagram;

        if (!flush_udp()) {
            $writable->add($socket);
            return 0;
        }

        return 1;
    },

    set_timeout => sub {
        my ($seconds) = @_;

        $deadline = defined($seconds)
            ? time() + $seconds
            : undef;

        return;
    },
);

$SIG{INT} = sub { $running = 0 };

$driver->start;

print "QUIC echo server listening on $host:$port\n";
print "ALPN: $alpn\n";
print "Press Ctrl-C to stop.\n";

while ($running) {
    service_application();

    my $wait = 1;

    if (defined $deadline) {
        my $remaining = $deadline - time();
        $remaining = 0 if $remaining < 0;
        $wait = $remaining if $remaining < $wait;
    }

    my ($read_ready, $write_ready) = IO::Select->select(
        $readable,
        $writable,
        undef,
        $wait,
    );

    if ($read_ready && @$read_ready) {
        my $bytes = '';
        my $peer = recv($socket, $bytes, 65_535, 0);

        if (!defined $peer) {
            die "UDP receive failed: $!\n"
                if !$!{EAGAIN} && !$!{EWOULDBLOCK};
        } else {
            my $local = getsockname($socket)
                or die "could not read local UDP address: $!\n";

            $driver->receive($bytes, $local, $peer);
        }
    }

    if ($write_ready && @$write_ready && flush_udp()) {
        $driver->writable;
    }

    if (defined($deadline) && $deadline <= time()) {
        $deadline = undef;
        $driver->timeout;
    }

    service_application();
}

close $socket;

print "Stopped.\n";
