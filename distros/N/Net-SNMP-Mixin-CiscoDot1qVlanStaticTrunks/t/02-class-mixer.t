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

is( Net::SNMP->mixer('Net::SNMP::Mixin::CiscoDot1qVlanStaticTrunks'),
  'Net::SNMP', 'mixer returns the class name' );
ok(
  Net::SNMP->can('cisco_vlan_ids2names'),
  'cisco_vlan_ids2names() is now a class method'
);
ok(
  Net::SNMP->can('cisco_vlan_ids2trunk_ports'),
  'cisco_vlan_ids2trunk_ports() is now a class method'
);
ok(
  Net::SNMP->can('cisco_trunk_ports2vlan_ids'),
  'cisco_trunk_ports2vlan_ids() is now a class method'
);

eval {Net::SNMP->mixer('Net::SNMP::Mixin::CiscoDot1qVlanStaticTrunks')};
like( $@, qr/already mixed into/, 'mixed in twice is an error' );

my ( $session, $error ) = Net::SNMP->session( hostname => '127.0.0.1', );

ok( !$error, 'snmp session created without error' );
isa_ok( $session, 'Net::SNMP' );

# already mixed in as a class mixin
eval {$session->mixer("Net::SNMP::Mixin::CiscoDot1qVlanStaticTrunks")};
like( $@, qr/already mixed into/, 'mixed in twice is an error' );

ok( $session->can('cisco_vlan_ids2names'), '$session can cisco_vlan_ids2names' );
ok( $session->can('cisco_vlan_ids2trunk_ports'), '$session can cisco_vlan_ids2trunk_ports' );
ok( $session->can('cisco_trunk_ports2vlan_ids'), '$session can cisco_trunk_ports2vlan_ids' );

eval {$session->cisco_vlan_ids2names};
like( $@, qr/not initialized/i, 'not initialized' );

eval {$session->cisco_vlan_ids2trunk_ports};
like( $@, qr/not initialized/i, 'not initialized' );

eval {$session->cisco_trunk_ports2vlan_ids};
like( $@, qr/not initialized/i, 'not initialized' );

# vim: ft=perl sw=2
