#!perl

use strict;
use warnings;
use Test::More;

eval "use Net::SNMP";
plan skip_all => "Net::SNMP required for testing Net::SNMP::Mixin" if $@;

eval "use Net::SNMP::Mixin";
plan skip_all =>
  "Net::SNMP::Mixin required for testing Net::SNMP::Mixin module"
  if $@;

plan tests => 17;
#plan 'no_plan';

my ( $session, $error ) =
  Net::SNMP->session( hostname => '127.0.0.1', retries => 0, timeout => 1, );

ok( !$error, 'snmp session created without error' );
isa_ok( $session, 'Net::SNMP' );

eval { $session->mixer("Net::SNMP::Mixin::Dot1qVlanStatic") };
is( $@, '', 'Net::SNMP::Mixin::Dot1qVlanStatic mixed in successful' );
ok(
  $session->can('map_vlan_id2name'),
  '$session can map_vlan_id2name'
);
ok(
  $session->can('map_if_idx2vlan_id'),
  '$session can map_if_idx2vlan_id'
);
ok(
  $session->can('map_vlan_id2if_idx'),
  '$session can map_vlan_id2if_idx'
);
ok(
  $session->can('map_vlan_static_ids2names'),
  '$session can map_vlan_static_ids2names'
);
ok(
  $session->can('map_vlan_static_ids2ports'),
  '$session can map_vlan_static_ids2ports'
);
ok(
  $session->can('map_vlan_static_ports2ids'),
  '$session can map_vlan_static_ports2ids'
);

# try to mixin twice
eval { $session->mixer("Net::SNMP::Mixin::Dot1qVlanStatic") };
like( $@, qr/already mixed into/, 'mixed in twice is an error' );

eval { $session->init_mixins() };
like(
  $session->error,
  qr/No response from remote host/i,
  'No response from remote host'
);

eval { $session->init_mixins(1) };
like(
  $session->error,
  qr/No response from remote host/i,
  'No response from remote host'
);

undef $session;

# tests with nonblocking session
( $session, $error ) = Net::SNMP->session(
  hostname    => '127.0.0.1',
  nonblocking => 1,
  retries     => 0,
  timeout     => 1,
);

ok( !$error, 'nonblocking snmp session created without error' );
isa_ok( $session, 'Net::SNMP' );

eval { $session->mixer("Net::SNMP::Mixin::Dot1qVlanStatic") };
is( $@, '', 'Net::SNMP::Mixin::Dot1qVlanStatic mixed in successful' );

eval { $session->init_mixins() };
Net::SNMP::snmp_dispatcher();
like(
  $session->error,
  qr/No response from remote host/i,
  'No response from remote host'
);

eval { $session->init_mixins(1) };
Net::SNMP::snmp_dispatcher();
like(
  $session->error,
  qr/No response from remote host/i,
  'No response from remote host'
);

# vim: ft=perl sw=2
