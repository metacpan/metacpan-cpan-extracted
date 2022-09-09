package PDK::Device::Common;

#------------------------------------------------------------------------------
# 加载项目依赖模块
#------------------------------------------------------------------------------
use strict;
use warnings;
use Try::Tiny;

#------------------------------------------------------------------------------
# 设定可以导出方法函数
#------------------------------------------------------------------------------
require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw/getRunConfig/;

#------------------------------------------------------------------------------
# 获取设备运行配置
#------------------------------------------------------------------------------
sub getRunConfig {
  my $param = shift;

  # 提取设备登录相关属性
  my $ip       = $param->{manage_ip}   // $param->{ip};
  my $hostname = $param->{device_name} // $param->{hostname};
  my $vendor   = $param->{vendor};
  my $username = $param->{username};
  my $password = $param->{password};

  # 动态加载设备连接插件
  $vendor = ucfirst lc $vendor;
  my $class = "Firewall::Device::$vendor";

  # 实例化设备连机对象
  my $result;
  @{$result}{qw /ip hostname vendor username password/} = ($ip, $hostname, $vendor, $username, $password);
  try {
    eval 'use $class; 1' or die "Cannot load module $class: $@\n";
    my $session = $class->new(host => $ip, username => $username, password => $password);
    $result = $session->getConfig();
  }
  catch {
    my $e = $_;
    $result->{error}   = $e;
    $result->{success} = 0;
  };

  return $result;
}

1;
