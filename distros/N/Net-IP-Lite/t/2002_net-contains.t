use strict;
use warnings;
use Test::More;

use lib './t/lib';

use Net::IP::Lite;
use Test::Net::IP::Lite;

sub test_contains_str {
	my ($addr, $range) = @_;
	my $net = Net::IP::Lite::Net->new($range);
	return 0 unless $net;
	return $net->contains($addr);
}

sub test_contains_obj {
	my ($addr, $range) = @_;
	my $ip = Net::IP::Lite->new($addr) || die "Invalid IP address '$addr'";
	my $net = Net::IP::Lite::Net->new($range) || die "Invalid network definition '$addr'";
	return 0 unless $net;
	return $net->contains($addr);
}

sub test_in_range {
	my ($addr, $range, $extra_net) = @_;
	my $ip = Net::IP::Lite->new($addr) || die "Invalid IP address '$addr'";
	my $net = Net::IP::Lite::Net->new($range) || die "Invalid network definition '$addr'";
	if ($extra_net) {
		return $ip->in_range([$extra_net, $net]);
	} else {
		return $ip->in_range($net);
	}
}

my $count = 0;
for my $comb (@wrong_ip_net) {
	next if ref($comb->[1]) eq 'ARRAY';
	$count++;
	ok !test_contains_str($comb->[0], $comb->[1]), $comb->[2];
	$count++;
	ok !test_contains_obj($comb->[0], $comb->[1]), $comb->[2];
	$count++;
	ok !test_in_range($comb->[0], $comb->[1]), $comb->[2];
	$count++;
	ok !test_in_range($comb->[0], $comb->[1], '111.111/32'), $comb->[2];
}

$count += scalar @ipv4_in_range << 2;
for my $args (@ipv4_in_range) {
	ok test_contains_str($args->[0], $args->[1]), "IPv4 address '$args->[0]' is in the range '$args->[1]'";
	ok test_contains_obj($args->[0], $args->[1]), "IPv4 address '$args->[0]' is in the range '$args->[1]'";
	ok test_in_range($args->[0], $args->[1]), "IPv4 address '$args->[0]' is in the range '$args->[1]'";
	ok test_in_range($args->[0], $args->[1], '111.111'), "IPv4 address '$args->[0]' is in the range '$args->[1]'";
}

$count += scalar @ipv4_not_in_range << 2;
for my $args (@ipv4_not_in_range) {
	ok !test_contains_str($args->[0], $args->[1]), "IPv4 address '$args->[0]' is not in the range '$args->[1]'";
	ok !test_contains_obj($args->[0], $args->[1]), "IPv4 address '$args->[0]' is not in the range '$args->[1]'";
	ok !test_in_range($args->[0], $args->[1]), "IPv4 address '$args->[0]' is not in the range '$args->[1]'";
	ok !test_in_range($args->[0], $args->[1], '111.111'), "IPv4 address '$args->[0]' is not in the range '$args->[1]'";
}

$count += scalar @ipv6_in_range << 2;
for my $args (@ipv6_in_range) {
	ok test_contains_str($args->[0], $args->[1]), "IPv6 address '$args->[0]' is in the range '$args->[1]'";
	ok test_contains_obj($args->[0], $args->[1]), "IPv6 address '$args->[0]' is in the range '$args->[1]'";
	ok test_in_range($args->[0], $args->[1], '1111::1111'), "IPv6 address '$args->[0]' is in the range '$args->[1]'";
	ok test_in_range($args->[0], $args->[1], '1111::1111'), "IPv6 address '$args->[0]' is in the range '$args->[1]'";
}

$count += scalar @ipv6_not_in_range << 2;
for my $args (@ipv6_not_in_range) {
	ok !test_contains_str($args->[0], $args->[1]), "IPv6 address '$args->[0]' is not in the range '$args->[1]'";
	ok !test_contains_obj($args->[0], $args->[1]), "IPv6 address '$args->[0]' is not in the range '$args->[1]'";
	ok !test_in_range($args->[0], $args->[1], '1111::1111'), "IPv6 address '$args->[0]' is not in the range '$args->[1]'";
	ok !test_in_range($args->[0], $args->[1], '1111::1111'), "IPv6 address '$args->[0]' is not in the range '$args->[1]'";
}

done_testing($count);
