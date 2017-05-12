#
# $Id: Frame.pm 2002 2015-02-15 16:50:35Z gomor $
#
package Net::Packet::Frame;
use warnings;
use strict;
use Carp;

require Class::Gomor::Array;
our @ISA = qw(Class::Gomor::Array);

require Net::Packet::Dump;
require Net::Packet::ETH;
require Net::Packet::ARP;
require Net::Packet::IPv4;
require Net::Packet::IPv6;
require Net::Packet::TCP;
require Net::Packet::UDP;
require Net::Packet::ICMPv4;
require Net::Packet::Layer7;
require Net::Packet::NULL;
require Net::Packet::PPPoE;
require Net::Packet::PPP;
require Net::Packet::LLC;
require Net::Packet::PPPLCP;
require Net::Packet::CDP;
require Net::Packet::STP;
require Net::Packet::OSPF;
require Net::Packet::IGMPv4;
require Net::Packet::RAW;
require Net::Packet::SLL;
require Net::Packet::VLAN;

use Time::HiRes qw(gettimeofday);
use Net::Packet::Env qw($Env);
use Net::Packet::Consts qw(:dump :layer :arp);

our @AS = qw(
   env
   raw
   l2
   l3
   l4
   l7
   reply
   timestamp
   encapsulate
   padding
);
__PACKAGE__->cgBuildIndices;
__PACKAGE__->cgBuildAccessorsScalar(\@AS);

no strict 'vars';

sub _gettimeofday {
   my ($sec, $usec) = gettimeofday();
   sprintf("%d.%06d", $sec, $usec);
}

sub new {
   my $self = shift->SUPER::new(
      timestamp   => _gettimeofday(),
      env         => $Env,
      encapsulate => NP_LAYER_UNKNOWN,
      @_,
   );

   my $env = $self->[$__env];

   if (! $env->noFrameAutoDesc && ! $env->desc) {
      if ($self->[$__l2]) {
         require Net::Packet::DescL2;
         $env->desc(Net::Packet::DescL2->new);
         $self->cgDebugPrint(1, "DescL2 object created");
      }
      elsif ($self->[$__l3]) {
         require Net::Packet::DescL3;
         $env->desc(Net::Packet::DescL3->new(
            target => $self->[$__l3]->dst,
         ));
         $self->cgDebugPrint(1, "DescL3 object created");
      }
      elsif ($self->[$__l4]) {
         confess("@{[(caller(0))[3]]}: you must manually create a DescL4 ".
                 "object\n");
      }
   }

   if (! $env->noFrameAutoDump && ! $env->dump) {
      my $getFilter;
      my $dumpFilter = ($env->dump && $env->dump->filter);
      if ($dumpFilter || ($getFilter = $self->getFilter)) {
         require Net::Packet::Dump;
         $env->dump(
            Net::Packet::Dump->new(
               filter => $dumpFilter || $getFilter,
            ),
         );
         $self->cgDebugPrint(1, "Dump object created");
      }
   }

   $self->[$__raw] ? $self->unpack : $self->pack;
}

sub getLengthFromL7 {
   my $self = shift;
   $self->[$__l7] ? $self->[$__l7]->getLength : 0;
}
sub getLengthFromL4 {
   my $self = shift;
   my $len  = 0;
   $len    += $self->[$__l4]->getLength if $self->[$__l4];
   $len    += $self->getLengthFromL7;
   $len || 0;
}
sub getLengthFromL3 {
   my $self = shift;
   my $len  = 0;
   $len    += $self->[$__l3]->getLength if $self->[$__l3];
   $len    += $self->getLengthFromL4;
   $len || 0;
}
sub getLengthFromL2 {
   my $self = shift;
   my $len  = 0;
   $len    += $self->[$__l2]->getLength if $self->[$__l2];
   $len    += $self->getLengthFromL3;
   $len || 0;
}
sub getLength { shift->getLengthFromL3 }

