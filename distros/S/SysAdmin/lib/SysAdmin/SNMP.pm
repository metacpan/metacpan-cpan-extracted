
package SysAdmin::SNMP;

use Moose;
use Net::SNMP;
extends 'SysAdmin';

our $VERSION = 0.09;

has 'ip'        => (isa => 'Str', is => 'rw', required => 1, default => "localhost");
has 'community' => (isa => 'Str', is => 'rw', required => 1, default => "public");
has 'port'      => (isa => 'Str', is => 'rw', required => 0, default => 161);

__PACKAGE__->meta->make_immutable;



sub _create_snmp_session {
	
	my ($self) = @_;
	
	my ($session, $error) = Net::SNMP->session(Hostname  => $self->ip(), 
		                                       Community => $self->community(),
											   Port      => $self->port());
	if (!defined($session)) {
		Carp::croak sprintf("## WARNING ##\n%s", $error);
		exit 1;
	}
	
	return $session;
}

sub snmpwalk {
	
	my ($self, $oid_to_get) = @_;
	
	Carp::croak "## WARNING ##\nNo OID supplied!" unless $oid_to_get;
	
	my $session = SysAdmin::SNMP::_create_snmp_session($self);
	
	my $response = undef;
	my %hash_to_return_from_sub = ();
	
	if (!defined($response = $session->get_table($oid_to_get))) {
		Carp::croak sprintf("## WARNING ##\n%s\n", $session->error);
		$session->close;
		exit 1;
	}
	
	## Test $response for HASH
	if (ref($response) ne 'HASH') {
		Carp::croak "## WARNING ##\nExpected a hash reference, not $response\n";
	}
	
	foreach my $key (sort keys %$response) {
		
		## Use regex to extract only the oid value different from
		## $oid_to_get.
		
		if ($key =~ /($oid_to_get)\.(\d+)/){
			## For Debugging
			#print "Key: $2 " . "Interface: " . $$response{$key} . "\n";
			$hash_to_return_from_sub{$2} = $$response{$key}
		}
	}
	
	$session->close;
	return \%hash_to_return_from_sub;

}

sub snmpget {
	
	my ($self, $oid_to_get) = @_;
	
	Carp::croak "No OID supplied" unless $oid_to_get;
	
	my $session = SysAdmin::SNMP::_create_snmp_session($self);
	
	my $response = undef;
	my $scalar_to_return_from_sub = undef;
	
	if (!defined($response = $session->get_request($oid_to_get))) {
		Carp::croak sprintf("## WARNING ##\n%s\n", $session->error);
		$session->close;
		exit 1;
	}
	
	## Test $response for HASH
	if (ref($response) ne 'HASH') {
		Carp::croak "## WARNING ##\nExpected a hash reference, not $response\n";
	}

	$scalar_to_return_from_sub = $response->{$oid_to_get};
	
	$session->close;
	return $scalar_to_return_from_sub;

}

