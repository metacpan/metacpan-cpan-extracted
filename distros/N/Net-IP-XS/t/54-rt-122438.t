#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 2;

use Net::IP::XS;

my $ip = Net::IP::XS->new('1.0.0.0-1.255.255.255');
ok($ip, 'Got new object');
is($ip->last_bin(), '00000001111111111111111111111111',
    'Got correct last_bin value');

1;
