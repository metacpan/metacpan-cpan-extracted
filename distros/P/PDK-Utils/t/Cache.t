#!/usr/bin/perl

use strict;
use warnings;

use 5.030;
use Test::More;
use Data::Printer;
use PDK::Utils::Cache;

my $cache;

subtest '创建 PDK::Utils::Cache 对象' => sub {
  plan tests => 2;
  $cache = eval { PDK::Utils::Cache->new };
  is($@, '', '创建对象时没有错误');
  isa_ok($cache, 'PDK::Utils::Cache');
};

subtest 'locate方法测试' => sub {
  plan tests => 1;
  $cache = PDK::Utils::Cache->new(cache => {lala => {lele => {lili => {lolo => 'lulu'}}}});
  is($cache->locate(qw/lala lele lili/)->{lolo}, 'lulu', 'locate方法正确返回值');
};

subtest 'get方法测试' => sub {
  plan tests => 1;
  $cache = PDK::Utils::Cache->new(cache => {lala => {lele => {lili => {lolo => 'lulu'}}}});
  is($cache->get(qw/lala lele lili/)->{lolo}, 'lulu', 'get方法正确返回值');
};

subtest 'clear方法测试' => sub {
  plan tests => 2;
  $cache = PDK::Utils::Cache->new(cache => {lala => {lele => {lili => {lolo => 'lulu'}}}});
  $cache->clear(qw/lala lele lili lolo/);
  my $ref = $cache->get(qw/lala lele lili/);
  ok(defined $ref,         'clear后仍能获取到父级引用');
  ok(!exists $ref->{lolo}, 'clear后指定的键已被删除');
};

subtest 'set方法测试' => sub {
  plan tests => 1;
  $cache = PDK::Utils::Cache->new(cache => {lala => {lele => {lili => {lolo => 'lulu'}}}});
  $cache->set(qw/lala lele lili 2/);
  is($cache->get(qw/lala lele lili/), '2', 'set方法正确设置新值');
};

done_testing();
