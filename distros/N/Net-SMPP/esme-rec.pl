#!/usr/bin/perl
#
# Copyright (c) 2001 SymLABS <symlabs@symlabs.com>, All Rights Reserved.
# See README for license. NO WARRANTY.
#
# 10.7.2001, Sampo Kellomaki <sampo@symlabs.com>
# $Id: esme-rec.pl,v 1.4 2002/02/11 16:43:47 sampo Exp $
#
# ESME in receiver role.
#
# Test Net::SMPP in SMSC role
#
# Usage: ./esme-rec.pl *version*
#    version can be 4 or 3             #4

use Net::SMPP;
use Data::Dumper;

$trace = 1;
$sysid = "GSMSGW";
$pw = "secret";
$host = 'localhost';
$port = 9900;
$facil = 0x00010003;
($vers) = @ARGV;
$vers = $vers == 4 ? 0x40 : 0x34;   #4
$if_vers = 0x00;

use constant reply_tab => {
    0x80000000 => { cmd => 'generic_nack', reply => undef, },
    0x00000001 => { cmd => 'bind_receiver',
		    reply => sub { my ($me,$pdu) = @_;
				   $me->set_version(0x34);
				   $me->bind_receiver_resp(system_id => $sysid,
							   seq => $pdu->{seq});
			       }, },
    0x80000001 => { cmd => 'bind_receiver_resp', reply => undef, }, 
    0x00000002 => { cmd => 'bind_transmitter',
		    reply => sub { my ($me, $pdu) = @_;
				   $me->set_version(0x34);
				   warn "Doing bind_tx_resp";
				   $me->bind_transmitter_resp(system_id => $sysid,
							   seq => $pdu->{seq});
			       }, },
    0x80000002 => { cmd => 'bind_transmitter_resp', reply => undef, }, 
    0x00000003 => { cmd => 'query_sm',
		    reply => sub { my ($me, $pdu) = @_;
				   $me->query_sm_resp(message_id=>$pdu->{message_id},
						      final_date=>'010711135959000+',
							   seq => $pdu->{seq},
						      ) }, },
    0x80000003 => { cmd => 'query_sm_resp', reply => undef, },     
    0x00000004 => { cmd => 'submit_sm',
		    reply => sub { my ($me, $pdu) = @_;
				   $me->submit_sm_resp(message_id=>'123456789',
						       seq => $pdu->{seq}) }, },
    0x80000004 => { cmd => 'submit_sm_resp', reply => undef, },   
    0x00000005 => { cmd => 'deliver_sm', reply => undef, },    # we originate this
    0x80000005 => { cmd => 'deliver_sm_resp', reply => undef, },  # *** need to handle this?
    0x00000006 => { cmd => 'unbind',
		    reply => sub { my ($me, $pdu) = @_;
				   $me->unbind_resp(seq => $pdu->{seq});
				   warn "$$: Remote sent unbind. Dropping connection.";
				   exit;
			       }, },       
    0x80000006 => { cmd => 'unbind_resp',
		    reply => sub { warn "$$: Remote replied to unbind. Dropping connection.";
				   exit;
			       }, },
    0x00000007 => { cmd => 'replace_sm',
		    reply => sub { my ($me, $pdu) = @_;
				   $me->replace_sm_resp(seq => $pdu->{seq}) }, },
    0x80000007 => { cmd => 'replace_sm_resp', reply => undef, }, 
    0x00000008 => { cmd => 'cancel_sm', reply => sub { my ($me, $pdu) = @_;
						       $me->cancel_resp(seq => $pdu->{seq}) }, },
    0x80000008 => { cmd => 'cancel_sm_resp', reply => undef, },  
    0x00000009 => { cmd => 'bind_transceiver',
		    reply => sub { my ($me, $pdu) = @_;
				   $me->set_version(0x34);
				   $me->bind_transceiver_resp(system_id => $sysid,
							      seq => $pdu->{seq});
			       }, },
    0x80000009 => { cmd => 'bind_transceiver_resp', reply => undef, }, 
    0x0000000b => { cmd => 'outbind',
		    reply => sub {  my ($me, $pdu) = @_;
				    $me->set_version(0x34);
				    $me->bind_receiver(system_id => $sysid,
						       password => $pw) }, },
    0x00000015 => { cmd => 'enquire_link',
		    reply => sub { my ($me, $pdu) = @_;
				   $me->enquire_link_resp(seq => $pdu->{seq}) }, },      
    0x80000015 => { cmd => 'enquire_link_resp', reply => undef, }, 
    0x00000021 => { cmd => 'submit_multi',
		    reply => sub { my ($me, $pdu) = @_;
				   $me->submit_multi_resp(message_id=>'123456789',
#							  no_unsuccess=>0,
							  seq => $pdu->{seq} ) }, },
    0x80000021 => { cmd => 'submit_multi_resp', reply => undef, }, 
    0x00000102 => { cmd => 'alert_notification', reply => undef, },  # ***
    0x00000103 => { cmd => 'data_sm', reply => undef, },  # ***
    0x80000103 => { cmd => 'data_sm_resp', reply => undef, }, 

#4#cut

    # v4 codes

    0x80010000 => { cmd => 'generic_nack_v4', reply => undef, }, 
    0x00010001 => { cmd => 'bind_receiver_v4',
		    reply => sub { my ($me, $pdu) = @_;
				   $me->set_version(0x40);
				   $me->bind_receiver_resp(system_id => $sysid,
							   facilities_mask => $facil,
							   seq => $pdu->{seq});
			       }, },
    0x80010001 => { cmd => 'bind_receiver_resp_v4', reply => undef, }, 
    0x00010002 => { cmd => 'bind_transmitter_v4',
		    reply => sub { my ($me, $pdu) = @_;
				   $me->set_version(0x40);
				   $me->bind_transmitter_resp(system_id => $sysid,
							      facilities_mask => $facil,
							      seq => $pdu->{seq});
			       }, },
    0x80010002 => { cmd => 'bind_transmitter_resp_v4', reply => undef, }, 
    0x00010003 => { cmd => 'query_sm_v4',
		    reply => sub { my ($me, $pdu) = @_;
				   $me->query_sm_resp(message_id=>$pdu->{message_id},
						      final_date=>'010711135959000+',
						      seq => $pdu->{seq}) }, },
    0x80010003 => { cmd => 'query_sm_resp_v4', reply => undef, },     
    0x00010004 => { cmd => 'submit_sm_v4',
		    reply => sub { my ($me, $pdu) = @_;
				   $me->submit_sm_resp(message_id=>'123456789',
#						       num_unsuccess=>0,
#						       destination_addr=>$pdu->{source_addr},
						       error_status_code => 0,
						       seq => $pdu->{seq} ) }, },
    0x80010004 => { cmd => 'submit_sm_resp_v4', reply => undef, },   
    0x00010005 => { cmd => 'deliver_sm_v4', reply => undef, },
    0x80010005 => { cmd => 'deliver_sm_resp_v4', reply => undef, },  # Need to handle this?
    0x00010006 => { cmd => 'unbind_v4',
		    reply => sub { my ($me, $pdu) = @_;
				   $me->unbind_resp(seq => $pdu->{seq});
				   warn "$$: Remote sent unbind. Dropping connection.";
				   exit;
			       }, },       
    0x80010006 => { cmd => 'unbind_resp_v4',
		    reply => sub { warn "$$: Remote replied to unbind. Dropping connection.";
				   exit;
			       }, },       
    0x00010007 => { cmd => 'replace_sm_v4',
		    reply => sub { my ($me, $pdu) = @_;
				   $me->replace_sm_resp(seq => $pdu->{seq}) }, },
    0x80010007 => { cmd => 'replace_sm_resp_v4', reply => undef, }, 
    0x00010008 => { cmd => 'cancel_sm_v4',
		    reply => sub { my ($me, $pdu) = @_;
				   $me->cancel_resp(seq => $pdu->{seq}) }, },      
    0x80010008 => { cmd => 'cancel_sm_resp_v4', reply => undef, },  
    0x00010009 => { cmd => 'delivery_receipt_v4',
		    reply => sub { my ($me, $pdu) = @_;
				   $me->delivery_receipt_resp(seq => $pdu->{seq}) }, },
    0x80010009 => { cmd => 'delivery_receipt_resp_v4', reply => undef, },  
    0x0001000a => { cmd => 'enquire_link_v4',
		    reply => sub { my ($me, $pdu) = @_;
				   $me->enquire_link_resp(seq => $pdu->{seq}) }, },
    0x8001000a => { cmd => 'enquire_link_resp_v4', reply => undef, },
    0x0001000b => { cmd => 'outbind_v4',
		    reply => sub { my ($me, $pdu) = @_;
				   $me->set_version(0x34);
				   $me->bind_receiver(system_id => $sysid,
						      password => $pw,
						      facilities_mask => $facil,
						      seq => $pdu->{seq}) }, },
#4#end
};

$smpp = Net::SMPP->new_receiver($host,
			      smpp_version => $vers,
			      interface_version => $if_vers,
			      system_id => $sysid,
			      password => $pw,
			      addr_ton => 0x09,
			      addr_npi => 0x00,
			      source_addr_ton => 0x09,
			      source_addr_npi => 0x00,
			      dest_addr_ton => 0x09,
			      dest_addr_npi => 0x00,
			      system_type => '_001',
			      facilities_mask => $facil,
			      port => $port,
#				timeout => 7,
			      )
    or die "Can't create server: $!";

while (1) {
    warn "Waiting for PDU";
    $pdu = $smpp->read_pdu() or die "$$: PDU not read. Closing connection";
    print "Received #$pdu->{seq} $pdu->{cmd}:". Net::SMPP::pdu_tab->{$pdu->{cmd}}{cmd} ."\n"
	;
    warn Dumper($pdu) if $trace;

    if (defined reply_tab->{$pdu->{cmd}}) {
	&{reply_tab->{$pdu->{cmd}}{reply}}($c, $pdu);
	warn "Replied";
    } else {
	warn "Don't know to reply to $pdu->{cmd}";
	sleep 1;
    }
}

#EOF
