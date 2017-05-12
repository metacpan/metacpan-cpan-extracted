use strict;
use warnings;
use Test::More;

use lib './t/lib';

use Net::IP::Lite;
use Test::Net::IP::Lite;


sub test_equal_v6_str {
	my ($addr1, $addr2) = @_;
	my $ip = Net::IP::Lite->new($addr1) || die "Invalid IP address '$addr1'";;
	return $ip->equal_v6($addr2);
}

sub test_equal_v6_obj {
	my ($addr1, $addr2) = @_;
	my $ip1 = Net::IP::Lite->new($addr1) || die "Invalid IP address '$addr1'";;
	my $ip2 = Net::IP::Lite->new($addr2) || die "Invalid IP address '$addr2'";;
	return $ip1->equal_v6($ip2);
}

my $count = die_on_invalid(\&test_equal_v6_str, ['192.168.0.1', '$']);

$count += scalar @ipv4_equal << 1;
for my $addr (@ipv4_equal) {
	ok test_equal_v6_str($addr->[0], $addr->[1]), "Equivalent IPv4: '$addr->[0]' eq '$addr->[1]'";
	ok test_equal_v6_obj($addr->[0], $addr->[1]), "Equivalent IPv4: '$addr->[0]' eq '$addr->[1]'";
}

$count += scalar @ipv4_not_equal << 1;
for my $addr (@ipv4_not_equal) {
	ok !test_equal_v6_str($addr->[0], $addr->[1]), "Nonequivalent IPv4: '$addr->[0]' eq '$addr->[1]'";
	ok !test_equal_v6_obj($addr->[0], $addr->[1]), "Nonequivalent IPv4: '$addr->[0]' eq '$addr->[1]'";
}

$count += scalar @ipv6_equal << 1;
for my $addr (@ipv6_equal) {
	ok test_equal_v6_str($addr->[0], $addr->[1]), "Equivalent IPv6: '$addr->[0]' eq '$addr->[1]'";
	ok test_equal_v6_obj($addr->[0], $addr->[1]), "Equivalent IPv6: '$addr->[0]' eq '$addr->[1]'";
}

$count += scalar @ipv6_not_equal << 1;
for my $addr (@ipv6_not_equal) {
	ok !test_equal_v6_str($addr->[0], $addr->[1]), "Nonequivalent IPv6: '$addr->[0]' eq '$addr->[1]'";
	ok !test_equal_v6_obj($addr->[0], $addr->[1]), "Nonequivalent IPv6: '$addr->[0]' eq '$addr->[1]'";
}

$count += scalar @ipv6ipv4_equal << 1;
for my $addr (@ipv6ipv4_equal) {
	ok test_equal_v6_str($addr->[0], $addr->[1]), "Equivalent IPv6IPv4: '$addr->[0]' ne '$addr->[1]'";
	ok test_equal_v6_obj($addr->[0], $addr->[1]), "Equivalent IPv6IPv4: '$addr->[0]' ne '$addr->[1]'";
}

$count += scalar @ipv6ipv4_not_equal << 1;
for my $addr (@ipv6ipv4_not_equal) {
	ok !test_equal_v6_str($addr->[0], $addr->[1]), "Nonequivalent IPv6IPv4: '$addr->[0]' ne '$addr->[1]'";
	ok !test_equal_v6_obj($addr->[0], $addr->[1]), "Nonequivalent IPv6IPv4: '$addr->[0]' ne '$addr->[1]'";
}

done_testing($count);
