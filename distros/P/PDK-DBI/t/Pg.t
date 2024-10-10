#!/usr/bin/perl

use v5.30;
use strict;
use warnings;

use Test::More;
use Test::Exception;
use Data::Printer;
use PDK::DBI::Pg;

my $db_params = {host => '127.0.0.1', port => 5432, dbname => 'netdisco', user => 'netdisco', password => 'Cisc0123'};

subtest 'PDK::DBI::Pg 对象创建' => sub {
  my ($dbi, $dbi2, $dbi3);

  lives_ok(
    sub {
      $dbi = PDK::DBI::Pg->new(
        dsn      => "dbi:Pg:dbname=$db_params->{dbname};host=$db_params->{host};port=$db_params->{port}",
        user     => $db_params->{user},
        password => $db_params->{password}
      );
    },
    '使用显式 DSN 创建 PDK::DBI::Pg 对象'
  );

  lives_ok(sub { $dbi2 = PDK::DBI::Pg->new($db_params) }, '使用哈希引用创建 PDK::DBI::Pg 对象');

  lives_ok(sub { $dbi3 = PDK::DBI::Pg->new(%$db_params) }, '使用哈希创建 PDK::DBI::Pg 对象');

  for my $obj ($dbi, $dbi2, $dbi3) {
    isa_ok($obj, 'PDK::DBI::Pg', '创建的对象');
  }
};

subtest '数据库操作' => sub {
  my $dbi = PDK::DBI::Pg->new($db_params);

  my $result;
  lives_ok(sub { $result = $dbi->execute("SELECT * FROM device")->all }, '执行 SELECT 查询');

  ok(defined $result, '查询返回结果');
  diag p($result);

  my $cloned_dbi = $dbi->clone;
  isa_ok($cloned_dbi, 'PDK::DBI::Pg', '克隆的对象');

  my $cloned_result;
  lives_ok(sub { $cloned_result = $cloned_dbi->execute("SELECT * FROM device")->all }, '在克隆的对象上执行 SELECT 查询');

  ok(defined $cloned_result, '克隆对象的查询返回结果');
  diag p($cloned_result);

  is_deeply($result, $cloned_result, '原始对象和克隆对象的结果相同');
};

done_testing();