my $whichLink = {
   NP_LAYER_ETH()    =>
      sub { Net::Packet::ETH->new(raw => shift())    },
   NP_LAYER_NULL()   =>
      sub { Net::Packet::NULL->new(raw => shift())   },
   NP_LAYER_RAW()    =>
      sub { Net::Packet::RAW->new(raw => shift())    },
   NP_LAYER_SLL()    =>
      sub { Net::Packet::SLL->new(raw => shift())    },
   NP_LAYER_ARP()    =>
      sub { Net::Packet::ARP->new(raw => shift())    },
   NP_LAYER_IPv4()   =>
      sub { Net::Packet::IPv4->new(raw => shift())   },
   NP_LAYER_IPv6()   =>
      sub { Net::Packet::IPv6->new(raw => shift())   },
   NP_LAYER_VLAN()   =>
      sub { Net::Packet::VLAN->new(raw => shift())   },
   NP_LAYER_TCP()    =>
      sub { Net::Packet::TCP->new(raw => shift())    },
   NP_LAYER_UDP()    =>
      sub { Net::Packet::UDP->new(raw => shift())    },
   NP_LAYER_ICMPv4() =>
      sub { Net::Packet::ICMPv4->new(raw => shift()) },
   NP_LAYER_PPPoE()  =>
      sub { Net::Packet::PPPoE->new(raw => shift())  },
   NP_LAYER_PPP()    =>
      sub { Net::Packet::PPP->new(raw => shift())    },
   NP_LAYER_LLC()    =>
      sub { Net::Packet::LLC->new(raw => shift())    },
   NP_LAYER_PPPLCP() =>
      sub { Net::Packet::PPPLCP->new(raw => shift()) },
   NP_LAYER_CDP()    =>
      sub { Net::Packet::CDP->new(raw => shift())    },
   NP_LAYER_STP()    =>
      sub { Net::Packet::STP->new(raw => shift())    },
   NP_LAYER_OSPF()   =>
      sub { Net::Packet::OSPF->new(raw => shift())   },
   NP_LAYER_IGMPv4() =>
      sub { Net::Packet::IGMPv4->new(raw => shift()) },
   NP_LAYER_7()      =>
      sub { Net::Packet::Layer7->new(raw => shift()) },
};

my $mapNum = {
   'L?' => 0,
   'L2' => 2,
   'L3' => 3,
   'L4' => 4,
   'L7' => 7,
};

sub unpack {
   my $self = shift;

   my $encapsulate = $self->[$__encapsulate];

   if ($encapsulate eq NP_LAYER_UNKNOWN) {
      print("Unable to unpack Frame from this layer type, ".
            "not yet implemented (maybe should be in Dump)\n");
      return undef;
   }

   my $doMemoryOptimizations = $self->[$__env]->doMemoryOptimizations;

   my @frames;
   my $prev;
   my $n = 0;
   my $raw  = $self->[$__raw];
   my $rawLength = length($raw);
   my $oRaw = $raw;
   # No more than a thousand nested layers, maybe should be an Env param
   for (1..1000) {
      last unless $raw;

      my $l = $whichLink->{$encapsulate}($raw);

      $encapsulate = $l->encapsulate;
      $raw         = $l->payload;

      if ($doMemoryOptimizations) {
         $l->raw(undef);
         $l->payload(undef);
         $l = $l->cgClone;
      }

      # Frame creation handling
      if ($prev && $mapNum->{$l->layer} <= $mapNum->{$prev->layer}) {
         $n++;
      }
      $prev = $l;

      unless ($frames[$n]) {
         $frames[$n] = Net::Packet::Frame->new;
         $frames[$n]->[$__raw] = $oRaw;

         # We strip the payload for last layer of previously built frame, 
         # because it is now analyzed within the new frame
         my $m = $n - 1;
         if ($m >= 0) {
            if ($frames[$m]->[$__l7])    { $frames[$m]->[$__l7]->payload(undef)}
            elsif ($frames[$m]->[$__l4]) { $frames[$m]->[$__l4]->payload(undef)}
            elsif ($frames[$m]->[$__l3]) { $frames[$m]->[$__l3]->payload(undef)}
            elsif ($frames[$m]->[$__l2]) { $frames[$m]->[$__l2]->payload(undef)}
         }
      }
      if    ($l->isLayer2) { $frames[$n]->[$__l2] = $l }
      elsif ($l->isLayer3) { $frames[$n]->[$__l3] = $l }
      elsif ($l->isLayer4) { $frames[$n]->[$__l4] = $l }
      elsif ($l->isLayer7) { $frames[$n]->[$__l7] = $l }
      # / Frame creation handling

      if ($encapsulate eq NP_LAYER_UNKNOWN) {
         print("Unable to unpack next Layer, not yet implemented in Layer: ".
               "$n:@{[$l->is]}\n");
         last;
      }

      last if $encapsulate eq NP_LAYER_NONE;

      $oRaw = $raw;
   }

   $frames[-1]->_getPadding($rawLength);

   $self->[$__env]->doFrameReturnList ? \@frames : $frames[0];
}

