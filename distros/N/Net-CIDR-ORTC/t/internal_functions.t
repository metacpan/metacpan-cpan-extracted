#!/usr/bin/perl
# $Id: internal_functions.t 414 2012-11-29 12:05:27Z ayuzhaninov $

use strict;
use warnings;

use Test::More;

BEGIN {
	use_ok('Net::CIDR::ORTC')
}

*dd2int = \&Net::CIDR::ORTC::dd2int;

is( dd2int('0.0.0.0'), 0, '0.0.0.0');
is( dd2int('1.1.1.1'), 0x01010101, '1.1.1.1');
is( dd2int('255.255.255.255'), 0xffffffff, '255.255.255.255');
is( dd2int('255.0.0.0'), 0xff000000, '255.0.0.0');
is( dd2int('109.61.207.53'), 1832767285, '109.61.207.53');
is( dd2int('2.132.156.124'), 42245244 ,'2.132.156.124');
is( dd2int('213.228.93.109'), 3588513133 ,'213.228.93.109');

*int2dd = \&Net::CIDR::ORTC::int2dd;

is( int2dd(0), '0.0.0.0', '0.0.0.0');
is( int2dd(0x01010101), '1.1.1.1', '1.1.1.1');
is( int2dd(0xffffffff), '255.255.255.255', '255.255.255.255');

for (1 .. 10) {
	my $i = int rand(0xffffffff);
	is( dd2int(int2dd($i)), $i, "int IP $i");
}

*len2mask = \&Net::CIDR::ORTC::len2mask;

is( len2mask(32), 0xffffffff, '/32');
is( len2mask(31), dd2int('255.255.255.254'), '/31');
is( len2mask(24), 0xffffff00, '/24');
is( len2mask(16), 0xffff0000, '/16');
is( len2mask(8), 0xff000000, '/8');
is( len2mask(0), 0x00000000, '/0');

*is_valid_prefix = \&Net::CIDR::ORTC::is_valid_prefix;

ok( is_valid_prefix(dd2int('192.168.0.0'), 16), '192.168.0.0/16');
ok( is_valid_prefix(dd2int('192.168.0.8'), 29), '192.168.0.8/29');
ok( !is_valid_prefix(dd2int('192.168.0.192'), 24), '192.168.0.192/24');
ok( !is_valid_prefix(dd2int('192.168.0.4'), 29), '192.168.0.4/29');

done_testing();
