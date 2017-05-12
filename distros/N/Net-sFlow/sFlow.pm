#!/usr/bin/perl
#
#
# My first perl project ;)
# Elisa Jasinska <elisa.jasinska@ams-ix.net>
# With many thanks to Tobias Engel for his help and support!
#
#
# sFlow.pm - 2009/01/20
#
# Please send comments or bug reports to <sflow@ams-ix.net>
#
#
# sFlow v4 RFC 3176 
# http://www.ietf.org/rfc/rfc3176.txt
# Dataformat: http://jasinska.de/sFlow/sFlowV4FormatDiagram/
#
# sFlow v5 Memo
# http://sflow.org/sflow_version_5.txt
# Dataformat: http://jasinska.de/sFlow/sFlowV5FormatDiagram/
#
#
# Copyright (c) 2006 - 2009 AMS-IX B.V.
#
# This package is free software and is provided "as is" without express 
# or implied warranty.  It may be used, redistributed and/or modified 
# under the terms of the Perl Artistic License (see
# http://www.perl.com/perl/misc/Artistic.html)
#


package Net::sFlow;


use strict;
use warnings;
use bytes;

require Exporter;
# 64bit integers
use Math::BigInt;


our $VERSION = '0.11';
our @EXPORT_OK = qw(decode);


# constants

use constant SFLOWv4                        => 4;
use constant SFLOWv5                        => 5;

use constant UNKNOWNIPVERSION               => 0;
use constant IPv4                           => 1;
use constant IPv6                           => 2;

# sFlow v4 constants

use constant FLOWSAMPLE_SFLOWv4             => 1;
use constant COUNTERSAMPLE_SFLOWv4          => 2;

use constant HEADERDATA_SFLOWv4             => 1;
use constant IPv4DATA_SFLOWv4               => 2;
use constant IPv6DATA_SFLOWv4               => 3;

use constant SWITCHDATA_SFLOWv4             => 1;
use constant ROUTERDATA_SFLOWv4             => 2;
use constant GATEWAYDATA_SFLOWv4            => 3;
use constant USERDATA_SFLOWv4               => 4;
use constant URLDATA_SFLOWv4                => 5;

use constant GENERICCOUNTER_SFLOWv4         => 1;
use constant ETHERNETCOUNTER_SFLOWv4        => 2;
use constant TOKENRINGCOUNTER_SFLOWv4       => 3;
use constant FDDICOUNTER_SFLOWv4            => 4;
use constant VGCOUNTER_SFLOWv4              => 5;
use constant WANCOUNTER_SFLOWv4             => 6;
use constant VLANCOUNTER_SFLOWv4            => 7;

# sFlow v5 constants

use constant FLOWSAMPLE_SFLOWv5             => 1;
use constant COUNTERSAMPLE_SFLOWv5          => 2;
use constant EXPANDEDFLOWSAMPLE_SFLOWv5     => 3;
use constant EXPANDEDCOUNTERSAMPLE_SFLOWv5  => 4;
use constant FOUNDRY_ACL_SFLOWv5            => 1991;

use constant HEADERDATA_SFLOWv5             => 1;
use constant ETHERNETFRAMEDATA_SFLOWv5      => 2;
use constant IPv4DATA_SFLOWv5               => 3;
use constant IPv6DATA_SFLOWv5               => 4;
use constant SWITCHDATA_SFLOWv5             => 1001;
use constant ROUTERDATA_SFLOWv5             => 1002;
use constant GATEWAYDATA_SFLOWv5            => 1003;
use constant USERDATA_SFLOWv5               => 1004;
use constant URLDATA_SFLOWv5                => 1005;
use constant MPLSDATA_SFLOWv5               => 1006;
use constant NATDATA_SFLOWv5                => 1007;
use constant MPLSTUNNEL_SFLOWv5             => 1008;
use constant MPLSVC_SFLOWv5                 => 1009;
use constant MPLSFEC_SFLOWv5                => 1010;
use constant MPLSLVPFEC_SFLOWv5             => 1011;
use constant VLANTUNNEL_SFLOWv5             => 1012;

use constant GENERICCOUNTER_SFLOWv5         => 1;
use constant ETHERNETCOUNTER_SFLOWv5        => 2;
use constant TOKENRINGCOUNTER_SFLOWv5       => 3;
use constant VGCOUNTER_SFLOWv5              => 4;
use constant VLANCOUNTER_SFLOWv5            => 5;
use constant PROCESSORCOUNTER_SFLOWv5       => 1001;

# ethernet header constants

use constant ETH_TYPE_UNK                   => '0000';
use constant ETH_TYPE_XNS_IDP               => '0600';
use constant ETH_TYPE_IP                    => '0800';
use constant ETH_TYPE_X25L3                 => '0805';
use constant ETH_TYPE_ARP                   => '0806';
use constant ETH_TYPE_VINES_IP              => '0bad';
use constant ETH_TYPE_VINES_ECHO            => '0baf';
use constant ETH_TYPE_TRAIN                 => '1984';
use constant ETH_TYPE_CGMP                  => '2001';
use constant ETH_TYPE_CENTRINO_PROMISC      => '2452';
use constant ETH_TYPE_3C_NBP_DGRAM          => '3c07';
use constant ETH_TYPE_EPL_V1                => '3e3f';
use constant ETH_TYPE_DEC                   => '6000';
use constant ETH_TYPE_DNA_DL                => '6001';
use constant ETH_TYPE_DNA_RC                => '6002';
use constant ETH_TYPE_DNA_RT                => '6003';
use constant ETH_TYPE_LAT                   => '6004';
use constant ETH_TYPE_DEC_DIAG              => '6005';
use constant ETH_TYPE_DEC_CUST              => '6006';
use constant ETH_TYPE_DEC_SCA               => '6007';
use constant ETH_TYPE_ETHBRIDGE             => '6558';
use constant ETH_TYPE_RAW_FR                => '6559';
use constant ETH_TYPE_RARP                  => '8035';
use constant ETH_TYPE_DEC_LB                => '8038';
use constant ETH_TYPE_DEC_LAST              => '8041';
use constant ETH_TYPE_APPLETALK             => '809b';
use constant ETH_TYPE_SNA                   => '80d5';
use constant ETH_TYPE_AARP                  => '80f3';
use constant ETH_TYPE_VLAN                  => '8100';
use constant ETH_TYPE_IPX                   => '8137';
use constant ETH_TYPE_SNMP                  => '814c';
use constant ETH_TYPE_WCP                   => '80ff';
use constant ETH_TYPE_STP                   => '8181';
use constant ETH_TYPE_ISMP                  => '81fd';
use constant ETH_TYPE_ISMP_TBFLOOD          => '81ff';
use constant ETH_TYPE_IPv6                  => '86dd';
use constant ETH_TYPE_WLCCP                 => '872d';
use constant ETH_TYPE_MAC_CONTROL           => '8808';
use constant ETH_TYPE_SLOW_PROTOCOLS        => '8809';
use constant ETH_TYPE_PPP                   => '880b';
use constant ETH_TYPE_COBRANET              => '8819';
use constant ETH_TYPE_MPLS                  => '8847';
use constant ETH_TYPE_MPLS_MULTI            => '8848';
use constant ETH_TYPE_FOUNDRY               => '885a';
use constant ETH_TYPE_PPPOED                => '8863';
use constant ETH_TYPE_PPPOES                => '8864';
use constant ETH_TYPE_INTEL_ANS             => '886d';
use constant ETH_TYPE_MS_NLB_HEARTBEAT      => '886f';
use constant ETH_TYPE_CDMA2000_A10_UBS      => '8881';
use constant ETH_TYPE_EAPOL                 => '888e';
use constant ETH_TYPE_PROFINET              => '8892';
use constant ETH_TYPE_HYPERSCSI             => '889a';
use constant ETH_TYPE_CSM_ENCAPS            => '889b';
use constant ETH_TYPE_TELKONET              => '88a1';
use constant ETH_TYPE_AOE                   => '88a2';
use constant ETH_TYPE_EPL_V2                => '88ab';
use constant ETH_TYPE_BRDWALK               => '88ae';
use constant ETH_TYPE_IEEE802_OUI_EXTENDED  => '88b7';
use constant ETH_TYPE_IEC61850_GOOSE        => '88b8';
use constant ETH_TYPE_IEC61850_GSE          => '88b9';
use constant ETH_TYPE_IEC61850_SV           => '88ba';
use constant ETH_TYPE_TIPC                  => '88ca';
use constant ETH_TYPE_RSN_PREAUTH           => '88c7';
use constant ETH_TYPE_LLDP                  => '88cc';
use constant ETH_TYPE_3GPP2                 => '88d2';
use constant ETH_TYPE_MRP                   => '88e3';
use constant ETH_TYPE_LOOP                  => '9000';
use constant ETH_TYPE_RTMAC                 => '9021';
use constant ETH_TYPE_RTCFG                 => '9022';
use constant ETH_TYPE_LLT                   => 'cafe';
use constant ETH_TYPE_FCFT                  => 'fcfc';



