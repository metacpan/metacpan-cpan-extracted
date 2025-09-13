#!/usr/bin/env perl

use v5.30;
use strict;
use warnings;
use Test::More;
use Test::Exception;

# 测试模块加载
BEGIN {
    use_ok('PDK::DBI::Mysql');
    say "测试模块加载: PDK::DBI::Mysql 成功加载";
}

# 测试对象实例化
subtest '对象实例化测试' => sub {
    say "开始对象实例化测试";

    # 测试使用完整参数创建对象
    my $mysql = PDK::DBI::Mysql->new(
        dsn      => 'DBI:mysql:database=testdb',
        user     => 'testuser',
        password => 'testpass'
    );

    isa_ok($mysql, 'PDK::DBI::Mysql', '对象类型正确');
    is($mysql->dsn, 'DBI:mysql:database=testdb', 'DSN 设置正确');
    is($mysql->user, 'testuser', '用户名设置正确');
    say "使用完整参数创建对象测试通过";

    # 测试使用主机和数据库名创建对象（自动构建DSN）
    my $mysql2 = PDK::DBI::Mysql->new(
        host     => 'localhost',
        dbname   => 'testdb',
        user     => 'testuser',
        password => 'testpass'
    );

    is($mysql2->dsn, 'DBI:mysql:database=testdb;host=localhost;port=3306',
       '从主机和数据库名自动构建 DSN 正确');
    say "自动构建 DSN 测试通过";

    say "对象实例化测试完成";
};

# 测试克隆方法
subtest '克隆方法测试' => sub {
    say "开始克隆方法测试";

    my $mysql = PDK::DBI::Mysql->new(
        dsn      => 'DBI:mysql:database=testdb',
        user     => 'testuser',
        password => 'testpass'
    );

    my $clone = $mysql->clone;
    isa_ok($clone, 'PDK::DBI::Mysql', '克隆对象类型正确');
    is($clone->dsn, $mysql->dsn, 'DSN 克隆正确');
    is($clone->user, $mysql->user, '用户名克隆正确');

    say "克隆方法测试完成";
};

# 测试方法存在性
subtest '方法存在性测试' => sub {
    say "开始方法存在性测试";

    my $mysql = PDK::DBI::Mysql->new(
        dsn      => 'DBI:mysql:database=testdb',
        user     => 'testuser',
        password => 'testpass'
    );

    # 测试核心方法是否存在
    can_ok($mysql, 'clone');
    can_ok($mysql, 'batchExecute');
    can_ok($mysql, 'disconnect');
    can_ok($mysql, 'reconnect');

    # 测试委托的 DBIx::Custom 方法是否存在
    can_ok($mysql, 'execute');
    can_ok($mysql, 'select');
    can_ok($mysql, 'update');
    can_ok($mysql, 'insert');
    can_ok($mysql, 'delete');

    say "方法存在性测试完成";
};

# 测试选项设置
subtest '连接选项测试' => sub {
    say "开始连接选项测试";

    my $custom_option = {AutoCommit => 1, RaiseError => 0};

    my $mysql = PDK::DBI::Mysql->new(
        dsn      => 'DBI:mysql:database=testdb',
        user     => 'testuser',
        password => 'testpass',
        option   => $custom_option
    );

    is($mysql->option->{AutoCommit}, 1, '自定义 AutoCommit 选项设置正确');
    is($mysql->option->{RaiseError}, 0, '自定义 RaiseError 选项设置正确');

    say "连接选项测试完成";
};

# 测试 MySQL 特定功能
subtest 'MySQL 特定功能测试' => sub {
    say "开始 MySQL 特定功能测试";
    
    my $mysql = PDK::DBI::Mysql->new(
        dsn      => 'DBI:mysql:database=testdb',
        user     => 'testuser',
        password => 'testpass'
    );
    
    # 测试端口默认值
    my $mysql_with_port = PDK::DBI::Mysql->new(
        host     => 'localhost',
        dbname   => 'testdb',
        port     => '3307', # 非默认端口
        user     => 'testuser',
        password => 'testpass'
    );
    
    is($mysql_with_port->dsn, 'DBI:mysql:database=testdb;host=localhost;port=3307',
       '自定义端口设置正确');
    
    say "MySQL 特定功能测试完成";
};

done_testing;
