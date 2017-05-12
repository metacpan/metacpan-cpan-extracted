package Net::CSTAv3::Client;

use Carp;
use strict;
use warnings;
use Convert::ASN1::asn1c;

require Exporter;

BEGIN {
	require Net::CSTAv3::Client::HiPath;
}

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Net::CSTAv3::Client ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.06';

sub debug {
	my $self = shift;
	if ($self->{'_debug_state'}) {
		print( "[DEBUG] " . join('', @_));
	}
}

sub decode_msg_header {
	my $self = shift;
	my $bin = shift;
	my ($header, $b1, $b2) = unpack('CCC', $bin);
	croak "Not a valid Siemens Hipath data packet\n" unless ($header == 0x26);
	$b1 -= 128; # "MSB" of len field is always 1
	my $len = ($b1 << 8) + $b2;
	return $len;
}

sub encode_msg_header {
	my $self = shift;
	my $len = shift;
	die "Message larger than allowed!" unless ($len <= 1000);
	my $bin = pack('Cn', 38, $len+(1<<15));
	return $bin;
}

sub open_csta_socket {
	my $self = shift;
	my $host = shift;
	my $port = shift;

	$self->debug("trying to open a connection to $host on port $port\n");
 
	my $socket = new IO::Socket::INET(
        PeerAddr => $host,
        PeerPort => $port,
		Blocking => 1,
        Proto => 'tcp') || die "Error creating socket: $!\n";
	$socket->autoflush(1);
	$self->debug("opened a connection to $host on port $port\n");
	$self->{'_csta_socket'} = $socket;
}

sub send_pdu {
	my $self = $_[0];
	my $pdu = $_[1];
	my $header = $self->encode_msg_header(length($pdu));
	$self->{'_csta_socket'}->write($header);
	my $hexdata = $self->convert_to_hex($header);
	$self->{'_csta_socket'}->write($pdu);
	$hexdata = $self->convert_to_hex($pdu);
	$self->debug("SENT PDU: [$hexdata]\n");
}

sub send_aarq {
	my $self = $_[0];
	my %args = %{$_[1]};
	my $conv = Convert::ASN1::asn1c->new();
	my $pdu = $conv->sencode(Net::CSTAv3::Client::HiPath::AARQ_apdu(), {
		'sender-acse-requirements'=>$conv->encode_bitstring('10'),
	    'authentication-name'=>$conv->encode_octet_string($args{authname}),
	    'authentication-password'=>$conv->encode_octet_string($args{password}),
	    'csta-version'=>$conv->encode_bitstring('0001000000000000'),
	    'authentication-password_length'=>length($args{password}),
	    'authentication-name_length'=>length($args{authname})
	});
	croak "Couldn't encode AARQ-apdu!\n" unless (defined $pdu); 
	$self->debug("SENDING AARQ-apdu\n");
	$self->send_pdu($pdu);
}

sub receive_aare {
	my $self = $_[0];
	my $pdu = $self->receive_stuff();
	my $conv = Convert::ASN1::asn1c->new();
	my $values = $conv->sdecode(Net::CSTAv3::Client::HiPath::AARE_apdu(), $pdu);
	$self->debug("RECEIVED AARE-apdu\n");
	$self->debug("> result: $values->{'result'} (0=accepted, 1=rejected permanent, 2=rejected transient)\n");
	$self->debug("> aps-stamp: $values->{'aps-stamp'}\n");
	$self->debug("> system-version: $values->{'system-version'}\n");
	return $values;
}

sub send_abrt {
	my $self = $_[0];
	my $conv = Convert::ASN1::asn1c->new();
	my $pdu = $conv->sencode(Net::CSTAv3::Client::HiPath::ABRT_apdu(), { });
	croak "Couldn't encode ABRT-apdu!\n" unless (defined $pdu); 
	$self->debug("SENDING ABRT-apdu\n");
	$self->send_pdu($pdu);
}

sub receive_csta_system_status {
	my $self = $_[0];
	my $pdu = $self->receive_stuff();
	my $conv = Convert::ASN1::asn1c->new();
	my $values = $conv->sdecode(Net::CSTAv3::Client::HiPath::CSTA_SystemStatus(), $pdu);
	$self->debug("RECEIVED CSTA-SystemStatus\n");
	# system-status is an enumerated integer, we have to decode it ourselves
	$values->{'system-status'} = $conv->decode_integer($values->{'system-status'}, $values->{'system-status_length'});
	$self->debug("> invoke-id: $values->{'invoke-id'}\n");
	$self->debug("> operation-value: $values->{'operation-value'}\n");
	$self->debug("> system-status: $values->{'system-status'}\n");
	return $values;
}

