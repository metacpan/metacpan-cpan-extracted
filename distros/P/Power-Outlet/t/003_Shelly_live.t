# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 31;

BEGIN { use_ok( 'Power::Outlet::Shelly' ); }

my $host        = $ENV{"NET_SHELLY_HOST"}     || undef;
my $port        = $ENV{"NET_SHELLY_PORT"}     || 80;

{
  my $device = Power::Outlet::Shelly->new(name=>"my name");
  isa_ok($device, 'Power::Outlet::Shelly');
  can_ok($device, 'new');
  can_ok($device, 'index');
  can_ok($device, 'url');
  can_ok($device, 'on');
  can_ok($device, 'off');
  can_ok($device, 'cycle');
  can_ok($device, 'switch');
  can_ok($device, 'host');
  can_ok($device, 'port');
  is($device->style, 'relay', 'style defualt');
  is($device->index, 0, 'index defualt');
  is($device->port, 80, 'port default');
  is($device->host('this_host.should_not.exist'), 'this_host.should_not.exist', 'host set');
  is($device->name, "my name", 'name set should not hit host');
}

SKIP: {

  unless ($host) {
    my $text = '$ENV{"NET_SHELLY_HOST"} not set skipping live tests';
    diag($text);
    skip $text, 15;
  }

  my $index  = 0;
  my $device = Power::Outlet::Shelly->new(host=>$host, port=>$port, index=>$index, cycle_duration=>2.5);

  diag("\nIndex: $index\n\n");

  is($device->index, $index, 'index');
  is($device->host, $host, 'host');
  is($device->port, $port, 'port');
  is($device->name, 'my name', 'name');

  isa_ok($device, 'Power::Outlet::Shelly');
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
  is($device->cycle, "OFF", 'cycle method'); #non-blocking....
  sleep 5;
  is($device->query, "OFF", 'query method');

  if ($state eq "ON") {
    diag("Turning On");
    $device->on;
  }
}
