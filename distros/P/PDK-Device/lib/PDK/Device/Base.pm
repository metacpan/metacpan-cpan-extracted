package PDK::Device::Base;

use v5.30;
use strict;
use warnings;

use Moose::Role;
use Carp qw'croak';
use Expect;
use namespace::autoclean;


requires 'errCodes';
requires 'waitfor';
requires 'getConfig';

has exp => (is => 'ro', required => 0,);

has host => (is => 'ro', required => 0,);

has port => (is => 'ro', required => 0, default => '',);

has proto => (is => 'ro', required => 0, default => 'ssh',);

has prompt => (is => 'ro', required => 1, default => '\S+[#>]\s*\z',);

has enPrompt => (is => 'ro', required => 0, default => '',);

has enCommand => (is => 'ro', required => 0, default => '',);

has username => (is => 'ro', required => 0, default => '',);

has password => (is => 'ro', required => 0, default => '',);

has enPassword => (is => 'ro', required => 0,);

has passphrase => (is => 'ro', required => 0, default => '',);

has mode => (is => 'ro', required => 0, default => 'normal',);

has catchError => (is => 'ro', required => 0, default => 1,);

has enabled => (is => 'rw', required => 0, default => 0,);

has status => (is => 'rw', required => 0, default => 0,);

has month => (
  is       => 'rw',
  required => 0,
  default  => sub {
    my $month = `date +%Y-%m`;
    chomp($month);
    return $month;
  },
);

has date => (
  is       => 'rw',
  required => 0,
  default  => sub {
    my $date = `date +%Y-%m-%d`;
    chomp($date);
    return $date;
  },
);

