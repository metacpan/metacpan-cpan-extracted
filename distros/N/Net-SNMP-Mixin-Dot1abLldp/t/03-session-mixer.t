#!perl

use strict;
use warnings;
use Test::More;

eval "use Net::SNMP";
plan skip_all => "Net::SNMP required for testing Net::SNMP::Mixin" if $@;

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

plan tests => 15;
#plan 'no_plan';

my ( $session, $error ) =
  Net::SNMP->session( hostname => '127.0.0.1', retries => 0, timeout => 1, );

ok( !$error, 'snmp session created without error' );
isa_ok( $session, 'Net::SNMP' );

eval { $session->mixer("Net::SNMP::Mixin::Dot1abLldp") };
is( $@, '', 'Net::SNMP::Mixin::Dot1abLldp mixed in successful' );

foreach my $m (@methods) {
  ok( $session->can($m), "\$session can $m()" );
}

# try to mixin twice
eval { $session->mixer("Net::SNMP::Mixin::Dot1abLldp") };
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
  hostname    => '127.0.0.1',
  nonblocking => 1,
  retries     => 0,
  timeout     => 1,
);

ok( !$error, 'nonblocking snmp session created without error' );
isa_ok( $session, 'Net::SNMP' );

eval { $session->mixer("Net::SNMP::Mixin::Dot1abLldp") };
is( $@, '', 'Net::SNMP::Mixin::Dot1abLldp mixed in successful' );

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
