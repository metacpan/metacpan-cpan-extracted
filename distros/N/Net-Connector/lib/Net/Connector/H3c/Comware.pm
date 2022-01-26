package Net::Connector::H3c::Comware;

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use 5.016;
use Expect;
use Moose;
use namespace::autoclean;

#------------------------------------------------------------------------------
# 继承 Net::Connector::Role 方法属性,同时具体实现其指定方法
#------------------------------------------------------------------------------
with 'Net::Connector::Role';

#------------------------------------------------------------------------------
# 具体实现 _buildPrompt,设置设备脚本执行成功回显
#------------------------------------------------------------------------------
sub _buildPrompt {
  my $self   = shift;
  my $prompt = '\<(?:[^\<\>]*)\>|\[(?:[^\[\]]*)\]';
  return $prompt;
}

#------------------------------------------------------------------------------
# 具体实现 _buildCommands,设置抓取设备运行配置的脚本
#------------------------------------------------------------------------------
sub _buildCommands {
  my $self = shift;

  # my $commands = ["dis current-configuration"];
  my $commands = [ "screen-length disable", "dis current-configuration", "save force" ];
  return $commands;
}

#------------------------------------------------------------------------------
# 具体实现 _buildErrorCode,设置命令下发错误码 -> 用于拦截配置下发
#------------------------------------------------------------------------------
sub _buildErrorCode {
  my $self  = shift;
  my $codes = [
    'Invalid input detected\s+.+\^',
    '% Ambiguous command found at',
    '% Incomplete command found at',
    '(^\s*\^|error:)',
  ];
  return $codes;
}

#------------------------------------------------------------------------------
# 具体实现 _buildBufferCode,设置交互式执行脚本 -> 用于交互式下发配置
#------------------------------------------------------------------------------
sub _buildBufferCode {
  my $self    = shift;
  my %mapping = (
    more     => '---- More ----.*$',
    interact => {
      'Are\s+you\s+sure\?\s*\[Y\/N\]' => 'Y',
      'overwrite\?\s*\[Y\/N\]'        => 'Y',
      'press the enter key\)'         => ' ',
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
  $self->addCommand('system-view');

  # 完成配置后 | 报错具体配置
  $self->pushCommand("save force");

  # 执行调度，配置批量下发
  $self->execCommands( $self->commands->@* );
}

=encoding utf8

=head1 NAME

Net::Connector::H3c::Comware for H3C SWITCH AUTO SSH

=head1 SYNOPSIS

  # Net::Connector::H3c::Comware, UNDER DEVELOPMENT
    该项目使用 Moose 编写相关代码逻辑，当前支持的功能如下：
    1、支持定义enable模式；
    2、支持初阶的错误代码拦截；

    $h3c = Net::Connector::H3c::Comware->new(host => "127.0.0.1")
    # get config by default scripts, you can change with your requirements
    $ret = $h3c->getConfig()
    # print the result
    print p $h3c

=head1 DESCRIPTION

    待完善功能描述和模块使用概要

=head1 SEE ALSO

L<Net::Connector>, L<https://github.com/snmpd/net-connector>.

=cut

__PACKAGE__->meta->make_immutable;
1;
