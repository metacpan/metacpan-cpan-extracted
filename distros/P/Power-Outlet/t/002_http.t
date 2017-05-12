# -*- perl -*-

use strict;
use warnings;
use Test::More tests => 13;

BEGIN { use_ok( 'Power::Outlet::Common::IP::HTTP' ); }

my $object=Power::Outlet::Common::IP::HTTP->new();
isa_ok($object, "Power::Outlet::Common::IP::HTTP");
isa_ok($object, "Power::Outlet::Common::IP");
isa_ok($object, "Power::Outlet::Common");
can_ok($object, qw{host port}); #from Power::Outlet::Common::IP
can_ok($object, qw{http_path}); #from Power::Outlet::Common::IP::HTTP
can_ok($object, qw{url});       #from Power::Outlet::Common::IP::HTTP

is($object->host("myhost"), "myhost", "host");
is($object->port("123"), "123", "port");
is($object->http_path("/mypath"), "/mypath", "http_path");

my $url=$object->url;
isa_ok($url, "URI::http");
isa_ok($url, "URI");
is("$url", "http://myhost:123/mypath", "url");
