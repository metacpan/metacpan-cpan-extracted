use strict;
use Test;
BEGIN { plan test => 39; }

use Net::IPv6Addr;
ok(1);

my @x;

# Test ipv6_parse_ipv4_compressed, with garbage.
eval { @x = Net::IPv6Addr::ipv6_parse_ipv4_compressed("life, in a nutshell"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_ipv4_compressed, bad ipv6 digits.
eval { @x = Net::IPv6Addr::ipv6_parse_ipv4_compressed("::fffe:10.0.0.1"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_ipv4_compressed, bad ipv4 digits.
eval { @x = Net::IPv6Addr::ipv6_parse_ipv4_compressed("::ffff:10.0.0.x"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_ipv4_compressed, too many adjacent :
eval { @x = Net::IPv6Addr::ipv6_parse_ipv4_compressed(":::ffff:10.0.0.1"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_ipv4_compressed, too many ipv6 digits.
eval { @x = Net::IPv6Addr::ipv6_parse_ipv4_compressed("::fffff:10.0.0.1"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_ipv4_compressed, too many ipv4 digits.
eval { @x = Net::IPv6Addr::ipv6_parse_ipv4_compressed("::ffff:10.0.0.9999"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_ipv4_compressed, too many :
eval { @x = Net::IPv6Addr::ipv6_parse_ipv4_compressed("::0:ffff:10.0.0.1"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_ipv4_compressed, not enough :
eval { @x = Net::IPv6Addr::ipv6_parse_ipv4_compressed(":ffff:10.0.0.1"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_ipv4_compressed, too many .
eval { @x = Net::IPv6Addr::ipv6_parse_ipv4_compressed("::ffff:10.0.0.0.1"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_ipv4_compressed, not enough .
eval { @x = Net::IPv6Addr::ipv6_parse_ipv4_compressed("::ffff:10.0.1"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_ipv4_compressed, adjacent .
eval { @x = Net::IPv6Addr::ipv6_parse_ipv4_compressed("::ffff:10.0..0.1"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_ipv4_compressed, with good stuff.
@x = Net::IPv6Addr::ipv6_parse_ipv4_compressed("::ffff:10.0.0.1");
ok($x[0], 0);
ok($x[1], 0);
ok($x[2], 0);
ok($x[3], 0);
ok($x[4], 0);
ok($x[5], 0xffff);
ok($x[6], 0xa00);
ok($x[7], 1);

@x = Net::IPv6Addr::ipv6_parse_ipv4_compressed("::10.0.0.1");
ok($x[0], 0);
ok($x[1], 0);
ok($x[2], 0);
ok($x[3], 0);
ok($x[4], 0);
ok($x[5], 0);
ok($x[6], 0xa00);
ok($x[7], 1);
