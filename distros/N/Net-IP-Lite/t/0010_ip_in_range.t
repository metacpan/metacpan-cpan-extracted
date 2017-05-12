use strict;
use warnings;
use Test::More;
use Test::Exception;

use lib './t/lib';

use Net::IP::Lite;
use Test::Net::IP::Lite;

my $count = die_on_invalid(\&ip_in_range, [ '$', '192.168.0.1' ]);
$count += die_on_invalid(\&ip_in_range, [ '192.168.0.1', '$' ]);

$count += scalar @wrong_ip_net;
for my $comb (@wrong_ip_net) {
	ok !ip_in_range($comb->[0], $comb->[1]), $comb->[2];
}

$count += scalar @wrong_net;
for my $net (@wrong_net) {
	dies_ok {ip_in_range($net->[0], $net->[1]) } $net->[2];
}

$count += scalar @invalid_ipv4;
for my $addr (@invalid_ipv4) {
	if ($addr->[0] =~ /^\s|\s$/) {
		$count--;
		next;
	}
	dies_ok { ip_in_range('10.0.0.0', "10.0.0.0 $addr->[0]") } "Die on wrong IPv4 mask '$addr->[0]'";
}

$count += scalar @invalid_ipv6;
for my $addr (@invalid_ipv6) {
	if ($addr->[0] =~ /^\s|\s$/) {
		$count--;
		next;
	}
	dies_ok { ip_in_range('::', ":: $addr->[0]") } "Die on wrong IPv6 mask '$addr->[0]'";
}


$count += scalar @ipv4_in_range * 3;
for my $args (@ipv4_in_range) {
	ok ip_in_range($args->[0], $args->[1]), "IPv4 address '$args->[0]' is in the range '$args->[1]'";
	my @nets = ('1.1.1.1');
	ok !ip_in_range($args->[0], \@nets), "IPv4 address '$args->[0]' is not in the range '@nets'";
	push @nets, $args->[1];
	ok ip_in_range($args->[0], \@nets), "IPv4 address '$args->[0]' is in the range '" . join(', ', @nets) . "'";
}

$count += scalar @ipv4_not_in_range * 3;
for my $args (@ipv4_not_in_range) {
	ok !ip_in_range($args->[0], $args->[1]), "IPv4 address '$args->[0]' is not in the range '$args->[1]'";
	my @nets = ('0/0');
	ok ip_in_range($args->[0], \@nets), "IPv4 address '$args->[0]' is in the range '@nets'";
	unshift @nets, $args->[1];
	ok ip_in_range($args->[0], \@nets), "IPv4 address '$args->[0]' is in the range '" . join(', ', @nets) . "'";
}

$count += scalar @ipv6_in_range * 3;
for my $args (@ipv6_in_range) {
	ok ip_in_range($args->[0], $args->[1]), "IPv6 address '$args->[0]' is in the range '$args->[1]'";
	my @nets = ('cc::cc');
	ok !ip_in_range($args->[0], \@nets), "IPv6 address '$args->[0]' is not in the range '@nets'";
	push @nets, $args->[1];
	ok ip_in_range($args->[0], \@nets), "IPv6 address '$args->[0]' is in the range '" . join(', ', @nets) . "'";
}

$count += scalar @ipv6_not_in_range * 3;
for my $args (@ipv6_not_in_range) {
	ok !ip_in_range($args->[0], $args->[1]), "IPv6 address '$args->[0]' is not in the range '$args->[1]'";
	my @nets = ('::/0');
	ok ip_in_range($args->[0], \@nets), "IPv6 address '$args->[0]' is in the range '@nets'";
	unshift @nets, $args->[1];
	ok ip_in_range($args->[0], \@nets), "IPv6 address '$args->[0]' is in the range '" . join(', ', @nets) . "'";
}

done_testing($count);
