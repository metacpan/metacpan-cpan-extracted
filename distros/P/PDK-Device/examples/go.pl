#!/usr/bin/perl

use strict;
use warnings;
use v5.30;

use Expect;
use Carp  qw(croak);
use POSIX qw(strftime);
use namespace::autoclean;

my $ip = shift @ARGV or die "脚本使用说明: $0 <IP>，必须提供需要登录的IP地址";

my $username   = 'admin';
my $password   = 'Cisc0123';
my $enPassword = 'Cisco';
my $enCommand  = 'enable';

my $prompt   = qr/^\s*\S+[>#\]]\s*$/mi;
my $enPrompt = qr/^\s*\S+[>]\s*$/mi;

my $timeout = 30;
my $debug   = 0;
my $workdir = $ENV{PDK_CONFIG_HOME} // glob("~");
my $date    = do { my $dt = `date +%Y-%m-%d`; chomp($dt); $dt; };

my $exp     = '';
my $enabled = 0;
my $status  = 0;

sub slogan {
  say '-' x 80;
  say "\n玩命加载任务，正在登陆 ($ip)，请稍等 ...\n";
  say '-' x 80;
}

sub login {
  my $ret;

  eval { $ret = &connect(); };

  if (!!$@) {
    chomp($@);

    if ($@ =~ /RSA modulus too small/mi) {
      eval { $ret = &connect({args => '-o KexAlgorithms=+diffie-hellman-group1-sha1'}); };
    }
    elsif ($@ =~ /Selected cipher type <unknown> not supported by server/mi) {
      eval { $ret = &connect({args => '-c aes128-cbc'}); };
    }
    elsif ($@ =~ /no matching key exchange method found/mi) {
      eval { $ret = &connect({args => '-o KexAlgorithms=+diffie-hellman-group1-sha1'}); };
    }
    elsif ($@ =~ /Connection refused/mi) {
      &dump("SSH 会话 ($ip) 失败，尝试切换到 [telnet] 登录（仅支持默认端口）！");
      eval { $ret = &connect({proto => 'telnet'}); };
    }
    elsif ($@ =~ /IDENTIFICATION CHANGED/mi) {
      &dump("尝试刷新 SSH 密钥 -> /usr/bin/ssh-keygen -R $ip");
      system("/usr/bin/ssh-keygen -R $ip");
      eval { $ret = &connect({}); };
    }

    if (!!$@) {
      chomp($@);
      return {success => 0, reason => $@};
    }
  }

  $exp = $ret;
  return {success => 1, exp => $exp};
}

sub connect {
  my ($params) = @_;
  $params //= {};
  my $proto = $params->{proto} // "ssh";
  my $args  = $params->{args}  // '';

  my $cmd = "$proto $args -l $username $ip";
  &dump("正在调用 connect() 方法并启动脚本：$cmd");
  $exp = Expect->spawn($cmd) or die "无法启动 $cmd: $!";

  $exp->raw_pty(1);
  $exp->restart_timeout_upon_receive(1);
  $exp->debug(0);
  $exp->log_stdout(0);

  if ($debug == 1 || $ENV{PDK_DEBUG} == 1) {
    $exp->log_stdout(1);
  }
  elsif ($debug == 2 || $ENV{PDK_DEBUG} == 2) {
    my $dir = "$workdir/$date";
    use File::Path qw(make_path);
    make_path($dir) unless -d $dir;
    $exp->log_file("$dir/$ip.log");
  }
  elsif ($debug == 3 || $ENV{PDK_DEBUG} == 3) {
    $exp->debug(3);
  }

  my @ret = $exp->expect(
    $timeout,
    [
      qr/REMOTE HOST IDENTIFICATION HAS CHANGED/i => sub {
        croak("IDENTIFICATION CHANGED");
      }
    ],
    [
      qr/(?:yes\/no|fingerprint)/i => sub {
        &send("yes\r");
        exp_continue;
      }
    ],
    [
      qr/(?:sername|login)/i => sub {
        &send("$username\r");
        exp_continue;
      }
    ],
    [
      qr/assword/i => sub {
        &send("$password\r");
      }
    ],
    [
      eof => sub {
        croak("执行[connect/尝试登录设备]，与设备 $ip 会话丢失，连接被意外关闭！具体原因：\n" . $exp->before());
      }
    ],
    [
      timeout => sub {
        croak("执行[connect/尝试登录设备]，与设备 $ip 会话超时，请检查网络连接或服务器状态！具体原因：\n" . $exp->before());
      }
    ]
  );

  if ($ret[1]) {
    &dump("调用 connect() 方法/[尝试登录设备]，expect 函数捕捉异常");
    croak $ret[3];
  }

  @ret = $exp->expect(
    10,
    [
      qr/sername|assword:\s*$/i => sub {
        $status = -1;
        croak("username or password is wrong!");
      }
    ],
    [
      qr/$prompt/mi => sub {
        $status = 1;
      }
    ],
    [
      eof => sub {
        croak("执行[connect/验证登录状态]，与设备 $ip 会话丢失，连接被意外关闭！具体原因：\n" . $exp->before());
      }
    ],
    [
      timeout => sub {
        croak("执行[connect/验证登录状态]，与设备 $ip 会话超时，请检查网络连接或服务器状态！具体原因：\n" . $exp->before());
      }
    ]
  );

  if ($enPrompt && $exp->match() =~ /$enPrompt/i) {
    eval { $enabled = &enable(); };
    if ($@ || $enabled == 0) {
      croak "username or enPassword is wrong!";
    }
  }

  return $exp;
}

sub enable {
  $enPassword ||= $ENV{PDK_SSH_ENPASSWORD} || $password;

  &dump("执行切换高权模式");

  &send("$enCommand\n");

  my @ret = $exp->expect(
    10,
    [
      qr/assword:\s*$/i => sub {
        &send("$enPassword\n");
      }
    ],
    [
      qr/(ername|ogin|user):\s*$/i => sub {
        &send("$username\n");
        exp_continue;
      }
    ],
    [
      eof => sub {
        croak("执行[enable/尝试切换特权模式]，与设备 $ip 会话丢失，连接被意外关闭！具体原因：\n" . $exp->before());
      }
    ],
    [
      timeout => sub {
        croak("执行[enable/尝试切换特权模式]，与设备 $ip 会话超时，请检查网络连接或服务器状态！具体原因：\n" . $exp->before());
      }
    ],
  );

  if (defined $ret[1]) {
    &dump("切换高权模式失败");
    return 0;
  }

  @ret = $exp->expect(
    10,
    [
      qr/sername|assword:\s*$/i => sub {
        $enabled = -1;
        croak("username or enPassword is wrong!");
      }
    ],
    [
      qr/(\^|Bad secrets|Permission denied|invalid)/i => sub {
        $enabled = -1;
        croak("username or enPassword is wrong!");
      }
    ],
    [
      qr/$prompt/mi => sub {
        $enabled = 1;
      }
    ],
    [
      eof => sub {
        croak("执行[enable/检查是否成功切换特权模式]，与设备 $ip 会话丢失，连接被意外关闭！具体原因：\n" . $exp->before());
      }
    ],
    [
      timeout => sub {
        croak("执行[enable/检查是否成功切换特权模式]，与设备 $ip 会话超时，请检查网络连接或服务器状态！具体原因：\n" . $exp->before());
      }
    ],
  );

  &dump("成功切换到特权模式");
  return $enabled;
}

sub dump {
  my ($msg) = @_;
  if ($ENV{PDK_DEBUG} == 2) {
    my $content = "[debug] " . &now . " $msg ;";
    say $content;
  }
}

sub send {
  my $cmd = shift;

  die "执行send下发脚本异常，请检查是否成功初始化 Expect 对象" unless !!$exp;

  my $cli = $cmd;
  if ($cli eq ' ') {
    &dump("正在下发脚本: (空格)");
  }
  elsif ($cli =~ /^(\r|\n)$/) {
    &dump("正在下发脚本: (回车)");
  }
  else {
    $cli =~ s/\r|\n|(\r\n)//g;
    &dump("正在下发脚本: ($cli)");
  }
  $exp->send($cmd);
}

sub now {
  my ($sec, $min, $hour, $mday, $mon, $year) = localtime;
  $mon++;
  $year += 1900;
  return sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday, $hour, $min, $sec);
}

eval {
  slogan();
  my $login = login();

  if ($login->{success}) {
    &dump("成功登录设备：$ip");

    &send("\n");
    $login->{exp}->interact();
  }
  else {
    die "登录失败: " . $login->{reason};
  }
};

die "脚本执行异常，请联系管理员检查原因" if !!$@;
