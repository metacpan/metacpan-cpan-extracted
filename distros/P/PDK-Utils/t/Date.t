#!/usr/bin/env perl

use v5.30;
use strict;
use warnings;
use Test::More tests => 7;

use PDK::Utils::Date;

my $date;

# 对象创建
subtest '对象创建测试' => sub {
    ok(
        eval {
            $date = PDK::Utils::Date->new;
            1;
        } && $date->isa('PDK::Utils::Date'),
        '成功创建 PDK::Utils::Date 对象'
    );
    done_testing();
};

# 测试 getCurrentYearMonth
subtest '获取当前年月测试' => sub {
    my $ym = $date->getCurrentYearMonth;
    like( $ym, qr/^\d{4}-\d{2}$/, "返回格式 YYYY-MM 正确: $ym" );
    done_testing();
};

# 测试 getCurrentYearMonthDay
subtest '获取当前年月日测试' => sub {
    my $ymd = $date->getCurrentYearMonthDay;
    like( $ymd, qr/^\d{4}-\d{2}-\d{2}$/, "返回格式 YYYY-MM-DD 正确: $ymd" );
    done_testing();
};

# 测试 getFormatedDate 默认格式
subtest '格式化日期默认格式测试' => sub {
    my $now = time;
    my $formatted = $date->getFormatedDate(undef, $now);
    like( $formatted, qr/^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$/, "默认格式正确: $formatted" );
    done_testing();
};

# 测试 getFormatedDate 指定格式
subtest '格式化日期指定格式测试' => sub {
    my $ts = 1704067200; # 2024-01-01 00:00:00 UTC+8 (根据时区不同会略有差异)
    my $formatted = $date->getFormatedDate('yyyy-mm-dd', $ts);
    is( $formatted, '2024-01-01', '格式化为 yyyy-mm-dd 成功' );

    my $time_only = $date->getFormatedDate($ts, 'hh:mi:ss');
    like( $time_only, qr/^\d{2}:\d{2}:\d{2}$/, '格式化为 hh:mi:ss 成功' );
    done_testing();
};

# 测试参数顺序 (格式, 时间) 与 (时间, 格式)
subtest '参数顺序兼容测试' => sub {
    my $ts = 1704067200;
    my $fmt1 = $date->getFormatedDate('yyyy-mm-dd', $ts);
    my $fmt2 = $date->getFormatedDate($ts, 'yyyy-mm-dd');
    is( $fmt1, $fmt2, '两种参数顺序结果一致' );
    done_testing();
};

# 错误格式字符串
subtest '错误格式字符串测试' => sub {
    my $error;
    eval {
        $date->getFormatedDate('invalid_format');
    };
    $error = $@;
    like( $error, qr/.*/, '错误格式触发 confess 异常' );
    done_testing();
};

done_testing();

