#!perl

use strict;
use warnings;
use Test::More;

eval "use Net::SNMP";
plan skip_all => "Net::SNMP required for testing Net::SNMP::Mixin module"
  if $@;

eval "use Net::SNMP::Mixin";
plan skip_all => "Net::SNMP::Mixin required for testing Net::SNMP::Mixin module"
  if $@;

plan tests => 11;

is( Net::SNMP->mixer('Net::SNMP::Mixin::PoE'), 'Net::SNMP', 'mixer returns the class name' );
ok( Net::SNMP->can('get_poe_port_table'), 'poe_port_table() is now a class method' );
ok( Net::SNMP->can('get_poe_main_table'), 'poe_main_table() is now a class method' );

eval { Net::SNMP->mixer('Net::SNMP::Mixin::PoE') };
like( $@, qr/already mixed into/, 'mixed in twice is an error' );

my ( $session, $error ) = Net::SNMP->session( hostname => '0.0.0.0', );

ok( !$error, 'snmp session created without error' );
isa_ok( $session, 'Net::SNMP' );

# already mixed in as a class mixin
eval { $session->mixer("Net::SNMP::Mixin::PoE") };
like( $@, qr/already mixed into/, 'mixed in twice is an error' );

ok( $session->can('get_poe_port_table'), '$session can poe_port_table' );
ok( $session->can('get_poe_main_table'), '$session can poe_main_table' );

eval { $session->get_poe_port_table };
like( $@, qr/not initialized/i, 'not initialized' );

eval { $session->get_poe_main_table };
like( $@, qr/not initialized/i, 'not initialized' );

# vim: ft=perl sw=2