sub pack {
   my $self = shift;

   my $env = $self->[$__env];
   my $l2  = $self->[$__l2];
   my $l3  = $self->[$__l3];
   my $l4  = $self->[$__l4];
   my $l7  = $self->[$__l7];

   my $noChecksums = $env->noFrameComputeChecksums;
   my $noLengths   = $env->noFrameComputeLengths;
   if (! $noChecksums && ! $noLengths) {
      if ($l2) {
         $l2->computeLengths($env, $l2, $l3, $l4, $l7)   or return undef;
         $l2->computeChecksums($env, $l2, $l3, $l4, $l7) or return undef;
         $l2->pack or return undef;
      }
      if ($l3) {
         $l3->computeLengths($env, $l2, $l3, $l4, $l7)   or return undef;
         $l3->computeChecksums($env, $l2, $l3, $l4, $l7) or return undef;
         $l3->pack or return undef;
      }
      if ($l4) {
         $l4->computeLengths($env, $l2, $l3, $l4, $l7)   or return undef;
         $l4->computeChecksums($env, $l2, $l3, $l4, $l7) or return undef;
         $l4->pack or return undef;
      }
      if ($l7) {
         $l7->computeLengths($env, $l2, $l3, $l4, $l7)   or return undef;
         $l7->computeChecksums($env, $l2, $l3, $l4, $l7) or return undef;
         $l7->pack or return undef;
      }
   }
   elsif (! $noChecksums && $noLengths) {
      if ($l2) {
         $l2->computeChecksums($env, $l2, $l3, $l4, $l7) or return undef; 
         $l2->pack or return undef;
      }
      if ($l3) {
         $l3->computeChecksums($env, $l2, $l3, $l4, $l7) or return undef;
         $l3->pack or return undef;
      }
      if ($l4) {
         $l4->computeChecksums($env, $l2, $l3, $l4, $l7) or return undef;
         $l4->pack or return undef;
      }
      if ($l7) {
         $l7->computeChecksums($env, $l2, $l3, $l4, $l7) or return undef;
         $l7->pack or return undef;
      }
   }
   else {
      if ($l2) { $l2->pack or return undef }
      if ($l3) { $l3->pack or return undef }
      if ($l4) { $l4->pack or return undef }
      if ($l7) { $l7->pack or return undef }
   }


   my $raw;
   $raw .= $self->[$__l2]->raw if $self->[$__l2];
   $raw .= $self->[$__l3]->raw if $self->[$__l3];
   $raw .= $self->[$__l4]->raw if $self->[$__l4];
   $raw .= $self->[$__l7]->raw if $self->[$__l7];
   $raw .= $self->[$__padding] if $self->[$__padding];

   if ($raw) {
      $self->[$__raw] = $raw;
      $self->_padFrame unless $env->noFramePadding;
   }

   if ($env->doMemoryOptimizations) {
      if ($self->[$__l2]) {
         $self->[$__l2]->raw(undef);
         $self->[$__l2]->payload(undef);
         $self->[$__l2] = $self->[$__l2]->cgClone;
      }
      if ($self->[$__l3]) {
         $self->[$__l3]->raw(undef);
         $self->[$__l3]->payload(undef);
         $self->[$__l3] = $self->[$__l3]->cgClone;
      }
      if ($self->[$__l4]) {
         $self->[$__l4]->raw(undef);
         $self->[$__l4]->payload(undef);
         $self->[$__l4] = $self->[$__l4]->cgClone;
      }
      if ($self->[$__l7]) {
         $self->[$__l7]->raw(undef);
         $self->[$__l7]->payload(undef);
         $self->[$__l7] = $self->[$__l7]->cgClone;
      }
   }

   $self;
}

