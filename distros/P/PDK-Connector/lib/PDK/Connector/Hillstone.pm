package PDK::Connector::Hillstone;

use utf8;
use v5.30;
use Moose;
use Carp;
use Data::Dumper;
use Expect qw(exp_continue);

# 继承连接器常用功能
with 'PDK::Connector::Role';

# 登录成功提示符（Hillstone设备特有格式）
has prompt => (
    is       => 'ro',
    required => 0,
    default  => '^.*?(\((?:M|B|F)\))?[>#]\s*$', # 匹配Hillstone设备的提示符格式
);

# 特权模式状态标志（Hillstone设备默认进入特权模式）
has _enable_ => (
    is       => 'ro',
    required => 0,
    default  => 1, # Hillstone设备默认进入特权模式
);

# 等待设备响应，处理各种交互提示
sub waitfor {
    my ($self, $prompt) = @_;
    $prompt //= $self->{prompt}; # 使用提供的提示符或默认提示符

    my $exp = $self->{exp};
    my $buff = "";

    # 等待设备响应，处理各种交互提示
    my @ret = $exp->expect($self->{timeout},
        # 处理分页提示（Hillstone特有格式）
        [ qr/^.+more.+$/mi => sub {
            $exp->send(" ");         # 发送空格继续显示
            $buff .= $exp->before(); # 保存当前输出
            exp_continue;
        } ],
        # 自动输入 Y（处理确认提示）
        [ qr/are you sure\?/i => sub {
            $self->send("y"); # 发送y确认
            $buff .= $exp->before() . $exp->match();
            exp_continue;
        } ],
        # 匹配命令提示符
        [ qr/$prompt/m => sub {
            $buff .= $exp->before() . $exp->match(); # 保存完整输出
        } ]
    );

    # 检查Expect操作是否出错
    if (defined $ret[1]) {
        croak("[等待回显捕捉异常]" . $ret[3] . $ret[1]);
    }

    # 清理输出内容（Hillstone设备特有控制字符）
    $buff =~ s/\c@\cH+\s+\cH+//g; # 移除退格控制字符及其影响的文本
    $buff =~ s/\cM//g;            # 移除回车符（CR），保留换行符（LF）

    return $buff;
}

# 执行多个命令
sub execCommands {
    my ($self, $commands) = @_;

    # 检查登录状态，如果未登录则先登录
    if (!$self->{_login_}) {
        my $ret = $self->login();
        return $ret unless $ret->{success};
    }

    my $result = '';
    # 逐个执行命令
    for my $cmd (@{$commands}) {
        $self->send("$cmd\n");

        # 检查命令是否执行失败（Hillstone特有错误消息）
        my $buff = $self->waitfor();
        if ($buff =~ /incomplete|ambiguous|unrecognized keyword|\^-----/i) {
            return {
                success     => 0,
                failCommand => $cmd,
                result      => $result,
                reason      => $buff
            };
        }
        elsif ($buff =~ /syntax error|missing argument|unknown command|\^Error:/i) {
            return {
                success     => 0,
                failCommand => $cmd,
                result      => $result,
                reason      => $buff
            };
        }
        else {
            $result .= $buff; # 保存命令执行结果
        }
    }

    return { success => 1, result => $result };
}

# 获取设备配置方法（Hillstone特有命令）
sub getConfig {
    my $self = shift;
    my $commands = [
        "terminal length 0", # 禁用分页
        "show configuration" # 显示配置
    ];
    my $config = $self->execCommands($commands);
    my $lines = "";

    if ($config->{success} == 1) {
        $lines = $config->{result};
    }
    else {
        return $config; # 返回错误信息
    }

    return { success => 1, config => $lines };
}

# 使Moose类不可变
__PACKAGE__->meta->make_immutable;
1;

=encoding utf8
=head1 NAME

PDK::Connector::Hillstone - Hillstone 山石防火墙设备连接器

=head1 SYNOPSIS

    use PDK::Connector::Hillstone;

    # 创建 Hillstone 设备连接器实例
    my $conn = PDK::Connector::Hillstone->new(
        host => '192.168.1.1',
        username => 'admin',
        password => 'password'
    );

    # 登录设备
    $conn->login;

    # 获取设备配置
    my $config = $conn->getConfig;

    # 执行自定义命令
    my $result = $conn->execCommands(['show version', 'show interface']);

=head1 DESCRIPTION

Hillstone 山石防火墙设备专用连接器，继承 L<PDK::Connector::Role> 角色，提供与 Hillstone 防火墙设备的交互功能。

支持设备登录、命令执行、配置获取等操作，自动处理 Hillstone 设备特有的交互提示、分页显示和控制字符。

=head1 ATTRIBUTES

=head2 prompt

Hillstone 设备命令行提示符的正则表达式模式，默认匹配包含模式标识（M/B/F）的提示符格式。

=head2 _enable_

特权模式状态标志，Hillstone 设备默认进入特权模式，值为 1。

=head1 METHODS

=head2 waitfor

    my $output = $conn->waitfor($prompt);

等待设备响应，处理 Hillstone 设备特有的交互提示：
- 分页显示控制（more 提示）
- 操作确认提示（are you sure?）

自动清理输出中的控制字符，返回处理后的文本内容。

=head2 execCommands

    my $result = $conn->execCommands(\@commands);

执行多个命令序列。自动检测 Hillstone 特有的错误消息（incomplete/ambiguous/unrecognized keyword/syntax error 等），返回包含执行结果的结构化数据。

=head2 getConfig

    my $config = $conn->getConfig;

获取设备完整配置。使用 Hillstone 特有的命令序列：
- 禁用分页显示（terminal length 0）
- 显示配置（show configuration）

=head1 SEE ALSO

L<PDK::Connector::Role>, L<Expect>, L<Moose>

=head1 AUTHOR

WENWU YAN E<lt>968828@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

版权所有 2025 WENWU YAN。

本软件按Perl自身许可条款发布。

=cut
