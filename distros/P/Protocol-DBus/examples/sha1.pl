#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Socket;
use Protocol::DBus::Client;
use Protocol::DBus::Path;

use Data::Dumper;

my $path = Protocol::DBus::Path::login_session_message_bus();

my $addr = Socket::pack_sockaddr_un($path);

socket my $s, Socket::AF_UNIX, Socket::SOCK_STREAM, 0;
connect $s, $addr;

my $dbus = Protocol::DBus::Client->new(
    authn_mechanism => 'DBUS_COOKIE_SHA1',
    socket => $s,
);

$dbus->initialize();

my $got_response;

$dbus->send_call(
    path => '/org/freedesktop/DBus',
    interface => 'org.freedesktop.DBus.Properties',
    destination => 'org.freedesktop.DBus',
    signature => 's',
    member => 'GetAll',
    body => ['org.freedesktop.DBus'],
    on_return => sub {
        $got_response = 1;
        print "got getall response\n";
        print Dumper shift;
    },
);

$dbus->get_message() while !$got_response;