sub _padFrame {
   my $self = shift;

   # Pad this frame, if sent from layer 2
   if ($self->[$__l2]) {
      my $rawLength = length($self->[$__raw]);
      if ($rawLength < 60) {
         my $padding = ('G' x (60 - $rawLength));
         $self->[$__raw] = $self->[$__raw].$padding;
      }
   }
}

sub _getPadding {
   my $self = shift;
   my ($rawLength) = @_;

   my $thisLength = length($self->[$__raw]);

   # There is a chance this is a memory bug to align with 60 bytes
   # We check it to see if it is true Layer7, or just a padding
   if ($self->[$__l7] && $thisLength == 60
   &&  $self->[$__l3] && $self->[$__l4]) {
      my $pLen = $self->[$__l3]->getPayloadLength;
      my $nLen = $self->[$__l4]->getLength;
      if ($pLen == $nLen) {
         $self->[$__padding] = $self->[$__l7]->data;
         $self->[$__l7]      = undef;
      }
      return 1;
   }

   # No padding
   return 1 if $rawLength > 60;

   my $len     = $self->getLengthFromL2;
   my $padding = substr($self->[$__raw], $len, $rawLength - $len);
   $self->[$__padding] = $padding;
}

sub send {
   my $self = shift;

   my $env = $self->[$__env];

   if ($env->dump && ! $env->dump->isRunning) {
      $env->dump->start;
      $self->cgDebugPrint(1, "Dump object started");
   }

   if ($env->debug >= 3) {
      if ($self->isEth) {
         $self->cgDebugPrint(3,
            "send: l2: type:". sprintf("0x%x", $self->l2->type). ", ".
            "@{[$self->l2->src]} => @{[$self->l2->dst]}"
         );
      }

      if ($self->isIp) {
         $self->cgDebugPrint(3,
            "send: l3: protocol:@{[$self->l3->protocol]}, ".
            "size:@{[$self->getLength]}, ".
            "@{[$self->l3->src]} => @{[$self->l3->dst]}"
         );
      }
      elsif ($self->isArp) {
         $self->cgDebugPrint(3,
            "send: l3: @{[$self->l3->src]} => @{[$self->l3->dst]}"
         );
      }

      if ($self->isTcp || $self->isUdp) {
         $self->cgDebugPrint(3,
            "send: l4: @{[$self->l4->is]}, ".
            "@{[$self->l4->src]} => @{[$self->l4->dst]}"
         );
      }
   }

   $self->[$__timestamp] = _gettimeofday();
   if ($env->desc) {
      $env->desc->send($self->[$__raw]);
   }
   else {
      carp("@{[(caller(0))[3]]}: no Desc open, can't send Frame\n");
      return undef;
   }
   1;
}

sub reSend { my $self = shift; $self->send unless $self->[$__reply] }

