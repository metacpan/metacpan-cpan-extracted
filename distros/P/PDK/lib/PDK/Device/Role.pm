package PDK::Device::Role;

# ABSTRACT: PDK::Device::Role 网络设备登录通用对象属性;
#------------------------------------------------------------------------------
# 加载系统模块
#------------------------------------------------------------------------------
use Moose::Role;
use namespace::autoclean;
use Expect;
use utf8;

our $VERSION = '0.007';

#------------------------------------------------------------------------------
# 注册 Expect 为 Moose 对象类型
#------------------------------------------------------------------------------
use Moose::Util::TypeConstraints;
subtype Expect => as Object => where { $_->isa('Expect') };

#------------------------------------------------------------------------------
# 继承 Net::Device::Role 必须实现的方法
#------------------------------------------------------------------------------
requires '_prompt';
requires '_errorCodes';
requires '_bufferCodes';
requires 'runCommands';

#------------------------------------------------------------------------------
# 运行相关配置
#------------------------------------------------------------------------------
requires '_startupCommands';
requires '_runningCommands';
requires '_healthCheckCommands';

#------------------------------------------------------------------------------
# 网络设备连接器通用方法和属性
#------------------------------------------------------------------------------
has expect => (is => 'rw', isa => 'Expect');

has host => (is => 'ro', isa => 'Str', required => 1,);

has username => (is => 'ro', isa => 'Str', required => 1,);

# 存在不确定性
has enCommand => (is => 'ro', isa => 'Str', lazy => 1, builder => '_enCommand');

has enPassword => (is => 'ro', isa => 'Str', lazy => 1, builder => '_enPassword');

has password => (is => 'ro', isa => 'Str', required => 1,);

# 证书秘钥 -- 支持 SSH_KEY 认证登录
has passphrase => (is => 'rw', isa => 'Str', default => 'xxx',);

has proto => (is => 'ro', isa => 'Str', default => 'ssh',);

has port => (is => 'ro', isa => 'Str|Int|Undef',);

has prompt => (is => 'ro', isa => 'Str', lazy => 1, builder => '_prompt');

has enPrompt => (is => 'ro', isa => 'Str', lazy => 1, builder => '_enPrompt');

has timeout => (is => 'ro', isa => 'Int', default => 45,);

# 设备是否已登录
has status => (is => 'rw', isa => 'Int', default => 0,);

# 设备是否进入 enabled 模式
has enabled => (is => 'rw', isa => 'Int', default => 0,);

# 是否需要捕捉异常
has catchError => (is => 'rw', isa => 'Int', default => 1,);

# 缺省模式为常规，配置模式为 configMode
has mode => (is => 'rw', isa => 'Str', default => 'normal',);

# 异常拦截的错误码
has errorCodes => (is => 'ro', lazy => 1, builder => '_errorCodes');

# 设备脚本执行交互逻辑
has bufferCodes => (is => 'ro', lazy => 1, builder => '_bufferCodes');

has startupCommands => (is => 'ro', isa => 'ArrayRef', builder => "_startupCommands",);

has runningCommands => (is => 'ro', isa => 'ArrayRef', builder => "_runningCommands",);

has healthCheckCommands => (is => 'ro', isa => 'ArrayRef', builder => "_healthCheckCommands",);

# 需要下发的脚本容器
has commands => (
  is       => 'rw',
  isa      => 'ArrayRef[Str]',
  required => 0,
  traits   => ['Array'],
  handles  => {addCommand => 'push', pushCommand => 'unshift'}
);

#------------------------------------------------------------------------------
# telnet 函数入口
#------------------------------------------------------------------------------
sub telnet {
  my ($self, %param) = @_;
  $param{proto} = "telnet";
  return $self->driver(%param);
}

#------------------------------------------------------------------------------
# ssh 函数入口
#------------------------------------------------------------------------------
sub ssh {
  my ($self, %param) = @_;
  $param{proto} = "ssh";
  return $self->driver(%param);
}

#------------------------------------------------------------------------------
# driver 函数入口
#------------------------------------------------------------------------------
sub driver {
  my ($self, %param) = @_;
  my ($host, $username, $password, $proto) = @{param}{qw/host username password proto/};
  $proto //= $self->proto;

  # 初始化会话并连击获取配置信息
  my $session = $self->new(host => $host, username => $username, password => $password, proto => $proto);
  my $result  = $session->getConfig();

  if ($result->{success}) {
    return $result->{config};
  }
  else {
    return $result;
  }
}