#############################################################################
sub decode {
#############################################################################

  my $sFlowDatagramPacked = shift;
  my %sFlowDatagram = ();
  my @sFlowSamples = ();
  my @errors = ();
  my $error = undef;
  my $subProcessed = undef;

  my $offset = 0;

  ($sFlowDatagram{sFlowVersion},
   $sFlowDatagram{AgentIpVersion}) =
    unpack('NN', $sFlowDatagramPacked);

  $offset += (2 * 4);

  ($subProcessed, $error) =
    &_decodeIpAddress(
      \$offset,
      \$sFlowDatagramPacked,
      \%sFlowDatagram,
      undef,
      \@sFlowSamples,
      $sFlowDatagram{AgentIpVersion},
      'AgentIp',
      1,
    );

  unless ($subProcessed) {
    push @errors, $error;
    %sFlowDatagram = ();
    return (\%sFlowDatagram, \@sFlowSamples, \@errors);
  }


####### sFlow V4 #######

  if ($sFlowDatagram{sFlowVersion} <= SFLOWv4) {

    (undef,
     $sFlowDatagram{datagramSequenceNumber},
     $sFlowDatagram{agentUptime},
     $sFlowDatagram{samplesInPacket}) =
      unpack("a$offset N3", $sFlowDatagramPacked);

    $offset += (3 * 4);

    # boundcheck for $sFlowDatagram{samplesInPacket}
    # $sFlowDatagram{samplesInPacket} * 4
    # cannot be longer than the number of $sFlowDatagramPacked byte - $offset

    if (length($sFlowDatagramPacked) - $offset <
      $sFlowDatagram{samplesInPacket} * 4) {

      # error $sFlowDatagram{samplesInPacket} too big
      $error = "ERROR: [sFlow.pm] Datagram: Samples in packet count too big "
             . "- rest of the datagram skipped";

      push @errors, $error;
      pop @sFlowSamples;
      return (\%sFlowDatagram, \@sFlowSamples, \@errors);

    } elsif ($sFlowDatagram{samplesInPacket} < 0) {

      # error $sFlowDatagram{samplesInPacket} too small
      $error = "ERROR: [sFlow.pm] Datagram: Samples in packet count too small "
             . "- rest of the datagram skipped";

      push @errors, $error;
      pop @sFlowSamples;
      return (\%sFlowDatagram, \@sFlowSamples, \@errors);

    } else {

      # parse samples
      for my $samplesCount (0 .. $sFlowDatagram{samplesInPacket} - 1) {

        my %sFlowSample = ();
        push @sFlowSamples, \%sFlowSample;

        (undef,
         $sFlowSample{sampleType}) =
          unpack("a$offset N", $sFlowDatagramPacked);

        $offset += 4;


        # FLOWSAMPLE
        if ($sFlowSample{sampleType} == FLOWSAMPLE_SFLOWv4) {

          (undef,
           $sFlowSample{sampleSequenceNumber}) =
            unpack("a$offset N", $sFlowDatagramPacked);

          $offset += 4;

          my $sourceId = undef;

          (undef,
           $sourceId,
           $sFlowSample{samplingRate},
           $sFlowSample{samplePool},
           $sFlowSample{drops},
           $sFlowSample{inputInterface},
           $sFlowSample{outputInterface},
           $sFlowSample{packetDataType}) =
            unpack("a$offset N7", $sFlowDatagramPacked);

          $offset += 28;

          $sFlowSample{sourceIdType} = $sourceId >> 24;
          $sFlowSample{sourceIdIndex} = $sourceId & 2 ** 24 - 1;

          # packet data type: header
          if ($sFlowSample{packetDataType} == HEADERDATA_SFLOWv4) {

            ($subProcessed, $error) =
              &_decodeHeaderData(
                \$offset,
                \$sFlowDatagramPacked,
                \%sFlowDatagram,
                \%sFlowSample,
                \@sFlowSamples,
              );

            unless ($subProcessed) {
              push @errors, $error;
            }
          }

          # packet data type: IPv4
          elsif ($sFlowSample{packetDataType} == IPv4DATA_SFLOWv4) {
            &_decodeIPv4Data(\$offset, \$sFlowDatagramPacked, \%sFlowSample);
          }

          # packet data type: IPv6
          elsif ($sFlowSample{packetDataType} == IPv6DATA_SFLOWv4){
            &_decodeIPv6Data(\$offset, \$sFlowDatagramPacked, \%sFlowSample);
          }

          else {
  
            $error = "ERROR: [sFlow.pm] <sFlowV4:PacketData> AgentIP: $sFlowDatagram{AgentIp}, "
                   . "Datagram: $sFlowDatagram{datagramSequenceNumber} - Unknown packet data type: "
                   . "$sFlowSample{packetDataType} - rest of the datagram skipped";
  
            push @errors, $error;
            pop @sFlowSamples;
		        return (\%sFlowDatagram, \@sFlowSamples, \@errors);
          }

          (undef,
           $sFlowSample{extendedDataInSample}) =
            unpack("a$offset N", $sFlowDatagramPacked);

          $offset += 4;

          # boundcheck for $sFlowSample{extendedDataInSample}
          # $sFlowSample{extendedDataInSample} * 4
          # cannot be longer than the number of $sFlowDatagramPacked byte - $offset

          if (length($sFlowDatagramPacked) - $offset <
            $sFlowSample{extendedDataInSample} * 4) {

            # error $sFlowSample{extendedDataInSample} too big
            $error = "ERROR: [sFlow.pm] Datagram: Extended data in sample count too big "
                   . "- rest of the datagram skipped";

            push @errors, $error;
            pop @sFlowSamples;
            return (\%sFlowDatagram, \@sFlowSamples, \@errors);

          } elsif ($sFlowSample{extendedDataInSample} < 0) {

            # error $sFlowSample{extendedDataInSample} too small
            $error = "ERROR: [sFlow.pm] Datagram: Extended data in sample count too small "
                   . "- rest of the datagram skipped";

            push @errors, $error;
            pop @sFlowSamples;
            return (\%sFlowDatagram, \@sFlowSamples, \@errors);

          } else {

            for my $extendedDataCount (0 .. $sFlowSample{extendedDataInSample} - 1){

              my $extendedDataType = undef;

              (undef, $extendedDataType) = unpack("a$offset N", $sFlowDatagramPacked);
              $offset += 4;

              # extended data: switch
              if ($extendedDataType == SWITCHDATA_SFLOWv4) {
                &_decodeSwitchData(\$offset, \$sFlowDatagramPacked, \%sFlowSample);
              }

              # extended data: router
              elsif ($extendedDataType == ROUTERDATA_SFLOWv4) {
  
                ($subProcessed, $error) =
                  &_decodeRouterData(
                    \$offset,
                    \$sFlowDatagramPacked,
                    \%sFlowDatagram,
                    \%sFlowSample,
                    \@sFlowSamples,
                  );

                unless ($subProcessed) {
                  push @errors, $error;
                  pop @sFlowSamples;
                  return (\%sFlowDatagram, \@sFlowSamples, \@errors);
                }

              }

              # extended data: gateway
              elsif ($extendedDataType == GATEWAYDATA_SFLOWv4) {

                ($subProcessed, $error) =
                  &_decodeGatewayData(
                    \$offset,
                    \$sFlowDatagramPacked,
                    \%sFlowDatagram,
                    \%sFlowSample,
                    \@sFlowSamples,
                  );

                unless ($subProcessed) {
                  push @errors, $error;
                  pop @sFlowSamples;
                  return (\%sFlowDatagram, \@sFlowSamples, \@errors);
                }
  
             }
  
              # extended data: user
              elsif ($extendedDataType == USERDATA_SFLOWv4) {

                ($subProcessed, $error) =
                  &_decodeUserData(
                    \$offset,
                    \$sFlowDatagramPacked,
                    \%sFlowDatagram,
                    \%sFlowSample,
                  );  

                unless ($subProcessed) {
                  push @errors, $error;
                  pop @sFlowSamples;
                  return (\%sFlowDatagram, \@sFlowSamples, \@errors);
                }

              }

              # extended data: url
              # added in v.3.
              elsif ($extendedDataType == URLDATA_SFLOWv4) {

                ($subProcessed, $error) =
                  &_decodeUrlData(
                    \$offset,
                    \$sFlowDatagramPacked,
                    \%sFlowDatagram,
                    \%sFlowSample,
                  );

                unless ($subProcessed) {
                  push @errors, $error;
                  pop @sFlowSamples;
                  return (\%sFlowDatagram, \@sFlowSamples, \@errors);
                }
  
              }

              else {
  
                $error = "ERROR: [sFlow.pm] <sFlowV4:ExtendedData> AgentIP: $sFlowDatagram{AgentIp}, "
                       . "Datagram: $sFlowDatagram{datagramSequenceNumber} - Unknown extended data type: "
                       . "$extendedDataType - rest of the datagram skipped";
    
                push @errors, $error;
                pop @sFlowSamples;
		            return (\%sFlowDatagram, \@sFlowSamples, \@errors);
              }
  
            }
  
          }

        }

        # COUNTERSAMPLE
        elsif ($sFlowSample{sampleType} == COUNTERSAMPLE_SFLOWv4) {

          my $sourceId = undef;

          (undef,
           $sFlowSample{sampleSequenceNumber},
           $sourceId,
           $sFlowSample{counterSamplingInterval},
           $sFlowSample{countersVersion}) =
            unpack("a$offset N4", $sFlowDatagramPacked);

          $offset += 16;
      
          $sFlowSample{sourceIdType} = $sourceId >> 24;
          $sFlowSample{sourceIdIndex} = $sourceId & 2 ** 24 - 1;

          # counterstype: generic
          if ($sFlowSample{countersVersion} == GENERICCOUNTER_SFLOWv4) {
            &_decodeCounterGeneric(\$offset, \$sFlowDatagramPacked, \%sFlowSample);
          }

          # counterstype: ethernet
          elsif ($sFlowSample{countersVersion} == ETHERNETCOUNTER_SFLOWv4) {
            &_decodeCounterGeneric(\$offset, \$sFlowDatagramPacked, \%sFlowSample);
            &_decodeCounterEthernet(\$offset, \$sFlowDatagramPacked, \%sFlowSample);
          }

          # counterstype: tokenring
          elsif ($sFlowSample{countersVersion} == TOKENRINGCOUNTER_SFLOWv4) {
            &_decodeCounterGeneric(\$offset, \$sFlowDatagramPacked, \%sFlowSample);
            &_decodeCounterTokenring(\$offset, \$sFlowDatagramPacked, \%sFlowSample);
          }

          # counterstype: fddi
          elsif ($sFlowSample{countersVersion} == FDDICOUNTER_SFLOWv4) {
            &_decodeCounterGeneric(\$offset, \$sFlowDatagramPacked, \%sFlowSample);
          }

          # counterstype: vg
          elsif ($sFlowSample{countersVersion} == VGCOUNTER_SFLOWv4) {
            &_decodeCounterGeneric(\$offset, \$sFlowDatagramPacked, \%sFlowSample);
            &_decodeCounterVg(\$offset, \$sFlowDatagramPacked, \%sFlowSample);
          }

          # counterstype: wan
          elsif ($sFlowSample{countersVersion} == WANCOUNTER_SFLOWv4) {
            &_decodeCounterGeneric(\$offset, \$sFlowDatagramPacked, \%sFlowSample);
          }
  
          # counterstype: vlan
          elsif ($sFlowSample{countersVersion} == VLANCOUNTER_SFLOWv4) {
            &_decodeCounterVlan(\$offset, \$sFlowDatagramPacked, \%sFlowSample);
          }

          else {
  
            $error = "ERROR: [sFlow.pm] <sFlowV4:CountersType> AgentIP: $sFlowDatagram{AgentIp}, "
                   . "Datagram: $sFlowDatagram{datagramSequenceNumber} - Unknown counters type: "
                   . "$sFlowSample{countersVersion} - rest of the datagram skipped";
  
            push @errors, $error;
            pop @sFlowSamples;
		        return (\%sFlowDatagram, \@sFlowSamples, \@errors);
          }

        }

        else {

          $error = "ERROR: [sFlow.pm] <sFlowV4:SampleType> AgentIP: $sFlowDatagram{AgentIp}, "
                 . "Datagram: $sFlowDatagram{datagramSequenceNumber} - Unknown sample type: "
                 . "$sFlowSample{sampleType} - rest of the datagram skipped";

          push @errors, $error;
          pop @sFlowSamples;
		      return (\%sFlowDatagram, \@sFlowSamples, \@errors);
        }

      }

    }

  }

####### sFlow V5 #######

  elsif ($sFlowDatagram{sFlowVersion} >= SFLOWv5) {

    # v5 also provides a sub agent id
    (undef,
     $sFlowDatagram{subAgentId}) =
      unpack("a$offset N", $sFlowDatagramPacked);

    $offset += 4;

    (undef,
     $sFlowDatagram{datagramSequenceNumber},
     $sFlowDatagram{agentUptime},
     $sFlowDatagram{samplesInPacket}) =
      unpack("a$offset N3", $sFlowDatagramPacked);

    $offset += 12;

    # boundcheck for $sFlowDatagram{samplesInPacket}
    # $sFlowDatagram{samplesInPacket} * 4
    # cannot be longer than the number of $sFlowDatagramPacked byte - $offset

    if (length($sFlowDatagramPacked) - $offset <
      $sFlowDatagram{samplesInPacket} * 4) {

      # error $sFlowDatagram{samplesInPacket} too big
      $error = "ERROR: [sFlow.pm] Datagram: Samples in packet count too big "
             . "- rest of the datagram skipped";

      push @errors, $error;
      pop @sFlowSamples;
      return (\%sFlowDatagram, \@sFlowSamples, \@errors);

    } elsif ($sFlowDatagram{samplesInPacket} < 0) {

      # error $sFlowDatagram{samplesInPacket} too small
      $error = "ERROR: [sFlow.pm] Datagram: Samples in packet count too small "
             . "- rest of the datagram skipped";

      push @errors, $error;
      pop @sFlowSamples;
      return (\%sFlowDatagram, \@sFlowSamples, \@errors);

    } else {

      # parse samples
      for my $samplesCount (0 .. $sFlowDatagram{samplesInPacket} - 1) {

        my %sFlowSample = ();
        push @sFlowSamples, \%sFlowSample;

        my $sampleType = undef;

        (undef,
        $sampleType,
        $sFlowSample{sampleLength}) =
          unpack("a$offset NN", $sFlowDatagramPacked);

        $offset += 8;

        $sFlowSample{sampleTypeEnterprise} = $sampleType >> 12;
        $sFlowSample{sampleTypeFormat} = $sampleType & 2 ** 12 - 1;

        my $sourceId = undef;

        if ($sFlowSample{sampleTypeEnterprise} == 0
            and $sFlowSample{sampleTypeFormat} == FLOWSAMPLE_SFLOWv5) {

          (undef,
           $sFlowSample{sampleSequenceNumber},
           $sourceId,
           $sFlowSample{samplingRate},
           $sFlowSample{samplePool},
           $sFlowSample{drops},
           $sFlowSample{inputInterface},
           $sFlowSample{outputInterface},
           $sFlowSample{flowRecordsCount}) =
            unpack("a$offset N8", $sFlowDatagramPacked);

          $offset += 32;

          $sFlowSample{sourceIdType} = $sourceId >> 24;
          $sFlowSample{sourceIdIndex} = $sourceId & 2 ** 24 - 1;

          # boundcheck for $sFlowSample{flowRecordsCount}
          # $sFlowSample{flowRecordsCount} * 4
          # cannot be longer than the number of $sFlowDatagramPacked byte - $offset

          if (length($sFlowDatagramPacked) - $offset <
            $sFlowSample{flowRecordsCount} * 4) {

            # error $sFlowSample{flowRecordsCount} too big
            $error = "ERROR: [sFlow.pm] Datagram: Flow records count too big "
                   . "for this packet length - rest of the datagram skipped";

            push @errors, $error;
            pop @sFlowSamples;
            return (\%sFlowDatagram, \@sFlowSamples, \@errors);

          } elsif ($sFlowSample{flowRecordsCount} < 0) {

            # error $sFlowSample{flowRecordsCount} too small
            $error = "ERROR: [sFlow.pm] Datagram: Flow records count too small "
                   . "- rest of the datagram skipped";

            push @errors, $error;
            pop @sFlowSamples;
            return (\%sFlowDatagram, \@sFlowSamples, \@errors);

          } else {

            for my $flowRecords (0 .. $sFlowSample{flowRecordsCount} - 1) {

              ($subProcessed, $error) =
                &_decodeFlowRecord(
                  \$offset,
                  \$sFlowDatagramPacked,
                  \%sFlowDatagram,
                  \%sFlowSample,
                  \@sFlowSamples,
                  \@errors,
                );

              unless ($subProcessed) {
                push @errors, $error;
                pop @sFlowSamples;
                return (\%sFlowDatagram, \@sFlowSamples, \@errors);
              }

            }

          }

        }

        elsif ($sFlowSample{sampleTypeEnterprise} == 0
               and $sFlowSample{sampleTypeFormat} == COUNTERSAMPLE_SFLOWv5) {
  
          (undef,
           $sFlowSample{sampleSequenceNumber},
           $sourceId,
           $sFlowSample{counterRecordsCount}) =
            unpack("a$offset N3", $sFlowDatagramPacked);

          $offset += 12;

          $sFlowSample{sourceIdType} = $sourceId >> 24;
          $sFlowSample{sourceIdIndex} = $sourceId & 2 ** 24 - 1;

          # boundcheck for $sFlowSample{counterRecordsCount}
          # $sFlowSample{counterRecordsCount} * 4
          # cannot be longer than the number of $sFlowDatagramPacked byte - $offset

          if (length($sFlowDatagramPacked) - $offset <
            $sFlowSample{counterRecordsCount} * 4) {

            # error $sFlowSample{counterRecordsCount} too big
            $error = "ERROR: [sFlow.pm] Datagram: Counter records count too big "
                   . "- rest of the datagram skipped";

            push @errors, $error;
            pop @sFlowSamples;
            return (\%sFlowDatagram, \@sFlowSamples, \@errors);

          } elsif ($sFlowSample{counterRecordsCount} < 0) {

            # error $sFlowSample{counterRecordsCount} too small
            $error = "ERROR: [sFlow.pm] Datagram: Counter records count too small "
                   . "- rest of the datagram skipped";

            push @errors, $error;
            pop @sFlowSamples;
            return (\%sFlowDatagram, \@sFlowSamples, \@errors);

          } else {

            for my $counterRecords (0 .. $sFlowSample{counterRecordsCount} - 1) {

              ($subProcessed, $error) =
                &_decodeCounterRecord(
                  \$offset,
                  \$sFlowDatagramPacked,
                  \%sFlowDatagram,
                  \%sFlowSample,
                  \@sFlowSamples,
                );
  
              unless ($subProcessed) {
                push @errors, $error;
                pop @sFlowSamples;
                return (\%sFlowDatagram, \@sFlowSamples, \@errors);
              }

            }

          }

        }

        elsif ($sFlowSample{sampleTypeEnterprise} == 0
               and $sFlowSample{sampleTypeFormat} == EXPANDEDFLOWSAMPLE_SFLOWv5) {
        
          (undef,
           $sFlowSample{sampleSequenceNumber},
           $sFlowSample{sourceIdType},
           $sFlowSample{sourceIdIndex},
           $sFlowSample{samplingRate},
           $sFlowSample{samplePool},
           $sFlowSample{drops},
           $sFlowSample{inputInterfaceFormat},
           $sFlowSample{inputInterfaceValue},
           $sFlowSample{outputInterfaceFormat},
           $sFlowSample{outputInterfaceValue},
           $sFlowSample{flowRecordsCount}) =
            unpack("a$offset N11", $sFlowDatagramPacked);

          $offset += 44;

          # boundcheck for $sFlowSample{flowRecordsCount}
          # $sFlowSample{flowRecordsCount} * 4
          # cannot be longer than the number of $sFlowDatagramPacked byte - $offset

          if (length($sFlowDatagramPacked) - $offset <
            $sFlowSample{flowRecordsCount} * 4) {

            # error $sFlowSample{flowRecordsCount} too big
            $error = "ERROR: [sFlow.pm] Datagram: Flow records count too big "
                   . "for this packet length - rest of the datagram skipped";

            push @errors, $error;
            pop @sFlowSamples;
            return (\%sFlowDatagram, \@sFlowSamples, \@errors);

          } elsif ($sFlowSample{flowRecordsCount} < 0) {

            # error $sFlowSample{flowRecordsCount} too small
            $error = "ERROR: [sFlow.pm] Datagram: Flow records count too small"
                   . "- rest of the datagram skipped";

            push @errors, $error;
            pop @sFlowSamples;
            return (\%sFlowDatagram, \@sFlowSamples, \@errors);

          } else {

            for my $flowRecords (0 .. $sFlowSample{flowRecordsCount} - 1) {

              ($subProcessed, $error) =
                &_decodeFlowRecord(
                  \$offset,
                  \$sFlowDatagramPacked,
                  \%sFlowDatagram,
                  \%sFlowSample,
                  \@sFlowSamples,
                  \@errors,
                );

              unless ($subProcessed) {
                push @errors, $error;
                pop @sFlowSamples;
                return (\%sFlowDatagram, \@sFlowSamples, \@errors);
              }
  
            }
  
          }

        }

        elsif ($sFlowSample{sampleTypeEnterprise} == 0
               and $sFlowSample{sampleTypeFormat} == EXPANDEDCOUNTERSAMPLE_SFLOWv5) {

          (undef,
           $sFlowSample{sampleSequenceNumber},
           $sFlowSample{sourceIdType},
           $sFlowSample{sourceIdIndex},
           $sFlowSample{counterRecordsCount}) =
            unpack("a$offset N4", $sFlowDatagramPacked);

          $offset += 16;
  
          # boundcheck for $sFlowSample{counterRecordsCount}
          # $sFlowSample{counterRecordsCount} * 4
          # cannot be longer than the number of $sFlowDatagramPacked byte - $offset

          if (length($sFlowDatagramPacked) - $offset <
            $sFlowSample{counterRecordsCount} * 4) {

            # error $sFlowSample{counterRecordsCount} too big
            $error = "ERROR: [sFlow.pm] Datagram: Counter records count too big "
                   . "- rest of the datagram skipped";

            push @errors, $error;
            pop @sFlowSamples;
            return (\%sFlowDatagram, \@sFlowSamples, \@errors);

          } elsif ($sFlowSample{counterRecordsCount} < 0) {

            # error $sFlowSample{counterRecordsCount} too small
            $error = "ERROR: [sFlow.pm] Datagram: Counter records count too small "
                   . "- rest of the datagram skipped";

            push @errors, $error;
            pop @sFlowSamples;
            return (\%sFlowDatagram, \@sFlowSamples, \@errors);

          } else {

            for my $counterRecords (0 .. $sFlowSample{counterRecordsCount} - 1) {

              ($subProcessed, $error) =
                &_decodeCounterRecord(
                  \$offset,
                  \$sFlowDatagramPacked,
                  \%sFlowDatagram,
                  \%sFlowSample,
                  \@sFlowSamples,
                );

              unless ($subProcessed) {
                push @errors, $error;
                pop @sFlowSamples;
                return (\%sFlowDatagram, \@sFlowSamples, \@errors);
              }

            }

          }

        }

        elsif ($sFlowSample{sampleTypeEnterprise} == FOUNDRY_ACL_SFLOWv5
               and $sFlowSample{sampleTypeFormat} == FLOWSAMPLE_SFLOWv5) {

          (undef,
           $sFlowSample{FoundryFlags},
           $sFlowSample{FoundryGroupID}) =
            unpack("a$offset N2", $sFlowDatagramPacked);

          $offset += 8;

          $sFlowDatagram{samplesInPacket}++;
          next;

        }

        else {

          $error = "ERROR: [sFlow.pm] <sFlowV5:SampleData> AgentIP: $sFlowDatagram{AgentIp} Datagram: "
                 . "$sFlowDatagram{datagramSequenceNumber} - Unknown sample enterprise: "
                 . "$sFlowSample{sampleTypeEnterprise} or format: $sFlowSample{sampleTypeFormat} "
                 . "- rest of the datagram skipped";
  
          push @errors, $error;
          pop @sFlowSamples;
		      return (\%sFlowDatagram, \@sFlowSamples, \@errors);
        } 

      }

    }

  }

  else {

    $error = "ERROR: [sFlow.pm] AgentIP: $sFlowDatagram{AgentIp}, Datagram: "
           . "$sFlowDatagram{datagramSequenceNumber} - Unknown sFlow Version: "
           . "$sFlowDatagram{sFlowVersion}";

    push @errors, $error;
    %sFlowDatagram = ();
		return (\%sFlowDatagram, \@sFlowSamples, \@errors);
  }
  
  return (\%sFlowDatagram, \@sFlowSamples, \@errors);

}


