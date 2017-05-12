use strict;
use warnings;
use Test::More;

use lib './t/lib';

use Net::IP::Lite;
use Test::Net::IP::Lite;

sub test_new {
	my $addr = shift;
	my $ip = Net::IP::Lite->new($addr);
	return 0 unless $ip; 
	return $ip->binary eq ip2bin($addr);
}

my $count = invalid(\&Net::IP::Lite::new, [ 'Net::IP::Lite', '$' ]);

$count += scalar @valid_ipv4;
for my $addr (@valid_ipv4) {
	ok test_new($addr->[0]), "Valid IPv4: '$addr->[0]'";
}

$count += scalar @valid_ipv6;
for my $addr (@valid_ipv6) {
	ok test_new($addr->[0]), "Valid IPv6: '$addr->[0]'";
}

$count += scalar @valid_ipv6_ipv4;
for my $addr (@valid_ipv6_ipv4) {
	ok test_new($addr->[0]), "Valid IPv6->IPv4: '$addr->[0]'";
}

done_testing($count);