sub send_csta_system_status_response {
	my $self = $_[0];
	my %args = %{$_[1]};
	my $conv = Convert::ASN1::asn1c->new();
	my $pdu = $conv->sencode(Net::CSTAv3::Client::HiPath::CSTA_SystemStatusResponse(), 
	   {'invoke-id'=>$conv->encode_integer($args{'invoke-id'}, $args{'invoke-id_length'}),
	    'operation-value'=>$conv->encode_integer($args{'operation-value'}, $args{'operation-value_length'})
	   });
	$self->debug("SENDING CSTA-SystemStatusResponse\n");
	$self->send_pdu($pdu);
}

sub send_csta_monitor_start {

	my $self = $_[0];
	my %args = %{$_[1]};

	# NOTE: It seems that our PBX, contrary to the SwitchSimulator, only monitors ALL events if all bits are set to 0.

	# call-control: 18 bits, meaning: bit 0 ....... 17
	# unknown, conferenced, connectionCleared, delivered, diverted, established,
    # failed, held, networkReached, originated, queued, retrieved, serviceInitiated, transferred, 4 x unknown
	# call-associated: 5 bits, meaning: bit 0 ...... 4
	# unknown, charging, 3 x unknown
	# media-attachment: 2 bits, meaning  2 xunknown
	# physical-device-feature: 11 bits, meaning: bit 0 ..... 10
	# buttonInformation, buttonPress, unknown, hookswitch, unknown, messageWaiting, 5 x unknown
	# logical-device-feature: 14 bits, meaning: bit 0 ...... 14
	# agentBusy, agentLoggedOn, agentLoggedOff, agentNotReady, agentReady, agentWorkingAfterCall,
    # 5 x unknown, doNotDisturb, forwarding, unknown
	# maintainance: 3 bits, meaning: bit 0 ...... 2
	# backInService, outOfService, unknown
	# voice-unit: 7 bits, meaning: bit 0 ...... 6
	# play, stop, 5 x unknown
	# private: 1 bit meaning unknown

	# ALL UNKNOWN BITS SHOULD ALWAYS BE ZERO!
	
	my $conv = Convert::ASN1::asn1c->new();
	
	my $pdu = $conv->sencode(Net::CSTAv3::Client::HiPath::CSTA_MonitorStart(), {
		'invoke-id'=>$conv->encode_integer($args{'invoke-id'}, 1), 
        'invoke-id_length'=>1, #TODO handle length correctly
		'operation-value'=>$conv->encode_integer(71, 1),
        'operation-value_length'=>1,
        'dialing-number'=>$conv->encode_octet_string($args{'dialing-number'}),
        'dialing-number_length'=>length($args{'dialing-number'}),
		'call-control'=>$conv->encode_bitstring($args{'call-control'} || '000000000000000000'),
		'call-associated'=>$conv->encode_bitstring($args{'call-associated'} || '00000'),
		'media-attachment'=>$conv->encode_bitstring($args{'media-attachment'} || '00'),
		'physical-device-feature'=>$conv->encode_bitstring($args{'physical-device-feature'} || '00000000000'),
		'logical-device-feature'=>$conv->encode_bitstring($args{'logical-device-feature'} || '00000000000000'),
		'maintainance'=>$conv->encode_bitstring($args{'maintainance'} || '000'),
		'voice-unit'=>$conv->encode_bitstring($args{'voice-unit'} || '0000000'),
		'private'=>$conv->encode_bitstring($args{'private'} || '0'),
	});
	$self->debug("SENDING CSTA-MonitorStart\n");
	$self->send_pdu($pdu);
	
}

