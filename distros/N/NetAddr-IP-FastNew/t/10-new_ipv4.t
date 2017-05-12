use Test::More;
use strict;
use warnings;
use lib './lib';

use NetAddr::IP::FastNew;

my $ip = NetAddr::IP::FastNew->new_ipv4( '10.10.10.5' );
my $ipmask = NetAddr::IP::FastNew->new_ipv4_mask( '10.10.10.5', '255.255.255.0' );
my $ipcidr = NetAddr::IP::FastNew->new_ipv4_cidr( '10.10.10.5/24' );

is($ipmask->mask, '255.255.255.0', 'netmask');
is($ipmask->addr, '10.10.10.5', 'address for ipmask');
is($ip->addr, '10.10.10.5', 'address for ip');
is($ipcidr->addr, '10.10.10.5', 'address for ipcidr');
is($ipcidr->mask, '255.255.255.0', 'mask for ipcidr');

done_testing();
