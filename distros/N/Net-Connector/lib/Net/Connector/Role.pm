package Net::Connector::Role;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use 5.016;
use utf8;
use Try::Tiny;
use Expect;
use Moose::Role;
use namespace::autoclean;

# 调试模式
# use Data::Printer;
# use Data::Dumper;

#------------------------------------------------------------------------------
# 继承 Net::Connector::Role 必须实现的方法
#------------------------------------------------------------------------------
requires '_prompt';
requires '_errorCodes';
requires '_bufferCodes';
requires 'runCommands';
# 运行相关配置
requires '_startupCommands';
requires '_runningCommands';
requires '_healthCheckCommands';
requires 'truncateCommand';

#------------------------------------------------------------------------------
# 定义生成登录脚本字串的相关状态和变量 spawn
#------------------------------------------------------------------------------
has exp => (
  is      => 'ro',
  isa     => 'Expect',
  default => sub { Expect->new },
  handles => [ 'spawn', 'expect', 'interact' ]
);

has host => (
  is       => 'ro',
  required => 1,
);

has tftp_server => (
  is      => 'ro',
  default => 'tftp://192.168.8.105/',
);

has username => (
  is       => 'ro',
  required => 0,
  default  => 'cisco'
);

has password => (
  is       => 'ro',
  required => 0,
  default  => 'cisco',
);

has port => (
  is        => 'ro',
  predicate => 'hasPort'
);

has enPassword => (
  is        => 'ro',
  required  => 0,
  predicate => 'hasEnPassword'
);

has proto => (
  is       => 'ro',
  traits   => ["Enumeration"],
  enum     => [qw/ssh telnet/],
  required => 1,
  default  => 'ssh',
);

has status => (
  is      => 'ro',
  isa     => 'Int',
  default => 0,
  writer  => 'setStatus'
);

has enabled => (
  is      => 'ro',
  isa     => 'Int',
  default => 0,
  writer  => 'setEnabled',
);

#------------------------------------------------------------------------------
#  定义设备登录后自动交互逻辑，细节由各厂商实现
#------------------------------------------------------------------------------
has prompt => (
  is       => 'ro',
  builder  => "_prompt",
  required => 1
);

has enPrompt => (
  is => 'ro',
  # builder   => "_enPrompt",
  predicate => 'hasEnPrompt',
  writer    => 'setEnPrompt',
  required  => 0
);

has enableCommand => (
  is       => 'ro',
  isa      => 'Str',
  default  => 'enable',
  required => 0,
);

has errorCodes => (
  is      => 'ro',
  builder => '_errorCodes'
);

has bufferCodes => (
  is      => 'ro',
  builder => '_bufferCodes'
);

#------------------------------------------------------------------------------
# 定义不同厂商需要加载的临时变量和脚本修正逻辑
#------------------------------------------------------------------------------
has startupCommands => (
  is       => 'ro',
  isa      => 'ArrayRef',
  builder  => "_startupCommands",
  required => 1,
);

has runningCommands => (
  is       => 'ro',
  isa      => 'ArrayRef',
  builder  => "_runningCommands",
  required => 1,
);

has healthCheckCommands => (
  is       => 'ro',
  isa      => 'ArrayRef',
  builder  => "_healthCheckCommands",
  required => 0,
);

has timeout => (
  is      => 'ro',
  isa     => 'Int',
  default => 60,
  writer  => 'setTimeout'
);

#------------------------------------------------------------------------------
# login 登录网络设备，支持异常重连
#------------------------------------------------------------------------------
sub login {
  my $self = shift;
  # 检查是否已经登录过 | 边界条件检查
  return { success => 1 } if $self->status == 1;

  # 尝试连接设备,支持异常重连机制
  try {
    $self->connect();
  }
  catch {
    if (/RSA modulus too small/i) {
      try { $self->connect('-v -1 -c des ') }
      catch {
        return {
          success => 0,
          reason  => $_
        };
      }
    }
    elsif (/Selected cipher type <.*> not supported/i) {
      try {
        $self->connect('-c des ');
      }
      catch {
        return {
          success => 0,
          reason  => $_
        };
      }
    }
    elsif (/IDENTIFICATION CHANGED!/i) {
      try {
        `/usr/bin/ssh-keygen -R $self->{host}`;
        $self->connect();
      }
      catch {
        return {
          success => 0,
          reason  => $_
        };
      }
    }
    else {
      return {
        success => 0,
        reason  => $_
      };
    }
  };
}

