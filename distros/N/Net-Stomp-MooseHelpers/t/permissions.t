#!perl
use strict;
use warnings;
use Test::More;
use Net::Stomp::MooseHelpers::Types qw(Permissions OctalPermissions);

ok(is_Permissions(420),'420 is Permissions');
ok(is_Permissions(0),'0 is Permissions');
ok(!is_Permissions('0123'),'0123 is not Permissions');

ok(is_OctalPermissions('0644'),'0644 is OctalPermissions');
ok(is_OctalPermissions('01644'),'01644 is OctalPermissions');
ok(!is_OctalPermissions(0),'0 is not OctalPermissions');
ok(!is_OctalPermissions('0999'),'0999 is not OctalPermissions');
ok(!is_OctalPermissions('011'),'011 is not OctalPermissions');
ok(!is_OctalPermissions(1),'1 is not OctalPermissions');
ok(!is_OctalPermissions('016442'),'016442 is not OctalPermissions');

is(to_Permissions('0644'),420,'coercion works');

done_testing;
