#!/usr/bin/perl
#
#
# Atsushi Kobayashi 
#
# Ie.pm - 2008/04/07
#
# Copyright (c) 2007-2008 NTT Information Sharing Platform Laboratories
#
# This package is free software and is provided "as is" without express
# or implied warranty.  It may be used, redistributed and/or modified
# under the terms of the Perl Artistic License (see
# http://www.perl.com/perl/misc/Artistic.html)
#

package Net::Flow::Ie;

use strict;
use warnings;

use Exporter;
use Math::BigInt;


our $VERSION = '0.01';
our @EXPORT_OK = qw(iedecode addie);

my $ieRef = {
    # NetFlowV9
    
    0=>{ # dummy
	'Name'=>'dummy',
	'Type'=>'octetArray' },
    1=>{ # RFC5102
	'Name'=>'octetDeltaCount',
	'Type'=>'unsigned64' },
    2=>{ # RFC5102
	'Name'=>'packetDeltaCount',
	'Type'=>'unsigned64' },
    4=>{ # RFC5102
	'Name'=>'protocolIdentifier',
	'Type'=>'unsigned8' },
    5=>{ # RFC5102
	'Name'=>'ipClassOfService',
	'Type'=>'unsigned8' },
    6=>{ # RFC5102
	'Name'=>'tcpControlBits',
	'Type'=>'unsigned8' },
    7=>{ # RFC5102
	'Name'=>'sourceTransportPort',
	'Type'=>'unsigned16' },
    8=>{ # RFC5102
	'Name'=>'sourceIPv4Address',
	'Type'=>'ipv4Address' },
    9=>{ # RFC5102
	'Name'=>'sourceIPv4PrefixLength',
	'Type'=>'unsigned8' },
    10=>{ # RFC5102
	'Name'=>'ingressInterface',
	'Type'=>'unsigned32' },
    11=>{ # RFC5102
	'Name'=>'destinationTransportPort',
	'Type'=>'unsigned16' },
    12=>{ # RFC5102
	'Name'=>'destinationIPv4Address',
	'Type'=>'ipv4Address' },
    13=>{ # RFC5102
	'Name'=>'destinationIPv4PrefixLength',
	'Type'=>'unsigned8' },
    14=>{ # RFC5102
	'Name'=>'egressInterface',
	'Type'=>'unsigned32' },
    15=>{ # RFC5102
	'Name'=>'ipNextHopIPv4Address',
	'Type'=>'ipv4Address' },
    16=>{ # RFC5102
	'Name'=>'bgpSourceAsNumber',
	'Type'=>'unsigned32' },
    17=>{ # RFC5102
	'Name'=>'bgpDestinationAsNumber',
	'Type'=>'unsigned32' },
    18=>{ # RFC5102
	'Name'=>'bgpNextHopIPv4Address',
	'Type'=>'ipv4Address' },
    19=>{ # RFC5102
	'Name'=>'postMCastPacketDeltaCount',
	'Type'=>'unsigned64' },
    20=>{ # RFC5102
	'Name'=>'postMCastOctetDeltaCount',
	'Type'=>'unsigned64' },
    21=>{ # RFC5102
	'Name'=>'flowEndSysUpTime',
	'Type'=>'unsigned32' },
    22=>{ # RFC5102
	'Name'=>'flowStartSysUpTime',
	'Type'=>'unsigned32' },
    23=>{ # RFC5102
	'Name'=>'postOctetDeltaCount',
	'Type'=>'unsigned64' },
    24=>{ # RFC5102
	'Name'=>'postPacketDeltaCount',
	'Type'=>'unsigned64' },
    25=>{ # RFC5102
	'Name'=>'minimumIpTotalLength',
	'Type'=>'unsigned64' },
    26=>{ # RFC5102
	'Name'=>'maximumIpTotalLength',
	'Type'=>'unsigned64' },
    27=>{ # RFC5102
	'Name'=>'sourceIPv6Address',
	'Type'=>'ipv6Address' },
    28=>{ # RFC5102
	'Name'=>'destinationIPv6Address',
	'Type'=>'ipv6Address' },
    29=>{ # RFC5102
	'Name'=>'sourceIPv6PrefixLength',
	'Type'=>'unsigned8' },
    30=>{ # RFC5102
	'Name'=>'destinationIPv6PrefixLength',
	'Type'=>'unsigned8' },
    31=>{ # RFC5102
	'Name'=>'flowLabelIPv6',
	'Type'=>'unsigned32' },
    32=>{ # RFC5102
	'Name'=>'icmpTypeCodeIPv4',
	'Type'=>'unsigned16' },
    33=>{ # RFC5102
	'Name'=>'igmpType',
	'Type'=>'unsigned8' },
    36=>{ # RFC5102
	'Name'=>'flowActiveTimeout',
	'Type'=>'unsigned16' },
    37=>{ # RFC5102
	'Name'=>'flowIdleTimeout',
	'Type'=>'unsigned16' },
    
    38=>{ # NetFlowV9
	'Name'=>'ENGINE_TYPE',
	'Type'=>'unsigned8' },
    39=>{ # NetFlowV9
	'Name'=>'ENGINE_ID',
	'Type'=>'unsigned8' },
    
    
    40=>{ # RFC5102
	'Name'=>'exportedOctetTotalCount',
	'Type'=>'unsigned64' },
    41=>{ # RFC5102
	'Name'=>'exportedMessageTotalCount',
	'Type'=>'unsigned64' },
    42=>{ # RFC5102
	'Name'=>'exportedFlowRecordTotalCount',
	'Type'=>'unsigned64' },
    44=>{ # RFC5102
	'Name'=>'sourceIPv4Prefix',
	'Type'=>'ipv4Address' },
    45=>{ # RFC5102
	'Name'=>'destinationIPv4Prefix',
	'Type'=>'ipv4Address' },
    46=>{ # RFC5102
	'Name'=>'mplsTopLabelType',
	'Type'=>'unsigned8' },
    47=>{ # RFC5102
	'Name'=>'mplsTopLabelIPv4Address',
	'Type'=>'ipv4Address' },
    
    48=>{ # NetFlowV9
	'Name'=>'FLOW_SAMPLER_ID',
	'Type'=>'unsigned8' },
    49=>{ # NetFlowV9
	'Name'=>'FLOW_SAMPLER_MODE',
	'Type'=>'unsigned8' },
    50=>{ # NetFlowV9
	'Name'=>'FLOW_SAMPLER_RAMDOM_INTERVAL',
	'Type'=>'unsigned32' },
    
    52=>{ # RFC5102
	'Name'=>'minimumTTL',
	'Type'=>'unsigned8' },
    53=>{ # RFC5102
	'Name'=>'maximumTTL',
	'Type'=>'unsigned8' },
    54=>{ # RFC5102
	'Name'=>'fragmentIdentification',
	'Type'=>'unsigned32' },
    55=>{ # RFC5102
	'Name'=>'postIpClassOfService',
	'Type'=>'unsigned8' },
    56=>{ # RFC5102
	'Name'=>'sourceMacAddress',
	'Type'=>'macAddress' },
    57=>{ # RFC5102
	'Name'=>'postDestinationMacAddress',
	'Type'=>'macAddress' },
    58=>{ # RFC5102
	'Name'=>'vlanId',
	'Type'=>'unsigned16' },
    59=>{ # RFC5102
	'Name'=>'postVlanId',
	'Type'=>'unsigned16' },
    60=>{ # RFC5102
	'Name'=>'ipVersion',
	'Type'=>'unsigned8' },
    61=>{ # RFC5102
	'Name'=>'flowDirection',
	'Type'=>'unsigned8' },
    62=>{ # RFC5102
	'Name'=>'ipNextHopIPv6Address',
	'Type'=>'ipv6Address' },
    63=>{ # RFC5102
	'Name'=>'bgpNextHopIPv6Address',
	'Type'=>'ipv6Address' },
    64=>{ # RFC5102
	'Name'=>'ipv6ExtensionHeaders',
	'Type'=>'unsigned32' },
    70=>{ # RFC5102
	'Name'=>'mplsTopLabelStackSection',
	'Type'=>'octetArray' },
    71=>{ # RFC5102
	'Name'=>'mplsLabelStackSection2',
	'Type'=>'octetArray' },
    72=>{ # RFC5102
	'Name'=>'mplsLabelStackSection3',
	'Type'=>'octetArray' },
    73=>{ # RFC5102
	'Name'=>'mplsLabelStackSection4',
	'Type'=>'octetArray' },
    74=>{ # RFC5102
	'Name'=>'mplsLabelStackSection5',
	'Type'=>'octetArray' },
    75=>{ # RFC5102
	'Name'=>'mplsLabelStackSection6',
	'Type'=>'octetArray' },
    76=>{ # RFC5102
	'Name'=>'mplsLabelStackSection7',
	'Type'=>'octetArray' },
    77=>{ # RFC5102
	'Name'=>'mplsLabelStackSection8',
	'Type'=>'octetArray' },
    78=>{ # RFC5102
	'Name'=>'mplsLabelStackSection9',
	'Type'=>'octetArray' },
    79=>{ # RFC5102
	'Name'=>'mplsLabelStackSection10',
	'Type'=>'octetArray' },
    80=>{ # RFC5102
	'Name'=>'destinationMacAddress',
	'Type'=>'macAddress' },
    81=>{ # RFC5102
	'Name'=>'postSourceMacAddress',
	'Type'=>'macAddress' },
    
    82=>{ # NetFlowV9
	'Name'=>'INTERFACE_NAME',
	'Type'=>'string' },
    83=>{ # NetFlowV9
	'Name'=>'INTERFACE_DESCRIPTION',
	'Type'=>'string' },
    84=>{ # NetFlowV9
	'Name'=>'FLOW_SAMPLER_NAME',
	'Type'=>'string' },
    
    85=>{ # RFC5102
	'Name'=>'octetTotalCount',
	'Type'=>'unsigned64' },
    86=>{ # RFC5102
	'Name'=>'packetTotalCount',
	'Type'=>'unsigned64' },
    88=>{ # RFC5102
	'Name'=>'fragmentOffset',
	'Type'=>'unsigned16' },
    90=>{ # RFC5102
	'Name'=>'mplsVpnRouteDistinguisher',
	'Type'=>'octetArray' },
    
    # RFC5102
    
    128=>{ # RFC5102
	'Name'=>'bgpNextAdjacentAsNumber',
	'Type'=>'unsigned32' },
    129=>{ # RFC5102
	'Name'=>'bgpPrevAdjacentAsNumber',
	'Type'=>'unsigned32' },
    130=>{ # RFC5102
	'Name'=>'exporterIPv4Address',
	'Type'=>'ipv4Address' },
    131=>{ # RFC5102
	'Name'=>'exporterIPv6Address',
	'Type'=>'ipv6Address' },
    132=>{ # RFC5102
	'Name'=>'droppedOctetDeltaCount',
	'Type'=>'unsigned64' },
    133=>{ # RFC5102
	'Name'=>'droppedPacketDeltaCount',
	'Type'=>'unsigned64' },
    134=>{ # RFC5102
	'Name'=>'droppedOctetTotalCount',
	'Type'=>'unsigned64' },
    135=>{ # RFC5102
	'Name'=>'droppedPacketTotalCount',
	'Type'=>'unsigned64' },
    136=>{ # RFC5102
	'Name'=>'flowEndReason',
	'Type'=>'unsigned8' },
    137=>{ # RFC5102
	'Name'=>'commonPropertiesId',
	'Type'=>'unsigned64' },
    138=>{ # RFC5102
	'Name'=>'observationPointId',
	'Type'=>'unsigned32' },
    139=>{ # RFC5102
	'Name'=>'icmpTypeCodeIPv6',
	'Type'=>'unsigned16' },
    140=>{ # RFC5102
	'Name'=>'mplsTopLabelIPv6Address',
	'Type'=>'ipv6Address' },
    141=>{ # RFC5102
	'Name'=>'lineCardId',
	'Type'=>'unsigned32' },
    142=>{ # RFC5102
	'Name'=>'portId',
	'Type'=>'unsigned32' },
    143=>{ # RFC5102
	'Name'=>'meteringProcessId',
	'Type'=>'unsigned32' },
    144=>{ # RFC5102
	'Name'=>'exportingProcessId',
	'Type'=>'unsigned32' },
    145=>{ # RFC5102
	'Name'=>'templateId',
	'Type'=>'unsigned16' },
    146=>{ # RFC5102
	'Name'=>'wlanChannelId',
	'Type'=>'unsigned8' },
    147=>{ # RFC5102
	'Name'=>'wlanSSID',
	'Type'=>'string' },
    148=>{ # RFC5102
	'Name'=>'flowId',
	'Type'=>'unsigned64' },
    149=>{ # RFC5102
	'Name'=>'observationDomainId',
	'Type'=>'unsigned32' },
    150=>{ # RFC5102
	'Name'=>'flowStartSeconds',
	'Type'=>'dateTimeSeconds' },
    151=>{ # RFC5102
	'Name'=>'flowEndSeconds',
	'Type'=>'dateTimeSeconds' },
    152=>{ # RFC5102
	'Name'=>'flowStartMilliseconds',
	'Type'=>'dateTimeMilliseconds' },
    153=>{ # RFC5102
	'Name'=>'flowEndMilliseconds',
	'Type'=>'dateTimeMilliseconds' },
    154=>{ # RFC5102
	'Name'=>'flowStartMicroseconds',
	'Type'=>'dateTimeMicroseconds' },
    155=>{ # RFC5102
	'Name'=>'flowEndMicroseconds',
	'Type'=>'dateTimeMicroseconds' },
    156=>{ # RFC5102
	'Name'=>'flowStartNanoseconds',
	'Type'=>'dateTimeNanoseconds' },
    157=>{ # RFC5102
	'Name'=>'flowEndNanoseconds',
	'Type'=>'dateTimeNanoseconds' },
    158=>{ # RFC5102
	'Name'=>'flowStartDeltaMicroseconds',
	'Type'=>'unsigned32' },
    159=>{ # RFC5102
	'Name'=>'flowEndDeltaMicroseconds',
	'Type'=>'unsigned32' },
    160=>{ # RFC5102
	'Name'=>'systemInitTimeMilliseconds',
	'Type'=>'unsigned32' },
    161=>{ # RFC5102
	'Name'=>'flowDurationMilliseconds',
	'Type'=>'unsigned32' },
    162=>{ # RFC5102
	'Name'=>'flowDurationMicroseconds',
	'Type'=>'unsigned32' },
    163=>{ # RFC5102
	'Name'=>'observedFlowTotalCount',
	'Type'=>'unsigned64' },
    164=>{ # RFC5102
	'Name'=>'ignoredPacketTotalCount',
	'Type'=>'unsigned64' },
    165=>{ # RFC5102
	'Name'=>'ignoredOctetTotalCount',
	'Type'=>'unsigned64' },
    166=>{ # RFC5102
	'Name'=>'notSentFlowTotalCount',
	'Type'=>'unsigned64' },
    167=>{ # RFC5102
	'Name'=>'notSentPacketTotalCount',
	'Type'=>'unsigned64' },
    168=>{ # RFC5102
	'Name'=>'notSentOctetTotalCount',
	'Type'=>'unsigned64' },
    169=>{ # RFC5102
	'Name'=>'destinationIPv6Prefix',
	'Type'=>'ipv6Address' },
    170=>{ # RFC5102
	'Name'=>'sourceIPv6Prefix',
	'Type'=>'ipv6Address' },
    171=>{ # RFC5102
	'Name'=>'postOctetTotalCount',
	'Type'=>'unsigned64' },
    172=>{ # RFC5102
	'Name'=>'postPacketTotalCount',
	'Type'=>'unsigned64' },
    173=>{ # RFC5102
	'Name'=>'flowKeyIndicator',
	'Type'=>'unsigned64' },
    174=>{ # RFC5102
	'Name'=>'postMCastPacketTotalCount',
	'Type'=>'unsigned64' },
    175=>{ # RFC5102
	'Name'=>'postMCastOctetTotalCount',
	'Type'=>'unsigned64' },
    176=>{ # RFC5102
	'Name'=>'icmpTypeIPv4',
	'Type'=>'unsigned8' },
    177=>{ # RFC5102
	'Name'=>'icmpCodeIPv4',
	'Type'=>'unsigned8' },
    178=>{ # RFC5102
	'Name'=>'icmpTypeIPv6',
	'Type'=>'unsigned8' },
    179=>{ # RFC5102
	'Name'=>'icmpCodeIPv6',
	'Type'=>'unsigned8' },
    180=>{ # RFC5102
	'Name'=>'udpSourcePort',
	'Type'=>'unsigned16' },
    181=>{ # RFC5102
	'Name'=>'udpDestinationPort',
	'Type'=>'unsigned16' },
    182=>{ # RFC5102
	'Name'=>'tcpSourcePort',
	'Type'=>'unsigned16' },
    183=>{ # RFC5102
	'Name'=>'tcpDestinationPort',
	'Type'=>'unsigned16' },
    184=>{ # RFC5102
	'Name'=>'tcpSequenceNumber',
	'Type'=>'unsigned32' },
    185=>{ # RFC5102
	'Name'=>'tcpAcknowledgementNumber',
	'Type'=>'unsigned32' },
    186=>{ # RFC5102
	'Name'=>'tcpWindowSize',
	'Type'=>'unsigned16' },
    187=>{ # RFC5102
	'Name'=>'tcpUrgentPointer',
	'Type'=>'unsigned16' },
    188=>{ # RFC5102
	'Name'=>'tcpHeaderLength',
	'Type'=>'unsigned8' },
    189=>{ # RFC5102
	'Name'=>'ipHeaderLength',
	'Type'=>'unsigned8' },
    190=>{ # RFC5102
	'Name'=>'totalLengthIPv4',
	'Type'=>'unsigned16' },
    191=>{ # RFC5102
	'Name'=>'payloadLengthIPv6',
	'Type'=>'unsigned16' },
    192=>{ # RFC5102
	'Name'=>'ipTTL',
	'Type'=>'unsigned8' },
    193=>{ # RFC5102
	'Name'=>'nextHeaderIPv6',
	'Type'=>'unsigned8' },
    194=>{ # RFC5102
	'Name'=>'mplsPayloadLength',
	'Type'=>'unsigned32' },
    195=>{ # RFC5102
	'Name'=>'ipDiffServCodePoint',
	'Type'=>'unsigned8' },
    196=>{ # RFC5102
	'Name'=>'ipPrecedence',
	'Type'=>'unsigned8' },
    197=>{ # RFC5102
	'Name'=>'fragmentFlags',
	'Type'=>'unsigned8' },
    198=>{ # RFC5102
	'Name'=>'octetDeltaSumOfSquares',
	'Type'=>'unsigned64' },
    199=>{ # RFC5102
	'Name'=>'octetTotalSumOfSquares',
	'Type'=>'unsigned64' },
    200=>{ # RFC5102
	'Name'=>'mplsTopLabelTTL',
	'Type'=>'unsigned8' },
    201=>{ # RFC5102
	'Name'=>'mplsLabelStackLength',
	'Type'=>'unsigned32' },
    202=>{ # RFC5102
	'Name'=>'mplsLabelStackDepth',
	'Type'=>'unsigned32' },
    203=>{ # RFC5102
	'Name'=>'mplsTopLabelExp',
	'Type'=>'unsigned8' },
    204=>{ # RFC5102
	'Name'=>'ipPayloadLength',
	'Type'=>'unsigned32' },
    205=>{ # RFC5102
	'Name'=>'udpMessageLength',
	'Type'=>'unsigned16' },
    206=>{ # RFC5102
	'Name'=>'isMulticast',
	'Type'=>'unsigned8' },
    207=>{ # RFC5102
	'Name'=>'ipv4IHL',
	'Type'=>'unsigned8' },
    208=>{ # RFC5102
	'Name'=>'ipv4Options',
	'Type'=>'unsigned32' },
    209=>{ # RFC5102
	'Name'=>'tcpOptions',
	'Type'=>'unsigned64' },
    210=>{ # RFC5102
	'Name'=>'paddingOctets',
	'Type'=>'octetArray' },
    211=>{ # RFC5102
	'Name'=>'collectorIPv4Address',
	'Type'=>'ipv4Address' },
    212=>{ # RFC5102
	'Name'=>'collectorIPv6Address',
	'Type'=>'ipv6Address' },
    213=>{ # RFC5102
	'Name'=>'exportInterface',
	'Type'=>'unsigned32' },
    214=>{ # RFC5102
	'Name'=>'exportProtocolVersion',
	'Type'=>'unsigned8' },
    215=>{ # RFC5102
	'Name'=>'exportTransportProtocol',
	'Type'=>'unsigned8' },
    216=>{ # RFC5102
	'Name'=>'collectorTransportPort',
	'Type'=>'unsigned16' },
    217=>{ # RFC5102
	'Name'=>'exporterTransportPort',
	'Type'=>'unsigned16' },
    218=>{ # RFC5102
	'Name'=>'tcpSynTotalCount',
	'Type'=>'unsigned64' },
    219=>{ # RFC5102
	'Name'=>'tcpFinTotalCount',
	'Type'=>'unsigned64' },
    220=>{ # RFC5102
	'Name'=>'tcpRstTotalCount',
	'Type'=>'unsigned64' },
    221=>{ # RFC5102
	'Name'=>'tcpPshTotalCount',
	'Type'=>'unsigned64' },
    222=>{ # RFC5102
	'Name'=>'tcpAckTotalCount',
	'Type'=>'unsigned64' },
    223=>{ # RFC5102
	'Name'=>'tcpUrgTotalCount',
	'Type'=>'unsigned64' },
    224=>{ # RFC5102
	'Name'=>'ipTotalLength',
	'Type'=>'unsigned64' },
    237=>{ # RFC5102
	'Name'=>'postMplsTopLabelExp',
	'Type'=>'unsigned8' },
    238=>{ # RFC5102
	'Name'=>'tcpWindowScale',
	'Type'=>'unsigned16' },
};

