use Test::More;
use strict;
use warnings;
use lib './lib';

use NetAddr::IP::LazyInit;

my $ipcidr = NetAddr::IP::LazyInit->new( '10.10.10.5/24' );
my $ipmask = NetAddr::IP::LazyInit->new( '10.10.10.5', '255.255.255.0' );
my $ip6 = NetAddr::IP::LazyInit->new( 'fe80::/64' );
my $ip = NetAddr::IP::LazyInit->new( '10.10.10.5' );

is($ipcidr->addr, '10.10.10.5', 'Can we extract just the IP (cidr)');
is($ipmask->addr, '10.10.10.5', 'Can we extract just the IP (netmask)');
is($ip6->addr, 'fe80::', 'Can we extract just the IP for IPv6');
is($ip->addr, '10.10.10.5', 'No CIDR/subnet');

done_testing();
