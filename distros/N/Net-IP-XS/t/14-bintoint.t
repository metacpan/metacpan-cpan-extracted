#!/usr/bin/env perl

use warnings;
use strict;

use Test::More tests => 13;

use Net::IP::XS qw(ip_bintoint);
use IO::Capture::Stderr;

my $c = IO::Capture::Stderr->new();

my $res = ip_bintoint('1');
isa_ok($res, 'Math::BigInt');
is($res, 1, 'ip_bintoint (single bit)');

$res = ip_bintoint('10101010');
is($res, 170, 'ip_bintoint 2');

$res = ip_bintoint('1' x 128);
is($res, '340282366920938463463374607431768211455', 'ip_bintoint 3');

$res = ip_bintoint('0' x 32);
isa_ok($res, 'Math::BigInt');
is($res, 0, 'ip_bintoint 4');

$res = ip_bintoint('1' x 32);
is($res, '4294967295', 'ip_bintoint 5');

$res = ip_bintoint('0' x 128);
isa_ok($res, 'Math::BigInt');
is($res, 0, 'ip_bintoint 6');

$res = ip_bintoint('0A0B0C0D');
is($res, 85, 'Non-zero treated as 1');

$res = ip_bintoint('1' x 1024);
is($res, '340282366920938463463374607431768211455', 
    'More than 128 bits in bitstring yields the largest 128-bit number');

$c->start();
is(ip_bintoint(undef), 0, 'Got zero on undef');
$c->stop();
is(ip_bintoint(''),    0, 'Got zero on empty string');

1;
