package PDK::Connector::Huawei;

use utf8;
use v5.30;
use Moose;
use Carp;
use Data::Dumper;
use Expect qw(exp_continue);

# 继承连接器常用功能
with 'PDK::Connector::Role';

# 登录成功提示符（Huawei设备特有格式）
has prompt => (
    is       => 'ro',
    required => 0,
    default  => '^\s*(\x00)?[<\[].*?[>\]]\s*$', # 匹配Huawei设备的提示符格式
);

# 进入特权模式
sub enable {
    my $self = shift;
    my $enPass = $self->{enPassword} // $self->{password}; # 优先使用特权密码
    my $username = $self->{username};
    my $exp = $self->{exp};

    $exp->send("su\n"); # Huawei使用su命令进入特权模式
    my $enable = 1;     # 标记是否已尝试输入密码
    my $result = 0;     # 操作结果

    # 处理进入特权模式的过程
    my @ret = $exp->expect($self->{timeout}, # 使用配置的超时时间
        # 处理密码提示
        [ qr/assword:\s*$/ => sub {
            if ($enable) {
                $enable = 0;
                $exp->send("$enPass\n"); # 输入密码
            }
            else {
                croak("[切换到特权模式异常] 用户或使能密码错误！")
            }
            exp_continue;
        } ],
        # 处理登录名提示
        [ qr/ogin:\s*$|name:\s*$/i => sub {
            $exp->send("$username\n"); # 输入用户名
            exp_continue;
        } ],
        # 成功进入特权模式（匹配Huawei特权模式提示）
        [ qr/(privilege\s+level\s+is.+>\s*\z)|(privilege\s+is\s+.+>\s*\z)/si => sub {
            $self->{_enable_} = 1; # 设置特权模式标志
            $result = 1;           # 设置操作成功标志
        } ],
        # 进入特权模式失败
        [ qr/\^.*$/i => sub {
            croak("请联系管理员检查原因: $1") # 抛出异常并包含错误信息
        } ],
    );

    if (defined $ret[1]) {
        croak("[切换到特权模式异常]" . $ret[3] . $ret[1]);
    }

    return $result;
}

