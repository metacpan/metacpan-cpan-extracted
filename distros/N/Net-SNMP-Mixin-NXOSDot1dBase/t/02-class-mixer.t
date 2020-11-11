#!perl

use strict;
use warnings;
use Test::More;

eval "use Net::SNMP";
plan skip_all => "Net::SNMP required for testing Net::SNMP::Mixin module"
  if $@;

eval "use Net::SNMP::Mixin";
plan skip_all =>
  "Net::SNMP::Mixin required for testing Net::SNMP::Mixin module"
  if $@;

plan tests => 14;

is( Net::SNMP->mixer('Net::SNMP::Mixin::NXOSDot1dBase'),
  'Net::SNMP', 'mixer returns the class name' );
ok(
  Net::SNMP->can('get_dot1d_base_group'),
  'get_dot1d_base_group() is now a class method'
);
ok(
  Net::SNMP->can('map_bridge_ports2if_indexes'),
  'map_bridge_ports2if_indexes() is now a class method'
);
ok(
  Net::SNMP->can('map_if_indexes2bridge_ports'),
  'map_if_indexes2bridge_ports() is now a class method'
);

eval {Net::SNMP->mixer('Net::SNMP::Mixin::NXOSDot1dBase')};
like( $@, qr/already mixed into/, 'mixed in twice is an error' );

my ( $session, $error ) = Net::SNMP->session( hostname => '127.0.0.1', );

ok( !$error, 'snmp session created without error' );
isa_ok( $session, 'Net::SNMP' );

# already mixed in as a class mixin
eval {$session->mixer("Net::SNMP::Mixin::NXOSDot1dBase")};
like( $@, qr/already mixed into/, 'mixed in twice is an error' );

ok( $session->can('get_dot1d_base_group'), '$session can get_dot1d_base_group' );
ok( $session->can('map_bridge_ports2if_indexes'), '$session can map_bridge_ports2if_indexes' );
ok( $session->can('map_if_indexes2bridge_ports'), '$session can map_if_indexes2bridge_ports' );

eval {$session->get_dot1d_base_group};
like( $@, qr/not initialized/i, 'not initialized' );

eval {$session->map_bridge_ports2if_indexes};
like( $@, qr/not initialized/i, 'not initialized' );

eval {$session->map_if_indexes2bridge_ports};
like( $@, qr/not initialized/i, 'not initialized' );

# vim: ft=perl sw=2
