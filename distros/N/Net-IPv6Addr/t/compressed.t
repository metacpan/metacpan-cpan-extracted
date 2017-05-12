use strict;
use Test;
BEGIN { plan test => 19; }

use Net::IPv6Addr;
ok(1);

my @x;

# Test ipv6_parse_compressed, bad digits.
eval { @x = Net::IPv6Addr::ipv6_parse_compressed("::x"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_compressed, too many adjacent :
eval { @x = Net::IPv6Addr::ipv6_parse_compressed(":::1"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_compressed, too many digits.
eval { @x = Net::IPv6Addr::ipv6_parse_compressed("::11111"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_compressed, too many :
eval { @x = Net::IPv6Addr::ipv6_parse_compressed("0:1:2:3:4:5:6::7"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_compressed, not enough :
eval { @x = Net::IPv6Addr::ipv6_parse_compressed(":1"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_compressed, with good stuff.
@x = Net::IPv6Addr::ipv6_parse_compressed("::1");
ok($x[0], 0);
ok($x[1], 0);
ok($x[2], 0);
ok($x[3], 0);
ok($x[4], 0);
ok($x[5], 0);
ok($x[6], 0);
ok($x[7], 1);
