#!/usr/bin/env perl

use strict;
use warnings;

use IO::Socket::INET;
use Mojo::IOLoop;

use Net::QUIC::Driver;

my ($host, $port, $alpn, $server_name, $ca_file, $message) = @ARGV;

$host        = '127.0.0.1'        if !defined $host;
$port        = 4433               if !defined $port;
$alpn        = 'net-quic-example' if !defined $alpn;
$server_name = $host              if !defined $server_name;
$ca_file     = undef              if defined($ca_file) && $ca_file eq '-';
$message     = "hello from Mojo::IOLoop\n" if !defined $message;

my $socket = IO::Socket::INET->new(
    PeerAddr => $host,
    PeerPort => $port,
    Proto    => 'udp',
) or die "could not create UDP socket: $!\n";

$socket->blocking(0);

my $local = getsockname($socket)
    or die "could not read local UDP address: $!\n";
my $peer = getpeername($socket)
    or die "could not read peer UDP address: $!\n";

my $loop = Mojo::IOLoop->singleton;
my $reactor = $loop->reactor;

my $driver;
my $connection;
my $stream;
my $closing = 0;
my $done = 0;

my @udp_out;
my $want_write = 0;
my $timer_id;

my ($enable_write, $disable_write, $flush_udp);
my $service_application;

my $stop = sub {
    return if $done++;
    $loop->stop;
};

$disable_write = sub {
    return if !$want_write;

    $want_write = 0;
    $reactor->watch($socket, 1, 0);
    return;
};

$flush_udp = sub {
    while (@udp_out) {
        my $bytes = $udp_out[0];

        my $sent = send($socket, $bytes, 0);

        if (!defined $sent) {
            return 0 if $!{EAGAIN} || $!{EWOULDBLOCK};
            die "UDP send failed: $!\n";
        }

        die "UDP send was partial\n"
            if $sent != length($bytes);

        shift @udp_out;
    }

    $disable_write->();
    return 1;
};

$enable_write = sub {
    return if $want_write;

    $want_write = 1;
    $reactor->watch($socket, 1, 1);
    return;
};

$service_application = sub {
    return if $done;

    my $info = $connection->close_info;

    if (defined($info) && !$closing) {
        warn "connection ended: $info->{type} ($info->{initiator}) code=$info->{code}\n";
        $stop->();
        return;
    }

    return if !$connection->ready;

    if (!defined($stream) && !$closing) {
        $stream = $connection->open_bidi_stream;
        return if !defined $stream;

        $stream->send($message);
        $stream->finish;
    }

    if (defined $stream) {
        while (defined(my $bytes = $stream->next_data)) {
            print $bytes;
        }

        if ($stream->remote_finished && !$closing) {
            $closing = 1;
            $connection->close;
        }
    }

    $stop->()
        if $closing && $connection->closed;

    return;
};

my %driver_args = (
    local       => $local,
    peer        => $peer,
    alpn        => $alpn,
    server_name => $server_name,

    send => sub {
        my ($datagram) = @_;

        push @udp_out, $datagram->data;

        if (!$flush_udp->()) {
            $enable_write->();
            return 0;
        }

        return 1;
    },

    set_timeout => sub {
        my ($seconds) = @_;

        if (defined $timer_id) {
            $loop->remove($timer_id);
            undef $timer_id;
        }

        if (defined $seconds) {
            $timer_id = $loop->timer(
                $seconds => sub {
                    undef $timer_id;
                    $driver->timeout;
                    $service_application->();
                },
            );
        }

        return;
    },
);

$driver_args{ca_file} = $ca_file if defined $ca_file;

$driver = Net::QUIC::Driver->client(%driver_args);
$connection = $driver->connection;

$connection->on_stream_available(sub {
    $service_application->();
});

$reactor->io(
    $socket => sub {
        my ($reactor, $writable) = @_;

        if ($writable) {
            return if !$flush_udp->();

            $driver->writable;
            $service_application->();
            return;
        }

        my $bytes = '';
        my $from = recv($socket, $bytes, 65_535, 0);

        if (!defined $from) {
            return if $!{EAGAIN} || $!{EWOULDBLOCK};
            die "UDP receive failed: $!\n";
        }

        $driver->receive($bytes, $local, $from);
        $service_application->();
    },
)->watch($socket, 1, 0);

$driver->start;
$service_application->();

$loop->start if !$loop->is_running;

close $socket;
