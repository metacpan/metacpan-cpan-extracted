use strict;
use Test;
BEGIN { plan tests => 12; }
use Net::IPv6Addr;
ok(1);

# Yeah, so I was listening to it when I wrote the test.
eval { Net::IPv6Addr::ipv6_parse("sunshine of your love"); };
ok($@);
ok($@, qr/invalid IPv6 address/);

eval { Net::IPv6Addr::ipv6_parse("::/x"); };
ok($@);
ok($@, qr/non-numeric prefix length/);

eval { Net::IPv6Addr::ipv6_parse("::/-19325"); };
ok($@);
ok($@, qr/non-numeric prefix length/);

eval { Net::IPv6Addr::ipv6_parse("::/65389"); };
ok($@);
ok($@, qr/invalid prefix length/);

ok(scalar(Net::IPv6Addr::ipv6_parse("a:b:c:d:0:1:2:3")), "a:b:c:d:0:1:2:3");

my ($x, $y) = Net::IPv6Addr::ipv6_parse("a::/24");
ok($x, "a::");
ok($y, 24);
