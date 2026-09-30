#!/usr/bin/env perl

use strict;
use warnings;

use EV;
use IO::Socket::INET;

use Net::QUIC::Driver;

my ($host, $port, $alpn, $server_name, $ca_file, $message) = @ARGV;

$host        = '127.0.0.1'        if !defined $host;
$port        = 4433               if !defined $port;
$alpn        = 'net-quic-example' if !defined $alpn;
$server_name = $host              if !defined $server_name;
$ca_file     = undef              if defined($ca_file) && $ca_file eq '-';
$message     = "hello from EV\n" if !defined $message;

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

my $driver;
my $connection;
my $stream;
my $closing = 0;
my $done = 0;

my @udp_out;
my $read_watcher;
my $write_watcher;
my $timer_watcher;

my ($enable_write, $disable_write, $flush_udp);
my $service_application;

my $stop = sub {
    return if $done++;
    EV::break(EV::BREAK_ALL);
};

$disable_write = sub {
    undef $write_watcher;
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
    return if defined $write_watcher;

    $write_watcher = EV::io(
        $socket,
        EV::WRITE,
        sub {
            return if !$flush_udp->();

            $driver->writable;
            $service_application->();
        },
    );

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

        undef $timer_watcher;

        if (defined $seconds) {
            $timer_watcher = EV::timer(
                $seconds,
                0,
                sub {
                    undef $timer_watcher;
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

$read_watcher = EV::io(
    $socket,
    EV::READ,
    sub {
        my $bytes = '';
        my $from = recv($socket, $bytes, 65_535, 0);

        if (!defined $from) {
            return if $!{EAGAIN} || $!{EWOULDBLOCK};
            die "UDP receive failed: $!\n";
        }

        $driver->receive($bytes, $local, $from);
        $service_application->();
    },
);

$driver->start;
$service_application->();

EV::run;

close $socket;
