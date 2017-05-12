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

is( Net::SNMP->mixer('Net::SNMP::Mixin::Dot1qVlanStatic'),
  'Net::SNMP', 'mixer returns the class name' );
ok(
  Net::SNMP->can('map_vlan_static_ids2names'),
  'map_vlan_static_ids2names() is now a class method'
);
ok(
  Net::SNMP->can('map_vlan_static_ids2ports'),
  'map_vlan_static_ids2ports() is now a class method'
);
ok(
  Net::SNMP->can('map_vlan_static_ports2ids'),
  'map_vlan_static_ports2ids() is now a class method'
);

eval {Net::SNMP->mixer('Net::SNMP::Mixin::Dot1qVlanStatic')};
like( $@, qr/already mixed into/, 'mixed in twice is an error' );

my ( $session, $error ) = Net::SNMP->session( hostname => '127.0.0.1', );

ok( !$error, 'snmp session created without error' );
isa_ok( $session, 'Net::SNMP' );

# already mixed in as a class mixin
eval {$session->mixer("Net::SNMP::Mixin::Dot1qVlanStatic")};
like( $@, qr/already mixed into/, 'mixed in twice is an error' );

ok( $session->can('map_vlan_static_ids2names'), '$session can map_vlan_static_ids2names' );
ok( $session->can('map_vlan_static_ids2ports'), '$session can map_vlan_static_ids2ports' );
ok( $session->can('map_vlan_static_ports2ids'), '$session can map_vlan_static_ports2ids' );

eval {$session->map_vlan_static_ids2names};
like( $@, qr/not initialized/i, 'not initialized' );

eval {$session->map_vlan_static_ids2ports};
like( $@, qr/not initialized/i, 'not initialized' );

eval {$session->map_vlan_static_ports2ids};
like( $@, qr/not initialized/i, 'not initialized' );

# vim: ft=perl sw=2
