package PDK::Utils::BlockIpaddr;

#------------------------------------------------------------------------------
# 加载系统模块
#------------------------------------------------------------------------------
use 5.016;
use warnings;
use utf8;
use diagnostics;
use Sub::Exporter -setup => {exports => [qw(block_ddos firewall_block_ddos)]};

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
# 生成 hillstone 防火墙封堵脚本
#------------------------------------------------------------------------------
sub hillstone_block_list {
  my $address = shift;
  my @address = filter_valid_address($address);
  return unless @address;
  my @command = ("configure", "address DENY_DDOS",);
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
      trim($ip);
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
    sz  => {host => '10.250.8.16', vendor => 'Hillstone',},
    idc => {host => '10.250.8.16', vendor => 'Hillstone',},
    sh  => {host => '10.250.8.16', vendor => 'Paloalto',},
    cq  => {host => '10.250.8.16', vendor => 'Paloalto',},
  };
}

1;