sub fetchInterfaces {
	
	my ($self) = @_;
	
	my $ifIndex = '.1.3.6.1.2.1.2.2.1.1';
	my $ifDescr = '.1.3.6.1.2.1.2.2.1.2';
	my $ifType = '.1.3.6.1.2.1.2.2.1.3';
	my $ifAdminStatus = '.1.3.6.1.2.1.2.2.1.7';
	my $ifOperStatus = '.1.3.6.1.2.1.2.2.1.8';
	my $ifAlias = '.1.3.6.1.2.1.31.1.1.1.18';
	
	my $session = SysAdmin::SNMP::_create_snmp_session($self);
	
	my $ifIndex_ref = SysAdmin::SNMP::snmpwalk($self,$ifIndex);
	
	my %interfaces_to_return = ();
	
	foreach my $key (sort keys %$ifIndex_ref) {
		
		my $ifDescr_index       = "$ifDescr.$key";
		my $ifType_index        = "$ifType.$key";
		my $ifAdminStatus_index = "$ifAdminStatus.$key";
		my $ifOperStatus_index  = "$ifOperStatus.$key";
		my $ifAlias_index       = "$ifAlias.$key";
	
		my $ifDescr_response       = undef;
		my $ifType_response        = undef;
		my $ifAdminStatus_response = undef;
		my $ifOperStatus_response  = undef;
		my $ifAlias_response       = undef;
		
		$interfaces_to_return{$key}{'ifIndex'} = $key;
		
		if (defined( $ifDescr_response = $session->get_request($ifDescr_index)) ){
			$interfaces_to_return{$key}{'ifDescr'} = $ifDescr_response->{$ifDescr_index};
		}
		else{
			$interfaces_to_return{$key}{'ifDescr'} = "N/A";
		}
		if (defined( $ifType_response = $session->get_request($ifType_index)) ){
			$interfaces_to_return{$key}{'ifType'} = $ifType_response->{$ifType_index};
			
			my $ifType_name = SysAdmin::SNMP::_interface_type_sub($ifType_response->{$ifType_index});
			$interfaces_to_return{$key}{'ifType_name'} = $ifType_name;			
		}
		else{
			$interfaces_to_return{$key}{'ifType'} = "N/A";
			$interfaces_to_return{$key}{'ifType_name'} = "N/A";
		}
		if (defined( $ifAdminStatus_response = $session->get_request($ifAdminStatus_index)) ){
			$interfaces_to_return{$key}{'ifAdminStatus'} = $ifAdminStatus_response->{$ifAdminStatus_index};
		}
		else{
			$interfaces_to_return{$key}{'ifAdminStatus'} = "N/A";
		}
		if (defined( $ifOperStatus_response = $session->get_request($ifOperStatus_index)) ){
			$interfaces_to_return{$key}{'ifOperStatus'} = $ifOperStatus_response->{$ifOperStatus_index};
		}
		else{
			$interfaces_to_return{$key}{'ifOperStatus'} = "N/A";
		}
		if (defined( $ifAlias_response = $session->get_request($ifAlias_index)) ){
			$interfaces_to_return{$key}{'ifAlias'} = $ifAlias_response->{$ifAlias_index};
		}
		else{
			$interfaces_to_return{$key}{'ifAlias'} = "N/A";
		}
	}
	return \%interfaces_to_return;
}

sub fetchActiveInterfaces {
	
	my ($self) = @_;
	
	my $snmp_query_result_ref = SysAdmin::SNMP::fetchInterfaces($self);
	
	my %active_interfaces_in_equipment = ();
	
	foreach my $key ( sort keys %$snmp_query_result_ref){
	
		if($$snmp_query_result_ref{$key}{'ifAdminStatus'} =~ /(\d)/){
			if($1 eq "1"){
				
				$active_interfaces_in_equipment{$key}{'ifIndex'} = $key;
				$active_interfaces_in_equipment{$key}{'ifDescr'} = $$snmp_query_result_ref{$key}{'ifDescr'};
				$active_interfaces_in_equipment{$key}{'ifType'} = $$snmp_query_result_ref{$key}{'ifType'};
				$active_interfaces_in_equipment{$key}{'ifType_name'} = $$snmp_query_result_ref{$key}{'ifType_name'};
				$active_interfaces_in_equipment{$key}{'ifAdminStatus'} = $$snmp_query_result_ref{$key}{'ifAdminStatus'};
				$active_interfaces_in_equipment{$key}{'ifOperStatus'} = $$snmp_query_result_ref{$key}{'ifOperStatus'};
				$active_interfaces_in_equipment{$key}{'ifAlias'} = $$snmp_query_result_ref{$key}{'ifAlias'};
			}
		}
	}
	
	return \%active_interfaces_in_equipment;
}

