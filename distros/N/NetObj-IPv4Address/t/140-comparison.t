#!perl
use strict;
use warnings FATAL => 'all';
use 5.014;

BEGIN { chdir 't' if -d 't'; }
use lib '../lib';

use Test::More; END { done_testing; }

use NetObj::IPv4Address;

my $ip1 = NetObj::IPv4Address->new('127.0.0.1');
my $ip2 = NetObj::IPv4Address->new('127.0.0.1');
my $ip3 = NetObj::IPv4Address->new('192.168.0.1');

# numeric comparison
cmp_ok($ip1, '==', $ip1, 'same object: equal numeric');
cmp_ok($ip1, '==', $ip2, 'different object, same IP address: equal numeric');
cmp_ok($ip1, '!=', $ip3, 'different IP address: not equal numeric');

# stringwise comparison
cmp_ok($ip1, 'eq', $ip1, 'same object: equal stringwise');
cmp_ok($ip1, 'eq', $ip2, 'different object, same IP address: equal stringwise');
cmp_ok($ip1, 'ne', $ip3, 'different IP address: not equal stringwise');

# string in second operand of comparison
cmp_ok($ip1, '==', '127.0.0.1', 'comparison with string, numeric');
cmp_ok($ip1, '==', "\x7f\x00\x00\x01", 'comparison with raw binary, numeric');
cmp_ok($ip1, 'eq', '127.0.0.1', 'comparison with string, stringwise');
cmp_ok($ip1, 'eq', "\x7f\x00\x00\x01", 'comparison with raw binary, stringwise');

