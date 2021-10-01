package Netstack::Connector::Role;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use 5.016;
use utf8;
use Try::Tiny;
use Expect;
use Moose::Role;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 继承 Netstack::Connector::Role 必须实现的方法
#------------------------------------------------------------------------------
requires '_buildPrompt';
requires '_buildCommands';
requires '_buildErrorCode';
requires '_buildBufferCode';
requires 'runCommands';

#------------------------------------------------------------------------------
# 定义设备联结 Netstack::Connector::Role 方法属性
#------------------------------------------------------------------------------
has exp => (
  is      => 'ro',
  default => sub { Expect->new },
  # Expect 方法权限下放，该属性将代理响应
  handles => [ 'spawn', 'expect', 'interact' ]
);

has host => (
  is       => 'ro',
  required => 1,
);

has username => (
  is       => 'ro',
  required => 1,
  default  => 'read'
);

has password => (
  is       => 'ro',
  required => 1,
  default  => 'read',
);

has port => (
  is        => 'ro',
  default   => '22',
  predicate => 'hasPort'
);

# 缺省设置为 password
has enPassword => (
  is       => 'ro',
  required => 0
);

has proto => (
  is       => 'ro',
  required => 1,
  default  => 'ssh',
);

# 登录成功更新状态为 1
has status => (
  is      => 'ro',
  isa     => 'Int',
  default => 0,
  writer  => 'setStatus'
);

# 判断 enable 状态 还需要推敲
has enabled => (
  is      => 'ro',
  isa     => 'Int',
  writer  => 'setEnabled',
  default => 0
);

has prompt => (
  is       => 'ro',
  builder  => "_buildPrompt",
  required => 1
);

has enPrompt => (
  is        => 'ro',
  writer    => 'setEnablePrompt',
  predicate => 'definedEnablePrompt'
);

has commands => (
  is      => 'rw',
  isa     => 'ArrayRef[Str]',
  writer  => 'setCommands',
  traits  => ['Array'],
  handles => {
    addCommand  => 'unshift',
    pushCommand => 'push'
  }
);

has getEnableCommand => (
  is       => 'ro',
  isa      => 'Str',
  required => 0,
);

has getCommands => (
  is       => 'ro',
  isa      => 'ArrayRef',
  builder  => "_buildCommands",
  required => 1,
);

has timeout => (
  is      => 'ro',
  isa     => 'Int',
  default => 30,
  writer  => 'setTimeout'
);

# 命令行代码
has errorCode => (
  is      => 'ro',
  builder => '_buildErrorCode'
);

# 交互式执行脚本
has bufferCode => (
  is      => 'ro',
  builder => '_buildBufferCode'
);

