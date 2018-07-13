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

plan tests => 16;

#plan 'no_plan';

my @methods = qw/
  get_lldp_local_system_data
  get_lldp_loc_port_table
  get_lldp_rem_table
  map_lldp_loc_portid2portnum
  /;

is( Net::SNMP->mixer('Net::SNMP::Mixin::Dot1abLldp'),
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

  foreach my $m (@methods) {
    ok( $session->can($m), "can \$session->$m()" );
  }

  eval { $session->init_mixins };
  ok( !$@, 'init_mixins without error' );
  ok( $session->init_ok('Net::SNMP::Mixin::Dot1abLldp'), 'initialization successful completetd' );

  eval { $session->init_mixins };
  like(
    $@,
    qr/already initialized and reload not forced/i,
    'already initialized and reload not forced'
  );

  eval { $session->init_mixins(1) };
  ok( !$@, 'already initialized but reload forced' );
  ok( $session->init_ok('Net::SNMP::Mixin::Dot1abLldp'), 'initialization successful completetd' );


  my $lldp_local_system_data;
  eval { $lldp_local_system_data = $session->get_lldp_local_system_data };
  ok( !$@, 'get_lldp_local_system_data' );

  my $lldp_loc_port_table;
  eval { $lldp_loc_port_table = $session->get_lldp_loc_port_table };
  ok( !$@, 'get_lldp_loc_port_table' );

  my $lldp_rem_table;
  eval { $lldp_rem_table = $session->get_lldp_rem_table };
  ok( !$@, 'get_lldp_rem_table' );

  my $map_lldp_loc_portid2portnum;
  eval { $map_lldp_loc_portid2portnum = $session->map_lldp_loc_portid2portnum };
  ok( !$@, 'map_lldp_loc_portid2portnum' );
}

# vim: ft=perl sw=2
