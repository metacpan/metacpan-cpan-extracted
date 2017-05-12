use strict;
use Test;
BEGIN { plan test => 63; }

use Net::IPv6Addr;
ok(1);

my $x;

# Test new with garbage.
eval { $x = new Net::IPv6Addr("Obvious Garbage"); };
ok($@);
ok($@, qr/invalid IPv6 address/);

# Test new with preferred style, too many :
eval { $x = new Net::IPv6Addr("0:1:2:3:4:5:6:7:8"); };
ok($@);
ok($@, qr/invalid IPv6 address/);

# Test new with preferred style, not enough :
eval { $x = new Net::IPv6Addr("0:1:2:3:4:5:6"); };
ok($@);
ok($@, qr/invalid IPv6 address/);

# Test new with preferred style, bad digits.
eval { $x = new Net::IPv6Addr("0:1:2:3:4:5:6:x"); };
ok($@);
ok($@, qr/invalid IPv6 address/);

# Test new with preferred style, adjacent :
eval { $x = new Net::IPv6Addr("0:1:2:3:4:5:6::7"); };
ok($@);
ok($@, qr/invalid IPv6 address/);

# Test new with preferred style, too many digits.
eval { $x = new Net::IPv6Addr("0:1:2:3:4:5:6:789abcdef"); };
ok($@);
ok($@, qr/invalid IPv6 address/);

# Test new with preferred style.
$x = new Net::IPv6Addr("0:1:2:3:4:5:6:789a");
ok(ref $x, 'Net::IPv6Addr');

# Test new with compressed style, bad digits.
eval { $x = new Net::IPv6Addr("0:1:2:3::x");  };
ok($@);
ok($@, qr/invalid IPv6 address/);

# Test new with compressed style, too many adjacent :
eval { $x = new Net::IPv6Addr("0:1:2:::3"); };
ok($@);
ok($@, qr/invalid IPv6 address/);

# Test new with compressed style, too many digits.
eval { $x = new Net::IPv6Addr("0:1:2:3::abcde"); };
ok($@);
ok($@, qr/invalid IPv6 address/);

# Test new with compressed style, too many :
eval { $x = new Net::IPv6Addr("0:1:2:3:4:5:6:7:8"); };
ok($@);
ok($@, qr/invalid IPv6 address/);

# Test new with compressed style, not enough :
eval { $x = new Net::IPv6Addr("0:1"); };
ok($@);
ok($@, qr/invalid IPv6 address/);

# Test new with compressed style.
$x = new Net::IPv6Addr("0:1:2:3::f"); 
ok(ref $x, 'Net::IPv6Addr');

# Test new with ipv4 style, bad ipv6 digits.
eval { $x = new Net::IPv6Addr("0:0:0:0:0:x:10.0.0.1"); };
ok($@);
ok($@, qr/invalid IPv6 address/);

# Test new with ipv4 style, bad ipv4 digits.
eval { $x = new Net::IPv6Addr("0:0:0:0:0:0:10.0.0.x"); };
ok($@);
ok($@, qr/invalid IPv6 address/);

# Test new with ipv4 style, adjacent :
eval { $x = new Net::IPv6Addr("0:0:0:0:0::0:10.0.0.1"); };
ok($@);
ok($@, qr/invalid IPv6 address/);

# Test new with ipv4 style, too many ipv6 digits.
eval { $x = new Net::IPv6Addr("0:0:0:0:0:00000:10.0.0.1"); };
ok($@);
ok($@, qr/invalid IPv6 address/);

# Test new with ipv4 style, too many :
eval { $x = new Net::IPv6Addr("0:0:0:0:0:0:0:10.0.0.1"); };
ok($@);
ok($@, qr/invalid IPv6 address/);

# Test new with ipv4 style, not enough :
eval { $x = new Net::IPv6Addr("0:0:0:0:0:10.0.0.1"); };
ok($@);
ok($@, qr/invalid IPv6 address/);

# Test new with ipv4 style, too many .
eval { $x = new Net::IPv6Addr("0:0:0:0:0:0:10.0.0.0.1"); };
ok($@);
ok($@, qr/invalid IPv6 address/);

# Test new with ipv4 style, not enough .
eval { $x = new Net::IPv6Addr("0:0:0:0:0:0:10.0.1"); };
ok($@);
ok($@, qr/invalid IPv6 address/);

# Test new with ipv4 style, adjacent .
eval { $x = new Net::IPv6Addr("0:0:0:0:0:0:10..0.0.1"); };
ok($@);
ok($@, qr/invalid IPv6 address/);

# Test new with ipv4 style.
$x = new Net::IPv6Addr("0:0:0:0:0:0:10.0.0.1"); 
ok(ref $x, 'Net::IPv6Addr');

# Test new with compressed ipv4 style, bad ipv6 digits.
eval { $x = new Net::IPv6Addr("::fffx:192.168.0.1"); };
ok($@);
ok($@, qr/invalid IPv6 address/);

# Test new with compressed ipv4 style, bad ipv4 digits.
eval { $x = new Net::IPv6Addr("::ffff:192.168.0.x"); };
ok($@);
ok($@, qr/invalid IPv6 address/);

# Test new with compressed ipv4 style, too many adjacent :
eval { $x = new Net::IPv6Addr(":::ffff:192.168.0.1"); };
ok($@);
ok($@, qr/invalid IPv6 address/);

# Test new with compressed ipv4 style, too many ipv6 digits.
eval { $x = new Net::IPv6Addr("::fffff:192.168.0.1"); };
ok($@);
ok($@, qr/invalid IPv6 address/);

# Test new with compressed ipv4 style, too many ipv4 digits.
eval { $x = new Net::IPv6Addr("::ffff:1923.168.0.1"); };
ok($@);
ok($@, qr/invalid IPv6 address/);

# Test new with compressed ipv4 style, not enough :
eval { $x = new Net::IPv6Addr(":ffff:192.168.0.1"); };
ok($@);
ok($@, qr/invalid IPv6 address/);

# Test new with compressed ipv4 style, too many .
eval { $x = new Net::IPv6Addr("::ffff:192.168.0.1.2"); };
ok($@);
ok($@, qr/invalid IPv6 address/);

# Test new with compressed ipv4 style, not enough .
eval { $x = new Net::IPv6Addr("::ffff:192.168.0"); };
ok($@);
ok($@, qr/invalid IPv6 address/);

# Test new with compressed ipv4 style, adjacent .
eval { $x = new Net::IPv6Addr("::ffff:192.168..0.1"); };
ok($@);
ok($@, qr/invalid IPv6 address/);

# Test new with compressed ipv4 style.
$x = new Net::IPv6Addr("::ffff:192.168.0.1"); 
ok(ref $x, 'Net::IPv6Addr');
