package PDK::Utils::OpenSwitchPort;

#------------------------------------------------------------------------------
# 加载系统模块
#------------------------------------------------------------------------------
use 5.016;
use warnings;
use utf8;
no warnings 'utf8';
use diagnostics;
use Sub::Exporter -setup => {exports => [qw(parseExcel openCiscoPort openH3cPort portManager writePortConfig)]};

#------------------------------------------------------------------------------
# 加载扩展模块
#------------------------------------------------------------------------------
use Mojo::Util    qw/trim/;
use File::Slurper qw/write_text/;
use Spreadsheet::ParseExcel;
use Data::Validate::IP qw/is_ipv4/;

# use List::MoreUtils    qw/any/;
#------------------------------------------------------------------------------
# parse_excel => 解析 Excel 表单
#------------------------------------------------------------------------------
sub parseExcel {
  my $file_name = shift;

  # 实例化插件对象
  my $parser = Spreadsheet::ParseExcel->new();
  do { say "请正确提供交换机端口申请表单"; return } unless -e $file_name;
  my $workbook = $parser->parse($file_name);

  # 未检测到指定文件，提示用户
  unless (defined $workbook) {
    die "请参考 openSwitchPort.xls 配置模板" . $parser->error() . "\n";
  }

  # 批量解析 EXCEL 文件下多个 SHEET
  my $switchPorts;
  for my $worksheet ($workbook->worksheets()) {
    my ($row_min, $row_max) = $worksheet->row_range();

    # 从第三行开始为布线接口数据
    for my $row (2 .. $row_max) {
      my %port;

      # 判定改行是否为空
      if ($worksheet->get_cell($row, 0) and $worksheet->get_cell($row, 2)) {
        $port{line}    = trim $worksheet->get_cell($row, 0)->value();
        $port{device1} = trim $worksheet->get_cell($row, 2)->value();
      }
      else {
        next;
      }

      # 提取单元格表项
      $port{sn1}        = trim $worksheet->get_cell($row, 3)->value();
      $port{rack1}      = trim $worksheet->get_cell($row, 4)->value();
      $port{mgmt1}      = trim $worksheet->get_cell($row, 5)->value();
      $port{iface1}     = trim $worksheet->get_cell($row, 6)->value();
      $port{ip1}        = trim $worksheet->get_cell($row, 7)->value();
      $port{device2}    = trim $worksheet->get_cell($row, 8)->value();
      $port{sn2}        = trim $worksheet->get_cell($row, 9)->value();
      $port{rack2}      = trim $worksheet->get_cell($row, 10)->value();
      $port{mgmt2}      = trim $worksheet->get_cell($row, 11)->value();
      $port{iface2}     = trim $worksheet->get_cell($row, 12)->value();
      $port{ip2}        = trim $worksheet->get_cell($row, 13)->value();
      $port{is_network} = trim $worksheet->get_cell($row, 14)->value();
      $port{is_l3}      = trim $worksheet->get_cell($row, 15)->value();
      $port{is_aggr}    = trim $worksheet->get_cell($row, 16)->value();
      $port{aggr_id}    = trim $worksheet->get_cell($row, 17)->value();
      $port{is_trunk}   = trim $worksheet->get_cell($row, 18)->value();
      $port{vlan_id}    = trim $worksheet->get_cell($row, 19)->value();

      # 根据交换机SN规整表单下相关端口
      push @{$switchPorts}, \%port;
    }
  }
  my $counter = scalar @{$switchPorts};
  say "已将 $counter 个交换机端口添加到作业队列中，请稍等...";

  # 返回计算计算结果
  return $switchPorts;
}

