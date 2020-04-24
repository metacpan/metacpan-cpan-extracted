# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 15;

BEGIN { use_ok( 'Power::Outlet::SonoffDiy' ); }

my $host        = $ENV{"NET_SONOFFDIY_HOST"} || undef;

SKIP: {

  unless ($host) {
    my $text='$ENV{"NET_SONOFFDIY_HOST"} not set skipping live tests';
    diag($text);
    skip $text, 14;
  }

  my $device = Power::Outlet::SonoffDiy->new(host=>$host);

  is($device->host, $host, 'host');
  is($device->port, '8081', 'port');
  is($device->name, $host, 'name');

  isa_ok ($device, 'Power::Outlet::SonoffDiy');
  my $state = $device->query;
  if ($state eq "ON") {
    diag("Turning Off");
    $device->off;
    sleep 1;
  }

  diag("Turning On");
  is($device->on, "ON", 'on method');
  is($device->query, "ON", 'query method');
  sleep 1;

  diag("Turning Off");
  is($device->off, "OFF", 'off method');
  is($device->query, "OFF", 'query method');
  sleep 1;

  diag("Switching");
  is($device->switch, "ON", 'on method');
  is($device->query, "ON", 'query method');
  sleep 1;

  diag("Switching");
  is($device->switch, "OFF", 'off method');
  is($device->query, "OFF", 'query method');
  sleep 1;

  diag("Cycling");
  is($device->cycle, "OFF", 'cycle method'); #blocking
  is($device->query, "OFF", 'query method');

  if ($state eq "ON") {
    diag("Turning On");
    $device->on;
  }
}
