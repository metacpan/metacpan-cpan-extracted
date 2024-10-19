package PDK::Concern::Netdisco::Cisco;

use v5.30;
use Moose;
use Data::Dumper;
use namespace::autoclean;

with 'PDK::Concern::Netdisco::Role';

sub commands {
  my $self = shift;

  ['show cdp neighbor | begin Device[- ]ID'];
}

sub gen_iface_desc {
  my ($self, $topology) = @_;
  my @commands = ('conf t');

  my ($neighbor, $local_port, $remote_port);
  my $partial_neighbor = '';
  my $need_concat      = 0;

  foreach my $line (@{$topology}) {
    if ($line =~ /show cdp neighbor|Total entries displayed|^\s*$|Device ID|^\S+#$/i) {
      $self->dump("跳过不需要处理的行：$line");
      next;
    }

    if (
      $line =~ /
                ^(\S+(?:\.\S+)*)           # 邻居设备名称（可能包含域名）
                \s+
                ((?:Eth|Gig|Ten|Twe|Fa|mgmt)\s*[\d\/]+)  # 本地端口
                \s+
                \d+                         # Holdtime（忽略）
                \s+
                (?:\S+\s+)*                 # Capability（忽略）
                \S+(?:\s+\S+)*              # Platform（忽略）
                \s+
                ((?:Eth|Gig|Ten|Twe|Fa|mgmt|e0M)\s*[\d\/]*)  # 远程端口
                \s*$
            /xi
      )
    {
      ($neighbor, $local_port, $remote_port) = ($1, $2, $3);
      $self->dump("匹配单行格式：$line");
    }
    elsif ($need_concat == 0 && $line =~ /^\S+\s*$/) {
      $partial_neighbor .= $line;
      $need_concat = 1;
      $self->dump("匹配多行格式：第一部分$line");
      next;
    }
    elsif (
         $need_concat == 1
      && $line =~ /
                ^\s+
                ((?:Eth|Gig|Ten|Twe|Fa|mgmt)\s*[\d\/]+)  # 本地端口
                \s+
                \d+                         # Holdtime（忽略）
                \s+
                (?:\S+\s+)*                 # Capability（忽略）
                \S+(?:\s+\S+)*              # Platform（忽略）
                \s+
                ((?:Eth|Gig|Ten|Twe|Fa|mgmt|e0M)\s*[\d\/]*)  # 远程端口
                \s*$
            /xi
      )
    {
      $neighbor = $partial_neighbor;
      ($local_port, $remote_port) = ($1, $2);
      $self->dump("匹配多行格式：第二部分$line");
    }
    else {
      $self->dump("未匹配正则格式跳过解析：$line");
      warn("未匹配正则格式跳过解析:$line");
      next;
    }

    $self->dump("打印解析到的数据：\n" . Dumper($local_port, $neighbor, $remote_port));

    next unless $neighbor && $local_port && $remote_port;

    $neighbor =~ s/(?:\.|\().*$//;

    $local_port  = $self->refine_if($local_port);
    $remote_port = uc $self->refine_if($remote_port);

    $remote_port =~ s/\s+//g;

    push @commands, ("interface $local_port", "description TO_${neighbor}_${remote_port}");

    ($neighbor, $local_port, $remote_port) = (undef, undef, undef);
    $partial_neighbor = '';
    $need_concat      = 0;
  }

  push @commands, ('end', 'copy run start');

  $self->dump("邻居拓扑解析完毕并生成接口描述脚本:\n" . Dumper @commands);

  return @commands;
}

__PACKAGE__->meta->make_immutable;
1;
