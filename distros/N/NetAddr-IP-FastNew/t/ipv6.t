use Test::More;
use strict;
use warnings;
use lib './lib';

use NetAddr::IP::FastNew;
use NetAddr::IP qw (:lower);

my $ip = NetAddr::IP::FastNew->new_ipv6( 'fe80::/64' );

is($ip->masklen, '64', 'is the cidr correct');
is($ip->short, 'fe80::', 'address for ip');

done_testing();
