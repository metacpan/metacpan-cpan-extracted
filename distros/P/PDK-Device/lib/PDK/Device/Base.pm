package PDK::Device::Base;

use v5.30;
use Moose::Role;
use Carp qw(croak);
use Expect;
use namespace::autoclean;

requires 'errCodes';
requires 'waitfor';
requires 'getConfig';

has host => (is => 'ro', isa => 'Str', required => 1,);

has port => (is => 'ro', isa => 'Int', required => 0,);

has proto => (is => 'ro', isa => 'Str', default => 'ssh',);

has prompt => (is => 'ro', required => 0, default => '\S+[#>\]]\s*$',);

has enPrompt => (is => 'ro', required => 0,);

has enCommand => (is => 'ro', required => 0,);

has username => (is => 'ro', required => 0,);

has password => (is => 'ro', required => 0,);

has enPassword => (is => 'ro', required => 0,);

has passphrase => (is => 'ro', required => 0,);

has mode => (is => 'ro', default => 'normal',);

has catchError => (is => 'ro', default => 1,);

has enabled => (is => 'rw', default => 0,);

has status => (is => 'rw', default => 0,);

has month => (
  is      => 'ro',
  default => sub {
    my $month = `date +%Y-%m`;
    chomp($month);
    return $month;
  },
);

has date => (
  is      => 'ro',
  default => sub {
    my $date = `date +%Y-%m-%d`;
    chomp($date);
    return $date;
  },
);

