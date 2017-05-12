#!/usr/bin/perl
#
# Copyright (c) 2001 SymLABS <symlabs@symlabs.com>, All Rights Reserved.
# See README for license. NO WARRANTY.
#
# 15.3.2001, Sampo Kellomaki <sampo@symlabs.com>
# $Id: bind-hammer.pl,v 1.4 2001/09/28 16:27:41 sampo Exp $
#
# ESME - Exterior Short Message Entity
#
# Test Net::SMPP in ESME role
#
# Usage: ./bind-hammer.pl *version*

use Net::SMPP;
use Data::Dumper;

$trace = 1;
$sysid = "GSMSGW";
$pw = "secret";
$host = 'localhost';
$port = 9900;
$facil = 0x00010003;
($vers) = @ARGV;
$vers = $vers == 4 ? 0x40 : 0x34;  #4
$if_vers = 0x00;

### Connect and bind

$Net::SMPP::trace = 0;
for my $i (1..10000) {

    ($smpp, $resp) = Net::SMPP->new_transmitter($host,
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
		       )
	or die "Can't contact server: $!";

    ###
    ### Typical session in synchronous mode
    ###

    #warn "Sending submit_sm";

    $resp = $smpp->submit_sm(message_class=>0,
			 protocol_id=>0x20,   # telematic_interworking
			 validity_period=>0,  # "default"
			 source_addr_ton => 0x00,
			 source_addr => '0777101777',
			 destination_addr => '077747772777',
			 msg_reference => '00000097',
			 priority_level => 3,
			 registered_delivery_mode => 1,
			 data_coding => 9,
			 short_message=>'Hello',
			 PVCY_AuthenticationStr => "\x01\x00\x00",
			 PDC_MessageClass => "\x20\x00",
			 PDC_PresentationOption => "\x01\xff\xff\xff",
			 PDC_AlertMechanism => "\x01",
			 PDC_Teleservice => "\x01",
			 PDC_PredefinedMsg => "\0",
			 source_subaddress => "\x01\x00\x00",  # PDC_Originator_Subaddr
			 dest_subaddress => "\x01\x00\x00",    # PDC_Destination_Subaddr
			 );

    #warn Dumper $resp;

    $resp = $smpp->unbind();
}

warn Dumper $resp;
warn "Done.";

#EOF
