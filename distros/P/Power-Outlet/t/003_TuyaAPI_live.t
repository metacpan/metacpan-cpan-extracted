# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 14 + 16;

BEGIN { use_ok( 'Power::Outlet' ); }
BEGIN { use_ok( 'Power::Outlet::TuyaAPI' ); }

my $host          = $ENV{'TUYA_HOST'};
my $client_id     = $ENV{'TUYA_CLIENT_ID'};
my $client_secret = $ENV{'TUYA_CLIENT_SECRET'};
my $deviceid      = $ENV{'TUYA_DEVICEID'};
my $relay         = $ENV{'TUYA_RELAY'} || 'switch_1';
my $name          = $ENV{'TUYA_NAME'};

my $skip          = not ($client_id and $client_secret and $deviceid and $relay);

my $obj = Power::Outlet::TuyaAPI->new;
isa_ok ($obj, 'Power::Outlet::TuyaAPI');
can_ok($obj, 'new');
can_ok($obj, 'host');
can_ok($obj, 'relay');
can_ok($obj, 'on');
can_ok($obj, 'off');
can_ok($obj, 'switch');
can_ok($obj, 'cycle');
can_ok($obj, 'action');
can_ok($obj, 'client_id');
can_ok($obj, 'client_secret');
can_ok($obj, 'deviceid');

SKIP: {
  skip "ENV TUYA_CLIENT_ID, TUYA_CLIENT_SECRET and TUYA_DEVICE must be set", 16 if $skip;

  my $device = Power::Outlet::TuyaAPI->new(client_id=>$client_id, client_secret=>$client_secret, deviceid=>$deviceid, host=>$host);

  is($device->relay, $relay, 'relay');
  is($device->host, $host, 'host');
  is($device->port, '443', 'port');
  is($device->client_id, $client_id, 'client_id');
  is($device->client_secret, $client_secret, 'client_secret');

  SKIP: {
    skip "ENV TUYA_NAME must be set", 1 unless $name;
    is($device->name, $name, 'name');
  }

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
