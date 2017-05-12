use strict;
use Test;
BEGIN { 
    eval { require Math::Base85; };
    if ($@) {
	print "1..0 # Math::Base85 is not installed\n";
	exit 0;
    }
}
BEGIN { plan test => 29; }

use Net::IPv6Addr;
ok(1);

# Test ipv6_parse_base85 with garbage.

eval { Net::IPv6Addr::ipv6_parse_base85("\n"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_base85 with a bad character.
eval { Net::IPv6Addr::ipv6_parse_base85("abcdefghi klmnopqrst"); };
ok($@);
ok($@, qr/invalid address/);


# Test ipv6_parse_base85 with a bad length.
eval { Net::IPv6Addr::ipv6_parse_base85("abcdefghijklmnopqrs"); };
ok($@);
ok($@, qr/invalid address/);

# Test ipv6_parse_base85 with good stuff.
# Example stolen from rfc1924.txt
my @pieces = Net::IPv6Addr::ipv6_parse_base85("4)+k&C#VzJ4br>0wv%Yp");
ok($pieces[0], 0x1080);
ok($pieces[1], 0);
ok($pieces[2], 0);
ok($pieces[3], 0);
ok($pieces[4], 0x8);
ok($pieces[5], 0x800);
ok($pieces[6], 0x200C);
ok($pieces[7], 0x417A);

my $x;
# Test new with bad base85 digits.
eval { $x = new Net::IPv6Addr("0123456789ABCDEF GHI"); };
ok($@);
ok($@, qr/invalid IPv6 address/);

# Test new with bad base85 length.
eval { $x = new Net::IPv6Addr("0123456789ABCDEFGHI"); };
ok($@);
ok($@, qr/invalid IPv6 address/);

# Test new with good base85.
$x = new Net::IPv6Addr("4)+k&C#VzJ4br>0wv%Yp");
ok(ref $x, 'Net::IPv6Addr');
ok($x->[0], 0x1080);
ok($x->[1], 0);
ok($x->[2], 0);
ok($x->[3], 0);
ok($x->[4], 8);
ok($x->[5], 0x800);
ok($x->[6], 0x200C);
ok($x->[7], 0x417A);

# Test to_string_base85.
ok($x->to_string_base85(), "4)+k&C#VzJ4br>0wv%Yp");
