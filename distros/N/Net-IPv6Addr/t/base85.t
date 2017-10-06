use strict;
use Test::More;

use Net::IPv6Addr;

# Test ipv6_parse_base85 with garbage.

eval { Net::IPv6Addr::ipv6_parse_base85("\n"); };
ok($@);
like ($@, qr/invalid address/);

# Test ipv6_parse_base85 with a bad character.
eval { Net::IPv6Addr::ipv6_parse_base85("abcdefghi klmnopqrst"); };
ok($@);
like ($@, qr/invalid address/);


# Test ipv6_parse_base85 with a bad length.
eval { Net::IPv6Addr::ipv6_parse_base85("abcdefghijklmnopqrs"); };
ok($@);
like ($@, qr/invalid address/);

# Test ipv6_parse_base85 with good stuff.
# Example stolen from rfc1924.txt
my @pieces = Net::IPv6Addr::ipv6_parse_base85("4)+k&C#VzJ4br>0wv%Yp");
is ($pieces[0], 0x1080);
is ($pieces[1], 0);
is ($pieces[2], 0);
is ($pieces[3], 0);
is ($pieces[4], 0x8);
is ($pieces[5], 0x800);
is ($pieces[6], 0x200C);
is ($pieces[7], 0x417A);

my $x;
# Test new with bad base85 digits.
eval { $x = new Net::IPv6Addr("0123456789ABCDEF GHI"); };
ok($@);
like ($@, qr/invalid IPv6 address/);

# Test new with bad base85 length.
eval { $x = new Net::IPv6Addr("0123456789ABCDEFGHI"); };
ok($@);
like ($@, qr/invalid IPv6 address/);

# Test new with good base85.
$x = new Net::IPv6Addr("4)+k&C#VzJ4br>0wv%Yp");
is (ref $x, 'Net::IPv6Addr');
is ($x->[0], 0x1080);
is ($x->[1], 0);
is ($x->[2], 0);
is ($x->[3], 0);
is ($x->[4], 8);
is ($x->[5], 0x800);
is ($x->[6], 0x200C);
is ($x->[7], 0x417A);

# Test to_string_base85.
is ($x->to_string_base85(), "4)+k&C#VzJ4br>0wv%Yp");
done_testing ();
