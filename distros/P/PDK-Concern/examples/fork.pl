#!/usr/bin/env perl

use strict;
use warnings;
use v5.30;

use PDK::DBI::Pg;
use PDK::Device::Concern::Netdisco;
use Data::Dumper;
use Data::Printer;

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
SELECT name, ip, os
FROM device
SQL

my $devices = $dbi->execute($sql)->all;
my $nd = PDK::Device::Concern::Netdisco->new();
say Dumper $nd->exploreTopologyJob($devices);