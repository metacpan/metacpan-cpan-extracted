# -*- perl -*-
use strict;
use warnings;
use Time::HiRes qw{sleep};
use Test::Warn;
use Test::More tests => 16 + 26;

#TODO: add tests for SSL
#TODO: add tests for auth

BEGIN { use_ok( 'Power::Outlet' ); }
BEGIN { use_ok( 'Power::Outlet::MQTT' ); }

my $host = $ENV{'MQTT_HOST'};
my $device = $ENV{'MQTT_DEVICE'};
my $skip = not ($host and $device);

my $obj = Power::Outlet::MQTT->new;
isa_ok ($obj, 'Power::Outlet::MQTT');
can_ok($obj, 'new');
can_ok($obj, 'host');
can_ok($obj, 'device');
can_ok($obj, 'relay');
can_ok($obj, 'name');
can_ok($obj, 'on');
can_ok($obj, 'off');
can_ok($obj, 'query');
can_ok($obj, 'switch');
can_ok($obj, 'cycle');
can_ok($obj, 'action');

{
  my $outlet = Power::Outlet::MQTT->new(host=>'397c4c5a-c78d-11ed-b50d-3417ebe27d0f');
  local $@;
  eval {$outlet->mqtt};
  my $error  = $@;
  $error =~ s/\s+\Z//;
  ok($error, 'bad mqtt host');
  like($error, qr/\AMQTT Error: connection/, 'bad mqtt host');
}

SKIP: {
  skip 'ENV MQTT_HOST, MQTT_DEVICE must be set', 26 if $skip;
  {
    my $outlet = Power::Outlet::MQTT->new(host=>$host, device=>$device, cycle_duration=>1);
    isa_ok($outlet->mqtt, 'Net::MQTT::Simple');
    can_ok($outlet->mqtt, 'one_shot'); #added by One_Shot_Loader

    is($outlet->host, $host, 'host');
    is($outlet->device, $device, 'device');
    is($outlet->port, '1883', 'port');

    is($outlet->publish_topic , "cmnd/$device/POWER1"       , 'publish_topic');
    is($outlet->publish_on    , "cmnd/$device/POWER1+ON"    , 'publish_on');
    is($outlet->publish_off   , "cmnd/$device/POWER1+OFF"   , 'publish_off');
    is($outlet->publish_switch, "cmnd/$device/POWER1+TOGGLE", 'publish_switch');
    is($outlet->publish_query , "cmnd/$device/POWER1+"      , 'publish_query');

    is($outlet->subscribe_topic    , "stat/$device/POWER1"  , 'subscribe_topic');
    isa_ok($outlet->subscribe_value_on,  'Regexp'         , 'subscribe_value_on');
    isa_ok($outlet->subscribe_value_off, 'Regexp'         , 'subscribe_value_off');
    is($outlet->subscribe_value_on('ON')  , 'ON'          , 'subscribe_value_on');
    is($outlet->subscribe_value_off('OFF'), 'OFF'         , 'subscribe_value_off');

    my $state = $outlet->query;
    if ($state eq 'ON') {
      diag('Turning Off');
      $outlet->off;
      sleep .25;
    }

    diag('Turning On');
    is($outlet->on, 'ON', 'on method');
    is($outlet->query, 'ON', 'query method');
    sleep .25;

    diag('Turning Off');
    is($outlet->off, 'OFF', 'off method');
    is($outlet->query, 'OFF', 'query method');
    sleep .25;

    diag('Switching');
    is($outlet->switch, 'ON', 'on method');
    is($outlet->query, 'ON', 'query method');
    sleep .25;

    diag('Switching');
    is($outlet->switch, 'OFF', 'off method');
    is($outlet->query, 'OFF', 'query method');
    sleep .25;

    diag('Cycling');
    is($outlet->cycle, 'OFF', 'cycle method'); #blocking
    is($outlet->query, 'OFF', 'query method');

    if ($state eq 'ON') {
      diag('Turning On');
      $outlet->on;
    }
  }

  {
    my $outlet = Power::Outlet::MQTT->new(host=>$host, device=>'aa529f62-c78b-11ed-96b8-3417ebe27d0f');
    warnings_like {$outlet->query} [qr/\AMQTT Error:/], 'bad device name';
  }
}
