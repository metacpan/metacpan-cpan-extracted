#!perl

use strict;
use warnings;
use Test::More;

eval "use Net::SNMP";
plan skip_all => "Net::SNMP required for testing Net::SNMP::Mixin module"
  if $@;

my @methods = qw/
  get_lldp_local_system_data
  get_lldp_loc_port_table
  get_lldp_rem_table
  map_lldp_loc_portid2portnum
  /;

eval "use Net::SNMP::Mixin";
plan skip_all =>
  "Net::SNMP::Mixin required for testing Net::SNMP::Mixin module"
  if $@;

plan tests => 17;

is( Net::SNMP->mixer('Net::SNMP::Mixin::Dot1abLldp'),
  'Net::SNMP', 'mixer returns the class name' );

foreach my $m (@methods) {
  ok( Net::SNMP->can($m), "$m() is now a class method" );
}

eval {Net::SNMP->mixer('Net::SNMP::Mixin::Dot1abLldp')};
like( $@, qr/already mixed into/, 'mixed in twice is an error' );

my ( $session, $error ) = Net::SNMP->session( hostname => '127.0.0.1', );

ok( !$error, 'snmp session created without error' );
isa_ok( $session, 'Net::SNMP' );

# already mixed in as a class mixin
eval {$session->mixer("Net::SNMP::Mixin::Dot1abLldp")};
like( $@, qr/already mixed into/, 'mixed in twice is an error' );

foreach my $m (@methods) {
  ok( $session->can($m), "\$session can $m()" );
}

eval {$session->get_lldp_local_system_data};
like( $@, qr/not initialized/i, 'not initialized' );

eval {$session->get_lldp_loc_port_table};
like( $@, qr/not initialized/i, 'not initialized' );

eval {$session->map_lldp_loc_portid2portnum};
like( $@, qr/not initialized/i, 'not initialized' );

eval {$session->get_lldp_rem_table};
like( $@, qr/not initialized/i, 'not initialized' );

# vim: ft=perl sw=2
