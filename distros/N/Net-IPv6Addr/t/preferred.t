use strict;
use Test;
BEGIN { plan test => 25; }

use Net::IPv6Addr;
ok(1);

my @x;

# Test ipv6_parse_preferred, garbage input.
eval { @x = Net::IPv6Addr::ipv6_parse_preferred("nathan jones"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_preferred, too many :
eval { @x = Net::IPv6Addr::ipv6_parse_preferred("0:1:2:3:4:5:6:7:8"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_preferred, not enough :
eval { @x = Net::IPv6Addr::ipv6_parse_preferred("0:1:2:3:4:5:6"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_preferred, bad digits.
eval { @x = Net::IPv6Addr::ipv6_parse_preferred("0:1:2:3:4:5:6:x"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_preferred, adjacent :
eval { @x = Net::IPv6Addr::ipv6_parse_preferred("0:1:2:3:4:5:6::7"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_preferred, too many digits.
eval { @x = Net::IPv6Addr::ipv6_parse_preferred("0:1:2:3:4:5:6:789ab"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_preferred, : on boundary.
eval { @x = Net::IPv6Addr::ipv6_parse_preferred(":0:1:2:3:4:5:6"); };
ok($@);
ok($@, qr/invalid address/);

eval { @x = Net::IPv6Addr::ipv6_parse_preferred("0:1:2:3:4:5:6:"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_preferred, with good stuff.

@x = Net::IPv6Addr::ipv6_parse_preferred("0:1:2:3:4:5:6:7");
for my $i (0..7) { ok($x[$i], $i); }
