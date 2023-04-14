package PDK::Device::Juniper;

#------------------------------------------------------------------------------
# 加载系统模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 加载通用方法属性
#------------------------------------------------------------------------------
with 'PDK::Device::Role';

#------------------------------------------------------------------------------
# 具体实现 _prompt,设置设备脚本执行成功回显
#------------------------------------------------------------------------------
sub _prompt {
  my $self   = shift;
  my $prompt = '[\w\d\-\_]+(\>|\#)\s+$';
  return $prompt;
}

#------------------------------------------------------------------------------
# 具体实现 _startupCommands,设置抓取设备启动配置的脚本
#------------------------------------------------------------------------------
sub _startupCommands {
  my $self     = shift;
  my $commands = ["show configuration | display set | no-more"];
  return $commands;
}

#------------------------------------------------------------------------------
# 具体实现 _runningCommands,设置抓取设备运行配置的脚本
#------------------------------------------------------------------------------
sub _runningCommands {
  my $self     = shift;
  my $commands = ["show configuration | display set | no-more"];
  return $commands;
}

#------------------------------------------------------------------------------
# 具体实现 _healthCheckCommands,设置抓取设备健康检查配置的脚本
#------------------------------------------------------------------------------
sub _healthCheckCommands {
  my $self     = shift;
  my $commands = ["show version", "show service", "show cdp neighbor"];
  return $commands;
}

#------------------------------------------------------------------------------
# 具体实现 truncateCommand，修正脚本下发后回显乱码
#------------------------------------------------------------------------------
sub truncateCommand {
  my ($self, $buff) = @_;

  # 字符串修正处理
  $buff =~ s/\x1b\[\d+D\s+\x1b\[\d+D//g;
  $buff =~ s/\x{08}+\s+\x{08}+//g;
  $buff =~ s/\r\n|\n+\n/\n/g;
  $buff =~ s/^%.+$//mg;
  $buff =~ s/^\s*$//mg;

  # 返回修正数据
  return $buff;
}

#------------------------------------------------------------------------------
# 具体实现 _errorCodes,设置命令下发错误码 -> 用于拦截配置下发
#------------------------------------------------------------------------------
sub _errorCodes {
  my $self  = shift;
  my $codes = [
    'missing argument',
    'unknown command',
    'Invalid input detected',
    '^Error:',
    'Couldn\'t initiate connection',
    'Unrecognized command',
    'command is not valid',
    'syntax error',
  ];
  return $codes;
}

#------------------------------------------------------------------------------
# 具体实现 _buildWaitforMap,设置交互式执行脚本 -> 用于交互式下发配置
#------------------------------------------------------------------------------
sub _bufferCodes {
  my $self    = shift;
  my %mapping = (
    more     => '\Q---(more \E(\d+%)?\Q)---\E',
    interact => {
      'Are\s+you\s+sure\?\s*\[Y\/N\]' => 'Y',
      'press the enter key\)'         => ' ',
      'overwrite\?\s*\[Y\/N\]'        => 'Y',
      '^\%.+\z'                       => 'Y',
    }
  );
  return \%mapping;
}

#------------------------------------------------------------------------------
# 具体实现 runCommands，编写进入特权模式、退出保存配置的逻辑
#------------------------------------------------------------------------------
sub runCommands {
  my ($self, @commands) = @_;

  # 配置下发前 | 切入配置模式
  unshift(@commands, "configure");

  # 完成配置后 | 报错具体配置
  push(@commands, "commit");

  # 执行调度，配置批量下发
  $self->execCommands(@commands);
}

__PACKAGE__->meta->make_immutable;
1;