#------------------------------------------------------------------------------
# 设备登陆函数入口
#------------------------------------------------------------------------------
sub login {
  my $self = shift;

  # 如果已经登录直接跳过后续代码逻辑
  return {success => 1} if $self->{status};

  # 登录异常拦截和主动重连修复
  eval { $self->connect() unless defined $self->{expect} };
  if ($@ or not $self->{status}) {
    if ($@ =~ /RSA modulus too small/mi) {
      eval { $self->connect(' -1 -c des ') };
      if ($@ or not $self->{status}) {
        return {success => 0, reason => 'RSA modulus too small ' . $@};
      }
    }
    elsif ($@ =~ /Selected cipher type <unknown> not supported/mi) {
      eval { $self->connect('-c des '); };
      if ($@ or not $self->{status}) {
        return {success => 0, reason => 'Cipher not support ' . $@};
      }
    }
    elsif ($@ =~ /Connection refused|Unable to negotiate with/mi) {
      eval {
        $self->{proto} = 'telnet';
        $self->connect();
      };
      if ($@ or not $self->{status}) {
        return {success => 0, reason => "Telnet host $self->{host} failed"};
      }
    }
    elsif ($@ =~ /REMOTE HOST IDENTIFICATION HAS CHANGED/mi) {
      eval {
        `/usr/bin/ssh-keygen -R $self->{host}`;
        $self->connect();
      };
      if ($@ or not $self->{status}) {
        return {success => 0, reason => $@};
      }
    }
    elsif ($@ =~ /Permission denied/i) {
      return {success => 0, reason => 'Permission denied, check username password the ipaddr'};
    }
    elsif ($@ =~ /TIMEOUT/i) {
      return {success => 0, reason => 'Please check network reachability'};
    }
    else {
      $@ =~ s/ at .*$//ims;
      return {success => 0, reason => $@};
    }
  }
  elsif ($self->{status} == 0) {
    return {success => 0, reason => "login $self->{host}/$self->{proto} failed, check policy or credits"};
  }
  return {success => 1};
}

#------------------------------------------------------------------------------
# 联结网络设备
#------------------------------------------------------------------------------
sub connect {
  my ($self, $args) = @_;

  # 检查是否携带变量并初始化
  $args //= "";
  $self->{expect} = undef;
  my $prompt   = $self->prompt;
  my $enPrompt = $self->enPrompt;

  # 初始化Expect函数
  my $expect  = $self->expect($self->_buildExpect);
  my $command = $self->_spawn_command($args);

  $expect->spawn($command) or die "Can not spawn $command: $!\n";
  my @ret = $expect->expect(
    $self->timeout,
    [
      qr/Are you sure you want to continue connecting/i => sub {
        $self->send("yes\n");
        exp_continue;
      }
    ],
    [
      qr/Permission denied/i => sub {
        die "Username or password is wrong when login $self->{host}\n";
      }
    ],
    [
      qr/assword:.*/i => sub {
        $self->send($self->password . "\n");
        exp_continue;
      }
    ],
    [
      qr/Enter passphrase for key/i => sub {
        $self->send($self->passphrase . "\n");
        exp_continue;
      }
    ],
    [
      qr/(ogin|name):\s*$/i => sub {
        $self->send($self->username . "\n");
        exp_continue;
      }
    ],
    [
      qr/REMOTE HOST IDENTIFICATION HAS CHANGED/i => sub {
        die "REMOTE HOST IDENTIFICATION HAS CHANGED\n";
      }
    ],
    [
      qr/$prompt/ => sub {
        $self->{status} = 1;
      }
    ],
  );

  # 异常拦截
  if (defined $ret[1] or not $self->{status}) {
    die "Connect host $self->{host} failed " . $ret[3] . "\n";
  }

  # 确定是否 enable 模式
  if ($expect->match =~ /$enPrompt/i) {
    $self->{enabled} = 1;
  }
  else {
    if ($self->enable) {
      $self->{enabled} = 1;
    }
    else {
      die "Can't switch to enable mode when exec connect method\n";
    }
  }

  return 1;
}

