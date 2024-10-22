#!/usr/bin/perl

use strict;
use warnings;
use v5.30;

use Expect;
use Carp qw(croak);
use POSIX qw(strftime);
use namespace::autoclean;

# 获取命令行参数，若没有提供IP地址，则退出脚本并给出使用说明
my $ip = shift @ARGV or die "脚本使用说明: $0 <IP>，必须提供需要登录的IP地址";

# 设置默认的登录凭据、特权模式密码和超时时间
my $username   = 'admin';
my $password   = 'Cisc0123';
my $enPassword = 'Cisco';
my $enCommand  = 'enable';

# 定义正常模式和增强模式的提示符
my $prompt     = qr/^\s*\S+[>#\]]\s*$/mi;   # 匹配结尾的普通提示符
my $enPrompt   = qr/^\s*\S+[>]\s*$/mi;      # 匹配特权模式前的提示符

# Expect 全局配置
my $timeout = 30;    # 超时时间，单位秒
my $debug   = 0;     # 调试模式标志
my $workdir = $ENV{PDK_CONFIG_HOME} // glob("~");  # 获取工作目录，默认用户主目录
my $date    = do { my $dt = `date +%Y-%m-%d`; chomp($dt); $dt; };  # 获取当前日期

# Expect 对象和状态变量初始化
my $exp      = '';  # Expect 对象
my $enabled  = 0;   # 是否进入特权模式的标志
my $status   = 0;   # 登录状态标志

# 打印登录提示信息
sub slogan {
  say '-' x 80;
  say "\n玩命加载任务，正在登陆 ($ip)，请稍等 ...\n";
  say '-' x 80;
}

# 尝试登录设备
sub login {
  my $ret;

  # 尝试使用 SSH 连接
  eval {
    $ret = &connect();
  };

  # 捕获异常并进行错误处理
  if (!!$@) {
    chomp($@);

    # 根据不同的错误信息，尝试使用不同的加密算法或切换到 Telnet 连接
    if ($@ =~ /RSA modulus too small/mi) {
      eval { $ret = &connect({ args => '-o KexAlgorithms=+diffie-hellman-group1-sha1' }); };
    }
    elsif ($@ =~ /Selected cipher type <unknown> not supported by server/mi) {
      eval { $ret = &connect({ args => '-c aes128-cbc' }); };
    }
    elsif ($@ =~ /no matching key exchange method found/mi) {
      eval { $ret = &connect({ args => '-o KexAlgorithms=+diffie-hellman-group1-sha1' }); };
    }
    elsif ($@ =~ /Connection refused/mi) {
      &dump("SSH 会话 ($ip) 失败，尝试切换到 [telnet] 登录（仅支持默认端口）！");
      eval { $ret = &connect({ proto => 'telnet' }); };
    }
    elsif ($@ =~ /IDENTIFICATION CHANGED/mi) {
      &dump("尝试刷新 SSH 密钥 -> /usr/bin/ssh-keygen -R $ip");
      system("/usr/bin/ssh-keygen -R $ip");
      eval { $ret = &connect({}); };
    }

    # 如果所有尝试都失败，返回错误信息
    if (!!$@) {
      chomp($@);
      return { success => 0, reason => $@ };
    }
  }

  # 如果成功，返回 Expect 对象
  $exp = $ret;
  return { success => 1, exp => $exp };
}

# 连接设备，支持 SSH 和 Telnet
sub connect {
  my ($params) = @_;
  $params //= {};
  my $proto = $params->{proto} // "ssh";  # 默认协议为 SSH
  my $args  = $params->{args}  // '';     # 默认没有附加参数

  my $cmd = "$proto $args -l $username $ip";
  &dump("正在调用 connect() 方法并启动脚本：$cmd");
  $exp = Expect->spawn($cmd) or die "无法启动 $cmd: $!";

  $exp->raw_pty(1);                       # 设置为原始伪终端模式
  $exp->restart_timeout_upon_receive(1);  # 每次收到输入时重启超时计时器
  $exp->debug(0);                         # 禁用调试输出
  $exp->log_stdout(0);                    # 禁用标准输出日志

  # 根据调试模式设置不同的日志选项
  if ($debug == 1 || $ENV{PDK_DEBUG} == 1) {
    $exp->log_stdout(1);  # 打印所有标准输出
  } elsif ($debug == 2 || $ENV{PDK_DEBUG} == 2) {
    my $dir = "$workdir/$date";
    # 创建日期目录（如果不存在）
    use File::Path qw(make_path);
    make_path($dir) unless -d $dir;
    $exp->log_file("$dir/$ip.log");  # 将日志保存到文件
  } elsif ($debug == 3 || $ENV{PDK_DEBUG} == 3) {
    $exp->debug(3);  # 设置最大调试信息输出
  }

  # 捕获 SSH 登录的各种交互情况并处理
  my @ret = $exp->expect($timeout,
    [ qr/REMOTE HOST IDENTIFICATION HAS CHANGED/i => sub {
      croak("IDENTIFICATION CHANGED");  # 处理 SSH 密钥改变的情况
    } ],
    [ qr/(?:yes\/no|fingerprint)/i => sub {
      &send("yes\r");  # 自动确认新的 SSH 密钥
      exp_continue;
    } ],
    [ qr/(?:sername|login)/i => sub {
      &send("$username\r");  # 输入用户名
      exp_continue;
    } ],
    [ qr/assword/i => sub {
      &send("$password\r");  # 输入密码
    } ],
    [ eof => sub {  # 处理意外的会话关闭
      croak("执行[connect/尝试登录设备]，与设备 $ip 会话丢失，连接被意外关闭！具体原因：\n" . $exp->before());
    } ],
    [ timeout => sub {  # 处理超时情况
      croak("执行[connect/尝试登录设备]，与设备 $ip 会话超时，请检查网络连接或服务器状态！具体原因：\n" . $exp->before());
    } ]
  );

  # 如果有异常，抛出错误
  if ($ret[1]) {
    &dump("调用 connect() 方法/[尝试登录设备]，expect 函数捕捉异常");
    croak $ret[3];
  }

  # 验证登录状态，确认是否匹配到设备提示符
  @ret = $exp->expect(10,
    [ qr/sername|assword:\s*$/i => sub {
      $status = -1;  # 登录失败
      croak("username or password is wrong!");  # 抛出错误
    } ],
    [ qr/$prompt/mi => sub {
      $status = 1;  # 登录成功
    } ],
    [ eof => sub {
      croak("执行[connect/验证登录状态]，与设备 $ip 会话丢失，连接被意外关闭！具体原因：\n" . $exp->before());
    } ],
    [ timeout => sub {
      croak("执行[connect/验证登录状态]，与设备 $ip 会话超时，请检查网络连接或服务器状态！具体原因：\n" . $exp->before());
    } ]
  );

  # 检查特权模式提示符并尝试切换到特权模式
  if ($enPrompt && $exp->match() =~ /$enPrompt/i) {
    eval {
      $enabled = &enable();
    };
    if ($@ || $enabled == 0) {
      croak "username or enPassword is wrong!";  # 切换特权模式失败
    }
  }

  return $exp;
}

# 切换到特权模式
sub enable {
  # 支持从环境变量加载特权密码，默认使用 $password
  $enPassword ||= $ENV{PDK_SSH_ENPASSWORD} || $password;

  &dump("执行切换高权模式");

  # 获取 Expect 对象，发送命令以切换到特权模式
  &send("$enCommand\n");

  # 处理输入密码的期望
  my @ret = $exp->expect(10,
    [ qr/assword:\s*$/i => sub {
      &send("$enPassword\n"); # 输入特权密码
    } ],
    [ qr/(ername|ogin|user):\s*$/i => sub {
      &send("$username\n"); # 输入用户名并继续监听
      exp_continue; # 继续处理下一个期望
    } ],
    [ eof => sub {
      # 会话意外关闭，抛出异常
      croak("执行[enable/尝试切换特权模式]，与设备 $ip 会话丢失，连接被意外关闭！具体原因：\n" . $exp->before());
    } ],
    [ timeout => sub {
      # 会话超时，抛出异常
      croak("执行[enable/尝试切换特权模式]，与设备 $ip 会话超时，请检查网络连接或服务器状态！具体原因：\n" . $exp->before());
    } ],
  );

  # 检查是否出现问题
  if (defined $ret[1]) {
    &dump("切换高权模式失败");
    return 0; # 返回失败
  }

  # 观察是否正常登录设备
  @ret = $exp->expect(10, # 设置等待时间为10秒
    [ qr/sername|assword:\s*$/i => sub {
      # 检测到用户名或密码提示
      $enabled = -1; # 登录失败，设置状态
      croak("username or enPassword is wrong!"); # 抛出错误
    } ],
    [ qr/(\^|Bad secrets|Permission denied|invalid)/i => sub {
      # 检测到错误提示
      $enabled = -1; # 登录失败，设置状态
      croak("username or enPassword is wrong!"); # 抛出错误
    } ],
    [ qr/$prompt/mi => sub {
      # 检测到预期的提示符，表示登录成功
      $enabled = 1; # 登录成功，设置状态
    } ],
    [ eof => sub {
      # 会话意外关闭，抛出异常
      croak("执行[enable/检查是否成功切换特权模式]，与设备 $ip 会话丢失，连接被意外关闭！具体原因：\n" . $exp->before());
    } ],
    [ timeout => sub {
      # 会话超时，抛出异常
      croak("执行[enable/检查是否成功切换特权模式]，与设备 $ip 会话超时，请检查网络连接或服务器状态！具体原因：\n" . $exp->before());
    } ],
  );

  # 返回操作结果
  &dump("成功切换到特权模式");
  return $enabled; # 返回当前状态
}

# 打印日志提示
sub dump {
  my ($msg) = @_;
  # 当调试模式为2时，打印调试信息
  if ($ENV{PDK_DEBUG} == 2) {
    my $content = "[debug] " . &now . " $msg ;";
    say $content; # 打印内容
  }
}

# 发送脚本
sub send {
  my $cmd = shift;

  # 检查 Expect 对象是否已初始化
  die "执行send下发脚本异常，请检查是否成功初始化 Expect 对象" unless !!$exp;

  my $cli = $cmd;
  if ($cli eq ' ') {
    &dump("正在下发脚本: (空格)");
  }
  elsif ($cli =~ /^(\r|\n)$/) {
    &dump("正在下发脚本: (回车)");
  }
  else {
    $cli =~ s/\r|\n|(\r\n)//g; # 去除多余的换行符
    &dump("正在下发脚本: ($cli)");
  }
  $exp->send($cmd); # 发送命令
}

# 获取当前时间
sub now {
  # 获取当前时间并格式化
  my ($sec, $min, $hour, $mday, $mon, $year) = localtime;
  $mon++;
  $year += 1900;
  return sprintf("%04d-%02d-%02d %02d:%02d:%02d", $year, $mon, $mday, $hour, $min, $sec);
}

# 尝试登录并打印登录提示
eval {
  slogan();
  my $login = login();

  if ($login->{success}) {
    &dump("成功登录设备：$ip");

    # 进入交互模式
    &send("\n");
    $login->{exp}->interact();
  }
  else {
    die "登录失败: " . $login->{reason};
  }
};

die "脚本执行异常，请联系管理员检查原因" if !!$@;