sub addie {
    my( $Ref) = @_ ;

    return $ieRef if !(defined $Ref && ref $Ref) ;
    
    foreach my $id (keys %{$Ref} ){
	$$ieRef{$id}->{Name} = $$Ref{$id}->{Name} ;
	$$ieRef{$id}->{Type} = $$Ref{$id}->{Type} ;
    }
    
    return $ieRef ;
    
}

sub iedecode {
    my( $id,$bvalue,$Ref) = @_ ;
    my $value = undef ;
    
    if( !(defined $Ref && ref $Ref) ){
	$Ref = $ieRef ;
    }
    
    $Ref->{$id}->{Name} = "unknown".$id if !defined $Ref->{$id}->{Name} ;
    $Ref->{$id}->{Type} = "octetArray"  if !defined $Ref->{$id}->{Type} ;
    
    if( defined $bvalue ){
	
	if( ref $bvalue ){
	    
	    foreach my $eachvalue ( @{$bvalue} ){
		
		$value .= &eachdecode($id,$eachvalue,$Ref) . "," ;
				    
	    }

	    chop($value) ;
		
	}else{
	    
	    $value = &eachdecode($id,$bvalue,$Ref) ;
	    
	}
	
    }

    return(
	   $Ref->{$id}->{Name},
	   $value
	   ) ;
    
}

