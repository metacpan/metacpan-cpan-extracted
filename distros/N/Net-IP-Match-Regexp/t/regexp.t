#!/usr/bin/perl -w

BEGIN
{
   use Test::More tests => 21 + 33 * 18 + 16;
   use_ok(Net::IP::Match::Regexp);
}

use strict;
use warnings;
use Net::IP::Match::Regexp qw( create_iprange_regexp create_iprange_regexp_depthfirst match_ip );
use English qw( -no_match_vars );

my $re;


#### Two tests translated from Net-IP-Match-XS.t ####
$re = create_iprange_regexp(qw(10.0.0.0/8 99.99.99.0/1));
ok(!match_ip('207.175.219.202', $re), 'match_ip');
$re = create_iprange_regexp(qw(10.0.0.0/8 192.168.0.0/16 207.175.219.200/29));
ok(match_ip('207.175.219.202', $re), 'match_ip');


#### basic tests ####
$re = create_iprange_regexp('127.0.0.1/32');
ok(match_ip('127.0.0.1', $re), 'match_ip');
ok(!match_ip('127.0.0.2', $re), 'match_ip');

$re = create_iprange_regexp('192.168.0.0/16');
ok(match_ip('192.168.0.1', $re), 'match_ip');
ok(match_ip('192.168.255.255', $re), 'match_ip');
ok(!match_ip('127.0.0.1', $re), 'match_ip');

$re = create_iprange_regexp('209.249.163.0/25');
ok(match_ip('209.249.163.20', $re), 'match_ip');
ok(!match_ip('209.249.163.128', $re), 'match_ip');
ok(!match_ip('209.249.164.0', $re), 'match_ip');

$re = create_iprange_regexp({
   '127.0.0.1/32' => 'localhost',
   '192.168.0.0/16' => 'localnet',
   '209.249.163.0/25' => 'clotho.com',
});
is(match_ip('127.0.0.1', $re), 'localhost', 'match_ip');
is(match_ip('192.168.0.0', $re), 'localnet', 'match_ip');
is(match_ip('209.249.163.20', $re), 'clotho.com', 'match_ip');
is(match_ip('10.0.0.1', $re), undef, 'match_ip');


#### Breadth vs. depth ####

$re = create_iprange_regexp({
   '192.0.0.0/8' => 'wide',
   '192.168.0.0/16' => 'localnet',
   '192.168.0.1/32' => 'router',
});
is(match_ip('192.169.0.4', $re), 'wide', 'breadthfirst');
is(match_ip('192.168.0.4', $re), 'wide', 'breadthfirst');
is(match_ip('192.168.0.1', $re), 'wide', 'breadthfirst');

$re = create_iprange_regexp_depthfirst({
   '192.0.0.0/8' => 'wide',
   '192.168.0.0/16' => 'localnet',
   '192.168.0.1/32' => 'router',
});
is(match_ip('192.200.0.1', $re), 'wide', 'depthfirst');
is(match_ip('192.168.0.4', $re), 'localnet', 'depthfirst');
is(match_ip('192.168.0.1', $re), 'router', 'depthfirst');

#### Methodical tests ####

for my $mask (0..32)
{
   # Notes for my masking math...
   # 127.0.0.0       = 0F.00.00.00
   # 128.0.0.0       = 80.00.00.00
   # 207.0.0.0       = CF.00.00.00
   # 224.0.0.0       = E0.00.00.00
   # 255.255.255.254 = FF.FF.FF.FE
   # 255.255.255.255 = FF.FF.FF.FF

   $re = create_iprange_regexp("0.0.0.0/$mask");
   is(match_ip('0.0.0.0',         $re), $mask > 32 ? undef : 1, "match_ip 0,0/$mask");
   is(match_ip('0.0.0.1',         $re), $mask > 31 ? undef : 1, "match_ip 1,0/$mask");
   is(match_ip('1.2.3.4',         $re), $mask >  7 ? undef : 1, "match_ip 1234,0/$mask");
   is(match_ip('127.0.0.1',       $re), $mask >  1 ? undef : 1, "match_ip 127,0/$mask");
   is(match_ip('128.0.0.0',       $re), $mask >  0 ? undef : 1, "match_ip 128,0/$mask");
   is(match_ip('207.0.0.0',       $re), $mask >  0 ? undef : 1, "match_ip 207,0/$mask");
   is(match_ip('224.0.0.0',       $re), $mask >  0 ? undef : 1, "match_ip 224,0/$mask");
   is(match_ip('255.255.255.254', $re), $mask >  0 ? undef : 1, "match_ip 254,0/$mask");
   is(match_ip('255.255.255.255', $re), $mask >  0 ? undef : 1, "match_ip 255,0/$mask");

   $re = create_iprange_regexp("255.255.255.255/$mask");
   is(match_ip('0.0.0.0',         $re), $mask >  0 ? undef : 1, "match_ip 0,255/$mask");
   is(match_ip('0.0.0.1',         $re), $mask >  0 ? undef : 1, "match_ip 1,255/$mask");
   is(match_ip('1.2.3.4',         $re), $mask >  0 ? undef : 1, "match_ip 1234,255/$mask");
   is(match_ip('127.0.0.1',       $re), $mask >  0 ? undef : 1, "match_ip 127,255/$mask");
   is(match_ip('128.0.0.0',       $re), $mask >  1 ? undef : 1, "match_ip 128,255/$mask");
   is(match_ip('207.0.0.0',       $re), $mask >  2 ? undef : 1, "match_ip 207,255/$mask");
   is(match_ip('224.0.0.0',       $re), $mask >  3 ? undef : 1, "match_ip 224,255/$mask");
   is(match_ip('255.255.255.254', $re), $mask > 31 ? undef : 1, "match_ip 254,255/$mask");
   is(match_ip('255.255.255.255', $re), $mask > 32 ? undef : 1, "match_ip 255,255/$mask");
}


