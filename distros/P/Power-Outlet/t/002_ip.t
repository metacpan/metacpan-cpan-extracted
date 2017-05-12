# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 6;

BEGIN { use_ok( 'Power::Outlet::Common::IP' ); }

my $object=Power::Outlet::Common::IP->new();
isa_ok($object, "Power::Outlet::Common::IP");
isa_ok($object, "Power::Outlet::Common");
can_ok($object, qw{host port}); #from Power::Outlet::Common::IP

is($object->host("myhost"), "myhost", "host");
is($object->port("123"), "123", "port");
