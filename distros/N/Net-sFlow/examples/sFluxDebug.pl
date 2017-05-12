#!/usr/bin/perl
#
#
# My first perl project ;)
# Elisa Jasinska <elisa.jasinska@ams-ix.net>
#
# sFluxDebug.pl - 2008/12/10
#
# Please send comments or bug reports to <sflow@ams-ix.net>
#
#
# Copyright (c) 2008 AMS-IX B.V.
#
# This package is free software and is provided "as is" without express 
# or implied warranty.  It may be used, redistributed and/or modified 
# under the terms of the Perl Artistic License (see
# http://www.perl.com/perl/misc/Artistic.html)
#

use strict;
use warnings;

# command line options
use Getopt::Std;

# to read a pcap file
use Net::Pcap;

# to decode the packet
use NetPacket::Ethernet;
use NetPacket::IP;
use NetPacket::UDP;

# sFlow module
use Net::sFlow;

# to listen to socket
use IO::Socket::INET;



#############################################################################

# options
my %options = ();

getopts("f:p:h", \%options)
  or &usage;


# print the help
&usage if $options{h};


# prepare arrays for print order
my $orderHashRef = &preparePrint;


# if switch -f read from pcap file
if (defined($options{f})) { 
  &readFile($orderHashRef); 
}


# else just open udp socket
else { 
  &listenPort($orderHashRef); 
}



#############################################################################
################################# sub's #####################################
#############################################################################


sub usage {

  print
    qq{usage: sFluxDebug.pl -h | -f filename | -p port
    -h          : this (help) message
    -f <file>   : read from pcap file <file>
    -p <port>   : listen to port <port>\n};
  exit;

}


#############################################################################


sub readFile {

  my $orderHashRef = shift;

  my $err = undef;

  my $pcap = Net::Pcap::open_offline($options{f}, \$err)
    or die "Can't read '$options{f}': $err\n";

  Net::Pcap::loop($pcap, 0, \&processPcap, $orderHashRef);
  Net::Pcap::close($pcap);
}


#############################################################################


# in case of a pcap file we also use the pcap data
sub processPcap {

  my($orderHashRef, $header, $pcapPacket) = @_;
  
  print "\n\n-------------------------------------------------------------------------------\n";
  print "PCAP length: $header->{len} timestamp in sec:  $header->{tv_sec}\n";

  my %sFlowPacket = ();

  # unpack ethernet header
  my $ethObj = NetPacket::Ethernet->decode($pcapPacket);

  $sFlowPacket{srcMac}    = $ethObj->{src_mac};
  $sFlowPacket{destMac}   = $ethObj->{dest_mac};
  $sFlowPacket{type}      = $ethObj->{type};

  # who came up with the idea to decode the ether type as 'n' in NetPacket?!?!?!?
  if ($ethObj->{type} eq '33024') {
    # cut off the vlan tag
    ($sFlowPacket{vlanTag},
     $sFlowPacket{type}) = unpack ('nH4',$ethObj->{data});
    $ethObj->{data} = substr($ethObj->{data},4);
  }

  # unpack ip header
  my $ipObj = NetPacket::IP->decode($ethObj->{data});
  $sFlowPacket{srcIP}     = $ipObj->{src_ip};
  $sFlowPacket{destIP}    = $ipObj->{dest_ip};

  # unpack udp header
  my $udpObj = NetPacket::UDP->decode($ipObj->{data});
  $sFlowPacket{srcPort}   = $udpObj->{src_port};
  $sFlowPacket{destPort}  = $udpObj->{dest_port};

  # more debug: 
  # print HexDump $udpObj->{data};

  &processPacket(\%sFlowPacket, $udpObj->{data}, $orderHashRef);
}

#############################################################################


