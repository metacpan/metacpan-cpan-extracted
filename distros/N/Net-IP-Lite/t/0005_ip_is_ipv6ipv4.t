use strict;
use warnings;
use Test::More;

use lib './t/lib';

use Net::IP::Lite;
use Test::Net::IP::Lite;

my $count = invalid(\&ip_is_ipv6ipv4);

$count += scalar @valid_ipv4;
for my $addr (@valid_ipv4) {
	ok !ip_is_ipv6ipv4($addr->[0]), "Valid IPv4: '$addr->[0]'";
}

$count += scalar @valid_ipv6;
for my $addr (@valid_ipv6) {
	ok !ip_is_ipv6ipv4($addr->[0]), "Valid IPv6: '$addr->[0]'";
}

$count += scalar @valid_ipv6_ipv4;
for my $addr (@valid_ipv6_ipv4) {
	ok ip_is_ipv6ipv4($addr->[0]), "Valid IPv6->IPv4: '$addr->[0]'";
}

done_testing($count);
