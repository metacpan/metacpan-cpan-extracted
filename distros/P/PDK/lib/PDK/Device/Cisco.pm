package PDK::Device::Cisco;

#------------------------------------------------------------------------------
# 加载项目依赖模块
#------------------------------------------------------------------------------
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 加载通用方法属性
#------------------------------------------------------------------------------
with 'PDK::Device::Role';

#------------------------------------------------------------------------------
# _enCommand 进入特权模式
#------------------------------------------------------------------------------
sub _enCommand {
  my $self = shift;
  return 'enable';
}

#------------------------------------------------------------------------------
# _enPrompt 特权模式提示符
#------------------------------------------------------------------------------
sub _enPrompt {
  my $self = shift;
  $self->{enPrompt} = '\S*#\s*$';
}

#------------------------------------------------------------------------------
# 具体实现 _prompt,设置设备脚本执行成功回显
#------------------------------------------------------------------------------
sub _prompt {
  my $self = shift;
  $self->{prompt} = '\S*(#|>)\s*$';
}

#------------------------------------------------------------------------------
# 具体实现 _startupCommands,设置抓取设备启动配置的脚本
#------------------------------------------------------------------------------
sub _startupCommands {
  my $self     = shift;
  my $commands = ["terminal length 0", "show startup-config", "write"];
  return $commands;
}

#------------------------------------------------------------------------------
# 具体实现 _runningCommands,设置抓取设备运行配置的脚本
#------------------------------------------------------------------------------
sub _runningCommands {
  my $self     = shift;
  my $commands = ["terminal length 0", "show running-config", "write"];
  return $commands;
}

#------------------------------------------------------------------------------
# 具体实现 _healthCheckCommands,设置抓取设备健康检查配置的脚本
#------------------------------------------------------------------------------
sub _healthCheckCommands {
  my $self     = shift;
  my $commands = ["terminal length 0", "show ip arp", "show cdp neighbor"];
  return $commands;
}

#------------------------------------------------------------------------------
# 具体实现 truncateCommand，修正脚本下发后回显乱码
#------------------------------------------------------------------------------
sub truncateCommand {
  my ($self, $buff) = @_;

  # 字符串修正处理
  $buff =~ s/\cH+\s+\cH+//g;                   # IOS
  $buff =~ s/\c[\S+\c[\S+\cM//g;               # Nexus
  $buff =~ s/\cM(\c[\S+)*//g;                  # Nexus
  $buff =~ s/\[#.*%//g;                        # Nexus
  $buff =~ s/\[#.*100%/Saved successfully/;    # Nexus
  return $buff;
}

#------------------------------------------------------------------------------
# 具体实现 _errorCodes,设置命令下发错误码 -> 用于拦截配置下发
#------------------------------------------------------------------------------
sub _errorCodes {
  my $self  = shift;
  my $codes = [
    'ERROR\:( \%)? ',
    '(Open device \S+ failed|Error opening \S+:)',
    '\% Incomplete command',
    '\% Invalid input detected at',
    '\% Ambiguous command:',
  ];
  return $codes;
}

#------------------------------------------------------------------------------
# 具体实现 _bufferCodes,设置交互式执行脚本 -> 用于交互式下发配置
#------------------------------------------------------------------------------
sub _bufferCodes {
  my $self    = shift;
  my %mapping = (
    more     => '( )*--More--\s*',
    interact => {
      'Address or name of remote host \['                            => "\r",
      'Destination filename \[s'                                     => "\n",
      'the product\? \[Y\]es, \[N\]o, \[A\]sk later\: '              => "Y\n",
      'overwrite\?\s*\[Y\/N\]'                                       => "Y\r",
      'Source filename \[running-config\]\? '                        => "\r",
      'Configuring from terminal, memory, or network \[terminal\]\?' => "\r",
    }
  );

  # 返回数据字典
  return \%mapping;
}

#------------------------------------------------------------------------------
# 具体实现 runCommands，编写进入特权模式、退出保存配置的逻辑
#------------------------------------------------------------------------------
sub runCommands {
  my ($self, @commands) = @_;

  # 配置下发前 | 切入配置模式
  unshift(@commands, "terminal page 0", "conf t");

  # 完成配置后 | 报错具体配置
  push(@commands, "end", "write");

  # 执行调度，配置批量下发
  $self->execCommands(@commands);
}

__PACKAGE__->meta->make_immutable;
1;
