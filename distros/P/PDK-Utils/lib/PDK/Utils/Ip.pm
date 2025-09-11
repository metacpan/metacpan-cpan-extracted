package PDK::Utils::Ip;

use utf8;
use v5.30;
use Moose;
use namespace::autoclean;
use PDK::Utils::Set;
use Carp;

our $VERSION = '0.005';

# 从IP范围获取整数范围
sub getRangeFromIpRange {
    my ($self, $ipMin, $ipMax) = @_;
    my $min = $self->changeIpToInt($ipMin);
    my $max = $self->changeIpToInt($ipMax);
    return (wantarray ? ($min, $max) : PDK::Utils::Set->new($min, $max));
}

# 从IP和掩码获取整数范围
sub getRangeFromIpMask {
    my ($self, $ip, $mask) = @_;
    my $ipPattern = '\d+\.\d+\.\d+\.\d+';

    # 处理IP范围格式 (如: 192.168.1.1-192.168.1.10)
    if ($ip =~ /$ipPattern-$ipPattern/) {
        my ($ipMin, $ipMax) = split('-', $ip);
        return $self->getRangeFromIpRange($ipMin, $ipMax);
    }

    # 将IP转换为整数形式
    $ip = $self->changeIpToInt($ip);

    # 将掩码转换为数字形式 (如: 24)
    $mask = $self->changeMaskToNumForm($mask // 32);

    # 创建二进制掩码字符串
    my $maskString = ('1' x $mask) . ('0' x (32 - $mask));

    # 计算网络地址和广播地址
    my $networkAddress = $ip & oct("0b$maskString");
    my $broadcastAddress = $networkAddress + oct("0b" . ('1' x (32 - $mask)));

    return (wantarray ? ($networkAddress, $broadcastAddress) : PDK::Utils::Set->new($networkAddress, $broadcastAddress));
}

# 从IP和掩码获取网络地址
sub getNetIpFromIpMask {
    my ($self, $ip, $mask) = @_;
    $mask = $self->changeMaskToNumForm($mask // 32);

    my $netIp;
    if ($mask == 32) {
        $netIp = $ip;  # 32位掩码，网络地址就是IP本身
    }
    else {
        $ip = $self->changeIpToInt($ip);
        my $maskString = ('1' x $mask) . ('0' x (32 - $mask));
        my $netIpNum = $ip & oct("0b$maskString");
        $netIp = $self->changeIntToIp($netIpNum);
    }
    return $netIp;
}

# 将整数转换为IP地址
sub changeIntToIp {
    my ($self, $num) = @_;
    # 将数字转换为32位二进制字符串，然后每8位分割并转换为十进制
    my $ip = join('.', map {oct("0b$_")} split(/(?<=[01])(?=(?:[01]{8})+$)/, sprintf("%032b", $num)));
    return $ip;
}

# 将IP地址转换为整数
sub changeIpToInt {
    my ($self, $ip) = @_;
    # 验证IP格式
    if ($ip !~ /^\d+\.\d+\.\d+\.\d+$/o) {
        if ($ip =~ /any/i) {
            $ip = "0.0.0.0";  # 处理'any'特殊值
        }
        else {
            confess("错误: IP地址 $ip 格式不正确");
        }
    }

    # 分割IP为四个部分并处理未定义值
    my @ipParts = map {not defined or /^\s*$/ ? 0 : $_} split(/\./, $ip, 4);

    # 将四个部分组合为32位整数
    my $ipNum = ($ipParts[0] << 24) + ($ipParts[1] << 16) + ($ipParts[2] << 8) + $ipParts[3];
    return $ipNum;
}

# 将掩码转换为数字形式
sub changeMaskToNumForm {
    my ($self, $mask) = @_;
    confess("错误: 掩码未定义") if not defined $mask;

    # 处理点分十进制格式的掩码 (如: 255.255.255.0)
    if ($mask =~ /^\d+\.\d+\.\d+\.\d+$/o) {
        my $binaryString = sprintf("%032b", $self->changeIpToInt($mask));

        # 验证掩码有效性 (不能有01模式)
        if ($binaryString =~ /01/) {
            confess("错误: 掩码 $mask 格式不正确");
        }
        elsif ($binaryString =~ /^(1+)/) {
            $mask = length($1);  # 计算连续1的个数
        }
        else {
            $mask = 0;  # 全0掩码
        }
    }
    elsif ($mask !~ /^\d+$/o) {
        confess("错误: 掩码值 [$mask] 格式不正确");
    }

    # 验证掩码范围
    if ($mask < 0 or $mask > 32) {
        confess("错误: 掩码 $mask 超出有效范围(0-32)");
    }

    return $mask;
}

# 将反掩码转换为掩码
sub changeWildcardToMaskForm {
    my ($self, $wildcard) = @_;
    if ($wildcard =~ /(\d+)\.(\d+)\.(\d+)\.(\d+)/) {
        # 对每个部分进行按位取反操作
        my ($a, $b, $c, $d) = ($1 ^ 255, $2 ^ 255, $3 ^ 255, $4 ^ 255);
        my $mask = "$a.$b.$c.$d";
        return $mask;
    }
    else {
        return undef;  # 无效格式返回undef
    }
}

# 将数字掩码转换为点分十进制格式
sub changeMaskToIpForm {
    my ($self, $mask) = @_;
    my $ip = '';

    # 如果已经是点分十进制格式，直接返回
    if ($mask =~ /^\d+\.\d+\.\d+\.\d+$/o) {
        $ip = $mask;
    }
    # 如果是数字格式 (0-32)，转换为点分十进制
    elsif ($mask >= 0 and $mask <= 32) {
        my $maskString = ('1' x $mask) . ('0' x (32 - $mask));
        my @ipParts = $maskString =~ /([01]{8})(?=(?:[01]{8})*$)/g;
        $ip .= oct("0b$_") . "." for @ipParts[0 .. 3];
        chop($ip);  # 移除末尾的点
    }
    else {
        confess("错误: 掩码 $mask 格式不正确");
    }

    return $ip;
}

# 从整数范围获取IP和掩码
sub getIpMaskFromRange {
    my ($self, $min, $max) = @_;
    my $minIp;

    # 验证参数
    if (not defined $max) {
        confess("错误: 最大值未定义");
    }

    # 将最小值转换为IP格式
    $minIp = $self->changeIntToIp($min);

    # 计算范围大小和掩码
    my $rangeSize = $max - $min + 1;
    my $mask = int(32 - log($rangeSize) / log(2));

    # 检查范围是否可以表示为CIDR格式
    if ($min == ($min & ((1 << 32) - (1 << (32 - $mask)))) and
        $max == $min + (1 << (32 - $mask)) - 1) {
        return $minIp . '/' . $mask;  # 返回CIDR格式
    }
    else {
        return $minIp . '-' . $self->changeIntToIp($max);  # 返回IP范围格式
    }
}

# 从服务字符串获取端口范围
sub getRangeFromService {
    my ($self, $service) = @_;
    my ($protocol, $port) = split('/', $service);
    my $protocolValue;

    # 处理'any'或'0'协议
    if ($protocol eq '0' or $protocol =~ /any/i) {
        return (wantarray ? (0, 16777215) : PDK::Utils::Set->new(0, 16777215));
    }
    # 处理TCP、UDP、ICMP或数字协议
    elsif ($protocol =~ /tcp|udp|icmp|\d+/i) {
        my $protocolNumber;
        if ($protocol =~ /tcp/i) {
            $protocolNumber = 6;
        }
        elsif ($protocol =~ /udp/i) {
            $protocolNumber = 17;
        }
        elsif ($protocol =~ /icmp/i) {
            $protocolNumber = 1;
        }
        elsif ($protocol =~ /\d+/i) {
            $protocolNumber = $protocol;
        }
        $protocolValue = ($protocolNumber << 16);  # 协议号左移16位
    }

    # 处理端口范围
    my ($portMin, $portMax);
    if (defined $port) {
        ($portMin, $portMax) = split(/-|\s+/, $port);
        $portMax = $portMin if not defined $portMax or $portMax =~ /^\s*/s;
    }
    else {
        $portMin = 0;
        $portMax = 0;
    }

    # 返回协议和端口组合后的范围
    return (wantarray ? ($protocolValue + $portMin, $protocolValue + $portMax) :
        PDK::Utils::Set->new($protocolValue + $portMin, $protocolValue + $portMax));
}

__PACKAGE__->meta->make_immutable;
1;

=encoding utf8
=head1 NAME

PDK::Utils::Ip - IP 地址与掩码转换及范围操作工具类

=head1 SYNOPSIS

    use PDK::Utils::Ip;

    my $ipUtil = PDK::Utils::Ip->new;

    # IP 转整数
    my $num = $ipUtil->changeIpToInt("192.168.1.1");
    say $num;  # 3232235777

    # 整数转 IP
    say $ipUtil->changeIntToIp($num);  # 192.168.1.1

    # 获取 IP 范围
    my ($min, $max) = $ipUtil->getRangeFromIpMask("192.168.1.0", "24");

    # 获取网络地址
    say $ipUtil->getNetIpFromIpMask("192.168.1.10", "255.255.255.0"); # 192.168.1.0

    # 服务端口范围
    my ($smin, $smax) = $ipUtil->getRangeFromService("tcp/80");

=head1 DESCRIPTION

该模块提供了一系列与 IP 地址、掩码、端口及服务相关的工具方法，支持 IP 与整数的互转、CIDR/掩码处理、范围计算、以及服务端口解析。

=head1 METHODS

=head2 IP 范围处理

=over 4

=item getRangeFromIpRange($ipMin, $ipMax)

从两个 IP 地址范围 (点分十进制) 获取对应的整数范围。

在列表上下文中返回 (MIN, MAX)，在标量上下文中返回一个 L<PDK::Utils::Set> 对象。

=item getRangeFromIpMask($ip, $mask)

根据 IP 和掩码计算整数范围。

支持以下几种输入：

=over 8

=item * CIDR 格式，例如: C<192.168.1.1/24>

=item * 掩码格式，例如: C<192.168.1.1 255.255.255.0>

=item * IP 范围格式，例如: C<192.168.1.1-192.168.1.10>

=back

返回网络范围的最小值与最大值（列表上下文返回区间，标量上下文返回 Set 对象）。

=item getNetIpFromIpMask($ip, $mask)

根据 IP 和掩码获取网络地址。

=back

=head2 IP 与整数互转

=over 4

=item changeIntToIp($num)

将整数转换为 IP 地址 (点分十进制)。

=item changeIpToInt($ip)

将 IP 地址 (点分十进制) 转换为整数。

支持特殊值 C<any>，转换为 C<0.0.0.0>。

=back

=head2 掩码转换

=over 4

=item changeMaskToNumForm($mask)

将掩码转换为数字形式（0–32）。

支持两种输入：

=over 8

=item * 点分十进制格式 (如 255.255.255.0)

=item * 数字格式 (如 24)

=back

=item changeWildcardToMaskForm($wildcard)

将反掩码（Wildcard Mask）转换为普通掩码。

例如：C<0.0.0.255> 转换为 C<255.255.255.0>。

=item changeMaskToIpForm($mask)

将掩码转换为点分十进制格式。

支持输入数字形式 (0–32)，或已是点分格式。

=back

=head2 IP 范围与 CIDR 转换

=over 4

=item getIpMaskFromRange($min, $max)

将整数范围转换为 CIDR 表示形式（如果能整齐表示），否则返回 IP 范围格式 (C<ip1-ip2>)。

=back

=head2 服务端口处理

=over 4

=item getRangeFromService($service)

根据服务字符串获取协议和端口范围。

输入格式：C<协议/端口>，例如：

=over 8

=item * C<tcp/80> → TCP 协议 80 端口

=item * C<udp/53> → UDP 协议 53 端口

=item * C<icmp/0> → ICMP 协议

=item * C<any> 或 C<0> → 任意协议与端口

=item * C<tcp/20-21> → TCP 协议 20–21 端口

=back

返回值为协议号左移 16 位 + 端口号。
在列表上下文返回 (MIN, MAX)，在标量上下文返回 L<PDK::Utils::Set> 对象。

=back

=head1 ERROR HANDLING

=over 4

=item *

IP 格式不正确时抛出异常。

=item *

掩码格式或范围非法时抛出异常。

=item *

服务字符串不符合格式时可能返回默认范围或异常。

=back

=head1 EXAMPLES

    use PDK::Utils::Ip;

    my $ipUtil = PDK::Utils::Ip->new;

    # IP 转整数
    my $num = $ipUtil->changeIpToInt("192.168.1.1");
    say $num;  # 3232235777

    # 整数转 IP
    say $ipUtil->changeIntToIp($num);  # 192.168.1.1

    # 获取 IP 范围
    my ($min, $max) = $ipUtil->getRangeFromIpMask("192.168.1.0", "24");

    # 获取网络地址
    say $ipUtil->getNetIpFromIpMask("192.168.1.10", "255.255.255.0"); # 192.168.1.0

    # 服务端口范围
    my ($smin, $smax) = $ipUtil->getRangeFromService("tcp/80");

=head1 AUTHOR

WENWU YAN E<lt>968828@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

This software is licensed under the same terms as Perl itself.

=cut
