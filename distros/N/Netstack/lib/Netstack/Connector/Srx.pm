package Netstack::Connector::Srx;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use 5.016;
use utf8;
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
  my $prompt = qr/\@[\w\d\-\_]+\>|\#\s+$/;
  return $prompt;
}

#------------------------------------------------------------------------------
# 具体实现 _buildCommands,设置抓取设备运行配置的脚本
#------------------------------------------------------------------------------
sub _buildCommands {
  my $self     = shift;
  my $commands = ["show configuration | display set | no-more"];
  return $commands;
}

#------------------------------------------------------------------------------
# 具体实现 _buildErrorCode,设置命令下发错误码 -> 用于拦截配置下发
#------------------------------------------------------------------------------
sub _buildErrorCode {
  my $self  = shift;
  my $codes = [
    'syntax error, expecting',
    'missing argument',
    'unknown command',
    'error: cli version does not match Managment Daemon', '^Error:',
  ];
  return $codes;
}

#------------------------------------------------------------------------------
# 具体实现 _buildWaitforMap,设置交互式执行脚本 -> 用于交互式下发配置
#------------------------------------------------------------------------------
sub _buildBufferCode {
  my $self    = shift;
  my %mapping = (
    qr/---\(more\)---/mi                => ' ',
    qr/Are\s+you\s+sure\?\s*\[Y\/N\]/mi => 'Y',
    qr/press the enter key\)/mi         => ' ',
    qr/overwrite\?\s*\[Y\/N\]/mi        => 'Y',
    qr/^\%.+\z/mi                       => 'Y',
  );
  # 返回数据字典
  return \%mapping;
}

__PACKAGE__->meta->make_immutable;
1;
