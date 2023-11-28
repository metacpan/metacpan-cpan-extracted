package PDK::Device::Cisco;

use Moose;
use Carp;
use namespace::autoclean;
use Expect;

# use open qw(:std :utf8);

# 使用 'PDK::Device::Base' 角色
with 'PDK::Device::Base';

# 等待响应方法
sub waitfor {
  my ($self, $prompt) = @_;

  # 如果没有指定提示符，则使用默认提示符
  $prompt //= $self->prompt();

  my $exp  = $self->expect();
  my $buff = "";

  my @ret = $exp->expect(
    10,
    [
      qr/^.+more\s*.+$/mi => sub {
        $exp->send(" ");
        $buff .= $exp->before();
        exp_continue;
      }
    ],
    [
      qr/overwrite\?\s*\[Y\/N\]/mi => sub {
        $exp->send("Y\r");
        $buff .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [
      qr/Source filename \[running-config\]\?/mi => sub {
        $exp->send("\r");
        $buff .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [
      qr/Destination filename \[startup-config\]\?/mi => sub {
        $exp->send("\n");
        $buff .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [qr/$prompt/m => sub { $buff .= $exp->before() . $exp->match() }]
  );

  # 如果发生异常，抛出错误
  if (defined $ret[1]) {
    croak($ret[3] . $ret[1]);
  }

  # 修正脚本输出
  $buff =~ s/\r\n|\n+\n/\n/g;                       # 统一换行符
  $buff =~ s/(\x{08}+|\cH+)\s+(\x{08}+|\cH+)//g;    # 删除退格符
  $buff =~ s/\x1B\S+\x1B\cM//g;                     # 删除特殊字符
  $buff =~ s/\cM(\c[\S+]*)//g;                      # 删除特殊字符
  $buff =~ s/(\[#+\])\s+\d+%.*$//g;                 # 删除特殊字符

  return $buff;
}

# 执行多个命令方法
sub execCommands {
  my ($self, @commands) = @_;

  # 在脚本执行期间确保设备已登录并处于特权模式下
  if ($self->{isLogin} == 0) {
    my $result = $self->login();
    unless ($self->isLogin) {
      return $result;
    }
  }

  if ($self->{isEnable} == 0) {
    my $result = $self->enable();
    unless ($self->isEnable) {
      return $result;
    }
  }

  my $result = "";

  # 遍历待下发脚本，并对每个脚本执行回显进行异常捕捉
  for my $cmd (@commands) {
    $self->send("$cmd\n");
    my $buff = $self->waitfor();

    if ($buff =~ /% Invalid/i) {
      return {success => 0, failCommand => $cmd, reason => $result . $buff};
    }
    elsif ($buff =~ /(% Incomplete|% Unrecognized)/i) {
      return {success => 0, failCommand => $cmd, reason => $result . $buff};
    }
    elsif ($buff =~ /% Ambiguous/i) {
      return {success => 0, failCommand => $cmd, reason => $result . $buff};
    }
    elsif ($buff =~ /% (Unknown|Type|Permission denied)/i) {
      return {success => 0, failCommand => $cmd, reason => $result . $buff};
    }
    elsif ($buff =~ /(authorization failed|command is not support|syntax error|^Error:)/i) {
      return {success => 0, failCommand => $cmd, reason => $result . $buff};
    }
    else {
      $result .= $buff;
    }
  }

  return {success => 1, result => $result};
}

# 切换到特权模式方法
sub enable {
  my $self     = shift;
  my $enPrompt = $self->enPrompt();
  my $username = $self->{username};
  my $password = $self->{enPassword} // $self->{password};
  my $exp      = $self->expect;
  $exp->send("enable\n");

  my @ret = $exp->expect(
    10,
    [
      qr/assword:\s*$/ => sub {
        $exp->send("$password\n");
      }
    ],
    [
      qr/(ogin|name):\s*$/i => sub {
        $exp->send("$username\n");
        exp_continue;
      }
    ],
    [qr/$enPrompt/ => sub { $self->isEnable(1) }],
    [qr/\^/i       => sub { $self->isEnable(0) }],
  );

  # 如果发生异常，返回失败
  if (defined $ret[1]) {
    return {success => 0, failCommand => '无法切换到特权模式', reason => $ret[3]};
  }

  @ret = $exp->expect(
    10,
    [qr/assword:\s*$/ => sub { croak("Username or enPassword is wrong!") }],
    [qr/$enPrompt/m   => sub { $self->isEnable(1) }],
  );

  # 如果发生异常，返回失败
  if (defined $ret[1]) {
    return {success => 0, failCommand => '无法切换到特权模式', reason => $ret[3]};
  }

  return {success => 1};
}

#------------------------------------------------------------------------------
# 具体实现 runCommands，编写进入特权模式、退出保存配置的逻辑
#------------------------------------------------------------------------------
sub runCommands {
  my ($self, @commands) = @_;

  # 配置下发前 | 切入配置模式
  unshift(@commands, "terminal length 0", "conf t");

  # 完成配置后 | 报错具体配置
  push(@commands, "end", "copy r s");

  # 执行调度，配置批量下发
  $self->execCommands(@commands);
}

# 获取设备配置方法
sub getConfig {
  my $self     = shift;
  my @commands = ("show run | exclude !Time");
  my $config   = $self->execCommands(@commands);

  if ($config->{success} == 1) {
    my $lines = $config->{result};
    $lines =~ s/^\s*ntp\s+clock-period\s+\d+\s*$//mi;
    return {success => 1, config => $lines};
  }
  else {
    return $config;
  }
}

#------------------------------------------------------------------------------
# 具体实现 startupCommands,设置抓取设备启动配置的脚本
#------------------------------------------------------------------------------
sub startupConfig {
  my $self     = shift;
  my $commands = ["terminal length 0", "show startup-config", "copy r s"];

  return $self->execCommands(@{$commands});
}

#------------------------------------------------------------------------------
# 具体实现 runningCommands,设置抓取设备运行配置的脚本
#------------------------------------------------------------------------------
sub runningConfig {
  my $self     = shift;
  my $commands = ["terminal length 0", "show startup-config", "copy r s"];

  return $self->execCommands(@{$commands});
}

#------------------------------------------------------------------------------
# 具体实现 healthCheckCommands,设置抓取设备健康检查配置的脚本
#------------------------------------------------------------------------------
sub healthCheck {
  my $self     = shift;
  my $commands = [
    "show system resources",
    "show system resources",
    "show spanning-tree summary",
    "show environment fan",
    "show environment temperature",
    "show clock",
    "show ntp peers"
  ];

  return $self->execCommands(@{$commands});
}

__PACKAGE__->meta->make_immutable;

1;