sub receive_csta_monitor_start_response {
	my $self = $_[0];
	my $conv = Convert::ASN1::asn1c->new();
	my $pdu = $self->receive_stuff();
	my $values = $conv->sdecode(Net::CSTAv3::Client::HiPath::CSTA_MonitorStartResponse(), $pdu);
	# cross-ref-identifier is actually an octet string but we can not print it as such as it may contain null bytes at the beginning
	# so we will just treat it as a binary object (it is an opaque object anyway)
	$values->{'cross-ref-identifier'} = $conv->decode_xml2hextxt($values->{'cross-ref-identifier_orig'});
	$self->debug("RECEIVED CSTA-MonitorStartResponse\n");
	$self->debug("< cross-ref-identifier: $values->{'cross-ref-identifier'}\n");
	return $values;
}

sub send_csta_monitor_stop {

	my $self = $_[0];
	my %args = %{$_[1]};

	my $conv = Convert::ASN1::asn1c->new();

	my $pdu = $conv->sencode(Net::CSTAv3::Client::HiPath::CSTA_MonitorStop(), {
		'cross-ref-identifier'=>$conv->encode_hextxt2xml($args{'cross-ref-identifier'}, 1),
	    'cross-ref-identifier_length'=>length($args{'cross-ref-identifier'})/2,
	    'invoke-id'=>$conv->encode_integer($args{'invoke-id'}, 1),
	    'invoke-id_length'=>1, #TODO handle length correctly
	});
	$self->debug("SENDING CSTA-MonitorStop\n");
	$self->send_pdu($pdu);
	
}

sub receive_csta_monitor_stop_response {
	my $self = $_[0];
	my $conv = Convert::ASN1::asn1c->new();
	my $pdu = $self->receive_stuff();
	my $values = $conv->sdecode(Net::CSTAv3::Client::HiPath::CSTA_MonitorStopResponse(), $pdu);
	$self->debug("RECEIVED CSTA-MonitorStopResponse\n");
	return $values;
}



sub convert_to_hex {
	my $self = $_[0];
	my $pdu = $_[1];
	my $hexdata = unpack('H*', $pdu);
	$hexdata =~ tr/a-z/A-Z/;
	$hexdata =~ s/(..)/$1 /g;
	$hexdata =~ s/ $//g;
	return $hexdata;
}


sub receive_stuff {
	my $self = $_[0];
	my $header = '';
	my $pdu = '';
	my $nbytes = $self->{'_csta_socket'}->sysread($header, 3);
	croak "Didn't receive the specified amount of data!\n" unless ($nbytes == 3);
	$self->debug("Received three bytes, assuming it's a message header\n");
	my $len = $self->decode_msg_header($header);
	$self->debug("Waiting for $len bytes of ASN1 data now\n");
	$nbytes = $self->{'_csta_socket'}->sysread($pdu, $len);
	# TODO sysread can return with fewer bytes, has to be called in a loop
	croak "Didn't receive the specified amount of data!\n" unless ($nbytes == $len);
	my $hexdata = $self->convert_to_hex($pdu);
	$self->debug("RECEIVED PDU: [$hexdata]\n");
	return $pdu;
}

sub csta_connect {
	my $self = $_[0];
	my %args = %{$_[1]};
	$self->open_csta_socket($args{host}, $args{port});
	$self->send_aarq({authname=>$args{authname}||"AMHOST", password=>$args{password}||'77777'});
	$self->receive_aare();
	my $ret = $self->receive_csta_system_status();
	$self->send_csta_system_status_response($ret);
}

sub csta_disconnect {
	my $self = $_[0];
	$self->send_abrt();
	close($self->{'_csta_socket'});
}

sub csta_setup_monitoring {
	my $self = $_[0];
	my %args = %{$_[1]};
	
	$self->send_csta_monitor_start({'invoke-id'=>1, 'dialing-number'=>$args{'dialing-number'}});
	my $ret = $self->receive_csta_monitor_start_response();

	if (defined $ret->{'cross-ref-identifier'}) {
		$self->{'_active_monitorings'}->{$ret->{'cross-ref-identifier'}} = {
			'dialing_number' => $args{'dialing-number'},
			'delivered_cb' =>   $args{'delivered_cb'} || sub {},
			'cleared_cb' =>     $args{'cleared_cb'} || sub{},
			'established_cb' => $args{'established_cb'} || sub{},
			'transferred_cb' => $args{'transferred_cb'} || sub{},
		}
	}

	return $ret->{'cross-ref-identifier'};
}

