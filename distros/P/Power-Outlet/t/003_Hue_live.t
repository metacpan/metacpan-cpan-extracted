# -*- perl -*-

use strict;
use warnings;
my $lamps=3;
use Test::More tests => 1 + 16 * 3;
my $skip=16 * $lamps;

BEGIN { use_ok( 'Power::Outlet::Hue' ); }

my $host     = $ENV{"NET_HUE_HOST"}     || undef;
my $port     = $ENV{"NET_HUE_PORT"}     || undef;
my $username = $ENV{"NET_HUE_USERNAME"} || undef;
my $names    = $ENV{"NET_HUE_NAMES"}    || "Hue Lamp 1,Hue Lamp 2,Hue Lamp 3"; #my devices defaults...

my %name=(); @name{1 .. $lamps}=split(/,/, $names);

SKIP: {
  unless ($host) {
    my $text='$ENV{"NET_HUE_HOST"} not set skipping live tests';
    diag($text);
    skip $text, $skip;
  }


  foreach my $id (1 .. $lamps) {
    diag("\n\nOutlet: $id\n\n");

    my $device=Power::Outlet::Hue->new(host=>$host, id=>$id, username=>$username, port=>$port);
    is($device->id, $id, 'id');
    is($device->host, $host, 'host');
    is($device->port, $port, 'port');
    is($device->username, "newdeveloper", 'username');
    is($device->name, $name{$id}, 'name');

    isa_ok ($device, 'Power::Outlet::Hue');
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
    is($device->cycle, "OFF", 'cycle method'); #blocking
    is($device->query, "OFF", 'query method');

    if ($state eq "ON") {
      diag("Turning On");
      $device->on;
    }
  }
}
