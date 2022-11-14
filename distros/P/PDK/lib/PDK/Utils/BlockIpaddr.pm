package PDK::Utils::BlockIpaddr;

#------------------------------------------------------------------------------
# 加载系统模块
#------------------------------------------------------------------------------
use 5.016;
use warnings;
use utf8;
use diagnostics;
use Sub::Exporter -setup => {exports => [qw(block_ddos firewall_block_ddos cross_to_hk)]};

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Mojo::Util         qw/trim/;
use List::MoreUtils    qw/any/;
use Data::Validate::IP qw/is_ipv4/;
use PDK::Device::Hillstone;
use PDK::Device::Paloalto;

#------------------------------------------------------------------------------
# 互联网攻击封堵函数入口
#------------------------------------------------------------------------------
sub block_ddos {
  my ($location, $address) = @_;
  my $mapping = mapping();
  my $result  = {code => 0, msg => '封堵脚本执行成功', data => ''};

  # 遍历勾选的入口区域
  foreach my $item (@{$location}) {
    my $params  = $mapping->{$item};
    my $context = firewall_block_ddos($params, $address);
    if ($context->{success} == 0) {
      $result->{code} = 7;
      $result->{msg}  = "封堵脚本下发(部分)异常，请检查日志";
      $result->{data} .= $context->{reason};
    }
    else {
      $result->{data} .= $context->{config};
    }
  }

  return $result;
}

#------------------------------------------------------------------------------
# 防火墙封堵 DDOS
#------------------------------------------------------------------------------
sub firewall_block_ddos {
  my ($params, $address) = @_;

  # 查询入参并设定设备登录权限凭证
  my $host     = $params->{host};
  my $vendor   = $params->{vendor}   // "Hillstone";
  my $username = $params->{username} // "xxx";
  my $password = $params->{password} // "zzz";

  # 初始化设备连接
  my $class = "PDK::Device::" . (ucfirst lc $vendor);
  my $block = (lc $vendor) . "_block_list";
  my $conn  = $class->new(host => $host, username => $username, password => $password);
  no strict "refs";
  my @command = &$block($address);
  use strict "refs";
  return $conn->execCommands(@command);
}

#------------------------------------------------------------------------------
# cross_to_hk 一键翻墙
#------------------------------------------------------------------------------
sub cross_to_hk {
  my ($context, $address) = @_;

  # 查询入参并设定设备登录权限凭证
  my $host     = "10.250.8.26";
  my $vendor   = "Hillstone";
  my $username = "xxx";
  my $password = "zzz";

  # 初始化设备连接
  my $class   = "PDK::Device::" . (ucfirst lc $vendor);
  my $conn    = $class->new(host => $host, username => $username, password => $password);
  my @command = hillstone_to_hk($context, $address);
  my $execRet = $conn->execCommands(@command);

  my $result;
  if ($execRet->{success} == 0) {
    $result->{code} = 7;
    $result->{msg}  = "一键翻墙脚本下发(部分)异常，请检查日志";
    $result->{data} .= $context->{reason};
  }
  else {
    $result->{data} .= $context->{config};
  }
  return $result;
}

#------------------------------------------------------------------------------
# 生成 hillstone 一键翻墙脚本
#------------------------------------------------------------------------------
sub hillstone_to_hk {
  my ($context, $address) = @_;
  return _hillstone_block_list($address, ucfirst $context);
}

#------------------------------------------------------------------------------
# 生成 hillstone 封堵DDOS脚本
#------------------------------------------------------------------------------
sub hillstone_block_list {
  my $address = shift;
  return _hillstone_block_list($address, "DENY_DDOS");
}

#------------------------------------------------------------------------------
# _hillstone_block_list address 对象新增成员对象
#------------------------------------------------------------------------------
sub _hillstone_block_list {
  my ($address, $context) = @_;
  my @address = filter_valid_address($address);
  return unless @address;
  my $addrItem = "address " . $context;
  my @command  = ("configure", $addrItem);
  foreach my $ip (@address) {
    my $item = "ip $ip" . "/32";
    push(@command, $item);
  }
  push(@command, "end", "save force");
  return @command;

  # my $command = join("\n", @command);
  # return $command;
}

#------------------------------------------------------------------------------
# 生成 paloalto 防火墙封堵脚本
#------------------------------------------------------------------------------
sub paloalto_block_list {
  my $address = shift;
  my @address = filter_valid_address($address);
  return unless @address;
  my @command = ("configure", "edit DENY_DDOS",);
  foreach my $ip (@address) {
    my $item = "ip $ip" . "/32";
    push(@command, $item);
  }
  push(@command, "save config");
  return @command;

  # my $command = join("\n", @command);
  # return $command;
}

#------------------------------------------------------------------------------
# 过滤有效的 IPv4 地址
#------------------------------------------------------------------------------
sub filter_valid_address {
  my $address = shift;
  my @data    = split(/\n|\r|;|,/, $address);
  my @address;
  foreach my $ip (@data) {
    if (is_ipv4($ip)) {
      trim $ip;
      push(@address, $ip);
    }
  }
  return @address;
}

#------------------------------------------------------------------------------
# 本地字典映射
#------------------------------------------------------------------------------
sub mapping {
  return {
    sz  => {host => '10.250.8.26', vendor => 'Hillstone',},
    idc => {host => '10.250.8.16', vendor => 'Paloalto',},
    sh  => {host => '10.250.8.16', vendor => 'Paloalto',},
    cq  => {host => '10.250.8.16', vendor => 'Hillstone',},
  };
}

1;