sub listenPort {

  my $orderHashRef = shift;

  my $port = undef;
  my $packet = undef;

  if (defined($options{p})) {

    $options{p} =~ /^\d+$/ and $options{p} > 0

      or  print("Port must be an integer > 0\n"),
          &usage;

    $port = $options{p};
  }

  else {
    $port = '6343';
  }

  my $sock = IO::Socket::INET->new( LocalPort => $port,
                                    Proto     => 'udp')
                               or die "Can't bind : $!\n";

  print "Port: $port\n";
  print "Listening...\n";

  while ($sock->recv($packet,1548)) {
    &processPacket(undef, $packet, $orderHashRef);
  }
  die "Socket recv: $!";

}


#############################################################################


sub processPacket {

  my $sFlowPacketDataHashRef = shift;
  my $sFlowPacket = shift;
  my $orderHashRef = shift;

  my ($sFlowDatagramHashRef, $sFlowSamplesArrayRef, $errorsArrayRef) =
    Net::sFlow::decode($sFlowPacket);

  &stdout($sFlowPacketDataHashRef, $sFlowDatagramHashRef, $sFlowSamplesArrayRef, $orderHashRef);

  foreach my $error (@{$errorsArrayRef}) {
    print "$error\n";
  } 

}



#############################################################################


sub preparePrint {

  my @packetOrder = (
    "srcMac",
    "destMac",
    "vlanTag",
    "type",
    "srcIP",
    "destIP",
    "srcPort",
    "destPort"
  );

  my @datagramOrder = (
    "sFlowVersion",
    "AgentIpVersion",
    "AgentIp",
    "subAgentId",
    "datagramSequenceNumber",
    "agentUptime",
    "samplesInPacket"
  );

  my @sampleOrder = (
    "sampleType",

    "sampleTypeEnterprise",
    "sampleTypeFormat",
    "sampleLength",

    "FoundryFlags",
    "FoundryGroupID",

    "sampleSequenceNumber",
    "sourceIdType",
    "sourceIdIndex",
    "samplingRate",
    "samplePool",
    "drops",
    "inputInterface",
    "outputInterface",

    "inputInterfaceFormat",
    "inputInterfaceValue",
    "outputInterfaceFormat",
    "outputInterfaceValue",

    "packetDataType",
    "extendedDataInSample",

    "counterSamplingInterval",
    "countersVersion",
    "counterDataLength",

    "flowRecordsCount",

    "HEADERDATA",
    "HeaderProtocol",
    "HeaderFrameLength",
    "HeaderStrippedLength",
    "HeaderSizeByte",
    "HeaderSizeBit",
    "HeaderEtherSrcMac",
    "HeaderEtherDestMac",
    "HeaderType",
    "HeaderVer",
    "HeaderTclass",
    "HeaderFlabel",
    "HeaderDatalen",
    "HeaderNexth",
    "HeaderProto",
    "HeaderHlim",
    "HeaderSrcIP",
    "HeaderDestIP",
    "HeaderTCPSrcPort",
    "HeaderTCPDestPort",
    "HeaderUDPSrcPort",
    "HeaderUDPDestPort",
    "HeaderICMP",
    "NoTransportLayer",

    "ETHERNETFRAMEDATA",
    "EtherMacPacketlength",
    "EtherSrcMac",
    "EtherDestMac",
    "EtherPackettype",

    "IPv4DATA",
    "IPv4Packetlength",
    "IPv4NextHeaderProtocol",
    "IPv4srcIp",
    "IPv4destIp",
    "IPv4srcPort",
    "IPv4destPort",
    "IPv4tcpFlags",
    "IPv4tos",

    "IPv6DATA",
    "IPv6Packetlength",
    "IPv6NextHeaderProto",
    "IPv6srcIp",
    "IPv6destIp",
    "IPv6srcPort",
    "IPv6destPort",
    "IPv6tcpFlags",
    "IPv6Priority",

    "SWITCHDATA",
    "SwitchSrcVlan",
    "SwitchSrcPriority",
    "SwitchDestVlan",
    "SwitchDestPriority",

    "ROUTERDATA",
    "RouterIpVersionNextHopRouter",
    "RouterIpAddressNextHopRouter",
    "RouterSrcMask",
    "RouterDestMask",

    "GATEWAYDATA",
    "GatewayIpVersionNextHopRouter",
    "GatewayIpAddressNextHopRouter",
    "GatewayAsRouter",
    "GatewayAsSource",
    "GatewayAsSourcePeer",
    "GatewayDestAsPathsCount",
    "GatewayDestAsPaths",
    "GatewayLengthCommunitiesList",
    "GatewayCommunities",
    "localPref",

    "USERDATA",
    "UserSrcCharset",
    "UserLengthSrcString",
    "UserSrcString",
    "UserDestCharset",
    "UserLengthDestString",
    "UserDestString",

    "URLDATA",
    "UrlDirection",
    "UrlLength",
    "Url",
    "UrlHostLength",
    "UrlHost",

    "MPLSDATA",
    "MplsIpVersionNextHopRouter",
    "MplsIpAddressNextHopRouter",
    "MplsInLabesStackCount",
    # MplsInLabelStackArray
    "MplsOutLabelStackCount",
    # MplsOutLabelStackArray

    "NATDATA",
    "NatIpVersionSrcAddress",
    "NatSrcAddress",
    "NatIpVersionDestAddress",
    "NatDestAddress",

    "MPLSTUNNEL",
    "MplsTunnelNameLength",
    "MplsTunnelName",
    "MplsTunnelId",
    "MplsTunnelCosValue",

    "MPLSVC",
    "MplsVcInstanceNameLength",
    "MplsVcInstanceName",
    "MplsVcId",
    "MplsVcLabelCosValue",

    "MPLSFEC",
    "MplsFtnDescrLength",
    "MplsFtnDescr",
    "MplsFtnMask",

    "MPLSLPVFEC",
    "MplsFecAddrPrefixLength",

    "VLANTUNNEL",
    "VlanTunnelLayerStackCount",
    # VlanTunnelLayerStackArray

    "COUNTERGENERIC",
    "ifIndex",
    "ifType",
    "ifSpeed",
    "ifDirection",
    "ifAdminStatus",
    "ifOperStatus",
    "ifInOctets",
    "ifInUcastPkts",
    "ifInMulticastPkts",
    "ifInBroadcastPkts",
    "ifInDiscards",
    "ifInErrors",
    "ifInUnknownProtos",
    "ifOutOctets",
    "ifOutUcastPkts",
    "ifOutMulticastPkts",
    "ifOutBroadcastPkts",
    "ifOutDiscards",
    "ifOutErrors",
    "ifPromiscuousMode",

    "COUNTERETHERNET",
    "dot3StatsAlignmentErrors",
    "dot3StatsFCSErrors",
    "dot3StatsSingleCollisionFrames",
    "dot3StatsMultipleCollisionFrames",
    "dot3StatsSQETestErrors",
    "dot3StatsDeferredTransmissions",
    "dot3StatsLateCollisions",
    "dot3StatsExcessiveCollisions",
    "dot3StatsInternalMacTransmitErrors",
    "dot3StatsCarrierSenseErrors",
    "dot3StatsFrameTooLongs",
    "dot3StatsInternalMacReceiveErrors",
    "dot3StatsSymbolErrors",

    "COUNTERTOKENRING",
    "dot5StatsLineErrors",
    "dot5StatsBurstErrors",
    "dot5StatsACErrors",
    "dot5StatsAbortTransErrors",
    "dot5StatsInternalErrors",
    "dot5StatsLostFrameErrors",
    "dot5StatsReceiveCongestions",
    "dot5StatsFrameCopiedErrors",
    "dot5StatsTokenErrors",
    "dot5StatsSoftErrors",
    "dot5StatsHardErrors",
    "dot5StatsSignalLoss",
    "dot5StatsTransmitBeacons",
    "dot5StatsRecoverys",
    "dot5StatsLobeWires",
    "dot5StatsRemoves",
    "dot5StatsSingles",
    "dot5StatsFreqErrors",

    "COUNTERVG",
    "dot12InHighPriorityFrames",
    "dot12InHighPriorityOctets",
    "dot12InNormPriorityFrames",
    "dot12InNormPriorityOctets",
    "dot12InIPMErrors",
    "dot12InOversizeFrameErrors",
    "dot12InDataErrors",
    "dot12InNullAddressedFrames",
    "dot12OutHighPriorityFrames",
    "dot12OutHighPriorityOctets",
    "dot12TransitionIntoTrainings",
    "dot12HCInHighPriorityOctets",
    "dot12HCInNormPriorityOctets",
    "dot12HCOutHighPriorityOctets",

    "COUNTERVLAN",
    "vlan_id",
    "octets",
    "ucastPkts",
    "multicastPkts",
    "broadcastPkts",
    "discards",

    "COUNTERPROCESSOR",
    "cpu5s",
    "cpu1m",
    "cpu5m",
    "memoryTotal",
    "memoryFree"
  );

  my %orderHash = (
    'packetOrder'   => \@packetOrder, 
    'datagramOrder' => \@datagramOrder, 
    'sampleOrder'   => \@sampleOrder
  );
  
  return(\%orderHash);

}



