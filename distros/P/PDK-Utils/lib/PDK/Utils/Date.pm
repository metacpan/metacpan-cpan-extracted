package PDK::Utils::Date;

use utf8;
use v5.30;
use Moose;
use namespace::autoclean;
use POSIX qw/strftime/;
use Carp;

# 获取当前年月（格式：YYYY-MM）
sub getCurrentYearMonth {
    return strftime("%Y-%m", localtime);
}

# 获取当前年月日（格式：YYYY-MM-DD）
sub getCurrentYearMonthDay {
    return strftime("%Y-%m-%d", localtime);
}

# 获取格式化后的日期时间字符串
sub getFormatedDate {
    my ($self, @param) = @_;
    my ($format, $time);

    # 处理参数顺序：支持 (格式, 时间) 或 (时间, 格式)
    if (defined $param[0] and $param[0] =~ /^\d+$/) {
        ($time, $format) = @param;
    }
    else {
        ($format, $time) = @param;
    }

    # 设置默认值
    $format //= 'yyyy-mm-dd hh:mi:ss';
    $time //= time();

    # 获取本地时间分量
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime($time);

    # 时间分量映射表
    my %timeMap = (
        yyyy => $year + 1900, # 四位年份
        mm   => $mon + 1,     # 月份（1-12）
        dd   => $mday,        # 日期
        hh   => $hour,        # 小时
        mi   => $min,         # 分钟
        ss   => $sec,         # 秒
    );

    # 格式符映射表
    my %formatMap = (
        yyyy => '%04d', # 四位年份格式
        mm   => '%02d', # 两位月份格式
        dd   => '%02d', # 两位日期格式
        hh   => '%02d', # 两位小时格式
        mi   => '%02d', # 两位分钟格式
        ss   => '%02d', # 两位秒格式
    );

    # 构建匹配模式
    my $regex = '(' . join('|', keys %timeMap) . ')';

    # 提取时间分量值
    my @times = map {$timeMap{$_}} ($format =~ /$regex/g);

    # 验证格式字符串有效性
    if (scalar(@times) == 0) {
        confess("错误：格式字符串 [$format] 不包含有效格式符\n");
    }

    # 替换格式符为 sprintf 格式
    $format =~ s/$regex/$formatMap{$1}/g;

    # 生成格式化后的时间字符串
    my $formatedTime = sprintf("$format", @times);
    return $formatedTime;
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8
=head1 名称

PDK::Utils::Date - 日期时间工具类

=head1 简介

该模块提供常用的日期与时间处理方法，包括获取当前日期、年月、以及自定义格式化输出。

=head1 方法说明

=head2 getCurrentYearMonth

    my $ym = PDK::Utils::Date::getCurrentYearMonth();

获取当前年月，返回字符串格式：

    YYYY-MM

示例：

    2025-09

=head2 getCurrentYearMonthDay

    my $ymd = PDK::Utils::Date::getCurrentYearMonthDay();

获取当前年月日，返回字符串格式：

    YYYY-MM-DD

示例：

    2025-09-09

=head2 getFormatedDate([$format, $time])

    my $date = $dateUtil->getFormatedDate("yyyy-mm-dd hh:mi:ss", time());

根据指定格式与时间戳返回格式化的日期字符串。

支持两种调用方式：

=over 4

=item * (格式, 时间)

=item * (时间, 格式) —— 当第一个参数为纯数字时

=back

=over 8

=item * $format - 格式字符串，默认 C<yyyy-mm-dd hh:mi:ss>

=item * $time - Unix 时间戳，默认当前时间 (time)

=back

可用格式符：

=over 8

=item * yyyy - 四位年份 (如 2025)

=item * mm   - 两位月份 (01–12)

=item * dd   - 两位日期 (01–31)

=item * hh   - 两位小时 (00–23)

=item * mi   - 两位分钟 (00–59)

=item * ss   - 两位秒数 (00–59)

=back

示例：

    # 当前时间，默认格式
    $dateUtil->getFormatedDate();
    # 输出: 2025-09-09 21:35:42

    # 指定格式
    $dateUtil->getFormatedDate("yyyy年mm月dd日 hh:mi");
    # 输出: 2025年09月09日 21:35

    # 指定时间戳
    $dateUtil->getFormatedDate(1609459200, "yyyy/mm/dd");
    # 输出: 2021/01/01

=head1 错误处理

=over 4

=item *

当格式字符串中未包含任何有效格式符时，会抛出异常。

=back

=head1 使用示例

    use PDK::Utils::Date;

    my $dateUtil = PDK::Utils::Date->new;

    say $dateUtil->getCurrentYearMonth();     # 2025-09
    say $dateUtil->getCurrentYearMonthDay();  # 2025-09-09
    say $dateUtil->getFormatedDate("yyyy-mm-dd hh:mi:ss");

=head1 作者

WENWU YAN E<lt>968828@gmail.comE<gt>

=head1 版权与许可

本模块遵循与 Perl 相同的许可协议。

=cut

