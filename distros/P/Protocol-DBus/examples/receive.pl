#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Socket;

# bug in this module: it breaks when loaded dynamically
use Socket::MsgHdr;

use Data::Dumper;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Protocol::DBus::Client;

my $dbus = Protocol::DBus::Client::system();

$dbus->do_authn();

$dbus->send_call(
    member => 'AddMatch',
    signature => 's',
    destination => 'org.freedesktop.DBus',
    interface => 'org.freedesktop.DBus',
    path => '/org/freedesktop/DBus',
    body => [
       "type='signal'",
    ]
);

print Dumper( $dbus->get_message() ) while 1;
