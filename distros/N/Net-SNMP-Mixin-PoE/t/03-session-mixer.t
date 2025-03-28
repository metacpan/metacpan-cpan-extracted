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

plan tests => 13;
#plan 'no_plan';

my ( $session, $error ) =
  Net::SNMP->session( hostname => '0.0.0.0', retries => 0, timeout => 1, );

ok( !$error, 'snmp session created without error' );
isa_ok( $session, 'Net::SNMP' );

eval { $session->mixer("Net::SNMP::Mixin::PoE") };
is( $@, '', 'Net::SNMP::Mixin::PoE mixed in successful' );
ok( $session->can('get_poe_main_table'), '$session can get_poe_main_table');
ok( $session->can('get_poe_port_table'), '$session can get_poe_port_table');

# try to mixin twice
eval { $session->mixer("Net::SNMP::Mixin::PoE") };
like( $@, qr/already mixed into/, 'mixed in twice is an error' );

eval { $session->init_mixins() };
like(
  $session->errors,
  qr/No response from remote host/i,
  'No response from remote host'
);

eval { $session->init_mixins(1) };
like(
  $session->errors,
  qr/No response from remote host/i,
  'No response from remote host'
);

undef $session;

# tests with nonblocking session
( $session, $error ) = Net::SNMP->session(
  hostname    => '0.0.0.0',
  nonblocking => 1,
  retries     => 0,
  timeout     => 1,
);

ok( !$error, 'nonblocking snmp session created without error' );
isa_ok( $session, 'Net::SNMP' );

eval { $session->mixer("Net::SNMP::Mixin::PoE") };
is( $@, '', 'Net::SNMP::Mixin::PoE mixed in successful' );

eval { $session->init_mixins() };
Net::SNMP::snmp_dispatcher();
like(
  $session->errors,
  qr/No response from remote host/i,
  'No response from remote host'
);

eval { $session->init_mixins(1) };
Net::SNMP::snmp_dispatcher();
like(
  $session->errors,
  qr/No response from remote host/i,
  'No response from remote host'
);

# vim: ft=perl sw=2