#------------------------------------------------------------------------------
# 进入使能模式
#------------------------------------------------------------------------------
sub enable {
  my $self = shift;

  # 变量初始化
  my $prompt   = $self->prompt;
  my $enPrompt = $self->enPrompt;

  # 初始化 expect 会话
  # 异常拦截，确保此处已登陆到设备，如果没有登陆后续逻辑无法正常执行
  my $expect = $self->expect;
  die "Should login host $self->{host} during enable mode\n" unless !!$expect;

  # 进入使能配置模式
  $self->send($self->enCommand . "\n");
  my @ret = $expect->expect(
    15,
    [
      qr/Permission denied|invalid/i => sub {
        die "username or enPassword is wrong when login $self->{host}\n";
      }
    ],
    [
      qr/assword:\s*/i => sub {
        $self->send($self->enPassword . "\n");
        exp_continue;
      }
    ],
    [
      qr/(login|name)/i => sub {
        $self->send($self->username . "\n");
        exp_continue;
      }
    ],
    [qr/$enPrompt/ => sub { $self->{enabled} = 1 }],
    [qr/$prompt/mi => sub { die "Can not switch to enable mode: " . $self->enCommand . "\n" }],
  );

  # 捕捉异常信号
  if (defined $ret[1] or not $self->{enabled}) {
    die "Switch enable failed: " . $self->enCommand . $ret[3] . "\n";
  }
  else {
    return 1;
  }
}

#------------------------------------------------------------------------------
# send 推送脚本 -- 支持自动识别是否携带换行回车，以及显示设定 flag
#------------------------------------------------------------------------------
sub send {
  my ($self, $command, $flag) = @_;
  if (defined $flag) {
    $self->expect->send($command . $flag);
  }
  else {
    $self->expect->send($command);
  }
}

#------------------------------------------------------------------------------
# 具体实现 waitfor，自动交互式执行脚本
#------------------------------------------------------------------------------
sub waitfor {
  my ($self, $prompt) = @_;

  # 设置缺省提示符
  $self->{isMatched} = 0;
  $prompt //= $self->prompt;

  # 变量初始化
  my $buff     = "";
  my $expect   = $self->expect;
  my $mapping  = $self->bufferCodes;
  my $codeARef = [];

  # 过滤部分输出
  if ($mapping->{ignore}) {
    foreach my $element (@{$mapping->{ignore}}) {
      push @{$codeARef}, [
        qr/$element/mi => sub {
          exp_continue;
        }
      ];
    }
  }

  # 执行等待
  push @{$codeARef}, [
    qr/$mapping->{more}/mi => sub {
      $buff .= $expect->before;
      $self->send(" ");
      exp_continue;
    }
  ] if $mapping->{more};

  # 交互式脚本执行
  while (my ($wait, $action) = each %{$mapping->{interact}}) {
    push @{$codeARef}, [
      qr/$wait/mi => sub {
        $buff .= $expect->before . $expect->match;
        $self->send($action);
        exp_continue;
      }
    ];
  }

  # 执行成功捕捉输出符
  push @{$codeARef}, [
    qr/$prompt/mi => sub {
      $buff .= $expect->before . $expect->match . $expect->after;
    }
  ];

  # 交互式执行数据观察
  my @ret = $expect->expect($self->timeout, @{$codeARef});

  # 异常拦截和早期字串裁剪
  if (defined $ret[1]) {
    die 'Output not match waitfor pattern ' . $ret[3] . "\n";
  }
  else {
    $self->{isMatched} = 1;

    # 脚本执行成功字串裁剪
    # $buff =~ s/\r\n|\n+\n/\n/g;
    # $buff =~ s/^\s*$//g;
    # $buff =~ s/^%.+$//g;
    # $buff =~ s/\015//g;
    # $buff =~ s/\x{08}+\s+\x{08}+//g;
    # $buff =~ s/\x1b\[\d+D\s+\x1b\[\d+D//g;
  }

  # 后期特定厂商可能需要进一步修正字串
  if ($self->can('truncateCommand')) {
    return $self->truncateCommand($buff);
  }
  else {
    return $buff;
  }
}