sub _interface_type_sub {
	
	my ($id) = @_;

	my %ifType_d = (
		'1'=>'other',
		'2'=>'regular1822',
		'3'=>'hdh1822',
		'4'=>'ddnX25',
		'5'=>'rfc877x25',
		'6'=>'ethernetCsmacd',
		'7'=>'iso88023Csmacd',
		'8'=>'iso88024TokenBus',
		'9'=>'iso88025TokenRing',
		'10'=>'iso88026Man',
		'11'=>'starLan',
		'12'=>'proteon10Mbit',
		'13'=>'proteon80Mbit',
		'14'=>'hyperchannel',
		'15'=>'fddi',
		'16'=>'lapb',
		'17'=>'sdlc',
		'18'=>'ds1',
		'19'=>'e1',
		'20'=>'basicISDN',
		'21'=>'primaryISDN',
		'22'=>'propPointToPointSerial',
		'23'=>'ppp',
		'24'=>'softwareLoopback',
		'25'=>'eon',
		'26'=>'ethernet-3Mbit',
		'27'=>'nsip',
		'28'=>'slip',
		'29'=>'ultra',
		'30'=>'ds3',
		'31'=>'sip',
		'32'=>'frame-relay',
		'33'=>'rs232',
		'34'=>'para',
		'35'=>'arcnet',
		'36'=>'arcnetPlus',
		'37'=>'atm',
		'38'=>'miox25',
		'39'=>'sonet',
		'40'=>'x25ple',
		'41'=>'iso88022llc',
		'42'=>'localTalk',
		'43'=>'smdsDxi',
		'44'=>'frameRelayService',
		'45'=>'v35',
		'46'=>'hssi',
		'47'=>'hippi',
		'48'=>'modem',
		'49'=>'aal5',
		'50'=>'sonetPath',
		'51'=>'sonetVT',
		'52'=>'smdsIcip',
		'53'=>'propVirtual',
		'54'=>'propMultiplexor',
		'55'=>'100BaseVG',
		'56'=>'fibreChannel',
		'57'=>'hippiInterface',
		'58'=>'frameRelayInterconnect',
		'59'=>'aflane8023',
		'60'=>'aflane8025',
		'61'=>'cctEmul',
		'62'=>'fastEther',
		'63'=>'isdn',
		'64'=>'v11',
		'65'=>'v36',
		'66'=>'g703at64k',
		'67'=>'g703at2mb',
		'68'=>'qllc',
		'69'=>'fastEtherFX',
		'70'=>'channel',
		'71'=>'ieee80211',
		'72'=>'ibm370parChan',
		'73'=>'escon',
		'74'=>'dlsw',
		'75'=>'isdns',
		'76'=>'isdnu',
		'77'=>'lapd',
		'78'=>'ipSwitch',
		'79'=>'rsrb',
		'80'=>'atmLogical',
		'81'=>'ds0',
		'82'=>'ds0Bundle',
		'83'=>'bsc',
		'84'=>'async',
		'85'=>'cnr',
		'86'=>'iso88025Dtr',
		'87'=>'eplrs',
		'88'=>'arap',
		'89'=>'propCnls',
		'90'=>'hostPad',
		'91'=>'termPad',
		'92'=>'frameRelayMPI',
		'93'=>'x213',
		'94'=>'adsl',
		'95'=>'radsl',
		'96'=>'sdsl',
		'97'=>'vdsl',
		'98'=>'iso88025CRFPInt',
		'99'=>'myrinet',
		'100'=>'voiceEM',
		'101'=>'voiceFXO',
		'102'=>'voiceFXS',
		'103'=>'voiceEncap',
		'104'=>'voiceOverIp',
		'105'=>'atmDxi',
		'106'=>'atmFuni',
		'107'=>'atmIma',
		'108'=>'pppMultilinkBundle',
		'109'=>'ipOverCdlc',
		'110'=>'ipOverClaw',
		'111'=>'stackToStack',
		'112'=>'virtualIpAddress',
		'113'=>'mpc',
		'114'=>'ipOverAtm',
		'115'=>'iso88025Fiber',
		'116'=>'tdlc',
		'117'=>'gigabitEthernet',
		'118'=>'hdlc',
		'119'=>'lapf',
		'120'=>'v37',
		'121'=>'x25mlp',
		'122'=>'x25huntGroup',
		'123'=>'trasnpHdlc',
		'124'=>'interleave',
		'125'=>'fast',
		'126'=>'ip',
		'127'=>'docsCableMaclayer',
		'128'=>'docsCableDownstream',
		'129'=>'docsCableUpstream',
		'130'=>'a12MppSwitch',
		'131'=>'tunnel',
		'132'=>'coffee',
		'133'=>'ces',
		'134'=>'atmSubInterface',
		'135'=>'l2vlan',
		'136'=>'l3ipvlan',
		'137'=>'l3ipxvlan',
		'138'=>'digitalPowerline',
		'139'=>'mediaMailOverIp',
		'140'=>'dtm',
		'141'=>'dcn',
		'142'=>'ipForward',
		'143'=>'msdsl',
		'144'=>'ieee1394',
		'145'=>'if-gsn',
		'146'=>'dvbRccMacLayer',
		'147'=>'dvbRccDownstream',
		'148'=>'dvbRccUpstream',
		'149'=>'atmVirtual',
		'150'=>'mplsTunnel',
		'151'=>'srp',
		'152'=>'voiceOverAtm',
		'153'=>'voiceOverFrameRelay',
		'154'=>'idsl',
		'155'=>'compositeLink',
		'156'=>'ss7SigLink',
		'157'=>'propWirelessP2P',
		'158'=>'frForward',
		'159'=>'rfc1483',
		'160'=>'usb',
		'161'=>'ieee8023adLag',
		'162'=>'bgppolicyaccounting',
		'163'=>'frf16MfrBundle',
		'164'=>'h323Gatekeeper',
		'165'=>'h323Proxy',
		'166'=>'mpls',
		'167'=>'mfSigLink',
		'168'=>'hdsl2',
		'169'=>'shdsl',
		'170'=>'ds1FDL',
		'171'=>'pos',
		'172'=>'dvbAsiIn',
		'173'=>'dvbAsiOut',
		'174'=>'plc',
		'175'=>'nfas',
		'176'=>'tr008',
		'177'=>'gr303RDT',
		'178'=>'gr303IDT',
		'179'=>'isup',
		'180'=>'propDocsWirelessMaclayer',
		'181'=>'propDocsWirelessDownstream',
		'182'=>'propDocsWirelessUpstream',
		'183'=>'hiperlan2',
		'184'=>'propBWAp2Mp',
		'185'=>'sonetOverheadChannel',
		'186'=>'digitalWrapperOverheadChannel',
		'187'=>'aal2',
		'188'=>'radioMAC',
		'189'=>'atmRadio',
		'190'=>'imt',
		'191'=>'mvl',
		'192'=>'reachDSL',
		'193'=>'frDlciEndPt',
		'194'=>'atmVciEndPt',
		'195'=>'opticalChannel',
		'196'=>'opticalTransport',
		'197'=>'propAtm',
		'198'=>'voiceOverCable',
		'199'=>'infiniband',
		'200'=>'teLink',
		'201'=>'q2931',
		'202'=>'virtualTg',
		'203'=>'sipTg',
		'204'=>'sipSig',
		'205'=>'docsCableUpstreamChannel',
		'206'=>'econet',
		'207'=>'pon155',
		'208'=>'pon622',
		'209'=>'bridge',
		'210'=>'linegroup',
		'211'=>'voiceEMFGD',
		'212'=>'voiceFGDEANA',
		'213'=>'voiceDID',
		'214'=>'mpegTransport',
		'215'=>'sixToFour',
		'216'=>'gtp',
		'217'=>'pdnEtherLoop1',
		'218'=>'pdnEtherLoop2',
		'219'=>'opticalChannelGroup',
		'220'=>'homepna',
		'221'=>'gfp',
		'222'=>'ciscoISLvlan',
		'223'=>'actelisMetaLOOP',
		'224'=>'fcipLink',
		'225'=>'rpr',
		'226'=>'qam',
		'227'=>'lmp',
		'228'=>'cblVectaStar',
		'229'=>'docsCableMCmtsDownstream',
		'230'=>'adsl2',
		'231'=>'macSecControlledIF',
		'232'=>'macSecUncontrolledIF',
		'233'=>'aviciOpticalEther',
		'234'=>'atmbond',
		'235'=>'voiceFGDOS',
		'236'=>'mocaVersion1',
		'237'=>'ieee80216WMAN',
		'238'=>'adsl2plus'
	);
	return $ifType_d{$id};
}