####  END sub decode() ######################################################



#############################################################################
sub _bin2ip {
#############################################################################

  # _bin2ip is a copy of "to_dotquad" from NetPacket::IP.pm
  # Copyright (c) 2001 Tim Potter.
  # Copyright (c) 2001 Stephanie Wehner.

  my($net) = @_ ;
  my($na, $nb, $nc, $nd);

  $na = $net >> 24 & 255;
  $nb = $net >> 16 & 255;
  $nc = $net >>  8 & 255;
  $nd = $net & 255;

  return ("$na.$nb.$nc.$nd");
}


#############################################################################
sub _decodeIpAddress {
#############################################################################

  my $offsetref = shift;
  my $sFlowDatagramPackedRef = shift;
  my $sFlowDatagram = shift;
  my $sFlowSample = shift;
  my $sFlowSamples = shift;
  my $IpVersion = shift;
  my $keyName = shift;
  my $DatagramOrSampleData = shift;

  my $error = undef;
  my $sFlowDatagramPacked = $$sFlowDatagramPackedRef;
  my $offset = $$offsetref;

  if (defined($DatagramOrSampleData)) {

    if ($IpVersion == IPv4) {

      (undef,
       $sFlowDatagram->{$keyName}) =
        unpack("a$offset N", $sFlowDatagramPacked);

      $sFlowDatagram->{$keyName} = &_bin2ip($sFlowDatagram->{$keyName});
      $offset += 4;
    }

    elsif ($IpVersion == IPv6) {

      $sFlowSample->{$keyName} =
        join(':', unpack("x$offset H4H4H4H4H4H4H4H4", $sFlowDatagramPacked));

      $offset += 16;
    }
  }

  else {

    if ($IpVersion == IPv4) {

      (undef,
       $sFlowSample->{$keyName}) =
        unpack("a$offset N", $sFlowDatagramPacked);

      $sFlowSample->{$keyName} = &_bin2ip($sFlowSample->{$keyName});
      $offset += 4;
    }

    elsif ($IpVersion == IPv6) {

      $sFlowSample->{$keyName} =
        join(':', unpack("x$offset H4H4H4H4H4H4H4H4", $sFlowDatagramPacked));

      $offset += 16;
    }
  }

  if ($IpVersion != IPv4 and $IpVersion != IPv6) {

    if (defined($DatagramOrSampleData)) {

      # unknown ip version added in v5 
      if ($IpVersion == UNKNOWNIPVERSION) {

        $error = "ERROR: [sFlow.pm] AgentIP: Unknown agent ip version: "
               . "$IpVersion - rest of the datagram skipped";

        return (undef, $error);
      }

      else {

        $error = "ERROR: [sFlow.pm] AgentIP: Unknown agent ip version: "
               . "$IpVersion - rest of the datagram skipped";

        return (undef, $error);
      }

    }

    else {

      # unknown ip version added in v5 
      if ($IpVersion == UNKNOWNIPVERSION) {

        $error = "ERROR: [sFlow.pm] AgentIP: $sFlowDatagram->{AgentIp}, "
               . "Datagram: $sFlowDatagram->{datagramSequenceNumber}, Sample: "
               . "$sFlowSample->{sampleSequenceNumber} - Unknown ip version: "
               . "$IpVersion - rest of the datagram skipped";

        return (undef, $error);
      }
    
      else {
        $error = "ERROR: [sFlow.pm] AgentIP: $sFlowDatagram->{AgentIp}, "
               . "Datagram: $sFlowDatagram->{datagramSequenceNumber}, Sample: "
               . "$sFlowSample->{sampleSequenceNumber} - Unknown ip version: "
               . "$IpVersion - rest of the datagram skipped";

        return (undef, $error);
      }

    }

  }

  $$offsetref = $offset;
  return (1, undef);
}


