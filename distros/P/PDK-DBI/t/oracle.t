#!/usr/bin/env perl

use v5.30;
use strict;
use warnings;
use Test::More;
use Test::Exception;

# 测试模块加载
BEGIN {
    use_ok('PDK::DBI::Oracle');
    say "测试模块加载: PDK::DBI::Oracle 成功加载";
}

# 测试对象实例化
subtest '对象实例化测试' => sub {
    say "开始对象实例化测试";

    # 测试使用完整参数创建对象
    my $oracle = PDK::DBI::Oracle->new(
        dsn      => 'dbi:Oracle:host=localhost;sid=orcl;port=1521',
        user     => 'testuser',
        password => 'testpass'
    );

    isa_ok($oracle, 'PDK::DBI::Oracle', '对象类型正确');
    is($oracle->dsn, 'dbi:Oracle:host=localhost;sid=orcl;port=1521', 'DSN 设置正确');
    is($oracle->user, 'testuser', '用户名设置正确');
    say "使用完整参数创建对象测试通过";

    # 测试使用主机、端口和SID创建对象（自动构建DSN）
    my $oracle2 = PDK::DBI::Oracle->new(
        host     => 'localhost',
        port     => '1521',
        sid      => 'orcl',
        user     => 'testuser',
        password => 'testpass'
    );

    is($oracle2->dsn, 'dbi:Oracle:host=localhost;sid=orcl;port=1521',
       '从主机、端口和SID自动构建 DSN 正确');
    say "自动构建 DSN 测试通过";

    say "对象实例化测试完成";
};

# 测试克隆方法
subtest '克隆方法测试' => sub {
    say "开始克隆方法测试";

    my $oracle = PDK::DBI::Oracle->new(
        dsn      => 'dbi:Oracle:host=localhost;sid=orcl;port=1521',
        user     => 'testuser',
        password => 'testpass'
    );

    my $clone = $oracle->clone;
    isa_ok($clone, 'PDK::DBI::Oracle', '克隆对象类型正确');
    is($clone->dsn, $oracle->dsn, 'DSN 克隆正确');
    is($clone->user, $oracle->user, '用户名克隆正确');

    say "克隆方法测试完成";
};

# 测试方法存在性
subtest '方法存在性测试' => sub {
    say "开始方法存在性测试";

    my $oracle = PDK::DBI::Oracle->new(
        dsn      => 'dbi:Oracle:host=localhost;sid=orcl;port=1521',
        user     => 'testuser',
        password => 'testpass'
    );

    # 测试核心方法是否存在
    can_ok($oracle, 'clone');
    can_ok($oracle, 'batchExecute');
    can_ok($oracle, 'disconnect');
    can_ok($oracle, 'reconnect');

    # 测试委托的 DBIx::Custom 方法是否存在
    can_ok($oracle, 'execute');
    can_ok($oracle, 'select');
    can_ok($oracle, 'update');
    can_ok($oracle, 'insert');
    can_ok($oracle, 'delete');

    say "方法存在性测试完成";
};

# 测试选项设置
subtest '连接选项测试' => sub {
    say "开始连接选项测试";

    my $custom_option = {AutoCommit => 1, RaiseError => 0};

    my $oracle = PDK::DBI::Oracle->new(
        dsn      => 'dbi:Oracle:host=localhost;sid=orcl;port=1521',
        user     => 'testuser',
        password => 'testpass',
        option   => $custom_option
    );

    is($oracle->option->{AutoCommit}, 1, '自定义 AutoCommit 选项设置正确');
    is($oracle->option->{RaiseError}, 0, '自定义 RaiseError 选项设置正确');

    say "连接选项测试完成";
};

# 测试 Oracle 特定功能
subtest 'Oracle 特定功能测试' => sub {
    say "开始 Oracle 特定功能测试";
    
    # 测试 Oracle 的 DSN 构建需要 host、port 和 sid 三个参数
    my $oracle = PDK::DBI::Oracle->new(
        host     => 'dbserver',
        port     => '1522',
        sid      => 'orclprod',
        user     => 'testuser',
        password => 'testpass'
    );
    
    is($oracle->dsn, 'dbi:Oracle:host=dbserver;sid=orclprod;port=1522',
       'Oracle DSN 构建正确');
    
    say "Oracle 特定功能测试完成";
};

done_testing;