sub getFilter {
   my $self = shift;

   my $filter;

   # L4 filtering
   if ($self->[$__l4]) {
      if ($self->isTcp) {
         $filter .= "(tcp and".
                    " src port @{[$self->[$__l4]->dst]}".
                    " and dst port @{[$self->[$__l4]->src]})";
      }
      elsif ($self->isUdp) {
         $filter .= "(udp and".
                    " src port @{[$self->[$__l4]->dst]}".
                    " and dst port @{[$self->[$__l4]->src]})";
      }
      elsif ($self->isIcmpv4) {
         $filter .= "(icmp)";
      }
      $filter .= " or icmp";
   }

   # L3 filtering
   if ($self->[$__l3]) {
      $filter .= " and " if $filter;

      if ($self->isIpv4) {
         $filter .= "(src host @{[$self->[$__l3]->dst]}".
                    " and dst host @{[$self->[$__l3]->src]}) ".
                    " or ".
                    "(icmp and dst host @{[$self->[$__l3]->src]})";
      }
      elsif ($self->isIpv6) {
         $filter .= "(ip6 and src host @{[$self->[$__l3]->dst]}".
                    " and dst host @{[$self->[$__l3]->src]})";
      }
      elsif ($self->isArp) {
         $filter .= "(arp and src host @{[$self->[$__l3]->dstIp]}".
                    " and dst host @{[$self->[$__l3]->srcIp]})";
      }
   }
    
   $filter;
}

sub recv {
   my $self = shift;

   $self->[$__env]->dump->nextAll if $self->[$__env]->dump->isRunning;

   # We already have the reply
   return undef if $self->[$__reply];

   croak("@{[(caller(0))[3]]}: \$self->env->dump variable not set\n")
      unless $self->[$__env]->dump;

   if ($self->[$__l4] && $self->[$__l4]->can('recv')) {
      $self->[$__reply] = $self->[$__l4]->recv($self);
   }
   elsif ($self->[$__l3] && $self->[$__l3]->can('recv')) {
      $self->[$__reply] = $self->[$__l3]->recv($self);
   }
   else {
      carp("@{[(caller(0))[3]]}: not implemented for this Layer\n");
      return undef;
   }

   $self->[$__reply]
      ? do { $self->cgDebugPrint(1, "Reply received"); return $self->[$__reply]}
      : return undef;
}

sub print {
   my $self = shift;
   my $str = '';
   $str .= $self->[$__l2]->print."\n" if $self->[$__l2];
   $str .= $self->[$__l3]->print."\n" if $self->[$__l3];
   $str .= $self->[$__l4]->print."\n" if $self->[$__l4];
   $str .= $self->[$__l7]->print."\n" if $self->[$__l7];

   $str =~ s/\n$//s;

   # Print remaining to be decoded, if any
   if ($self->[$__l7]) {
      $str .= "\n".'L7: payload:'.CORE::unpack('H*', $self->[$__l7]->payload)
         if $self->[$__l7]->payload;
   }
   elsif ($self->[$__l4]) {
      $str .= "\n".'L4: payload:'.CORE::unpack('H*', $self->[$__l4]->payload)
         if $self->[$__l4]->payload;
   }
   elsif ($self->[$__l3]) {
      $str .= "\n".'L3: payload:'.CORE::unpack('H*', $self->[$__l3]->payload)
         if $self->[$__l3]->payload;
   }
   elsif ($self->[$__l2]) {
      $str .= "\n".'L2: payload:'.CORE::unpack('H*', $self->[$__l2]->payload)
         if $self->[$__l2]->payload;
   }

   # Print the padding, if any
   if ($self->[$__padding]) {
      $str .= "\n".'Padding: '.CORE::unpack('H*', $self->[$__padding]);
   }

   $str;
}

sub dump {
   my $self = shift;
   my $str = '';
   $str .= $self->[$__l2]->dump."\n" if $self->[$__l2];
   $str .= $self->[$__l3]->dump."\n" if $self->[$__l3];
   $str .= $self->[$__l4]->dump."\n" if $self->[$__l4];
   $str .= $self->[$__l7]->dump."\n" if $self->[$__l7];
   if ($self->[$__padding]) {
      $str .= 'Padding: '.CORE::unpack('H*', $self->[$__padding])."\n";
   }
   $str;
}

#
# Helpers
#

