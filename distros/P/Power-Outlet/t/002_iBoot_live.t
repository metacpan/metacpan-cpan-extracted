# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 13;

BEGIN { use_ok( 'Power::Outlet::iBoot' ); }

my $host=$ENV{"NET_IBOOT_HOST"} || undef;
my $port=$ENV{"NET_IBOOT_PORT"} || undef;
my $pass=$ENV{"NET_IBOOT_PASS"} || undef;

SKIP: {
  unless ($host) {
    my $text='$ENV{"NET_IBOOT_HOST"} not set skipping live tests';
    diag($text);
    skip $text, 12;
  }

  my $device=Power::Outlet::iBoot->new(host=>$host, port=>$port, pass=>$pass);
  isa_ok ($device, 'Power::Outlet::iBoot');
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
