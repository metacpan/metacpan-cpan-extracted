#!/usr/bin/env perl

use strict;
use warnings;
use v5.30;

use PDK::DBI::Pg;
use PDK::Device::H3c;
use PDK::Concern::H3c::Netdisco;
use Data::Dumper;
use Data::Printer;

# 测试数据库连接参数
my $db_params = {
  host     => '192.168.99.99',
  port     => 5432,
  dbname   => 'netdisco',
  user     => 'netdisco',
  password => 'Cisc0123'
};

my $dbi = PDK::DBI::Pg->new($db_params);

my $sql = <<SQL;
select name, ip, os
from device
SQL

my $devices = $dbi->execute($sql)->all;
say Dumper exploreTopologyJob($devices);

# 根据设备操作系统类型为每个设备分配相应的 PDK 设备模块
sub assignAttributes {
  my $items = shift;

  # 检查输入类型，并统一转换为数组引用
  my $type = ref($items) || '';
  if ($type eq 'HASH') {
    $items = [$items];
  } elsif ($type ne 'ARRAY') {
    croak "必须提供基于哈希对象的数组引用或单个哈希对象";
  }

  my %os_to_module = (
    qr/^Cisco|ios/i   => 'PDK::Device::Cisco',
    qr/^nx-os/i       => 'PDK::Device::Cisco::Nxos',
    qr/^PAN-OS/i      => 'PDK::Device::Paloalto',
    qr/^Radware/i     => 'PDK::Device::Radware',
    qr/^H3C|Comware/i => 'PDK::Device::H3c',
    qr/^Hillstone/i   => 'PDK::Device::Hillstone',
    qr/^junos/i       => 'PDK::Device::Juniper',
  );

  for my $item (@{$items}) {
    # 检查必需的属性
    croak "设备属性必须包含 'ip' 和 'name' 属性"
      unless exists $item->{ip} && exists $item->{name};

    # 设置默认用户名和密码
    $item->{username} ||= $ENV{PDK_DEVICE_USERNAME};
    $item->{password} ||= $ENV{PDK_DEVICE_PASSWORD};

    # 根据操作系统分配 PDK 设备模块
    my ($module) = grep { $item->{os} =~ $_ } keys %os_to_module;
    croak "暂不兼容的 OS：$item->{os}" unless !!$module;
    $item->{pdk_device_module} = $os_to_module{$module};

    # 修正设备主机名
    $item->{name} =~ s/\..*$//;
  }

  warn("尝试自动装配 {pdk_device_module} 并修正设备主机名");

  # 如果输入是单个哈希对象，返回单个处理后的对象，否则返回数组引用
  return $type eq 'HASH' ? $items->[0] : $items;
}

# 并行执行多个设备的配置获取任务
sub exploreTopologyJob {
  my $devices = shift;

  try {
    # 确保 $devices 始终是一个数组引用
    $devices = ref($devices) eq 'ARRAY' ? $devices : [$devices];
    $devices = assignAttributes($devices);

    my $count = scalar(@{$devices});
    warn("开始任务：并行执行 ($count) 台设备的配置获取任务");
  }
  catch {
    croak "自动加载并装配模块抛出异常: $_";
  };

  my $pm = Parallel::ForkManager->new(10);

  # 创建线程安全的队列用于存储结果
  my $queue = Thread::Queue->new();

  # 启用数据共享
  $pm->run_on_finish(sub {
    my (undef, undef, undef, undef, undef, $data) = @_;

    # 将数据添加到队列中，而不是直接修改共享数据
    if (defined $data) {
      $queue->enqueue($data);
    }
  });

  foreach my $device (@{$devices}) {
    $pm->start and next;
    my $h3c = PDK::Device::H3c->new( host => $device->{ip});
    my $nd = PDK::Concern::H3c::Netdisco->new(device => $h3c);
    my $status = $nd->explore_topology();
    $pm->finish(0, $status);
  }
  $pm->wait_all_children;

  # 在所有子进程完成后处理队列
  my $result = { success => [], fail => [] };
  while (my $data = $queue->dequeue_nb()) {
    if ($data->{success}) {
      push $result->{success}, $data->{result}
    } else {
      push $result->{fail}, $data->{reason}
    }
  }

  return $result;
}