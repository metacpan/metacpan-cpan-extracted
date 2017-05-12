#!/usr/bin/perl
#
# Copyright (c) 2001 SymLABS <symlabs@symlabs.com>, All Rights Reserved.
# See README for license. NO WARRANTY.
#
# 15.3.2001, Sampo Kellomaki <sampo@iki.fi>
# July, 2001, J-Phone specific experimentation and hacks
#             by Felix Gaehtgens <felix@symlabs.com>
# 1.8.2001, Checked in CVS and clarified, Sampo Kellomaki <sampo@symlabs.com>
# $Id: sendmessage.pl,v 1.4 2001/09/28 20:08:25 sampo Exp $
#
# Send a message given on command line
#
# Test Net::SMPP in ESME role
#
# Usage: ./sendmessage.pl *message*

use Net::SMPP;
use Data::Dumper;

$trace = 1;
$Net::SMPP::trace = 1;
$sysid = "GSMSGW";
$pw = "secret";
$host = 'localhost';
$port = 9900;
$facil = 0x00010003;  # NF_PDC | GF_PVCY
my $mymsg = join (" ", @ARGV);
my $multimsg = 0;
if (length ($mymsg) > 128) {
    $multimsg = 1;
}

$vers = 0x40;  #4
$if_vers = 0x00;

### Connect and bind

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

warn "Sending submit_sm";

$sent_no = 0;
$origref = $ref = 160;
$textptr = 0;
$finished = 0;

#print "FELIX: Now checking length of string: ".length ($mymsg)."\n";
if (length ($mymsg) > 128) {
    $multimsg_maxparts = int (length ($mymsg) / 128);
    if (length ($mymsg) % 128) {
	$multimsg_maxparts++;
    }
    $multimsg_curpart = 1;
    print "multimsgsparts: $multimsg_maxparts\n";
}
$msgtext = substr ($mymsg, 0, 128, "");
while (length ($msgtext)) {

    ### See V4, p. 77

    if ($multimsg_curpart) {
	$multimsg = pack ("nCC", $origref, $multimsg_curpart, $multimsg_maxparts);
	printf STDERR "\nI AM SETTING MULTIPART: len=%d\n", multimsg;
    } else {
	$multimsg = undef;
    }
    printf "Now sending: (multimsg = %.8x) (len: %d) %s\n", $multimsg, length ($msgtext), $msgtext;
    $msgref = sprintf "%.8d", $ref;
    print "MESSAGE REFERENCE: $msgref   REF= $ref\n";

    $resp = $smpp->submit_sm(message_class=>0,
			     protocol_id=>0x20,   # telematic_interworking
			     validity_period=>0,  # "default"
			     source_addr_ton => 0x09,
			     source_addr => '',
#			     source_addr => '0077719011234777',
			     destination_addr => '077714107777',

#			     msg_reference => '\0',
			     msg_reference => $msgref,
			     priority_level => 3,
			     registered_delivery_mode => 0,
			     data_coding => 9,
			     short_message=>$msgtext,
			     
			     PDC_MessageClass => "\x20\x00",
			     PDC_PresentationOption => "\x01\xff\xff\xff",
			     PDC_AlertMechanism => "\x01",
			     PDC_Teleservice => "\x04",
			     PDC_MultiPartMessage => $multimsg,
			     PDC_PredefinedMsg => "\0",
			     PVCY_AuthenticationStr => "\x01\x00\x00",
			     
			     source_subaddress => "\x01\x00\x00",  # PDC_Originator_Subaddr
			     dest_subaddress => "\x01\x00\x00",    # PDC_Destination_Subaddr
			     );
    $multimsg_curpart++;
    $msgtext = substr ($mymsg, 0, 120, "");
    $ref++;
}

# warn Dumper $resp;

$resp = $smpp->unbind();

# warn Dumper $resp;
warn "Done.";

#EOF