sub csta_destroy_monitoring {
	my $self = $_[0];
	my %args = %{$_[1]};
	$self->send_csta_monitor_stop({'cross-ref-identifier'=>$args{'cross-ref-identifier'}, 'invoke-id'=>2});
	$self->receive_csta_monitor_stop_response();
}

sub parse_any_csta_packet {

	# not really true! we are expecting an event report here!

	my ($self, $pdu) = @_;
	my $conv = Convert::ASN1::asn1c->new();
	my $values = $conv->sdecode(Net::CSTAv3::Client::HiPath::CSTA_RosePacketDecode(), $pdu);
	if ($values->{'operation-value'} == 21) {
		$self->parse_csta_event_report($pdu);
	}
	else {
		$self->debug("I received an unexpected packet!\n");
	}
}

sub parse_csta_event_report {
	my ($self, $pdu) = @_;
	my $pdu_copy = $pdu;

	# get the first three tags in the tree of the packet to find out what kind of
	# event report we are dealing with - their meaning is:
	# [1]                -- always the same 
	#   [UNIVERSAL 16]   -- always the same
	#      [0]           -- CallControlServAndEvents (all other packets are uninteresting)
	#         [3]        -- event type
	# interesting types are 
    # connectionCleared          [ 3] 
    # delivered                  [ 4] 
    # established                [ 7] 
    # originated                 [13] 
    # transferred                [17] 

	my $conv = Convert::ASN1::asn1c->new();
	my $tagpaths = $conv->get_tagpaths_with_prefix($pdu, "[1]|[UNIVERSAL 16]|[0]|");
	my $node = $tagpaths->[0];
	my $packettype = undef;
	my $escaped_regex = quotemeta("[1]|[UNIVERSAL 16]|[0]|");
	if ($node =~ /$escaped_regex \[(\d+)\]/x) {
		$packettype = $1;
	}

	if (defined $packettype) {
		if ($packettype == 3) {
			$self->parse_connection_cleared_event($pdu_copy);
		}
		elsif ($packettype == 4) {
			$self->parse_delivered_event($pdu_copy);
		}
		elsif ($packettype == 7) {
			$self->parse_established_event($pdu_copy);
		}
		elsif ($packettype == 17) {
			$self->parse_transferred_event($pdu_copy);
		}
		else {
			$self->debug("I am ignoring this Event because the handling of this eventtype is not implemented\n");
		}
#  		parse_diverted_event($pdu)           if ($packettype == 6);
#		parse_originated_event($pdu)         if ($packettype == 13);
	}
	else {
		$self->debug("I am ignoring this Event because it is not a call-event\n");
	}

}

sub parse_connection_cleared_event {
	my ($self, $pdu) = @_;
	
	my $conv = Convert::ASN1::asn1c->new();

	my $values = $conv->sdecode(Net::CSTAv3::Client::HiPath::CSTA_EventReport_ConnectionCleared(), $pdu);
	$values->{'dialing-number'} = $conv->decode_octet_string($values->{'dialing-number_orig'}, $values->{'dialing-number_length'});
	$values->{'cross-ref-identifier'} = $conv->decode_xml2hextxt($values->{'cross-ref-identifier_orig'});
	$values->{'connection-info'} = $conv->decode_integer($values->{'connection-info_orig'}, $values->{'connection-info_length'});
	$values->{'releasing-device'} = $conv->decode_octet_string($values->{'releasing-device_orig'}, $values->{'releasing-device_length'});
	$values->{'call-id'} = $conv->decode_xml2hextxt($values->{'call-id_orig'});

	$self->debug("EVENT RECEIVED: connection cleared event:\n");
	$self->debug("> cross-ref-identifier: $values->{'cross-ref-identifier'}\n");
	$self->debug("> call-id: $values->{'call-id'}\n");
	$self->debug("> dialing-number: $values->{'dialing-number'}\n");
	$self->debug("> releasing-device: $values->{'releasing-device'}\n");
	$self->debug("> timestamp: $values->{'timestamp'}\n");

	$self->{'_active_monitorings'}->{$values->{'cross-ref-identifier'}}->{'cleared_cb'}->($values);

	return $values;
}