has workdir => (
  is       => 'rw',
  required => 0,

  default => sub { $ENV{PDK_CONFIG_HOME} // glob("~") },
);

has debug => (is => 'rw', required => 0, default => 0,);


sub login {
  my $self = shift;

  return {success => 1} if $self->{status} == 1;

  eval {
    if (!$self->{exp}) {
      say "[debug] 正在初始化 Expect 对象并登录设备 $self->{host} !" if $self->{debug};
      $self->connect();
    }
    else {
      croak "执行[login/尝试连接设备]，连接 $self->{host} 异常: 已经初始化 Expect 对象，无法再次初始化！";
    }
  };

  if ($@) {
    chomp($@);

    if ($@ =~ /RSA modulus too small/mi) {
      eval { $self->connect('-v -1'); };
      if ($@) {
        chomp($@);
        return {success => 0, reason => $@};
      }
    }
    elsif ($@ =~ /Selected cipher type <unknown> not supported by server/mi) {
      eval { $self->connect('-c des'); };
      if ($@) {
        chomp($@);
        return {success => 0, reason => $@};
      }
    }
    elsif ($@ =~ /no matching key exchange method found./mi) {
      eval { $self->connect('-c des'); };
      if ($@) {
        chomp($@);
        return {success => 0, reason => $@};
      }
    }
    elsif ($@ =~ /Connection refused/mi) {
      if ($self->{debug}) {
        say "[debug] SSH会话($self->{host})异常, 尝试（仅支持默认端口自动切换）切换 [telnet] 登录！";
      }
      eval {
        $self->{proto} = 'telnet';
        $self->connect();
      };
      if ($@) {
        chomp($@);
        return {success => 0, reason => $@};
      }
    }
    elsif ($@ =~ /IDENTIFICATION CHANGED/mi) {
      if ($self->{debug}) {
        my $msg = "捕捉到异常：" . $@;
        say "[debug] 尝试刷新SSH密钥-> /usr/bin/ssh-keygen -R $self->{host} , $msg";
      }

      system("/usr/bin/ssh-keygen -R $self->{host}");
      eval { $self->connect(); };
      if ($@) {
        chomp($@);
        return {success => 0, reason => $@};
      }
    }
    else {
      return {success => 0, reason => $@};
    }
  }

  say "\n[debug] 成功登录网络设备 $self->{host};" if $self->{debug};

  return {success => 1};
}

sub connect {
  my ($self, $args) = @_;

  $args //= "";

  my $username = $self->{username} || $ENV{PDK_USERNAME};
  my $password = $self->{password} || $ENV{PDK_PASSWORD};
  my $debug    = $self->{debug};
  my $prompt   = $self->{prompt};
  my $enPrompt = $self->{enPrompt};

  croak("请正确提供设备登录所需账户密码凭证，或设置对象的环境变量！") unless $username && $password;

  $debug = $ENV{PDK_DEBUG} if $debug == 0 && $ENV{PDK_DEBUG};

  my $exp = Expect->new();
  $exp->raw_pty(1);
  $exp->restart_timeout_upon_receive(1);
  $exp->debug(0);
  $exp->log_stdout(0);

  $self->{exp} = $exp;

  if ($debug) {
    if ($debug == 3) {

      $self->{username} = $username if $username ne $self->{username};
      $self->{username} = $username if $username ne $self->{username};
    }

    $self->{debug} = $debug if $debug ne $self->{debug};

    $self->_debug($debug);
  }

  my $command = $self->_spawn_command($args);

  $exp->spawn($command) or croak "执行[connect/连接脚本准备阶段]，Cannot spawn $command: $!";

  my @ret = $exp->expect(
    15,
    [
      qr/to continue conne/mi => sub {
        $exp->send("yes\n");
        exp_continue;
      }
    ],
    [
      qr/assword:\s*$/mi => sub {
        $exp->send("$password\n");
      }
    ],
    [
      qr/(name|ogin|user):\s*$/mi => sub {
        $exp->send("$username\n");
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
    10,
    [
      qr/sername|assword:\s*$/mi => sub {
        $self->{status} = -1;
        croak("username or password is wrong!");
      }
    ],
    [
      qr/$prompt/m => sub {
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

  if ($enPrompt && $exp->match() =~ /$enPrompt/m) {
    say "\n[debug] 尝试切换到特权模式;" if $self->{debug};

    eval { $self->{enabled} = $self->enable(); };
    if ($@ || $self->{enabled} == 0) {
      croak "username or enPassword is wrong!";
    }
  }

  return $self->{status};
}

sub send {
  my ($self, $command) = @_;

  my $exp = $self->{exp};

  if ($self->{debug}) {
    my $cmd = $command;
    chomp($cmd);
    say "\n[debug] send command: ($cmd);";
  }

  $exp->send($command);
}

sub enable {
  my $self = shift;

  my $username  = $self->{username};
  my $enPasswd  = $self->{enPassword};
  my $enCommand = $self->{enCommand};
  my $prompt    = $self->{prompt};

  $enPasswd ||= $ENV{PDK_ENPASSWORD} || $self->{password};

  my $exp = $self->{exp};
  $exp->send("$enCommand\n");

  my @ret = $exp->expect(
    10,
    [
      qr/assword:\s*$/mi => sub {
        $exp->send("$enPasswd\n");
      }
    ],
    [
      qr/(ername|ogin|user):\s*$/mi => sub {
        $exp->send("$username\n");
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
    10,
    [
      qr/sername|assword:\s*$/mi => sub {
        $self->{enabled} = -1;
        croak("username or enPassword is wrong!");
      }
    ],
    [
      qr/(\^|Bad secrets|Permission denied|invalid)/mi => sub {
        $self->{enabled} = -1;
        croak("username or enPassword is wrong!");
      }
    ],
    [
      qr/$prompt/m => sub {
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

  return $self->{enabled};
}

sub execCommands {
  my ($self, $commands) = @_;

  if (not defined $self->{exp} and $self->{status} == 0) {
    my $login = $self->login();
    if ($login->{success} == 0) {
      my $snapshot = "执行[execCommands/下发配置前自动登录设备]，尝试（首次）登录设备失败。";
      if (my $exp = $self->{exp}) {
        $snapshot .= "，相关异常：\n" . $exp->before() . $exp->match() . $exp->after();
      }
      return {success => 0, failCommand => join(", ", @{$commands}), snapshot => $snapshot, reason => $login->{reason}};
    }
  }
  elsif ($self->{exp} and $self->{status} == -1) {
    my $exp      = $self->{exp};
    my $snapshot = "先前捕捉到的交互信息：" . $exp->before() . $exp->match() . $exp->after();
    my $reason   = "执行[execCommands/下发配置前自动登录设备]，尝试（非首次）登录设备失败。";
    return {success => 0, failCommand => join(", ", @{$commands}), snapshot => $snapshot, reason => $reason};
  }

  my $result = $self->{exp} ? $self->{exp}->match() . $self->{exp}->after() : "";
  my $errors = $self->errCodes();

  if ($ENV{PDK_CATCH_ERROR} =~ /^\d+$/) {

    $self->{catchError} = ($ENV{PDK_CATCH_ERROR} == 1) ? 1 : 0;
  }

  for my $cmd (@{$commands}) {

    next if $cmd =~ /^\s*$/;
    next if $cmd =~ /^[#!;]/;

    my $buff = "";

    $self->send("$cmd\n");
    eval { $buff = $self->waitfor(); };

    if ($@) {
      chomp($@);
      my $snapshot = $result . $buff;
      my $reason   = "执行[execCommands/等待脚本回显自动交互]，捕捉到异常: \n" . $@;
      return {success => 0, failCommand => $cmd, reason => $reason, snapshot => $snapshot};
    }

    if ($self->{catchError}) {
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

sub write_file {
  my ($self, $config, $name) = @_;

  croak("必须提供非空配置信息") unless $config;

  $name //= $self->{host} . ".cfg";

  my $workdir = "$self->{workdir}/$self->{month}/$self->{date}";

  if ($self->{debug}) {
    say "\n[debug] 准备将配置文件写入工作目录: ($workdir)";
  }

  use File::Path qw(make_path);
  make_path($workdir) unless -d $workdir;

  my $filename = "$workdir/$name";

  open(my $fh, '>', $filename) or croak "无法打开文件 $filename 进行写入: $!";
  print $fh $config            or croak "写入文件 $filename 失败: $!";
  close($fh)                   or croak "关闭文件句柄 $filename 失败: $!";

  if ($self->{debug}) {
    say "[debug] 已将配置文件写入文本文件: $filename !";
  }

  return {success => 1};
}

sub _spawn_command {
  my ($self, $args) = @_;

  my $user  = $self->{username};
  my $host  = $self->{host};
  my $port  = $self->{port};
  my $proto = $self->{proto};

  $user ||= $ENV{PDK_USERNAME};

  $args //= "";
  my $command;

  if ($port) {
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

  say "[debug] 已生成登录设备的脚本: $command" if $self->{debug};

  return $command;
}

sub _debug {
  my ($self, $level) = @_;

  $level //= 1;
  $level = 3 if $level > 3;

  my $workdir = "$self->{workdir}/debug/$self->{date}";

  use File::Path qw(make_path);
  make_path($workdir) unless -d $workdir;

  my $exp = $self->{exp};

  if ($level == 2) {
    say '[debug] 当前 debug 级别将打开日志记录功能，并同步脚本执行回显到控制台！';
    $exp->log_stdout(1);
  }
  elsif ($level == 3) {
    say '[debug] 当前 debug 级别将打开日志记录功能，观察更详细的 Expect 信息！';
    $exp->log_stdout(1);
    $exp->debug($level);
  }

  $exp->log_file("$workdir/$self->{host}.log");
}

1;
