#
# $Id: Intf.pm 57 2012-11-02 16:39:39Z gomor $
#
package Net::Libdnet::Entry::Intf;
use strict; use warnings;

use base qw(Class::Gomor::Array);

our @AS = qw(
   aliasNum
   mtu
   len
   type
   name
   dstAddr
   linkAddr
   flags
   addr
   ip
   subnet
   broadcast
   cidr
);
our @AA = qw(
   aliasAddrs
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);
__PACKAGE__->cgBuildAccessorsArray (\@AA);

use Net::Libdnet qw(:consts :obsolete);

sub new {
   my $self = shift->SUPER::new(
      aliasAddrs => [],
      @_,
   );
   return $self;
}

sub newFromHash {
   my $self = shift->SUPER::new;
   my ($h) = @_;
   $self->aliasNum  ($h->{intf_alias_num})   if defined($h->{intf_alias_num});
   $self->mtu       ($h->{intf_mtu})         if defined($h->{intf_mtu});
   $self->len       ($h->{intf_len})         if defined($h->{intf_len});
   $self->type      ($h->{intf_type})        if defined($h->{intf_type});
   $self->name      ($h->{intf_name})        if defined($h->{intf_name});
   $self->dstAddr   ($h->{intf_dst_addr})    if defined($h->{intf_dst_addr});
   $self->linkAddr  ($h->{intf_link_addr})   if defined($h->{intf_link_addr});
   $self->flags     ($h->{intf_flags})       if defined($h->{intf_flags});
   $self->aliasAddrs($h->{intf_alias_addrs}) if defined($h->{intf_alias_addrs});
   if (defined($h->{intf_addr})) {
      $self->addr($h->{intf_addr});
      $self->subnet(addr_net($h->{intf_addr}));
      $self->broadcast(addr_bcast($h->{intf_addr}));
      my ($ip, $cidr) = split('/', $h->{intf_addr});
      $self->ip($ip)     if defined($ip);
      $self->cidr($cidr) if defined($cidr);
   }
   return $self;
}

sub tohash {
   my $self = shift;

   my %hash;
   $hash{intf_alias_num}   = $self->aliasNum   if defined($self->aliasNum);
   $hash{intf_mtu}         = $self->mtu        if defined($self->mtu);
   $hash{intf_len}         = $self->len        if defined($self->len);
   $hash{intf_type}        = $self->type       if defined($self->type);
   $hash{intf_name}        = $self->name       if defined($self->name);
   $hash{intf_dst_addr}    = $self->dstAddr    if defined($self->dstAddr);
   $hash{intf_link_addr}   = $self->linkAddr   if defined($self->linkAddr);
   $hash{intf_flags}       = $self->flags      if defined($self->flags);
   $hash{intf_alias_addrs} = $self->aliasAddrs if defined($self->aliasAddrs);
   $hash{intf_addr}        = $self->addr       if defined($self->addr);

   return \%hash;
}

#
# Courtesy of Net::IPv4Addr
#
sub cidr2mask {
   my $self = shift;
   return unless $self->cidr;
   my $cidr = $self->cidr;
   return unless ($cidr > 0 && $cidr < 33);
   my $bits = '1'x$cidr.'0'x(32 - $cidr);
   return join(".", unpack('CCCC', pack('B*', $bits)));
}

#
# Courtesy of Net::IPv4Addr
#
sub mask2cidr {
   my $self = shift;
   my ($mask) = @_;
   return unless $mask;
   my @toks = split(/\./, $mask);
   return unless @toks == 4;
   my $cidr = 0;
   for (@toks) {
      my $bits = unpack('B*', pack('C', $_));
      $cidr += $bits =~ tr/1/1/;
   }
   return $cidr;
}

sub flags2string {
   my $self = shift;
   my $flags = $self->flags;
   my $buf = '';
   if ($flags & DNET_INTF_FLAG_UP)          { $buf .= "UP,"          }
   if ($flags & DNET_INTF_FLAG_LOOPBACK)    { $buf .= "LOOPBACK,"    }
   if ($flags & DNET_INTF_FLAG_POINTOPOINT) { $buf .= "POINTOPOINT," }
   if ($flags & DNET_INTF_FLAG_NOARP)       { $buf .= "NOARP,"       }
   if ($flags & DNET_INTF_FLAG_BROADCAST)   { $buf .= "BROADCAST,"   }
   if ($flags & DNET_INTF_FLAG_MULTICAST)   { $buf .= "MULTICAST,"   }
   $buf =~ s/,$//;
   return $buf;
}

sub print {
   my $self = shift;

   my $buf = sprintf("%s: flags=0x%02x<%s>",
      $self->name, $self->flags, $self->flags2string);
   if ($self->mtu != 0) {
      $buf .= sprintf(" mtu %d", $self->mtu);
   }
   $buf .= sprintf("\n");
   if ($self->addr && $self->dstAddr) {
      $buf .= sprintf("\taddr %s --> %s\n", $self->addr, $self->dstAddr);
   }
   elsif ($self->addr) {
      $buf .= sprintf("\taddr %s\n", $self->addr);
   }
   if ($self->ip) {
      $buf .= sprintf("\tip %s\n", $self->ip);
   }
   if ($self->subnet && $self->cidr) {
      $buf .= sprintf("\tsubnet %s - cidr %s [mask %s]\n",
         $self->subnet, $self->cidr, $self->cidr2mask);
   }
   if ($self->broadcast) {
      $buf .= sprintf("\tbroadcast %s\n", $self->broadcast);
   }
   if ($self->linkAddr) {
      $buf .= sprintf("\tlinkAddr %s\n", $self->linkAddr);
   }
   for ($self->aliasAddrs) {
      $buf .= sprintf("\talias %s\n", $_);
   }
   $buf =~ s/\n$//;

   return $buf;
}

1;

__END__

=head1 NAME

Net::Libdnet::Entry::Intf - Intf Entry object

=head1 SYNOPSIS

XXX

=head1 DESCRIPTION

XXX

=head1 METHODS

=over 4

=item B<new>

=item B<newFromHash>

=item B<cidr2mask>

=item B<flags2string>

=item B<mask2cidr>

=item B<print>

=item B<tohash>

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

You may distribute this module under the terms of the BSD license. See LICENSE file in the source distribution archive.

Copyright (c) 2008-2012, Patrice <GomoR> Auffret

=cut
