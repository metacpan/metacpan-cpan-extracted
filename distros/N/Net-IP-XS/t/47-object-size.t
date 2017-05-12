#!/usr/bin/env perl

use warnings;
use strict;

use Net::IP::XS;

use Test::More tests => 6;

my $ip = Net::IP::XS->new('0.0.0.0/0');
is($ip->size()->bstr(), '4294967296',
    'Got correct size for 0/0');

$ip = Net::IP::XS->new('0.0.0.0/32');
is($ip->size()->bstr(), '1',
    'Got correct size for 0/32');

$ip = Net::IP::XS->new('0.0.0.0/16');
is($ip->size()->bstr(), '65536',
    'Got correct size for 0/16');

$ip = Net::IP::XS->new('0.0.0.0/8');
is($ip->size()->bstr(), '16777216',
    'Got correct size for 0/8');

$ip = Net::IP::XS->new('::/0');
is($ip->size()->bstr(), '340282366920938463463374607431768211456',
    'Got correct size for ::/0');

$ip = Net::IP::XS->new('::/128');
is($ip->size()->bstr(), '1',
    'Got correct size for ::/128');

1;
