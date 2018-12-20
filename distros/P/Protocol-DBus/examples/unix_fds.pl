#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Socket;

# Required for unix FD support
use Socket::MsgHdr;

use Data::Dumper;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Protocol::DBus::Client;

my $dbus = $> ? Protocol::DBus::Client::login_session() : Protocol::DBus::Client::system();

# $dbus->big_endian(1);

$dbus->initialize();

my $signal_name = 'ProtocolDBusFDPass';

$dbus->send_call(
    member => 'AddMatch',
    signature => 's',
    destination => 'org.freedesktop.DBus',
    interface => 'org.freedesktop.DBus',
    path => '/org/freedesktop/DBus',
    body => [
       "type=signal,member=$signal_name",
    ]
);

$dbus->get_message();

my $recv_name = $dbus->get_connection_name();

my $pid = fork or do {
    my $dbus = my $dbus = $> ? Protocol::DBus::Client::login_session() ? Protocol::DBus::Client::system();

    $dbus->initialize();

    pipe( my $r, my $w );

    $dbus->send_signal(
        member => $signal_name,
        signature => 'h',
        destination => $recv_name,
        interface => 'org.freedesktop.DBus',
        path => '/org/freedesktop/DBus',
        body => [$w],
    );

    print "$$ receives: " . <$r>;

    exit;
};

close STDOUT;

while (1) {
    my $msg = $dbus->get_message();

    my ($fh) = $msg->get_body() && @{ $msg->get_body() };
    next if 'GLOB' ne ref $fh;

    syswrite $fh, "Hello from PID $$ at " . localtime . $/;
    last;
}

waitpid $pid, 0;
