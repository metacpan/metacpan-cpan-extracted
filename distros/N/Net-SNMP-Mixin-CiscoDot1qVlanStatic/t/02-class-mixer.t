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

is( Net::SNMP->mixer('Net::SNMP::Mixin::CiscoDot1qVlanStatic'),
  'Net::SNMP', 'mixer returns the class name' );
ok(
  Net::SNMP->can('map_vlan_id2name'),
  'map_vlan_id2name() is now a class method'
);
ok(
  Net::SNMP->can('map_vlan_id2if_idx'),
  'map_vlan_id2if_idx() is now a class method'
);
ok(
  Net::SNMP->can('map_if_idx2vlan_id'),
  'map_if_idx2vlan_id() is now a class method'
);

eval {Net::SNMP->mixer('Net::SNMP::Mixin::CiscoDot1qVlanStatic')};
like( $@, qr/already mixed into/, 'mixed in twice is an error' );

my ( $session, $error ) = Net::SNMP->session( hostname => '127.0.0.1', );

ok( !$error, 'snmp session created without error' );
isa_ok( $session, 'Net::SNMP' );

# already mixed in as a class mixin
eval {$session->mixer("Net::SNMP::Mixin::CiscoDot1qVlanStatic")};
like( $@, qr/already mixed into/, 'mixed in twice is an error' );

ok( $session->can('map_vlan_id2name'), '$session can map_vlan_id2name' );
ok( $session->can('map_vlan_id2if_idx'), '$session can map_vlan_id2if_idx' );
ok( $session->can('map_if_idx2vlan_id'), '$session can map_if_idx2vlan_id' );

eval {$session->map_vlan_id2name};
like( $@, qr/not initialized/i, 'not initialized' );

eval {$session->map_vlan_id2if_idx};
like( $@, qr/not initialized/i, 'not initialized' );

eval {$session->map_if_idx2vlan_id};
like( $@, qr/not initialized/i, 'not initialized' );

# vim: ft=perl sw=2
