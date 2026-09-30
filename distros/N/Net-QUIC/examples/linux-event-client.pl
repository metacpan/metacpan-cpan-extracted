#!/usr/bin/env perl

use v5.36;
use strict;
use warnings;

use Linux::Event::IO::Sock::Dgram;
use Linux::Event::Kernel::Timer;
use Linux::Event::Loop;

use Net::QUIC::Driver;

my ($host, $port, $alpn, $server_name, $ca_file, $message) = @ARGV;

$host        = '127.0.0.1'        if !defined $host;
$port        = 4433               if !defined $port;
$alpn        = 'net-quic-example' if !defined $alpn;
$server_name = $host              if !defined $server_name;
$ca_file     = undef              if defined($ca_file) && $ca_file eq '-';
$message     = "hello from Linux::Event\n" if !defined $message;

my $loop = Linux::Event::Loop->new;

my $driver;
my $connection;
my $stream;
my $quic_timer;
my $closing = 0;
my $done = 0;

my $service_application;

my $stop = sub {
    return if $done++;
    $loop->stop;
};

$service_application = sub {
    return if $done || !defined $connection;

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

my $socket = Linux::Event::IO::Sock::Dgram->connect(
    loop => $loop,
    host => $host,
    port => $port,

    on_ready => sub ($socket) {
        my %driver_args = (
            local       => $socket->local->sockaddr,
            peer        => $socket->peer->sockaddr,
            alpn        => $alpn,
            server_name => $server_name,

            send => sub ($datagram) {
                return $socket->send($datagram->data);
            },

            set_timeout => sub ($seconds) {
                if (defined($quic_timer) && $quic_timer->is_active) {
                    $quic_timer->cancel;
                }

                undef $quic_timer;

                if (defined $seconds) {
                    $quic_timer = Linux::Event::Kernel::Timer->new(
                        loop  => $loop,
                        after => $seconds,

                        on_timer => sub ($timer) {
                            undef $quic_timer;
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

        $driver->start;
        $service_application->();
    },

    on_datagram => sub ($socket, $payload, $peer) {
        return if !defined $driver;

        $driver->receive(
            $payload,
            $socket->local->sockaddr,
            $peer->sockaddr,
        );

        $service_application->();
    },

    on_drain => sub ($socket) {
        return if !defined $driver;

        $driver->writable;
        $service_application->();
    },

    on_error => sub ($socket, $error) {
        die "UDP error: $error\n";
    },
);

$loop->run;

$socket->close if $socket->is_active;
