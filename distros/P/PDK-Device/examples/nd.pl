#!/usr/bin/perl

use 5.030;              # 使用 Perl 版本 5.30
use strict;             # 启用严格模式以捕获潜在错误
use warnings;           # 启用警告以提高代码的健壮性

use Test::More;         # 导入 Test::More 模块以进行单元测试
use PDK::DBI::Pg;       # 导入 PDK::DBI::Pg 模块以进行设备操作
use PDK::Device::ConfigBackup;
use PDK::Device::Concern::Netdisco;

# 测试数据库连接参数
my $db_params = {
  host     => '192.168.99.99',
  port     => 5432,
  dbname   => 'netdisco',
  user     => 'netdisco',
  password => 'Cisc0123'
};

my $dbi = PDK::DBI::Pg->new($db_params);

my $sql = <<SQL;
select name, ip, os
from device
where os ~* 'cisco|ios'
  limit 1
SQL

my $devices = $dbi->execute($sql)->all;

my $nd = PDK::Device::Concern::Netdisco->new(dbi => $dbi);

$nd->exploreTopologyJob($devices);
#$cb->execCommandsJob($devices, ['conf t', 'no ip do loo', 'end', 'wri']);
#$cb->ftpConfigJob($devices);

use DDP;
p $cb;
