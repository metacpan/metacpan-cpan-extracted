use strict;
use warnings;
use Test::More;

use lib './t/lib';

use Net::IP::Lite;
use Test::Net::IP::Lite;

sub test_new {
	my ($net, $bin_net, $bin_mask) = @_;
	$net = Net::IP::Lite::Net->new($net);
	return 0 unless $net;
	if (defined $bin_net) {
		return 0 if $net->binary ne $bin_net;
	}
	if (defined $bin_mask) {
		return 0 if $net->mask->binary ne $bin_mask;
	}
	return 1;
}

my $count = invalid(\&test_new, ['$']);

$count += scalar @wrong_net;
for my $net (@wrong_net) {
	ok ! test_new($net->[1]), $net->[2];
}

$count += scalar @invalid_ipv4;
for my $addr (@invalid_ipv4) {
	if ($addr->[0] =~ /\s/) {
		$count--;
		next;
	}
	ok ! test_new("10.0.0.0 $addr->[0]"), "Die on wrong IPv4 mask '$addr->[0]'";
}

$count += scalar @invalid_ipv6;
for my $addr (@invalid_ipv6) {
	if ($addr->[0] =~ /\s/) {
		$count--;
		next;
	}
	ok ! test_new(":: $addr->[0]"), "Die on wrong IPv6 mask '$addr->[0]'";
}


$count += scalar @valid_ipv4 << 1;
for my $addr (@valid_ipv4) {
	ok test_new($addr->[0], $addr->[1]), "Test valid IPv4 network '$addr->[0]'";
	ok test_new("10.0.0.0 $addr->[0]", undef, $addr->[1]), "Test valid IPv4 mask'$addr->[0]'";
}

$count += scalar @valid_ipv6 << 1;
for my $addr (@valid_ipv6) {
	ok test_new($addr->[0], $addr->[1]), "Test valid IPv6 network '$addr->[0]'";
	ok test_new(":: $addr->[0]", undef, "$addr->[1]"), "Test valid IPv6 mask'$addr->[0]'";
}

$count += 129;
for (my $mask = 0; $mask < 129; $mask++) {
	my $bin_mask = ('1' x $mask) . ('0' x (128 - $mask));
	ok test_new("::/$mask", undef, $bin_mask), "Test /$mask mask";
}

done_testing($count);
