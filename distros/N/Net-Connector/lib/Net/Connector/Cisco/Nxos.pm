package Net::Connector::Cisco::Nxos;

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
# 具体实现 _prompt,设置设备脚本执行成功回显
#------------------------------------------------------------------------------
sub _prompt {
  my $self   = shift;
  my $prompt = '[\w\d\-\_\)]+\#|\>\s*';
  # my $prompt = '[^([^#>]+[#>])';
  return $prompt;
}

#------------------------------------------------------------------------------
# 具体实现 _startupCommands,设置抓取设备启动配置的脚本
#------------------------------------------------------------------------------
sub _startupCommands {
  my $self     = shift;
  my $commands = [ "terminal length 0", "show startup-config", "copy run start" ];

  # my $commands = ["show running-config"];
  return $commands;
}

#------------------------------------------------------------------------------
# 具体实现 _runningCommands,设置抓取设备运行配置的脚本
#------------------------------------------------------------------------------
sub _runningCommands {
  my $self     = shift;
  my $commands = [ "terminal length 0", "show running-config", "copy run start" ];

  # my $commands = ["show running-config"];
  return $commands;
}

#------------------------------------------------------------------------------
# 具体实现 _healthCheckCommands,设置抓取设备健康检查配置的脚本
#------------------------------------------------------------------------------
sub _healthCheckCommands {
  my $self     = shift;
  my $commands = [ "terminal length 0", "show ip arp", "show cdp neighbor" ];

  return $commands;
}

#------------------------------------------------------------------------------
# 具体实现 truncateCommand，修正脚本下发后回显乱码
#------------------------------------------------------------------------------
sub truncateCommand {
  my ( $self, $buff ) = @_;

  # 字符串修正处理
  $buff =~ s/\x1b\[\d+D\s+\x1b\[\d+D//g;
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
    '(invalid (input|command) detected|type help or)',
    '(Open device \S+ failed|Error opening \S+:)',
    '(?:%|command)? authorization failed',
    'for a list of subcommands',
    'command is not support',
    '% Incomplete command',
    '% Invalid command at',
    'Line has invalid autocommand',
    'No such device|Error Sending Request',
    '%Error calling',
    'Ambiguous command',
    'No token match at',
    '% Permission denied',
    '% Unknown',
    '% Bad IP',
    'Invalid input detected|Incomplete command',
    'Invalid |\%Error ',
  ];
  return $codes;
}

#------------------------------------------------------------------------------
# 具体实现 _bufferCodes,设置交互式执行脚本 -> 用于交互式下发配置
#------------------------------------------------------------------------------
sub _bufferCodes {
  my $self    = shift;
  my %mapping = (
    more     => '--More--',
    interact => {
      '\[startup-config\]\?'              => ' ',
      'Address or name of remote host \[' => "\r",
      'Destination filename \['           => "\r",
      'overwrite\?\s*\[Y\/N\]'            => 'Y',
    }
  );

  # 返回数据字典
  return \%mapping;
}

#------------------------------------------------------------------------------
# 具体实现 runCommands，编写进入特权模式、退出保存配置的逻辑
#------------------------------------------------------------------------------
sub runCommands {
  my ( $self, @commands ) = @_;

  # 配置下发前 | 切入配置模式
  unshift( @commands, "conf t" );

  # 完成配置后 | 报错具体配置
  push( @commands, "end", "copy run start" );

  # 执行调度，配置批量下发
  $self->execCommands(@commands);
}

# generate tftp config variables
sub generate_tftp_cmd {

  # load modules
  use Carp;
  use POSIX qw/strftime/;

  my ( $self, $ip, $hostname ) = @_;
  $hostname = $ip unless defined $hostname;
  confess "must provide ip and hostname" if not defined $ip or $ip eq "";

  my $tftp_server = $self->tftp_server;

  # init variables
  my $dir  = strftime( "%Y-%m",  localtime );
  my $time = strftime( "%Y%m%d", localtime );

  # generate tftp path
  my $tftp_destination = $tftp_server . "$dir/$time/$ip-$hostname.config";

  # generate tftp_destination
  return "copy running-config $tftp_destination";
}

# 支持 tftp 保存运行配置
sub copy_config_by_tftp {
  my ( $self, $ip, $hostname ) = @_;

  # 生成命令
  my $cmd = $self->generate_tftp_cmd( $ip, $hostname );

  # 执行脚本
  return $self->execCommands($cmd);

}

=encoding utf8

=head1 NAME

Net::Connector::Cisco::Nxos for CISCO NETWORK DEVICES AUTO SSH

=head1 SYNOPSIS

  # Net::Connector::Cisco::Nxos, UNDER DEVELOPMENT
    该项目使用 Moose 编写相关代码逻辑，当前支持的功能如下：
    1、支持定义enable模式；
    2、支持初阶的错误代码拦截；

    $d = Net::Connector::Cisco::Nxos->new(host => "127.0.0.1");
    # get config by default scripts, you can change with your requirements
    $ret = $d->runningConfig();

    # print the result
    use DDP;
    print p $ret;

=head1 DESCRIPTION

    待完善功能描述和模块使用概要

=head1 SEE ALSO

L<Net::Connector>, L<https://github.com/snmpd/net-connector>.

=cut

__PACKAGE__->meta->make_immutable;
1;
