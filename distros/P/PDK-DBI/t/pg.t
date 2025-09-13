#!/usr/bin/env perl
use v5.30;
use strict;
use warnings;
use Test::More;
use Test::Exception;

# 测试模块加载
BEGIN {
    use_ok('PDK::DBI::Pg');
    say "测试模块加载: PDK::DBI::Pg 成功加载";
}

# 测试对象实例化
subtest '对象实例化测试' => sub {
    say "开始对象实例化测试";
    
    # 测试使用完整参数创建对象
    my $pg = PDK::DBI::Pg->new(
        dsn      => 'dbi:Pg:dbname=testdb',
        user     => 'testuser',
        password => 'testpass'
    );
    
    isa_ok($pg, 'PDK::DBI::Pg', '对象类型正确');
    is($pg->dsn, 'dbi:Pg:dbname=testdb', 'DSN 设置正确');
    is($pg->user, 'testuser', '用户名设置正确');
    say "使用完整参数创建对象测试通过";
    
    # 测试使用主机和数据库名创建对象（自动构建DSN）
    my $pg2 = PDK::DBI::Pg->new(
        host     => 'localhost',
        dbname   => 'testdb',
        user     => 'testuser',
        password => 'testpass'
    );
    
    is($pg2->dsn, 'dbi:Pg:dbname=testdb;host=localhost;port=5432', 
       '从主机和数据库名自动构建 DSN 正确');
    say "自动构建 DSN 测试通过";
    
    say "对象实例化测试完成";
};

# 测试克隆方法
subtest '克隆方法测试' => sub {
    say "开始克隆方法测试";
    
    my $pg = PDK::DBI::Pg->new(
        dsn      => 'dbi:Pg:dbname=testdb',
        user     => 'testuser',
        password => 'testpass'
    );
    
    my $clone = $pg->clone;
    isa_ok($clone, 'PDK::DBI::Pg', '克隆对象类型正确');
    is($clone->dsn, $pg->dsn, 'DSN 克隆正确');
    is($clone->user, $pg->user, '用户名克隆正确');
    
    say "克隆方法测试完成";
};

# 测试方法存在性
subtest '方法存在性测试' => sub {
    say "开始方法存在性测试";
    
    my $pg = PDK::DBI::Pg->new(
        dsn      => 'dbi:Pg:dbname=testdb',
        user     => 'testuser',
        password => 'testpass'
    );
    
    # 测试核心方法是否存在
    can_ok($pg, 'clone');
    can_ok($pg, 'batchExecute');
    can_ok($pg, 'disconnect');
    can_ok($pg, 'reconnect');
    
    # 测试委托的 DBIx::Custom 方法是否存在
    can_ok($pg, 'execute');
    can_ok($pg, 'select');
    can_ok($pg, 'update');
    can_ok($pg, 'insert');
    can_ok($pg, 'delete');
    
    say "方法存在性测试完成";
};

# 测试选项设置
subtest '连接选项测试' => sub {
    say "开始连接选项测试";
    
    my $custom_option = {AutoCommit => 1, RaiseError => 0};
    
    my $pg = PDK::DBI::Pg->new(
        dsn      => 'dbi:Pg:dbname=testdb',
        user     => 'testuser',
        password => 'testpass',
        option   => $custom_option
    );
    
    is($pg->option->{AutoCommit}, 1, '自定义 AutoCommit 选项设置正确');
    is($pg->option->{RaiseError}, 0, '自定义 RaiseError 选项设置正确');
    
    say "连接选项测试完成";
};

done_testing;
