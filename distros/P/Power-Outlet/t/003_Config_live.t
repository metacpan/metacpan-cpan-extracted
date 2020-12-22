# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 15;

BEGIN { use_ok( 'Power::Outlet::Config' ); }

my $ini_file = "$0.ini";
my $id       = 99;
my $name     = "My Name";

{
  my $device = Power::Outlet::Config->new(section=>"My Virtual", ini_file=>$ini_file);
  isa_ok ($device, 'Power::Outlet::Virtual');
  is($device->id, $id, 'id');
  is($device->name, $name, 'name');
  my $state  = $device->query;
  if ($state eq "ON") {
    diag("Turning Off");
    $device->off;
  }

  diag("Turning On");
  is($device->on, "ON", 'on method');
  is($device->query, "ON", 'query method');

  diag("Turning Off");
  is($device->off, "OFF", 'off method');
  is($device->query, "OFF", 'query method');

  diag("Switching");
  is($device->switch, "ON", 'on method');
  is($device->query, "ON", 'query method');

  diag("Switching");
  is($device->switch, "OFF", 'off method');
  is($device->query, "OFF", 'query method');

  diag("Cycling");
  is($device->cycle, "OFF", 'cycle method');
  is($device->query, "OFF", 'query method');

  is($device->query, "OFF", 'query method');

  if ($state eq "ON") {
    diag("Turning On");
    $device->on;
  }
}
