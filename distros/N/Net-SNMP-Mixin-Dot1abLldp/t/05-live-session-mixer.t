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

plan tests => 44;
#plan 'no_plan';

my @methods = qw/
  get_lldp_local_system_data
  get_lldp_loc_port_table
  get_lldp_rem_table
  map_lldp_loc_portid2portnum
  /;

my $builder        = Module::Build->current;
my $snmp_agent     = $builder->notes('snmp_agent');
my $snmp_community = $builder->notes('snmp_community');
my $snmp_version   = $builder->notes('snmp_version');

SKIP: {
  skip '-> no live tests', 44, unless $snmp_agent;

  my ( $session, $error ) = Net::SNMP->session(
    hostname  => $snmp_agent,
    community => $snmp_community || 'public',
    version   => $snmp_version || '2c',
  );

  ok( !$error, 'got snmp session for live tests' );
  isa_ok( $session, 'Net::SNMP' );

  isa_ok( $session->mixer('Net::SNMP::Mixin::Dot1abLldp'), 'Net::SNMP' );

  foreach my $m (@methods) {
    ok( $session->can($m), "can \$session->$m()" );
  }

  eval { $session->init_mixins };
  ok( !$@, 'init_mixins without error' );
  ok( $session->init_ok('Net::SNMP::Mixin::Dot1abLldp'), 'initialization successful completed' );

  eval { $session->init_mixins(1) };
  ok( !$@, 'already initialized but reload forced' );
  ok( $session->init_ok('Net::SNMP::Mixin::Dot1abLldp'), 'initialization successful completed' );

  eval { $session->init_mixins };
  like(
    $@,
    qr/already initialized and reload not forced/i,
    'already initialized and reload not forced'
  );

  eval { Net::SNMP->init_mixins };
  like(
    $@,
    qr/pure instance method called as class method/i,
    'pure instance method called as class method'
  );

  my ($lldp_local_system_data, $lldp_loc_port_table, $lldp_rem_table, $map_lldp_loc_portid2portnum);

  eval { $lldp_local_system_data = $session->get_lldp_local_system_data };
  ok( !$@, 'get_lldp_local_system_data' );

  eval { $map_lldp_loc_portid2portnum = $session->map_lldp_loc_portid2portnum };
  ok( !$@, 'map_lldp_loc_portid2portnum' );

  eval { $lldp_loc_port_table = $session->get_lldp_loc_port_table };
  ok( !$@, 'get_lldp_loc_port_table' );

  eval { $lldp_rem_table = $session->get_lldp_rem_table };
  ok( !$@, 'get_lldp_rem_table' );

  undef $session;

  # nonblocking tests
  ( $session, $error ) = Net::SNMP->session(
    hostname    => $snmp_agent,
    community   => $snmp_community || 'public',
    version   => $snmp_version || '2c',
    nonblocking => 1,
  );

  ok( !$error, 'got snmp session for live tests' );
  isa_ok( $session, 'Net::SNMP' );

  isa_ok( $session->mixer('Net::SNMP::Mixin::Dot1abLldp'), 'Net::SNMP' );

  eval { $session->init_mixins };
  ok( !$@, 'init_mixins without error' );
  snmp_dispatcher();
  ok( $session->init_ok('Net::SNMP::Mixin::Dot1abLldp'), 'initialization successful completed' );

  eval { $session->init_mixins(1) };
  ok( !$@, 'already initialized but reload forced' );
  snmp_dispatcher();
  ok( $session->init_ok('Net::SNMP::Mixin::Dot1abLldp'), 'initialization successful completed' );

  eval { $lldp_local_system_data = $session->get_lldp_local_system_data };
  ok( !$@, 'get_lldp_local_system_data' );

  eval { $map_lldp_loc_portid2portnum = $session->map_lldp_loc_portid2portnum };
  ok( !$@, 'map_lldp_loc_portid2portnum' );

  eval { $lldp_loc_port_table = $session->get_lldp_loc_port_table };
  ok( !$@, 'get_lldp_loc_port_table' );

  eval { $lldp_rem_table = $session->get_lldp_rem_table };
  ok( !$@, 'get_lldp_rem_table' );

  undef $session;

  # tests with wrong community
  ( $session, $error ) = Net::SNMP->session(
    hostname  => $snmp_agent,
    community => '_foo_bar_bazz_yazz_%_',
    version   => $snmp_version || '2c',
    timeout   => 1,
    retries   => 0,
  );

  ok( !$error, 'got snmp session for live tests' );
  isa_ok( $session, 'Net::SNMP' );

  isa_ok( $session->mixer('Net::SNMP::Mixin::Dot1abLldp'), 'Net::SNMP' );

  eval { $session->init_mixins };
  like(
    $session->errors,
    qr/No response from remote host/i,
    'No response from remote host'
  );

  eval { $lldp_local_system_data = $session->get_lldp_local_system_data };
  like( $@, qr/not initialized/, 'not initialized' );

  eval { $map_lldp_loc_portid2portnum = $session->map_lldp_loc_portid2portnum };
  like( $@, qr/not initialized/, 'not initialized' );

  eval { $lldp_loc_port_table = $session->get_lldp_loc_port_table };
  like( $@, qr/not initialized/, 'not initialized' );

  eval { $lldp_rem_table = $session->get_lldp_rem_table };
  like( $@, qr/not initialized/, 'not initialized' );

  undef $session;

  # nonblocking tests with wrong community
  ( $session, $error ) = Net::SNMP->session(
    hostname    => $snmp_agent,
    community   => '_foo_bar_bazz_yazz_%_',
    version   => $snmp_version || '2c',
    timeout     => 1,
    retries     => 0,
    nonblocking => 1,
  );

  ok( !$error, 'got snmp session for live tests' );
  isa_ok( $session, 'Net::SNMP' );

  isa_ok( $session->mixer('Net::SNMP::Mixin::Dot1abLldp'), 'Net::SNMP' );

  eval { $session->init_mixins };
  snmp_dispatcher();
  like(
    $session->errors,
    qr/No response from remote host/i,
    'No response from remote host'
  );

  eval { $lldp_local_system_data = $session->get_lldp_local_system_data };
  like( $@, qr/not initialized/, 'not initialized' );

  eval { $map_lldp_loc_portid2portnum = $session->map_lldp_loc_portid2portnum };
  like( $@, qr/not initialized/, 'not initialized' );

  eval { $lldp_loc_port_table = $session->get_lldp_loc_port_table };
  like( $@, qr/not initialized/, 'not initialized' );

  eval { $lldp_rem_table = $session->get_lldp_rem_table };
  like( $@, qr/not initialized/, 'not initialized' );

}

# vim: ft=perl sw=2