sub eachdecode {
    
    my( $id,$bvalue,$Ref) = @_ ;
    my $value = undef ;
    
    if( $Ref->{$id}->{Type} =~ /^unsigned/ ){

	my $length = length($bvalue) ;

	if( $length == 1 ){

	    $value = unpack("C",$bvalue) ;

	}elsif( $length == 2 ){

	    $value = unpack("n",$bvalue) ;
	    
	}elsif( $length == 4 ){

	    $value = unpack("N",$bvalue) ;

	}elsif( $length == 8 ){

	    my $bigvalue = Math::BigInt->new();
	    my ($value1,$value2) = unpack("NN",$bvalue) ;
	    $bigvalue += $value1<<32 ;
	    $bigvalue += $value2 ;
	    $value = $bigvalue->bstr() ;

	}else{
    
	    $value = unpack("H*",$bvalue) ;
	    
	}

    }elsif( $Ref->{$id}->{Type} eq "ipv4Address" ){
	
	my @ipv4 = unpack("C4",$bvalue) ;
	$value = $ipv4[0] .".". $ipv4[1] .".". $ipv4[2].".". $ipv4[3] ;
	
    }elsif( $Ref->{$id}->{Type} eq "ipv6Address" ){
	
	my @ipv6 = unpack("H4"x8,$bvalue) ;
	
	foreach my $field (@ipv6){

	    $field =~ s/^0+// ;
	    $value .= $field . ":" ;
	    
	}
	
	chop($value) ;
	$value =~ s/\:\:+/\:\:/ ;
	
    }elsif( $Ref->{$id}->{Type} eq "macAddress" ){
    
	$value = unpack("H*",$bvalue) ;
	$value =~ s/([0-9a-f]{2})/$1\:/g ;
    
    }elsif( $Ref->{$id}->{Type} eq "octetArray" ){
    
	$value = unpack("H*",$bvalue) ;
    
    }elsif( $Ref->{$id}->{Type} eq "string" ){
    
	my $num = index($bvalue,pack("H*",0x00)) ;

	if( $num == 1 ){
	    $value = pack("a*",$bvalue) ;
	}else{
	    $value = pack("a$num",$bvalue) ;
	}
    
    }else{
    
	$value = unpack("H*",$bvalue) ;
    
    }

    return( $value );
  
}

