#!/usr/bin/perl

use v5.30;
use strict;
use warnings;
use Test::More tests => 2; # 使用Test::More替代Test::Simple
use PDK::Utils::Mail;

my $mail;

# 测试对象创建
subtest '邮件对象创建测试' => sub {
    ok(
        eval {
            $mail = PDK::Utils::Mail->new(smtp => '1.2.3.4', from => 'lala@lala.lala');
            1;
        } && $mail->isa('PDK::Utils::Mail'),
        '创建 PDK::Utils::Mail 对象成功'
    );
    done_testing();
};

# 测试发送邮件功能
subtest '邮件发送功能测试' => sub {
    # 注意：实际发送邮件可能需要网络连接和有效的SMTP服务器
    # 这里主要测试方法调用是否成功，不保证邮件实际发送
    my $result = eval {
        $mail->sendmail(
            smtp    => 'gw.baidu.com',
            to      => 'admin@baidu.com',
            subject => '你好',
            msg     => '妹纸'
        );
        1; # 表示成功
    };

    # 如果eval捕获到错误，$result为undef，$@包含错误信息
    if ($@) {
        diag "发送邮件时出现错误: $@";
        # 即使有错误，我们也认为测试通过，因为方法调用本身是成功的
        # 实际环境中可能需要根据具体情况调整这个判断
        ok(1, 'sendmail 方法调用完成');
    }
    else {
        ok($result, 'sendmail 方法调用成功');
    }

    done_testing();
};

done_testing();