#############################################################################
sub _decodeFlowRecord {
#############################################################################

  my $offsetref = shift;
  my $sFlowDatagramPackedRef = shift;
  my $sFlowDatagram = shift;
  my $sFlowSample = shift;
  my $sFlowSamples = shift;
  my $errors = shift;

  my $sFlowDatagramPacked = $$sFlowDatagramPackedRef;
  my $offset = $$offsetref;
  my $flowType = undef;
  my $flowDataLength = undef;
  my $error = undef;
  my $subProcessed = undef;

  (undef,
   $flowType,
   $flowDataLength) =
    unpack("a$offset NN", $sFlowDatagramPacked);

  $offset += 8;

  my $flowTypeEnterprise = $flowType >> 12;
  my $flowTypeFormat = $flowType & 2 ** 12 - 1;

  if ($flowTypeEnterprise == 0) {

    if ($flowTypeFormat == HEADERDATA_SFLOWv5) {

      ($subProcessed, $error) =
        &_decodeHeaderData(
          \$offset,
          $sFlowDatagramPackedRef,
          $sFlowDatagram,
          $sFlowSample,
          $sFlowSamples,
        );

      unless ($subProcessed) {
        push @{$errors}, $error;
      }

    }

    elsif ($flowTypeFormat == SWITCHDATA_SFLOWv5) {
      &_decodeSwitchData(\$offset, $sFlowDatagramPackedRef, $sFlowSample);
    }

    elsif ($flowTypeFormat == ETHERNETFRAMEDATA_SFLOWv5) {
      &_decodeEthernetFrameData(\$offset, $sFlowDatagramPackedRef, $sFlowSample);
    }

    elsif ($flowTypeFormat == IPv4DATA_SFLOWv5) {
      &_decodeIPv4Data(\$offset, $sFlowDatagramPackedRef, $sFlowSample);
    }

    elsif ($flowTypeFormat == IPv6DATA_SFLOWv5) {
      &_decodeIPv6Data(\$offset, $sFlowDatagramPackedRef, $sFlowSample);
    }

    elsif ($flowTypeFormat == ROUTERDATA_SFLOWv5) {

      ($subProcessed, $error) =
        &_decodeRouterData(
          \$offset,
          $sFlowDatagramPackedRef,
          $sFlowDatagram,
          $sFlowSample,
          $sFlowSamples,
        );

      unless ($subProcessed) {
        return (undef, $error);
      }

    }

    elsif ($flowTypeFormat == GATEWAYDATA_SFLOWv5) {

      ($subProcessed, $error) =
        &_decodeGatewayData(
          \$offset,
          $sFlowDatagramPackedRef,
          $sFlowDatagram,
          $sFlowSample,
          $sFlowSamples,
        );

      unless ($subProcessed) {
        return (undef, $error);
      }

    }

    elsif ($flowTypeFormat == USERDATA_SFLOWv5) {

      ($subProcessed, $error) =
        &_decodeUserData(
          \$offset, 
          $sFlowDatagramPackedRef, 
          $sFlowDatagram, 
          $sFlowSample
        );

      unless ($subProcessed) {
        return (undef, $error);
      }

    }

    elsif ($flowTypeFormat == URLDATA_SFLOWv5) {

      ($subProcessed, $error) =
        &_decodeUrlData(
          \$offset, 
          $sFlowDatagramPackedRef, 
          $sFlowDatagram, 
          $sFlowSample
        );

      unless ($subProcessed) {
        return (undef, $error);
      }

    }

    elsif ($flowTypeFormat == MPLSDATA_SFLOWv5) {

      ($subProcessed, $error) =
        &_decodeMplsData(
          \$offset,
          $sFlowDatagramPackedRef,
          $sFlowDatagram,
          $sFlowSample,
          $sFlowSamples,
        );

      unless ($subProcessed) {
        return (undef, $error);
      }

    }

    elsif ($flowTypeFormat == NATDATA_SFLOWv5) {

      ($subProcessed, $error) =
        &_decodeNatData(
          \$offset,
          $sFlowDatagramPackedRef,
          $sFlowDatagram,
          $sFlowSample,
          $sFlowSamples,
      );

      unless ($subProcessed) {
        return (undef, $error);
      }

    }

    elsif ($flowTypeFormat == MPLSTUNNEL_SFLOWv5) {

      ($subProcessed, $error) =
        &_decodeMplsTunnel(
          \$offset, 
          $sFlowDatagramPackedRef, 
          $sFlowSample
        );

      unless ($subProcessed) {
        return (undef, $error);
      }

    }

    elsif ($flowTypeFormat == MPLSVC_SFLOWv5) {

      ($subProcessed, $error) =
        &_decodeMplsVc(
          \$offset, 
          $sFlowDatagramPackedRef, 
          $sFlowSample
        );

      unless ($subProcessed) {
        return (undef, $error);
      }

    }

    elsif ($flowTypeFormat == MPLSFEC_SFLOWv5) {

      ($subProcessed, $error) =
        &_decodeMplsFec(
          \$offset, 
          $sFlowDatagramPackedRef, 
          $sFlowSample
        );

      unless ($subProcessed) {
        return (undef, $error);
      }

    }

    elsif ($flowTypeFormat == MPLSLVPFEC_SFLOWv5) {
      &_decodeMplsLpvFec(\$offset, $sFlowDatagramPackedRef, $sFlowSample);
    }

    elsif ($flowTypeFormat == VLANTUNNEL_SFLOWv5) {

      ($subProcessed, $error) =
        &_decodeVlanTunnel(
          \$offset, 
          $sFlowDatagramPackedRef, 
          $sFlowSample
        );

      unless ($subProcessed) {
        return (undef, $error);
      }

    }

    else {

      $error = "ERROR: [sFlow.pm] <sFlowV5:FlowData> AgentIP: $sFlowDatagram->{AgentIp}, "
             . "Datagram: $sFlowDatagram->{datagramSequenceNumber}, Sample: "
             . "$sFlowSample->{sampleSequenceNumber} - Unknown Flowdata format: "
             . "$flowTypeFormat - rest of the datagram skipped";

		  return (undef, $error);
    }

  }

  else {

    $error = "ERROR: [sFlow.pm] <sFlowV5:FlowData> AgentIP: $sFlowDatagram->{AgentIp}, "
           . "Datagram: $sFlowDatagram->{datagramSequenceNumber} - Unknown Flowdata enterprise: "
           . "$flowTypeEnterprise - rest of the datagram skipped";

		return (undef, $error);
  }

  $$offsetref = $offset;
  return (1,undef);
}


#############################################################################
sub _decodeCounterRecord {
#############################################################################

  my $offsetref = shift;
  my $sFlowDatagramPackedRef = shift;
  my $sFlowDatagram = shift;
  my $sFlowSample = shift;
  my $sFlowSamples = shift;

  my $sFlowDatagramPacked = $$sFlowDatagramPackedRef;
  my $offset = $$offsetref;
  my $counterType = undef;
  my $counterDataLength = undef;
  my $error = undef;

  (undef,
   $counterType,
   $sFlowSample->{counterDataLength}) =
    unpack("a$offset NN", $sFlowDatagramPacked);

  $offset += 8;

  my $counterTypeEnterprise = $counterType >> 12;
  my $counterTypeFormat = $counterType & 2 ** 12 - 1;

  if ($counterTypeEnterprise == 0) {

    if ($counterTypeFormat == GENERICCOUNTER_SFLOWv5) {
      &_decodeCounterGeneric(\$offset, $sFlowDatagramPackedRef, $sFlowSample);
    }

    elsif ($counterTypeFormat == ETHERNETCOUNTER_SFLOWv5) {
      &_decodeCounterEthernet(\$offset, $sFlowDatagramPackedRef, $sFlowSample);
    }

    elsif ($counterTypeFormat == TOKENRINGCOUNTER_SFLOWv5) {
      &_decodeCounterTokenring(\$offset, $sFlowDatagramPackedRef, $sFlowSample);
    }

    elsif ($counterTypeFormat == VGCOUNTER_SFLOWv5) {
      &_decodeCounterVg(\$offset, $sFlowDatagramPackedRef, $sFlowSample);
    }

    elsif ($counterTypeFormat == VLANCOUNTER_SFLOWv5) {
      &_decodeCounterVlan(\$offset, $sFlowDatagramPackedRef, $sFlowSample);
    }

    elsif ($counterTypeFormat == PROCESSORCOUNTER_SFLOWv5) {
      &_decodeCounterProcessor(\$offset, $sFlowDatagramPackedRef, $sFlowSample);
    }

    else {

      $error = "ERROR: [sFlow.pm] <sFlowV5:CounterData> AgentIP: $sFlowDatagram->{AgentIp}, "
             . "Datagram: $sFlowDatagram->{datagramSequenceNumber} - Unknown counter data format: "
             . "$counterTypeFormat - rest of the datagram skipped";
		  return (undef, $error);
    }

  }

  else {

    $error = "ERROR: [sFlow.pm] <sFlowV5:CounterData> AgentIP: $sFlowDatagram->{AgentIp}, "
           . "Datagram: $sFlowDatagram->{datagramSequenceNumber} - Unknown counter data enterprise: "
           . "$counterTypeEnterprise - rest of the datagram skipped";

	  return (undef, $error);
  }

  $$offsetref = $offset;
  return (1, undef);

}


#############################################################################
sub _decodeHeaderData {
#############################################################################

  my $offsetref = shift;
  my $sFlowDatagramPackedRef = shift;
  my $sFlowDatagram = shift;
  my $sFlowSample = shift;
  my $sFlowSamples = shift;

  my $sFlowDatagramPacked = $$sFlowDatagramPackedRef;
  my $offset = $$offsetref;
  my $vlanTag = 0;
  my $error = undef;

  $sFlowSample->{HEADERDATA} = 'HEADERDATA';

  if ($sFlowDatagram->{sFlowVersion} == SFLOWv5) {

    (undef,
     $sFlowSample->{HeaderProtocol},
     $sFlowSample->{HeaderFrameLength},
     $sFlowSample->{HeaderStrippedLength},
     $sFlowSample->{HeaderSizeByte}) =
      unpack("a$offset N4", $sFlowDatagramPacked);

    $offset += 16;

  } else {

    (undef,
     $sFlowSample->{HeaderProtocol},
     $sFlowSample->{HeaderFrameLength},
     $sFlowSample->{HeaderSizeByte}) =
      unpack("a$offset N3", $sFlowDatagramPacked);

    $offset += 12;

  }

  # check if $sFlowSample->{HeaderSizeByte} has a reasonable value
  # it cannot be more than 256 Byte

  if ($sFlowSample->{HeaderSizeByte} > 256) {

    # error: header size byte too long
    $error = "ERROR: [sFlow.pm] HeaderData: Header data too long";

    return (undef, $error);

  } elsif ($sFlowSample->{HeaderSizeByte} < 0) {

    # error: header size byte too small
    $error = "ERROR: [sFlow.pm] HeaderData: Header data too small";

    return (undef, $error);

  } else {

    # header size in bits
    $sFlowSample->{HeaderSizeBit} =
      $sFlowSample->{HeaderSizeByte} * 8;

    $sFlowSample->{HeaderBin} =
      substr ($sFlowDatagramPacked, $offset, $sFlowSample->{HeaderSizeByte});

    # we have to cut off a $sFlowSample->{HeaderSizeByte} mod 4 == 0 number of bytes
    my $tmp = 4 - ($sFlowSample->{HeaderSizeByte} % 4);
    $tmp == 4 and $tmp = 0;

    $offset += ($sFlowSample->{HeaderSizeByte} + $tmp);

    my $ipdata = undef;

    ($sFlowSample->{HeaderEtherDestMac},
     $sFlowSample->{HeaderEtherSrcMac},
     $sFlowSample->{HeaderType},
     $ipdata) =
      unpack('a6a6H4a*', $sFlowSample->{HeaderBin});

    # analyze ether type
    if ($sFlowSample->{HeaderType} eq ETH_TYPE_VLAN) {

      (undef, $sFlowSample->{HeaderType}, $ipdata) = unpack('nH4a*', $ipdata);
      # add 4 bytes to ethernet header length because of vlan tag
      # this is done later on, if $vlanTag  is set to 1
      $vlanTag = 1;

    }

    if ($sFlowSample->{HeaderType} eq ETH_TYPE_IP) {

      (undef, $sFlowSample->{HeaderDatalen}) = unpack('nn', $ipdata);
      # add ethernet header length
      $sFlowSample->{HeaderDatalen} += 14;
    }

    elsif ($sFlowSample->{HeaderType} eq ETH_TYPE_IPv6) {

      (undef, $sFlowSample->{HeaderDatalen}) = unpack('Nn', $ipdata);
      # add v6 header (not included in v6)
      $sFlowSample->{HeaderDatalen} += 40;
      # add ethernet header length
      $sFlowSample->{HeaderDatalen} += 14;
    }

    elsif ($sFlowSample->{HeaderType} eq ETH_TYPE_ARP) {
      # ARP
      $sFlowSample->{HeaderDatalen} = 64;
    }

    else {
      # unknown
      $sFlowSample->{HeaderDatalen} = 64;
    }

    # add vlan tag length
    if ($vlanTag == 1) {
      $sFlowSample->{HeaderDatalen} += 4;
    }

    if ($sFlowSample->{HeaderDatalen} < 64) {
      $sFlowSample->{HeaderDatalen} = 64;
    }

  } 

  $$offsetref = $offset;
  return (1, undef);

}


