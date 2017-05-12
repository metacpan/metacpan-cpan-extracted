use strict;
use warnings;
use Test::More;

use lib './t/lib';

use Net::IP::Lite;
use Test::Net::IP::Lite;

sub test_binary {
	my $ip = Net::IP::Lite->new(shift) || die 'Failed to construct Net::IP::Lite';
	return $ip->binary;
}

my $count = scalar @valid_ipv4;
for my $addr (@valid_ipv4) {
	ok test_binary($addr->[0]) eq $addr->[1], "IPv4: '$addr->[0]'";
}

$count += scalar @valid_ipv6;
for my $addr (@valid_ipv6) {
	ok test_binary($addr->[0]) eq $addr->[1], "IPv6: '$addr->[0]'";
}

$count += scalar @valid_ipv6_ipv4;
for my $addr (@valid_ipv6_ipv4) {
	ok test_binary($addr->[0]) eq $addr->[1], "IPv6->IPv4: '$addr->[0]'";
}

done_testing($count);
