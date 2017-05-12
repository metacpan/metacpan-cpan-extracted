use strict;
use Test;
BEGIN { plan test => 31; }

use Net::IPv6Addr;
ok(1);

my @x;

# Test ipv6_parse_ipv4, garbage.
eval { @x = Net::IPv6Addr::ipv6_parse_ipv4("absolute and utter garbage"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_ipv4, bad ipv6 digits.
eval { @x = Net::IPv6Addr::ipv6_parse_ipv4("x:0:0:0:0:0:10.0.0.1"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_ipv4, bad ipv4 digits.
eval { @x = Net::IPv6Addr::ipv6_parse_ipv4("0:0:0:0:0:0:x.0.0.1"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_ipv4, adjacent :
eval { @x = Net::IPv6Addr::ipv6_parse_ipv4("0:0:0:0:0::0:10.0.0.1"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_ipv4, too many ipv6 digits.
eval { @x = Net::IPv6Addr::ipv6_parse_ipv4("00000:0:0:0:0:0:10.0.0.1"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_ipv4, too many ipv4 digits.
eval { @x = Net::IPv6Addr::ipv6_parse_ipv4("0:0:0:0:0:0:10.0.0.1000"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_ipv4, too many :
eval { @x = Net::IPv6Addr::ipv6_parse_ipv4("0:0:0:0:0:0:0:10.0.0.1"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_ipv4, not enough :
eval { @x = Net::IPv6Addr::ipv6_parse_ipv4("0:0:0:0:0:10.0.0.1"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_ipv4, too many .
eval { @x = Net::IPv6Addr::ipv6_parse_ipv4("0:0:0:0:0:0:10.0.0.0.1"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_ipv4, not enough .
eval { @x = Net::IPv6Addr::ipv6_parse_ipv4("0:0:0:0:0:0:10.0.1"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_ipv4, adjacent .
eval { @x = Net::IPv6Addr::ipv6_parse_ipv4("0:0:0:0:0:0:10.0.0..1"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_ipv4, good stuff.
@x = Net::IPv6Addr::ipv6_parse_ipv4("0:0:0:0:0:0:10.0.0.1");
ok($x[0], 0);
ok($x[1], 0);
ok($x[2], 0);
ok($x[3], 0);
ok($x[4], 0);
ok($x[5], 0);
ok($x[6], 0xa00);
ok($x[7], 1);
