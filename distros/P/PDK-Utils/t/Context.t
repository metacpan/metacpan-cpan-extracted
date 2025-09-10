#!/usr/bin/env perl

use v5.30;
use strict;
use warnings;
use Test::More tests => 7;

use Digest::MD5;
use PDK::Utils::Context;

my $ctx;

# 对象创建测试
subtest '对象创建测试' => sub {
    ok(
        eval {
            $ctx = PDK::Utils::Context->new(config => [ "line 1", "line 2", "line 3", "line 4" ]);
            1;
        } && $ctx->isa('PDK::Utils::Context'),
        '成功创建 PDK::Utils::Context 对象'
    );
    done_testing();
};

# content 与 confSign 测试
subtest '内容与配置签名测试' => sub {
    my @lines = ("line 1", "line 2", "line 3", "line 4");
    is($ctx->content, join("\n", @lines), '内容拼接正确');
    is($ctx->confSign, Digest::MD5::md5_hex(join("\n", @lines)), '配置签名正确');
    done_testing();
};

# timestamp 与行解析标志测试
subtest '时间戳与行解析标志测试' => sub {
    ok($ctx->timestamp =~ /\d{4}-\d{2}-\d{2}/, '时间戳格式正确');
    is_deeply($ctx->lineParsedFlags, [0,0,0,0], '行解析标志初始化正确');
    done_testing();
};

# 游标操作测试
subtest '游标操作测试' => sub {
    is($ctx->nextLine, 'line 1', 'nextLine 返回第一行');
    is($ctx->nextLine, 'line 2', 'nextLine 返回第二行');
    ok($ctx->prevLine, 'prevLine 成功回退');
    is($ctx->nextLine, 'line 2', '回退后 nextLine 正确');
    done_testing();
};

# 解析标志操作测试
subtest '解析标志操作测试' => sub {
    $ctx->setParseFlag(1);
    is($ctx->getParseFlag, 1, '解析标志设置正确');
    $ctx->nextLine;
    ok($ctx->backtrack, 'backtrack 成功');
    done_testing();
};

# ignore 与 nextUnParsedLine 测试
subtest '忽略与下一个未解析行测试' => sub {
    my $ignored = $ctx->ignore;
    ok(defined $ignored, 'ignore 返回下一行');

    $ctx->goToHead;
    my $line = $ctx->nextUnParsedLine;
    is($line, 'line 1', 'nextUnParsedLine 正确返回第一行');
    done_testing();
};

# getUnParsedLines 测试
subtest '未解析行获取测试' => sub {
    $ctx->setParseFlag(1); # 标记第一行已解析
    my $unparsed = $ctx->getUnParsedLines;
    like($unparsed, qr/line 3.*line 4/s, 'getUnParsedLines 正确返回未解析行');
    done_testing();
};

done_testing();

