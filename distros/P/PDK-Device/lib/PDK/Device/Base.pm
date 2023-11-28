package PDK::Device::Base;

# 使用 Moose 的 Role 功能
use Moose::Role;
use Carp;

# use open qw(:std :utf8);

# 导入 Expect 模块，用于实现交互式脚本的功能
use Expect;
use namespace::autoclean;

# 定义 Moose 类型约束，用于限制 Expect 类型的属性
use Moose::Util::TypeConstraints;
subtype Expect => as Object => where { $_->isa('Expect') };

# 主机名
has host => (is => 'ro', required => 1);

# 用户名
has username => (is => 'ro', required => 0, default => 'admin');

# 密码
has password => (is => 'ro', required => 0, default => 'Cisc0123');

# 特权密码
has enPassword => (is => 'ro', required => 0);

# 端口
has port => (is => 'ro', required => 0);

# 连接协议
has proto => (is => 'ro', required => 0, default => 'ssh');

# 是否已登录
has isLogin => (is => 'rw', required => 0, default => 0);

# 是否已进入特权模式
has isEnable => (is => 'rw', required => 0, default => 0);

# Expect 对象
has expect => (is => 'rw', isa => 'Expect');

# 配置获取方法，需在具体设备类中实现
requires 'getConfig';
requires 'waitfor';
requires 'execCommands';

# 命令提示符正则表达式
sub prompt {
  shift;
  return '\S+[#>]\s*\z';
}

# 特权模式命令提示符正则表达式
sub enPrompt {
  my $self = shift;
  return $self->prompt();
}

# Telnet 连接方法
sub telnet {
  my ($self, %param) = @_;
  $param{proto} = "telnet";
  croak("请正确提供登录设备的权限账户密码") unless $param{username} && $param{password};
  return $self->driver(%param);
}

# SSH 连接方法
sub ssh {
  my ($self, %param) = @_;
  $param{proto} = "ssh";
  croak("请正确提供登录设备的权限账户密码") unless $param{username} && $param{password};
  return $self->driver(%param);
}

# 登录方法
sub login {
  my $self = shift;
  return {success => $self->{isLogin}} if $self->{isLogin};

  eval { $self->connect(); };

  # 处理不同的连接异常情况
  if (!!$@) {
    $@ =~ s/^\s+//;
    $@ =~ s/^\s*$//g;
    if ($@ =~ /RSA modulus too small/) {
      eval { $self->connect('-v -1 -c des '); };
      if (defined $@) {
        return {success => 0, failCommand => 'RSA 模数太小', reason => $@};
      }
    }
    elsif ($@ =~ /Selected cipher type <unknown> not supported by server/i) {
      eval { $self->connect('-c des '); };
      if (defined $@) {
        return {success => 0, failCommand => '服务器不支持所选密码类型 ', reason => $@};
      }
    }
    elsif ($@ =~ /Connection refused/i) {
      eval {
        $self->{proto} = 'telnet';
        $self->connect();
      };
      if (defined $@) {
        return {success => 0, failCommand => '尝试 telnet 登录期间捕捉异常', reason => $@};
      }
    }
    elsif ($@ =~ /IDENTIFICATION CHANGED/i) {
      `/usr/bin/ssh-keygen -R $self->{host}`;
      eval { $self->connect(); };
      if (defined $@) {
        return {success => 0, failCommand => '设备身份识别已更改', reason => $@};
      }
    }
    else {
      return {success => 0, failCommand => '尝试重新登录设备期间捕捉到异常', reason => $@};
    }
  }

  return {success => $self->{isLogin}};
}

# 连接方法
sub connect {
  my ($self, $args) = @_;
  $args //= "";

  my $username = $self->{username};
  my $password = $self->{password};
  my $prompt   = $self->prompt();
  my $command  = $self->buildConnector();
  my $exp      = $self->expect($self->buildExpect);

  $exp->spawn($command) or die "Expect函数执行 spawn 方法期间捕捉到异常 $command: $!\n";
  my @ret = $exp->expect(
    15,
    [
      qr/Are you sure you want to continue connecting/i => sub {
        $exp->send("yes\n");
        exp_continue;
      }
    ],
    [
      qr/(name|ogin):\s*$/ => sub {
        $exp->send("$username\n");
        exp_continue;
      }
    ],
    [qr/assword:\s*$/     => sub { $exp->send("$password\n") }],
    [qr/REMOTE HOST IDEN/ => sub { croak("IDENTIFICATION CHANGED!") }],
    [qr/$prompt/          => sub { $self->isLogin(1); }],
  );

  if (defined $ret[1]) {
    croak($ret[3]);
  }

  @ret = $exp->expect(
    10,
    [qr/assword:\s*$/ => sub { croak("Username or password is wrong!") }],
    [qr/$prompt/m     => sub { $self->isLogin(1) }],
  );

  if (defined $ret[1]) {
    croak($ret[3] . $ret[1]);
  }

  my $enPrompt = $self->enPrompt();
  if ($exp->match() =~ /$enPrompt/) {
    $self->isEnable(1);
  }

  return 1;
}

# 发送命令方法
sub send {
  my ($self, $command) = @_;
  my $exp = $self->expect;
  $exp->send($command);
}

# 生成 Expect->new 对象
sub buildExpect {
  shift;

  # 实例化 Expect 函数对象
  my $exp = Expect->new();
  $exp->raw_pty(1);
  $exp->debug(0);
  $exp->restart_timeout_upon_receive(1);

  # 是否打印日志，一般用于排错
  # $exp->log_file("output.log");
  $exp->log_stdout(1);
  return $exp;
}

# 驱动方法，根据连接协议选择相应的连接方式
sub driver {
  my ($self, %param) = @_;

  # 从参数中获取主机名、用户名、密码和连接协议，使用对象属性中的默认连接协议
  my ($host, $username, $password, $proto) = @param{qw/host username password proto/};

  # 创建网络设备对象，初始化会话并获取配置信息
  my $session = $self->new(host => $host, username => $username, password => $password, proto => $proto);
  my $result  = $session->startupConfig();

  # 返回获取配置信息的结果
  return $result->{success} ? $result->{config} : $result;
}

# 根据协议生成登录脚本
sub buildConnector {
  my ($self, $args) = @_;

  # 初始化变量
  my $user  = $self->username;
  my $host  = $self->host;
  my $port  = $self->port;
  my $proto = $self->proto;

  # 动态生成会话连接参数
  $args //= "";
  my $command;
  if (!!$port) {
    if ($proto =~ /telnet/i) {
      $command = qq{$proto $args -l $user $host $port};
    }
    elsif ($proto =~ /ssh/i) {
      $command = qq{$proto $args -l $user $host -p $port};
    }
  }
  else {
    $command = qq{$proto $args -l $user $host};
  }
  return $command;
}

sub enable {
  shift;
  return 0;
}

1;