#############################################################################
sub _decodeEthernetFrameData {
#############################################################################

  my $offsetref = shift;
  my $sFlowDatagramPackedRef = shift;
  my $sFlowSample = shift;

  my $sFlowDatagramPacked = $$sFlowDatagramPackedRef;
  my $offset = $$offsetref;
  my $EtherSrcMac1 = undef;
  my $EtherSrcMac2 = undef;
  my $EtherDestMac1 = undef;
  my $EtherDestMac2 = undef;

  $sFlowSample->{ETHERNETFRAMEDATA} = 'ETHERNETFRAMEDATA';

  (undef,
   $sFlowSample->{EtherMacPacketlength},
   $EtherSrcMac1,
   $EtherSrcMac2,
   $EtherDestMac1,
   $EtherDestMac2,
   $sFlowSample->{EtherPackettype}) =
    unpack("a$offset N6", $sFlowDatagramPacked);

  $sFlowSample->{EtherSrcMac} = sprintf("%08x%04x", $EtherSrcMac1, $EtherSrcMac2);
  $sFlowSample->{EtherDestMac} = sprintf("%08x%04x", $EtherDestMac1, $EtherDestMac2);

  $offset += 24;
  $$offsetref = $offset;

}


#############################################################################
sub _decodeIPv4Data {
#############################################################################

  my $offsetref = shift;
  my $sFlowDatagramPackedRef = shift;
  my $sFlowSample = shift;

  my $sFlowDatagramPacked = $$sFlowDatagramPackedRef;
  my $offset = $$offsetref;

  $sFlowSample->{IPv4DATA} = 'IPv4DATA';

  (undef,
   $sFlowSample->{IPv4Packetlength},
   $sFlowSample->{IPv4NextHeaderProtocol},
   $sFlowSample->{IPv4srcIp},
   $sFlowSample->{IPv4destIp},
   $sFlowSample->{IPv4srcPort},
   $sFlowSample->{IPv4destPort},
   $sFlowSample->{IPv4tcpFlags},
   $sFlowSample->{IPv4tos}) =
    unpack("a$offset N2B32B32N4", $sFlowDatagramPacked);

  $sFlowSample->{IPv4srcIp} = &_bin2ip($sFlowSample->{IPv4srcIp});
  $sFlowSample->{IPv4destIp} = &_bin2ip($sFlowSample->{IPv4destIp});

  $offset += 32;
  $$offsetref = $offset;

}


#############################################################################
sub _decodeIPv6Data {
#############################################################################

  my $offsetref = shift;
  my $sFlowDatagramPackedRef = shift;
  my $sFlowSample = shift;

  my $sFlowDatagramPacked = $$sFlowDatagramPackedRef;
  my $offset = $$offsetref;

  $sFlowSample->{IPv6DATA} = 'IPv6DATA';

  (undef,
   $sFlowSample->{IPv6Packetlength},
   $sFlowSample->{IPv6NextHeaderProto}) =
    unpack("a$offset N2", $sFlowDatagramPacked);

  $sFlowSample->{IPv6srcIp} =
    join(':', unpack("x$offset H4H4H4H4H4H4H4H4", $sFlowDatagramPacked));

  $sFlowSample->{IPv6destIp} =
    join(':', unpack("x$offset H4H4H4H4H4H4H4H4", $sFlowDatagramPacked));

  (undef,
   $sFlowSample->{IPv6srcPort},
   $sFlowSample->{IPv6destPort},
   $sFlowSample->{IPv6tcpFlags},
   $sFlowSample->{IPv6Priority}) =
    unpack("a$offset N4", $sFlowDatagramPacked);

  $offset += 56;
  $$offsetref = $offset;

}


#############################################################################
sub _decodeSwitchData {
#############################################################################

  my $offsetref = shift;
  my $sFlowDatagramPackedRef = shift;
  my $sFlowSample = shift;

  my $sFlowDatagramPacked = $$sFlowDatagramPackedRef;
  my $offset = $$offsetref;

  $sFlowSample->{SWITCHDATA} = 'SWITCHDATA';

  (undef,
   $sFlowSample->{SwitchSrcVlan},
   $sFlowSample->{SwitchSrcPriority},
   $sFlowSample->{SwitchDestVlan},
   $sFlowSample->{SwitchDestPriority}) =
    unpack("a$offset N4", $sFlowDatagramPacked);

  $offset += 16;
  $$offsetref = $offset;

}


#############################################################################
sub _decodeRouterData {
#############################################################################

  my $offsetref = shift;
  my $sFlowDatagramPackedRef = shift;
  my $sFlowDatagram = shift;
  my $sFlowSample = shift;
  my $sFlowSamples = shift;

  my $sFlowDatagramPacked = $$sFlowDatagramPackedRef;
  my $offset = $$offsetref;
  my $subProcessed = undef;
  my $error = undef;

  $sFlowSample->{ROUTERDATA} = 'ROUTERDATA';

  (undef,
   $sFlowSample->{RouterIpVersionNextHopRouter}) =
    unpack("a$offset N", $sFlowDatagramPacked);

  $offset += 4;

  ($subProcessed, $error) =
    &_decodeIpAddress(
      \$offset,
      $sFlowDatagramPackedRef,
      $sFlowDatagram,
      $sFlowSample,
      $sFlowSamples,
      $sFlowSample->{RouterIpVersionNextHopRouter},
      'RouterIpAddressNextHopRouter',
      undef
    );

  unless ($subProcessed) {
    return (undef, $error);
  }

  (undef,
   $sFlowSample->{RouterSrcMask},
   $sFlowSample->{RouterDestMask}) =
    unpack("a$offset NN", $sFlowDatagramPacked);

  $offset += 8;

  $$offsetref = $offset;
  return (1, undef);

}


#############################################################################
sub _decodeGatewayData {
#############################################################################

  my $offsetref = shift;
  my $sFlowDatagramPackedRef = shift;
  my $sFlowDatagram = shift;
  my $sFlowSample = shift;
  my $sFlowSamples = shift;

  my $sFlowDatagramPacked = $$sFlowDatagramPackedRef;
  my $offset = $$offsetref;
  my $subProcessed = undef;
  my $error = undef;

  $sFlowSample->{GATEWAYDATA} = 'GATEWAYDATA';

  if ($sFlowDatagram->{sFlowVersion} == SFLOWv5) {

    (undef,
     $sFlowSample->{GatewayIpVersionNextHopRouter}) =
      unpack("a$offset N", $sFlowDatagramPacked);

    $offset += 4;

    ($subProcessed, $error) =
      &_decodeIpAddress(
        \$offset,
        $sFlowDatagramPackedRef,
        $sFlowDatagram,
        $sFlowSample,
        $sFlowSamples,
        $sFlowSample->{GatewayIpVersionNextHopRouter},
        'GatewayIpAddressNextHopRouter',
        undef,
      );

    unless ($subProcessed) {
      return (undef, $error);
    }
  }

  (undef,
   $sFlowSample->{GatewayAsRouter},
   $sFlowSample->{GatewayAsSource},
   $sFlowSample->{GatewayAsSourcePeer},
   $sFlowSample->{GatewayDestAsPathsCount}) =
    unpack("a$offset N4", $sFlowDatagramPacked);

  $offset += 16;

  # boundcheck for $sFlowSample->{GatewayDestAsPathsCount}
  # $sFlowSample->{GatewayDestAsPathsCount} * 4 (that will be the min)
  # cannot be longer than the number of $sFlowDatagramPacked byte - $offset

  if (length($sFlowDatagramPacked) - $offset <
    $sFlowSample->{GatewayDestAsPathsCount} * 4) {

    # error $sFlowSample->{GatewayDestAsPaths} too big
    $error = "ERROR: [sFlow.pm] GatewayDestAsPaths: Gateway destination AS paths count too big "
             . "- rest of the datagram skipped";

    return (undef, $error);
 
  } elsif ($sFlowSample->{GatewayDestAsPathsCount} < 0) {
 
    # error $sFlowSample->{GatewayDestAsPaths} too small
    $error = "ERROR: [sFlow.pm] GatewayDestAsPaths: Gateway destination AS paths count too small "
             . "- rest of the datagram skipped";

    return (undef, $error);
  
  } else {

    # array containing the single paths
    my @sFlowAsPaths = ();

    # reference to this array in extended data
    $sFlowSample->{GatewayDestAsPaths} = \@sFlowAsPaths;

    for my $destAsPathCount (0 .. $sFlowSample->{GatewayDestAsPathsCount} - 1) {

      # single path hash
      my %sFlowAsPath = ();

      # reference to this single path hash in the paths array
      push @sFlowAsPaths, \%sFlowAsPath;

      if ($sFlowDatagram->{sFlowVersion} >= SFLOWv4) {

        (undef,
         $sFlowAsPath{asPathSegmentType},
         $sFlowAsPath{lengthAsList}) =
          unpack("a$offset NN", $sFlowDatagramPacked);

        $offset += 8;

      } else {

        $sFlowAsPath{lengthAsList} = 1;

      }

      # boundcheck for $sFlowAsPath{lengthAsList}
      # $sFlowAsPath{lengthAsList} * 4
      # cannot be longer than the number of $sFlowDatagramPacked byte - $offset

      if (length($sFlowDatagramPacked) - $offset <
        $sFlowAsPath{lengthAsList} * 4) {

        # error $sFlowAsPath{lengthAsList} too big
        $error = "ERROR: [sFlow.pm] AsPath: Length AS list too big "
                 . "- rest of the datagram skipped";

        return (undef, $error);

      } elsif ($sFlowAsPath{lengthAsList} < 0) {

        # error $sFlowAsPath{lengthAsList} too small
        $error = "ERROR: [sFlow.pm] AsPath: Length AS list too small "
                 . "- rest of the datagram skipped";

        return (undef, $error);

      } else {

        # array containing the as numbers of a path
        my @sFlowAsNumber = ();

        # referece to this array in path hash
        $sFlowAsPath{AsPath} = \@sFlowAsNumber;

        for my $asListLength (0 .. $sFlowAsPath{lengthAsList} - 1) {

          (undef,
           my $asNumber) =
            unpack("a$offset N", $sFlowDatagramPacked);

          # push as number to array
          push @sFlowAsNumber, $asNumber;
          $offset += 4;
        }

      }

    }

  }

  # communities and localpref added in v.4.
  if ($sFlowDatagram->{sFlowVersion} >= SFLOWv4) {

    (undef,
     $sFlowSample->{GatewayLengthCommunitiesList}) =
      unpack("a$offset N", $sFlowDatagramPacked);

    $offset += 4;

    # boundcheck for $sFlowSample->{GatewayLengthCommunitiesList}
    # $sFlowSample->{GatewayLengthCommunitiesList} * 4
    # cannot be longer than the number of $sFlowDatagramPacked byte - $offset

    if (length($sFlowDatagramPacked) - $offset <
      $sFlowSample->{GatewayLengthCommunitiesList} * 4) {

      # error $sFlowSample->{GatewayLengthCommunitiesList} too big
      $error = "ERROR: [sFlow.pm] GatewayCommunitiesList: Gateway communities list count too big "
               . "- rest of the datagram skipped";

      return (undef, $error);
    
    # $sFlowSample->{GatewayLengthCommunitiesList} might very well be 0
    } elsif ($sFlowSample->{GatewayLengthCommunitiesList} < 0) {

      # error $sFlowSample->{GatewayLengthCommunitiesList} too small
      $error = "ERROR: [sFlow.pm] GatewayCommunitiesList: Gateway communities list count too small "
               . "- rest of the datagram skipped";

      return (undef, $error);

    } else {

      my @sFlowCommunities = ();
      $sFlowSample->{GatewayCommunities} = \@sFlowCommunities;

      for my $commLength (0 .. $sFlowSample->{GatewayLengthCommunitiesList} - 1) {

        (undef,
         my $community) =
          unpack("a$offset N", $sFlowDatagramPacked);

        $community = ($community >> 16) . ':' . ($community & 65535);

        push @sFlowCommunities, $community;
        $offset += 4;
      }

    }

    (undef,
     $sFlowSample->{localPref}) =
      unpack("a$offset N", $sFlowDatagramPacked);

    $offset += 4;

  }

  $$offsetref = $offset;
  return (1, undef);

}