#### A few corner cases (and some to get Devel::Cover to 100%) ####

# Test equivalent ranges
$re = create_iprange_regexp([
   '1.1.1.0/31' => 'foo1',
   '1.1.1.1/31' => 'foo2',
]);
is(match_ip('1.1.1.0', $re), 'foo1', 'equiv ranges');
is(match_ip('1.1.1.1', $re), 'foo1', 'equiv ranges');

# Test overlapping ranges
$re = create_iprange_regexp([
   '1.1.1.0/31' => 'foo1',
   '1.1.1.0/30' => 'foo2',
]);
is(match_ip('1.1.1.0', $re), 'foo2', 'overlapping ranges');
is(match_ip('1.1.1.1', $re), 'foo2', 'overlapping ranges');

# Make sure the order doesn't matter
$re = create_iprange_regexp([
   '1.1.1.0/30' => 'foo2',
   '1.1.1.0/31' => 'foo1',
]);
is(match_ip('1.1.1.0', $re), 'foo2', 'overlapping ranges');
is(match_ip('1.1.1.1', $re), 'foo2', 'overlapping ranges');

# Test false value
$re = create_iprange_regexp({'127.0.0.1/32' => 0});
is(match_ip('127.0.0.1', $re), '0', 'false value');

# Test invalid args to match_ip
is(match_ip(undef, $re), undef, 'match_ip - undef args');
is(match_ip('127.0.0.1', undef), undef, 'match_ip - undef args');
is(match_ip(undef, undef), undef, 'match_ip - undef args');

# Catch bad trees (should never happen in real life)
{
   local $SIG{__DIE__} = 'DEFAULT';
   eval 'Net::IP::Match::Regexp::_tree2re({})';
   ok($EVAL_ERROR, 'bad tree');
}
{
   local $SIG{__DIE__} = 'DEFAULT';
   eval 'Net::IP::Match::Regexp::_tree2re_depthfirst({})';
   ok($EVAL_ERROR, 'bad tree');
}

# coverage of depthfirst tree builder
$re = create_iprange_regexp_depthfirst({
   '127.0.0.1' => 'localhost1',
   '127.0.0.2' => 'localhost2',
   '127.0.0.3' => 'localhost3',
   '127.0.0.4' => 'localhost4',
   '192.0.0.0/8' => 'wide',
   '192.168.0.0/16' => 'localnet',
   '192.12.0.0/16' => 'localnet2',
   '192.168.0.1/32' => 'router',
});
is(match_ip('192.200.0.1', $re), 'wide', 'depthfirst');
is(match_ip('192.168.0.4', $re), 'localnet', 'depthfirst');
is(match_ip('192.168.0.1', $re), 'router', 'depthfirst');


#### Regression tests ####

# Regression reported by Chris Snyder on Sep 5, 2007
# Treat missing mask as /32

{
   my $regex1 = create_iprange_regexp('10.0.0.0/8', '87.134.66.128',
                                      '87.134.87.0/24');
   my $regex2 = create_iprange_regexp('10.0.0.0/8', '87.134.66.128/32',
                                      '87.134.87.0/24');
   is($regex1, $regex2, 'null mask regression');
}