#------------------------------------------------------------------------------
# execCommands 执行批量下发脚本 || 如果未设置脚本，则默认返回运行配置
#------------------------------------------------------------------------------
sub execCommands {
  my ($self, @commands) = @_;

  # 早期异常拦截
  return {success => 0, failCommand => "No commands", reason => "No commands"} unless @commands > 0;

  # 阶段一：下发配置前确保已登录到设备上边
  unless ($self->{status}) {
    eval { $self->login };
    if ($@ or not $self->{status}) {
      return {success => 0, failCommand => 'Commands can not execute', reason => "Can not login device when execCommands"};
    }
  }

  # 阶段二：配置下发模式，确保进入 enable 模式
  if ($self->{mode} eq 'configMode' and not $self->{enabled}) {
    eval { $self->enable($self->enCommand); };
    if ($@ or not $self->{enabled}) {
      return {
        success     => 0,
        failCommand => 'Commands can not execute',
        reason      => qq{Can't change to enable mode when execCommands}
      };
    }
  }

  # 设定登录成功提示符字串
  my $result = $self->expect->match;

  # 按序执行脚本下发，执行期间遇到异常直接跳出后续脚本执行
  while (my $cmd = shift @commands) {

    # 自动跳过注释行和空白行
    # Linux 需要添加，网络设备待确定
    # $result .= "$cmd\n";
    next if $cmd =~ /^\s*$/;
    next if $cmd =~ /^[#!;]/;

    # 执行脚本并等待输出，判断是否符合预期
    my $buff;
    eval {
      $self->send("$cmd\n");
      $buff = $self->waitfor;
    };
    if ($@ or not $self->{isMatched}) {
      $self->{commands} = [];
      return {success => 0, failCommand => $cmd, reason => $@ . $result};
    }
    elsif ($self->catchError) {
      foreach my $error (@{$self->errorCodes}) {
        if ($buff and $buff =~ /$error/mi) {
          $self->{commands} = [];    # 捕捉异常期间及时清除 commands 队列
          return {success => 0, failCommand => $cmd, reason => $result . $buff};
        }
      }
      $result .= $buff;
    }
  }
  return {success => 1, config => $result};
}

#------------------------------------------------------------------------------
# getConfig 执行脚本调度基础组件
#------------------------------------------------------------------------------
sub getConfig {
  my ($self, $action) = @_;
  $action //= 'runningCommands';
  my $commands = $self->{$action};
  my $result   = $self->execCommands(@{$commands});

  if ($result->{success} == 1) {
    return {success => 1, config => $result->{config}};
  }
  return $result;
}

#------------------------------------------------------------------------------
# 定义 deploy 执行现有的命令行脚本
#------------------------------------------------------------------------------
sub deploy {
  my ($self, @commands) = @_;
  $self->{mode} = "configMode";    # 变量内插，设定配置下发模式
  return $self->runCommands(@commands);
}

#------------------------------------------------------------------------------
# _enPrompt 设置缺省使能模式提示符
#------------------------------------------------------------------------------
sub _enPrompt {
  my $self = shift;
  $self->{enPrompt} //= $self->prompt;
}

#------------------------------------------------------------------------------
# _enPassword 设置缺省使能密码
#------------------------------------------------------------------------------
sub _enPassword {
  my $self = shift;
  $self->{enPassword} //= $self->password;
}

#------------------------------------------------------------------------------
# startupConfig 获取设备运行配置
#------------------------------------------------------------------------------
sub startupConfig {
  my $self = shift;
  $self->getConfig("startupCommands");
}

#------------------------------------------------------------------------------
# runningConfig 获取设备运行配置
#------------------------------------------------------------------------------
sub runningConfig {
  my $self = shift;
  $self->getConfig("runningCommands");
}

#------------------------------------------------------------------------------
# healthCheck 获取设备运行配置
#------------------------------------------------------------------------------
sub healthCheckConfig {
  my $self = shift;
  $self->getConfig("healthCheckCommands");
}

#------------------------------------------------------------------------------
# _buildExpect 懒加载动态生成 Expect->new 对象
#------------------------------------------------------------------------------
sub _buildExpect {
  my $self = shift;

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

#------------------------------------------------------------------------------
# _spawn_command 根据协议生成登录脚本
#------------------------------------------------------------------------------
sub _spawn_command {
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

1;