#############################################################################
sub _decodeUserData {
#############################################################################

  my $offsetref = shift;
  my $sFlowDatagramPackedRef = shift;
  my $sFlowDatagram = shift;
  my $sFlowSample = shift;

  my $sFlowDatagramPacked = $$sFlowDatagramPackedRef;
  my $offset = $$offsetref;
  my $error = undef;

  $sFlowSample->{USERDATA} = 'USERDATA';

  if ($sFlowDatagram->{sFlowVersion} == SFLOWv5) {

    (undef,
     $sFlowSample->{UserSrcCharset}) =
      unpack("a$offset N", $sFlowDatagramPacked);

    $offset += 4;
  }

  (undef,
   $sFlowSample->{UserLengthSrcString}) =
    unpack("a$offset N", $sFlowDatagramPacked);

  $offset += 4;

  if ($sFlowSample->{UserLengthSrcString} > length($sFlowDatagramPacked) - $offset) {

    $error = "ERROR: [sFlow.pm] UserData: UserLengthSrcString too big "
           . "- rest of the datagram skipped";

    return (undef, $error);

  } elsif ($sFlowSample->{UserLengthSrcString} < 0) {

    $error = "ERROR: [sFlow.pm] UserData: UserLengthSrcString too small "
           . "- rest of the datagram skipped";

    return (undef, $error);

  } else {

    (undef,
     $sFlowSample->{UserSrcString}) =
      unpack("a$offset A$sFlowSample->{UserLengthSrcString}", $sFlowDatagramPacked);

    # we have to cut off a $sFlowSample->{UserLengthSrcString} mod 4 == 0 number of bytes
    my $tmp = 4 - ($sFlowSample->{UserLengthSrcString} % 4);
    $tmp == 4 and $tmp = 0;

    $offset += ($sFlowSample->{UserLengthSrcString} + $tmp);

  }

  if ($sFlowDatagram->{sFlowVersion} == SFLOWv5) {

    (undef,
     $sFlowSample->{UserDestCharset}) =
      unpack("a$offset N", $sFlowDatagramPacked);

    $offset += 4;
  }

  (undef,
   $sFlowSample->{UserLengthDestString}) =
    unpack("a$offset N", $sFlowDatagramPacked);

  $offset += 4;

  if ($sFlowSample->{UserLengthDestString} > length($sFlowDatagramPacked) - $offset) {

    $error = "ERROR: [sFlow.pm] UserData: UserLengthDestString too big "
           . "- rest of the datagram skipped";

    return (undef, $error);

  } elsif ($sFlowSample->{UserLengthDestString} < 0) {

    $error = "ERROR: [sFlow.pm] UserData: UserLengthDestString too small "
           . "- rest of the datagram skipped";

    return (undef, $error);

  } else {

    (undef,
     $sFlowSample->{UserDestString}) =
      unpack("a$offset A$sFlowSample->{UserLengthDestString}", $sFlowDatagramPacked);

    # we have to cut off a $sFlowSample->{UserLengthDestString} mod 4 == 0 number of bytes
    my $tmp = 4 - ($sFlowSample->{UserLengthDestString} % 4);
    $tmp == 4 and $tmp = 0;

    $offset += ($sFlowSample->{UserLengthDestString} + $tmp);

  }

  $$offsetref = $offset;
  return (1, undef);

}


#############################################################################
sub _decodeUrlData {
#############################################################################

  my $offsetref = shift;
  my $sFlowDatagramPackedRef = shift;
  my $sFlowDatagram = shift;
  my $sFlowSample = shift;

  my $sFlowDatagramPacked = $$sFlowDatagramPackedRef;
  my $offset = $$offsetref;
  my $error = undef;

  $sFlowSample->{URLDATA} = 'URLDATA';

  (undef,
   $sFlowSample->{UrlDirection},
   $sFlowSample->{UrlLength}) =
    unpack("a$offset NN", $sFlowDatagramPacked);

  $offset += 8;

  if ($sFlowSample->{UrlLength} > length($sFlowDatagramPacked) - $offset) {

    $error = "ERROR: [sFlow.pm] UrlData: UrlLength too big "
           . "- rest of the datagram skipped";

    return (undef, $error);

  } elsif ($sFlowSample->{UrlLength} < 0) {

    $error = "ERROR: [sFlow.pm] UrlData: UrlLength too small "
           . "- rest of the datagram skipped";

    return (undef, $error);

  } else {

    (undef,
     $sFlowSample->{Url}) =
      unpack("a$offset A$sFlowSample->{UrlLength}", $sFlowDatagramPacked);

    # we have to cut off a $sFlowSample->{UrlLength} mod 4 == 0 number of bytes
    my $tmp = 4 - ($sFlowSample->{UrlLength} % 4);
    $tmp == 4 and $tmp = 0;

    $offset += ($sFlowSample->{UrlLength} + $tmp);

    if ($sFlowDatagram->{sFlowVersion} == SFLOWv5) {

      (undef,
       $sFlowSample->{UrlHostLength}) =
        unpack("a$offset N", $sFlowDatagramPacked);

      $offset += 4;

      if ($sFlowSample->{UrlHostLength} > length($sFlowDatagramPacked) - $offset) {

        $error = "ERROR: [sFlow.pm] UrlData: UrlHostLength too big "
               . "- rest of the datagram skipped";

        return (undef, $error);

      } elsif ($sFlowSample->{UrlHostLength} < 0) {

        $error = "ERROR: [sFlow.pm] UrlData: UrlHostLength too small "
               . "- rest of the datagram skipped";

        return (undef, $error);

      } else {

        (undef,
         $sFlowSample->{UrlHost}) =
          unpack("a$offset A$sFlowSample->{UrlHostLength}", $sFlowDatagramPacked);

        # we have to cut off a $sFlowSample->{UrlHostLength} mod 4 == 0 number of bytes
        my $tmp = 4 - ($sFlowSample->{UrlHostLength} % 4);
        $tmp == 4 and $tmp = 0;

        $offset += ($sFlowSample->{UrlHostLength} + $tmp);

      }

    }

  }

  $$offsetref = $offset;
  return (1, undef);

}


#############################################################################
sub _decodeMplsData {
#############################################################################

  my $offsetref = shift;
  my $sFlowDatagramPackedRef = shift;
  my $sFlowDatagram = shift;
  my $sFlowSample = shift;
  my $sFlowSamples = shift;

  my $sFlowDatagramPacked = $$sFlowDatagramPackedRef;
  my $offset = $$offsetref;
  my $subProcessed = undef;
  my $error = undef;

  $sFlowSample->{MPLSDATA} = 'MPLSDATA';

  (undef,
   $sFlowSample->{MplsIpVersionNextHopRouter}) =
    unpack("a$offset N", $sFlowDatagramPacked);

  $offset += 4;

  ($subProcessed, $error) =
    &_decodeIpAddress(
      \$offset,
      $sFlowDatagramPackedRef,
      $sFlowDatagram,
      $sFlowSample,
      $sFlowSamples,
      $sFlowSample->{MplsIpVersionNextHopRouter},
      'MplsIpVersionNextHopRouter',
      undef,
    );

  unless ($subProcessed) {
    return (undef, $error);
  }

  (undef,
   $sFlowSample->{MplsInLabelStackCount}) =
    unpack("a$offset N", $sFlowDatagramPacked);

  $offset += 4;

  # boundcheck for $sFlowSample->{MplsInLabelStackCount}
  # $sFlowSample->{MplsInLabelStackCount} * 4
  # cannot be longer than the number of $sFlowDatagramPacked byte - $offset

  if (length($sFlowDatagramPacked) - $offset <
    $sFlowSample->{MplsInLabelStackCount} * 4) {

    # error $sFlowSample->{MplsInLabelStack} too big
    $error = "ERROR: [sFlow.pm] MplsInLabel: Mpls in label stack count too big "
             . "- rest of the datagram skipped";

    return (undef, $error);

  } elsif ($sFlowSample->{MplsInLabelStackCount} < 0) {

    # error $sFlowSample->{MplsInLabelStack} too small
    $error = "ERROR: [sFlow.pm] MplsInLabel: Mpls in label stack count too small "
             . "- rest of the datagram skipped";

    return (undef, $error);

  } else {

    my @MplsInLabelStack = ();
    $sFlowSample->{MplsInLabelStack} = \@MplsInLabelStack;

    for my $MplsInLabelStackCount (0 .. $sFlowSample->{MplsInLabelStackCount} - 1) {

      (undef, my $MplsInLabel) = unpack("a$offset N", $sFlowDatagramPacked);
      push @MplsInLabelStack, $MplsInLabel;
      $offset += 4;
    }

  }

  (undef, 
   $sFlowSample->{MplsOutLabelStackCount}) = 
    unpack("a$offset N", $sFlowDatagramPacked);

  $offset += 4;

  # boundcheck for $sFlowSample->{MplsOutLabelStackCount}
  # $sFlowSample->{MplsOutLabelStackCount} * 4
  # cannot be longer than the number of $sFlowDatagramPacked byte - $offset

  if (length($sFlowDatagramPacked) - $offset <
    $sFlowSample->{MplsOutLabelStackCount} * 4) {

    # error $sFlowSample->{MplsOutLabelStack} too big
    $error = "ERROR: [sFlow.pm] MplsOutLabel: Mpls out label stack count too big "
             . "- rest of the datagram skipped";

    return (undef, $error);

  } elsif ($sFlowSample->{MplsOutLabelStackCount} < 0) {

    # error $sFlowSample->{MplsOutLabelStack} too small
    $error = "ERROR: [sFlow.pm] MplsOutLabel: Mpls out label stack count too small "
             . "- rest of the datagram skipped";

    return (undef, $error);

  } else {

    my @MplsOutLabelStack = ();
    $sFlowSample->{MplsOutLabelStack} = \@MplsOutLabelStack;

    for my $MplsOutLabelStackCount (0 .. $sFlowSample->{MplsOutLabelStackCount} - 1) {

      (undef, my $MplsOutLabel) = unpack("a$offset N", $sFlowDatagramPacked);
      push @MplsOutLabelStack, $MplsOutLabel;
      $offset += 4;
    }

  }

  $$offsetref = $offset;
  return (1, undef);

}


#############################################################################
sub _decodeNatData {
#############################################################################

  my $offsetref = shift;
  my $sFlowDatagramPackedRef = shift;
  my $sFlowDatagram = shift;
  my $sFlowSample = shift;
  my $sFlowSamples = shift;

  my $sFlowDatagramPacked = $$sFlowDatagramPackedRef;
  my $offset = $$offsetref;
  my $subProcessed = undef;
  my $error = undef;

  $sFlowSample->{NATDATA} = 'NATDATA';

  (undef,
   $sFlowSample->{NatIpVersionSrcAddress}) =
    unpack("a$offset N", $sFlowDatagramPacked);

  $offset += 4;

  ($subProcessed, $error) =
    &_decodeIpAddress(
      \$offset,
      $sFlowDatagramPackedRef,
      $sFlowDatagram,
      $sFlowSample,
      $sFlowSamples,
      $sFlowSample->{NatIpVersionSrcAddress},
      'NatIpVersionSrcAddress',
      undef,
    );

  unless ($subProcessed) {
    return (undef, $error);
  }

  (undef,
   $sFlowSample->{NatIpVersionDestAddress}) =
    unpack("a$offset N", $sFlowDatagramPacked);

  $offset += 4;

  ($subProcessed, $error) =
    &_decodeIpAddress(
      \$offset,
      $sFlowDatagramPackedRef,
      $sFlowDatagram,
      $sFlowSample,
      $sFlowSamples,
      $sFlowSample->{NatIpVersionDestAddress},
      'NatIpVersionDestAddress',
      undef,
    );

  unless ($subProcessed) {
    return (undef, $error);
  }

  $$offsetref = $offset;
  return (1, undef);
}


