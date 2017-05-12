#!perl

use strict;
use warnings;
use Test::More;

my $test_warn_missing;

BEGIN {
  eval "use Test::Warn";
  $test_warn_missing++ if $@;
}

eval "use Net::SNMP";
plan skip_all => "Net::SNMP required for testing Net::SNMP::Mixin" if $@;

plan tests => 8;
#plan 'no_plan';

use_ok('Net::SNMP::Mixin');

my ( $session, $error1 ) = Net::SNMP->session( hostname => '127.0.0.1', );

ok( !$error1, 'no snmp session' );
isa_ok( $session, 'Net::SNMP' );

SKIP: {
  skip '-> Test::Warn required', 1, if $test_warn_missing;
  warnings_like { $session->init_mixins() }
  { carped => qr/please use first the mix.../i },
    'init_mixins called before mixer()';
}

eval {$session->mixer("Net::SNMP::Mixin::System")};
is( $@, '', 'Net::SNMP::Mixin::System mixed in successful' );
ok( $session->can('get_system_group'), '$session can get_system_group' );

# try to mixin twice
eval {$session->mixer("Net::SNMP::Mixin::System")};
like( $@, qr/already mixed into/, 'mixed in twice is an error' );

# try to mixin a non existent module
eval {$session->mixer("Net::SNMP::Mixin::mixin_does_not_exist")};
like( $@, qr/Can't locate/i, 'try to mixin a non existent module' );

# vim: ft=perl sw=2
