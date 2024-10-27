#!/usr/bin/perl

use strict;
use warnings;

use v5.30;
use Test::More;
use Data::Dumper;

use PDK::Utils::Date;

my $date;

subtest '创建 PDK::Utils::Date 对象' => sub {
  plan tests => 2;

  $date = eval { PDK::Utils::Date->new };
  is($@, '', '创建对象时没有错误');
  isa_ok($date, 'PDK::Utils::Date', '对象类型检查');
};

subtest 'getFormatedDate 方法测试' => sub {
  plan tests => 2;

  $date = PDK::Utils::Date->new;
  my $time = 1387431015;

  is($date->getFormatedDate($time), '2013-12-19 13:30:15', '使用指定时间戳格式化日期');

  my $current_formatted_date = $date->getFormatedDate();
  note("当前格式化日期: " . Dumper($current_formatted_date));

  like($current_formatted_date, qr/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/, '不带参数时返回当前日期的格式正确');
};

done_testing();