sub parse_established_event {
	my ($self, $pdu) = @_;
	my $conv = Convert::ASN1::asn1c->new();
	my $values = $conv->sdecode(Net::CSTAv3::Client::HiPath::CSTA_EventReport_Established(), $pdu);
	$values->{'dialing-number'} = $conv->decode_octet_string($values->{'dialing-number_orig'}, $values->{'dialing-number_length'});
	$values->{'answering-device'} = $conv->decode_octet_string($values->{'answering-device_orig'}, $values->{'answering-device_length'});
	$values->{'calling-device'} = $conv->decode_octet_string($values->{'calling-device_orig'}, $values->{'calling-device_length'});
	$values->{'called-device'} = $conv->decode_octet_string($values->{'called-device_orig'}, $values->{'called-device_length'});
	$values->{'cross-ref-identifier'} = $conv->decode_xml2hextxt($values->{'cross-ref-identifier_orig'});
	$values->{'connection-info'} = $conv->decode_integer($values->{'connection-info_orig'}, $values->{'connection-info_length'});
	$values->{'call-id'} = $conv->decode_xml2hextxt($values->{'call-id_orig'});

	$self->debug("EVENT RECEIVED: established event:\n");
	$self->debug("> cross-ref-identifier: $values->{'cross-ref-identifier'}\n");
	$self->debug("> call-id: $values->{'call-id'}\n");
	$self->debug("> answering-device: $values->{'answering-device'}\n");
	$self->debug("> calling-device: $values->{'calling-device'}\n");
	$self->debug("> called-device: $values->{'called-device'}\n");
	$self->debug("> timestamp: $values->{'timestamp'}\n");

	$self->{'_active_monitorings'}->{$values->{'cross-ref-identifier'}}->{'established_cb'}->($values);
	
	return $values;
}

sub parse_delivered_event {
	my ($self, $pdu) = @_;

	my $conv = Convert::ASN1::asn1c->new();

	my $values = $conv->sdecode(Net::CSTAv3::Client::HiPath::CSTA_EventReport_Delivered(), $pdu);
	$values->{'dialing-number'} = $conv->decode_octet_string($values->{'dialing-number_orig'}, $values->{'dialing-number_length'});
	$values->{'alerting-device'} = $conv->decode_octet_string($values->{'alerting-device_orig'}, $values->{'alerting-device_length'});
	$values->{'calling-device'} = $conv->decode_octet_string($values->{'calling-device_orig'}, $values->{'calling-device_length'});
	$values->{'called-device'} = $conv->decode_octet_string($values->{'called-device_orig'}, $values->{'called-device_length'});
	$values->{'cross-ref-identifier'} = $conv->decode_xml2hextxt($values->{'cross-ref-identifier_orig'});
	$values->{'call-id'} = $conv->decode_xml2hextxt($values->{'call-id_orig'});
	$values->{'connection-info'} = $conv->decode_integer($values->{'connection-info_orig'}, $values->{'connection-info_length'});

	$self->debug("EVENT RECEIVED: delivered event:\n");
	$self->debug("> cross-ref-identifier: $values->{'cross-ref-identifier'}\n");
	$self->debug("> call-id: $values->{'call-id'}\n");
	$self->debug("> alerting-device: $values->{'alerting-device'}\n");
	$self->debug("> calling-device: $values->{'calling-device'}\n");
	$self->debug("> called-device: $values->{'called-device'}\n");
	$self->debug("> timestamp: $values->{'timestamp'}\n");

	$self->{'_active_monitorings'}->{$values->{'cross-ref-identifier'}}->{'delivered_cb'}->($values);
	
	return $values;
}

