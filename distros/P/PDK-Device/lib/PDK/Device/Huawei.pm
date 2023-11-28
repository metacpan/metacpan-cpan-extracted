package PDK::Device::Huawei;

use Moose;
use Carp;
use namespace::autoclean;
use Expect;

# 使用 'PDK::Device::Base' 角色
with 'PDK::Device::Base';

# 定义登录成功提示符
sub prompt {
  shift;
  return '(\<(?:[^\<\>]*)\>)|(\[(?<!SubSlot \d)\])';
}

# 定义特权模式提示符
# sub enPrompt {
#   shift;
#   return ']\s*$';
# }

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
      qr/---- More ----.*$/mi => sub {
        $exp->send(" ");
        $buff .= $exp->before();
        exp_continue;
      }
    ],
    [
      qr/configuration will be written to the device. Are you sure.*$/mi => sub {
        $exp->send("Y\n");
        $buff .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [
      qr/startup.cfg exists, overwrite\?.*$/mi => sub {
        $exp->send("Y\n");
        $buff .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [
      qr/press the enter key.*$/mi => sub {
        $exp->send("\r");
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
  $buff =~ s/\cM+[ ]+\cM//g;
  $buff =~ s/\cM{2}//g;
  $buff =~ s/\cM//g;

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

    if ($buff =~ /(% Ambiguous|% Incomplete|invalid|unrecognized).*$/i) {
      return {success => 0, failCommand => $cmd, reason => $result . $buff};
    }
    elsif ($buff =~ /((% Too many parameters)|(% Wrong parameter)).*$/i) {
      return {success => 0, failCommand => $cmd, reason => $result . $buff};
    }
    elsif ($buff =~ /(%\s*Error )|(^error: )/i) {
      return {success => 0, failCommand => $cmd, reason => $result . $buff};
    }
    elsif ($buff =~ /(failed to pass the authorization)|(^\s*\^')/i) {
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

  $exp->send("super\n");

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
  unshift(@commands, "system-view");

  # 完成配置后 | 报错具体配置
  push(@commands, "return", "save force");

  # 执行调度，配置批量下发
  $self->execCommands(@commands);
}

# 获取设备配置方法
sub getConfig {
  my $self     = shift;
  my @commands = ("screen-length disable", "dis cu");
  my $config   = $self->execCommands(@commands);

  if ($config->{success} == 1) {
    my $lines = $config->{result};

    # $lines =~ s/^\s*ntp\s+clock-period\s+\d+\s*$//mi;
    return {success => 1, config => $lines};
  }
  else {
    return $config;
  }
}

#------------------------------------------------------------------------------
# 具体实现 startupConfig,设置抓取设备启动配置的脚本
#------------------------------------------------------------------------------
sub startupConfig {
  my $self     = shift;
  my $commands = ["screen-length disable", "dis cu", "save force"];

  return $self->execCommands(@{$commands});
}

#------------------------------------------------------------------------------
# 具体实现 runningConfig,设置抓取设备运行配置的脚本
#------------------------------------------------------------------------------
sub runningConfig {
  my $self     = shift;
  my $commands = ["screen-length disable", "dis saved-configuration", "save force"];

  return $self->execCommands(@{$commands});
}

#------------------------------------------------------------------------------
# 具体实现 healthCheck,设置抓取设备健康检查配置的脚本
#------------------------------------------------------------------------------
sub healthCheck {
  my $self     = shift;
  my $commands = [
    "dis cpu-usage",
    "dis memory",
    "dis stp down-port",
    "dis fan",
    "dis environment",
    "dis clock",
    "dis ntp-service status"
  ];

  return $self->execCommands(@{$commands});
}

__PACKAGE__->meta->make_immutable;

1;
