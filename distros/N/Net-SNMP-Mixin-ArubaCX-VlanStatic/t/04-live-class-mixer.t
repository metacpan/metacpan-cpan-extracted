#!perl

use strict;
use warnings;
use Test::More;
use Module::Build;

eval "use Net::SNMP";
plan skip_all => "Net::SNMP required for testing Net::SNMP::Mixin module"
  if $@;

eval "use Net::SNMP::Mixin";
plan skip_all =>
  "Net::SNMP::Mixin required for testing Net::SNMP::Mixin module"
  if $@;

plan tests => 14;

#plan 'no_plan';

is( Net::SNMP->mixer('Net::SNMP::Mixin::ArubaCX::VlanStatic'),
  'Net::SNMP', 'mixer returns the class name' );

my $builder        = Module::Build->current;
my $snmp_agent     = $builder->notes('snmp_agent');
my $snmp_community = $builder->notes('snmp_community');
my $snmp_version   = $builder->notes('snmp_version');

SKIP: {
  skip '-> no live tests', 13, unless $snmp_agent;

  my ( $session, $error ) = Net::SNMP->session(
    hostname  => $snmp_agent,
    community => $snmp_community || 'public',
    version   => $snmp_version || '2c',
  );

  ok( !$error, 'got snmp session for live tests' );
  isa_ok( $session, 'Net::SNMP' );
  ok(
    $session->can('map_vlan_id2name'),
    'can $session->map_vlan_id2name'
  );
  ok(
    $session->can('map_vlan_id2if_idx'),
    'can $session->map_vlan_id2if_idx'
  );
  ok( $session->can('map_if_idx2vlan_id'),
    'can $session->map_if_idx2vlan_id' );

  eval { $session->init_mixins };
  ok( !$@, 'init_mixins without error' );
  ok( $session->init_ok('Net::SNMP::Mixin::ArubaCX::VlanStatic'), 'initialization successful completetd' );

  eval { $session->init_mixins };
  like(
    $@,
    qr/already initialized and reload not forced/i,
    'already initialized and reload not forced'
  );

  eval { $session->init_mixins(1) };
  ok( !$@, 'already initialized but reload forced' );
  ok( $session->init_ok('Net::SNMP::Mixin::ArubaCX::VlanStatic'), 'initialization successful completetd' );


  my $ids2names;
  eval { $ids2names = $session->map_vlan_id2name };
  ok( !$@, 'map_vlan_id2name' );

  my $ids2ports;
  eval { $ids2ports = $session->map_vlan_id2if_idx };
  ok( !$@, 'map_vlan_id2if_idx' );

  my $ports2ids;
  eval { $ports2ids = $session->map_if_idx2vlan_id };
  ok( !$@, 'map_if_idx2vlan_id' );
}

# vim: ft=perl sw=2
