package PDK::Connector::Role;

use utf8;
use v5.30;
use Moose::Role;
use Carp;
use Expect;

# 设备连接属性定义
has host => (
    is       => 'ro', # 只读属性
    required => 1,    # 必需属性
);

# 用户名属性
has username => (
    is       => 'ro',
    required => 0,
    default  => 'read', # 默认用户名
);

# 密码属性
has password => (
    is       => 'ro',
    required => 0,
    default  => '', # 默认空密码
);

# 密码短语属性
has passphrase => (
    is       => 'ro',
    required => 0,
    default  => '', # 默认空密码短语
);

# 特权模式密码属性
has enPassword => (
    is       => 'ro',
    required => 0,
);

# 连接协议属性
has proto => (
    is       => 'ro',
    required => 0,
    default  => 'ssh', # 默认使用SSH协议
);

# 登录成功提示符
has prompt => (
    is       => 'ro',
    required => 0,
    default  => '^\s*\S+[>\]]\s*$', # 默认提示符
);

# 登录特权模式提示符
has enPrompt => (
    is       => 'ro',
    required => 0,
);

# 会话超时时间
has timeout => (
    is       => 'ro',
    required => 0,
    default  => 30, # 默认30秒
);

# 调试模式
has debug => (
    is       => 'ro',
    required => 0,
    default  => 2, # 默认不打印日志
);

# 日志记录文件
has log_file => (
    is      => 'ro',
    lazy    => 1,
    default => sub {
        my $self = shift;

        # 获取用户家目录（跨平台方式）
        my $home = $ENV{PDK_LOG_DIR};
        $home ||= $ENV{HOME} || $ENV{USERPROFILE} || (getpwuid($<))[7];

        # 创建 logs 目录（如果不存在）
        my $log_dir = "$home/logs";
        mkdir $log_dir unless -d $log_dir;

        # 构建日志文件路径，使用设备IP
        my $host = $self->host;
        return "$log_dir/$host.log";
    },
);

# 登录状态标志（内部使用）
has _login_ => (
    is       => 'ro',
    required => 0,
    default  => 0, # 默认未登录
);

# 特权模式状态标志（内部使用）
has _enable_ => (
    is       => 'ro',
    required => 0,
    default  => 0, # 默认未进入特权模式
);

# 登录设备方法
sub login {
    my $self = shift;
    # 如果已登录，直接返回成功
    return { success => $self->{_login_} } if $self->{_login_};

    # 尝试连接设备
    eval {
        $self->connect() if not defined $self->{exp};
    };

    # 处理连接过程中可能出现的异常
    if ($@) {
        # 处理RSA密钥太小的问题
        if ($@ =~ /RSA modulus too small/) {
            eval {
                $self->connect(' -1 '); # 使用SSHv1协议重试
            };
            if ($@) {
                return { success => 0, reason => $@ };
            }
        }
        # 处理不支持的加密算法问题
        elsif ($@ =~ /Selected cipher type <unknown> not supported by server/i) {
            eval {
                $self->connect('-c des '); # 使用DES加密算法重试
            };
            if ($@) {
                return { success => 0, reason => $@ };
            }
        }
        # 处理连接被拒绝的情况（可能是SSH端口关闭）
        elsif ($@ =~ /Connection refused/i) {
            eval {
                $self->{proto} = 'telnet'; # 切换到Telnet协议
                $self->connect();
            };
            if ($@) {
                return { success => 0, reason => $@ };
            }
        }
        # 处理主机密钥变更的情况
        elsif ($@ =~ /IDENTIFICATION CHANGED/i) {
            # 清除已知主机中的旧密钥
            system("/usr/bin/ssh-keygen -R $self->{host}");
            eval {
                $self->connect(); # 重试连接
            };
            if ($@) {
                return { success => 0, reason => $@ };
            }
        }
        # 处理其他未知错误
        else {
            return { success => 0, reason => $@ };
        }
    }

    # 返回登录结果
    return { success => $self->{_login_} };
}

