use strict;
use Test::More;
use Net::IPv6Addr qw/ipv6_parse is_ipv6/;

# Yeah, so I was listening to it when I wrote the test.
my $input = "sunshine of your love";
eval { Net::IPv6Addr::ipv6_parse($input); };
ok($@, "Error with bad address");
like($@, qr/invalid IPv6 address/, "correct error message");
ok (! is_ipv6 ($input), "Bad address not accepted");

$input = "::/x";
eval { Net::IPv6Addr::ipv6_parse($input); };
ok($@, "Error with $input");
like($@, qr/non-numeric prefix length/, "Reject non-numeric prefix length");
ok (! is_ipv6 ($input), "Reject non-numeric prefix length");

$input = "::/-19325";
eval { Net::IPv6Addr::ipv6_parse($input); };
ok($@, "error with negative prefix");
like($@, qr/non-numeric prefix length/, "Reject negative prefix length");
ok (! is_ipv6 ($input), "Reject negative prefix length");

$input = "::/65389";
eval { Net::IPv6Addr::ipv6_parse($input); };
ok($@, "error with $input");
like($@, qr/invalid prefix length/, "Reject excessive prefix length");
ok (! is_ipv6 ($input), "Reject excessive prefix length");

$input = "a:b:c:d:0:1:2:3";
is(scalar(Net::IPv6Addr::ipv6_parse($input)), $input,
   "Valid address OK (ipv6_parse)");
ok (is_ipv6 ($input), "Valid address OK (is_ipv6)");

$input = "a::/24";
my ($x, $y) = Net::IPv6Addr::ipv6_parse($input);
is($x, "a::", "Valid address OK");
is($y, 24, "Valid address OK");
ok (is_ipv6 ($input), "Valid address OK");

my @inputs = ('a::', '24');
my ($x2, $y2) = Net::IPv6Addr::ipv6_parse(@inputs);
is($x2, "a::", "Valid address OK");
is($y2, 24, "Valid address OK");
ok (is_ipv6 (@inputs), "Valid address OK");

done_testing ();
