#!/usr/bin/env perl

use strict;
use warnings;

use v5.30;
use Test::More;
use Data::Dumper;

use PDK::Utils::Ip;

my $ip;

subtest '创建 PDK::Utils::Ip 对象' => sub {
  plan tests => 1;
  $ip = eval { PDK::Utils::Ip->new };
  isa_ok($ip, 'PDK::Utils::Ip', '成功创建 PDK::Utils::Ip 对象');
};

subtest 'IP 地址和整数转换' => sub {
  plan tests => 2;
  $ip = PDK::Utils::Ip->new;
  is($ip->changeIpToInt('10.11.77.41'), 168512809,     'IP 地址转整数');
  is($ip->changeIntToIp(168512809),     '10.11.77.41', '整数转 IP 地址');
};

subtest '子网掩码格式转换' => sub {
  plan tests => 4;
  $ip = PDK::Utils::Ip->new;
  is($ip->changeMaskToNumForm('255.255.252.0'), 22,              'IP 格式掩码转数字格式');
  is($ip->changeMaskToNumForm(22),              22,              '数字格式掩码保持不变');
  is($ip->changeMaskToIpForm('255.255.252.0'),  '255.255.252.0', 'IP 格式掩码保持不变');
  is($ip->changeMaskToIpForm(22),               '255.255.252.0', '数字格式掩码转 IP 格式');
};

subtest 'IP 范围计算' => sub {
  plan tests => 4;
  $ip = PDK::Utils::Ip->new;
  my ($min1, $max1) = $ip->getRangeFromIpMask('10.11.77.41', 22);
  my $range1 = $ip->getRangeFromIpMask('10.11.77.41', '255.255.252.0');
  is($min1,        168512512, '正确计算最小 IP');
  is($max1,        168513535, '正确计算最大 IP');
  is($range1->min, $min1,     '使用对象方法获取最小 IP');
  is($range1->max, $max1,     '使用对象方法获取最大 IP');
};

subtest 'IP 范围计算（指定起始和结束 IP）' => sub {
  plan tests => 4;
  $ip = PDK::Utils::Ip->new;
  my ($min2, $max2) = $ip->getRangeFromIpRange('10.11.77.40', '10.11.77.41');
  my $range2 = $ip->getRangeFromIpRange('10.11.77.41', '10.11.77.40');
  is($min2,        168512808, '正确计算最小 IP');
  is($max2,        168512809, '正确计算最大 IP');
  is($range2->min, $min2,     '使用对象方法获取最小 IP');
  is($range2->max, $max2,     '使用对象方法获取最大 IP');
};

subtest '获取网络 IP' => sub {
  plan tests => 1;
  $ip = PDK::Utils::Ip->new;
  is($ip->getNetIpFromIpMask("10.11.77.41", 27), "10.11.77.32", '正确获取网络 IP');
};

subtest '从 IP 范围获取 CIDR 表示' => sub {
  plan tests => 1;
  $ip = PDK::Utils::Ip->new;
  is($ip->getIpMaskFromRange(168558592, 168574975), "10.12.0.0/18", '正确获取 CIDR 表示');
};

subtest '通配符掩码转换为标准掩码' => sub {
  plan tests => 1;
  $ip = PDK::Utils::Ip->new;
  is($ip->changeWildcardToMaskForm('0.0.255.255'), "255.255.0.0", '正确转换通配符掩码');
};

done_testing();
