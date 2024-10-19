#!/usr/bin/env perl

use strict;
use warnings;
use v5.30;

use PDK::DBI::Pg;
use PDK::Device::H3c;
use PDK::Device::Cisco;
use PDK::Concern::Netdisco::H3c;
use PDK::Concern::Netdisco::Cisco;
use Data::Dumper;
use Data::Printer;

my $db_params
  = {host => '192.168.99.99', port => 5432, dbname => 'netdisco', user => 'netdisco', password => 'Cisc0123'};

my $dbi = PDK::DBI::Pg->new($db_params);

my $sql = <<SQL;
select name, ip, os
from device
SQL

my $devices = $dbi->execute($sql)->all;
say Dumper exploreTopologyJob($devices);

sub assignAttributes {
  my $items = shift;

  my $type = ref($items) || '';
  if ($type eq 'HASH') {
    $items = [$items];
  }
  elsif ($type ne 'ARRAY') {
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
    croak "设备属性必须包含 'ip' 和 'name' 属性" unless exists $item->{ip} && exists $item->{name};

    $item->{username} ||= $ENV{PDK_DEVICE_USERNAME};
    $item->{password} ||= $ENV{PDK_DEVICE_PASSWORD};

    my ($module) = grep { $item->{os} =~ $_ } keys %os_to_module;
    croak "暂不兼容的 OS：$item->{os}" unless !!$module;
    $item->{pdk_device_module} = $os_to_module{$module};

    $item->{name} =~ s/\..*$//;
  }

  warn("尝试自动装配 {pdk_device_module} 并修正设备主机名");

  return $type eq 'HASH' ? $items->[0] : $items;
}

sub exploreTopologyJob {
  my $devices = shift;

  try {
    $devices = ref($devices) eq 'ARRAY' ? $devices : [$devices];
    $devices = assignAttributes($devices);

    my $count = scalar(@{$devices});
    warn("开始任务：并行执行 ($count) 台设备的配置获取任务");
  }
  catch {
    croak "自动加载并装配模块抛出异常: $_";
  };

  my $pm = Parallel::ForkManager->new(10);

  my $queue = Thread::Queue->new();

  $pm->run_on_finish(sub {
    my (undef, undef, undef, undef, undef, $data) = @_;

    if (defined $data) {
      $queue->enqueue($data);
    }
  });

  foreach my $device (@{$devices}) {
    $pm->start and next;
    my $h3c    = PDK::Device::H3c->new(host => $device->{ip});
    my $nd     = PDK::Concern::Netdisco::H3c->new(device => $h3c);
    my $status = $nd->explore_topology();
    $pm->finish(0, $status);
  }
  $pm->wait_all_children;

  my $result = {success => [], fail => []};
  while (my $data = $queue->dequeue_nb()) {
    if ($data->{success}) {
      push $result->{success}, $data->{result};
    }
    else {
      push $result->{fail}, $data->{reason};
    }
  }

  return $result;
}