#------------------------------------------------------------------------------
# _spawn_command 根据协议生成登录脚本
#------------------------------------------------------------------------------
sub _spawn_command {
  my ( $self, $args ) = @_;
  $args ||= "";

  # 初始化变量
  my $command;

  # 绑定已有变量
  my $user  = $self->{username};
  my $host  = $self->{host};
  my $port  = $self->{port};
  my $proto = $self->{proto};

  # 判断是否定义非标端口
  if ( $self->hasPort ) {

    # 根据不同协议生成脚本，telnet 协议兼容性可能有问题
    if ( $proto =~ /telnet/i ) {
      $command = $proto . " $args" . " -l $user $host $port";
    }
    elsif ( $proto =~ /ssh/i ) {
      $command = $proto . " $args" . " -l $user $host -p $port";
    }
  }
  else {
    $command = $proto . " $args" . " -l $user $host";
  }

  # 返回计算结果
  return $command;
}

#------------------------------------------------------------------------------
# connect 设备联机登录
#------------------------------------------------------------------------------
sub connect {
  my ( $self, $args ) = @_;
  # 初始化变量
  my $username = $self->{username};
  my $password = $self->{password};

  # 初始化 Expect 函数
  my $exp = Expect->new();
  $exp->raw_pty(1);
  $exp->debug(0);
  $exp->restart_timeout_upon_receive(1);

  # setting exp attribute
  $self->{exp} = $exp;

  # 是否打印日志，一般用于排错
  $exp->log_stdout(0);

  # 设置登录逻辑生成登录脚本
  my $status  = 1;
  my $command = $self->_spawn_command($args);

  # 尝试登录设备并执行异常拦截
  $exp->spawn($command) || confess __PACKAGE__ . " case0) connect | Cannot spawn $command: $!\n";

  # 登录期间交互式运行脚本
  my @ret = $exp->expect(
    30,

    # 自动输入 yes
    [
      qr/continue connecting \(yes\/no/i => sub {
        $exp->send("yes\n");
        exp_continue();
      }
    ],

    # 自动输入密码,且仅输入一次
    [
      qr/password:/i => sub {
        if ( $status == 1 ) {
          $status = 0;
          $exp->send("$password\n");
        }
        else {
          confess __PACKAGE__ . " case1) connect | Login ($self->{host}) failed, please provide the correct account password;";
        }
        exp_continue();
      }
    ],

    # 自动输入账号 | 脚本已经绑定用户名
    [
      qr/(ogin|name):\s*$/i => sub {
        $exp->send("$username\n");
        exp_continue();
      }
    ],
    [
      qr/(REMOTE HOST IDENTIFICATION|HOST IDENTIFICATION HAS CHANGED)/i => sub {
        croak("IDENTIFICATION CHANGED!");
      }
    ],

    # 捕捉到脚本下发正常提示符
    [
      qr/$self->{prompt}/ => sub {
        $self->setStatus(1);

        # 缺省情况下 没有 enable 模式
        $self->setEnabled(1) if $self->{prompt} eq $self->{enPrompt};
      }
    ],

    # 捕捉到脚本下发正常提示符
    [
      qr/$self->{enPrompt}/ => sub {
        $self->enable();
      }
    ]
  );

  # Expect是否异常
  if ( defined $ret[1] ) {
    confess __PACKAGE__ . " case2) connect | Exception caught during login to node ($self->{host}): $ret[3] . $ret[1]";
  }

  # if ($exp->match() =~ />/) {
  #   $self->enable();
  # } elsif ($exp->match() =~ /#/) {
  #   $self->{_enable_} = 1;
  # }
  return 1;
}

#------------------------------------------------------------------------------
# send 设备发送指令入口函数，接收字符串
#------------------------------------------------------------------------------
sub send {
  my ( $self, $command ) = @_;
  $self->{exp}->send($command);
}

#------------------------------------------------------------------------------
# 具体实现 waitfor，自动交互式执行脚本
#------------------------------------------------------------------------------
sub waitfor {
  my $self = shift;
  # 初始化变量
  my $buff = "";

  # 继承 exp 属性
  my $exp = $self->{exp};

  # 初始化缓存代码
  my $codeARef = [];
  my $mapping  = $self->bufferCodes();

  # 捕捉 more 交互式 code
  push $codeARef->@*, [
    qr/$mapping->{more}/mi => sub {
      $buff .= $exp->before();
      $exp->send(' ');
      exp_continue();
    }
  ] if exists $mapping->{more};

  # 遍历其他交互式字典映射
  while ( my ( $wait, $action ) = each $mapping->{interact}->%* ) {
    push $codeARef->@*, [
      qr/$wait/mi => sub {
        $buff .= $exp->before() . $exp->match();
        $exp->send("$action\n");
        exp_continue();
      }
    ];
  }

  # 捕捉脚本正常下发回显
  push $codeARef->@*, [
    qr/$self->{prompt}/mi => sub {
      $buff .= $exp->before() . $exp->match();
    }
  ];
  # say dumper $codeARef;

  # 动态加载交互式代码
  my @ret = $self->expect( 30, $codeARef->@* );

  # 异常捕捉
  if ( defined $ret[1] ) {
    confess __PACKAGE__ . " case 9) waitfor |  Exception caught when waitfor ($self->{host}) results：$ret[3] . $ret[1]";
  }

  # 返回修正后的脚本
  return $buff ? $self->truncateCommand($buff) : "";
}

# TODO 这里逻辑需要优化
#------------------------------------------------------------------------------
# execCommands 执行批量下发脚本 || 如果未设置脚本，则默认返回运行配置
#------------------------------------------------------------------------------
sub execCommands {
  my ( $self, @commands ) = @_;
  @commands = $self->runningCommands->@* unless scalar(@commands) > 0;

  # 判断是否已登陆设备
  if ( $self->status == 0 ) {
    $self->login();

    # 未成功登录设备，异常拦截
    return {
      success     => 0,
      failCommand => join( "\n", @commands ),
      reason      => "case 7) execCommands | Login host($self->{host}) failure when attempting login and deploy task"
      }
      if ( $self->status == 0 );

    # 检查是否进入 enable 状态
    if ( $self->enabled == 0 ) {

      # 尝试进入 enable
      $self->enable();

      # 异常拦截
      return {
        success     => 0,
        failCommand => join( "\n", @commands ),
        reason      => "case 8) execCommands | The device($self->{host}) cannot switch-to enable mode when deploy task"
        }
        if $self->enabled == 0;
    }
  }

  # 初始化 result 变量，并开始执行命令
  my $result = "";

  # 遍历接受到的命令行
  while ( my $cmd = shift @commands ) {

    # 自动跳过空白行和注释行
    next if $cmd =~ /^\s*$/;
    next if $cmd =~ /^[#|!]/;

    # 执行具体的脚本
    $self->send("$cmd\n");

    # 命令下发后需要等待返回输出
    my $buff = $self->waitfor();

    # 异常拦截，基于正则表达式判断是否匹配错误码
    foreach my $error ( $self->errorCodes->@* ) {
      return {
        success     => 0,
        failCommand => $cmd,
        reason      => $result . $buff
      } if ( $buff =~ /$error/mi );
    }

    # 脚本执行正常,则拼接字符串
    $result .= $buff;
  }

  # 输出计算结果
  return {
    success => 1,
    config  => $result
  };
}

#------------------------------------------------------------------------------
# getConfig 执行脚本调度基础组件
#------------------------------------------------------------------------------
sub getConfig {
  my ( $self, $flag ) = @_;
  # 抓取设备命令脚本，输入不分页命令加速输出
  my $commands = $self->${flag};
  my $ret      = $self->execCommands( $commands->@* );

  # 判断是否执行成功
  if ( $ret->{success} == 1 ) {
    return {
      success => 1,
      config  => $ret->{config}
    };
  }

  # 兜底的返回结果
  return $ret;
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
# 定义设备 enable 方法
#------------------------------------------------------------------------------
sub enable {
  my $self = shift;

  # 早期状态拦截
  return if $self->enable == 1;

  # 异常拦截
  confess "Please configure enablePrompt correctly, usually is a regular expression"
    unless $self->hasEnPrompt;

  # 初始化变量
  my $username = $self->{username};
  my $enPasswd = $self->{enPassword} || $self->{password};
  my $exp      = $self->{exp};

  # 判断需要进入 enable 后执行
  $exp->send( $self->enableCommand . "\n" );
  my $status = 1;
  my @ret    = $self->expect(
    15,
    [
      qr/assword:\s*$/mi => sub {
        if ( $status == 1 ) {
          $status = 0;
          $exp->send("$enPasswd\n");
        }
        else {
          confess __PACKAGE__ . " case5) enable | Please fill in the user and enable password correctly";
        }
        exp_continue();
      }
    ],
    [
      qr/(ogin|name):\s*$/mi => sub {
        $exp->send("$username\n");
        exp_continue();
      }
    ],
    [
      qr/$self->enPrompt/ => sub {
        $self->setEnabled(1);
      }
    ]
  );

  # 异常回显信号捕捉
  if ( defined $ret[1] ) {
    confess __PACKAGE__ . " case6) enable | during interactive authenticate enable password, got errors：$ret[3] . $ret[1]";
  }
}

#------------------------------------------------------------------------------
# 定义 deploy 执行现有的命令行脚本
#------------------------------------------------------------------------------
sub deploy {
  my ( $self, @commands ) = @_;

  # 异常拦截 | 命令行为空直接返回
  return {
    success     => 0,
    failCommand => "Not defined commands.",
    reason      => "Must provide specific configs.",
    }
    if scalar @commands == 0;

  # 遍历已有的 commands
  return $self->execCommands(@commands);
}

#------------------------------------------------------------------------------
# 定义 generate_vendor_connector 根据厂商自动生成连接器
#------------------------------------------------------------------------------
sub generate_vendor_connector {
  my ( $self, $vendor ) = @_;
  no warnings 'experimental';
  $vendor //= "comware";

  given ($vendor) {
    when (/ios|cisco/i) {
      return "Net::Connector::Cisco::Ios";
    }
    when (/h3c|comware/i) {
      return "Net::Connector::H3c::Comware";
    }
    when (/juniper|junos/i) {
      return "Net::Connector::Juniper::Srx";
    }
    when (/paloalto|panos/i) {
      return "Net::Connector::Paloalto::Firewall";
    }
    when (/hillstone|stoneos/i) {
      return "Net::Connector::Hillstone::Firewall";
    }
    when (/radware|stoneos/i) {
      return "Net::Connector::Radware::LoadBalance";
    }
    when (/nxos|nx-os/i) {
      return "Net::Connector::Cisco::Nxos";
    }
    when (/wlc/i) {
      return "Net::Connector::Cisco::Wlc";
    }
    default {
      return "Net::Connector::H3c::Comware";
    }
  }
}

#------------------------------------------------------------------------------
# 对象构造后的钩子函数，修正数据
#------------------------------------------------------------------------------
sub BUILD {
  my $self = shift;
  # 设置enPrompt缺省值: $self->prompt
  $self->setEnPrompt( $self->prompt ) unless $self->hasEnPrompt;
}

1;
