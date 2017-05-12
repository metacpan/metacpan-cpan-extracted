# -*- perl -*-
use Test::More tests => 11;

use strict;
use warnings;

BEGIN {
        use_ok('Net::DBus::Binding::Server');
        use_ok('Net::DBus::Binding::Connection');
        use_ok('Net::DBus::Reactor');
        use_ok('Net::DBus::Binding::Message::Signal');
}


my $server = Net::DBus::Binding::Server->new(address => "unix:path=/tmp/dbus-perl-test-$$");
ok ($server->is_connected, "server connected");

my $reactor = Net::DBus::Reactor->new();
$reactor->manage($server);

my $incoming;
$server->set_connection_callback(sub {
  $server = shift;
  $incoming = shift;
});

my $client = Net::DBus::Binding::Connection->new(address => "unix:path=/tmp/dbus-perl-test-$$",
						 private => 1);
ok ($client->is_connected, "client connected");
$reactor->manage($client);

$reactor->{running} = 1;
$reactor->step;

ok (defined $incoming, "incoming");
ok ($incoming->is_connected, "incoming connected");
#$reactor->manage($incoming);

$client->disconnect;
ok (!$client->is_connected, "client disconnected");

$incoming->disconnect;
ok (!$incoming->is_connected, "incoming disconnected");

$server->disconnect;
ok (!$server->is_connected, "server disconnected");
