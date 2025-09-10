#!/usr/bin/env perl

use v5.30;
use strict;
use warnings;
use Test::More tests => 6;

use PDK::Utils::Cache;

my $cache;

# 对象创建
subtest '对象创建测试' => sub {
    ok(
        eval {
            $cache = PDK::Utils::Cache->new;
            1;
        } && $cache->isa('PDK::Utils::Cache'),
        '成功创建 PDK::Utils::Cache 对象'
    );
    isa_ok( $cache->cache, 'HASH', 'cache 属性是哈希引用' );
    done_testing();
};

# set/get 简单键值
subtest 'set/get 简单键值测试' => sub {
    $cache->set(foo => 'bar');
    is( $cache->get('foo'), 'bar', '获取 foo => bar 成功' );
    done_testing();
};

# set/get 多层嵌套键值
subtest 'set/get 多层嵌套键值测试' => sub {
    $cache->set(qw(level1 level2 level3), 'deep_value');
    is( $cache->get(qw(level1 level2 level3)), 'deep_value', '获取嵌套值成功' );
    isa_ok( $cache->get('level1'), 'HASH', 'level1 是哈希引用' );
    isa_ok( $cache->get(qw(level1 level2)), 'HASH', 'level2 是哈希引用' );
    done_testing();
};

# clear 指定路径
subtest 'clear 指定路径测试' => sub {
    $cache->set(temp => '123');
    is( $cache->get('temp'), '123', '设置临时键成功' );
    $cache->clear('temp');
    is( $cache->get('temp'), undef, 'clear 删除指定键成功' );
    done_testing();
};

# clear 所有缓存
subtest 'clear 所有缓存测试' => sub {
    $cache->set(key1 => 'val1');
    $cache->set(key2 => 'val2');
    ok( $cache->get('key1') && $cache->get('key2'), '缓存已存在' );
    $cache->clear;
    is_deeply( $cache->cache, {}, 'clear 清空所有缓存成功' );
    done_testing();
};

# locate 测试
subtest 'locate 测试' => sub {
    $cache->set(a => { b => { c => 100 } });
    is( $cache->locate('a','b','c'), 100, 'locate 找到正确的值' );
    is( $cache->locate('a','x'), undef, 'locate 不存在路径返回 undef' );
    done_testing();
};

done_testing();

