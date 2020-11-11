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

plan tests => 48;
#plan 'no_plan';

my $builder        = Module::Build->current;
my $snmp_agent     = $builder->notes('snmp_agent');
my $snmp_community = $builder->notes('snmp_community');
my $snmp_version   = $builder->notes('snmp_version');

SKIP: {
  skip '-> no live tests', 48, unless $snmp_agent;

  my ( $session, $error ) = Net::SNMP->session(
    hostname  => $snmp_agent,
    community => $snmp_community || 'public',
    version   => $snmp_version || '2c',
  );

  ok( !$error, 'got snmp session for live tests' );
  isa_ok( $session, 'Net::SNMP' );

  isa_ok( $session->mixer('Net::SNMP::Mixin::NXOSDot1dBase'), 'Net::SNMP' );
  ok(
    $session->can('get_dot1d_base_group'),
    'can $session->get_dot1d_base_group'
  );
  ok( $session->can('map_bridge_ports2if_indexes'),
    'can $session->map_bridge_ports2if_indexes' );
  ok( $session->can('map_if_indexes2bridge_ports'),
    'can $session->map_if_indexes2bridge_ports' );

  eval { $session->init_mixins };
  ok( !$@, 'init_mixins without error' );
  ok( $session->init_ok('Net::SNMP::Mixin::NXOSDot1dBase'), 'initialization successful completetd' );

  eval { $session->init_mixins(1) };
  ok( !$@, 'already initialized but reload forced' );
  ok( $session->init_ok('Net::SNMP::Mixin::NXOSDot1dBase'), 'initialization successful completetd' );

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

  eval { $session->get_dot1d_base_group };
  ok( !$@, 'get_dot1d_base_group' );

  eval { $session->map_bridge_ports2if_indexes };
  ok( !$@, 'map_bridge_ports2if_indexes' );

  eval { $session->map_if_indexes2bridge_ports };
  ok( !$@, 'map_if_indexes2bridge_ports' );

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

  isa_ok( $session->mixer('Net::SNMP::Mixin::NXOSDot1dBase'), 'Net::SNMP' );
  ok(
    $session->can('get_dot1d_base_group'),
    'can $session->get_dot1d_base_group'
  );
  ok( $session->can('map_bridge_ports2if_indexes'),
    'can $session->map_bridge_ports2if_indexes' );
  ok( $session->can('map_if_indexes2bridge_ports'),
    'can $session->map_if_indexes2bridge_ports' );

  eval { $session->init_mixins };
  snmp_dispatcher();
  ok( !$@, 'init_mixins without error' );
  ok( $session->init_ok('Net::SNMP::Mixin::NXOSDot1dBase'), 'initialization successful completetd' );

  eval { $session->init_mixins(1) };
  snmp_dispatcher();
  ok( !$@, 'already initialized but reload forced' );
  ok( $session->init_ok('Net::SNMP::Mixin::NXOSDot1dBase'), 'initialization successful completetd' );

  eval { $session->get_dot1d_base_group };
  ok( !$@, 'get_dot1d_base_group' );

  eval { $session->map_bridge_ports2if_indexes };
  ok( !$@, 'map_bridge_ports2if_indexes' );

  eval { $session->map_if_indexes2bridge_ports };
  ok( !$@, 'map_if_indexes2bridge_ports' );

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

  isa_ok( $session->mixer('Net::SNMP::Mixin::NXOSDot1dBase'), 'Net::SNMP' );
  ok(
    $session->can('get_dot1d_base_group'),
    'can $session->get_dot1d_base_group'
  );
  ok( $session->can('map_bridge_ports2if_indexes'),
    'can $session->map_bridge_ports2if_indexes' );
  ok( $session->can('map_if_indexes2bridge_ports'),
    'can $session->map_if_indexes2bridge_ports' );

  eval { $session->init_mixins };
  like(
    $session->error,
    qr/No response from remote host/i,
    'No response from remote host'
  );

  eval { $session->get_dot1d_base_group };
  like( $@, qr/not initialized/, 'not initialized' );

  eval { $session->map_bridge_ports2if_indexes };
  like( $@, qr/not initialized/, 'not initialized' );

  eval { $session->map_if_indexes2bridge_ports };
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

  isa_ok( $session->mixer('Net::SNMP::Mixin::NXOSDot1dBase'), 'Net::SNMP' );
  ok(
    $session->can('get_dot1d_base_group'),
    'can $session->get_dot1d_base_group'
  );
  ok( $session->can('map_bridge_ports2if_indexes'),
    'can $session->map_bridge_ports2if_indexes' );
  ok( $session->can('map_if_indexes2bridge_ports'),
    'can $session->map_if_indexes2bridge_ports' );


  eval { $session->init_mixins };
  snmp_dispatcher();
  like(
    $session->error,
    qr/No response from remote host/i,
    'No response from remote host'
  );

  eval { $session->get_dot1d_base_group };
  like( $@, qr/not initialized/, 'not initialized' );

  eval { $session->map_bridge_ports2if_indexes };
  like( $@, qr/not initialized/, 'not initialized' );

  eval { $session->map_if_indexes2bridge_ports };
  like( $@, qr/not initialized/, 'not initialized' );

}

# vim: ft=perl sw=2