sub _isL2 { my $self = shift; $self->[$__l2] && $self->[$__l2]->is eq shift() }
sub _isL3 { my $self = shift; $self->[$__l3] && $self->[$__l3]->is eq shift() }
sub _isL4 { my $self = shift; $self->[$__l4] && $self->[$__l4]->is eq shift() }
sub _isL7 { my $self = shift; $self->[$__l7] && $self->[$__l7]->is eq shift() }
sub isEth    { shift->_isL2(NP_LAYER_ETH)    }
sub isRaw    { shift->_isL2(NP_LAYER_RAW)    }
sub isNull   { shift->_isL2(NP_LAYER_NULL)   }
sub isSll    { shift->_isL2(NP_LAYER_SLL)    }
sub isPpp    { shift->_isL2(NP_LAYER_PPP)    }
sub isArp    { shift->_isL3(NP_LAYER_ARP)    }
sub isIpv4   { shift->_isL3(NP_LAYER_IPv4)   }
sub isIpv6   { shift->_isL3(NP_LAYER_IPv6)   }
sub isVlan   { shift->_isL3(NP_LAYER_VLAN)   }
sub isPppoe  { shift->_isL3(NP_LAYER_PPPoE)  }
sub isLlc    { shift->_isL3(NP_LAYER_LLC)    }
sub isTcp    { shift->_isL4(NP_LAYER_TCP)    }
sub isUdp    { shift->_isL4(NP_LAYER_UDP)    }
sub isIcmpv4 { shift->_isL4(NP_LAYER_ICMPv4) }
sub isPpplcp { shift->_isL4(NP_LAYER_PPPLCP) }
sub isCdp    { shift->_isL4(NP_LAYER_CDP)    }
sub isStp    { shift->_isL4(NP_LAYER_STP)    }
sub isOspf   { shift->_isL4(NP_LAYER_OSPF)   }
sub isIgmpv4 { shift->_isL4(NP_LAYER_IGMPv4) }
sub is7      { shift->_isL7(NP_LAYER_7)      }
sub isIp     { my $self = shift; $self->isIpv4 || $self->isIpv6 }
sub isIcmp   { my $self = shift; $self->isIcmpv4 } # XXX: || v6

1;

__END__

=head1 NAME

Net::Packet::Frame - object encapsulator for Net::Packet layers

=head1 SYNOPSIS

   require Net::Packet::Frame;

   # Because we passed a layer 3 object, a Net::Packet::DescL3 object 
   # will be created automatically, by default. See Net::Packet::Env 
   # regarding changing this behaviour. Same for Net::Packet::Dump.
   my $frame = Net::Packet::Frame->new(
      l3 => $ipv4,  # Net::Packet::IPv4 object
      l4 => $tcp,   # Net::Packet::TCP object
                    # (here, a SYN request, for example)
   );

   # Without retries
   $frame->send;
   sleep(3);
   if (my $reply = $frame->recv) {
      print $reply->l3->print."\n";
      print $reply->l4->print."\n";
   }

   # Or with retries
   for (1..3) {
      $frame->reSend;

      until ($Env->dump->timeout) {
         if (my $reply = $frame->recv) {
            print $reply->l3->print."\n";
            print $reply->l4->print."\n";
            last;
         }
      }
   }

=head1 DESCRIPTION

In B<Net::Packet>, each sent and/or received frame is parsed and converted into a B<Net::Packet::Frame> object. Basically, it encapsulates various layers (2, 3, 4 and 7) into an object, making it easy to get or set information about it.

When you create a frame object, a B<Net::Packet::Desc> object is created if none is found in the default B<$Env> object (from B<Net::Packet> module), and a B<Net::Packet::Dump> object is also created if none is found in this same B<$Env> object. You can change this beheaviour, see B<Net::Packet::Env>.

Two B<new> invocation method exist, one with attributes passing, another with B<raw> attribute. This second method is usually used internally, in order to unpack received frame into all corresponding layers.

=head1 ATTRIBUTES

=over 4

=item B<env>

Stores the B<Net::Packet::Env> object. The default is to use B<$Env> from B<Net::Packet>. So, you can send/recv frames to/from different environements.

