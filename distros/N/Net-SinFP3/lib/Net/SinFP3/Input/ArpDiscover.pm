#
# $Id: ArpDiscover.pm,v 451c3602d7b2 2015/11/25 06:13:53 gomor $
#
package Net::SinFP3::Input::ArpDiscover;
use strict;
use warnings;

use base qw(Net::SinFP3::Input);
__PACKAGE__->cgBuildIndices;

use Net::SinFP3::Next::IpPort;

use Net::Libdnet::Arp;
use Net::Frame::Layer::ETH qw(:consts);
use Net::Frame::Layer::ARP qw(:consts);

sub give {
   return [
      'Net::SinFP3::Next::IpPort',
   ];
}

sub new {
   my $self = shift->SUPER::new(
      @_,
   );

   my $global = $self->global;
   my $log = $global->log;

   if (! defined($global->port)) {
      $log->fatal("You must provide a `port' attribute in Global object");
   }

   return $self;
}

sub _getArpPkt {
   my $self = shift;
   my ($ip) = @_;

   my $global = $self->global;

   my $eth = Net::Frame::Layer::ETH->new(
      type => NF_ETH_TYPE_ARP,
      src  => $global->mac,
   );
   my $arp = Net::Frame::Layer::ARP->new(
      opCode => NF_ARP_OPCODE_REQUEST,
      srcIp => $global->ip,
      dstIp => $ip,
      src   => $global->mac,
   );
   my $request = Net::Frame::Simple->new(
      layers => [ $eth, $arp ],
   );
   return $request;
}

sub _arpDiscover {
   my $self = shift;

   my $global = $self->global;
   my $log    = $global->log;

   my $cacheArp = $global->cacheArp;

   # We will also look in ARP cache table
   my $arp = Net::Libdnet::Arp->new;

   my @list   = ();
   my %reply  = ();
   my $ipList = ();
   # User want to overwrite default scanning option (local subnet)
   if ($global->target) {
      $ipList = $global->expandSubnet(subnet => $global->target);
   }
   else {
      $ipList = $global->expandSubnet(subnet => $global->subnet);
   }
   for my $ip (@$ipList) {
      # We scan ARP for everyone but our own IP
      next if $ip eq $global->ip;

      # XXX: move to Global so there is one place for ARP cache handling
      my $mac;
      if (defined($cacheArp->{$ip})) {
         $mac = $cacheArp->{$ip};
         $reply{$ip} = $mac;
      }
      elsif ($mac = $arp->get($ip)) {
         $log->verbose("Found $mac for $ip in ARP cache");
         $cacheArp->{$ip} = $mac;
         $reply{$ip} = $mac;
      }
      else {
         # If it is not in ARP cache yet
         push @list, $self->_getArpPkt($ip);
      }
   }

   my $oWrite = $global->getWriteL2 or return;
   $oWrite->open or return;

   my $oDump = $global->getDumpOnline(
      filter => 'arp',
   ) or return;
   $oDump->start or return;

   for my $t (1..3) {
      for my $r (@list) {
         my $dstIp = $r->ref->{ARP}->dstIp;
         $oWrite->send($r->raw) unless exists $reply{$dstIp};
      }
      until ($oDump->timeout) {
         if (my $h = $oDump->next) {
            my $r = Net::Frame::Simple->newFromDump($h);
            next unless $r->ref->{ARP}->opCode eq NF_ARP_OPCODE_REPLY;
            my $srcIp = $r->ref->{ARP}->srcIp;
            unless (exists $reply{$srcIp}) {
               my $mac = $r->ref->{ARP}->src;
               $log->info("Received $mac for $srcIp");
               $reply{$srcIp} = $r->ref->{ARP}->src;

               # Put it in ARP cache table
               $cacheArp->{$srcIp} = $mac;
            }
         }
      }
      $oDump->timeoutReset;
   }

   $oWrite->close;
   $oDump->stop;

   for (keys %reply) {
      $log->verbose(sprintf("%-16s => %s", $_, $reply{$_}));
   }

   return \%reply;
}

# http://tools.ietf.org/html/rfc2373
sub _mac2eui64 {
   my $self = shift;
   my ($mac) = @_;

   my @b  = split(':', $mac);
   my $b0 = hex($b[0]) ^ 2;

   return sprintf("fe80::%x%x:%xff:fe%x:%x%x", $b0, hex($b[1]), hex($b[2]),
      hex($b[3]), hex($b[4]), hex($b[5]));
}

sub init {
   my $self = shift->SUPER::init(@_) or return;

   my $global = $self->global;
   my $log = $global->log;

   my $ipMacList = $self->_arpDiscover;
   my $portList = $global->portList;

   my @nextList = ();
   for my $ip (keys %$ipMacList) {
      my $mac = $ipMacList->{$ip};
      if ($global->ipv6) {
         $log->debug("Converting MAC [$mac] to IPv6 with EUI64");
         $ip = $self->_mac2eui64($mac);
      }
      for my $port (@$portList) {
         push @nextList, Net::SinFP3::Next::IpPort->new(
            global => $self->global,
            ip => $ip,
            port => $port,
            mac => $mac,
         );
      }
   }
   $self->nextList(\@nextList);

   return 1;
}

sub run {
   my $self = shift->SUPER::run(@_) or return;

   my @nextList = $self->nextList;
   my $next     = shift @nextList;
   $self->nextList(\@nextList);

   return $next;
}

1;

__END__

=head1 NAME

Net::SinFP3::Input::ArpDiscover - object describing a SinFP target

=head1 DESCRIPTION

Go to http://www.metabrik.org/sinfp3/ to know more.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2011-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=cut
