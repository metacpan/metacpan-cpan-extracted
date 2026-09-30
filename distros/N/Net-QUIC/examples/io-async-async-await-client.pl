#!/usr/bin/env perl

use strict;
use warnings;

use Future::AsyncAwait;
use IO::Async::Loop;
use IO::Socket::INET;

use Net::QUIC::Driver;

my ($host, $port, $alpn, $server_name, $ca_file, $message) = @ARGV;

$host        = '127.0.0.1'        if !defined $host;
$port        = 4433               if !defined $port;
$alpn        = 'net-quic-example' if !defined $alpn;
$server_name = $host              if !defined $server_name;
$ca_file     = undef              if defined($ca_file) && $ca_file eq '-';
$message     = "hello from IO::Async + Future::AsyncAwait\n"
    if !defined $message;

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

my $loop = IO::Async::Loop->new;

my $driver;
my $connection;

my @udp_out;
my $write_watched = 0;
my $timer_id;

my @change_waiters;

sub state_changed {
    my @ready = splice @change_waiters;

    for my $future (@ready) {
        $future->done
            if !$future->is_ready;
    }

    return;
}

sub wait_for_change {
    my $future = $loop->new_future;

    push @change_waiters, $future;

    return $future;
}

sub stop_write_watch {
    return if !$write_watched;

    $loop->unwatch_io(
        handle         => $socket,
        on_write_ready => 1,
    );

    $write_watched = 0;
    return;
}

sub flush_udp {
    while (@udp_out) {
        my $bytes = $udp_out[0];

        my $sent = send($socket, $bytes, 0);

        if (!defined $sent) {
            return 0
                if $!{EAGAIN} || $!{EWOULDBLOCK};

            die "UDP send failed: $!\n";
        }

        die "UDP send was partial\n"
            if $sent != length($bytes);

        shift @udp_out;
    }

    stop_write_watch();

    return 1;
}

sub start_write_watch {
    return if $write_watched;

    $write_watched = 1;

    $loop->watch_io(
        handle => $socket,

        on_write_ready => sub {
            return if !flush_udp();

            $driver->writable;
            state_changed();
        },
    );

    return;
}

my %driver_args = (
    local       => $local,
    peer        => $peer,
    alpn        => $alpn,
    server_name => $server_name,

    send => sub {
        my ($datagram) = @_;

        push @udp_out, $datagram->data;

        if (!flush_udp()) {
            start_write_watch();
            return 0;
        }

        return 1;
    },

    set_timeout => sub {
        my ($seconds) = @_;

        if (defined $timer_id) {
            $loop->unwatch_time($timer_id);
            undef $timer_id;
        }

        if (defined $seconds) {
            $timer_id = $loop->watch_time(
                after => $seconds,

                code => sub {
                    undef $timer_id;

                    $driver->timeout;
                    state_changed();
                },
            );
        }

        return;
    },
);

$driver_args{ca_file} = $ca_file
    if defined $ca_file;

$driver = Net::QUIC::Driver->client(%driver_args);
$connection = $driver->connection;

$connection->on_stream_available(sub {
    state_changed();
});

$loop->watch_io(
    handle => $socket,

    on_read_ready => sub {
        my $bytes = '';
        my $from = recv($socket, $bytes, 65_535, 0);

        if (!defined $from) {
            return if $!{EAGAIN} || $!{EWOULDBLOCK};
            die "UDP receive failed: $!\n";
        }

        $driver->receive(
            $bytes,
            $local,
            $from,
        );

        state_changed();
    },
);

sub connection_failure {
    my $info = $connection->close_info;

    return if !defined $info;
    return if $info->{type} eq 'application'
        && $info->{initiator} eq 'local';

    return "$info->{type} ($info->{initiator}) code=$info->{code}";
}

async sub wait_for_handshake {
    while (!$connection->ready) {
        my $failure = connection_failure();

        die "connection failed during handshake: $failure\n"
            if defined $failure;

        await wait_for_change();
    }

    return;
}

async sub open_bidi_stream {
    while (1) {
        my $stream = $connection->open_bidi_stream;

        return $stream
            if defined $stream;

        my $failure = connection_failure();

        die "connection closed while waiting for stream credit: $failure\n"
            if defined $failure;

        await wait_for_change();
    }
}

async sub read_until_fin {
    my ($stream) = @_;

    my $reply = '';

    while (1) {
        while (defined(my $bytes = $stream->next_data)) {
            $reply .= $bytes;
        }

        return $reply
            if $stream->remote_finished;

        my $failure = connection_failure();

        die "connection closed while reading: $failure\n"
            if defined $failure;

        await wait_for_change();
    }
}

async sub wait_for_connection_close {
    while (!$connection->closed) {
        await wait_for_change();
    }

    return;
}

async sub run_client {
    await wait_for_handshake();

    my $stream = await open_bidi_stream();

    $stream->send($message);
    $stream->finish;

    my $reply = await read_until_fin($stream);

    $connection->close;

    await wait_for_connection_close();

    return $reply;
}

$driver->start;

my $future = run_client();

$loop->await($future);

my $reply = $future->get;

print $reply;

close $socket;
