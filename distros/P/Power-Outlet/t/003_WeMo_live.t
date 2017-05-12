# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 1 + 16;
my $skip=16;

BEGIN { use_ok( 'Power::Outlet::WeMo' ); }

my $host = $ENV{"NET_WEMO_HOST"} || undef;
my $port = $ENV{"NET_WEMO_PORT"} || 49153; #default

SKIP: {
  unless ($host) {
    my $text='$ENV{"NET_WEMO_HOST"} not set skipping live tests';
    diag($text);
    skip $text, $skip;
  }

  my $device=Power::Outlet::WeMo->new(host=>$host, port=>$port);
  is($device->host, $host, 'host');
  is($device->port, $port, 'port');
  is($device->http_path, "/upnp/control/basicevent1", "http_path");

  isa_ok ($device, 'Power::Outlet::WeMo');
  my $state=$device->query;
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
  is($device->cycle, "CYCLE", 'cycle method');
  is($device->query, "CYCLE", 'query method');
  sleep 10; #assume set up "Cycle Time" = 10 seconds

  is($device->query, "OFF", 'query method');
  sleep 1;

  if ($state eq "ON") {
    diag("Turning On");
    $device->on;
  }
}
