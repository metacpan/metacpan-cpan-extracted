package PDK::Connector::Radware;

use utf8;
use v5.30;
use Moose;
use Carp;
use Data::Dumper;
use Expect qw(exp_continue);

# 继承连接器常用功能
with 'PDK::Connector::Role';

# 登录成功提示符（Radware设备特有格式）
has prompt => (
    is       => 'ro',
    required => 0,
    default  => '^>>.*?#\s*$', # 匹配Radware设备的提示符格式
);

# 特权模式状态标志（Radware设备默认进入特权模式）
has _enable_ => (
    is       => 'ro',
    required => 0,
    default  => 1, # Radware设备默认进入特权模式
);

# 等待设备响应，处理各种交互提示
sub waitfor {
    my ($self, $prompt) = @_;
    $prompt //= $self->{prompt}; # 使用提供的提示符或默认提示符

    my $exp = $self->{exp};
    my $buff = "";

    # 等待设备响应，处理各种交互提示
    my @ret = $exp->expect($self->{timeout},
        # 处理保存确认提示
        [ qr/Confirm saving without first applying changes/i => sub {
            $self->send("y\r"); # 发送y确认
            $buff .= $exp->before() . $exp->match();
            exp_continue;
        } ],
        # 处理FLASH保存确认提示
        [ qr/Confirm saving to FLASH/i => sub {
            $self->send("y\r"); # 发送y确认
            $buff .= $exp->before() . $exp->match();
            exp_continue;
        } ],
        # 处理信息转储确认提示
        [ qr/Confirm dumping all information/i => sub {
            $self->send("y\r"); # 发送y确认
            $buff .= $exp->before() . $exp->match();
            exp_continue;
        } ],
        # 处理私钥显示确认提示
        [ qr/(Display|Include) private keys/i => sub {
            $self->send($self->{passphrase} ? "y\r" : "n\r"); # 根据是否有密码短语选择
            $buff .= $exp->before() . $exp->match();
            exp_continue;
        } ],
        # 处理密码短语输入提示
        [ qr/(Enter|Reconfirm) passphrase/i => sub {
            $self->send("$self->{passphrase}\r"); # 发送密码短语
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

    # 清理输出内容（Radware设备特有控制字符）
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

        # 检查命令是否执行失败（Radware特有错误消息）
        my $buff = $self->waitfor();
        if ($buff =~ /Error:/i) {
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

# 获取设备配置方法（Radware特有命令）
sub getConfig {
    my $self = shift;
    my $commands = [
        "cfg/dump", # 转储配置
        "cd",       # 切换目录（可能用于重置上下文）
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

PDK::Connector::Radware - Radware 设备连接器

=head1 SYNOPSIS

    use PDK::Connector::Radware;

    # 创建 Radware 设备连接器实例
    my $conn = PDK::Connector::Radware->new(
        host => '192.168.1.1',
        username => 'admin',
        password => 'password'
    );

    # 登录设备
    $conn->login;

    # 执行配置转储命令
    my $config = $conn->getConfig;

    # 执行自定义命令
    my $result = $conn->execCommands(['show version', 'show status']);

=head1 DESCRIPTION

Radware 设备专用连接器，继承 L<PDK::Connector::Role> 角色，提供与 Radware 网络设备的交互功能。

支持设备登录、命令执行、配置获取等操作，自动处理 Radware 设备特有的交互提示和控制字符。

=head1 ATTRIBUTES

=head2 prompt

Radware 设备命令行提示符的正则表达式模式，默认匹配 '^>>.*?#\s*$' 格式。

=head2 _enable_

特权模式状态标志，Radware 设备默认进入特权模式，值为 1。

=head1 METHODS

=head2 waitfor

    my $output = $conn->waitfor($prompt);

等待设备响应，处理 Radware 设备特有的交互提示：
- 配置保存确认
- FLASH 存储确认
- 信息转储确认
- 私钥显示确认
- 密码短语输入

自动清理输出中的控制字符，返回处理后的文本内容。

=head2 execCommands

    my $result = $conn->execCommands(\@commands);

执行多个命令序列。自动检测命令执行错误，返回包含执行结果的结构化数据。

=head2 getConfig

    my $config = $conn->getConfig;

获取设备完整配置。使用 Radware 特有的 'cfg/dump' 命令转储配置信息。

=head1 SEE ALSO

L<PDK::Connector::Role>, L<Expect>, L<Moose>

=head1 AUTHOR

WENWU YAN E<lt>968828@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

版权所有 2025 WENWU YAN。

本软件按Perl自身许可条款发布。
=cut