#------------------------------------------------------------------------------
# 生成思科交换机端口配置
#------------------------------------------------------------------------------
sub openCiscoPort {
  my $data = shift;

  # A端设备信息
  my $device1 = $data->{device1};
  my $mgmt1   = $data->{mgmt1};
  my $sn1     = $data->{sn1};
  my $iface1  = $data->{iface1};
  my $ip1     = $data->{ip1};

  # B端设备信息
  my $device2 = $data->{device2};
  my $mgmt2   = $data->{mgmt2};
  my $sn2     = $data->{sn2};
  my $iface2  = $data->{iface2};
  my $ip2     = $data->{ip2};

  # 接口通用属性
  my $is_aggr  = $data->{is_aggr};
  my $aggr_id  = $data->{aggr_id};
  my $is_trunk = $data->{is_trunk};
  my $vlan_id  = $data->{vlan_id};
  my $is_l3    = $data->{is_l3};

  # 是否网络设备 网络设备需要同时生成 AB端 交换机的配置
  my $is_network = $data->{is_network};

  # 初始化变量
  my ($cfg1, $cfg2);

  # CELL 填写成员端口可能有多个
  my $i = 0;
  my $j = 0;

  # 物理口实际配置
  my @iface1 = split(/,|;/, $iface1);
  my @iface2 = split(/,|;/, $iface2);

  # 早期异常拦截
  return unless @iface1;
  return unless @iface2;
  return if @iface1 != @iface2;
  if ($is_l3 =~ /Y|是/) {
    unless (is_ipv4($ip1) and is_ipv4($ip2)) {
      return;
    }
  }

  # 如果是网络设备同时生成双边交换机配置
  if ($is_network =~ /Y|是/i) {
    if ($is_aggr =~ /Y|是/i and !!$aggr_id) {
      push @{$cfg2}, "interface port-channel $aggr_id";
      push @{$cfg2}, "  description TO_" . ($device1 // $sn1) . "_" . ($iface1 // $ip1);
      push @{$cfg2}, "  no shutdown";

      if ($is_l3 =~ /Y|是/i and !!$ip2) {
        push @{$cfg2}, "  no switchport";
        push @{$cfg2}, "  ip address $ip2";
      }
      else {
        my $vlans = join(",", split(/,|;/, $vlan_id));
        push @{$cfg2}, "  spanning-tree port type network";
        if ($is_trunk =~ /Y|是/i) {
          push @{$cfg2}, "  switchport mode trunk";
          push @{$cfg2}, "  switchport trunk allowed vlan $vlans" if !!$vlans;
        }
        else {
          push @{$cfg2}, "  switchport mode access";
          push @{$cfg2}, "  switchport access vlan $vlan_id";
        }
      }
    }

    # 物理口实际配置
    foreach my $iface (@iface2) {
      push @{$cfg2}, "interface $iface";
      push @{$cfg2}, "  description TO_" . ($device1 // $sn1) . "_" . $iface1[$i];
      push @{$cfg2}, "  channel-group $aggr_id mode active" if $is_aggr and $aggr_id;
      push @{$cfg2}, "  no shutdown";

      if ($is_l3 =~ /Y|是/i and !!$ip2) {
        push @{$cfg2}, "  no switchport";
        push @{$cfg2}, "  ip address $ip2" unless $is_aggr and $aggr_id;
      }
      else {
        push @{$cfg2}, "  spanning-tree port type network";
        my $vlans = join(",", split(/,|;/, $vlan_id));
        if ($is_trunk =~ /Y|是/i) {
          push @{$cfg2}, "  switchport mode trunk";
          push @{$cfg2}, "  switchport trunk allowed vlan $vlans" if !!$vlans;
        }
        else {
          push @{$cfg2}, "  switchport mode access";
          push @{$cfg2}, "  switchport access vlan $vlan_id";
        }
      }
      push @{$cfg2}, "!";
      $i++;
    }
  }

  # 正常情况只关注交换机侧的配置
  if ($is_aggr =~ /Y|是/i and !!$aggr_id) {
    push @{$cfg1}, "interface port-channel $aggr_id";
    push @{$cfg1}, "  description TO_" . ($device2 // $sn2) . "_" . ($iface2 // $ip2);
    push @{$cfg1}, "  no shutdown";

    if ($is_l3 =~ /Y|是/i and !!$ip1) {
      push @{$cfg1}, "  no switchport";
      push @{$cfg1}, "  ip address $ip1";
    }
    else {
      my $vlans = join(",", split(/,|;/, $vlan_id));
      push @{$cfg1}, "  spanning-tree port type network";
      if ($is_trunk =~ /Y|是/i) {
        push @{$cfg1}, "  switchport mode trunk";
        push @{$cfg1}, "  switchport trunk allowed vlan $vlans" if !!$vlans;
      }
      else {
        push @{$cfg1}, "  switchport mode access";
        push @{$cfg1}, "  switchport access vlan $vlan_id";
      }
    }
  }

  # 物理口实际配置
  foreach my $iface (@iface1) {
    push @{$cfg1}, "interface $iface";
    push @{$cfg1}, "  description TO_" . ($device2 // $sn2) . "_" . $iface2[$j];
    push @{$cfg1}, "  channel-group $aggr_id mode active" if $is_aggr and $aggr_id;
    push @{$cfg1}, "  no shutdown";

    if ($is_l3 =~ /Y|是/i and !!$ip1) {
      push @{$cfg1}, "  no switchport";
      push @{$cfg1}, "  ip address $ip1" unless $is_aggr and $aggr_id;
    }
    else {
      push @{$cfg1}, "  spanning-tree port type network";
      my $vlans = join(",", split(/,|;/, $vlan_id));
      if ($is_trunk =~ /Y|是/i) {
        push @{$cfg1}, "  switchport mode trunk";
        push @{$cfg1}, "  switchport trunk allowed vlan $vlans" if !!$vlans;
      }
      else {
        push @{$cfg1}, "  switchport mode access";
        push @{$cfg1}, "  switchport access vlan $vlan_id";
      }
    }
    push @{$cfg1}, "!";
    $j++;
  }

  # 返回计算结果
  my $index1 = $device1 . "-" . $mgmt1;
  my $index2 = $device2 . "-" . $mgmt2;
  my $port1  = $cfg1                   ? [$index1, $cfg1] : undef;
  my $port2  = ($is_network and $cfg2) ? [$index2, $cfg2] : undef;
  return ([$port1, $port2]);
}

#------------------------------------------------------------------------------
# 生成华三交换机端口配置
#------------------------------------------------------------------------------
sub openH3cPort {
  my $data = shift;

  # A端设备信息
  my $device1 = $data->{device1};
  my $mgmt1   = $data->{mgmt1};
  my $sn1     = $data->{sn1};
  my $iface1  = $data->{iface1};
  my $ip1     = $data->{ip1};

  # B端设备信息
  my $device2 = $data->{device2};
  my $mgmt2   = $data->{mgmt2};
  my $sn2     = $data->{sn2};
  my $iface2  = $data->{iface2};
  my $ip2     = $data->{ip2};

  # 接口通用属性
  my $is_aggr  = $data->{is_aggr};
  my $aggr_id  = $data->{aggr_id};
  my $is_trunk = $data->{is_trunk};
  my $vlan_id  = $data->{vlan_id};
  my $is_l3    = $data->{is_l3};

  # 是否网络设备 网络设备需要同时生成 AB端 交换机的配置
  my $is_network = $data->{is_network};

  # 初始化变量
  my ($cfg1, $cfg2);

  # CELL 填写成员端口可能有多个
  my $i = 0;
  my $j = 0;

  # 物理口实际配置
  my @iface1 = split(/,|;/, $iface1);
  my @iface2 = split(/,|;/, $iface2);

  # 早期异常拦截
  return unless $is_l3 and $ip1 and $ip2;
  return unless @iface1;
  return unless @iface2;
  return if @iface1 != @iface2;

  # 如果是网络设备同时生成双边交换机配置
  if ($is_network =~ /Y|是/i) {
    if ($is_aggr =~ /Y|是/i and !!$aggr_id) {
      push @{$cfg2}, "interface Bridge-Aggregation $aggr_id";
      push @{$cfg2}, "  description TO_" . ($sn1 // $device1) . "_" . ($iface1 // $ip1);
      push @{$cfg2}, "  undo shutdown";

      if ($is_l3 =~ /Y|是/i and !!$ip2) {
        push @{$cfg2}, "  no switchport";
        push @{$cfg2}, "  ip address $ip2";
      }
      else {
        my $vlans = join(",", split(/,|;/, $vlan_id));
        push @{$cfg2}, "  spanning-tree port type network";
        if ($is_trunk =~ /Y|是/i) {
          push @{$cfg2}, "  port link-type trunk";
          push @{$cfg2}, "  port trunk permit vlan $vlans" if !!$vlans;
        }
        else {
          push @{$cfg2}, "  port link-type access";
          push @{$cfg2}, "  port access vlan $vlan_id";
        }
      }
    }

    # 物理口实际配置
    foreach my $iface (@iface2) {
      push @{$cfg2}, "interface $iface";
      push @{$cfg2}, "  description TO_" . ($sn1 // $device1) . "_" . $iface1[$i];
      push @{$cfg2}, "  port link-aggregation group $aggr_id" if $is_aggr and $aggr_id;
      push @{$cfg2}, "  undo shutdown";

      if ($is_l3 =~ /Y|是/i and !!$ip2) {
        push @{$cfg2}, "  no switchport";
        push @{$cfg2}, "  ip address $ip2" unless $is_aggr and $aggr_id;
      }
      else {
        push @{$cfg2}, "  spanning-tree port type network";
        my $vlans = join(",", split(/,|;/, $vlan_id));
        if ($is_trunk =~ /Y|是/i) {
          push @{$cfg2}, "  port link-type trunk";
          push @{$cfg2}, "  port trunk permit vlan $vlans" if !!$vlans;
        }
        else {
          push @{$cfg2}, "  port link-type access";
          push @{$cfg2}, "  port access vlan $vlan_id";
        }
      }
      push @{$cfg2}, "!";
      $i++;
    }
  }

  # 正常情况只关注交换机侧的配置
  if ($is_aggr =~ /Y|是/i and !!$aggr_id) {
    push @{$cfg1}, "interface Bridge-Aggregation $aggr_id";
    push @{$cfg1}, "  description TO_" . ($sn2 // $device2) . "_" . ($iface2 // $ip2);
    push @{$cfg1}, "  undo shutdown";

    if ($is_l3 =~ /Y|是/i and !!$ip1) {
      push @{$cfg1}, "  no switchport";
      push @{$cfg1}, "  ip address $ip1";
    }
    else {
      my $vlans = join(",", split(/,|;/, $vlan_id));
      push @{$cfg1}, "  spanning-tree port type network";
      if ($is_trunk =~ /Y|是/i) {
        push @{$cfg1}, "  port link-type trunk";
        push @{$cfg1}, "  port trunk permit vlan $vlans" if !!$vlans;
      }
      else {
        push @{$cfg1}, "  port link-type access";
        push @{$cfg1}, "  port access vlan $vlan_id";
      }
    }
  }

  # 物理口实际配置
  foreach my $iface (@iface1) {
    push @{$cfg1}, "interface $iface";
    push @{$cfg1}, "  description TO_" . ($sn2 // $device2) . "_" . $iface2[$j];
    push @{$cfg1}, "  port link-aggregation group $aggr_id" if $is_aggr and $aggr_id;
    push @{$cfg1}, "  undo shutdown";

    if ($is_l3 =~ /Y|是/i and !!$ip1) {
      push @{$cfg1}, "  no switchport";
      push @{$cfg1}, "  ip address $ip1" unless $is_aggr and $aggr_id;
    }
    else {
      push @{$cfg1}, "  spanning-tree port type network";
      my $vlans = join(",", split(/,|;/, $vlan_id));
      if ($is_trunk =~ /Y|是/i) {
        push @{$cfg1}, "  port link-type trunk";
        push @{$cfg1}, "  port trunk permit vlan  $vlans" if !!$vlans;
      }
      else {
        push @{$cfg1}, "  port link-type access";
        push @{$cfg1}, "  port access vlan $vlan_id";
      }
    }
    push @{$cfg1}, "#";
    $j++;
  }

  # 返回计算结果
  my $index1 = $device1 . "-" . $mgmt1;
  my $index2 = $device2 . "-" . $mgmt2;
  my $port1  = $cfg1                   ? [$index1, $cfg1] : undef;
  my $port2  = ($is_network and $cfg2) ? [$index2, $cfg2] : undef;
  return ([$port1, $port2]);
}

#------------------------------------------------------------------------------
# 自动读取 EXCEL 并结构化输出端口配置
#------------------------------------------------------------------------------
sub portManager {
  my $file = shift;
  my $data = parseExcel($file);

  my $result;

  # 遍历已有的端口信息
  foreach my $port (@{$data}) {
    my $cfg = openCiscoPort($port);
    if (!!$cfg) {
      if ($cfg->[0] and $cfg->[0][1]) {
        push @{$result->{$cfg->[0][0]}}, "!";
        push @{$result->{$cfg->[0][0]}}, @{$cfg->[0][1]};
      }
      if ($cfg->[1] and $cfg->[1][1]) {
        push @{$result->{$cfg->[1][0]}}, "!";
        push @{$result->{$cfg->[1][0]}}, @{$cfg->[1][1]};
      }
    }
    else {
      say "交换机端口配置生成异常，请检查EXCEL行 $port->{line} 的单元格配置";
    }
  }

  # 返回计算结果
  return $result;
}

#------------------------------------------------------------------------------
# 自动读取 EXCEL 并结构化输出端口配置
#------------------------------------------------------------------------------
sub writePortConfig {
  my $file = shift;
  my $data = portManager($file);

  # 遍历数据写入文本
  foreach my $item (keys %{$data}) {
    my $name = $item . ".txt";
    my $cfg  = join("\n", @{$data->{$item}});
    write_text($name, $cfg);
  }

  say "Job done!";
}

1;
