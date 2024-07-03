[![Actions Status](https://github.com/fooelisa/perl-net-sflow/actions/workflows/test.yml/badge.svg)](https://github.com/fooelisa/perl-net-sflow/actions)
# NAME

Net::sFlow - decode sFlow datagrams

# SYNOPSIS

    use Net::sFlow;
    use IO::Socket::INET;

    my $sock = IO::Socket::INET->new( LocalPort => '6343',
                                      Proto     => 'udp')
                                 or die "Can't bind : $@\n";

    while ($sock->recv($packet,1548)) {
      &processPacket($packet);
    }
    die "Socket recv: $!";


    sub processPacket {

      my $sFlowPacket = shift;

      # now we actually call the Net::sFlow::decode() function
      my ($sFlowDatagramRef, $sFlowSamplesRef, $errorsRef) = Net::sFlow::decode($sFlowPacket);

      # print errors
        foreach my $error (@{$errorsRef}) {
        warn "$error";
      }

      # print sflow data
      print "===Datagram===\n";
      print "sFlow version: $sFlowDatagramRef->{sFlowVersion}\n";
      print "datagram sequence number: $sFlowDatagramRef->{datagramSequenceNumber}\n";

      foreach my $sFlowSample (@{$sFlowSamplesRef}) {
        print "\n";
        print "---Sample---\n";
        print "sample sequence number: $sFlowSample->{sampleSequenceNumber}\n";
      }

    }

# DESCRIPTION

The sFlow module provides a mechanism to parse and decode sFlow
datagrams. It supports sFlow version 2/4 (RFC 3176 -
http://www.ietf.org/rfc/rfc3176.txt) and sFlow version 5 (Memo -
http://sflow.org/sflow\_version\_5.txt).

The module's functionality is provided by a single (exportable)
function, [decode()](#decode).

For more examples have a look into the 'examples' directory.

# FUNCTIONS

## decode()

($datagram, $samples, $error) = Net::sFlow::decode($udp\_data);

Returns a HASH reference containing the datagram data,
an ARRAY reference with the sample data (each array element contains a HASH reference for one sample)
and in case of an error a reference to an ARRAY containing the error messages.

### Return Values

- _$datagram_

    A HASH reference containing information about the sFlow datagram, with
    the following keys:

        sFlowVersion
        AgentIpVersion
        AgentIp
        datagramSequenceNumber
        agentUptime
        samplesInPacket

    In the case of sFlow v5, there is an additional key:

        subAgentId

- _$samples_

    Reference to a list of HASH references, each one representing one
    sample. Depending on the sFlow version and type of hardware where the data comes from
    (router, switch, etc.), the hash contains the following additional keys:

    In case of sFlow <= 4:

        sampleType
        sampleSequenceNumber
        sourceIdType
        sourceIdIndex

    If it's a sFlow <= 4 _flowsample_ you will get the following additional keys:

        samplingRate
        samplePool
        drops
        inputInterface
        outputInterface
        packetDataType
        extendedDataInSample

    If it's a sFlow <= 4 _countersample_ you will get these additional keys:

        counterSamplingInterval
        countersVersion

    In case of sFlow >= 5 you will first get enterprise, format and length information:

        sampleTypeEnterprise
        sampleTypeFormat
        sampleLength

    If the sample is a Foundry ACL based sample (enterprise == 1991 and format == 1) you will receive the following information:

        FoundryFlags
        FoundryGroupID

    In case of a _flowsample_ (enterprise == 0 and format == 1):

        sampleSequenceNumber
        sourceIdType
        sourceIdIndex
        samplingRate
        samplePool
        drops
        inputInterface
        outputInterface
        flowRecordsCount

    If it's an _expanded flowsample_ (enterprise == 0 and format == 3)
    you will get these additional keys instead of inputInterface and outputInterface:

        inputInterfaceFormat
        inputInterfaceValue
        outputInterfaceFormat
        outputInterfaceValue

    In case of a _countersample_ (enterprise == 0 and format == 2) or
    an _expanded countersample_ (enterprise == 0 and format == 4):

        sampleSequenceNumber
        sourceIdType
        sourceIdIndex
        counterRecordsCount
        counterDataLength

    Depending on the hardware you can get the following additional keys:

    Header data (sFlow format):

        HEADERDATA
        HeaderProtocol
        HeaderFrameLength
        HeaderStrippedLength
        HeaderSizeByte
        HeaderSizeBit
        HeaderBin

    Additional Header data decoded from the raw packet header:

        HeaderEtherSrcMac
        HeaderEtherDestMac
        HeaderType (ether type)
        HeaderDatalen (of the whole packet including ethernet header)

    Ethernet frame data:

        ETHERNETFRAMEDATA
        EtherMacPacketlength
        EtherSrcMac
        EtherDestMac
        EtherPackettype

    IPv4 data:

        IPv4DATA
        IPv4Packetlength
        IPv4NextHeaderProtocol
        IPv4srcIp
        IPv4destIp
        IPv4srcPort
        IPv4destPort
        IPv4tcpFlags
        IPv4tos

    IPv6 data:

        IPv6DATA
        IPv6Packetlength
        IPv6NextHeaderProto
        IPv6srcIp
        IPv6destIp
        IPv6srcPort
        IPv6destPort
        IPv6tcpFlags
        IPv6Priority

    Switch data:

        SWITCHDATA
        SwitchSrcVlan
        SwitchSrcPriority
        SwitchDestVlan
        SwitchDestPriority

    Router data:

        ROUTERDATA
        RouterIpVersionNextHopRouter
        RouterIpAddressNextHopRouter
        RouterSrcMask
        RouterDestMask

    Gateway data:

        GATEWAYDATA
        GatewayIpVersionNextHopRouter (only in case of sFlow v5)
        GatewayIpAddressNextHopRouter (only in case of sFlow v5)
        GatewayAsRouter
        GatewayAsSource
        GatewayAsSourcePeer
        GatewayDestAsPathsCount

        GatewayDestAsPaths (arrayreference)
          each enty contains a hashreference:
            asPathSegmentType
            lengthAsList
            AsPath (arrayreference, asNumbers as entries)

        GatewayLengthCommunitiesList (added in sFlow v4)
        GatewayCommunities (arrayreference, added in sFlow v4)
          each enty contains a community (added in sFlow v4)

        localPref

    User data:

        USERDATA
        UserSrcCharset (only in case of sFlow v5)
        UserLengthSrcString
        UserSrcString
        UserDestCharset (only in case of sFlow v5)
        UserLengthDestString
        UserDestString

    Url data (added in sFlow v3):

        URLDATA
        UrlDirection
        UrlLength
        Url
        UrlHostLength (only in case of sFlow v5)
        UrlHost (only in case of sFlow v5)

    The following keys can be only available in sFlow v5:

    Mpls data:

        MPLSDATA
        MplsIpVersionNextHopRouter
        MplsIpAddressNextHopRouter
        MplsInLabelStackCount
        MplsInLabelStack (arrayreference containing MplsInLabels)
        MplsOutLabelStackCount
        MplsOutLabelStack (arrayreference containing MplsOutLabels)

    Nat data:

        NATDATA
        NatIpVersionSrcAddress
        NatSrcAddress
        NatIpVersionDestAddress
        NatDestAddress

    Mpls tunnel:

        MPLSTUNNEL
        MplsTunnelNameLength
        MplsTunnelName
        MplsTunnelId
        MplsTunnelCosValue

    Mpls vc:

        MPLSVC
        MplsVcInstanceNameLength
        MplsVcInstanceName
        MplsVcId
        MplsVcLabelCosValue

    Mpls fec:

        MPLSFEC
        MplsFtnDescrLength
        MplsFtnDescr
        MplsFtnMask

    Mpls lpv fec:

        MPLSLPVFEC
        MplsFecAddrPrefixLength

    Vlan tunnel:

        VLANTUNNEL
        VlanTunnelLayerStackCount
        VlanTunnelLayerStack (arrayreference containing VlanTunnelLayer entries)

    The following keys are also available in sFlow < 5:

    Counter generic:

        COUNTERGENERIC
        ifIndex
        ifType
        ifSpeed
        ifDirection
        ifAdminStatus
        ifOperStatus
        ifInOctets
        ifInUcastPkts
        ifInMulticastPkts
        ifInBroadcastPkts
        ifInDiscards
        ifInErrors
        ifInUnknownProtos
        ifOutOctets
        ifOutUcastPkts
        ifOutMulticastPkts
        ifOutBroadcastPkts
        ifOutDiscards
        ifOutErrors
        ifPromiscuousMode

    Counter ethernet:

        COUNTERETHERNET
        dot3StatsAlignmentErrors
        dot3StatsFCSErrors
        dot3StatsSingleCollisionFrames
        dot3StatsMultipleCollisionFrames
        dot3StatsSQETestErrors
        dot3StatsDeferredTransmissions
        dot3StatsLateCollisions
        dot3StatsExcessiveCollisions
        dot3StatsInternalMacTransmitErrors
        dot3StatsCarrierSenseErrors
        dot3StatsFrameTooLongs
        dot3StatsInternalMacReceiveErrors
        dot3StatsSymbolErrors

    Counter tokenring:

        COUNTERTOKENRING
        dot5StatsLineErrors
        dot5StatsBurstErrors
        dot5StatsACErrors
        dot5StatsAbortTransErrors
        dot5StatsInternalErrors
        dot5StatsLostFrameErrors
        dot5StatsReceiveCongestions
        dot5StatsFrameCopiedErrors
        dot5StatsTokenErrors
        dot5StatsSoftErrors
        dot5StatsHardErrors
        dot5StatsSignalLoss
        dot5StatsTransmitBeacons
        dot5StatsRecoverys
        dot5StatsLobeWires
        dot5StatsRemoves
        dot5StatsSingles
        dot5StatsFreqErrors

    Counter vg:

        COUNTERVG
        dot12InHighPriorityFrames
        dot12InHighPriorityOctets
        dot12InNormPriorityFrames
        dot12InNormPriorityOctets
        dot12InIPMErrors
        dot12InOversizeFrameErrors
        dot12InDataErrors
        dot12InNullAddressedFrames
        dot12OutHighPriorityFrames
        dot12OutHighPriorityOctets
        dot12TransitionIntoTrainings
        dot12HCInHighPriorityOctets
        dot12HCInNormPriorityOctets
        dot12HCOutHighPriorityOctets

    Counter vlan:

        COUNTERVLAN
        vlan_id
        octets
        ucastPkts
        multicastPkts
        broadcastPkts
        discards

    Counter lag:

        COUNTERLAG
        dot3adAggPortActorSystemID
        dot3adAggPortPartnerOperSystemID
        dot3adAggPortAttachedAggID
        dot3adAggPortActorAdminState
        dot3adAggPortActorOperState
        dot3adAggPortPartnerAdminState
        dot3adAggPortPartnerOperState
        dot3adAggPortStatsLACPDUsRx
        dot3adAggPortStatsMarkerPDUsRx
        dot3adAggPortStatsMarkerResponsePDUsRx
        dot3adAggPortStatsUnknownRx
        dot3adAggPortStatsIllegalRx
        dot3adAggPortStatsLACPDUsTx
        dot3adAggPortStatsMarkerPDUsTx
        dot3adAggPortStatsMarkerResponsePDUsTx

    Counter processor (only in sFlow v5):

        COUNTERPROCESSOR
        cpu5s
        cpu1m
        cpu5m
        memoryTotal
        memoryFree

    Counter HTTP:

        COUNTERHTTP
        methodOptionCount
        methodGetCount
        methodHeadCount
        methodPostCount
        methodPutCount
        methodDeleteCount
        methodTraceCount
        methodConnectCount
        methodOtherCount
        status1xxCount
        status2xxCount
        status3xxCount
        status4xxCount
        status5xxCount
        statusOtherCount

- _$error_

    Reference to a list of error messages.

# CAVEATS

The [decode()](#decode) function will blindly attempt to decode the data
you provide. There are some tests for the appropriate values at various
places (where it is feasible to test - like enterprises,
formats, versionnumbers, etc.), but in general the GIGO principle still
stands: Garbage In / Garbage Out.

# SEE ALSO

sFlow v4
http://www.ietf.org/rfc/rfc3176.txt

sFlow v5
http://sflow.org/sflow\_version\_5.txt

Math::BigInt

# AUTHOR

Elisa Jasinska <elisa@bigwaveit.org>

# CONTACT

Please send comments or bug reports to <elisa@bigwaveit.org> and/or <sflow@ams-ix.net>

# COPYRIGHT

Copyright (c) 2006 - 2015 AMS-IX B.V.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)
