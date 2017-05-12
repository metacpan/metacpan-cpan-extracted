#!perl

use strict;
use warnings;
use Test::More;

eval "use Net::SNMP";
plan skip_all => "Net::SNMP required for testing Net::SNMP::Mixin" if $@;
plan tests => 20;

# explicit emtpy import list
eval "use Net::SNMP::Mixin ()";
ok('use Net::SNMP::Mixin ()') unless $@;
ok( !Net::SNMP->can('mixer'),       'mixer not imported' );
ok( !Net::SNMP->can('init_mixins'), 'init_mixins not imported' );
ok( !Net::SNMP->can('errors'), 'errors not imported' );
ok( !Net::SNMP->can('init_ok'), 'init_ok not imported' );

use_ok('Net::SNMP::Mixin');
ok( Net::SNMP->can('mixer'), 'mixer exported by default into Net::SNMP' );
ok( Net::SNMP->can('init_mixins'),
  'init_mixins exported by default into Net::SNMP' );
ok( Net::SNMP->can('errors'), 'errors exported by default into Net::SNMP' );
ok( Net::SNMP->can('init_ok'), 'init_ok exported by default into Net::SNMP' );

is( Net::SNMP->mixer(), 'Net::SNMP', 'mixer returns the class name' );
is( Net::SNMP->mixer('Net::SNMP::Mixin::System'),
  'Net::SNMP', 'mixer returns the class name' );
ok(
  Net::SNMP->can('get_system_group'),
  'get_system_group() is now a class method'
);

eval {Net::SNMP->mixer('Net::SNMP::Mixin::System')};
like( $@, qr/already mixed into/, 'mixed in twice is an error' );

eval {Net::SNMP->mixer('Net::SNMP::Mixin::mixin_does_not_exist')};
like( $@, qr/Can't locate/i, 'try to mixin a non existent module' );

my ( $session, $error ) = Net::SNMP->session( hostname => '127.0.0.1', );

ok( !$error, 'no snmp session' );
isa_ok( $session, 'Net::SNMP' );

# already mixed in as a class mixin
eval {$session->mixer("Net::SNMP::Mixin::System")};
like( $@, qr/already mixed into/, 'mixed in twice is an error' );

ok( $session->can('get_system_group'), '$session can get_system_group' );

eval {$session->get_system_group};
like( $@, qr/not initialized/i, 'not initialized' );

# vim: ft=perl sw=2