sub clear {
	my $self = shift;
	$self->ip(0);
	$self->community(0);
}

1;
__END__

=head1 NAME

SysAdmin::SNMP - Perl SNMP class wrapper module

=head1 SYNOPSIS

	use SysAdmin::SNMP;
	
	my $ip_address = "192.168.1.1";
	my $community  = "public";
	
	my $snmp_object = new SysAdmin::SNMP(IP        => "$ip_address",
                                         COMMUNITY => "$community");
				  
	my $sysName = '.1.3.6.1.2.1.1.5.0';
	
	my $query_result = $snmp_object->snmpget("$sysName");
	
	print "$ip_address\'s System Name is $query_result

=head1 DESCRIPTION

This is a sub class of SysAdmin. It was created to harness Perl Objects and keep
code abstraction to a minimum. This class acts as a master class for SNMP
objects.

SysAdmin::SNMP uses Net::SNMP to interact with SNMP enabled equipment.

=head1 METHODS

=head2 C<new()>

	my $snmp_object = new SysAdmin::SNMP(IP        => "$ip_address",
                                         COMMUNITY => "$community");

Declare the SysAdmin::SNMP object instance. Takes the network element ip
address and its SNMP community string as the only variables to use.

	IP => "$ip_address"

Declare the IP address of the network element.

	COMMUNITY => "$community"
	
Declares the SNMP community string.

=head2 C<snmpwalk()>

=head2 C<snmpget()>

=head2 C<fetchInterfaces()>

=head2 C<fetchActiveInterfaces()>

head3 C<checkValidOID()>
	
=head1 SEE ALSO

Net::SNMP - Object oriented interface to SNMP

=head1 AUTHOR

Miguel A. Rivera

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
