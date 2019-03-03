#!/usr/bin/env perl

use strict;
use warnings;
use autodie;

use Socket;

use Data::Dumper;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Protocol::DBus::Client;

my $dbus = $> ? Protocol::DBus::Client::login_session() : Protocol::DBus::Client::system();

$dbus->initialize();

# Wait for the initial hello acknowledgement
# so we know our connnection name.
$dbus->get_message();

for my $func ( qw( GetConnectionUnixUser GetConnectionCredentials ) ) {
    print "$func:\n";

    my $got_response;

    $dbus->send_call(
        path => '/org/freedesktop/DBus',
        interface => 'org.freedesktop.DBus',
        destination => 'org.freedesktop.DBus',
        signature => 's',
        member => $func,
        body => [ $dbus->get_unique_bus_name() ],
    )->then( sub {
        $got_response = 1;
        print Dumper shift;
    } );

    $dbus->get_message() while !$got_response;
}