has workdir => (is => 'rw', default => sub { $ENV{PDK_DEVICE_CONFIG_HOME} // glob("~") },);

has debug => (is => 'rw', default => 0,);

sub now {
  shift;
  my $now = `date "+%Y-%m-%d %H:%M:%S"`;
  chomp($now);
  return $now;
}

sub login {
  my $self = shift;

  if ($self->{status} == 1) {
    $self->dump("已经登录设备 $self->{host}，无需再次登录");
    return {success => 1};
  }

  eval {
    if (!$self->{exp}) {
      $self->dump("正在初始化 Expect 对象并登录设备 $self->{host}");
      $self->connect();
    }
    else {
      croak "执行[login/尝试连接设备]，连接 $self->{host} 异常: 已经初始化 Expect 对象，无法再次初始化";
    }
  };

  if (!!$@) {
    chomp($@);

    if ($@ =~ /RSA modulus too small/mi) {
      eval { $self->connect('-v -1'); };
    }
    elsif ($@ =~ /Selected cipher type <unknown> not supported by server/mi) {
      eval { $self->connect('-c des'); };
    }
    elsif ($@ =~ /no matching key exchange method found./mi) {
      eval { $self->connect('-c des'); };
    }
    elsif ($@ =~ /Connection refused/mi) {
      $self->dump("SSH会话($self->{host})异常, 尝试（仅支持默认端口自动切换）切换 [telnet] 登录");
      eval {
        $self->{proto} = 'telnet';
        $self->connect();
      };
    }
    elsif ($@ =~ /IDENTIFICATION CHANGED/mi) {
      $self->dump("尝试刷新SSH密钥-> /usr/bin/ssh-keygen -R $self->{host}");
      system("/usr/bin/ssh-keygen -R $self->{host}");
      eval { $self->connect(); };
    }

    if (!!$@) {
      chomp($@);
      return {success => 0, reason => $@};
    }
  }

  $self->dump("成功登录网络设备 $self->{host}");
  return {success => 1};
}

sub connect {
  my ($self, $args) = @_;

  $args //= "";

  my $username = $self->{username};
  my $password = $self->{password};
  my $debug    = $self->{debug};
  my $prompt   = $self->{prompt};
  my $enPrompt = $self->{enPrompt};

  if ($debug == 0 && $ENV{PDK_DEVICE_DEBUG}) {
    $self->{debug} = $debug = $ENV{PDK_DEVICE_DEBUG};
    $self->dump("从环境变量中加载并设置调试级别：($ENV{PDK_DEVICE_DEBUG})");
  }

  unless (!!$username) {
    $self->dump("从环境变量中加载并设置用户名：($ENV{PDK_DEVICE_USERNAME})");
    $self->{username} = $username = $ENV{PDK_DEVICE_USERNAME};
  }

  unless (!!$password) {
    $self->dump("从环境变量中加载并设置密码：($ENV{PDK_DEVICE_PASSWORD})");
    $self->{password} = $password = $ENV{PDK_DEVICE_PASSWORD};
  }

  croak("请正确提供设备登录所需账户密码凭证，或设置对象的环境变量:PDK_DEVICE_USERNAME, PDK_DEVICE_PASSWORD") unless $username && $password;

  my $passphrase = $self->{passphrase};
  unless (!!$passphrase) {
    if ($ENV{PDK_DEVICE_PASSPHRASE}) {
      $self->dump("从环境变量中加载并设置密钥：($ENV{PDK_DEVICE_PASSPHRASE})");
      $self->{passphrase} = $passphrase = $ENV{PDK_DEVICE_PASSPHRASE};
    }
  }

  my $exp = Expect->new();
  $exp->raw_pty(1);
  $exp->restart_timeout_upon_receive(1);
  $exp->debug(0);
  $exp->log_stdout(0);

  $self->{exp} = $exp;

  $self->_debug($debug) if !!$debug;

  my $command = $self->_spawn_command($args);

  $exp->spawn($command) or croak "执行[connect/启动脚本阶段]，Can't spawn $command: $!";
  $self->dump("正在发起脚本执行：$command");

  my @ret = $exp->expect(
    30,
    [
      qr/Enter passphrase for key/i => sub {
        $self->send($passphrase ? "$passphrase\r" : "\r");
        exp_continue;
      }
    ],
    [
      qr/to continue connect/i => sub {
        $self->send("yes\r");
        exp_continue;
      }
    ],
    [
      qr/assword:\s*$/i => sub {
        $self->send("$password\r");
      }
    ],
    [
      qr/(name|ogin|user):\s*$/i => sub {
        $self->send("$username\r");
        exp_continue;
      }
    ],
    [
      qr/REMOTE HOST IDENTIFICATION HAS CHANGED!/mi => sub {
        croak("IDENTIFICATION CHANGED!");
      }
    ],
    [
      eof => sub {
        croak("执行[connect/尝试登录设备阶段]，与设备 $self->{host} 会话丢失，连接被意外关闭！具体原因：\n" . $exp->before());
      }
    ],
    [
      timeout => sub {
        croak("执行[connect/尝试登录设备阶段]，与设备 $self->{host} 会话超时，请检查网络连接或服务器状态！具体原因：\n" . $exp->before());
      }
    ]
  );

  croak($ret[3]) if defined $ret[1];

  @ret = $exp->expect(
    15,
    [
      qr/sername|assword:\s*$/i => sub {
        $self->{status} = -1;
        croak("username or password is wrong!");
      }
    ],
    [
      qr/$prompt/mi => sub {
        $self->{status} = 1;
      }
    ],
    [
      eof => sub {
        croak("执行[connect/验证登录状态]，与设备 $self->{host} 会话丢失，连接被意外关闭！具体原因：\n" . $exp->before());
      }
    ],
    [
      timeout => sub {
        croak("执行[connect/验证登录状态]，与设备 $self->{host} 会话超时，请检查网络连接或服务器状态！具体原因：\n" . $exp->before());
      }
    ]
  );

  croak($ret[3]) if defined $ret[1];

  if ($enPrompt && $exp->match() =~ /$enPrompt/mi) {
    eval { $self->{enabled} = $self->enable(); };
    croak "username or enPassword is wrong!" if $@ || $self->{enabled} == 0;
  }

  return $self->{status};
}

sub send {
  my ($self, $command) = @_;

  my $exp = $self->{exp};

  if ($self->{debug} == 1) {
    my $cmd = $command;
    if ($cmd eq ' {1,}') {
      $cmd = '空格';
    }
    elsif ($cmd =~ /^(\r|\n|\r\n)$/i) {
      $cmd = '回车';
    }
    else {
      chomp($cmd);
      $cmd =~ s/(\r|n|\r\n)//g;
    }
    $self->dump("正在下发脚本：($cmd)");
  }

  $exp->send($command);
}

sub enable {
  my $self = shift;

  my $username  = $self->{username};
  my $enPasswd  = $self->{enPassword};
  my $enCommand = $self->{enCommand};
  my $prompt    = $self->{prompt};

  $enPasswd ||= $ENV{PDK_DEVICE_ENPASSWORD} || $self->{password};

  my $exp = $self->{exp};
  $self->dump("尝试切换到特权模式");

  $self->send("$enCommand\n");

  my @ret = $exp->expect(
    15,
    [
      qr/assword:\s*$/i => sub {
        $self->send("$enPasswd\n");
      }
    ],
    [
      qr/(ername|ogin|user):\s*$/i => sub {
        $self->send("$username\n");
        exp_continue;
      }
    ],
    [
      eof => sub {
        croak("执行[enable/尝试切换特权模式]，与设备 $self->{host} 会话丢失，连接被意外关闭！具体原因：\n" . $exp->before());
      }
    ],
    [
      timeout => sub {
        croak("执行[enable/尝试切换特权模式]，与设备 $self->{host} 会话超时，请检查网络连接或服务器状态！具体原因：\n" . $exp->before());
      }
    ],
  );

  return 0 if defined $ret[1];

  @ret = $exp->expect(
    15,
    [
      qr/sername|assword:\s*$/i => sub {
        $self->{enabled} = -1;
        croak("username or enPassword is wrong!");
      }
    ],
    [
      qr/(\^|Bad secrets|Permission denied|invalid)/i => sub {
        $self->{enabled} = -1;
        croak("username or enPassword is wrong!");
      }
    ],
    [
      qr/$prompt/mi => sub {
        $self->{enabled} = 1;
      }
    ],
    [
      eof => sub {

        croak("执行[enable/检查是否成功切换特权模式]，与设备 $self->{host} 会话丢失，连接被意外关闭！具体原因：\n" . $exp->before());
      }
    ],
    [
      timeout => sub {
        croak("执行[enable/检查是否成功切换特权模式]，与设备 $self->{host} 会话超时，请检查网络连接或服务器状态！具体原因：\n" . $exp->before());
      }
    ],
  );

  return 0 if defined $ret[1];

  $self->dump("成功切换到特权模式");
  return $self->{enabled};
}

sub execCommands {
  my ($self, $commands) = @_;

  if (not defined $self->{exp} and $self->{status} == 0) {
    $self->dump("执行[execCommands/未登录设备]，尝试自动登录设备中");
    my $login = $self->login();
    if ($login->{success} == 0) {
      my $snapshot = "执行[execCommands/自动登录设备]，尝试（首次）登录设备失败";
      if (my $exp = $self->{exp}) {
        $snapshot .= $exp->before;
      }
      return {success => 0, failCommand => join(", ", @{$commands}), snapshot => $snapshot, reason => $login->{reason}};
    }
  }
  elsif ($self->{exp} and $self->{status} == -1) {
    $self->dump("执行[execCommands/自动登录设备]，尝试（非首次）登录设备失败");
    my $exp      = $self->{exp};
    my $snapshot = '';
    if ($exp = $self->{exp}) {
      $snapshot .= $exp->before;
    }
    my $reason = "执行[execCommands/自动登录设备]，尝试（非首次）登录设备失败。";
    return {success => 0, failCommand => join(", ", @{$commands}), snapshot => $snapshot, reason => $reason};
  }

  my $result = $self->{exp} ? join('', grep defined $self->{exp}->match, $self->{exp}->after) : '';
  my $errors = $self->errCodes();

  if (exists $ENV{PDK_DEVICE_CATCH_ERROR} and $ENV{PDK_DEVICE_CATCH_ERROR} =~ /^\d+$/) {
    $self->{catchError} = ($ENV{PDK_DEVICE_CATCH_ERROR} == 1) ? 1 : 0;
  }

  $self->dump("执行[execCommands/通过前置检查]，正式进入配置下发阶段");
  for my $cmd (@{$commands}) {
    next if $cmd =~ /^\s*$/;
    next if $cmd =~ /^[#!;]/;

    my $buff = "";

    $self->send("$cmd\n");
    eval {
      $self->dump("等待脚本指令 $cmd 回显");
      $buff = $self->waitfor();
    };

    if (!!$@) {
      chomp($@);
      my $snapshot = $result . $buff;
      my $reason   = "执行[execCommands/等待脚本回显]，捕捉到异常: \n" . $@;
      return {success => 0, failCommand => $cmd, reason => $reason, snapshot => $snapshot};
    }

    if ($self->{catchError} == 1) {
      for my $error (@{$errors}) {
        if ($buff =~ /$error/i) {
          my $snapshot = "执行[execCommands/异常码字典拦截]，捕捉到异常: \n" . $result . $buff;
          return {success => 0, failCommand => $cmd, reason => $error, snapshot => $snapshot};
        }
      }
    }

    $result .= $buff;
  }

  return {success => 1, result => $result};
}

sub dump {
  my ($self, $msg) = @_;

  $msg .= ';' unless $msg =~ /(,|，|！|!|。|.)$/;

  if ($self->{debug} == 1) {
    say "[debug] $msg";
  }
  elsif ($self->{debug} > 1) {
    my $workdir = "$self->{workdir}/dump/$self->{month}/$self->{date}";

    use File::Path qw(make_path);
    make_path($workdir) unless -d $workdir;

    my $filename = "$workdir/$self->{host}.txt";

    open(my $fh, '>>', $filename) or croak "无法打开文件 $filename 进行写入: $!";
    my $text = $self->now() . " - [debug] $msg\n";
    print $fh $text or croak "写入文件 $filename 失败: $!";
    close($fh)      or croak "关闭文件句柄 $filename 失败: $!";
  }
}

sub write_file {
  my ($self, $config, $name) = @_;

  croak("必须提供非空配置信息") unless !!$config;

  $name //= $self->{host} . ".cfg";

  my $workdir = "$self->{workdir}/$self->{month}/$self->{date}";
  use File::Path qw(make_path);
  make_path($workdir) unless -d $workdir;

  $self->dump("准备将配置文件写入工作目录: ($workdir)");

  my $filename = "$workdir/$name";

  open(my $fh, '>', $filename) or croak "无法打开文件 $filename 进行写入: $!";
  print $fh $config            or croak "写入文件 $filename 失败: $!";
  close($fh)                   or croak "关闭文件句柄 $filename 失败: $!";

  $self->dump("已将配置文件写入文本文件: $filename");

  return {success => 1};
}

sub _spawn_command {
  my ($self, $args) = @_;

  my $user  = $self->{username};
  my $host  = $self->{host};
  my $port  = $self->{port};
  my $proto = $self->{proto};

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

  $self->dump("已生成登录设备的脚本: $command");

  return $command;
}

sub _debug {
  my ($self, $level) = @_;

  $level //= 1;
  $level = 3 if $level > 3;

  my $workdir = "$self->{workdir}/debug/$self->{month}/$self->{date}";
  use File::Path qw(make_path);
  make_path($workdir) unless -d $workdir;

  my $exp = $self->{exp};

  if ($level == 2) {
    $self->dump("当前 debug 级别将打开日志记录功能，并同步脚本执行回显到控制台");
    $exp->log_stdout(1);
  }
  elsif ($level == 3) {
    $self->dump("当前 debug 级别将打开日志记录功能，观察更详细的 Expect 信息");
    $exp->log_stdout(1);
    $exp->debug($level);
  }

  $exp->log_file("$workdir/$self->{host}.log");
}

1;