#############################################################################
sub _decodeMplsTunnel {
#############################################################################

  my $offsetref = shift;
  my $sFlowDatagramPackedRef = shift;
  my $sFlowSample = shift;

  my $sFlowDatagramPacked = $$sFlowDatagramPackedRef;
  my $offset = $$offsetref;
  my $error = undef;

  $sFlowSample->{MPLSTUNNEL} = 'MPLSTUNNEL';

  (undef,
   $sFlowSample->{MplsTunnelNameLength}) =
    unpack("a$offset N", $sFlowDatagramPacked);

  $offset += 4;

  if ($sFlowSample->{MplsTunnelNameLength} > length($sFlowDatagramPacked) - $offset) {

    # error $sFlowSample->{MplsTunnelLength} too big
    $error = "ERROR: [sFlow.pm] MplsTunnel: MplsTunnelNameLength too big "
             . "- rest of the datagram skipped";

    return (undef, $error);

  } elsif ($sFlowSample->{MplsTunnelNameLength} < 0) {

    # error $sFlowSample->{MplsTunnelLength} too small
    $error = "ERROR: [sFlow.pm] MplsTunnel: MplsTunnelNameLength too small "
             . "- rest of the datagram skipped";

    return (undef, $error);

  } else {

    (undef,
     $sFlowSample->{MplsTunnelName}) =
      unpack("a$offset A$sFlowSample->{MplsTunnelNameLength}", $sFlowDatagramPacked);

    # we have to cut off a $sFlowSample->{MplsTunnelLength} mod 4 == 0 number of bytes
    my $tmp = 4 - ($sFlowSample->{MplsTunnelNameLength} % 4);
    $tmp == 4 and $tmp = 0;

    $offset += ($sFlowSample->{MplsTunnelNameLength} + $tmp);

    (undef,
     $sFlowSample->{MplsTunnelId},
     $sFlowSample->{MplsTunnelCosValue}) =
      unpack("a$offset NN", $sFlowDatagramPacked);

    $offset += 8;

  }

  $$offsetref = $offset;
  return (1, undef);

}


#############################################################################
sub _decodeMplsVc {
#############################################################################

  my $offsetref = shift;
  my $sFlowDatagramPackedRef = shift;
  my $sFlowSample = shift;

  my $sFlowDatagramPacked = $$sFlowDatagramPackedRef;
  my $offset = $$offsetref;
  my $error = undef;

  $sFlowSample->{MPLSVC} = 'MPLSVC';

  (undef,
   $sFlowSample->{MplsVcInstanceNameLength}) =
    unpack("a$offset N", $sFlowDatagramPacked);

  $offset += 4;

  if ($sFlowSample->{MplsVcInstanceNameLength} > length($sFlowDatagramPacked) - $offset) {

    # error $sFlowSample->{MplsVcInstanceNameLength} too big
    $error = "ERROR: [sFlow.pm] MplsVc: MplsVcInstanceNameLength too big "
             . "- rest of the datagram skipped";

    return (undef, $error);

  } elsif ($sFlowSample->{MplsVcInstanceNameLength} < 0) {

    # error $sFlowSample->{MplsVcInstanceNameLength} too small
    $error = "ERROR: [sFlow.pm] MplsVc: MplsVcInstanceNameLength too small "
             . "- rest of the datagram skipped";

    return (undef, $error);

  } else {

    (undef,
     $sFlowSample->{MplsVcInstanceName}) =
      unpack("a$offset A$sFlowSample->{MplsVcInstanceNameLength}", $sFlowDatagramPacked);

    # we have to cut off a $sFlowSample->{MplsVcInstanceNameLength} mod 4 == 0 number of bytes
    my $tmp = 4 - ($sFlowSample->{MplsVcInstanceNameLength} % 4);
    $tmp == 4 and $tmp = 0;

    $offset += ($sFlowSample->{MplsVcInstanceNameLength} + $tmp);

    (undef,
     $sFlowSample->{MplsVcId},
     $sFlowSample->{MplsVcLabelCosValue}) =
      unpack("a$offset NN", $sFlowDatagramPacked);

    $offset += 8;

  }

  $$offsetref = $offset;
  return (1, undef);

}


#############################################################################
sub _decodeMplsFec {
#############################################################################

  my $offsetref = shift;
  my $sFlowDatagramPackedRef = shift;
  my $sFlowSample = shift;

  my $sFlowDatagramPacked = $$sFlowDatagramPackedRef;
  my $offset = $$offsetref;
  my $error = undef;

  $sFlowSample->{MPLSFEC} = 'MPLSFEC';

  (undef,
   $sFlowSample->{MplsFtnDescrLength}) =
    unpack("a$offset N", $sFlowDatagramPacked);

  $offset += 4;

  if ($sFlowSample->{MplsFtnDescrLength} > length($sFlowDatagramPacked) - $offset) {

    # error $sFlowSample->{{MplsFtnDescrLength} too big
    $error = "ERROR: [sFlow.pm] MplsFec: MplsFtnDescrLength too big "
             . "- rest of the datagram skipped";

    return (undef, $error);

  } elsif ($sFlowSample->{MplsFtnDescrLength} < 0) {

    # error $sFlowSample->{{MplsFtnDescrLength} too small
    $error = "ERROR: [sFlow.pm] MplsFec: MplsFtnDescrLength too small "
             . "- rest of the datagram skipped";

    return (undef, $error);

  } else {

    (undef,
     $sFlowSample->{MplsFtnDescr}) =
      unpack("a$offset A$sFlowSample->{MplsFtnDescrLength}", $sFlowDatagramPacked);

    # we have to cut off a $sFlowSample->{MplsFtrDescrLength} mod 4 == 0 number of bytes
    my $tmp = 4 - ($sFlowSample->{MplsFtrDescrLength} % 4);
    $tmp == 4 and $tmp = 0;

    $offset += ($sFlowSample->{MplsFtrDescrLength} + $tmp);

    (undef, $sFlowSample->{MplsFtnMask}) = unpack("a$offset N", $sFlowDatagramPacked);
    $offset += 4;

  }

  $$offsetref = $offset;
  return (1, undef);

}


#############################################################################
sub _decodeMplsLpvFec {
#############################################################################

  my $offsetref = shift;
  my $sFlowDatagramPackedRef = shift;
  my $sFlowSample = shift;

  my $sFlowDatagramPacked = $$sFlowDatagramPackedRef;
  my $offset = $$offsetref;

  $sFlowSample->{MPLSLPVFEC} = 'MPLSLPVFEC';

  (undef,
   $sFlowSample->{MplsFecAddrPrefixLength}) =
    unpack("a$offset N", $sFlowDatagramPacked);

  $offset += 4;

  $$offsetref = $offset;
}


#############################################################################
sub _decodeVlanTunnel {
#############################################################################

  my $offsetref = shift;
  my $sFlowDatagramPackedRef = shift;
  my $sFlowSample = shift;

  my $sFlowDatagramPacked = $$sFlowDatagramPackedRef;
  my $offset = $$offsetref;
  my $error = undef;

  $sFlowSample->{VLANTUNNEL} = 'VLANTUNNEL';

  (undef,
   $sFlowSample->{VlanTunnelLayerStackCount}) =
    unpack("a$offset N", $sFlowDatagramPacked);

  $offset += 4;

  # boundcheck for $sFlowSample->{VlanTunnelLayerStackCount}
  # $sFlowSample->{VlanTunnelLayerStackCount} * 4
  # cannot be longer than the number of $sFlowDatagramPacked byte - $offset

  if (length($sFlowDatagramPacked) - $offset < 
    $sFlowSample->{VlanTunnelLayerStackCount} * 4) {

    # error $sFlowSample->{VlanTunnelLayerStackCount} too big
    $error = "ERROR: [sFlow.pm] VlanTunnel: Vlan tunnel stack count too big "
             . "- rest of the datagram skipped";

    return (undef, $error);

  } elsif ($sFlowSample->{VlanTunnelLayerStackCount} < 0) {

    # error $sFlowSample->{VlanTunnelLayerStackCount} too small
    $error = "ERROR: [sFlow.pm] VlanTunnel: Vlan tunnel stack count too small "
             . "- rest of the datagram skipped";

    return (undef, $error);

  } else {

    my @VlanTunnelLayerStack = ();
    $sFlowSample->{VlanTunnelLayerStack} = \@VlanTunnelLayerStack;

    for my $VlanTunnelLayerCount (0 .. $sFlowSample->{VlanTunnelLayerStackCount} - 1) {

      (undef, my $VlanTunnelLayer) = unpack("a$offset N", $sFlowDatagramPacked);
      push @VlanTunnelLayerStack, $VlanTunnelLayer;
      $offset += 4;
    }

  }

  $$offsetref = $offset;
  return (1, undef);

}


#############################################################################
sub _decodeCounterGeneric {
#############################################################################

  my $offsetref = shift;
  my $sFlowDatagramPackedRef = shift;
  my $sFlowSample = shift;

  my $sFlowDatagramPacked = $$sFlowDatagramPackedRef;
  my $offset = $$offsetref;
  my $ifSpeed1 = undef;
  my $ifSpeed2 = undef;
  my $ifInOctets1 = undef;
  my $ifInOctets2 = undef;
  my $ifOutOctets1 = undef;
  my $ifOutOctets2 = undef;
  my $ifStatus = undef;

  $sFlowSample->{COUNTERGENERIC} = 'COUNTERGENERIC';

  (undef,
   $sFlowSample->{ifIndex},
   $sFlowSample->{ifType},
   $ifSpeed1,
   $ifSpeed2,
   $sFlowSample->{ifDirection},
   $ifStatus,
   $ifInOctets1,
   $ifInOctets2,
   $sFlowSample->{ifInUcastPkts},
   $sFlowSample->{ifInMulticastPkts},
   $sFlowSample->{ifInBroadcastPkts},
   $sFlowSample->{ifInDiscards},
   $sFlowSample->{ifInErrors},
   $sFlowSample->{ifInUnknownProtos},
   $ifOutOctets1,
   $ifOutOctets2,
   $sFlowSample->{ifOutUcastPkts},
   $sFlowSample->{ifOutMulticastPkts},
   $sFlowSample->{ifOutBroadcastPkts},
   $sFlowSample->{ifOutDiscards},
   $sFlowSample->{ifOutErrors},
   $sFlowSample->{ifPromiscuousMode}) =
    unpack("a$offset N22", $sFlowDatagramPacked);

  $offset += 88;

  $sFlowSample->{ifSpeed} = Math::BigInt->new("$ifSpeed1");
  $sFlowSample->{ifSpeed} = $sFlowSample->{ifSpeed} << 32;
  $sFlowSample->{ifSpeed} += $ifSpeed2;

  $sFlowSample->{ifInOctets} = Math::BigInt->new("$ifInOctets1");
  $sFlowSample->{ifInOctets} = $sFlowSample->{ifInOctets} << 32;
  $sFlowSample->{ifInOctets} += $ifInOctets2;

  $sFlowSample->{ifOutOctets} = Math::BigInt->new("$ifOutOctets1");
  $sFlowSample->{ifOutOctets} = $sFlowSample->{ifOutOctets} << 32;
  $sFlowSample->{ifOutOctets} += $ifOutOctets2;

  # seperate the 32bit status
  $sFlowSample->{ifAdminStatus} = $ifStatus & 0x1;
  $sFlowSample->{ifOperStatus} = ($ifStatus >> 1) & 0x1;

  $$offsetref = $offset;
}


#############################################################################
sub _decodeCounterEthernet {
#############################################################################

  my $offsetref = shift;
  my $sFlowDatagramPackedRef = shift;
  my $sFlowSample = shift;

  my $sFlowDatagramPacked = $$sFlowDatagramPackedRef;
  my $offset = $$offsetref;

  $sFlowSample->{COUNTERETHERNET} = 'COUNTERETHERNET';

  (undef,
   $sFlowSample->{dot3StatsAlignmentErrors},
   $sFlowSample->{dot3StatsFCSErrors},
   $sFlowSample->{dot3StatsSingleCollisionFrames},
   $sFlowSample->{dot3StatsMultipleCollisionFrames},
   $sFlowSample->{dot3StatsSQETestErrors},
   $sFlowSample->{dot3StatsDeferredTransmissions},
   $sFlowSample->{dot3StatsLateCollisions},
   $sFlowSample->{dot3StatsExcessiveCollisions},
   $sFlowSample->{dot3StatsInternalMacTransmitErrors},
   $sFlowSample->{dot3StatsCarrierSenseErrors},
   $sFlowSample->{dot3StatsFrameTooLongs},
   $sFlowSample->{dot3StatsInternalMacReceiveErrors},
   $sFlowSample->{dot3StatsSymbolErrors}) =
    unpack("a$offset N13", $sFlowDatagramPacked);

  $offset += 52;
  $$offsetref = $offset;
}


