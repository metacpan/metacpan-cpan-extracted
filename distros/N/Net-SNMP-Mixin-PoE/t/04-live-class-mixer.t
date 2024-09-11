#!perl

use strict;
use warnings;
use Test::More;
use Module::Build;

eval "use Net::SNMP";
plan skip_all => "Net::SNMP required for testing Net::SNMP::Mixin module"
  if $@;

eval "use Net::SNMP::Mixin";
plan skip_all => "Net::SNMP::Mixin required for testing Net::SNMP::Mixin module"
  if $@;

plan tests => 12;

#plan 'no_plan';

is(Net::SNMP->mixer('Net::SNMP::Mixin::PoE'), 'Net::SNMP', 'mixer returns the class name');

my $builder        = Module::Build->current;
my $snmp_agent     = $builder->notes('snmp_agent');
my $snmp_community = $builder->notes('snmp_community');
my $snmp_version   = $builder->notes('snmp_version');

SKIP: {
  skip '-> no live tests', 11, unless $snmp_agent;

  my ($session, $error) = Net::SNMP->session(
    hostname  => $snmp_agent,
    community => $snmp_community || 'public',
    version   => $snmp_version   || '2c',
  );

  ok(!$error, 'got snmp session for live tests');
  isa_ok($session, 'Net::SNMP');
  ok($session->can('get_poe_main_table'), '$session can get_poe_main_table');
  ok($session->can('get_poe_port_table'), '$session can get_poe_port_table');

  eval { $session->init_mixins };
  ok(!$@,                                        'init_mixins without error');
  ok($session->init_ok('Net::SNMP::Mixin::PoE'), 'initialization successful completetd');

  eval { $session->init_mixins(1) };
  ok(!$@,                                        'already initialized but reload forced');
  ok($session->init_ok('Net::SNMP::Mixin::PoE'), 'initialization successful completetd');

  eval { $session->init_mixins };
  like($@, qr/already initialized and reload not forced/i, 'already initialized and reload not forced');

  eval { $session->get_poe_main_table };
  ok(!$@, 'get_poe_main_table');

  eval { $session->get_poe_port_table };
  ok(!$@, 'get_poe_port_table');
}

# vim: ft=perl sw=2