# 等待设备响应，处理各种交互提示
sub waitfor {
    my ($self, $prompt) = @_;
    $prompt //= $self->{prompt}; # 使用提供的提示符或默认提示符

    my $exp = $self->{exp};
    my $buff = "";

    # 处理设备输出中的各种情况
    my @ret = $exp->expect($self->{timeout}, # 使用配置的超时时间
        # 处理分页显示（Huawei特有格式）
        [ qr/^\s*---- More ----\s*$/i => sub {
            $self->send(" "); # 发送空格继续显示
            $buff .= $exp->before();
            exp_continue;
        } ],
        # 处理确认提示
        [ qr/(Are you sure|overwrite|Continue|save operation)\? \[Y\/N\]:/i => sub {
            $self->send("Y\r"); # 自动确认
            $buff .= $exp->before() . $exp->match();
            exp_continue;
        } ],
        # 处理选择提示
        [ qr/Before pressing ENTER you must choose/i => sub {
            $self->send("Y\r"); # 自动选择是
            $buff .= $exp->before() . $exp->match();
            exp_continue;
        } ],
        # 处理按键提示
        [ qr/press the enter key/i => sub {
            $self->send("\r"); # 发送回车
            $buff .= $exp->before() . $exp->match();
            exp_continue;
        } ],
        # 匹配命令提示符，表示命令执行完成
        [ qr/$prompt/m => sub {
            $buff .= $exp->before() . $exp->match();
        } ]
    );

    if (defined $ret[1]) {
        croak("[等待回显捕捉异常]" . $ret[3] . $ret[1]);
    }

    # 清理输出内容（Huawei设备特有控制字符）
    $buff =~ s/\cM+[ ]+\cM//g;             # 删除退格效果
    $buff =~ s/\cM{2}//g;                  # 删除多余回车符
    $buff =~ s/\cM//g;                     # 删除回车符
    $buff =~ s/\x00//g;                    # 删除空字符
    $buff =~ s/\x1b\[\d+D\s+\x1b\[\d+D//g; # 删除ANSI光标左移序列及其影响的空格（用于终端覆盖显示）

    return $buff;
}

# 执行多个命令
sub execCommands {
    my ($self, $commands) = @_;

    # 检查登录状态，如果未登录则先登录
    if ($self->{_login_} == 0) {
        my $ret = $self->login();
        return $ret if $ret->{success} == 0; # 登录失败直接返回
    }

    my $result = "";
    # 如果未进入特权模式，则先进入特权模式
    $self->enable() if not $self->{_enable_};

    # 逐个执行命令
    for my $cmd (@{$commands}) {
        $self->send("$cmd\n");
        my $buff = $self->waitfor();

        # 检查命令是否执行失败（Huawei特有错误消息）
        if ($buff =~ /Ambiguous|Incomplete|not recognized|Unrecognized/i) {
            return {
                success     => 0,
                failCommand => $cmd,    # 失败的命令
                result      => $result, # 已成功执行的命令结果
                reason      => $buff    # 失败原因
            };
        }
        elsif ($buff =~ /Too many parameters|Invalid (input|command|file)|Unknown command|Wrong parameter/i) {
            return {
                success     => 0,
                failCommand => $cmd,    # 失败的命令
                result      => $result, # 已成功执行的命令结果
                reason      => $buff    # 失败原因
            };
        }
        else {
            $result .= $buff; # 保存命令执行结果
        }
    }

    return { success => 1, result => $result };
}

# 获取设备配置方法（Huawei特有命令）
sub getConfig {
    my $self = shift;
    my $commands = [
        "screen-length disable",     # 禁用分页显示
        "dis current-configuration", # 显示当前配置
        "save force",                # 强制保存配置
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

PDK::Connector::Huawei - Huawei 华为设备连接器

=head1 SYNOPSIS

    use PDK::Connector::Huawei;

    # 创建 Huawei 设备连接器实例
    my $conn = PDK::Connector::Huawei->new(
        host => '192.168.1.1',
        username => 'admin',
        password => 'password',
        enPassword => 'enable_password' # 特权密码
    );

    # 登录设备
    $conn->login;

    # 获取设备配置
    my $config = $conn->getConfig;

    # 执行自定义命令
    my $result = $conn->execCommands(['display version', 'display interface']);

=head1 DESCRIPTION

Huawei 华为网络设备专用连接器，继承 L<PDK::Connector::Role> 角色，提供与 Huawei 设备的交互功能。

支持设备登录、特权模式切换、命令执行、配置获取等操作，专门处理 Huawei 设备特有的交互流程和提示信息。

=head1 ATTRIBUTES

=head2 prompt

Huawei 设备命令行提示符的正则表达式模式，默认匹配包含尖括号或方括号的提示符格式。

=head1 METHODS

=head2 enable

    $conn->enable;

进入特权模式。Huawei 设备使用 'su' 命令进入特权模式，自动处理密码输入和权限验证。

=head2 waitfor

    my $output = $conn->waitfor($prompt);

等待设备响应，处理 Huawei 设备特有的交互提示：
- 分页显示控制（---- More ----）
- 操作确认提示（Are you sure? [Y/N]）
- 选择提示（Before pressing ENTER you must choose）
- 按键提示（press the enter key）

自动清理输出中的控制字符、ANSI 转义序列和特殊字符，返回处理后的文本内容。

=head2 execCommands

    my $result = $conn->execCommands(\@commands);

执行多个命令序列。自动检测 Huawei 特有的错误消息（Ambiguous/Incomplete/Unrecognized/Invalid command 等），返回包含执行结果的结构化数据。

=head2 getConfig

    my $config = $conn->getConfig;

获取设备完整配置。使用 Huawei 特有的命令序列：
- 禁用分页显示（screen-length disable）
- 显示当前配置（dis current-configuration）
- 强制保存配置（save force）

=head1 SEE ALSO

L<PDK::Connector::Role>, L<Expect>, L<Moose>

=head1 AUTHOR

WENWU YAN E<lt>968828@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

版权所有 2025 WENWU YAN。

本软件按Perl自身许可条款发布。

=cut