sub parse_transferred_event {
	my ($self, $pdu) = @_;

	my $conv = Convert::ASN1::asn1c->new();

	my $values = $conv->sdecode(Net::CSTAv3::Client::HiPath::CSTA_EventReport_Transferred(), $pdu);
	$values->{'cross-ref-identifier'} = $conv->decode_xml2hextxt($values->{'cross-ref-identifier_orig'});
	$values->{'call-id'} = $conv->decode_xml2hextxt($values->{'call-id_orig'});
	$values->{'old-call-id'} = $conv->decode_xml2hextxt($values->{'old-call-id_orig'});
	$values->{'dialing-number'} = $conv->decode_octet_string($values->{'dialing-number_orig'},$values->{'dialing-number_length'});
	$values->{'transferring-device'} = $conv->decode_octet_string($values->{'transferring-device_orig'}, $values->{'transferring-device_length'});
	$values->{'transferred-to-device'} = $conv->decode_octet_string($values->{'transferred-to-device_orig'}, $values->{'transferred-to-device_length'});
	$values->{'endpoint'} = $conv->decode_octet_string($values->{'endpoint_orig'}, $values->{'endpoint_length'});

	$self->debug("EVENT RECEIVED: transferred event:\n");
	$self->debug("> cross-ref-identifier: $values->{'cross-ref-identifier'}\n");
	$self->debug("> call-id: $values->{'call-id'}\n");
	$self->debug("> old-call-id: $values->{'old-call-id'}\n");
	$self->debug("> transferring-device: $values->{'transferring-device'}\n");
	$self->debug("> transferred-to-device: $values->{'transferred-to-device'}\n");
	$self->debug("> endpoint: $values->{'endpoint'}\n");
	$self->debug("> timestamp: $values->{'timestamp'}\n");

	$self->{'_active_monitorings'}->{$values->{'cross-ref-identifier'}}->{'transferred_cb'}->($values);

	return $values;
}



sub send_csta_make_call {
	my $self = $_[0];
	my %args = %{$_[1]}; 

	my $conv = Convert::ASN1::asn1c->new();

	my $pdu = $conv->sencode(Net::CSTAv3::Client::HiPath::CSTA_MakeCall(), {
					'calling-device'=>$conv->encode_octet_string($args{'calling-device'}, length($args{'calling-device'})),
	                'called-device'=>$conv->encode_octet_string($args{'called-device'}, length($args{'called-device'})),
	                'invoke-id'=>$conv->encode_integer($args{'invoke-id'}, 1),
	                'invoke-id_length'=>1, #TODO handle length correctly
	});
	$self->debug("SENDING CSTA-MakeCall\n");
	$self->send_pdu($pdu);
}

sub send_csta_set_display {
	my $self = $_[0];
	my %args = %{$_[1]}; 

	my $conv = Convert::ASN1::asn1c->new();

	my $pdu = $conv->sencode(Net::CSTAv3::Client::HiPath::CSTA_SetDisplay(), {
					'device'=>$conv->encode_octet_string($args{'device'}, length($args{'device'})),
	                'text'=>$conv->encode_octet_string($args{'text'}, length($args{'text'})),
	                'invoke-id'=>$conv->encode_integer($args{'invoke-id'}, 1),
	                'invoke-id_length'=>1, #TODO handle length correctly
	});
	$self->debug("SENDING CSTA-SetDisplay\n");
	$self->send_pdu($pdu);
}



sub receive_csta_make_call_response {
	
	my $self = shift;
	my $conv = Convert::ASN1::asn1c->new();
	my $pdu = $self->receive_stuff();
	my $values = $conv->sdecode(Net::CSTAv3::Client::HiPath::CSTA_MakeCallResponse(), $pdu);

	$self->debug("RECEIVED CSTA-MakeCallResponse\n");
	$self->debug("> invoke-id: $values->{'invoke-id'}\n");
	$self->debug("> operation-value: $values->{'operation-value'}\n");
	$self->debug("> call-id: $values->{'call-id'}\n");
	$self->debug("> dialing-number: $values->{'dialing-number'}\n");
	return $values;

}

sub receive_csta_set_display_response {
	
	my $self = shift;
	my $conv = Convert::ASN1::asn1c->new();
	my $pdu = $self->receive_stuff();
	my $values = $conv->sdecode(Net::CSTAv3::Client::HiPath::CSTA_SetDisplayResponse(), $pdu);

	$self->debug("RECEIVED CSTA-SetDisplayResponse\n");
	$self->debug("> invoke-id: $values->{'invoke-id'}\n");
	$self->debug("> operation-value: $values->{'operation-value'}\n");
	return $values;

}

sub new {
	my ($class_name) = @_;
	my $self = {};
	$self->{'_debug_state'} = 0;
	bless ($self, $class_name);
	return $self;
}

sub debug_on {
	my $self = shift;
	$self->{'_debug_state'} = 1;
}

sub debug_off {
	my $self = shift;
	$self->{'_debug_state'} = 0;
}

sub get_socket {
	my $self = shift;
	return $self->{'_csta_socket'}
}

sub main_loop {
	my $self = shift;
	while (1) {
		my $pdu = $self->receive_stuff();
		$self->parse_any_csta_packet($pdu);
	}
}


