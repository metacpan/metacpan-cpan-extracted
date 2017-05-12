use strict;
use warnings;
use Test::More;
use Test::Exception;

use lib './t/lib';

use Net::IP::Lite;
use Test::Net::IP::Lite;

sub test_equal_v4_str {
	my ($addr1, $addr2) = @_;
	my $ip = Net::IP::Lite->new($addr1) || die "Invalid IP address '$addr1'";;
	return $ip->equal_v4($addr2);
}

sub test_equal_v4_obj {
	my ($addr1, $addr2) = @_;
	my $ip1 = Net::IP::Lite->new($addr1) || die "Invalid IP address '$addr1'";;
	my $ip2 = Net::IP::Lite->new($addr2) || die "Invalid IP address '$addr2'";;
	return $ip1->equal_v4($ip2);
}

my $count = die_on_invalid(\&test_equal_v4_str, ['192.168.0.1', '$']);

$count += scalar @valid_ipv6 << 1;
for my $addr (@valid_ipv6) {
	dies_ok { test_equal_v4_str($addr->[0], '127.0.0.1') } "Die on valid IPv6: '$addr->[0] (1)'";
	dies_ok { test_equal_v4_str('127.0.0.1', $addr->[0]) } "Die on valid IPv6: '$addr->[0] (2)'";
}

$count += scalar @ipv4_equal << 1;
for my $addr (@ipv4_equal) {
	ok test_equal_v4_str($addr->[0], $addr->[1]), "Equivalent IPv4: '$addr->[0]' eq '$addr->[1]'";
	ok test_equal_v4_obj($addr->[0], $addr->[1]), "Equivalent IPv4: '$addr->[0]' eq '$addr->[1]'";
}

$count += scalar @ipv4_not_equal << 1;
for my $addr (@ipv4_not_equal) {
	ok !test_equal_v4_str($addr->[0], $addr->[1]), "Nonequivalent IPv4: '$addr->[0]' eq '$addr->[1]'";
	ok !test_equal_v4_obj($addr->[0], $addr->[1]), "Nonequivalent IPv4: '$addr->[0]' eq '$addr->[1]'";
}

$count += scalar @ipv6ipv4_equal << 1;
for my $addr (@ipv6ipv4_equal) {
	ok test_equal_v4_str($addr->[0], $addr->[1]), "Equivalent IPv6IPv4: '$addr->[0]' ne '$addr->[1]'";
	ok test_equal_v4_obj($addr->[0], $addr->[1]), "Equivalent IPv6IPv4: '$addr->[0]' ne '$addr->[1]'";
}

$count += scalar @ipv6ipv4_not_equal << 1;
for my $addr (@ipv6ipv4_not_equal) {
	ok !test_equal_v4_str($addr->[0], $addr->[1]), "Nonequivalent IPv6IPv4: '$addr->[0]' ne '$addr->[1]'";
	ok !test_equal_v4_obj($addr->[0], $addr->[1]), "Nonequivalent IPv6IPv4: '$addr->[0]' ne '$addr->[1]'";
}

$count += scalar @wrong_ipv6ipv4 << 1;
for my $addr (@wrong_ipv6ipv4) {
	dies_ok { test_equal_v4_str($addr->[0], '127.0.0.1') } "Die on not IPv6IPv4 '$addr->[0]' to IPv4";
	dies_ok { test_equal_v4_str($addr->[0], '127.0.0.1') } "Die on not IPv6IPv4 '$addr->[0]' to IPv4";
}

done_testing($count);