1;

__END__

=head1 NAME


Net::Flow::Ie - decode NetFlow/IPFIX information elements.


=head1 SYNOPSIS

=head2 EXAMPLE#1 - Output Flow Records of NetFlow v5, v9 and IPFIX -

The following script simply outputs the received Flow Records after decoding NetFlow/IPFIX datagrams by using Net::Flow. Net::Flow::Ie can decode binary data by giving element id and type of data. 

use strict ;
use Net::Flow qw(decode) ;
use Net::Flow::Ie qw(decode addie) ;
use Ie qw(iedecode addie) ;
use IO::Socket::INET;

my $receive_port = 4739 ;
my $packet = undef ;
my $TemplateArrayRef = undef ;
my $sock = IO::Socket::INET->new( LocalPort =>$receive_port, Proto => 'udp') ;
my $ieRef = Net::Flow::Ie::addie() ;

while ($sock->recv($packet,1548)) {
    
    my ($HeaderHashRef,$FlowArrayRef,$ErrorsArrayRef)=() ;
    
    ( $HeaderHashRef,
      $TemplateArrayRef,
      $FlowArrayRef,
      $ErrorsArrayRef)
	= Net::Flow::decode(
			    \$packet,
			    $TemplateArrayRef
			    ) ;

    grep{ print "$_\n" }@{$ErrorsArrayRef} if( @{$ErrorsArrayRef} ) ;
    
    print "\n- Header Information -\n" ;
    foreach my $Key ( sort keys %{$HeaderHashRef} ){
	printf " %s = %3d\n",$Key,$HeaderHashRef->{$Key} ;
    }
    
    foreach my $TemplateRef ( @{$TemplateArrayRef} ){
	print "\n-- Template Information --\n" ;
	
	foreach my $TempKey ( sort {$a <=> $b} keys %{$TemplateRef} ){
	    if( $TempKey eq "Template" ){
		
		printf "  %s = \n",$TempKey ;
		
		foreach my $Ref ( @{$$TemplateRef{Template}}  ){
		    
		    foreach my $Key ( keys %{$Ref} ){
			
			printf "   %s=%-3d Name=%-30s Type=%-10s",
			$Key, $$Ref{$Key}, $$ieRef{$$Ref{$Key}}->{Name},
			$$ieRef{$$Ref{$Key}}->{Type} if $Key eq "Id" ;
			
			printf "   %s=%-3d", $Key, $$Ref{$Key} if $Key eq "Length" ;
			
		    }

		    print "\n" ;
		    
		}
		
	    }else{
		
		printf "  %s = %s\n", $TempKey, $$TemplateRef{$TempKey} ;
		
	    }
	    
	}
	
    }

    foreach my $FlowRef ( @{$FlowArrayRef} ){
	print "\n-- Flow Information --\n" ;
	
	foreach my $Id ( sort {$a <=> $b} keys %{$FlowRef} ){
	    
	    if( $Id eq "SetId" ){
		
		print "  $Id=$$FlowRef{$Id}\n" if defined $$FlowRef{$Id} ;
		
	    }else{
		
		printf "  Id=%-3d Name=%-30s Value=%s\n",
		$Id, Net::Flow::Ie::decode($Id,$$FlowRef{$Id}) ;
		
	    }
	    
	}
	
    }
    
}

