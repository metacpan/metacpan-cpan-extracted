#!/usr/bin/env perl

use v5.30;
use strict;
use warnings;
use Test::More tests => 10; # 使用Test::More替代Test::Simple

# 添加模块搜索路径
use PDK::Utils::Ip;

my $ip;

# 测试对象创建
subtest '对象创建测试' => sub {
    ok(
        eval {
            $ip = PDK::Utils::Ip->new;
            1;
        } && $ip->isa('PDK::Utils::Ip'),
        '创建 PDK::Utils::Ip 对象成功'
    );
    done_testing();
};

# 测试IP地址转整数
subtest 'IP地址转整数测试' => sub {
    $ip = PDK::Utils::Ip->new;
    is(
        $ip->changeIpToInt('10.11.77.41'),
        168512809,
        'IP地址 10.11.77.41 转换为整数 168512809'
    );
    done_testing();
};

# 测试整数转IP地址
subtest '整数转IP地址测试' => sub {
    $ip = PDK::Utils::Ip->new;
    is(
        $ip->changeIntToIp(168512809),
        '10.11.77.41',
        '整数 168512809 转换为IP地址 10.11.77.41'
    );
    done_testing();
};

# 测试掩码转换
subtest '掩码转换测试' => sub {
    $ip = PDK::Utils::Ip->new;
    is(
        $ip->changeMaskToNumForm('255.255.252.0'),
        22,
        '点分十进制掩码 255.255.252.0 转换为数字形式 22'
    );
    is(
        $ip->changeMaskToNumForm(22),
        22,
        '数字形式掩码 22 保持不变'
    );
    done_testing();
};

# 测试掩码格式转换
subtest '掩码格式转换测试' => sub {
    $ip = PDK::Utils::Ip->new;
    is(
        $ip->changeMaskToIpForm('255.255.252.0'),
        '255.255.252.0',
        '点分十进制掩码 255.255.252.0 保持不变'
    );
    is(
        $ip->changeMaskToIpForm(22),
        '255.255.252.0',
        '数字形式掩码 22 转换为点分十进制 255.255.252.0'
    );
    done_testing();
};

# 测试从IP和掩码获取范围
subtest '从IP和掩码获取范围测试' => sub {
    $ip = PDK::Utils::Ip->new;
    my ($min, $max) = $ip->getRangeFromIpMask('10.11.77.41', 22);
    my $range = $ip->getRangeFromIpMask('10.11.77.41', '255.255.252.0');

    is($min, 168512512, 'IP 10.11.77.41/22 的最小值为 168512512');
    is($max, 168513535, 'IP 10.11.77.41/22 的最大值为 168513535');
    is($range->min, $min, 'Set对象最小值匹配');
    is($range->max, $max, 'Set对象最大值匹配');
    done_testing();
};

# 测试从IP范围获取范围
subtest '从IP范围获取范围测试' => sub {
    $ip = PDK::Utils::Ip->new;
    my ($min, $max) = $ip->getRangeFromIpRange('10.11.77.40', '10.11.77.41');
    my $range = $ip->getRangeFromIpRange('10.11.77.41', '10.11.77.40');

    is($min, 168512808, 'IP范围 10.11.77.40-10.11.77.41 的最小值为 168512808');
    is($max, 168512809, 'IP范围 10.11.77.40-10.11.77.41 的最大值为 168512809');
    is($range->min, $min, 'Set对象最小值匹配');
    is($range->max, $max, 'Set对象最大值匹配');
    done_testing();
};

# 测试从IP和掩码获取网络地址
subtest '从IP和掩码获取网络地址测试' => sub {
    $ip = PDK::Utils::Ip->new;
    my $netIp = $ip->getNetIpFromIpMask("10.11.77.41", 27);

    is(
        $netIp,
        "10.11.77.32",
        'IP 10.11.77.41/27 的网络地址为 10.11.77.32'
    );
    done_testing();
};

# 测试从范围获取IP和掩码
subtest '从范围获取IP和掩码测试' => sub {
    $ip = PDK::Utils::Ip->new;
    my $netIp = $ip->getIpMaskFromRange(168558592, 168574975);

    is(
        $netIp,
        "10.12.0.0/18",
        '范围 168558592-168574975 转换为 CIDR 10.12.0.0/18'
    );
    done_testing();
};

# 测试反掩码转换
subtest '反掩码转换测试' => sub {
    $ip = PDK::Utils::Ip->new;
    my $mask = $ip->changeWildcardToMaskForm('0.0.255.255');

    is(
        $mask,
        "255.255.0.0",
        '反掩码 0.0.255.255 转换为掩码 255.255.0.0'
    );
    done_testing();
};

done_testing();