1;
__END__

=head1 NAME

Net::CSTAv3::Client - Perl implementation of the CSTA Phase 3 protocol as used by siemens clients

=head1 SYNOPSIS

A simple example how this module can be used:

	use Data::Dumper;	
	use Net::CSTAv3::Client;
	
	my $csta_client;
	my $cross_ref;
	
	$csta_client = Net::CSTAv3::Client->new();

	sub my_cleared_cb {
		print "CONNECTION CLEARED CALLBACK\n\n";
		print Dumper(@_);
		print "Lets close the connection now\n";
		$csta_client->csta_destroy_monitoring({'cross-ref-identifier'=>$cross_ref});
		$csta_client->csta_disconnect();
		exit(0);
	}
	
	$csta_client->csta_connect({'host'=>'siemens-pbx', 'port'=>18000});
	$cross_ref = $csta_client->csta_setup_monitoring({'dialing-number'=>'100', 'cleared_cb'=>\&my_cleared_cb});
	$csta_client->main_loop();

In this example we create a CSTA client instance and connect it to the host
'siemens-pbx' which accepts connections on port 18000. After that we instruct
the PBX to monitor the (local) device which is reachable through the number
'100'. In case of a connection cleared event (which is triggered when a call is
torn down, for example because the caller or callee is hanging up) the function
'my_cleared_cb' is executed. It will get a reference to a hash as it's first
argument. This hash contains more information about the connection cleared
event because of which this function was called. After that we stop the
monitoring and disconnect from the PBX.


=head1 DESCRIPTION

This module implements (a part of) the Computer Supported Telecommunications
Applications (CSTA) protocol. It enables you to write perl programs which can
communicate with your Private Branch eXchange device (PBX) to, for example,
monitor calls to and from your own network.

Even though the CSTA protocol is defined in ECMA standards, vendors seem to
implement customized versions of it. This module was developed for a Siemens
HiPath PBX, most of the specification was obtained from the documentation of
the "Siemens HiPath OpenOffice" unit - available at
L<http://wiki.siemens-enterprise.com/index.php/HiPath_OpenOffice_ME_Offene_Schnittstellen>.

For now this module only implements a small subset of the functionality offered
by CSTA / Siemens' CSTA implementation - expect it to grow in future versions. :-)

=head2 EXPORT

None by default.

=head1 METHODS

=head2 $csta_client = Net::CSTAv3::Client->new()

Create a new Net::CSTAv3::Client instance $csta_client.

=head2 $csta_client->csta_connect({'host'=>'siemens-pbx', 'port'=>18000})

Connect the client to a PBX. This function takes a reference to a hash with
parameters. The recognized hash keys are:

=over 4

=item * C<host>: The hostname or IP address of the PBX.

=item * C<port>: The port number on which the PBX is accepting connections.

=item * C<authname>: Authentication name to use when connecting to the PBX.
Defaults to C<AMHOST>".

=item * C<password>: Password to use when connecting to the PBX. Defaults to
C<77777>.

=back

=head2 $cross_ref = $csta_client->csta_setup_monitoring({'dialing-number'=>'100'});

Start monitoring a device inside your network. This function takes a reference
to a hash with parameters. The recognized hash keys are documented below.
Monitoring a device means that the PBX will sent a notification to this client
if the monitored device is involved in an event that is monitored. CSTA
supports a wide range of events that can be monitored, but this module (up to
now) only supports the following events:

=over 4

=item * The connection cleared event, that occurs if an existing connection to/from the
monitored device is torn down, for example because the peer is going on-hook.

=item * The delivered event, which occurs if a device receives an incoming call.

=item * The established event, which occurs if a call to/from a device is established.

=item * The transferred event, which occurs if a monitored device is involved in
a transferred call. A transferred call is a call from device E that is received
by device A, after that A calls another device B and after the connection
between A and B is establised A can transfer it's call with E to device B.

=back

For more information about these events please refer to the CSTA specification.

=over 4

=item * C<dialing-number>: Local dialing number of the device that should be
monitored.

=item * C<delivered_cb>: A reference to a function that will be executed in
case a delivered event on the monitored device is observed. If this parameter
is undefined all delivered-events from this device will be ignored.