=head1 DESCRIPTION



=head1 FUNCTIONS

=head2 decode function

    ( $Name, $Value ) =
       Net::Flow::Ie::iedecode( $Id, $BinValue, $IeRef ) ;

It returns a pair of name and value of information element by giving the information element id and the binary data of associated information element.
This module has information element data that includes id, name, and data type, such as "1", "octetDeltaCount" and  "unsigned64". As default, if it can not find id number in the information element data, it change binary data to hex data.  If you want to add new information elements, such as enterprise id, you can put $IeRef. $IeRef is the reference that points information elements data, as follows. And also, you can use the return value of addie function. The return value is merged into information element data kept in this module.

    my $ieRef = {

	0=>{ 
	    'Name'=>'dummy',
	    'Type'=>'octetArray' },
	1=>{ 
	    'Name'=>'octetDeltaCount',
	    'Type'=>'unsigned64' },
	1000.1=>{ 
	    'Name'=>'enterprise.octetDeltaCount',
	    'Type'=>'unsigned64' },

    } ;

In addition, if you want to decode multiple binary data in same id, you can set input $BinValue as the reference of Array including each binary data. In that case, the return $Value is shown as the concatenation string of multiple data values using delimiter. Regarding data type and information elements, please see for detail.

=back

=head2 addie method

    $IeRef = Net::Flow::Ie::addie( $AddRef ) ;

You can add your original information elements into data set kept in this module. The return value $IeRef indicates the reference of merged information elements data.

=head3 Return Values

=over 4

=item I<$IeRef>

=back

=head1 SEE ALSO

=head1 AUTHOR

Atsushi Kobayashi

=head1 COPYRIGHT

Copyright (c) 2007-2008 NTT Information Sharing Platform Laboratories

This package is free software and is provided "as is" without express or implied warranty.  It may be used, redistributed and/or modified under the terms of the Perl Artistic License (see http://www.perl.com/perl/misc/Artistic.html)

=cut
