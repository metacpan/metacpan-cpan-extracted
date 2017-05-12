#!/usr/bin/perl
# $Id: class.t 420 2012-12-06 10:38:10Z ayuzhaninov $

use strict;
use warnings;

use Test::More tests => 12;

BEGIN {
	use_ok('Net::CIDR::ORTC')
}

my $map = Net::CIDR::ORTC->new();

isa_ok($map, 'Net::CIDR::ORTC');

$map->add('0.0.0.0/0', 0);
$map->add('1.0.0.0/24', 'AS15169');
$map->add('1.0.16.0/23', 'AS2519');
$map->add('1.0.18.0/23', 'AS2519');
$map->add('1.0.18.0/24', 'AS2519');

is( scalar @{ $map->list }, 5, '5 prefixes was added');

$map->compress();

is( scalar @{ $map->list }, 3, 'and compressed to 3 prefixes');

$map->remove('0.0.0.0/0');

is_deeply($map->list, [ ['1.0.0.0/24', 'AS15169'], ['1.0.16.0/22', 'AS2519'] ],
	'aggreagated list 1');

undef $map;

$map = Net::CIDR::ORTC->new();
$map->add('0.0.0.0/0', 2);
$map->add('0.0.0.0/2', 1);
$map->add('128.0.0.0/2', 1);
$map->add('192.0.0.0/2', 3);
$map->compress();

is_deeply($map->list, [ ['0.0.0.0/0', 1], ['64.0.0.0/2', 2], ['192.0.0.0/2', 3] ],
	'sample from MSR-TR-98-59');

undef $map;

$map = Net::CIDR::ORTC->new();
$map->add('0.0.0.0/0', 0);
$map->add('192.168.1.0/24', 1);
$map->add('192.168.2.0/24', 1);
$map->add('192.168.3.0/24', 2);
$map->compress();

# sometimes this algorithm makes unnecessary changes :(
is_deeply($map->list, [ ['0.0.0.0/0', 0], ['192.168.0.0/22', 1], ['192.168.0.0/24', 0], ['192.168.3.0/24', 2] ],
	'create less specifix prefix overlap :(');

undef $map;

$map = Net::CIDR::ORTC->new();
$map->add('0.0.0.0/0', 0);
$map->add('192.168.0.0/24', '1');
$map->add('192.168.1.0/24', '1');
$map->add('192.168.0.0/23', '2');

$map->compress();

is_deeply($map->list, [ ['0.0.0.0/0', 0], ['192.168.0.0/23', 1] ],
	'longer prefixes wins in case of overlap');

undef $map;

$map = Net::CIDR::ORTC->new();

my $d = [
	['0.0.0.0/0', 0],
	['192.168.7.0/24', 1],
	['192.168.8.0/24', 1],
];

foreach my $p (@$d) {
	$map->add($p->[0], $p->[1]);
}

$map->compress();

is_deeply($map->list, $d, 'uncompressible data');

undef $map;

$map = Net::CIDR::ORTC->new();

$d = [
	['0.0.0.0/0', 0],
	['192.168.0.0/24', 1],
	['192.168.1.0/24', 2],
	['192.168.2.0/24', 3],
	['192.168.3.0/24', 4],
	['192.168.4.0/24', 1],
	['192.168.5.0/24', 2],
	['192.168.6.0/24', 3],
	['192.168.7.0/24', 4],
];

foreach my $p (@$d) {
	$map->add($p->[0], $p->[1]);
}

$map->compress();

is_deeply($map->list, $d, 'uncompressible data2');

undef $map;

# some real life data
$map = Net::CIDR::ORTC->new();
$map->add('0.0.0.0/0', '00000000');
$map->add('1.0.0.0/24', '00003b41');
$map->add('1.0.128.0/17', '00002609');
$map->add('1.0.128.0/18', '00002609');
$map->add('1.0.129.0/24', '00005da1');
$map->add('1.0.16.0/23', '000009d7');
$map->add('1.0.18.0/23', '000009d7');
$map->add('1.0.192.0/18', '00002609');
$map->add('1.0.20.0/23', '000009d7');
$map->add('1.0.22.0/23', '000009d7');
$map->add('1.0.224.0/19', '00002609');

$map->compress();

my $r = [
	['0.0.0.0/0', '00000000'],
	['1.0.0.0/24', '00003b41'],
	['1.0.16.0/21', '000009d7'],
	['1.0.128.0/17', '00002609'],
	['1.0.129.0/24', '00005da1'],
];

is_deeply($map->list, $r, 'some real data');

$map->compress();

is_deeply($map->list, $r, 'same after 2nd compress');