# 建立设备连接的实际实现
sub connect {
    my ($self, $args) = @_;
    $args = $args // "";

    my $host = $self->{host};
    my $username = $self->{username};
    my $password = $self->{password};
    my $timeout = $self->{timeout};
    my $debug = $self->{debug};
    my $prompt = $self->{prompt};
    my $exp = Expect->new;
    my $login = 0;

    $self->{exp} = $exp;                   # 保存Expect对象实例
    $exp->raw_pty(1);                      # 启用原始PTY模式
    $exp->restart_timeout_upon_receive(1); # 收到数据时重置超时
    $exp->log_stdout($debug);              # 不记录标准输出到STDOUT

    # 构建连接命令
    my $command = $self->{proto} . " $args" . " -l $username $host";
    $exp->spawn($command) or die "[设备登录异常] 无法执行 $command: $!\n";

    my $log_file = $self->log_file;
    $exp->log_file($log_file) if $debug > 1; # 记录会话日志

    # 处理连接过程中的各种提示
    my @ret = $exp->expect($timeout,
        # 处理SSH密钥确认提示
        [ qr/Are you sure you want to continue/i => sub {
            $exp->send("yes\n"); # 自动确认
            exp_continue;        # 继续等待其他提示
        } ],
        # 处理密码输入提示
        [ qr/assword:\s*$/ => sub {
            $exp->send("$password\n") if defined $password;
        } ],
        # 处理登录名提示
        [ qr/login:\s*$/ => sub {
            $exp->send("$username\n");
            exp_continue;
        } ],
        # 处理用户名提示（不区分大小写）
        [ qr/name:\s*$/i => sub {
            $exp->send("$username\n");
            exp_continue;
        } ],
        # 处理主机身份验证变更错误
        [ qr/REMOTE HOST IDEN/ => sub {croak("[设备登录异常] IDENTIFICATION CHANGED！");} ],
        # 成功登录，匹配命令提示符
        [ qr/$prompt/m => sub {$login = 1;} ],
    );

    # 检查Expect操作是否出错
    if (defined $ret[1]) {
        croak("[设备登录异常]" . $ret[3] . $ret[1]);
    }

    # 再次检查，确保登录成功
    @ret = $exp->expect($timeout,
        [ qr/assword:\s*$/ => sub {croak("用户名或密码错误！");} ],
        [ qr/$prompt/m => sub {$login = 1;} ],
    );

    # 检查第二次Expect操作是否出错
    if (defined $ret[1]) {
        croak("[设备登录异常]" . $ret[3] . $ret[1]);
    }

    # 检查是否已处于特权模式（提示符表示特权模式）
    my $enPrompt = $self->{enPrompt} || $self->{prompt};
    if ($exp->match() =~ /$enPrompt/) {
        $self->{_enable_} = 1;
    }

    # 更新登录状态
    $self->{_login_} = $login;
    return 1;
}

# 发送命令到设备
sub send {
    my ($self, $command) = @_;
    my $exp = $self->{exp};
    $exp->send($command);
}

# 等待设备响应，处理各种交互提示
requires 'waitfor';

# 执行多个命令
requires 'execCommands';

# 获取设备运行配置
requires 'getConfig';

1;

# 模块文档
=encoding utf8
=head1 NAME

PDK::Connector::Role - 设备连接器通用角色

=head1 SYNOPSIS

    with 'PDK::Connector::Role';

    # 在连接器类中使用该角色
    has '+host' => (default => '192.168.1.1');
    has '+username' => (default => 'admin');

=head1 DESCRIPTION

设备连接器的通用 Moose 角色，定义了网络设备连接的基本属性和方法。
所有具体的设备连接器类都应该使用这个角色，以确保统一的接口和行为。

=head1 ATTRIBUTES

=head2 host

设备主机名或IP地址，必需属性。

=head2 username

登录用户名，默认为 'read'。

=head2 password

登录密码，默认为空。

=head2 passphrase

密码短语，用于某些需要额外认证的设备。

=head2 enPassword

特权模式密码，用于进入特权模式。

=head2 proto

连接协议，默认为 'ssh'，支持 ssh 和 telnet。

=head2 prompt

登录成功提示符的正则表达式模式。

=head2 enPrompt

特权模式提示符的正则表达式模式。

=head2 timeout

会话超时时间（秒），默认为30秒。

=head2 debug

调试模式级别，默认为2（不打印日志）。

=head2 log_file

日志文件路径，自动生成在用户目录的 logs 子目录下。

=head2 _login_

内部使用的登录状态标志。

=head2 _enable_

内部使用的特权模式状态标志。

=head1 METHODS

=head2 login

    my $result = $conn->login;

登录设备方法。自动处理各种连接异常：
- RSA密钥太小问题
- 不支持的加密算法
- 连接被拒绝（自动切换协议）
- 主机密钥变更

返回包含登录结果的结构化数据。

=head2 connect

    $conn->connect($args);

建立设备连接的实际实现。处理SSH密钥确认、密码输入、用户名提示等交互过程。

=head2 send

    $conn->send($command);

发送命令到设备。

=head2 waitfor

    my $output = $conn->waitfor($prompt);

等待设备响应，需要由具体连接器类实现。

=head2 execCommands

    my $result = $conn->execCommands(\@commands);

执行多个命令序列，需要由具体连接器类实现。

=head2 getConfig

    my $config = $conn->getConfig;

获取设备配置，需要由具体连接器类实现。

=head1 SEE ALSO

L<Moose::Role>, L<Expect>

=head1 AUTHOR

WENWU YAN E<lt>968828@gmail.comE<gt>

=head1 LICENSE AND COPYRIGHT

版权所有 2025 WENWU YAN。

本软件按Perl自身许可条款发布。

=cut
