#!/usr/bin/env perl

use warnings;
use strict;

use Net::IP::XS;

use Test::More tests => 2;

my $ip = Net::IP::XS->new('2001:db8:3:4:5:6:7::/112');
ok($ip, 'IPv6 address is considered valid');
if (not $ip) {
    diag $Net::IP::XS::ERROR;
    diag $Net::IP::XS::ERRNO;
}
is($ip->prefix(), '2001:0db8:0003:0004:0005:0006:0007:0000/112',
    'IPv6 object stringified correctly');

1;
