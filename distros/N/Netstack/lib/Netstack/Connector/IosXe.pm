package Netstack::Connector::IosXe;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use 5.016;
use Expect;
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 继承 Netstack::Connector::Role 方法属性,同时具体实现其指定方法
#------------------------------------------------------------------------------
with 'Netstack::Connector::Role';

#------------------------------------------------------------------------------
# 具体实现 _buildPrompt,设置设备脚本执行成功回显
#------------------------------------------------------------------------------
sub _buildPrompt {
  my $self   = shift;
  my $prompt = qr/[\w\d\-\_]+\#\s*$/;
  return $prompt;
}

#------------------------------------------------------------------------------
# 具体实现 _buildCommands,设置抓取设备运行配置的脚本
#------------------------------------------------------------------------------
sub _buildCommands {
  my $self     = shift;
  my $commands = [ "terminal length 0", "show running-config", "copy run start" ];
  # my $commands = ["show running-config"];
  return $commands;
}

#------------------------------------------------------------------------------
# 具体实现 _buildErrorCode,设置命令下发错误码 -> 用于拦截配置下发
#------------------------------------------------------------------------------
sub _buildErrorCode {
  my $self  = shift;
  my $codes = [
    'for a list of subcommands',
    '% Incomplete command',
    '% Ambiguous command',
    '% Permission denied',
    'command authorization failed',
    'Invalid input detected|Type help or ',
    'Line has invalid autocommand',
    'Invalid input detected|Incomplete command',
  ];
  return $codes;
}

#------------------------------------------------------------------------------
# 具体实现 _buildBufferCode,设置交互式执行脚本 -> 用于交互式下发配置
#------------------------------------------------------------------------------
sub _buildBufferCode {
  my $self    = shift;
  my %mapping = (
    more     => qr/--More--/m,
    interact => {
      qr/\[startup-config\]\?/mi   => ' ',
      qr/overwrite\?\s*\[Y\/N\]/mi => 'Y',
    }
  );
  # 返回数据字典
  return \%mapping;
}

#------------------------------------------------------------------------------
# 具体实现 runCommands，编写进入特权模式、退出保存配置的逻辑
#------------------------------------------------------------------------------
sub runCommands {
  my ( $self, $commands ) = @_;
  # 用户传递的具体配置 | 需要先初始化配置
  $self->setCommands($commands);
  # 配置下发前 | 切入配置模式
  $self->addCommand('conf t');
  # 完成配置后 | 报错具体配置
  $self->pushCommand("copy run start");

  # 执行调度，配置批量下发
  $self->execCommands( $self->commands->@* );
}
__PACKAGE__->meta->make_immutable;
1;
