package PDK::Connector::Cisco;

use utf8;
use v5.30;
use Moose;
use Carp;
use Data::Dumper;
use Expect qw(exp_continue);

# 继承连接器常用功能
with 'PDK::Connector::Role';

# 登录成功提示符
has prompt => (
    is       => 'ro',
    required => 0,
    default  => '\S+[#>]\s*\z', # 匹配Cisco设备的标准提示符格式
);

# 使能模式提示符
has enPrompt => (
    is       => 'ro',
    required => 0,
    default  => '#\s*$', # 匹配Cisco设备的特权模式提示符
);

# 进入特权模式（Cisco设备使用enable命令）
sub enable {
    my $self = shift;
    my $enPass = $self->{enPassword} // $self->{password}; # 优先使用特权密码
    my $username = $self->{username};
    my $exp = $self->{exp};

    $exp->send("enable\n"); # Cisco使用enable命令进入特权模式
    my $enable = 1;
    my $result = 0;

    # 处理进入特权模式的过程
    my @ret = $exp->expect($self->{timeout},
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
        # 成功进入特权模式
        [ qr/$self->{enPrompt}/ => sub {
            $self->{_enable_} = 1; # 设置特权模式标志
            $result = 1;           # 设置操作成功标志
        } ],
        # 进入特权模式失败
        [ qr/\^.*$/i => sub {
            croak("请联系管理员检查原因: $1")
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
    $prompt = $prompt // $self->{prompt}; # 使用提供的提示符或默认提示符
    my $exp = $self->{exp};
    my $buff = "";

    # 处理设备输出中的各种情况
    my @ret = $exp->expect($self->{timeout},
        # 处理分页显示（Cisco特有格式）
        [ qr/^.+more\s*.+$/mi => sub {
            $self->send(" "); # 发送空格继续显示
            $buff .= $exp->before();
            exp_continue;
        } ],
        # 处理配置文件确认提示
        [ qr/\[startup-config\]\?/i => sub {
            $self->send("\r"); # 发送回车确认
            $buff .= $exp->before() . $exp->match();
            exp_continue;
        } ],
        # 处理远程主机地址提示
        [ qr/Address or name of remote host/i => sub {
            $exp->send("\r"); # 发送回车确认
            $buff .= $exp->before() . $exp->match();
            exp_continue;
        } ],
        # 处理目标文件名提示
        [ qr/Destination filename \[/i => sub {
            $exp->send("\r"); # 发送回车确认
            $buff .= $exp->before() . $exp->match();
            exp_continue;
        } ],
        # 匹配命令提示符
        [ qr/$prompt/m => sub {
            $buff .= $exp->before() . $exp->match();
        } ]
    );

    if (defined $ret[1]) {
        croak("[等待回显捕捉异常]" . $ret[3] . $ret[1]);
    }

    # 清理输出内容（Cisco设备特有控制字符）
    $buff =~ s/\r\n|\n+\n/\n/g;                 # 将Windows换行(\r\n)和多个连续换行统一为单个换行符
    $buff =~ s/\x{08}+\s+\x{08}+//g;            # 删除退格符及其后面的空格（用于清除终端上的退格效果）
    $buff =~ s/\x0D\[\s*#+\s*\]?\s*\d{1,2}%//g; # 删除进度条显示（如"[### ] 50%"）
    $buff =~ s/\x1B\[K//g;                      # 删除ANSI控制序列（清除行内容）
    $buff =~ s/\x0D//g;                         # 删除单独的回车符（\r）

    return $buff;
}

# 执行多个命令
sub execCommands {
    my ($self, $commands) = @_;

    # 检查登录状态
    if ($self->{_login_} == 0) {
        my $ret = $self->login();
        return $ret if $ret->{success} == 0; # 登录失败直接返回
    }

    my $result = "";
    # 检查特权模式状态
    $self->enable() if not $self->{_enable_};

    # 逐个执行命令
    for my $cmd (@{$commands}) {
        $self->send("$cmd\n");
        my $buff = $self->waitfor();

        # 检查命令执行结果（Cisco特有错误消息）
        if ($buff =~ /Ambiguous|Incomplete|Unrecognized|not recognized|%Error/i) {
            return {
                success     => 0,
                failCommand => $cmd,
                result      => $result,
                reason      => $1
            };
        }
        elsif ($buff =~ /Permission denied|syntax error|authorization failed/i) {
            return {
                success     => 0,
                failCommand => $cmd,
                result      => $result,
                reason      => $buff
            };
        }
        elsif ($buff =~ /Invalid (parameter|command|input)|Unknown command|Login invalid/i) {
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

# 获取设备配置（Cisco特有命令）
sub getConfig {
    my $self = shift;

    my $commands = [
        "terminal width 511",       # 设置终端宽度
        "terminal length 0",        # 禁用分页
        "show run | exclude !Time", # 显示运行配置，排除时间注释行
        "copy run start"            # 保存配置到启动配置
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

PDK::Connector::Cisco - Cisco设备专用连接器

=head1 SYNOPSIS

    use PDK::Connector::Cisco;

    my $cisco = PDK::Connector::Cisco->new(
        host       => '192.168.1.1',
        username   => 'admin',
        password   => 'password',
        enPassword => 'enablepass'
    );

    my $config = $cisco->getConfig();

=head1 DESCRIPTION

Cisco网络设备专用连接器模块，提供Cisco路由器、交换机等设备的
特殊命令支持和交互处理。

=head1 ATTRIBUTES

=over 4

=item * prompt: Cisco设备标准提示符

=item * enPrompt: 特权模式提示符

=item * enPassword: 特权模式密码

=back

=head1 METHODS

=head2 enable()

进入Cisco设备特权模式。

=head2 waitfor($prompt)

等待设备响应，处理Cisco特有交互提示。

=head2 execCommands(\@commands)

执行多个Cisco命令。

=head2 getConfig()

获取设备配置信息。

=head1 CISCO特有功能

=over 4

=item * 自动处理'more'分页显示

=item * 支持enable特权模式

=item * 识别Cisco错误消息格式

=item * 处理配置确认提示

=back

=head1 EXAMPLES

=head2 获取设备配置

    my $cisco = PDK::Connector::Cisco->new(...);
    my $result = $cisco->getConfig();
    if ($result->{success}) {
        print $result->{config};
    }

=head2 执行Cisco命令

    my $commands = [
        'show version',
        'show interface',
        'show running-config'
    ];
    my $results = $cisco->execCommands($commands);

=head1 DIAGNOSTICS

=over 4

=item * 特权模式失败: 检查enable密码是否正确

=item * 命令执行错误: 确认命令在设备上可用

=item * 连接超时: 检查设备响应状态

=back

=head1 AUTHOR

WENWU YAN E<lt>968828@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

版权所有 2025 WENWU YAN。

本软件按Perl自身许可条款发布。

=cut