=item B<raw>

Pass this attribute when you want to decode a raw string captured from network. Usually used internally.

=item B<padding>

In Ethernet world, a frame should be at least 60 bytes in length. So when you send frames at layer 2, a padding is added in order to achieve this length, avoiding a local memory leak to network. Also, when you receive a frame from network, this attribute is filled with what have been used to pad it. This padding feature currently works for IPv4 and ARP frames.

=item B<l2>

Stores a layer 2 object. See B<Net::Packet> for layer 2 classes hierarchy.

=item B<l3>

Stores a layer 3 object. See B<Net::Packet> for layer 3 classes hierarchy.

=item B<l4>

Stores a layer 4 object. See B<Net::Packet> for layer 4 classes hierarchy.

=item B<l7>

Stores a layer 7 object. See B<Net::Packet::Layer7>.

=item B<reply>

When B<recv> method has been called on a frame object, and a corresponding reply has been catched, a pointer is stored in this attribute.

=item B<timestamp>

When a frame is packed/unpacked, the happening time is stored here.

=item B<encapsulate>

Give the type of the first encapsulated layer. It is a requirement to parse a user provided raw string.

=back

=head1 METHODS

=over 4

=item B<new>

Object constructor. If a B<$Env->desc> object does not exists, one is created by analyzing attributes (so, either one of B<Net::Packet::DescL2>, B<Net::Packet::DescL3>. B<Net::Packet::DescL4> cannot be created automatically for now). The same behaviour is true for B<$Env->dump> object. You can change this default creation behaviour, see B<Net::Packet::Env>. Default values:

timestamp: gettimeofday(),

env:       $Env

=item B<getLengthFromL7>

=item B<getLengthFromL4>

=item B<getLengthFromL3>

=item B<getLengthFromL2>

Returns the raw length in bytes from specified layer.

=item B<getLength>

Alias for B<getLengthFromL3>.

=item B<unpack>

Unpacks the raw string from network into various layers. Returns 1 on success, undef on failure.

=item B<pack>

Packs various layers into the raw string to send to network. Returns 1 on success, undef on failure.

=item B<send>

On the first send invocation in your program, the previously created B<Net::Packet::Dump> object is started (if available). That is, packet capturing is run. The B<timestamp> attribute is set to the sending time. The B<env> attribute is used to know where to send this frame.

=item B<reSend>

Will call B<send> method if no frame has been B<recv>'d, that is the B<reply> attribute is undef.

=item B<getFilter>

Will return a string which is a pcap filter, and corresponding to what you should receive compared with the frame request.

=item B<recv>

Searches B<framesSorted> or B<frames> from B<Net::Packet::Dump> for a matching response. If a reply has already been received (that is B<reply> attribute is already set), undef is returned. It no reply is received, return undef, else the B<Net::Packet::Frame> response.

=item B<print>

Just returns a string in a human readable format describing attributes found in the layer.

=item B<dump>

Just returns a string in hexadecimal format which is how the layer appears on the network.

=item B<isEth>

=item B<isRaw>

=item B<isNull>

=item B<isSll>

=item B<isPpp>

=item B<isArp>

=item B<isIpv4>

=item B<isIpv6>

=item B<isIp> - either IPv4 or IPv6

=item B<isPpplcp>

=item B<isVlan>

=item B<isPppoe>

=item B<isLlc>

=item B<isTcp>

=item B<isUdp>

=item B<isIcmpv4>

=item B<isIcmp> - currently only ICMPv4

=item B<isCdp>

=item B<isStp>

=item B<isOspf>

=item B<isIgmpv4>

=item B<is7>

Returns 1 if the B<Net::Packet::Frame> is of specified layer, 0 otherwise.

=back

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2004-2015, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of the Artistic license.
See LICENSE.Artistic file in the source distribution archive.

=head1 RELATED MODULES

L<NetPacket>, L<Net::RawIP>, L<Net::RawSock>

=cut
