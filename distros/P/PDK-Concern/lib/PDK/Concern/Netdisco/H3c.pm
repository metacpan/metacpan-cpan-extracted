package PDK::Concern::Netdisco::H3c;

use utf8;
use v5.30;
use Moose;
use Data::Dumper;
use namespace::autoclean;

with 'PDK::Concern::Netdisco::Role';

sub commands {
  my $self = shift;

  ['display lldp neighbor-information list | include GE'];
}

sub gen_iface_desc {
  my ($self, $topology) = @_;
  my @commands = ('system-view');

  foreach my $line (@{$topology}) {
    if ($line =~ /display/ || $line !~ /(S|X)?GE|Ethernet/i) {
      $self->dump("跳过不需要处理的行：$line");
      next;
    }

    my ($local_port, $chassis, $remote_port, $neighbor);

    if ($line =~ /^(S|X)?GE/) {
      ($local_port, $chassis, $remote_port, $neighbor) = split /\s+/, $line;
      $self->dump("匹配单行格式1：$line");
    }
    elsif ($line =~ /(S|X)?GE/) {
      ($neighbor, $local_port, $chassis, $remote_port) = split /\s+/, $line;
      $self->dump("匹配单行格式2：$line");
    }
    else {
      $self->dump("未匹配正则格式跳过解析：$line");
      warn("未匹配正则格式跳过解析：$line");
      next;
    }

    $self->dump("打印解析到的数据：\n" . Dumper($local_port, $neighbor, $remote_port));

    next if $remote_port !~ /eth|twe|ten|gig/i;

    $neighbor = "AP-${neighbor}" if $line =~ /Smartrate-Ethernet1\/0\/1/;
    $neighbor =~ s/(?:\.|\().*$//;

    $local_port  = $self->refine_if($local_port);
    $remote_port = $self->refine_if($remote_port);

    $remote_port =~ s/\s+//g;

    $remote_port = uc $remote_port;

    push @commands, ("interface $local_port", "description TO_${neighbor}_${remote_port}");
  }

  push @commands, ('quit', 'quit', 'save force');

  $self->dump("邻居拓扑解析完毕并生成接口描述脚本:\n" . Dumper @commands);

  return @commands;
}

__PACKAGE__->meta->make_immutable;
1;
