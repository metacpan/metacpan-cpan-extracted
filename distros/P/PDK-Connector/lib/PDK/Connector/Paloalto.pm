package PDK::Connector::Paloalto;

use utf8;
use v5.30;
use Moose;
use Carp;
use Data::Dumper;
use Expect qw(exp_continue);

# 继承连接器常用功能
with 'PDK::Connector::Role';

# 登录成功提示符（Paloalto设备特有格式）
has prompt => (
    is       => 'ro',
    required => 0,
    default  => '^.*?\((?:active|passive|suspended)\)[>#]\s*$', # 匹配Paloalto设备的提示符格式（包含HA状态）
);

# 特权模式状态标志（Paloalto设备默认进入特权模式）
has _enable_ => (
    is       => 'ro',
    required => 0,
    default  => 1, # Paloalto设备默认进入特权模式
);

# 等待设备响应，处理各种交互提示
sub waitfor {
    my ($self, $prompt) = @_;
    $prompt //= $self->{prompt}; # 使用提供的提示符或默认提示符

    my $exp = $self->{exp};
    my $buff = "";

    # 等待设备响应，处理各种交互提示
    my @ret = $exp->expect($self->{timeout},
        # 处理分页提示（Paloalto特有格式）
        [ qr/^lines\s*\d+-\d+\s*$/i => sub {
            $self->send(" "); # 发送空格继续显示
            $buff .= $exp->before();
            exp_continue;
        } ],
        # 处理确认提示
        [ qr/are you sure\?/i => sub {
            $self->send("y\r"); # 发送y确认
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
        croak("[等待回显期间异常]" . $ret[3] . $ret[1]);
    }

    # 清理输出内容（Paloalto设备特有控制字符）
    $buff =~ s/ \cH//g;                  # 移除空格后跟退格符（常用于终端覆盖显示）
    $buff =~ s/(\c[\S+)+\cM(\c[\[K)?//g; # 移除ANSI转义序列和回车符（控制光标位置和清除行）
    $buff =~ s/\cM(\c[\S+)+\c[>//g;      # 移除包含回车符的复杂ANSI序列（通常是终端提示符相关）

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

        # 检查命令是否执行失败（Paloalto特有错误消息）
        my $buff = $self->waitfor();
        if ($buff =~ /^Error:|Unknown command|Invalid syntax/i) {
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

# 获取设备配置方法（Paloalto特有命令）
sub getConfig {
    my $self = shift;
    my $commands = [
        "set cli pager off",                # 禁用分页
        "set cli config-output-format set", # 设置配置输出格式为set命令格式
        "configure",                        # 进入配置模式
        "show",                             # 显示配置
        "quit"                              # 退出配置模式
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

PDK::Connector::Paloalto - Paloalto 防火墙设备连接器

=head1 SYNOPSIS

    use PDK::Connector::Paloalto;

    # 创建 Paloalto 设备连接器实例
    my $conn = PDK::Connector::Paloalto->new(
        host => '192.168.1.1',
        username => 'admin',
        password => 'password'
    );

    # 登录设备
    $conn->login;

    # 获取设备配置
    my $config = $conn->getConfig;

    # 执行自定义命令
    my $result = $conn->execCommands(['show system info', 'show interface all']);

=head1 DESCRIPTION

Paloalto 防火墙设备专用连接器，继承 L<PDK::Connector::Role> 角色，提供与 Paloalto 防火墙设备的交互功能。

支持设备登录、命令执行、配置获取等操作，自动处理 Paloalto 设备特有的交互提示、分页显示和 ANSI 控制字符。

=head1 ATTRIBUTES

=head2 prompt

Paloalto 设备命令行提示符的正则表达式模式，默认匹配包含 HA 状态（active/passive/suspended）的提示符格式。

=head2 _enable_

特权模式状态标志，Paloalto 设备默认进入特权模式，值为 1。

=head1 METHODS

=head2 waitfor

    my $output = $conn->waitfor($prompt);

等待设备响应，处理 Paloalto 设备特有的交互提示：
- 分页显示控制（lines X-X 格式）
- 操作确认提示（are you sure?）

自动清理输出中的 ANSI 转义序列和控制字符，返回处理后的文本内容。

=head2 execCommands

    my $result = $conn->execCommands(\@commands);

执行多个命令序列。自动检测 Paloalto 特有的错误消息（Error:/Unknown command/Invalid syntax），返回包含执行结果的结构化数据。

=head2 getConfig

    my $config = $conn->getConfig;

获取设备完整配置。使用 Paloalto 特有的命令序列：
- 禁用分页显示
- 设置配置输出格式为 set 命令格式
- 进入配置模式并显示配置

=head1 SEE ALSO

L<PDK::Connector::Role>, L<Expect>, L<Moose>

=head1 AUTHOR

WENWU YAN E<lt>968828@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

版权所有 2025 WENWU YAN。

本软件按Perl自身许可条款发布。
=cut