#############################################################################


sub stdout {

  my $sFlowPacketDataHashRef = shift;
  my $sFlowDatagramHashRef = shift;
  my $sFlowSamplesArrayRef = shift;
  my $orderHashRef = shift;

  if (defined($sFlowPacketDataHashRef)) {
    print "\n";
    print "===PcapData===\n";
    foreach my $packetOrder (@{$orderHashRef->{packetOrder}}) {
      if (defined($sFlowPacketDataHashRef->{$packetOrder})) {
        print "$packetOrder => $sFlowPacketDataHashRef->{$packetOrder}\n";
      }
    }
  }

  print "\n\n";
  print "===Datagram===\n";
  foreach my $datagramOrder (@{$orderHashRef->{datagramOrder}}) {
    if (defined($sFlowDatagramHashRef->{$datagramOrder})) {
      print "$datagramOrder => $sFlowDatagramHashRef->{$datagramOrder}\n";
    }
  }

  foreach my $sFlowSampleHashRef (@{$sFlowSamplesArrayRef}) {
    print "\n";
    print "---Sample---\n";
    foreach my $sampleOrder (@{$orderHashRef->{sampleOrder}}) {

      if (defined($sFlowSampleHashRef->{$sampleOrder})) {

        if ($sampleOrder eq "GatewayDestAsPaths") {
          foreach my $GatewayDestAsPath (@{$sFlowSampleHashRef->{$sampleOrder}}) {
            print "  asPathSegmentType => $GatewayDestAsPath->{asPathSegmentType}\n";
            print "  lengthAsList => $GatewayDestAsPath->{lengthAsList}\n";
            foreach my $as (@{$GatewayDestAsPath->{AsPath}}) {
              print "    as nr. => $as\n";
            }
          }
        } 

        elsif ($sampleOrder eq "GatewayCommunities") {
          print "  GatewayCommunities => @{$sFlowSampleHashRef->{GatewayCommunities}}\n";
        }

        elsif ($sampleOrder eq "HeaderEtherSrcMac") {
          my ($sm_hi, $sm_lo) = unpack("Nn",$sFlowSampleHashRef->{HeaderEtherSrcMac});
          $sFlowSampleHashRef->{HeaderEtherSrcMac} = sprintf("%08x%04x", $sm_hi, $sm_lo);
          print "HeaderEtherSrcMac => $sFlowSampleHashRef->{HeaderEtherSrcMac}\n";
        }

        elsif ($sampleOrder eq "HeaderEtherDestMac") {
          my ($dm_hi, $dm_lo) = unpack("Nn",$sFlowSampleHashRef->{HeaderEtherDestMac});
          $sFlowSampleHashRef->{HeaderEtherDestMac} = sprintf("%08x%04x", $dm_hi, $dm_lo);
          print "HeaderEtherDestMac => $sFlowSampleHashRef->{HeaderEtherDestMac}\n";
        }

        else {
           print "$sampleOrder => $sFlowSampleHashRef->{$sampleOrder}\n";
        }
      }
    }
  }

}

