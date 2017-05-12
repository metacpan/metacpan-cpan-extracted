#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 16;

use Net::IP::XS qw(:PROC);

my $ip = Net::IP::XS->new('0/0');
is($ip->intip(), 0, 'Got correct intip');
is($ip->last_int(), '4294967295', 'Got correct last_int');

$ip += 16777216;
is($ip->intip(), 16777216, 'Got correct intip after addition');
is($ip->last_int(), '4294967295', 'Got correct last_int after addition');
is($ip->print(), '1.0.0.0 - 255.255.255.255', 
    'Stringification after addition');

$ip = Net::IP::XS->new('0/32');
is($ip->intip(), 0, 'Got correct intip');
is($ip->last_int(), 0, 'Got correct last_int');
$ip += 1;
is($ip, undef, 'Got undef on addition outside bounds');

$ip = Net::IP::XS->new('0/31');
is($ip->intip(), 0, 'Got correct intip');
is($ip->last_int(), 1, 'Got correct last_int');
$ip += 1;
is($ip->intip(), 1, 'Got correct intip (+1)');
is($ip->last_int(), 1, 'Got correct last_int (+1)');
$ip += 1;
is($ip, undef, 'Got undef on addition outside bounds');

$ip = Net::IP::XS->new('0/0');
my $count = 0;
while ($ip = $ip + 10000000) {
    $count++;
}
is($count, 429, 'Addition failed at correct point');

$ip = Net::IP::XS->new('0/0');
$ip += '9' x 256;
is($ip, undef, 'Got undef on trying to add a number that is too large');

$ip = Net::IP::XS->new('0');
$ip += -1;
is($ip, undef, 'Got undef of trying to add negative number');

1;
