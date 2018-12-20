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

$SIG{'PIPE'} = 'IGNORE';

# Just for demonstration purposes. Endianness
# should not matter.
$dbus->big_endian(1);

$dbus->blocking(0);

my $fileno = $dbus->fileno();

# You can use whatever polling method you prefer;
# the following is quick and easy:
vec( my $mask, $fileno, 1 ) = 1;

while (!$dbus->initialize()) {
    if ($dbus->init_pending_send()) {
        select( undef, my $wout = $mask, undef, undef );
    }
    else {
        select( my $rout = $mask, undef, undef, undef );
    }
}

printf "done authn; connection name: %s\n", $dbus->get_connection_name();

#----------------------------------------------------------------------

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

while (!$got_response) {
    my $win = $dbus->pending_send() || q<>;
    $win &&= $mask;

    select( my $rout = $mask, $win, undef, undef );
    $dbus->flush_write_queue() if $win;
    1 while $dbus->get_message();
}
