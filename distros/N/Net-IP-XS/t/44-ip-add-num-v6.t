#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 18;

use Net::IP::XS qw(:PROC);

my $ip = Net::IP::XS->new('::/0');
is($ip->intip(), 0, 'Got correct intip');
is($ip->last_int(), '340282366920938463463374607431768211455', 
    'Got correct last_int');

$ip += 16777216;
is($ip->intip(), 16777216, 'Got correct intip after addition');
is($ip->last_int(), '340282366920938463463374607431768211455', 
    'Got correct last_int after addition');
is($ip->print(),
    '0000:0000:0000:0000:0000:0000:0100:0000 - '.
    'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff',
    'Stringification after addition');

$ip = Net::IP::XS->new('::/128');
is($ip->intip(), 0, 'Got correct intip');
is($ip->last_int(), 0, 'Got correct last_int');
$ip += 1;
is($ip, undef, 'Got undef on addition outside bounds');

$ip = Net::IP::XS->new('::/127');
is($ip->intip(), 0, 'Got correct intip');
is($ip->last_int(), 1, 'Got correct last_int');
$ip += 1;
is($ip->intip(), 1, 'Got correct intip (+1)');
is($ip->last_int(), 1, 'Got correct last_int (+1)');
$ip += 1;
is($ip, undef, 'Got undef on addition outside bounds');

$ip = Net::IP::XS->new('::/0');
my $count = 0;
while ($ip = $ip + '1000000000000000000000000000000000000') {
    $count++;
}
is($count, 340, 'Addition failed at correct point');

$ip = Net::IP::XS->new('::/0');
$ip += '340282366920938463463374607431768211456';
is($ip, undef, 'Got undef on trying to add a number that is too large (1)');

$ip = Net::IP::XS->new('::/0');
$ip += '9' x 256;
is($ip, undef, 'Got undef on trying to add a number that is too large');

$ip = Net::IP::XS->new('::/128');
$ip += -1;
is($ip, undef, 'Got undef on trying to add negative number');

$ip = Net::IP::XS->new('::/0');
$ip += '340282366920938463463374607431768211455';
is($ip->ip(), 'ffff:ffff:ffff:ffff:ffff:ffff:ffff:ffff',
    'IP set correctly (added largest possible integer');

1;
