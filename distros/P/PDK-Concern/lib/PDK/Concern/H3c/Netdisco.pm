package PDK::Concern::H3c::Netdisco;

use v5.30;
use strict;
use warnings;
use Moose;

has device => (is => 'ro', isa => 'PDK::Device::H3c', required => 1,);

sub explore_topology {
  my ($self) = @_;

  my $device  = $self->device;
  my $command = ['display lldp neighbor-information list | include GE'];

  my $result = $device->execCommands($command);
  if ($result->{success}) {
    my @topology = split(/\n/, $result->{result});
    my @commands = $self->gen_iface_desc(\@topology);
    return $device->execCommands(\@commands);
  }
  else {
    return {success => 0, reason => $result->{reason}};
  }
}

sub gen_iface_desc {
  my ($self, $topology_data) = @_;
  my @commands = ('system-view');

  foreach my $line (@{$topology_data}) {
    next if $line =~ /^display/i;
    next if $line !~ /GE|XGE|Ethernet/i;

    my ($local_if, $chassis, $remote_if, $remote_dev);
    if ($line =~ /^X?GE/) {
      ($local_if, $chassis, $remote_if, $remote_dev) = split /\s+/, $line;
    }
    else {
      ($remote_dev, $local_if, $chassis, $remote_if) = split /\s+/, $line;
    }

    $local_if  = $self->refine_if($local_if);
    $remote_if = $self->refine_if($remote_if);

    push @commands, "interface $local_if";
    push @commands, "description TO_${remote_dev}_${remote_if}";
  }

  push @commands, ('quit', 'save force');

  return @commands;
}

sub refine_if {
  my ($self, $name) = @_;

  $name =~ s/TenGigabitEthernet/TE/g;
  $name =~ s/GigabitEthernet/GE/g;
  $name =~ s/Smartrate-Ethernet/SE/g;
  $name =~ s/Ethernet/Eth/g;
  $name =~ s/xethenet/X/gi;
  $name =~ s/mgmt0/MGMT0/g;

  return $name;
}

__PACKAGE__->meta->make_immutable;
1;