#############################################################################
sub _decodeCounterTokenring {
#############################################################################

  my $offsetref = shift;
  my $sFlowDatagramPackedRef = shift;
  my $sFlowSample = shift;

  my $sFlowDatagramPacked = $$sFlowDatagramPackedRef;
  my $offset = $$offsetref;

  $sFlowSample->{COUNTERTOKENRING} = 'COUNTERTOKENRING';

  (undef,
   $sFlowSample->{dot5StatsLineErrors},
   $sFlowSample->{dot5StatsBurstErrors},
   $sFlowSample->{dot5StatsACErrors},
   $sFlowSample->{dot5StatsAbortTransErrors},
   $sFlowSample->{dot5StatsInternalErrors},
   $sFlowSample->{dot5StatsLostFrameErrors},
   $sFlowSample->{dot5StatsReceiveCongestions},
   $sFlowSample->{dot5StatsFrameCopiedErrors},
   $sFlowSample->{dot5StatsTokenErrors},
   $sFlowSample->{dot5StatsSoftErrors},
   $sFlowSample->{dot5StatsHardErrors},
   $sFlowSample->{dot5StatsSignalLoss},
   $sFlowSample->{dot5StatsTransmitBeacons},
   $sFlowSample->{dot5StatsRecoverys},
   $sFlowSample->{dot5StatsLobeWires},
   $sFlowSample->{dot5StatsRemoves},
   $sFlowSample->{dot5StatsSingles},
   $sFlowSample->{dot5StatsFreqErrors}) =
    unpack("a$offset N18", $sFlowDatagramPacked);

  $offset += 72;
  $$offsetref = $offset;
}


#############################################################################
sub _decodeCounterVg {
#############################################################################

  my $offsetref = shift;
  my $sFlowDatagramPackedRef = shift;
  my $sFlowSample = shift;

  my $sFlowDatagramPacked = $$sFlowDatagramPackedRef;
  my $offset = $$offsetref;
  my $dot12InHighPriorityOctets1 = undef;
  my $dot12InHighPriorityOctets2 = undef;
  my $dot12InNormPriorityOctets1 = undef;
  my $dot12InNormPriorityOctets2 = undef;
  my $dot12OutHighPriorityOctets1 = undef;
  my $dot12OutHighPriorityOctets2 = undef;
  my $dot12HCInHighPriorityOctets1 = undef;
  my $dot12HCInHighPriorityOctets2 = undef;
  my $dot12HCInNormPriorityOctets1 = undef;
  my $dot12HCInNormPriorityOctets2 = undef;
  my $dot12HCOutHighPriorityOctets1 = undef;
  my $dot12HCOutHighPriorityOctets2 = undef;

  $sFlowSample->{COUNTERVG} = 'COUNTERVG';

  (undef,
   $sFlowSample->{dot12InHighPriorityFrames},
   $dot12InHighPriorityOctets1,
   $dot12InHighPriorityOctets2,
   $sFlowSample->{dot12InNormPriorityFrames},
   $dot12InNormPriorityOctets1,
   $dot12InNormPriorityOctets2,
   $sFlowSample->{dot12InIPMErrors},
   $sFlowSample->{dot12InOversizeFrameErrors},
   $sFlowSample->{dot12InDataErrors},
   $sFlowSample->{dot12InNullAddressedFrames},
   $sFlowSample->{dot12OutHighPriorityFrames},
   $dot12OutHighPriorityOctets1,
   $dot12OutHighPriorityOctets2,
   $sFlowSample->{dot12TransitionIntoTrainings},
   $dot12HCInHighPriorityOctets1,
   $dot12HCInHighPriorityOctets2,
   $dot12HCInNormPriorityOctets1,
   $dot12HCInNormPriorityOctets2,
   $dot12HCOutHighPriorityOctets1,
   $dot12HCOutHighPriorityOctets2) =
    unpack("a$offset N20", $sFlowDatagramPacked);

  $offset += 80;

  $sFlowSample->{dot12InHighPriorityOctets} = Math::BigInt->new("$dot12InHighPriorityOctets1");
  $sFlowSample->{dot12InHighPriorityOctets} = $sFlowSample->{dot12InHighPriorityOctets} << 32;
  $sFlowSample->{dot12InHighPriorityOctets} += $dot12InHighPriorityOctets2;

  $sFlowSample->{dot12InNormPriorityOctets} = Math::BigInt->new("$dot12InNormPriorityOctets1");
  $sFlowSample->{dot12InNormPriorityOctets} = $sFlowSample->{dot12InNormPriorityOctets} << 32;
  $sFlowSample->{dot12InNormPriorityOctets} += $dot12InNormPriorityOctets2;

  $sFlowSample->{dot12OutHighPriorityOctets} = Math::BigInt->new("$dot12OutHighPriorityOctets1");
  $sFlowSample->{dot12OutHighPriorityOctets} = $sFlowSample->{dot12OutHighPriorityOctets} << 32;
  $sFlowSample->{dot12OutHighPriorityOctets} += $dot12OutHighPriorityOctets2;

  $sFlowSample->{dot12HCInHighPriorityOctets} = Math::BigInt->new("$dot12HCInHighPriorityOctets1");
  $sFlowSample->{dot12HCInHighPriorityOctets} = $sFlowSample->{dot12HCInHighPriorityOctets} << 32;
  $sFlowSample->{dot12HCInHighPriorityOctets} += $dot12HCInHighPriorityOctets2;

  $sFlowSample->{dot12HCInNormPriorityOctets} = Math::BigInt->new("$dot12HCInNormPriorityOctets1");
  $sFlowSample->{dot12HCInNormPriorityOctets} = $sFlowSample->{dot12HCInNormPriorityOctets} << 32;
  $sFlowSample->{dot12HCInNormPriorityOctets} += $dot12HCInNormPriorityOctets2;

  $sFlowSample->{dot12HCOutHighPriorityOctets} = Math::BigInt->new("$dot12HCOutHighPriorityOctets1");
  $sFlowSample->{dot12HCOutHighPriorityOctets} = $sFlowSample->{dot12HCOutHighPriorityOctets} << 32;
  $sFlowSample->{dot12HCOutHighPriorityOctets} += $dot12HCOutHighPriorityOctets2;

  $$offsetref = $offset;
}


#############################################################################
sub _decodeCounterVlan {
#############################################################################

  my $offsetref = shift;
  my $sFlowDatagramPackedRef = shift;
  my $sFlowSample = shift;

  my $sFlowDatagramPacked = $$sFlowDatagramPackedRef;
  my $offset = $$offsetref;
  my $octets1 = undef;
  my $octets2 = undef;

  $sFlowSample->{COUNTERVLAN} = 'COUNTERVLAN';

  (undef,
   $sFlowSample->{vlan_id},
   $octets1,
   $octets2,
   $sFlowSample->{ucastPkts},
   $sFlowSample->{multicastPkts},
   $sFlowSample->{broadcastPkts},
   $sFlowSample->{discards}) =
    unpack("a$offset N7", $sFlowDatagramPacked);

  $offset += 28;

  $sFlowSample->{octets} = Math::BigInt->new("$octets1");
  $sFlowSample->{octets} = $sFlowSample->{octets} << 32;
  $sFlowSample->{octets} += $octets2;

  $$offsetref = $offset;
}


#############################################################################
sub _decodeCounterProcessor {
#############################################################################

  my $offsetref = shift;
  my $sFlowDatagramPackedRef = shift;
  my $sFlowSample = shift;

  my $sFlowDatagramPacked = $$sFlowDatagramPackedRef;
  my $offset = $$offsetref;
  my $memoryTotal1 = undef;
  my $memoryTotal2 = undef;
  my $memoryFree1 = undef;
  my $memoryFree2 = undef;

  $sFlowSample->{COUNTERPROCESSOR} = 'COUNTERPROCESSOR';

  (undef,
   $sFlowSample->{cpu5s},
   $sFlowSample->{cpu1m},
   $sFlowSample->{cpu5m},
   $memoryTotal1,
   $memoryTotal2,
   $memoryFree1,
   $memoryFree2) =
    unpack("a$offset N7", $sFlowDatagramPacked);

  $offset += 28;

  $sFlowSample->{memoryTotal} = Math::BigInt->new("$memoryTotal1");
  $sFlowSample->{memoryTotal} = $sFlowSample->{memoryTotal} << 32;
  $sFlowSample->{memoryTotal} += $memoryTotal2;

  $sFlowSample->{memoryFree} = Math::BigInt->new("$memoryFree1");
  $sFlowSample->{memoryFree} = $sFlowSample->{memoryFree} << 32;
  $sFlowSample->{memoryFree} += $memoryFree2;

  $$offsetref = $offset;
}


1;


__END__


=head1 NAME

Net::sFlow - decode sFlow datagrams



=head1 SYNOPSIS

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

    foreach my $sFlowSample (@{$printSamplesRef}) {
      print "\n";
      print "---Sample---\n";
      print "sample sequence number: $sFlowSample->{sampleSequenceNumber}\n";
    }

  }



=head1 DESCRIPTION

The sFlow module provides a mechanism to parse and decode sFlow
datagrams. It supports sFlow version 2/4 (RFC 3176 -
http://www.ietf.org/rfc/rfc3176.txt) and sFlow version 5 (Memo -
http://sflow.org/sflow_version_5.txt).

The module's functionality is provided by a single (exportable)
function, L<decode()|/decode()>.

For more examples have a look into the 'examples' directory.



=head1 FUNCTIONS

=head2 decode()

($datagram, $samples, $error) = Net::sFlow::decode($udp_data);

Returns a HASH reference containing the datagram data,
an ARRAY reference with the sample data (each array element contains a HASH reference for one sample)
and in case of an error a reference to an ARRAY containing the error messages.

=head3 Return Values

=over 4

=item I<$datagram>


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


=item I<$samples>


Reference to a list of HASH references, each one representing one
sample. Depending on the sFlow version and type of hardware where the data comes from
(router, switch, etc.), the hash contains the following additional keys:


In case of sFlow <= 4:

  sampleType
  sampleSequenceNumber
  sourceIdType
  sourceIdIndex

If it's a sFlow <= 4 I<flowsample> you will get the following additional keys:

  samplingRate
  samplePool
  drops
  inputInterface
  outputInterface
  packetDataType
  extendedDataInSample

If it's a sFlow <= 4 I<countersample> you will get these additional keys:

  counterSamplingInterval
  countersVersion

In case of sFlow >= 5 you will first get enterprise, format and length information:

  sampleTypeEnterprise
  sampleTypeFormat
  sampleLength

If the sample is a Foundry ACL based sample (enterprise == 1991 and format == 1) you will receive the following information:

  FoundryFlags
  FoundryGroupID

In case of a I<flowsample> (enterprise == 0 and format == 1):

  sampleSequenceNumber
  sourceIdType
  sourceIdIndex
  samplingRate
  samplePool
  drops
  inputInterface
  outputInterface
  flowRecordsCount

If it's an I<expanded flowsample> (enterprise == 0 and format == 3)
you will get these additional keys instead of inputInterface and outputInterface:

  inputInterfaceFormat
  inputInterfaceValue
  outputInterfaceFormat
  outputInterfaceValue

In case of a I<countersample> (enterprise == 0 and format == 2) or
an I<expanded countersample> (enterprise == 0 and format == 4):

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

Counter processor (only in sFlow v5):

  COUNTERPROCESSOR
  cpu5s
  cpu1m
  cpu5m
  memoryTotal
  memoryFree


=item I<$error>

Reference to a list of error messages.

=back



=head1 CAVEATS

The L<decode()|/decode()> function will blindly attempt to decode the data
you provide. There are some tests for the appropriate values at various
places (where it is feasible to test - like enterprises,
formats, versionnumbers, etc.), but in general the GIGO principle still
stands: Garbage In / Garbage Out.



=head1 SEE ALSO

sFlow v4
http://www.ietf.org/rfc/rfc3176.txt

Format Diagram v4:
http://jasinska.de/sFlow/sFlowV4FormatDiagram/

sFlow v5
http://sflow.org/sflow_version_5.txt

Format Diagram v5:
http://jasinska.de/sFlow/sFlowV5FormatDiagram/

Math::BigInt



=head1 AUTHOR

Elisa Jasinska <elisa.jasinska@ams-ix.net>



=head1 CONTACT

Please send comments or bug reports to <sflow@ams-ix.net>



=head1 COPYRIGHT

Copyright (c) 2008 AMS-IX B.V.

This package is free software and is provided "as is" without express
or implied warranty.  It may be used, redistributed and/or modified
under the terms of the Perl Artistic License (see
http://www.perl.com/perl/misc/Artistic.html)

=cut