#------------------------------------------------------------------------------
# login 设备登陆函数入口
#------------------------------------------------------------------------------
sub login {
  my $self = shift;

  # 检查是否已经登录过 | 边界条件检查
  return {success => 1} if $self->status == 1;

  # 尝试连接设备,支持异常重连机制
  try {
    # 需要等待这里执行完，才会跳转后面的代码
    $self->connect();
  }
  catch {
    if (/RSA modulus too small/mi) {
      try { $self->connect('-v -1 -c des ') }
      catch {
        return {
          success => 0,
          reason  => $_
        };
      }
    }
    elsif (/Selected cipher type <unknown> not supported/mi) {
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
    elsif (/IDENTIFICATION HAS CHANGED/mi) {
      try {
        system "/usr/bin/ssh-keygen -R $self->{host}";
        $self->connect;
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
# connect 设备联机登录
#------------------------------------------------------------------------------
sub connect {
  my ( $self, $args ) = @_;
  # 检查是否携带变量并初始化
  $args = defined $args ? $args : '';
  # # 检查是否携带端口信息
  $args . " -p $self->{port}" if $self->hasPort;

  # 初始化变量
  my $host     = $self->host;
  my $username = $self->username;
  my $password = $self->password;

  # 初始化 Expect 函数
  my $exp = $self->exp;
  $exp->raw_pty(1);
  $exp->debug(0);
  $exp->restart_timeout_upon_receive(1);

  # 是否打印日志，一般用于排错
  $exp->log_stdout(0);

  # 设置登录逻辑
  my $status  = 1;
  my $command = $self->proto . " $args" . " -l $username $host";
  # 尝试登录设备并执行异常拦截
  $self->spawn($command) || confess __PACKAGE__ . " case0) Cannot spawn $command: $!\n";

  # 登录期间交互式运行脚本
  my @ret = $self->expect(
    15,
    # 自动输入 yes
    [ qr/continue connecting \(yes\/no/mi => sub {
        $exp->send("yes\n");
        exp_continue;
      }
    ],
    # 自动输入密码,且仅输入一次
    [ qr/password:/mi => sub {
        if ( $status == 1 ) {
          $status = 0;
          $exp->send("$password\n");
        }
        else {
          confess __PACKAGE__ . " case1) 登录($self->{host})失败,请提供正确的账号密码;";
        }
        exp_continue;
      }
    ],
    # 自动输入账号 | 脚本已经绑定用户名
    [ qr/(ogin|name):\s*$/mi => sub {
        $exp->send("$username\n");
        exp_continue;
      }
    ],
    # 捕捉到脚本下发正常提示符
    [ $self->prompt => sub {
        $self->setStatus(1);
        # 缺省情况下 没有 enable 模式
        $self->setEnabled(1) unless $self->definedEnablePrompt;
      }
    ],
  );

  # Expect是否异常
  if ( defined $ret[1] ) {
    confess __PACKAGE__ . " case2) 登录节点($self->{host})期间捕捉到异常: $ret[3] . $ret[1]";
  }
}

#------------------------------------------------------------------------------
# send 设备发送指令入口函数，接收字符串
#------------------------------------------------------------------------------
sub send {
  my ( $self, $command ) = @_;
  # 执行脚本
  $self->exp->send($command);
}

#------------------------------------------------------------------------------
# 具体实现 waitfor，自动交互式执行脚本
#------------------------------------------------------------------------------
sub waitfor {
  my $self = shift;
  # 初始化变量
  my $buff = "";
  # 继承 exp 属性
  my $exp = $self->exp;

  # 初始化缓存代码
  my $codeARef = [];
  my $mapping  = $self->bufferCode;
  # 遍历字典
  while ( my ( $wait, $action ) = each $mapping->%* ) {
    push $codeARef->@*, [
      $wait => sub {
        $buff .= $exp->before . $exp->match;
        $exp->send($action);
        exp_continue;
      }
    ];
  }
  # 捕捉脚本正常下发回显
  push $codeARef->@*, [
    $self->{prompt} => sub {
      $buff .= $exp->before . $exp->match;
    }
  ];

  # 动态加载交互式代码
  my @ret = $exp->expect( 15, $codeARef->@* );
  # 异常捕捉
  if ( defined $ret[1] ) {
    confess __PACKAGE__ . " 节点($self->{host})脚本执行期间捕捉到异常：$ret[3] . $ret[1]";
  }

  # 字符串修正处理
  # $buff =~ s/\x1b\[\d+D\s+\x1b\[\d+D//g;
  # $buff =~ s/\r\n|\n+\n/\n/g;
  # $buff =~ s/^%.+$//mg;
  # $buff =~ s/^\s*$//mg;

  # 返回修正后的脚本
  return $buff;
}

#------------------------------------------------------------------------------
# getConfig 获取设备运行配置
#------------------------------------------------------------------------------
sub getConfig {
  my $self = shift;

  # 抓取设备命令脚本，输入不分页命令加速输出
  my $commands = $self->getCommands;
  my $ret      = $self->execCommands( $commands->@* );

  # 判断是否执行成功
  if ( $ret->{success} == 1 ) {
    return {
      success => 1,
      config  => $ret->{result}
    };
  }

  # 兜底的返回结果
  return {
    success => 0,
    config  => $ret
  };
}

#------------------------------------------------------------------------------
# execCommands 执行批量下发脚本
#------------------------------------------------------------------------------
sub execCommands {
  my ( $self, @commands ) = @_;

  # 判断是否已登陆设备
  if ( $self->status == 0 ) {
    $self->login;
    # 未成功登录设备，异常拦截
    if ( $self->status == 0 ) {
      return {
        success     => 0,
        failCommand => join( "\n", @commands ),
        reason      => "设备登录异常,无法下发配置"
      };
    }
    # 检查是否进入 enable 状态
    if ( $self->enabled == 0 ) {
      # 尝试进入 enable
      $self->enable;
      # 异常拦截
      return {
        success     => 0,
        failCommand => join( "\n", @commands ),
        reason      => "设备无法进入enable模式,无法下发配置"
      } if $self->enabled == 0;
    }
  }

  # 初始化 result 变量，并开始执行命令
  my $result = "";
  # 初始化 commands 属性
  $self->setCommands( \@commands );
  # 遍历接受到的命令行
  while ( $self->commands->@* ) {
    my $cmd = pop $self->commands->@*;
    # 自动跳过空白行
    next if $cmd =~ /^\s*$/;
    # 执行具体的脚本
    $self->send("$cmd\n");
    # 命令下发后需要等待返回输出
    my $buff = $self->waitfor;

    # 异常拦截，基于正则表达式判断是否匹配错误码
    foreach my $error ( $self->errorCode->@* ) {
      if ( $buff =~ /$error/ ) {
        return {
          success     => 0,
          failCommand => $cmd,
          reason      => $result . $buff
        };
      }
    }
    # 脚本执行正常,则拼接字符串
    $result .= $buff;
  }

  # 输出计算结果
  return {
    success => 1,
    result  => $result
  };
}

#------------------------------------------------------------------------------
# 定义设备 enable 方法
#------------------------------------------------------------------------------
sub enable {
  my $self = shift;
  # 早期状态拦截
  return if $self->enable == 1;
  # 异常拦截
  confess "请正确配置 enablePrompt，需要设置为正则表达式" unless $self->definedEnablePrompt;

  # 初始化变量
  my $username = $self->username;
  my $enPasswd = $self->enPassword // $self->password;
  my $exp      = $self->exp;

  # 判断需要进入 enable 后执行
  $exp->send( $self->getEnableCommand . "\n" );
  my $status = 1;
  my @ret    = $self->expect(
    15,
    [ qr/assword:\s*$/mi => sub {
        if ( $status == 1 ) {
          $status = 0;
          $exp->send("$enPasswd\n");
        }
        else {
          confess __PACKAGE__ . " case5) 请正确填写用户和enable password";
        }
        exp_continue;
      }
    ],
    [ qr/(ogin|name):\s*$/mi => sub {
        $exp->send("$username\n");
        exp_continue;
      }
    ],
    [ $self->enPrompt => sub {
        $self->setEnabled(1);
      }
    ]
  );

  # 异常回显信号捕捉
  if ( defined $ret[1] ) {
    confess __PACKAGE__ . " case6) 交互式提供enable密码期间报错：$ret[3] . $ret[1]";
  }
}

#------------------------------------------------------------------------------
# 定义 deploy 执行现有的命令行脚本
#------------------------------------------------------------------------------
sub deploy {
  my $self = shift;
  # 异常拦截 | 命令行为空直接返回
  return {
    success     => 0,
    failCommand => "not defined commands",
    reason      => "check defined command or not",
  } if scalar $self->commands->@* == 0;

  # 遍历已有的 commands
  return $self->execCommands($self->commands->@*);
}
1;
