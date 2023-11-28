package PDK::Device::Paloalto;

use Moose;
use Carp;
use namespace::autoclean;
use Expect;

# 使用 'PDK::Device::Base' 角色
with 'PDK::Device::Base';

# 定义登录成功提示符
sub prompt {
  shift;
  return '.*?\((?:active|passive)\)[>#]';
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
      qr/lines \d+-\d+.*$/mi => sub {
        $exp->send(" ");
        $buff .= $exp->before();
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
  $buff =~ s/ \cH//g;                     # 捕捉数字之间空白符
  $buff =~ s/(\c[\S+)+\cM(\c[\[K)?//g;    # 捕捉字符信息
  $buff =~ s/\cM(\c[\S+)+\c[>//g;         # 登陆成功提示符

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

    if ($buff =~ /Warning: Configuration is not committed/i) {
      return {success => 0, failCommand => $cmd, reason => $result . $buff};
    }
    elsif ($buff =~ /(Invalid syntax|Unknown command)/i) {
      return {success => 0, failCommand => $cmd, reason => $result . $buff};
    }
    elsif ($buff =~ /^Error:/i) {
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
  push(@commands, "save config");

  # 执行调度，配置批量下发
  $self->execCommands(@commands);
}

# 获取设备配置方法
sub getConfig {
  my $self     = shift;
  my @commands = ("set cli pager off", "set cli config-output-format set", "configure", "show", "exit");
  my $config   = $self->execCommands(@commands);

  if ($config->{success} == 1) {
    my $lines = $config->{result};
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
  my $commands = ["set cli pager off", "set cli config-output-format set", "configure", "show", "exit"];

  return $self->execCommands(@{$commands});
}

#------------------------------------------------------------------------------
# 具体实现 runningConfig,设置抓取设备运行配置的脚本
#------------------------------------------------------------------------------
sub runningConfig {
  my $self     = shift;
  my $commands = ["set cli pager off", "set cli config-output-format set", "configure", "show", "exit"];

  return $self->execCommands(@{$commands});
}

#------------------------------------------------------------------------------
# 具体实现 healthCheck,设置抓取设备健康检查配置的脚本
#------------------------------------------------------------------------------
sub healthCheck {
  my $self     = shift;
  my $commands = ["set cli pager off", "set cli config-output-format set", "configure", "show", "exit"];

  return $self->execCommands(@{$commands});
}

__PACKAGE__->meta->make_immutable;

1;
