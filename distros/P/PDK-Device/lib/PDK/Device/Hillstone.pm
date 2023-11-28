package PDK::Device::Hillstone;

use Moose;
use Carp;
use namespace::autoclean;
use Expect;

# 使用 'PDK::Device::Base' 角色
with 'PDK::Device::Base';

# 定义登录成功提示符
sub prompt {
  shift;
  return '.*?(\((?:M|B)\))?[>#]\s$';
}

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
      qr/^ --More-- .*$/mi => sub {
        $exp->send(" ");
        $buff .= $exp->before();
        exp_continue;
      }
    ],
    [
      qr/Save configuration for/mi => sub {
        $exp->send("y\r");
        $buff .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [
      qr/Backup all start configuration/mi => sub {
        $exp->send("y\r");
        $buff .= $exp->before() . $exp->match();
        exp_continue;
      }
    ],
    [
      qr/are you sure/mi => sub {
        $exp->send("y\r");
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

  # 字符串修正处理
  $buff =~ s/\c@\cH+\s+\cH+//g;
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

    if ($buff =~ /(incomplete command|ambiguous keyword|unrecognized keyword)/i) {
      return {success => 0, failCommand => $cmd, reason => $result . $buff};
    }
    elsif ($buff =~ /^Error:/i) {
      return {success => 0, failCommand => $cmd, reason => $result . $buff};
    }
    elsif ($buff =~ /(syntax error, expecting|unknown command)/i) {
      return {success => 0, failCommand => $cmd, reason => $result . $buff};
    }
    elsif ($buff =~ /missing argument/i) {
      return {success => 0, failCommand => $cmd, reason => $result . $buff};
    }
    elsif ($buff =~ /\s+\^-----.*$/i) {
      return {success => 0, failCommand => $cmd, reason => $result . $buff};
    }
    else {
      $result .= $buff;
    }
  }

  return {success => 1, result => $result};
}

#------------------------------------------------------------------------------
# 具体实现 runCommands，编写进入特权模式、退出保存配置的逻辑
#------------------------------------------------------------------------------
sub runCommands {
  my ($self, @commands) = @_;

  # 配置下发前 | 切入配置模式
  unshift(@commands, "configure");

  # 完成配置后 | 报错具体配置
  push(@commands, "save all");

  # 执行调度，配置批量下发
  $self->execCommands(@commands);
}

# 获取设备配置方法
sub getConfig {
  my $self     = shift;
  my @commands = ('terminal length 0', 'show configuration running');
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
  my $commands = ['terminal length 0', 'show configuration startup', 'save all'];

  return $self->execCommands(@{$commands});
}

#------------------------------------------------------------------------------
# 具体实现 runningConfig,设置抓取设备运行配置的脚本
#------------------------------------------------------------------------------
sub runningConfig {
  my $self     = shift;
  my $commands = ['terminal length 0', 'show configuration running', 'save all'];

  return $self->execCommands(@{$commands});
}

#------------------------------------------------------------------------------
# 具体实现 healthCheck,设置抓取设备健康检查配置的脚本
#------------------------------------------------------------------------------
sub healthCheck {
  my $self     = shift;
  my $commands = ["terminal length 0", "show version", "show service"];

  return $self->execCommands(@{$commands});
}

__PACKAGE__->meta->make_immutable;

1;
