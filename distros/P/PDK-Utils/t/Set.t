#!/usr/bin/env perl
use strict;
use warnings;

use 5.030;
use Test::More;

use PDK::Utils::Set;

subtest '创建 PDK::Utils::Set 对象' => sub {
  plan tests => 6;

  my $set = eval { PDK::Utils::Set->new };
  isa_ok($set, 'PDK::Utils::Set', '创建空对象');

  $set = eval { PDK::Utils::Set->new(mins => [1, 7], maxs => [4, 10]) };
  isa_ok($set, 'PDK::Utils::Set', '使用 mins 和 maxs 数组创建对象');

  $set = eval { PDK::Utils::Set->new(4, 1) };
  isa_ok($set, 'PDK::Utils::Set', '使用两个数字创建对象');
  is_deeply([$set->mins->[0], $set->maxs->[0]], [1, 4], '验证 mins 和 maxs 值');

  my $set2 = PDK::Utils::Set->new(mins => [1, 7], maxs => [4, 10]);
  $set = eval { PDK::Utils::Set->new($set2) };
  isa_ok($set, 'PDK::Utils::Set', '使用已有对象创建新对象');
  ok($set->isEqual($set2), '新对象与原对象相等');
};

subtest '基本属性和方法' => sub {
  plan tests => 3;

  my $set = PDK::Utils::Set->new(mins => [1, 7], maxs => [4, 10]);
  is($set->length, 2,  'length 方法');
  is($set->min,    1,  'min 方法');
  is($set->max,    10, 'max 方法');
};

subtest '合并方法' => sub {
  plan tests => 3;

  my $set  = PDK::Utils::Set->new(7, 10);
  my $aSet = PDK::Utils::Set->new(mins => [1, 7], maxs => [4, 10]);

  $set->mergeToSet($aSet);
  ok($set->isEqual($aSet), 'mergeToSet(PDK::Utils::Set)');

  $set = PDK::Utils::Set->new(7, 10);
  $set->mergeToSet(2, 4);
  ok($set->isEqual(PDK::Utils::Set->new(mins => [2, 7], maxs => [4, 10])), 'mergeToSet(min, max)');

  $set = PDK::Utils::Set->new(7, 10);
  $set->_mergeToSet(2, 4);
  ok($set->isEqual(PDK::Utils::Set->new(mins => [2, 7], maxs => [4, 10])), '_mergeToSet(min, max)');
};

subtest '添加方法' => sub {
  plan tests => 1;

  my $set = PDK::Utils::Set->new(7, 10);
  $set->addToSet(2, 4);
  ok($set->isEqual(PDK::Utils::Set->new(mins => [2, 7], maxs => [4, 10])), 'addToSet(min, max)');
};

subtest '比较方法' => sub {
  plan tests => 8;

  my $set = PDK::Utils::Set->new(mins => [1, 7], maxs => [4, 10]);

  ok($set->isEqual(PDK::Utils::Set->new(mins  => [1, 7], maxs => [4, 10])), 'isEqual - 相等');
  ok(!$set->isEqual(PDK::Utils::Set->new(mins => [1, 8], maxs => [4, 9])),  'isEqual - 不相等');

  ok($set->isContain(PDK::Utils::Set->new(mins  => [1, 8], maxs => [4, 9])),  'isContain - 包含');
  ok($set->isContain(PDK::Utils::Set->new(mins  => [1, 7], maxs => [4, 10])), 'isContain - 相等');
  ok(!$set->isContain(PDK::Utils::Set->new(mins => [1, 8], maxs => [4, 11])), 'isContain - 不包含');

  ok($set->_isContain(PDK::Utils::Set->new(mins  => [1, 8], maxs => [4, 9])),  '_isContain - 包含');
  ok($set->_isContain(PDK::Utils::Set->new(mins  => [1, 7], maxs => [4, 10])), '_isContain - 相等');
  ok(!$set->_isContain(PDK::Utils::Set->new(mins => [1, 8], maxs => [4, 11])), '_isContain - 不包含');
};

subtest '包含但不相等方法' => sub {
  plan tests => 3;

  my $set = PDK::Utils::Set->new(mins => [1, 7], maxs => [4, 10]);

  ok($set->isContainButNotEqual(PDK::Utils::Set->new(mins => [1, 8], maxs => [4, 9])), 'isContainButNotEqual - 包含但不相等');
  ok($set->isContain(PDK::Utils::Set->new(mins => [1, 7], maxs => [4, 10])),           'isContainButNotEqual - 相等');
  ok(!$set->isContainButNotEqual(PDK::Utils::Set->new(mins => [1, 7], maxs => [4, 10])),
    'isContainButNotEqual - 相等但返回false');
};

subtest '属于方法' => sub {
  plan tests => 6;

  my $set = PDK::Utils::Set->new(mins => [1, 8], maxs => [4, 9]);

  ok($set->isBelong(PDK::Utils::Set->new(mins  => [1, 7], maxs => [4, 10])), 'isBelong - 属于');
  ok($set->isBelong(PDK::Utils::Set->new(mins  => [1, 8], maxs => [4, 9])),  'isBelong - 相等');
  ok(!$set->isBelong(PDK::Utils::Set->new(mins => [1, 9], maxs => [4, 11])), 'isBelong - 不属于');

  ok($set->_isBelong(PDK::Utils::Set->new(mins  => [1, 7], maxs => [4, 10])), '_isBelong - 属于');
  ok($set->_isBelong(PDK::Utils::Set->new(mins  => [1, 8], maxs => [4, 9])),  '_isBelong - 相等');
  ok(!$set->_isBelong(PDK::Utils::Set->new(mins => [1, 9], maxs => [4, 11])), '_isBelong - 不属于');
};

subtest '属于但不相等方法' => sub {
  plan tests => 3;

  my $set = PDK::Utils::Set->new(mins => [1, 8], maxs => [4, 9]);

  ok($set->isBelongButNotEqual(PDK::Utils::Set->new(mins => [1, 7], maxs => [4, 10])), 'isBelongButNotEqual - 属于但不相等');
  ok($set->isBelong(PDK::Utils::Set->new(mins => [1, 8], maxs => [4, 9])),             'isBelongButNotEqual - 相等');
  ok(!$set->isBelongButNotEqual(PDK::Utils::Set->new(mins => [1, 8], maxs => [4, 9])),
    'isBelongButNotEqual - 相等但返回false');
};

subtest '比较方法' => sub {
  plan tests => 4;

  my $set = PDK::Utils::Set->new(mins => [1, 7], maxs => [4, 10]);

  is($set->compare(PDK::Utils::Set->new(mins => [1, 7], maxs => [4, 10])), 'equal',              'compare - 相等');
  is($set->compare(PDK::Utils::Set->new(mins => [1, 8], maxs => [4, 9])),  'containButNotEqual', 'compare - 包含但不相等');
  is($set->compare(PDK::Utils::Set->new(mins => [1, 7], maxs => [4, 11])), 'belongButNotEqual',  'compare - 属于但不相等');
  is($set->compare(PDK::Utils::Set->new(mins => [1, 8], maxs => [5, 9])),  'other',              'compare - 其他情况');
};

subtest '交集方法' => sub {
  plan tests => 1;

  my $set    = PDK::Utils::Set->new(mins => [1, 4, 12], maxs => [2, 10, 15]);
  my $result = $set->interSet(PDK::Utils::Set->new(mins => [3, 9], maxs => [7, 16]));

  is($result->compare(PDK::Utils::Set->new(mins => [4, 9, 12], maxs => [7, 10, 15])), 'equal', 'interSet - 正确计算交集');
};

done_testing();
