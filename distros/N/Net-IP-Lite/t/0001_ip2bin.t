use strict;
use warnings;
use Test::More;

use lib './t/lib';

use Net::IP::Lite;
use Test::Net::IP::Lite;

my $count = invalid(\&ip2bin);

$count += scalar @Test::IPAddrTest::valid_ipv4;
for my $addr (@Test::IPAddrTest::valid_ipv4) {
	ok ip2bin($addr->[0]) eq $addr->[1], "Valid IPv4: '$addr->[0]'";
}

$count += scalar @Test::IPAddrTest::valid_ipv6;
for my $addr (@Test::IPAddrTest::valid_ipv6) {
	ok ip2bin($addr->[0]) eq $addr->[1], "Valid IPv6: '$addr->[0]'";
}

$count += scalar @Test::IPAddrTest::valid_ipv6_ipv4;
for my $addr (@Test::IPAddrTest::valid_ipv6_ipv4) {
	ok ip2bin($addr->[0]) eq $addr->[1], "Valid IPv6->IPv4: '$addr->[0]'";
}

done_testing($count);
