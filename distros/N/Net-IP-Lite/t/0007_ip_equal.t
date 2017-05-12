use strict;
use warnings;
use Test::More;

use lib './t/lib';

use Net::IP::Lite;
use Test::Net::IP::Lite;

my $count = die_on_invalid(\&ip_equal, [ '$', '192.168.0.1' ]);
$count += die_on_invalid(\&ip_equal, [ '192.168.0.1', '$' ]);

$count += scalar @ipv4_equal;
for my $addr (@ipv4_equal) {
	ok ip_equal($addr->[0], $addr->[1]), "Equivalent IPv4: '$addr->[0]' eq '$addr->[1]'";
}

$count += scalar @ipv6_equal;
for my $addr (@ipv6_equal) {
	ok ip_equal($addr->[0], $addr->[1]), "Equivalent IPv6: '$addr->[0]' eq '$addr->[1]'";
}

$count += scalar @ipv4_not_equal;
for my $addr (@ipv4_not_equal) {
	ok !ip_equal($addr->[0], $addr->[1]), "Nonequivalent IPv4: '$addr->[0]' ne '$addr->[1]'";
}

$count += scalar @ipv6_not_equal;
for my $addr (@ipv6_not_equal) {
	ok !ip_equal($addr->[0], $addr->[1]), "Nonequivalent IPv6: '$addr->[0]' ne '$addr->[1]'";
}

$count += scalar @ipv6ipv4_equal;
for my $addr (@ipv6ipv4_equal) {
	ok !ip_equal($addr->[0], $addr->[1]), "Nonequivalent IPv6IPv4s: '$addr->[0]' ne '$addr->[1]'";
}

done_testing($count);
