use strict;
use Test::More;

use Net::IPv6Addr;

my $x;
# Test ipv6_chkip with garbage.
$x = Net::IPv6Addr::ipv6_chkip("Obvious Garbage");
ok(not defined $x);

# Test ipv6_chkip with preferred style, too many :
$x = Net::IPv6Addr::ipv6_chkip("0:1:2:3:4:5:6:7:8");
ok(not defined $x);

# Test ipv6_chkip with preferred style, not enough :
$x = Net::IPv6Addr::ipv6_chkip("0:1:2:3:4:5:6");
ok(not defined $x);

# Test ipv6_chkip with preferred style, bad digits.
$x = Net::IPv6Addr::ipv6_chkip("0:1:2:3:4:5:6:x");
ok(not defined $x);

# Test ipv6_chkip with preferred style, adjacent :
$x = Net::IPv6Addr::ipv6_chkip("0:1:2:3:4:5:6::7");
ok(not defined $x);

# Test ipv6_chkip with preferred style, too many digits.
$x = Net::IPv6Addr::ipv6_chkip("0:1:2:3:4:5:6:789abcdef");
ok(not defined $x);

# Test ipv6_chkip with preferred style.
$x = Net::IPv6Addr::ipv6_chkip("0:1:2:3:4:5:6:789a");
ok(ref $x, 'CODE');

# Test ipv6_chkip with compressed style, bad digits.
$x = Net::IPv6Addr::ipv6_chkip("0:1:2:3::x"); 
ok(not defined $x);

# Test ipv6_chkip with compressed style, too many adjacent :
$x = Net::IPv6Addr::ipv6_chkip("0:1:2:::3"); 
ok(not defined $x);

# Test ipv6_chkip with compressed style, too many digits.
$x = Net::IPv6Addr::ipv6_chkip("0:1:2:3::abcde"); 
ok(not defined $x);

# Test ipv6_chkip with compressed style, too many :
$x = Net::IPv6Addr::ipv6_chkip("0:1:2:3:4:5:6:7:8"); 
ok(not defined $x);

# Test ipv6_chkip with compressed style, not enough :
$x = Net::IPv6Addr::ipv6_chkip("0:1"); 
ok(not defined $x);

# Test ipv6_chkip with compressed style.
$x = Net::IPv6Addr::ipv6_chkip("0:1:2:3::f"); 
ok(ref $x, 'CODE');

# Test ipv6_chkip with ipv4 style, bad ipv6 digits.
$x = Net::IPv6Addr::ipv6_chkip("0:0:0:0:0:x:10.0.0.1"); 
ok(not defined $x);

# Test ipv6_chkip with ipv4 style, bad ipv4 digits.
$x = Net::IPv6Addr::ipv6_chkip("0:0:0:0:0:0:10.0.0.x"); 
ok(not defined $x);

# Test ipv6_chkip with ipv4 style, adjacent :
$x = Net::IPv6Addr::ipv6_chkip("0:0:0:0:0::0:10.0.0.1"); 
ok(not defined $x);

# Test ipv6_chkip with ipv4 style, too many ipv6 digits.
$x = Net::IPv6Addr::ipv6_chkip("0:0:0:0:0:00000:10.0.0.1"); 
ok(not defined $x);

# Test ipv6_chkip with ipv4 style, too many :
$x = Net::IPv6Addr::ipv6_chkip("0:0:0:0:0:0:0:10.0.0.1"); 
ok(not defined $x);

# Test ipv6_chkip with ipv4 style, not enough :
$x = Net::IPv6Addr::ipv6_chkip("0:0:0:0:0:10.0.0.1"); 
ok(not defined $x);

# Test ipv6_chkip with ipv4 style, too many .
$x = Net::IPv6Addr::ipv6_chkip("0:0:0:0:0:0:10.0.0.0.1"); 
ok(not defined $x);

# Test ipv6_chkip with ipv4 style, not enough .
$x = Net::IPv6Addr::ipv6_chkip("0:0:0:0:0:0:10.0.1"); 
ok(not defined $x);

# Test ipv6_chkip with ipv4 style, adjacent .
$x = Net::IPv6Addr::ipv6_chkip("0:0:0:0:0:0:10..0.0.1"); 
ok(not defined $x);

# Test ipv6_chkip with ipv4 style.
$x = Net::IPv6Addr::ipv6_chkip("0:0:0:0:0:0:10.0.0.1"); 
ok(ref $x, 'CODE');

# Test ipv6_chkip with compressed ipv4 style, bad ipv6 digits.
$x = Net::IPv6Addr::ipv6_chkip("::fffx:192.168.0.1"); 
ok(not defined $x);

# Test ipv6_chkip with compressed ipv4 style, bad ipv4 digits.
$x = Net::IPv6Addr::ipv6_chkip("::ffff:192.168.0.x"); 
ok(not defined $x);

# Test ipv6_chkip with compressed ipv4 style, too many adjacent :
$x = Net::IPv6Addr::ipv6_chkip(":::ffff:192.168.0.1"); 
ok(not defined $x);

# Test ipv6_chkip with compressed ipv4 style, too many ipv6 digits.
$x = Net::IPv6Addr::ipv6_chkip("::fffff:192.168.0.1"); 
ok(not defined $x);

# Test ipv6_chkip with compressed ipv4 style, too many ipv4 digits.
$x = Net::IPv6Addr::ipv6_chkip("::ffff:1923.168.0.1"); 
ok(not defined $x);

# Test ipv6_chkip with compressed ipv4 style, not enough :
$x = Net::IPv6Addr::ipv6_chkip(":ffff:192.168.0.1"); 
ok(not defined $x);

# Test ipv6_chkip with compressed ipv4 style, too many .
$x = Net::IPv6Addr::ipv6_chkip("::ffff:192.168.0.1.2"); 
ok(not defined $x);

# Test ipv6_chkip with compressed ipv4 style, not enough .
$x = Net::IPv6Addr::ipv6_chkip("::ffff:192.168.0"); 
ok(not defined $x);

# Test ipv6_chkip with compressed ipv4 style, adjacent .
$x = Net::IPv6Addr::ipv6_chkip("::ffff:192.168..0.1"); 
ok(not defined $x);

# Test ipv6_chkip with compressed ipv4 style.
$x = Net::IPv6Addr::ipv6_chkip("::ffff:192.168.0.1"); 
ok(ref $x, 'CODE');

eval {
    Net::IPv6Addr::ipv6_parse ('failburger');
};
ok ($@, "failed to parse nonsense");
unlike ($@, qr!Net::IPv6Addr::Net::IPv6Addr!,
	"Did not get Clement Freud output");
done_testing ();