=item * C<cleared_cb>: A reference to a function that will be executed in case
a connection-cleared-event on the monitored device is observed. If this
parameter is undefined all connection-cleared-events from this device will be
ignored.

=item * C<established_cb>: A reference to a function that will be executed in
case a established-event on the monitored device is observed. If this parameter
is undefined all established-events from this device will be ignored.

=item * C<transferred_cb>: A reference to a function that will be executed in
case a transferred-event on the monitored device is observed. If this parameter
is undefined all transferred-events from this device will be ignored.

=back 4

The callback functions will receive a reference to a hash with event parameters.
In case of a delivered-event the most interesting parameters / hash keys are:

=over 4

=item C<alerting-device>: The dialing number of the device which is ringing

=item C<calling-device>: The dialing number of the calling device

=item C<called-device>: The dialing number of the called device

=item C<cross-ref-identifier>: The cross reference identifier for the monitor
instance. This is the same identifier which was returned by the
csta_setup_monitoring function for the device that caused this event

=back

In case of a delivered-event the most interesting parameters / hash keys are:

=over 4

=item C<releasing-device>: The dialing number of the device that closed the connection

=item C<dialing-number>: The dialing number of the device that generated this event

=item C<cross-ref-identifier>: The cross reference identifier for the monitor
instance. This is the same identifier which was returned by the
csta_setup_monitoring function for the device that caused this event

=back

In case of a delivered-event the most interesting parameters / hash keys are:

=over 4

=item C<answering-device>: The dialing number of the device that answered the
call

=item C<calling-device>: The dialing number of the device which initiated the
call

=item C<called-device>: The dialing number of the device which was called by
calling-device

=item C<cross-ref-identifier>: The cross reference identifier for the monitor
instance. This is the same identifier which was returned by the
csta_setup_monitoring function for the device that caused this event

=back

In case of a delivered-event the most interesting parameters / hash keys are:

=over 4

=item C<transferring-device>: The dialing number of the device that is
responsible for the call transfer

=item C<transferred-to-device>: The dialing number of the device which became
the new internal endpoint for the transferred call

=item C<endpoint>: The dialing number of the device which initially called

=item C<cross-ref-identifier>: The cross reference identifier for the monitor
instance. This is the same identifier which was returned by the
csta_setup_monitoring function for the device that caused this event

=back

Note that you have to call the main_loop() function to receive incoming events
as soon as possible.

=head2 $csta_client->csta_destroy_monitoring({'cross-ref-identifier'=>$cross_ref})

Disable monitoring for the given cross-ref-identifier. These identifiers are
returned for each call of csta_setup_monitoring().

=head2 $csta_client->main_loop()

This is the "event loop" that indefinitely waits for incoming events. Call this
function after you set up all your monitorings. Note that this function can
only be left through callbacks invoked by incoming events.

=head2 $csta_client->debug_on()

If debugging is turned on this module emits *a lot* of debugging information on
STDOUT. All debugging information printed by this module is prefixed with
"[DEBUG] ". By default debugging is turned off.

=head2 $csta_client->debug_off()

Turn of debugging infos. Note that debugging is turned off by default anyway,
this function is only usefull after you turned it on via the debug_on()
function.

=head1 BUGS

=over 4

=item This module only implements a small subset of the CSTA protocol so far

=item It was developed for a Siemens HiPath PBX. It might not work with other
PBXs. I tried to isolate the Siemens specific stuff in
Net::CSTAv3::Client::HiPath.pm, so support for other devices can be added
later.

=item I am not fully satisfied with the event handling as it is now (users have
to call the 'black hole function' main-loop() manually), so the interface might
change in later versions.

=item Error handling and logging are poorly implemented in this module as of
now.

=back

=head1 SEE ALSO

The CSTA protocol is defined by ECMA International, see:
L<http://www.ecma-international.org/activities/Communications/TG11/cstaIII.htm>

Documentation on Siemens CSTA implementation for their HiPath PBXs can be found
at
L<http://wiki.siemens-enterprise.com/index.php/HiPath_OpenOffice_ME_Offene_Schnittstellen>

Siemens offers two usefull programs to test/develop CSTA applications,
CSTASwitchSimulator and CSTABrowser.

=head1 AUTHOR

Timo Schneider, E<lt>timos@informatik.tu-chemnitz.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Timo Schneider

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
