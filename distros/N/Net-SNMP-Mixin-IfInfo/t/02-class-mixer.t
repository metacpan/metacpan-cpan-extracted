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

plan tests => 8;

is( Net::SNMP->mixer('Net::SNMP::Mixin::IfInfo'),
  'Net::SNMP', 'mixer returns the class name' );
ok(
  Net::SNMP->can('get_if_entries'),
  'get_if_entries() is now a class method'
);

eval {Net::SNMP->mixer('Net::SNMP::Mixin::IfInfo')};
like( $@, qr/already mixed into/, 'mixed in twice is an error' );

my ( $session, $error ) = Net::SNMP->session( hostname => '0.0.0.0', );

ok( !$error, 'snmp session created without error' );
isa_ok( $session, 'Net::SNMP' );

# already mixed in as a class mixin
eval {$session->mixer("Net::SNMP::Mixin::IfInfo")};
like( $@, qr/already mixed into/, 'mixed in twice is an error' );

ok( $session->can('get_if_entries'), '$session can get_if_entries' );

eval {$session->get_if_entries};
like( $@, qr/not initialized/i, 'not initialized' );

# vim: ft=perl sw=2
