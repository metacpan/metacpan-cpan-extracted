# Net::SMPP.pm  -  SMPP over TCP, pure perl implementation
# Copyright (c) 2001-2011 Sampo Kellomaki <sampo@iki.fi>, All rights reserved.
# Portions Copyright (c) 2001-2005 Symlabs, All rights reserved.
# This code may be distributed under same terms as perl. NO WARRANTY.
# Work sponsored by Symlabs, the LDAP and directory experts (www.symlabs.com)
# 12.3.2001, Sampo Kellomaki <sampo@symlabs.com>
# 7.7.2001,  added SMPP 4.0 support --Sampo                               #4
# 9.7.2001,  continued 4.0 hacking --Sampo                                #4
# 11.7.2001, added J-Phone specific extended options --Sampo              #4
# 12.7.2001, fixed eating options off @_ --Sampo
# 1.8.2001,  merged in fixes from Felix Gaehtgens <felix@symlabs.com>, bumped
#            version to 0.90 to reflect successfully conducted tests --Sampo
# 25.9.2001, tagged all 4.0 specifics so that 3.4-only version can be     #4
#            extracted for public distribution --Sampo                    #4
# 11.12.2001, fixed encode_deliver_v4 to encode_deliver_sm_v4, bug reported
#            by Cristina Del Amo (Cristina.delAmo@vodafone-us.com), --Sampo
# 4.1.2002,  Fixed enquiry_link to enquire_link --Sampo
# 10.1.2002, applied big patch by Lars Thegler <lars@@thegler_.dk> to
#            make pack and unpack templates perl5.005_03 compatible. --Sampo
#            Caught bugs in decode_outbind_v34(), encode_query_sm(),
#            encode_query_sm_resp() and replace_sm() --Sampo
# 11.1.2002, 7bit pack and unpack --Sampo
# 3.4.2002,  command length check from Cris, rolled out 1.01 --Sampo
# 7.12.2002, applied some patched by Luis Munoz <lem@@cantv.net> --Sampo
# 8.12.2002, more patched from Luis, --Sampo
# 23.9.2004, applied bind ip patch from Igor Ivoilov <igor@_francoudi.com> --Sampo
# 29.4.2005, applied patch from Kristian Nielsen <kn_@@sifira..dk> --Sampo
# 21.4.2006, applied sysread patch from Dziugas.Baltrunas@bite..lt. Similar
#            patch was also proposed by Felix Gaehtgens <felix@symlabs..com> --Sampo
# 20.7.2007, patch from Matthias Meyser to fix enquiry_link, document 7bit (1.11) --Sampo
# 14.12.2008, adapted to SMPPv50, thanks to Gema niskazhu (and curse to
#             the spec authors for not letting me know about new version) --Sampo
# 24.6.2010, tweaked for perl 5.8.8 --Sampo
# 29.5.2011, improved signal handling in read_hard(), patch from Clemens Dorner --Sampo
#
# Why ${*$me}{async} vs. $me->async ?
#
# $Id: SMPP.pm,v 1.31 2008-12-02 16:41:30 sampo Exp $

### The comments often refer to sections of the following document
###   Short Message Peer to Peer Protocol Specification v3.4,
###   12-Oct-1999, Issue 1.2 (from www.smpp.org)
###
### Reference document for version 4.0 support was                        #4
###   Short Message Peer to Peer (SMPP) V4 Protocol Specification,        #4
###   29-Apr-1997, Version 1.1 (from Aldiscon/Logica)                     #4

package Net::SMPP;

require 5.008;
use strict;
use Socket;
use Symbol;
use Carp;
use IO::Socket;
use Data::Dumper;  # for debugging

use vars qw(@ISA $VERSION %default %param_by_name $trace);
@ISA = qw(IO::Socket::INET);
$VERSION = '1.19';
$trace = 0;

use constant Transmitter => 1;  # SMPP transmitter mode of operation
use constant Receiver    => 2;  #      receiver mode of operation
use constant Transceiver => 3;  #      both

### command_status code (Error Codes) from sec 5.1.3, table 5-2, pp.112-114

use constant status_code => {
    0x00000000 => { code => 'ESME_ROK', msg => 'No error', },
    0x00000001 => { code => 'ESME_RINVMSGLEN', msg => 'Message Length is invalid', },
    0x00000002 => { code => 'ESME_RINVCMDLEN', msg => 'Command Length is invalid', },
    0x00000003 => { code => 'ESME_RINVCMDID',  msg => 'Invalid Command ID', },
    0x00000004 => { code => 'ESME_RINVBNDSTS', msg => 'Incorrect BIND Status for given command', },
    0x00000005 => { code => 'ESME_RALYBND',    msg => 'ESME Already in bound state', },
    0x00000006 => { code => 'ESME_RINVPRTFLG', msg => 'Invalid priority flag', },
    0x00000007 => { code => 'ESME_RINVREGDLVFLG', msg => 'Invalid registered delivery flag', },
    0x00000008 => { code => 'ESME_RSYSERR',    msg => 'System Error', },
#    0x00000009 => { code => 'ESME_', msg => '', },
    0x0000000a => { code => 'ESME_RINVSRCADR', msg => 'Invalid source address', },
    0x0000000b => { code => 'ESME_RINVDSTADR', msg => 'Invalid destination address', },
    0x0000000c => { code => 'ESME_RINVMSGID',  msg => 'Message ID is invalid', },
    0x0000000d => { code => 'ESME_RBINDFAIL',  msg => 'Bind failed', },
    0x0000000e => { code => 'ESME_RINVPASWD',  msg => 'Invalid password', },
    0x0000000f => { code => 'ESME_RINVSYSID',  msg => 'Invalid System ID', },
#   0x00000010 => { code => 'ESME_', msg => '', },
    0x00000011 => { code => 'ESME_RCANCELFAIL',  msg => 'Cancel SM Failed', },
#   0x00000012 => { code => 'ESME_', msg => '', },
    0x00000013 => { code => 'ESME_RREPLACEFAIL', msg => 'Replace SM Failed', },
    0x00000014 => { code => 'ESME_RMSGQFUL',     msg => 'Message queue full', },
    0x00000015 => { code => 'ESME_RINVSERTYP',   msg => 'Invalid service type', },
# 0x00000016 - 0x00000032 reserved
    0x00000033 => { code => 'ESME_RINVNUMDESTS', msg => 'Invalid number of destinations', },
    0x00000034 => { code => 'ESME_RINVDLNAME',   msg => 'Invalid distribution list name', },
# 0x00000035 - 0x0000003f reserved
    0x00000040 => { code => 'ESME_RINVDESTFLAG', msg => 'Destination flag is invalid (submit_multi)', },
#   0x00000041 => { code => 'ESME_', msg => '', },
    0x00000042 => { code => 'ESME_RINVSUBREP',   msg => "Invalid `submit with replace' request (i.e. submit_sm with replace_if_present_flag set)", },
    0x00000043 => { code => 'ESME_RINVESMCLASS', msg => 'Invalid esm_class field data', },
    0x00000044 => { code => 'ESME_RCNTSUBDL',    msg => 'Cannot submit to distribution list', },
    0x00000045 => { code => 'ESME_RSUBMITFAIL',  msg => 'submit_sm or submit_multi failed', },
#   0x00000046 => { code => 'ESME_', msg => '', },
#   0x00000047 => { code => 'ESME_', msg => '', },
    0x00000048 => { code => 'ESME_RINVSRCTON', msg => 'Invalid source address TON', },
    0x00000049 => { code => 'ESME_RINVSRCNPI', msg => 'Invalid source address NPI', },
# 0x0000004a - 0x0000004f undocumented
    0x00000050 => { code => 'ESME_RINVDSTTON', msg => 'Invalid destination address TON', },
    0x00000051 => { code => 'ESME_RINVDSTNPI', msg => 'Invalid destination address NPI', },
#   0x00000052 => { code => 'ESME_', msg => '', },
    0x00000053 => { code => 'ESME_RINVSYSTYP', msg => 'Invalid system_type field', },
    0x00000054 => { code => 'ESME_RINVREPFLAG', msg => 'Invalid replace_if_present flag', },
    0x00000055 => { code => 'ESME_RINVNUMMSGS', msg => 'Invalid number of messages', },
#   0x00000056 => { code => 'ESME_', msg => '', },
#   0x00000057 => { code => 'ESME_', msg => '', },
    0x00000058 => { code => 'ESME_RTHROTTLED', msg => 'Throttling error (ESME has exceeded allowed message limits)', },
# 0x00000059 - 0x00000060 reserved
    0x00000061 => { code => 'ESME_RINVSCHED', msg => 'Invalid scheduled delivery time', },
    0x00000062 => { code => 'ESME_RINVEXPIRY', msg => 'Invalid message validity period (expiry time)', },
    0x00000063 => { code => 'ESME_RINVDFTMSGID', msg => 'Predefined message invalid or not found', },
    0x00000064 => { code => 'ESME_RX_T_APPN', msg => 'ESME Receiver Temporary App Error Code', },
    0x00000065 => { code => 'ESME_RX_P_APPN', msg => 'ESME Receiver Permanent App Error Code', },
    0x00000066 => { code => 'ESME_RX_R_APPN', msg => 'ESME Receiver Reject Message Error Code', },
    0x00000067 => { code => 'ESME_RQUERYFAIL', msg => 'query_sm request failed', },
# 0x00000068 - 0x000000bf reserved
    0x000000c0 => { code => 'ESME_RINVOPTPARSTREAM', msg => 'Error in the optional part of the PDU Body', },
    0x000000c1 => { code => 'ESME_ROPTPARNOTALLWD', msg => 'Optional paramenter not allowed', },
    0x000000c2 => { code => 'ESME_RINVPARLEN', msg => 'Invalid parameter length', },
    0x000000c3 => { code => 'ESME_RMISSINGOPTPARAM', msg => 'Expected optional parameter missing', },
    0x000000c4 => { code => 'ESME_RINVOPTPARAMVAL', msg => 'Invalid optional parameter value', },
# 0x000000c5 - 0x000000fd reserved
    0x000000fe => { code => 'ESME_RDELIVERYFAILURE', msg => 'Delivery Failure (used for data_sm_resp)', },
    0x000000ff => { code => 'ESME_RUNKNOWNERR', msg => 'Unknown error', },
# 0x00000100 - 0x000003ff reserved for SMPP extension
# 0x00000400 - 0x000004ff reserved for SMSC vendor specific errors
# 0x00000500 - 0xffffffff reserved

### *** Dear reader: if you know more error codes, e.g. in the
###     vendor specific range, please let me know so we can teach
###     this module about them.

};

### Convert the status code table into constants

do {
    no strict "refs";
    for my $k (keys(%{&status_code}))
    {
	eval { *{status_code->{$k}->{code}}        = sub { return $k; } };
        eval { *{status_code->{$k}->{code}.'_msg'} = sub { return *{status_code->{$k}->{msg}}; } };
    }
};

### Command IDs, sec 5.1.2.1, table 5-1, pp. 110-111

use constant CMD_generic_nack          => 0x80000000;
use constant CMD_bind_receiver         => 0x00000001;
use constant CMD_bind_receiver_resp    => 0x80000001;
use constant CMD_bind_transmitter      => 0x00000002;
use constant CMD_bind_transmitter_resp => 0x80000002;
use constant CMD_query_sm              => 0x00000003;
use constant CMD_query_sm_resp         => 0x80000003;
use constant CMD_submit_sm             => 0x00000004;
use constant CMD_submit_sm_resp        => 0x80000004;
use constant CMD_deliver_sm            => 0x00000005;
use constant CMD_deliver_sm_resp       => 0x80000005;
use constant CMD_unbind                => 0x00000006;
use constant CMD_unbind_resp           => 0x80000006;
use constant CMD_replace_sm            => 0x00000007;
use constant CMD_replace_sm_resp       => 0x80000007;
use constant CMD_cancel_sm             => 0x00000008;
use constant CMD_cancel_sm_resp        => 0x80000008;
use constant CMD_bind_transceiver      => 0x00000009;  # v3.4
use constant CMD_bind_transceiver_resp => 0x80000009;  # v3.4
use constant CMD_delivery_receipt      => 0x00000009;  # v4     #4
use constant CMD_delivery_receipt_resp => 0x80000009;  # v4     #4
use constant CMD_enquire_link_v4       => 0x0000000a;  #4
use constant CMD_enquire_link_resp_v4  => 0x8000000a;  #4
use constant CMD_outbind               => 0x0000000b;
use constant CMD_enquire_link          => 0x00000015;
use constant CMD_enquire_link_resp     => 0x80000015;
use constant CMD_submit_multi          => 0x00000021;
use constant CMD_submit_multi_resp     => 0x80000021;
use constant CMD_alert_notification    => 0x00000102;
use constant CMD_data_sm               => 0x00000103;
use constant CMD_data_sm_resp          => 0x80000103;

### Type of Number constants, see section 5.2.5, p. 117

use constant TON_unknown           => 0x00;
use constant TON_international     => 0x01;
use constant TON_national          => 0x02;
use constant TON_network_specific  => 0x03;
use constant TON_subscriber_number => 0x04;
use constant TON_alphanumeric      => 0x05;
use constant TON_abbreviated       => 0x06;

### Number plan indicators, sec 5.2.6, p. 118

use constant NPI_unknown     => 0x00;
use constant NPI_isdn        => 0x01;  # E163/E164
use constant NPI_data        => 0x03;  # X.121
use constant NPI_telex       => 0x04;  # F.69
use constant NPI_land_mobile => 0x06;  # E.212
use constant NPI_national    => 0x08;
use constant NPI_private     => 0x09;
use constant NPI_ERMES       => 0x0a;
use constant NPI_internet    => 0x0e;  # IP
use constant NPI_wap         => 0x12;  # WAP client id

### ESM class constants, these are additive, use or (|) to combine them (5.2.12, p.121)

use constant ESM_mode_mask    => 0x03;
use constant ESM_type_mask    => 0x3c;
use constant ESM_feature_mask => 0xc0;

use constant ESM_mode_default  => 0x00;           # usually store and forward
use constant ESM_mode_datagram => 0x01;
use constant ESM_mode_forward  => 0x02;           # i.e. transaction mode
use constant ESM_mode_store_and_forward => 0x03;  # store and forward mode (even if not default)

use constant ESM_type_default      => 0x00;       # default message type (i.e. normal message)
use constant ESM_type_delivery_receipt => 0x04;   #  SMSC Delivery receipt (SMSC->ESME only)
use constant ESM_type_delivery_ack => 0x08;       # ESME delivery acknowledgement
use constant ESM_type_0011 => 0x0a;
use constant ESM_type_user_ack     => 0x10;       # ESME manual/user acknowledgement
use constant ESM_type_0101 => 0x14;
use constant ESM_type_conversation_abort => 0x18; # Korean CDMA (SMSC->ESME only)
use constant ESM_type_0111 => 0x1a;
use constant ESM_type_intermed_deliv_notif => 0x20;  # Intermediate delivery notification (SMSC->ESME)
use constant ESM_type_1001 => 0x24;
use constant ESM_type_1010 => 0x28;
use constant ESM_type_1011 => 0x2a;
use constant ESM_type_1100 => 0x30;
use constant ESM_type_1101 => 0x34;
use constant ESM_type_1110 => 0x38;
use constant ESM_type_1111 => 0x3a;

use constant ESM_feature_none => 0x00;
use constant ESM_feature_UDHI => 0x40;  # User Data Header Ind, only relevant for MT short messages
use constant ESM_feature_reply_path => 0x80;           # only relevant for GSM networks
use constant ESM_feature_UDHI_and_reply_path => 0xc0;  # only relevant for GSM networks

### Registered delivery bits (5.2.17, p. 124)

use constant REG_receipt_mask => 0x03;
use constant REG_ack_mask => 0x0c;
use constant REG_intermed_notif_mask => 0x80;
		
use constant REG_receipt_none    => 0x00;
use constant REG_receipt_always  => 0x01;  # receipt is returned for both success and failure
use constant REG_receipt_on_fail => 0x02;
use constant REG_receipt_res     => 0x03;
		
use constant REG_ack_none => 0x00;
use constant REG_ack_delivery => 0x04;
use constant REG_ack_user => 0x08;
use constant REG_ack_delivery_and_user => 0x0c;
		
use constant REG_intermed_notif_none => 0x00;
use constant REG_intermed_notif => 0x10;

### submit_multi dest_flag constants (5.2.25, p. 129)

use constant MULTIDESTFLAG_SME_Address => 1;
use constant MULTIDESTFLAG_dist_list => 2;

### message_state codes returned in query_sm_resp (5.2.28, table 5-6, p. 130)

use constant MSGSTATE_enroute   => 1;
use constant MSGSTATE_delivered => 2;
use constant MSGSTATE_expired   => 3;  # message validity period has expired
use constant MSGSTATE_deleted   => 4;
use constant MSGSTATE_undeliverable => 5;
use constant MSGSTATE_accepted  => 6;  # i.e. message has been manually read on behalf of
                                       # the subscriber by customer service
use constant MSGSTATE_unknown   => 7;  # message is in invalid state
use constant MSGSTATE_rejected  => 8;

### Facility codes for V4 (used as arguments to bind, or the bits together)   #4

use constant GF_PVCY    => 0x00000001; # V4 extended p.58  Privacy  #4
use constant GF_SUBADDR => 0x00000002; # V4 extended p.64           #4
use constant NF_CC      => 0x00080000; # V4 extended p.69  Call Control  *** N.B: Spec has bug *** #4
use constant NF_PDC     => 0x00010000; # V4 extended p.74           #4
use constant NF_IS136   => 0x00020000; # V4 extended p.80  (TDMA)   #4
use constant NF_IS95A   => 0x00040000; # V4 extended p.84  (CDMA) (TIA/EIA IS-637)   #4

### Default value table that gets incorporated into smpp object unless
### overridden in the constructor

use constant Default => {

  async => 0,
  port => 2255,        # TCP port
  timeout => 5,        # Connection establishment timeout
  listen => 120,       # size of listen queue for new_listen()
  mode => Transceiver, # Chooses type of bind #4> (Transceiver is illegal for v4) <4#

  enquire_interval => 0,  # How often enquire PDU is sent during read_hard(). 0 == off

### Version dependent defaults. Mainly these are used to handle different     #4
### message header formats between v34 and v4 in a consistent way. Generally  #4
### these are set in the constructor based on the smpp_version field.         #4

  smpp_version => 0x34,  # Supported versions are 0x34 == 3.4 #4> and 0x40 == 4.0 <4#
  head_templ => 'NNNN',  # v3.4 'NNNN', #4> v4.0 'NNNNxxxx', must change in tandem with above <4#
  head_len => 16,        # v3.4 16, #4> v4.0 20, must change in tandem with smpp_version <4#
  cmd_version => 0x00000000, # v3.4 0x00000000, #4> v4 0x00010000; to be or'd with cmd <4#

### Default values for bind parameters
### For interpretation of these parameters refer to
### sections 4.1 (p.51) and 5.2 (p. 116).

  system_id => '',     # 5.2.1, usually needs to be supplied
  password => '',      # 5.2.2
  system_type => '',   # 5.2.3, often optional, leave empty
  interface_version => 0x34,  # 5.2.4
  addr_ton => 0x00,    # 5.2.5  type of number
  addr_npi => 0x00,    # 5.2.6  numbering plan indicator
  address_range => '', # 5.2.7  regular expression matching numbers
  facilities_mask => 0x00000000, # SMPP v4.0 extension   #4

### Default values for submit_sm and deliver_sm

  service_type => '',  # NULL: SMSC defaults, #4> on v4 this is message_class <4#
  message_class => 0xffff, # v4: 0xffff = not required, 0-0x0fff = non replace,           #4
                           #     0x8000-0x8fff = replace types, others reserved (v4 p.32) #4
  source_addr_ton => 0x00, #? not known, see sec 5.2.5
  source_addr_npi => 0x00, #? not known, see sec 5.2.6
  source_addr => '',       ## NULL: not known. You should set this for reply to work.
  dest_addr_ton => 0x00,  #??
  dest_addr_npi => 0x00,  #??
  destination_addr => '', ### Destination address must be supplied
  esm_class => 0x00,      # Default mode (store and forward) and type (5.2.12, p.121)
  messaging_mode => 0x00, # v4 Default mode (store and forward) (v4, table 6-8, p.33)    #4
  msg_reference => '',    # v4, either empty or 9 digits. For user messages 4 first digits must be 0 #4
  protocol_id => 0x00,    ### 0 works for TDMA & CDMA, for GSM set according to GSM 03.40
  telematic_interworking => 0xff, # v4 name for v34 protocol_id (SMPP V4 Telematic Interworking Identifiers, sec 7.11, p.68) #4
  priority_flag => 0,     # non-priority/bulk/normal
  priority_level => 0xff, # v4: 0=lowest, 1=lowmid, 2=himid, 3=highest, 4-254 reserved, 255 default #4
  schedule_delivery_time => '',  # NULL: immediate delivery
  validity_period => '',  # NULL: SMSC default validity period
  registered_delivery => 0x00,  # no receipt, no ack, no intermed notif
  registered_delivery_mode => 0x00,  # v4: 0=no receipt, 1=receipt required, 2=nondelivery receipt confirmation  #4
  replace_if_present_flag => 0, # no replacement
  data_coding => 0,       # SMSC default alphabet
  sm_default_msg_id => 0, # Do not use canned message

### default values for query_sm_resp
  final_date => '',  # NULL: message has not yet reached final state
  error_code => 0,   # no error
  network_error_code => 0, # v4 no error?  #4
### default values for alert_notification
  esme_addr_ton => 0x00,
  esme_addr_npi => 0x00,

### default values used by cancel_sm
  message_id => '', # NULL: other parameters specify message to be cancelled

### Table of PDU handlers. These PDUs are automatically
### handled during wait_pdu() (as opposed to being discarded).
### they are called as
###        $smpp->handler($pdu);
### N.B. because the command number is constant, a comma must be used as separator
###      to prevent interpretation as string. (Thanks Matthias Meyser for pointing this out.)

  handlers => {
	CMD_enquire_link, \&handle_enquire_link,
	CMD_enquire_link_v4, \&handle_enquire_link,  #4
    }, 
};

### Optional parameter tags, see sec 5.3.2, Table 5-7, pp.132-133
### See also Sec 4.8.1 "TLV Tag", Table 4-60 "TLV Tag Definitions", pp. 135-137

use constant param_tab => {
    0x0005 => { name => 'dest_addr_subunit',    technology => 'GSM', },
    0x0006 => { name => 'dest_network_type',    technology => 'Generic', },
    0x0007 => { name => 'dest_bearer_type',     technology => 'Generic', },
    0x0008 => { name => 'dest_telematics_id',   technology => 'GSM', },

    0x000d => { name => 'source_addr_subunit',  technology => 'GSM', },
    0x000e => { name => 'source_network_type',  technology => 'Generic', },
    0x000f => { name => 'source_bearer_type',   technology => 'Generic', },
    0x0010 => { name => 'source_telematics_id', technology => 'GSM', },

    0x0017 => { name => 'qos_time_to_live', technology => 'Generic', },
    0x0019 => { name => 'payload_type', technology => 'Generic', },
    0x001d => { name => 'additional_status_info_text', technology => 'Generic', },
    0x001e => { name => 'receipted_message_id',   technology => 'Generic', },
    0x0030 => { name => 'ms_msg_wait_facilities', technology => 'GSM', },

    0x0101 => { name => 'PVCY_AuthenticationStr', technology => '? (J-Phone)', },  # V4ext pp.58-62  #4
    # "\x01\x00\x00"  0x010000  no privacy option

    0x0201 => { name => 'privacy_indicator',  technology => 'CDMA,TDMA', },
    0x0202 => { name => 'source_subaddress',  technology => 'CDMA,TDMA', },  # V4ext pp. 65-67  #4
    # Aka PDC_Originator_Subaddr, "\x01\x00\x00" 0x010000 undefined #4> (J-Phone) <4#
    0x0203 => { name => 'dest_subaddress',    technology => 'CDMA,TDMA', },  # V4ext pp. 65-67  #4
    # Aka PDC_Destination_Subaddr, "\x01\x00\x00" 0x010000 undefined #4> (J-Phone) <4#
    0x0204 => { name => 'user_message_reference', technology => 'Generic', },
    0x0205 => { name => 'user_response_code', technology => 'CDMA,TDMA', },
    0x020a => { name => 'source_port',        technology => 'WAP', },
    0x020b => { name => 'destination_port',   technology => 'WAP', },
    0x020c => { name => 'sar_msg_ref_num',    technology => 'Generic', },
    0x020d => { name => 'language_indicator', technology => 'CDMA,TDMA', },
    0x020e => { name => 'sar_total_segments', technology => 'Generic', },
    0x020f => { name => 'sar_segment_seqnum', technology => 'Generic', },
    0x0210 => { name => 'sc_interface_version',  technology => 'Generic', },  # bind_*_resp

    0x0301 => { name => 'CC_CBN', technology => 'V4', }, # V4ext p.70  Call Back Number  #4
    0x0302 => { name => 'callback_num_pres_ind', technology => 'TDMA', },  # V4ext p.71  CC_CBNPresentation #4
    0x0303 => { name => 'callback_num_atag',  technology => 'TDMA', },  # V4ext p.71  CC_CBNAlphaTag #4
    0x0304 => { name => 'number_of_messages', technology => 'CDMA', },  # V4ext p.72  CC_NumberOfMessages #4
    0x0381 => { name => 'callback_num', technology => 'CDMA,TDMA,GSM,iDEN', },

    0x0420 => { name => 'dpf_result',   technology => 'Generic', },
    0x0421 => { name => 'set_dpf',      technology => 'Generic', },
    0x0422 => { name => 'ms_availability_status', technology => 'Generic', },
    0x0423 => { name => 'network_error_code', technology => 'Generic', },
    0x0424 => { name => 'message_payload',    technology => 'Generic', },
    0x0425 => { name => 'delivery_failure_reason', technology => 'Generic', },
    0x0426 => { name => 'more_messages_to_send',   technology => 'GSM', },
    0x0427 => { name => 'message_state',    technology => 'Generic', },
    0x0428 => { name => 'congestion_state', technology => 'Generic', },

    0x0501 => { name => 'ussd_service_op',  technology => 'GSM (USSD)', },

    0x0600 => { name => 'broadcast_channel_indicator',  technology => 'GSM', },
    0x0601 => { name => 'broadcast_content_type',       technology => 'CDMA, TDMA, GSM', },
    0x0602 => { name => 'broadcast_content_type_info',  technology => 'CDMA, TDMA', },
    0x0603 => { name => 'broadcast_message_class',      technology => 'GSM', },
    0x0604 => { name => 'broadcast_rep_num',            technology => 'GSM', },
    0x0605 => { name => 'broadcast_frequency_interval', technology => 'CDMA, TDMA, GSM', },
    0x0606 => { name => 'broadcast_area_identifier',    technology => 'CDMA, TDMA, GSM', },
    0x0607 => { name => 'broadcast_error_status',       technology => 'CDMA, TDMA, GSM', },
    0x0608 => { name => 'broadcast_area_success',       technology => 'GSM', },
    0x0609 => { name => 'broadcast_end_time',           technology => 'CDMA, TDMA, GSM', },
    0x060a => { name => 'broadcast_service_group',      technology => 'CDMA, TDMA', },
    0x060b => { name => 'billing_identification',       technology => 'Generic', },
    0x060d => { name => 'source_network_id',            technology => 'Generic', },
    0x060e => { name => 'dest_network_id',              technology => 'Generic', },
    0x060f => { name => 'source_node_id',               technology => 'Generic', },
    0x0610 => { name => 'dest_node_id',                 technology => 'Generic', },
    0x0611 => { name => 'dest_addr_np_resolution',      technology => 'CDMA, TDMA (US Only)', },
    0x0612 => { name => 'dest_addr_np_information',     technology => 'CDMA, TDMA (US Only)', },
    0x0613 => { name => 'dest_addr_np_country',         technology => 'CDMA, TDMA (US Only)', },

    0x1201 => { name => 'display_time',     technology => 'CDMA,TDMA', },  # IS136_DisplayTime
    0x1203 => { name => 'sms_signal',       technology => 'TDMA', },
    0x1204 => { name => 'ms_validity',      technology => 'CDMA,TDMA', },

    0x1304 => { name => 'IS95A_AlertOnDelivery', technology => 'CDMA', },    # V4ext p.85  #4
    0x1306 => { name => 'IS95A_LanguageIndicator', technology => 'CDMA', },  # V4ext p.86  #4
    # "\x00"  0x00 = Unknown, 0x01 = english, 0x02 = french, 0x03 = spanish
    0x130c => { name => 'alert_on_message_delivery', technology => 'CDMA', },
    0x1380 => { name => 'its_reply_type',   technology => 'CDMA', },
    0x1383 => { name => 'its_session_info', technology => 'CDMA Korean [KORITS]', },

    # from http://docs.roottori.fi/display/MSGAPI/SMPP+commands
    # On the other hand, http://sms-clearing.com/downloads/gateway/7_SMPP.pdf
    # lists tag 0x1403 as holding both MCC and MNC in format "MCC/MNC"
    0x1402 => { name => 'operator_id', technology => 'vendor extension', },
    0x1403 => { name => 'tariff', technology => 'Mobile Network Code vendor extension', },
    # valyakol@gmail.com reports that these should be
    #0x1402 => { name => 'mBlox_operator', technology => 'Generic', },
    #0x1403 => { name => 'mBlox_rate', technology => 'Generic', },
    0x1450 => { name => 'mcc', technology => 'Mobile Country Code vendor extension', },
    0x1451 => { name => 'mnc', technology => 'Mobile Network Code vendor extension', },

    0x1101 => { name => 'PDC_MessageClass', technology => '? (J-Phone)', },  # V4ext p.75  #4
    # "\x20\x00"  0x2000   Sky Mail (service name of J-Phone SMS)  #4
    # 0x2033 - 0x20fe      Vendor defined
    # 0x1001               Coordinator (sender is able to send msg to more than two users)
    # 0x1002               Hotline (two users communicate using private line)
    # 0x1003               Relay Mail (Message relays user to user in turn by sender is specified)
    # 0x1004               Greeting service (J-Phone original) (sender can spec. deiv. date and time) #4

    0x1102 => { name => 'PDC_PresentationOption', technology => '? (J-Phone)', }, # V4ext p.76  #4
    # "\x00\xff\xff\xff" 0x00ffffff  Receiver defined option
    # "\x01\xff\xff\xff" 0x01ffffff  MS

    0x1103 => { name => 'PDC_AlertMechanism', technology => '? (J-Phone)', }, # V4ext p.76  #4
    # "\x01" 0x01  Alert tones level 1, 0x00 = no detectable alert, 0x0f = emergency, 0xff = default

    0x1104 => { name => 'PDC_Teleservice', technology => '? (J-Phone)', },    # V4 p.77  #4
    # "\x01" 0x01  Generalized message, 0x00 reserved, 0x02 two way, 0x03 concateneated

    0x1105 => { name => 'PDC_MultiPartMessage', technology => '? (J-Phone)',  # V4 p.77  #4
		format => 'nCC',  # MessageNumber, current_Sequence_Number, Maximum_Sequence_Number
               },
    #  "\0\0\0\0" 0x00000000 undefined, i.e. no multipart

    0x1106 => { name => 'PDC_PredefinedMsg', technology => '? (J-Phone)', },  # V4 p.78  #4
    # "\x00" 0x00   Undefined. This can be used to indicate preformatted messages, possibly with Kanji
    #0x0101 => { name => '', technology => '? (J-Phone)', },

    ### Tags not specified in v3.4 specification
    # *** dear reader, please add here any old or nonstandard tags
    #     that you know to exist so that this module becomes more
    #     useful
};

### invert the param_tab so we can get from name to code

for my $tag (keys %{&param_tab}) {
    $param_by_name{param_tab->{$tag}->{name}} = $tag;
}

sub format_a_line {
    my ($tt, $prefix) = shift;
    my $t=$tt;
    $t=~tr[\x20-\x7e][]c;
#    sprintf("$prefix%04x: " . '%02x ' x length($1) . "\t$t\n", $n+=16, map {ord} split('', $1));
}

sub hexdump {
    my ($data, $prefix) = @_;
    my $n = -16;
    $data =~ s/(.{1,16})/
	sprintf("$prefix%04x: " . '%02x ' x length($1) . "\n", $n+=16, map {ord} split('', $1))/ge;
#	sprintf("$prefix%04x: " . '%02x ' x length($1) . "\t$1\n", $n+=16, map {ord} split('', $1))/ge;
#	format_a_line($1, $prefix)/gsex;
    return $data;
}

### The optional values are encoded as TLV (tag, len, value) triplets where
### tag and length are 16 bit network byteorder and value is as much as
### the length says (length does not include tag or length of the length
### field itself).

sub decode_optional_params {
    my ($pdu, $offset) = @_;    
    while ($offset < length($pdu->{data})) {
	my ($tag, $len) = unpack 'nn', substr($pdu->{data}, $offset);
	my ($val) = unpack "a$len", substr($pdu->{data}, $offset+4);
	$pdu->{$tag} = $val;   # value is always accessible via numeric tag
	if (defined param_tab->{$tag}) {
	    $pdu->{param_tab->{$tag}->{name}} = $val;  # assign symbolic name
	} else {
	    warn "Unknown tag (offset $offset): $tag, len=".length($val).", val=`$val'";
	}
	$offset += 4 + length($val);
    }
}

sub encode_optional_params {
    my $data = '';
    while (@_) {  # N.B. by using array instead of hash we can control order of items
	my $opt_param = shift;
	my $val = shift;
	next if !defined $opt_param;  # skip mandatory parameters that were taken
	if ($param_by_name{$opt_param}) {
	    $data .= pack 'nna*', $param_by_name{$opt_param}, length($val), $val;
	} elsif ($opt_param =~ /^\d+$/) {  # specification by numeric tag
	    if ($val > -128 && $val < 127) {
		$data .= pack 'nnc', $opt_param, 1, $val;
	    } elsif ($val > -32768 && $val < 32767) {
		$data .= pack 'nnn!', $opt_param, 2, $val;
	    } else {
		$data .= pack 'nnN!', $opt_param, 4, $val;
	    }
	} else {
	    warn "Unknown optional parameter `$opt_param', skipping";
	}
    }
    return $data;
}

### return $_[0]->req_backend($op, &encode, @_);

sub req_backend {
    my $me = shift;
    my $op = shift;
    my $data = shift;
    my ($async, $seq);
    shift; # skip over second copy of $me

    ### Extract operational parameters that should not make part of PDU
    
    for (my $i=0; $i <= $#_; $i+=2) {
	next if !defined $_[$i];
	if ($_[$i] eq 'async')  { $async = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'seq')   { $seq = splice @_,$i,2,undef,undef; }
    }
    $async = ${*$me}{async} if !defined $async;
    if (!defined $seq) {
	$seq = ++(${*$me}{seq});
    }

    $data .= &encode_optional_params;  # will process remaining @_

    my $header = pack(${*$me}{head_templ}, ${*$me}{head_len}+length($data),
		      $op|${*$me}{cmd_version}, 0, $seq);

    warn "req Header:\n".hexdump($header,"\t") if $trace;
    warn "req Body:\n".hexdump($data,"\t") if $trace;
    $me->syswrite($header.$data);
    return $seq if $async;
    
    # Synchronous operation: wait for response

    warn "req sent, waiting response" if $trace;
    return $me->wait_pdu($op | ${*$me}{cmd_version} | 0x80000000, $seq);
}

### return $_[0]->resp_backend($op, &encode, @_);

sub resp_backend {
    my $me = shift;
    my $op = shift;
    my $data = shift;
    my ($async, $seq, $status);
    shift; # skip over second copy of $me

    ### Extract operational parameters that should not make part of PDU
    
    for (my $i=0; $i <= $#_; $i+=2) {
	next if !defined $_[$i];
	if ($_[$i] eq 'async')  { $async = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'seq')    { $seq = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'status') { $status = splice @_,$i,2,undef,undef; }
    }
    croak "seq must be supplied" if !defined $seq;
    $status = 0 if !defined $status;

    $data .= &encode_optional_params;  # will process remaining @_

    my $header = pack(${*$me}{head_templ}, ${*$me}{head_len}+length($data),
		      $op|${*$me}{cmd_version}, $status, $seq);
    #warn "$op,$seq==>".join(':',@_);

    warn "resp Header:\n".hexdump($header, "\t") if $trace;
    warn "resp Body:\n".hexdump($data, "\t") if $trace;
    $me->syswrite($header.$data);
    return $seq;
}

### These triplets occur often enough to warrant common function

sub decode_source_addr {
    my ($pdu, $data) = @_;
    ($pdu->{source_addr_ton},   # 2  C
     $pdu->{source_addr_npi},   # 3  C
     $pdu->{source_addr}) = unpack 'CCZ*', $data;
    return 1 + 1 + length($pdu->{source_addr}) + 1;
}

sub decode_destination_addr {
    my ($pdu, $data) = @_;
    ($pdu->{dest_addr_ton},   # 2  C
     $pdu->{dest_addr_npi},   # 3  C
     $pdu->{destination_addr}) = unpack 'CCZ*', $data;
    return 1 + 1 + length($pdu->{destination_addr}) + 1;
}

sub decode_source_and_destination {
    my ($pdu, $data) = @_;
    my $len = decode_source_addr($pdu, $data);
    $len += decode_destination_addr($pdu, substr($data, $len));
    return $len;
}

### Some PDUs do not have any body (mandatory parameters)

sub decode_empty {
    #my $pdu = shift;
    return 0;
}

###
### Public API functions for emitting trivial empty PDUs
###

sub unbind { $_[0]->req_backend(CMD_unbind, '', @_) }

sub enquire_link {
    my $me = $_[0];
    return $me->req_backend(${*$me}{smpp_version}==0x40?CMD_enquire_link_v4:CMD_enquire_link, '', @_); #4
    $me->req_backend(CMD_enquire_link, '', @_);
}

sub enquire_link_resp {
    my $me = $_[0];
    return $me->resp_backend(${*$me}{smpp_version}==0x40?CMD_enquire_link_resp_v4:CMD_enquire_link_resp, '', @_); #4
    $me->resp_backend(CMD_enquire_link_resp, '', @_);
}

sub generic_nack          { $_[0]->resp_backend(CMD_generic_nack, '', @_) }
sub unbind_resp           { $_[0]->resp_backend(CMD_unbind_resp, '', @_) }
sub replace_sm_resp       { $_[0]->resp_backend(CMD_replace_sm_resp, '', @_) }
sub cancel_sm_resp        { $_[0]->resp_backend(CMD_cancel_sm_resp, '', @_) }
sub delivery_receipt_resp { $_[0]->resp_backend(CMD_delivery_receipt_resp, '', @_) }

###
### All bind operations have same PDU format (4.1.1, p.46)
###

sub decode_bind {
    my $pdu = shift;
    my $me = shift;
    ($pdu->{system_id}) = unpack 'Z*', $pdu->{data};               # 1 Z
    my $len = length($pdu->{system_id}) + 1;
    ($pdu->{password}) = unpack 'Z*', substr($pdu->{data}, $len);  # 2 Z
    $len += length($pdu->{password}) + 1;
    ($pdu->{system_type}) = unpack 'Z*', substr($pdu->{data}, $len);  # 3 Z
    $len += length($pdu->{system_type}) + 1;
    ($pdu->{interface_version}, # 4
     $pdu->{addr_ton},          # 5
     $pdu->{addr_npi},          # 6
     $pdu->{address_range}) = unpack 'CCCZ*', substr($pdu->{data}, $len);
    $len += 3 + length($pdu->{address_range}) + 1;
    if (${*$me}{smpp_version}==0x40) {                                     #4
      ($pdu->{facilities_mask}) = unpack 'N', substr($pdu->{data}, $len);  #4
      $len += 4;                                                           #4
    }                                                                      #4
    return $len;
}

sub encode_bind {
    my $me = $_[0];
    my ($system_id, $password, $system_type, $interface_version,
	$addr_ton, $addr_npi, $address_range, $facilities_mask);

    ### Extract mandatory parameters from argument stream
    
    for (my $i=1; $i <= $#_; $i+=2) {
	next if !defined $_[$i];
	if ($_[$i] eq 'system_id') { $system_id = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'password')  { $password = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'system_type')   { $system_type = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'interface_version') { $interface_version = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'interface_type') { $interface_version = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'addr_ton')  { $addr_ton = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'addr_npi')  { $addr_npi = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'address_range') { $address_range = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'facilities_mask') { $facilities_mask = splice @_,$i,2,undef,undef; }  #4
    }

    ### Apply defaults for those mandatory arguments that were not specified
    
    $system_id = ${*$me}{system_id} if !defined $system_id;
    $password = ${*$me}{password} if !defined $password;
    $system_type = ${*$me}{system_type} if !defined $system_type;
    $interface_version = ${*$me}{interface_version} if !defined $interface_version;
    $addr_ton = ${*$me}{addr_ton} if !defined $addr_ton;
    $addr_npi = ${*$me}{addr_npi} if !defined $addr_npi;
    $address_range = ${*$me}{address_range} if !defined $address_range;
    $facilities_mask = ${*$me}{facilities_mask} if !defined $facilities_mask;  #4

    ### N.B. v3.4 last argument, $facilities_mask, will be ignored because     #4
    ###      template misses N, v4.0 it will be used because template has N    #4
    return pack(${*$me}{smpp_version}==0x40?'Z*Z*Z*CCCZ*N':'Z*Z*Z*CCCZ*',      #4
                $system_id, $password, $system_type,                           #4
		$interface_version, $addr_ton, $addr_npi,                      #4
		$address_range, $facilities_mask);                             #4
    return pack('Z*Z*Z*CCCZ*',
                $system_id, $password, $system_type,
		$interface_version, $addr_ton, $addr_npi,
		$address_range);
}

### All bind operations have same response format (4.1.2, p.47)

sub decode_bind_resp_v34 {
    my $pdu = shift;
    my $me = shift;    
    ($pdu->{system_id}) = unpack 'Z*', $pdu->{data};
    return length($pdu->{system_id}) + 1;
}

#4#cut
sub decode_bind_resp_v4 {
    my $pdu = shift;
    my $me = shift;    
    ($pdu->{system_id}) = unpack 'Z*', $pdu->{data};
    my $len = length($pdu->{system_id}) + 1;
    ($pdu->{facilities_mask}) = unpack 'N', substr($pdu->{data}, $len);
    return $len + 4;
}
#4#end

sub encode_bind_resp {
    my $me = $_[0];
    my ($system_id, $facilities_mask);

    for (my $i=1; $i <= $#_; $i+=2) {
	next if !defined $_[$i];
	if ($_[$i] eq 'system_id') { $system_id = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'facilities_mask') { $facilities_mask = splice @_,$i,2,undef,undef; }  #4
    }
    $system_id = ${*$me}{system_id} if !defined $system_id;
    $facilities_mask = ${*$me}{facilities_mask} if !defined $facilities_mask;           #4
    return pack(${*$me}{smpp_version}==0x40?'Z*N':'Z*', $system_id, $facilities_mask);  #4
    return pack('Z*', $system_id);
}

###
### Public API functions to emit binds and bind_resps.
###

sub bind_transceiver { $_[0]->req_backend(CMD_bind_transceiver, &encode_bind, @_) }
sub bind_transmitter { $_[0]->req_backend(CMD_bind_transmitter, &encode_bind, @_) }
sub bind_receiver    { $_[0]->req_backend(CMD_bind_receiver,    &encode_bind, @_) }

sub bind_transceiver_resp { $_[0]->resp_backend(CMD_bind_transceiver_resp, &encode_bind_resp, @_) }
sub bind_transmitter_resp { $_[0]->resp_backend(CMD_bind_transmitter_resp, &encode_bind_resp, @_) }
sub bind_receiver_resp    { $_[0]->resp_backend(CMD_bind_receiver_resp,    &encode_bind_resp, @_) }

### outbind (4.1.7.1)

sub decode_outbind_v34 {
    my $pdu = shift;
    my $me = shift;
    ($pdu->{system_id}) = unpack 'Z*', $pdu->{data};
    my $len = length($pdu->{system_id}) + 1;
    ($pdu->{password}) = unpack 'Z*', substr($pdu->{data}, $len);
    return $len + length($pdu->{password}) + 1;
}

#4#cut
sub decode_outbind_v4 {
    my $pdu = shift;
    my $me = shift;
    ($pdu->{password}) = unpack 'Z*', $pdu->{data};
    return length($pdu->{password}) + 1;
}
#4#end

sub encode_outbind {
    my $me = $_[0];
    my ($system_id, $password);

    for (my $i=1; $i <= $#_; $i+=2) {
	next if !defined $_[$i];
	if ($_[$i] eq 'system_id') { $system_id = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'password')  { $password = splice @_,$i,2,undef,undef; }
    }
    
    $system_id = ${*$me}{system_id} if !defined $system_id;
    $password = ${*$me}{password} if !defined $password;
    ### N.B. v4 does not have system_id. "CX" construct skips over this parameter   #4
    return pack(${*$me}{smpp_version}==0x40?'CXZ*':'Z*Z*', $system_id, $password);  #4
    return pack('Z*Z*', $system_id, $password);
}

sub outbind {
    my $me = $_[0];
    push @_, seq => ++(${*$me}{seq}) unless grep $_ eq 'seq', @_;
    return $me->resp_backend(CMD_outbind, &encode_outbind, @_);
}

### outbind does not have response

### submit (4.4.1), deliver (4.6.1) (both use same PDU format), p.59

sub decode_submit_v34 {
    my $pdu = shift;
    ($pdu->{service_type}) = unpack 'Z*', $pdu->{data};
    my $len = length($pdu->{service_type}) + 1;
    $len += decode_source_and_destination($pdu, substr($pdu->{data}, $len));
    
    ($pdu->{esm_class},         # 8
     $pdu->{protocol_id},       # 9
     $pdu->{priority_flag},     # 10
     $pdu->{schedule_delivery_time}) = unpack 'CCCZ*', substr($pdu->{data}, $len);
    $len += 1 + 1 + 1 + length($pdu->{schedule_delivery_time}) + 1;

    ($pdu->{validity_period}) = unpack 'Z*', substr($pdu->{data}, $len);
    $len += length($pdu->{validity_period}) + 1;

    my $sm_length;
    ($pdu->{registered_delivery}, # 13
     $pdu->{replace_if_present_flag}, # 14
     $pdu->{data_coding},       # 15
     $pdu->{sm_default_msg_id}, # 16
     $sm_length,                # 17
#                         1
#                12345678901234567 8
     ) = unpack 'CCCCC', substr($pdu->{data}, $len);
    $len += 1 + 1 + 1 + 1 + 1;
    ($pdu->{short_message}      # 18
     ) = unpack "a$sm_length", substr($pdu->{data}, $len);
    return $len + $sm_length;
}

sub encode_submit_v34 {
    my $me = $_[0];
    my ($service_type, $source_addr_ton, $source_addr_npi, $source_addr,
	$dest_addr_ton, $dest_addr_npi, $destination_addr,
	$esm_class, $protocol_id, $priority_flag,
	$schedule_delivery_time, $validity_period,
	$registered_delivery, $replace_if_present_flag, $data_coding,
	$sm_default_msg_id, $short_message);

    ### Extract mandatory parameters from argument stream
    
    for (my $i=1; $i <= $#_; $i+=2) {
	next if !defined $_[$i];
	if ($_[$i] eq 'service_type') { $service_type = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'source_addr_ton')  { $source_addr_ton = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'source_addr_npi')  { $source_addr_npi = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'source_addr')      { $source_addr = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'dest_addr_ton')    { $dest_addr_ton = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'dest_addr_npi')    { $dest_addr_npi = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'destination_addr') { $destination_addr = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'esm_class')     { $esm_class = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'protocol_id')   { $protocol_id = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'priority_flag') { $priority_flag = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'schedule_delivery_time') { $schedule_delivery_time = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'validity_period') { $validity_period = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'registered_delivery') { $registered_delivery = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'replace_if_present_flag') { $replace_if_present_flag = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'data_coding') { $data_coding = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'sm_default_msg_id') { $sm_default_msg_id = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'short_message') { $short_message = splice @_,$i,2,undef,undef; }
    }

    ### Apply defaults for those mandatory arguments that were not specified
    
    $service_type = ${*$me}{service_type} if !defined $service_type;
    $source_addr_ton = ${*$me}{source_addr_ton} if !defined $source_addr_ton;
    $source_addr_npi = ${*$me}{source_addr_npi} if !defined $source_addr_npi;
    $source_addr = ${*$me}{source_addr} if !defined $source_addr;
    $dest_addr_ton = ${*$me}{dest_addr_ton} if !defined $dest_addr_ton;
    $dest_addr_npi = ${*$me}{dest_addr_npi} if !defined $dest_addr_npi;
    croak "Must supply destination_addr to submit_sm or deliver_sm" if !defined $destination_addr;
    $esm_class = ${*$me}{esm_class} if !defined $esm_class;
    $protocol_id = ${*$me}{protocol_id} if !defined $protocol_id;
    $priority_flag = ${*$me}{priority_flag} if !defined $priority_flag;
    $schedule_delivery_time = ${*$me}{schedule_delivery_time} if !defined $schedule_delivery_time;
    $validity_period = ${*$me}{validity_period} if !defined $validity_period;
    $registered_delivery = ${*$me}{registered_delivery} if !defined $registered_delivery;
    $replace_if_present_flag = ${*$me}{replace_if_present_flag} if !defined $replace_if_present_flag;
    $data_coding = ${*$me}{data_coding} if !defined $data_coding;
    $sm_default_msg_id = ${*$me}{sm_default_msg_id} if !defined $sm_default_msg_id;
    $short_message = '' if !defined $short_message;

    return pack('Z*CCZ*CCZ*CCCZ*Z*CCCCCa*',
		$service_type, $source_addr_ton, $source_addr_npi, $source_addr,
		$dest_addr_ton, $dest_addr_npi, $destination_addr,
		$esm_class, $protocol_id, $priority_flag,
		$schedule_delivery_time, $validity_period,
		$registered_delivery, $replace_if_present_flag, $data_coding,
		$sm_default_msg_id, length($short_message), $short_message, );
}

#4#cut
### submit_sm_v4 (6.4.4.1), v4 p.32

sub decode_submit_v4 {
    my $pdu = shift;
    ($pdu->{message_class},     # 1 (2)
     $pdu->{source_addr_ton},   # 2 (1)
     $pdu->{source_addr_npi},   # 3 (1)
     $pdu->{source_addr},       # 4 (n+1)
     ) = unpack 'nCCZ*', $pdu->{data};
    my $len = 2	+ 1 + 1 + length($pdu->{source_addr}) + 1;

    ($pdu->{number_of_dests}) = unpack 'N', substr($pdu->{data}, $len);
    $len += 4;
    #warn "a decode_submit $len ($pdu->{number_of_dests}): ".hexdump(substr($pdu->{data}, $len));
    
    ### Walk down the variable length destination address list

    for (my $i = 0; $i < $pdu->{number_of_dests}; $i++) {
	($pdu->{dest_addr_ton}[$i],     # SME ton (v4 table 6-9, p. 36)
	 $pdu->{dest_addr_npi}[$i],     # SME npi
	 $pdu->{destination_addr}[$i])  # SME address
	    = unpack 'CCZ*', substr($pdu->{data}, $len);
	$len += 1 + 1 + length($pdu->{destination_addr}[$i]) + 1;
	#warn "b decode_submit $len: ".hexdump(substr($pdu->{data}, $len));
    }
    
    ### Now that we skipped over the variable length destinations
    ### we are ready to decode the rest of the packet.

    ($pdu->{messaging_mode},         # 7  C
     $pdu->{msg_reference}) = unpack 'CZ*', substr($pdu->{data}, $len);
    $len += 1 + length($pdu->{msg_reference}) + 1;
    #warn "c decode_submit $len: ".hexdump(substr($pdu->{data}, $len));

    ($pdu->{telematic_interworking}, # 9  C
     $pdu->{priority_level},         # 10 C
     $pdu->{schedule_delivery_time}) = unpack 'CCZ*', substr($pdu->{data}, $len);
    $len += 1 + 1 + length($pdu->{schedule_delivery_time}) + 1;
    warn "d decode_submit $len: ".hexdump(substr($pdu->{data}, $len)) if $trace;

    my $sm_length;
    ($pdu->{validity_period},        # 12 n  v4: n.b. this is now short instead of Cstr
     $pdu->{registered_delivery},    # 13 C
     $pdu->{data_coding},            # 14 C
     $pdu->{sm_default_msg_id},      # 15 C
     $sm_length,                     # 16 n

#                   1
#                7890123456 7
     ) = unpack 'nCCCn', substr($pdu->{data}, $len);
    $len += 2 + 1 + 1 + 1 + 2;
    ($pdu->{short_message}           # 17 a
     ) = unpack "a$sm_length", substr($pdu->{data}, $len);
    $len += $sm_length;
    warn "e decode_submit ($pdu->{short_message}) $len: ".hexdump(substr($pdu->{data}, $len)) if $trace;

    $pdu->{service_type} = $pdu->{message_class};   # compat v34
    $pdu->{esm_class} = $pdu->{messaging_mode};     # compat v34
    $pdu->{protocol_id} = $pdu->{telematic_interworking}; # compat v34
    $pdu->{priority_flag} = $pdu->{priority_level}; # compat v34
    
    return $len;
}

sub encode_submit_v4 {
    my $me = $_[0];
    my ($message_class, $source_addr_ton, $source_addr_npi, $source_addr,
	@dest_addr_ton, @dest_addr_npi, @destination_addr,
	$messaging_mode, $msg_reference, $telematic_interworking, $priority_level,
	$schedule_delivery_time, $validity_period,
	$registered_delivery_mode, $data_coding,
	$sm_default_msg_id, $short_message, $addr_data);

    ### Extract mandatory parameters from argument stream
    
    for (my $i=1; $i <= $#_; $i+=2) {
	next if !defined $_[$i];
	#warn "iter $i: >$_[$i]<";
	if ($_[$i] eq 'message_class')   { $message_class = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'service_type')    { $message_class = splice @_,$i,2,undef,undef; } # v34
	elsif ($_[$i] eq 'source_addr_ton') { $source_addr_ton = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'source_addr_npi') { $source_addr_npi = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'source_addr')     { $source_addr = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'dest_addr_ton')   {
	    @dest_addr_ton = ref($_[$i+1]) ? @{scalar(splice @_,$i,2,undef,undef)}
	                                   : (scalar(splice @_,$i,2,undef,undef));
	}
	elsif ($_[$i] eq 'dest_addr_npi')   {
	    @dest_addr_npi = ref($_[$i+1]) ? @{scalar(splice @_,$i,2,undef,undef)}
	                                   : (scalar(splice @_,$i,2,undef,undef));
	}
	elsif ($_[$i] eq 'destination_addr') {
	    @destination_addr = ref($_[$i+1]) ? @{scalar(splice @_,$i,2,undef,undef)}
	                                      : (scalar(splice @_,$i,2,undef,undef));
	}
	elsif ($_[$i] eq 'messaging_mode') { $messaging_mode = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'esm_class')      { $messaging_mode = splice @_,$i,2,undef,undef; } # v34
	elsif ($_[$i] eq 'msg_reference')  { $msg_reference = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'telematic_interworking') { $telematic_interworking = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'protocol_id') { $telematic_interworking = splice @_,$i,2,undef,undef; } # v34
	elsif ($_[$i] eq 'priority_level') { $priority_level = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'priority_flag')  { $priority_level = splice @_,$i,2,undef,undef; } # v34
	elsif ($_[$i] eq 'schedule_delivery_time') { $schedule_delivery_time = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'validity_period') { $validity_period = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'registered_delivery_mode') { $registered_delivery_mode = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'registered_delivery') { $registered_delivery_mode = splice @_,$i,2,undef,undef; } # v34
	elsif ($_[$i] eq 'data_coding') { $data_coding = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'sm_default_msg_id') { $sm_default_msg_id = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'short_message') { $short_message = splice @_,$i,2,undef,undef; }

	### Following kludge was added by Felix as PTF when integrating.
	### Basically this should be handled correctly by the generic
	### optional parameter code but didn't work right for Felix at the
	### time. Lets hope this is fixed now. --Sampo
	#elsif ($_[$i] eq 'PDC_MultiPartMessage') { my $tmp_mpm = splice @_,$i,2, undef,undef;
	#					    $pdc_multipartmessage = pack("CCCC",
	#                                                                        0x11, 0x05, 0x00, 0x04)
        #                                                 . $tmp_mpm
	#					       unless (length ($tmp_mpm) != 4);
	#				       }

    }

    ### Apply defaults for those mandatory arguments that were not specified

    $message_class = ${*$me}{message_class} if !defined $message_class;
    $source_addr_ton = ${*$me}{source_addr_ton} if !defined $source_addr_ton;
    $source_addr_npi = ${*$me}{source_addr_npi} if !defined $source_addr_npi;
    $source_addr = ${*$me}{source_addr} if !defined $source_addr;

    croak "Must supply destination_addr to submit_sm v4" if !@destination_addr;
    
    $messaging_mode = ${*$me}{messaging_mode} if !defined $messaging_mode;
    $msg_reference = ${*$me}{msg_reference} if !defined $msg_reference;
    $telematic_interworking = ${*$me}{telematic_interworking} if !defined $telematic_interworking;
    $priority_level = ${*$me}{priority_level} if !defined $priority_level;
    $schedule_delivery_time = ${*$me}{schedule_delivery_time} if !defined $schedule_delivery_time;
    $validity_period = ${*$me}{validity_period} if !defined $validity_period;
    $registered_delivery_mode = ${*$me}{registered_delivery_mode} if !defined $registered_delivery_mode;
    $data_coding = ${*$me}{data_coding} if !defined $data_coding;
    $sm_default_msg_id = ${*$me}{sm_default_msg_id} if !defined $sm_default_msg_id;
    $short_message = '' if !defined $short_message;

    ### destination address encoding is pretty messy with variable
    ### number of variable length records.

    for (my $i = 0; $i <= $#destination_addr; $i++) {
	my $ton = !defined($dest_addr_ton[$i]) ? ${*$me}{dest_addr_ton} : $dest_addr_ton[$i];
	my $npi = !defined($dest_addr_npi[$i]) ? ${*$me}{dest_addr_npi} : $dest_addr_npi[$i];
	$addr_data .= pack 'CCZ*', $ton, $npi, $destination_addr[$i];
    }

    return pack('nCCZ*N',
		$message_class, $source_addr_ton, $source_addr_npi, $source_addr,
		scalar(@destination_addr)) . $addr_data
		    . pack('CZ*CCZ*nCCCna*',
			   $messaging_mode, $msg_reference, $telematic_interworking,
			   $priority_level, $schedule_delivery_time, $validity_period,
			   $registered_delivery_mode, $data_coding,
			   $sm_default_msg_id, length($short_message), $short_message, )
    # . $pdc_multipartmessage  # *** Felix
    ;
}

### v4 submit_sm response encoding and decoding is equal to submit_multi_resp v3.4
#4#end

sub submit_sm {
    my $me = $_[0];
    return $me->req_backend(CMD_submit_sm,                            #4
			    (${*$me}{smpp_version} == 0x40)           #4
	                    ? &encode_submit_v4 : &encode_submit_v34, #4
	                    @_);                                      #4
    return $me->req_backend(CMD_submit_sm, &encode_submit_v34, @_);
}

#4#cut
### deliver_sm_v4 (v4 6.4.5.1), p.38
### N.B v34 deliver is decoded as v34 submit

sub decode_deliver_sm_v4 {
    my $pdu = shift;
    my $len = decode_source_and_destination($pdu, $pdu->{data});
    
    ### *** WARNING: if this section of code bombs you should
    ###     check carefully that Z9 and Z17 are working correctly.
    ###     Although the spec says that these are fixed length, one
    ###     should not blindly take this for granted. If fixed length
    ###     interpreatation is chosen then the $len has to be updated
    ###     by the fixed length irrespective of what the C string
    ###     length is. If however the variable length interpretation
    ###     is chosen then Z* should be used to decode and C string
    ###     length should be used to update the length. Using Z9 to
    ###     decode but C string length to update $len is inconsistent
    ###     although I believe it amounts to the variable length
    ###     interpretation in the end. --Sampo
    
    ($pdu->{msg_reference}) = unpack 'Z9', substr($pdu->{data}, $len);   # Felix: its always fixed len
    $len += 9;
    #($pdu->{msg_reference}) = unpack 'Z*', substr($pdu->{data}, $len);
    #$len += length($pdu->{msg_reference}) + 1;

    ($pdu->{message_class},     # 8  n
     $pdu->{telematic_interworking},  # 9  C
     $pdu->{priority_level},          # 10 C
     $pdu->{submit_time_stamp}) = unpack 'nCCZ17', substr($pdu->{data}, $len);  # Felix: fixed len
    $len += 2 + 1 + 1 + 17;
    # $pdu->{submit_time_stamp}) = unpack 'nCCZ*', substr($pdu->{data}, $len);
    #$len += 2 + 1 + 1 + length($pdu->{submit_time_stamp}) + 1;

    my $sm_length;
    ($pdu->{data_coding},       # 15 C
     $sm_length,                # 17 n
     ) = unpack 'Cn', substr($pdu->{data}, $len);
    $len += 1 + 2;
    ($pdu->{short_message}
     ) = unpack "a$sm_length", substr($pdu->{data}, $len);
    $len += $sm_length;

    $pdu->{esm_class} = $pdu->{message_class};
    $pdu->{protocol_id} = $pdu->{telematic_interworking};
    $pdu->{priority_flag} = $pdu->{priority_level};
    $pdu->{schedule_delivery_time} = $pdu->{submit_time_stamp};
    
    return $len;
}

sub encode_deliver_sm_v4 {
    my $me = $_[0];
    my ($source_addr_ton, $source_addr_npi, $source_addr,
	$dest_addr_ton, $dest_addr_npi, $destination_addr,
	$msg_reference, $message_class, $telematic_interworking, $priority_level,
	$schedule_delivery_time, $data_coding, $short_message);

    ### Extract mandatory parameters from argument stream
    
    for (my $i=1; $i <= $#_; $i+=2) {
	next if !defined $_[$i];
	if ($_[$i] eq 'source_addr_ton')  { $source_addr_ton = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'source_addr_npi')  { $source_addr_npi = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'source_addr')      { $source_addr = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'dest_addr_ton')    { $dest_addr_ton = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'dest_addr_npi')    { $dest_addr_npi = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'destination_addr') { $destination_addr = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'msg_reference')    { $msg_reference = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'message_class')    { $message_class = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'esm_class')        { $message_class = splice @_,$i,2,undef,undef; }  # v34
	elsif ($_[$i] eq 'telematic_interworking')   { $telematic_interworking = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'protocol_id')    { $telematic_interworking = splice @_,$i,2,undef,undef; } # v34
	elsif ($_[$i] eq 'priority_level') { $priority_level = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'priority_flag')  { $priority_level = splice @_,$i,2,undef,undef; } # v34
	elsif ($_[$i] eq 'schedule_delivery_time') { $schedule_delivery_time = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'data_coding')    { $data_coding = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'short_message')  { $short_message = splice @_,$i,2,undef,undef; }
    }

    ### Apply defaults for those mandatory arguments that were not specified
    
    $source_addr_ton = ${*$me}{source_addr_ton} if !defined $source_addr_ton;
    $source_addr_npi = ${*$me}{source_addr_npi} if !defined $source_addr_npi;
    $source_addr = ${*$me}{source_addr} if !defined $source_addr;
    $dest_addr_ton = ${*$me}{dest_addr_ton} if !defined $dest_addr_ton;
    $dest_addr_npi = ${*$me}{dest_addr_npi} if !defined $dest_addr_npi;
    die "Must supply destination_addr to deliver_sm v4" if !defined $destination_addr;
    $msg_reference = ${*$me}{msg_reference} if !defined $msg_reference;
    $message_class = ${*$me}{message_class} if !defined $message_class;
    $telematic_interworking = ${*$me}{telematic_interworking} if !defined $telematic_interworking;
    $priority_level = ${*$me}{priority_level} if !defined $priority_level;
    $schedule_delivery_time = ${*$me}{schedule_delivery_time} if !defined $schedule_delivery_time;
    $data_coding = ${*$me}{data_coding} if !defined $data_coding;
    $short_message = '' if !defined $short_message;
    
    return pack('CCZ*CCZ*Z*nCCZ*Cna*',
		$source_addr_ton, $source_addr_npi, $source_addr,
		$dest_addr_ton, $dest_addr_npi, $destination_addr,
		$msg_reference, $message_class, $telematic_interworking, $priority_level,
		$schedule_delivery_time, $data_coding, length($short_message),$short_message, );
}
#4#end

sub deliver_sm {
    my $me = $_[0];
    # N.B. deliver_sm v34 == submit_sm v34
    return $me->req_backend(CMD_deliver_sm,                             #4
			    (${*$me}{smpp_version} == 0x40)             #4
			    ? &encode_deliver_sm_v4 : &encode_submit_v34,  #4
			    @_);                                        #4
    return $me->req_backend(CMD_deliver_sm, &encode_submit_v34, @_);
}

###

sub decode_submit_resp_v34 {
    my $pdu = shift;
    ($pdu->{message_id}) = unpack 'Z*', $pdu->{data};
    return length($pdu->{message_id}) + 1;
}

sub encode_submit_resp_v34 {
    my $me = $_[0];
    my ($message_id);

    for (my $i=1; $i <= $#_; $i+=2) {
	next if !defined $_[$i];
	if ($_[$i] eq 'message_id') { $message_id = splice @_,$i,2,undef,undef; }
    }
    warn "message_id=$message_id" if $trace;
    croak "message_id must be supplied" if !defined $message_id;
    return pack('Z*', $message_id);
}

sub submit_sm_resp {
    my $me = $_[0];

    # N.B. submit_sm_resp v4 == submit_multi_resp v34   #4
    #      data_sm_resp v34 == submit_sm_resp v34
    return $me->resp_backend(CMD_submit_sm_resp,              #4
			     (${*$me}{smpp_version} == 0x40)  #4
				 ? &encode_submit_sm_resp_v4  #4
				 : &encode_submit_resp_v34,   #4
				 @_);                         #4
    return $me->resp_backend(CMD_submit_sm_resp, &encode_submit_resp_v34, @_);
}
sub data_sm_resp    { $_[0]->resp_backend(CMD_data_sm_resp, &encode_submit_resp_v34, @_) } # pubAPI

sub deliver_sm_resp {  # public API
    my $me = $_[0];
    # N.B. submit_sm_resp v34 == deliver_sm_resp v34
    return $me->resp_backend(CMD_deliver_sm_resp,                                #4
			     (${*$me}{smpp_version} == 0x40)                     #4
			     ? ''  # v4 deliver_resp is empty v4 6.4.5.2, p.40   #4
			     : &encode_submit_resp_v34,                          #4
			     @_);                                                #4
    return $me->resp_backend(CMD_deliver_sm_resp, &encode_submit_resp_v34, @_);
}

### submit_multi (4.5.1), p.59

sub decode_submit_multi {
    my $pdu = shift;
    ($pdu->{service_type}) = unpack 'Z*', $pdu->{data};
    my $len = length($pdu->{service_type}) + 1;

    $len += decode_source_addr($pdu, substr($pdu->{data}, $len));

    ($pdu->{number_of_dests}) = unpack 'C', substr($pdu->{data}, $len);
    $len += 1;

    ### To make life difficult, the multi destination addresses
    ### are a hotch potch of variable length, variable type
    ### records. Only way to do it is to walk the list.

    for (my $i = 0; $i < $pdu->{number_of_dests}; $i++) {
	($pdu->{dest_flag}[$i]) = unpack 'C', substr($pdu->{data}, $len++);
	if ($pdu->{dest_flag}[$i] == MULTIDESTFLAG_SME_Address) {
	    ($pdu->{dest_addr_ton}[$i],
	     $pdu->{dest_addr_npi}[$i],
	     $pdu->{destination_addr}[$i])
		= unpack 'CCZ*', substr($pdu->{data}, $len);
	    $len += 1 + 1 + length($pdu->{destination_addr}[$i]) + 1;
	} elsif ($pdu->{dest_flag}[$i] == MULTIDESTFLAG_dist_list) {
	    $pdu->{dest_addr_ton}[$i] = 0;
	    $pdu->{dest_addr_npi}[$i] = 0;
	    ($pdu->{destination_addr}[$i])
		= unpack 'Z*', substr($pdu->{data}, $len);
	    $len += length($pdu->{destination_addr}[$i]) + 1;
	} else {
	    warn "Unknown multidest flag: $pdu->{dest_flag} (4.5.1.1, p. 75)";
	}
    }

    ### Now that we skipped over the variable length destinations
    ### we are ready to decode the rest of the packet.

    ($pdu->{esm_class},         # 8
     $pdu->{protocol_id},       # 9
     $pdu->{priority_flag},     # 10
     $pdu->{schedule_delivery_time}) = unpack 'CCCZ*', substr($pdu->{data}, $len);
    $len += 1 + 1 + 1 + length($pdu->{schedule_delivery_time}) + 1;
    
    ($pdu->{validity_period}) = unpack 'Z*', substr($pdu->{data}, $len);
    $len += length($pdu->{validity_period}) + 1;

    my $sm_length;
    ($pdu->{registered_delivery}, # 13
     $pdu->{replace_if_present_flag}, # 14
     $pdu->{data_coding},       # 15
     $pdu->{sm_default_msg_id}, # 16
     $sm_length,                # 17
#                  1
#                8901234567 8
     ) = unpack 'CCCCC', substr($pdu->{data}, $len);
    $len += 1 + 1 + 1 + 1 + 1;
    ($pdu->{short_message}      # 18
     ) = unpack "a$sm_length", substr($pdu->{data}, $len);
    
    return $len + $sm_length;
}

sub encode_submit_multi {
    my $me = $_[0];
    my ($service_type, $source_addr_ton, $source_addr_npi, $source_addr,
	@dest_flag, @dest_addr_ton, @dest_addr_npi, @destination_addr,
	$esm_class, $protocol_id, $priority_flag,
	$schedule_delivery_time, $validity_period,
	$registered_delivery, $replace_if_present_flag, $data_coding,
	$sm_default_msg_id, $short_message, $addr_data);

    ### Extract mandatory parameters from argument stream
    
    for (my $i=1; $i <= $#_; $i+=2) {
	next if !defined $_[$i];
	if ($_[$i] eq 'service_type') { $service_type = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'source_addr_ton') { $source_addr_ton = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'source_addr_npi') { $source_addr_npi = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'source_addr')     { $source_addr = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'dest_flag')       {
	    @dest_flag = ref($_[$i+1]) ? @{scalar(splice @_,$i,2,undef,undef)}
	                               : (scalar(splice @_,$i,2,undef,undef));
	}
	elsif ($_[$i] eq 'dest_addr_ton')   {
	    @dest_addr_ton = ref($_[$i+1]) ? @{scalar(splice @_,$i,2,undef,undef)}
	                                   : (scalar(splice @_,$i,2,undef,undef));
	}
	elsif ($_[$i] eq 'dest_addr_npi')   {
	    @dest_addr_npi = ref($_[$i+1]) ? @{scalar(splice @_,$i,2,undef,undef)}
	                                   : (scalar(splice @_,$i,2,undef,undef));
	}
	elsif ($_[$i] eq 'destination_addr') {
	    @destination_addr = ref($_[$i+1]) ? @{scalar(splice @_,$i,2,undef,undef)}
	                                      : (scalar(splice @_,$i,2,undef,undef));
	}
	elsif ($_[$i] eq 'esm_class')     { $esm_class = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'protocol_id')   { $protocol_id = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'priority_flag') { $priority_flag = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'schedule_delivery_time') { $schedule_delivery_time = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'validity_period') { $validity_period = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'registered_delivery') { $registered_delivery = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'replace_if_present_flag') { $replace_if_present_flag = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'data_coding') { $data_coding = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'sm_default_msg_id') { $sm_default_msg_id = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'short_message') { $short_message = splice @_,$i,2,undef,undef; }
    }

    ### Apply defaults for those mandatory arguments that were not specified
    
    $service_type = ${*$me}{service_type} if !defined $service_type;
    $source_addr_ton = ${*$me}{source_addr_ton} if !defined $source_addr_ton;
    $source_addr_npi = ${*$me}{source_addr_npi} if !defined $source_addr_npi;
    $source_addr = ${*$me}{source_addr} if !defined $source_addr;
    croak "Must supply destination_addr to submit_multi" if !@destination_addr;
    $esm_class = ${*$me}{esm_class} if !defined $esm_class;
    $protocol_id = ${*$me}{protocol_id} if !defined $protocol_id;
    $priority_flag = ${*$me}{priority_flag} if !defined $priority_flag;
    $schedule_delivery_time = ${*$me}{schedule_delivery_time} if !defined $schedule_delivery_time;
    $validity_period = ${*$me}{validity_period} if !defined $validity_period;
    $registered_delivery = ${*$me}{registered_delivery} if !defined $registered_delivery;
    $replace_if_present_flag = ${*$me}{replace_if_present_flag} if !defined $replace_if_present_flag;
    $data_coding = ${*$me}{data_coding} if !defined $data_coding;
    $sm_default_msg_id = ${*$me}{sm_default_msg_id} if !defined $sm_default_msg_id;
    $short_message = '' if !defined $short_message;

    ### destination address encoding is pretty messy with variable
    ### number of variable length variable type records.

    for (my $i = 0; $i <= $#destination_addr; $i++) {
	if (!defined($dest_flag[$i])
	    || $dest_flag[$i] == MULTIDESTFLAG_SME_Address) {
	    my $ton = !defined($dest_addr_ton[$i]) ? ${*$me}{dest_addr_ton} : $dest_addr_ton[$i];
	    my $npi = !defined($dest_addr_npi[$i]) ? ${*$me}{dest_addr_npi} : $dest_addr_npi[$i];
	    $addr_data .= pack 'CCCZ*', MULTIDESTFLAG_SME_Address, $ton, $npi, $destination_addr[$i];
	} elsif ($dest_flag[$i] == MULTIDESTFLAG_dist_list) {
	    $addr_data .= pack 'CZ*', MULTIDESTFLAG_dist_list, $destination_addr[$i];
	} else {
	    warn "Unknown dest_flag: $dest_flag[$i] (4.5.1, p. 70)";
	}
    }

    return pack('Z*CCZ*C',
		$service_type, $source_addr_ton, $source_addr_npi, $source_addr,
		scalar(@destination_addr)) . $addr_data
		    . pack('CCCZ*Z*CCCCCa*',
			   $esm_class, $protocol_id, $priority_flag,
			   $schedule_delivery_time, $validity_period,
			   $registered_delivery, $replace_if_present_flag, $data_coding,
			   $sm_default_msg_id, length($short_message), $short_message, );
}

sub submit_multi { $_[0]->req_backend(CMD_submit_multi, &encode_submit_multi, @_) } # public API

#4#cut

sub decode_submit_sm_resp_v4 {
    my $pdu = shift;
    ($pdu->{message_id}) = unpack 'Z*', $pdu->{data};
    my $len = length($pdu->{message_id}) + 1;
    ($pdu->{no_unsuccess}) = unpack 'n', substr($pdu->{data}, $len);
    $pdu->{num_unsuccess} = $pdu->{no_unsuccess};  # Compat
    $len += 2;

    ### process the unsuccess_sme(s) field into meaningful arrays
    
    for (my $i = 0; $i < $pdu->{no_unsuccess}; $i++) {
	($pdu->{dest_addr_ton}[$i], $pdu->{dest_addr_npi}[$i],
	 $pdu->{destination_addr}[$i]) = unpack 'CCZ*', substr($pdu->{data}, $len);
	$len += 1 + 1 + length($pdu->{destination_addr}[$i]) + 1;
	($pdu->{error_status_code}[$i]) = unpack 'N', substr($pdu->{data}, $len);
	$len += 4;
    }
    
    return $len;
}
#4#end

sub decode_submit_multi_resp {
    my $pdu = shift;
    ($pdu->{message_id}) = unpack 'Z*', $pdu->{data};
    my $len = length($pdu->{message_id}) + 1;
    ($pdu->{no_unsuccess}) = unpack 'C', substr($pdu->{data}, $len);
    $pdu->{num_unsuccess} = $pdu->{no_unsuccess};  # Compat
    $len += 1;

    ### process the unsuccess_sme(s) field into meaningful arrays

    for (my $i = 0; $i < $pdu->{no_unsuccess}; $i++) {
	($pdu->{dest_addr_ton}[$i], $pdu->{dest_addr_npi}[$i],
	 $pdu->{destination_addr}[$i]) = unpack 'CCZ*', substr($pdu->{data}, $len);
	$len += 1 + 1 + length($pdu->{destination_addr}[$i]) + 1;
	($pdu->{error_status_code}[$i]) = unpack 'N', substr($pdu->{data}, $len);
	$len += 4;
    }
    
    return $len;
}

sub encode_submit_multi_resp {
    my $me = $_[0];
    my ($message_id, @dest_addr_ton, @dest_addr_npi, @destination_addr,
	@error_status_code, $addr_data);

    for (my $i=1; $i <= $#_; $i+=2) {
	next if !defined $_[$i];
	if ($_[$i] eq 'message_id') { $message_id = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'dest_addr_ton')   {
	    @dest_addr_ton = ref($_[$i+1]) ? @{scalar(splice @_,$i,2,undef,undef)}
	                                   : (scalar(splice @_,$i,2,undef,undef));
	}
	elsif ($_[$i] eq 'dest_addr_npi')   {
	    @dest_addr_npi = ref($_[$i+1]) ? @{scalar(splice @_,$i,2,undef,undef)}
	                                   : (scalar(splice @_,$i,2,undef,undef));
	}
	elsif ($_[$i] eq 'destination_addr') {
	    @destination_addr = ref($_[$i+1]) ? @{scalar(splice @_,$i,2,undef,undef)}
	                                      : (scalar(splice @_,$i,2,undef,undef));
	}
	elsif ($_[$i] eq 'error_status_code') {
	    @error_status_code = ref($_[$i+1]) ? @{scalar(splice @_,$i,2,undef,undef)}
	                                       : (scalar(splice @_,$i,2,undef,undef));
	}
    }

    croak "message_id must be supplied" if !defined $message_id;
    #croak "destination_addr must be supplied" if !@destination_addr;
    croak "error_status_code must be supplied" if !@error_status_code;

    for (my $i = 0; $i <= $#destination_addr; $i++) {
	my $ton = !defined($dest_addr_ton[$i]) ? ${*$me}{dest_addr_ton} : $dest_addr_ton[$i];
	my $npi = !defined($dest_addr_npi[$i]) ? ${*$me}{dest_addr_npi} : $dest_addr_npi[$i];
	$addr_data .= pack 'CCZ*N', $ton, $npi, $destination_addr[$i], $error_status_code[$i];
    }
    
    return pack('Z*C', $message_id, scalar(@destination_addr)) . $addr_data;
}

#4#cut
sub encode_submit_sm_resp_v4 {
    my $me = $_[0];
    my ($message_id, @dest_addr_ton, @dest_addr_npi, @destination_addr,
	@error_status_code);
    my $addr_data = '';  # May be empty if all addresses were successful
    
    for (my $i=1; $i <= $#_; $i+=2) {
	next if !defined $_[$i];
	if ($_[$i] eq 'message_id') { $message_id = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'sc_msg_reference') { $message_id = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'dest_addr_ton')   {
	    @dest_addr_ton = ref($_[$i+1]) ? @{scalar(splice @_,$i,2,undef,undef)}
	                                   : (scalar(splice @_,$i,2,undef,undef));
	}
	elsif ($_[$i] eq 'dest_addr_npi')   {
	    @dest_addr_npi = ref($_[$i+1]) ? @{scalar(splice @_,$i,2,undef,undef)}
	                                   : (scalar(splice @_,$i,2,undef,undef));
	}
	elsif ($_[$i] eq 'destination_addr') {
	    @destination_addr = ref($_[$i+1]) ? @{scalar(splice @_,$i,2,undef,undef)}
	                                      : (scalar(splice @_,$i,2,undef,undef));
	}
	elsif ($_[$i] eq 'error_status_code') {
	    @error_status_code = ref($_[$i+1]) ? @{scalar(splice @_,$i,2,undef,undef)}
	                                       : (scalar(splice @_,$i,2,undef,undef));
	}
    }

    croak "message_id must be supplied" if !defined $message_id;
    #croak "destination_addr must be supplied" if !@destination_addr;
    croak "error_status_code must be supplied" if !@error_status_code;

    for (my $i = 0; $i <= $#destination_addr; $i++) {
	my $ton = !defined($dest_addr_ton[$i]) ? ${*$me}{dest_addr_ton} : $dest_addr_ton[$i];
	my $npi = !defined($dest_addr_npi[$i]) ? ${*$me}{dest_addr_npi} : $dest_addr_npi[$i];
	$addr_data .= pack 'CCZ*N', $ton, $npi, $destination_addr[$i], $error_status_code[$i];
    }
    
    return pack('Z*n', $message_id, scalar(@destination_addr)) . $addr_data;
}
#4#end

sub submit_multi_resp { $_[0]->resp_backend(CMD_submit_multi_resp, &encode_submit_multi_resp, @_) }

### query (4.8.1), p.95

sub decode_query_v34 {
    my $pdu = shift;
    ($pdu->{message_id}) = unpack 'Z*', $pdu->{data};
    my $len = length($pdu->{message_id}) + 1;
    $len += decode_source_addr($pdu, substr($pdu->{data}, $len));
    return $len;
}

#4#cut
sub decode_query_v4 {
    my $pdu = shift;
    ($pdu->{message_id}) = unpack 'Z*', $pdu->{data};
    my $len = length($pdu->{message_id}) + 1;
    $len += decode_source_and_destination($pdu, substr($pdu->{data}, $len));
    return $len;
}
#4#end

sub encode_query_sm_v34 {
    my $me = $_[0];
    my ($message_id, $source_addr_ton, $source_addr_npi, $source_addr);

    ### Extract mandatory parameters from argument stream
    
    for (my $i=1; $i <= $#_; $i+=2) {
	next if !defined $_[$i];
	if ($_[$i] eq 'message_id') { $message_id = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'source_addr_ton')  { $source_addr_ton = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'source_addr_npi')  { $source_addr_npi = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'source_addr') { $source_addr = splice @_,$i,2,undef,undef; }
    }

    ### Apply defaults for those mandatory arguments that were not specified
    
    croak "Must supply message_id to query_sm" if !defined $message_id;
    $source_addr_ton = ${*$me}{source_addr_ton} if !defined $source_addr_ton;
    $source_addr_npi = ${*$me}{source_addr_npi} if !defined $source_addr_npi;
    $source_addr = ${*$me}{source_addr} if !defined $source_addr;

    return pack('Z*CCZ*', $message_id, $source_addr_ton, $source_addr_npi, $source_addr);
}

#4#cut
sub encode_query_sm_v4 {
    my $me = $_[0];
    my ($message_id, $source_addr_ton, $source_addr_npi, $source_addr,
	$dest_addr_ton, $dest_addr_npi, $destination_addr);

    ### Extract mandatory parameters from argument stream
    
    for (my $i=1; $i <= $#_; $i+=2) {
	next if !defined $_[$i];
	if ($_[$i] eq 'message_id') { $message_id = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'source_addr_ton')  { $source_addr_ton = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'source_addr_npi')  { $source_addr_npi = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'source_addr') { $source_addr = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'dest_addr_ton')  { $dest_addr_ton = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'dest_addr_npi')  { $dest_addr_npi = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'destination_addr') { $destination_addr = splice @_,$i,2,undef,undef; }
    }

    ### Apply defaults for those mandatory arguments that were not specified
    
    croak "Must supply message_id to query_sm" if !defined $message_id;

    $source_addr_ton = ${*$me}{source_addr_ton} if !defined $source_addr_ton;
    $source_addr_npi = ${*$me}{source_addr_npi} if !defined $source_addr_npi;
    $source_addr = ${*$me}{source_addr} if !defined $source_addr;

    $dest_addr_ton = ${*$me}{dest_addr_ton} if !defined $dest_addr_ton;
    $dest_addr_npi = ${*$me}{dest_addr_npi} if !defined $dest_addr_npi;
    $destination_addr = ${*$me}{destination_addr} if !defined $destination_addr;

    return pack('Z*CCZ*CCZ*',
		$message_id, $source_addr_ton, $source_addr_npi, $source_addr,
		$dest_addr_ton, $dest_addr_npi, $destination_addr);
}
#4#end

sub query_sm {
    my $me = $_[0];
    return $me->req_backend(CMD_query_sm, ${*$me}{smpp_version} == 0x40  #4
	? &encode_query_sm_v4 : &encode_query_sm_v34, @_);               #4
    return $me->req_backend(CMD_query_sm, &encode_query_sm_v34, @_);
}

sub decode_query_resp_v34 {
    my $pdu = shift;
    ($pdu->{message_id}) = unpack 'Z*', $pdu->{data};
    my $len = length($pdu->{message_id}) + 1;

    ($pdu->{final_date}) = unpack 'Z*', substr($pdu->{data}, $len);
    $len += length($pdu->{final_date}) + 1;

    ($pdu->{message_state}, $pdu->{error_code}) = unpack 'CC', substr($pdu->{data}, $len);
    return $len + 1 + 1;
}

#4#cut
sub decode_query_resp_v4 {
    my $pdu = shift;
    ($pdu->{sc_msg_reference}) = unpack 'Z*', $pdu->{data};
    my $len = length($pdu->{sc_msg_reference}) + 1;

    ($pdu->{final_date}) = unpack 'Z*', substr($pdu->{data}, $len);
    $len += length($pdu->{final_date}) + 1;

    ($pdu->{message_status}, $pdu->{network_error_code}) = unpack 'CN', substr($pdu->{data}, $len);
    
    $pdu->{message_id} = $pdu->{sc_msg_reference};   # v34 compat
    $pdu->{message_state} = $pdu->{message_status};  # v34 compat
    $pdu->{error_code} = $pdu->{network_error_code}; # v34 compat
    return $len + 1 + 4;
}
#4#end

sub encode_query_sm_resp_v34 {
    my $me = $_[0];
    my ($message_id, $final_date, $message_state, $error_code);
    $message_id = '2';

    for (my $i=1; $i < $#_; $i+=2) {
	next if !defined $_[$i];
	if ($_[$i] eq 'message_id')       { $message_id    = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'final_date')    { $final_date    = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'message_state') { $message_state = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'error_code')    { $error_code    = splice @_,$i,2,undef,undef; }
    }
    
    croak "message_id must be supplied" if !defined $message_id;
    $final_date = ${*$me}{final_date} if !defined $final_date;
    croak "message_state must be supplied" if !defined $message_state;
    $error_code = ${*$me}{error_code} if !defined $error_code;
    return pack('Z*Z*CC', $message_id, $final_date, $message_state, $error_code);
}

#4#cut
sub encode_query_sm_resp_v4 {
    my $me = $_[0];
    my ($sc_msg_reference, $final_date, $message_status, $network_error_code);
    
    for (my $i=1; $i <= $#_; $i+=2) {
	next if !defined $_[$i];
	if ($_[$i] eq 'sc_msg_reference')     { $sc_msg_reference = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'message_id')        { $sc_msg_reference = splice @_,$i,2,undef,undef; } # v34
	elsif ($_[$i] eq 'final_date')        { $final_date = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'message_status')    { $message_status = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'message_state')     { $message_status = splice @_,$i,2,undef,undef; } # v34
	elsif ($_[$i] eq 'networkerror_code') { $network_error_code = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'error_code')        { $network_error_code = splice @_,$i,2,undef,undef; } # v34
    }
    
    croak "sc_msg_reference or message_id must be supplied" if !defined $sc_msg_reference;
    $final_date = ${*$me}{final_date} if !defined $final_date;
    croak "message_status or message_state must be supplied" if !defined $message_status;
    $network_error_code = ${*$me}{network_error_code} if !defined $network_error_code;
    return pack('Z*Z*CN', $sc_msg_reference, $final_date, $message_status, $network_error_code);
}
#4#end

sub query_sm_resp {
    my $me = $_[0];
    return $me->resp_backend(CMD_query_sm_resp, ${*$me}{smpp_version} == 0x40    #4
    ? &encode_query_sm_resp_v4 : &encode_query_sm_resp_v34, @_);      #4
    return $me->resp_backend(CMD_query_sm_resp, &encode_query_sm_resp_v34, @_);
}

### alert_notification (4.12.1), p.108

sub decode_alert_notification {
    my $pdu = shift;
    my $len = decode_source_addr($pdu, $pdu->{data});
    
    ($pdu->{esme_addr_ton},     # 4
     $pdu->{esme_addr_npi},     # 5
     $pdu->{esme_addr}) = unpack 'CCZ*', substr($pdu->{data}, $len);
    
    return $len + 1 + 1 + length($pdu->{esme_addr}) + 1;
}

sub encode_alert_notification {
    my $me = $_[0];
    my ($source_addr_ton, $source_addr_npi, $source_addr,
	$esme_addr_ton, $esme_addr_npi, $esme_addr);

    ### Extract mandatory parameters from argument stream
    
    for (my $i=1; $i <= $#_; $i+=2) {
	next if !defined $_[$i];
	if ($_[$i] eq 'source_addr_ton')  { $source_addr_ton = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'source_addr_npi')  { $source_addr_npi = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'source_addr')      { $source_addr = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'esme_addr_ton')  { $esme_addr_ton = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'esme_addr_npi')  { $esme_addr_npi = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'esme_addr')      { $esme_addr = splice @_,$i,2,undef,undef; }
    }

    ### Apply defaults for those mandatory arguments that were not specified
    
    $source_addr_ton = ${*$me}{source_addr_ton} if !defined $source_addr_ton;
    $source_addr_npi = ${*$me}{source_addr_npi} if !defined $source_addr_npi;
    $source_addr = ${*$me}{source_addr}     if !defined $source_addr;
    $esme_addr_ton = ${*$me}{esme_addr_ton} if !defined $esme_addr_ton;
    $esme_addr_npi = ${*$me}{esme_addr_npi} if !defined $esme_addr_npi;
    croak "Must supply esme_addr to alert_notification" if !defined $esme_addr;

    return pack('CCZ*CCZ*',
		$source_addr_ton, $source_addr_npi, $source_addr,
		$esme_addr_ton, $esme_addr_npi, $esme_addr, );
}

sub alert_notification { $_[0]->req_backend(CMD_alert_notification,
					    &encode_alert_notification, @_) }

### replace (4.10.1), p.102

sub decode_replace_sm_v34 {
    my $pdu = shift;
    ($pdu->{message_id}) = unpack 'Z*', $pdu->{data};
    my $len = length($pdu->{message_id}) + 1;
    $len += decode_source_addr($pdu, substr($pdu->{data}, $len));

    ($pdu->{schedule_delivery_time}) = unpack 'Z*', substr($pdu->{data}, $len);
    $len += length($pdu->{schedule_delivery_time}) + 1;

    ($pdu->{validity_period}) = unpack 'Z*', substr($pdu->{data}, $len);
    $len += length($pdu->{validity_period}) + 1;

    my $sm_length;
    ($pdu->{registered_delivery}, # 7
     $pdu->{sm_default_msg_id}, # 8
     $sm_length,                # 9
#                123456789 0
     ) = unpack 'CCC', substr($pdu->{data}, $len);
    $len += 1 + 1 + 1;
    ($pdu->{short_message}      # 10
     ) = unpack "a$sm_length", substr($pdu->{data}, $len);
    
    return $len + $sm_length;
}

#4#cut
sub decode_replace_sm_v4 {
    my $pdu = shift;
    ($pdu->{msg_reference}) = unpack 'Z*', $pdu->{data};
    my $len = length($pdu->{msg_reference}) + 1;    
    $len += decode_source_and_destination($pdu, substr($pdu->{data}, $len));
    
    ($pdu->{schedule_delivery_time}, # Z
     ) = unpack 'Z*', substr($pdu->{data}, $len);
    $len += length($pdu->{schedule_delivery_time}) + 1;

    my $sm_length;
    ($pdu->{validity_period},   # 6    n
     $pdu->{registered_delivery_mode}, # C
     $pdu->{data_coding},       # 8  C
     $pdu->{sm_default_msg_id}, # 8  C
     $sm_length,                # 9  n
     ) = unpack 'nCCCn', substr($pdu->{data}, $len);
    $len += 2 + 1 + 1 + 1 + 2;
    ($pdu->{short_message}      # 10 a
     ) = unpack "a$sm_length", substr($pdu->{data}, $len);
    
    $pdu->{message_id} = $pdu->{msg_reference}; # v34 compat
    $pdu->{registered_delivery} = $pdu->{registered_delivery_mode}; # v34 compat
    
    return $len + $sm_length;
}
#4#end

sub encode_replace_sm_v34 {
    my $me = $_[0];
    my ($message_id, $source_addr_ton, $source_addr_npi, $source_addr,
	$schedule_delivery_time, $validity_period,
	$registered_delivery, $sm_default_msg_id, $short_message);

    ### Extract mandatory parameters from argument stream
    
    for (my $i=1; $i <= $#_; $i+=2) {
	next if !defined $_[$i];
	if ($_[$i] eq 'message_id') { $message_id = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'source_addr_ton')  { $source_addr_ton = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'source_addr_npi')  { $source_addr_npi = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'source_addr') { $source_addr = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'schedule_delivery_time') { $schedule_delivery_time = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'validity_period') { $validity_period = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'registered_delivery') { $registered_delivery = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'sm_default_msg_id') { $sm_default_msg_id = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'short_message') { $short_message = splice @_,$i,2,undef,undef; }
    }

    ### Apply defaults for those mandatory arguments that were not specified
    
    croak "Must supply message_id to replace_sm" if !defined $message_id;
    $source_addr_ton = ${*$me}{source_addr_ton} if !defined $source_addr_ton;
    $source_addr_npi = ${*$me}{source_addr_npi} if !defined $source_addr_npi;
    $source_addr = ${*$me}{source_addr} if !defined $source_addr;
    $schedule_delivery_time = ${*$me}{schedule_delivery_time} if !defined $schedule_delivery_time;
    $validity_period = ${*$me}{validity_period} if !defined $validity_period;
    $registered_delivery = ${*$me}{registered_delivery} if !defined $registered_delivery;
    $sm_default_msg_id = ${*$me}{sm_default_msg_id} if !defined $sm_default_msg_id;
    $short_message = ${*$me}{short_message} if !defined $short_message;

    return pack('Z*CCZ*Z*Z*CCCa*',
		$message_id, $source_addr_ton, $source_addr_npi, $source_addr,
		$schedule_delivery_time, $validity_period,
		$registered_delivery, $sm_default_msg_id, length($short_message), $short_message, );
}

#4#cut
sub encode_replace_sm_v4 {
    my $me = $_[0];
    my ($msg_reference, $source_addr_ton, $source_addr_npi, $source_addr,
	$dest_addr_ton, $dest_addr_npi, $destination_addr,
	$schedule_delivery_time, $validity_period,
	$registered_delivery_mode, $data_coding, $sm_default_msg_id, $short_message);

    ### Extract mandatory parameters from argument stream
    
    for (my $i=1; $i <= $#_; $i+=2) {
	next if !defined $_[$i];
	if ($_[$i] eq 'msg_reference') { $msg_reference = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'message_id') { $msg_reference = splice @_,$i,2,undef,undef; } # v34
	elsif ($_[$i] eq 'source_addr_ton')  { $source_addr_ton = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'source_addr_npi')  { $source_addr_npi = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'source_addr') { $source_addr = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'dest_addr_ton')  { $dest_addr_ton = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'dest_addr_npi')  { $dest_addr_npi = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'destination_addr') { $destination_addr = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'schedule_delivery_time') { $schedule_delivery_time = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'validity_period') { $validity_period = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'registered_delivery_mode') { $registered_delivery_mode = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'registered_delivery') { $registered_delivery_mode = splice @_,$i,2,undef,undef; } # v34
	elsif ($_[$i] eq 'data_coding') { $data_coding = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'sm_default_msg_id') { $sm_default_msg_id = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'short_message') { $short_message = splice @_,$i,2,undef,undef; }
    }

    ### Apply defaults for those mandatory arguments that were not specified
    
    croak "Must supply msg_reference or message_id to replace_sm" if !defined $msg_reference;
    $source_addr_ton = ${*$me}{source_addr_ton} if !defined $source_addr_ton;
    $source_addr_npi = ${*$me}{source_addr_npi} if !defined $source_addr_npi;
    $source_addr = ${*$me}{source_addr} if !defined $source_addr;
    $dest_addr_ton = ${*$me}{dest_addr_ton} if !defined $dest_addr_ton;
    $dest_addr_npi = ${*$me}{dest_addr_npi} if !defined $dest_addr_npi;
    $destination_addr = ${*$me}{destination_addr} if !defined $destination_addr;
    $schedule_delivery_time = ${*$me}{schedule_delivery_time} if !defined $schedule_delivery_time;
    $validity_period = ${*$me}{validity_period} if !defined $validity_period;
    $registered_delivery_mode = ${*$me}{registered_delivery_mode} if !defined $registered_delivery_mode;
    $data_coding = ${*$me}{data_coding} if !defined $data_coding;
    $sm_default_msg_id = ${*$me}{sm_default_msg_id} if !defined $sm_default_msg_id;
    $short_message = ${*$me}{short_message} if !defined $short_message;

    return pack('Z*CCZ*CCZ*Z*nCCCna*',
		$msg_reference, $source_addr_ton, $source_addr_npi, $source_addr,
		$dest_addr_ton, $dest_addr_npi, $destination_addr,
		$schedule_delivery_time, $validity_period,
		$registered_delivery_mode, $data_coding, $sm_default_msg_id, length($short_message), $short_message, );
}
#4#end

sub replace_sm {
    my $me = $_[0];
    return $me->req_backend(CMD_replace_sm, ${*$me}{smpp_version} == 0x40                 #4
				? &encode_replace_sm_v4 : &encode_replace_sm_v34,  #4
				@_);                                               #4
    return $me->req_backend(CMD_replace_sm, &encode_replace_sm_v34, @_);
}

### cancel (4.9.1), p.98

sub decode_cancel {
    my $pdu = shift;
    my $me = shift;
    my $len = 0;
    if (${*$me}{smpp_version}==0x40) {                       #4
        ($pdu->{service_type}) = unpack 'n', $pdu->{data};   #4
        $len += 2;                                           #4
    } else {                                                 #4
        ($pdu->{service_type}) = unpack 'Z*', $pdu->{data};
        $len += length($pdu->{service_type}) + 1;
    }                                                        #4
    ($pdu->{message_id}) = unpack 'Z*', substr($pdu->{data}, $len);
    $len += length($pdu->{message_id}) + 1;

    $len += decode_source_and_destination($pdu, substr($pdu->{data}, $len));

    $pdu->{message_class} = $pdu->{service_type};  # v4      #4
    return $len;
}

sub encode_cancel_sm {
    my $me = $_[0];
    my ($service_type, $message_id, $source_addr_ton, $source_addr_npi, $source_addr,
	$dest_addr_ton, $dest_addr_npi, $destination_addr);

    ### Extract mandatory parameters from argument stream
    
    for (my $i=1; $i <= $#_; $i+=2) {
	next if !defined $_[$i];
	if ($_[$i] eq 'service_type') { $service_type = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'message_class') { $service_type = splice @_,$i,2,undef,undef; }  # v4  #4
	elsif ($_[$i] eq 'message_id') { $message_id = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'source_addr_ton')  { $source_addr_ton = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'source_addr_npi')  { $source_addr_npi = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'source_addr') { $source_addr = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'dest_addr_ton')  { $dest_addr_ton = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'dest_addr_npi')  { $dest_addr_npi = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'destination_addr') { $destination_addr = splice @_,$i,2,undef,undef; }
    }

    ### Apply defaults for those mandatory arguments that were not specified
    
    $service_type = ${*$me}{service_type} if !defined $service_type;
    $message_id = ${*$me}{message_id} if !defined $message_id;
    $source_addr_ton = ${*$me}{source_addr_ton} if !defined $source_addr_ton;
    $source_addr_npi = ${*$me}{source_addr_npi} if !defined $source_addr_npi;
    $source_addr = ${*$me}{source_addr} if !defined $source_addr;
    $dest_addr_ton = ${*$me}{dest_addr_ton} if !defined $dest_addr_ton;
    $dest_addr_npi = ${*$me}{dest_addr_npi} if !defined $dest_addr_npi;
    $destination_addr = ${*$me}{destination_addr} if !defined $destination_addr;

    return pack(${*$me}{smpp_version}==0x40 ? 'nZ*CCZ*CCZ*' : 'Z*Z*CCZ*CCZ*',  #4
		$service_type, $message_id,                                    #4
		$source_addr_ton, $source_addr_npi, $source_addr,              #4
		$dest_addr_ton, $dest_addr_npi, $destination_addr, );          #4
    return pack('Z*Z*CCZ*CCZ*',
		$service_type, $message_id,
		$source_addr_ton, $source_addr_npi, $source_addr,
		$dest_addr_ton, $dest_addr_npi, $destination_addr, );
}

sub cancel_sm { $_[0]->req_backend(CMD_cancel_sm, &encode_cancel_sm, @_) }  # public API

### data_sm (4.7.1), p.87

sub decode_data_sm {
    my $pdu = shift;
    
    ($pdu->{service_type}) = unpack 'Z*', $pdu->{data};
    my $len = length($pdu->{service_type}) + 1;
    
    $len += decode_source_and_destination($pdu, substr($pdu->{data}, $len));

    ($pdu->{esm_class},         # 8
     $pdu->{registered_delivery}, # 9
     $pdu->{data_coding},       # 10
#                890
     ) = unpack 'CCC', substr($pdu->{data}, $len);
    
    return $len + 1 + 1 + 1;
}

sub encode_data_sm {
    my $me = $_[0];
    my ($service_type, $source_addr_ton, $source_addr_npi, $source_addr,
	$dest_addr_ton, $dest_addr_npi, $destination_addr,
	$esm_class, $registered_delivery, $data_coding);

    ### Extract mandatory parameters from argument stream
    
    for (my $i=1; $i <= $#_; $i+=2) {
	next if !defined $_[$i];
	if ($_[$i] eq 'service_type') { $service_type = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'source_addr_ton')  { $source_addr_ton = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'source_addr_npi')  { $source_addr_npi = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'source_addr') { $source_addr = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'dest_addr_ton')  { $dest_addr_ton = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'dest_addr_npi')  { $dest_addr_npi = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'destination_addr') { $destination_addr = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'esm_class') { $esm_class = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'registered_delivery') { $registered_delivery = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'data_coding') { $data_coding = splice @_,$i,2,undef,undef; }
    }

    ### Apply defaults for those mandatory arguments that were not specified
    
    $service_type = ${*$me}{service_type} if !defined $service_type;
    $source_addr_ton = ${*$me}{source_addr_ton} if !defined $source_addr_ton;
    $source_addr_npi = ${*$me}{source_addr_npi} if !defined $source_addr_npi;
    $source_addr = ${*$me}{source_addr} if !defined $source_addr;
    $dest_addr_ton = ${*$me}{dest_addr_ton} if !defined $dest_addr_ton;
    $dest_addr_npi = ${*$me}{dest_addr_npi} if !defined $dest_addr_npi;

    croak "Must supply destination_addr to data_sm" if !defined $destination_addr;

    $esm_class = ${*$me}{esm_class} if !defined $esm_class;
    $registered_delivery = ${*$me}{registered_delivery} if !defined $registered_delivery;
    $data_coding = ${*$me}{data_coding} if !defined $data_coding;

    return pack('Z*CCZ*CCZ*CCC',
		$service_type, $source_addr_ton, $source_addr_npi, $source_addr,
		$dest_addr_ton, $dest_addr_npi, $destination_addr,
		$esm_class, $registered_delivery, $data_coding, );
}

sub data_sm { $_[0]->req_backend(CMD_data_sm, &encode_data_sm, @_) }

#4#cut
### delivery_receipt: v4 6.4.6.1, p.41

sub decode_delivery_receipt {
    my $pdu = shift;
    my $len = decode_source_and_destination($pdu, $pdu->{data});

    ($pdu->{msg_reference}) = unpack 'Z*', substr($pdu->{data}, $len);
    $len += length($pdu->{msg_reference}) + 1;

    ($pdu->{num_msgs_submitted}, # 9  N
     $pdu->{num_msgs_delivered}, # 10 N
     $pdu->{submit_date},        # 11 Z
     ) = unpack 'NNZ*', substr($pdu->{data}, $len);
    $len += 4 + 4 + length($pdu->{submit_date}) + 1;

    ($pdu->{done_date}) = unpack 'Z*', substr($pdu->{data}, $len);
    $len += length($pdu->{done_date}) + 1;
    
    my $sm_length;
    ($pdu->{message_state},      # 13 N
     $pdu->{network_error_code}, # 14 N
     $pdu->{data_coding},        # 15 C
     $sm_length,                 # 16 n
#                234567890123456 7
     ) = unpack 'NNCn', substr($pdu->{data}, $len);
    $len += 4 + 4 + 1 + 2;
    ($pdu->{short_message},      # 17 a    
     ) = unpack "a$sm_length", substr($pdu->{data}, $len);
    return $len + $sm_length;
}

sub encode_delivery_receipt {
    my $me = $_[0];
    my ($source_addr_ton, $source_addr_npi, $source_addr,
	$dest_addr_ton, $dest_addr_npi, $destination_addr,
	$msg_reference, $num_msgs_submitted, $num_msgs_delivered,
	$submit_date, $done_date, $message_state, $network_error_code,
	$data_coding, $short_message);

    ### Extract mandatory parameters from argument stream
    
    for (my $i=1; $i <= $#_; $i+=2) {
	next if !defined $_[$i];
	if ($_[$i] eq 'source_addr_ton')  { $source_addr_ton = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'source_addr_npi')  { $source_addr_npi = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'source_addr') { $source_addr = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'dest_addr_ton')  { $dest_addr_ton = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'dest_addr_npi')  { $dest_addr_npi = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'destination_addr') { $destination_addr = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'msg_reference') { $msg_reference = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'num_msgs_submitted') { $num_msgs_submitted = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'num_msgs_delivered') { $num_msgs_delivered = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'submit_date') { $submit_date = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'done_date') { $done_date = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'message_state') { $message_state = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'network_error_code') { $network_error_code = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'data_coding') { $data_coding = splice @_,$i,2,undef,undef; }
	elsif ($_[$i] eq 'short_message') { $short_message = splice @_,$i,2,undef,undef; }
    }

    ### Apply defaults for those mandatory arguments that were not specified
    
    $source_addr_ton = ${*$me}{source_addr_ton} if !defined $source_addr_ton;
    $source_addr_npi = ${*$me}{source_addr_npi} if !defined $source_addr_npi;
    $source_addr = ${*$me}{source_addr} if !defined $source_addr;
    $dest_addr_ton = ${*$me}{dest_addr_ton} if !defined $dest_addr_ton;
    $dest_addr_npi = ${*$me}{dest_addr_npi} if !defined $dest_addr_npi;
    
    croak "Must supply destination_addr to delivery_receipt" if !defined $destination_addr;

    $msg_reference = ${*$me}{msg_reference} if !defined $msg_reference;
    $num_msgs_submitted = ${*$me}{num_msgs_submitted} if !defined $num_msgs_submitted;
    $num_msgs_delivered = ${*$me}{num_msgs_delivered} if !defined $num_msgs_delivered;
    $submit_date = ${*$me}{submit_date} if !defined $submit_date;
    $done_date = ${*$me}{done_date} if !defined $done_date;
    $message_state = ${*$me}{message_state} if !defined $message_state;
    $network_error_code = ${*$me}{network_error_code} if !defined $network_error_code;
    $data_coding = ${*$me}{data_coding} if !defined $data_coding;
    $short_message = ${*$me}{short_message} if !defined $short_message;

    return pack('CCZ*CCZ*Z*NNZ*Z*NNCna*',
		$source_addr_ton, $source_addr_npi, $source_addr,
		$dest_addr_ton, $dest_addr_npi, $destination_addr,
		$msg_reference, $num_msgs_submitted, $num_msgs_delivered,
		$submit_date, $done_date, $message_state,
		$network_error_code, $data_coding, length($short_message), $short_message);
}

sub delivery_receipt { $_[0]->req_backend(CMD_delivery_receipt, &encode_delivery_receipt, @_) }
#4#end

###

sub set_version {
    my $me = shift;
    my $version = shift;

    if ($version == 0x40) {                  #4
	${*$me}{smpp_version} = 0x40;        #4
	${*$me}{head_templ} = 'NNNNxxxx';    #4
	${*$me}{head_len} = 20;              #4
	${*$me}{cmd_version} = 0x00010000;   #4
    } else {                                 #4
	${*$me}{smpp_version} = $version;
	${*$me}{head_templ} = 'NNNN';
	${*$me}{head_len} = 16;
	${*$me}{cmd_version} = 0x00000000;
    }                                        #4
}

### Accept a new server child, i.e. accepted socket. This
### constructor gets called internally just after accept system
### call when listening socket does accept. See also "new_listen"
### which gets called when socket is created and put listening.
### DO NOT USE THIS CONSTRUCTOR FOR CLIENT SIDE CONNECTIONS.
###
### The way this code works is that somewhere deep in guts of
### IO::Socket module the constructor name is hardwired to
### "new" and there is no way to pass any arguments to this
### constructor, hence I have to copy the arguments from
### the parent when constructing. Let's hope this aspect
### of IO::Socket does not change.

sub new {
    my $accept = shift;
    my $type = ref($accept) || $accept;
    my $me = gensym;
    for my $k (keys %{*$accept}) {
	${*$me}{$k} = ${*$accept}{$k};
    }
    return bless $me, $type;
}

### Create client connection (do not use "new")

sub new_connect {
    my $me = shift;
    my $type = ref($me) || $me;
    my $host = shift if @_ % 2;  # host need not be tagged
    my %arg = @_;

    my $s = $type->SUPER::new(
         PeerAddr  => $host,
	 PeerPort  => exists $arg{port} ? $arg{port} : Default->{port},
	 LocalAddr => exists $arg{local_ip} ? $arg{local_ip} : Default->{local_ip},
	 Proto     => 'tcp',
	 Timeout   => exists $arg{timeout} ? $arg{timeout} : Default->{timeout},
			      @_)  # pass any extra args to constructor
	or return undef;
    
    for my $a (keys %{&Default}) {
	${*$s}{$a} = exists $arg{$a} ? $arg{$a} : Default->{$a};
    }
    $s->set_version(${*$s}{smpp_version});
    #warn Dumper $s;
    
    $s->autoflush(1);
    #$s->debug(exists $arg{debug} ? $arg{debug} : undef);
    return $s;
}

sub new_transceiver {
    my $type = shift;
    my $me = $type->new_connect(@_);
    return undef if !defined $me;
    warn "Connected, sending bind: ".Dumper($me) if $trace;
    my $resp = $me->bind_transceiver();
    warn "Bound: ".Dumper($resp) if $trace;
    return ($me, $resp) if wantarray;
    return $me;
}

sub new_transmitter {
    my $type = shift;
    my $me = $type->new_connect(@_);
    return undef if !defined $me;
    warn "Connected, sending bind: ".Dumper($me) if $trace;
    my $resp = $me->bind_transmitter();
    warn "Bound: ".Dumper($resp) if $trace;
    return ($me, $resp) if wantarray;
    return $me;
}

sub new_receiver {
    my $type = shift;
    my $me = $type->new_connect(@_);
    return undef if !defined $me;
    warn "Connected, sending bind: ".Dumper($me) if $trace;
    my $resp = $me->bind_receiver();
    warn "Bound: ".Dumper($resp) if $trace;
    return ($me, $resp) if wantarray;
    return $me;
}

### Create new server connection, i.e. listening socket. See
### also "new" which gets called when connection is accepted
### from the listening socket.

sub new_listen {
    my $me = shift;
    my $type = ref($me) || $me;
    my $host = shift if @_ % 2;  # host need not be tagged
    my %arg = @_;

    my $s = $type->SUPER::new(
      LocalAddr => $host,
      LocalPort => exists $arg{port} ? $arg{port} : Default->{port},
      Proto    => 'tcp',
      ReuseAddr => 'true',
      Listen   => exists $arg{listen} ? $arg{listen} : Default->{listen},
      Timeout  => exists $arg{timeout} ? $arg{timeout} : Default->{timeout})
	or return undef;
    for my $a (keys %{&Default}) {
	${*$s}{$a} = exists $arg{$a} ? $arg{$a} : Default->{$a};
    }
    $s->set_version(${*$s}{smpp_version});
    $s->sockopt(SO_REUSEADDR => 1);
    $s->autoflush(1);
    #$s->debug(exists $arg{debug} ? $arg{debug} : undef);
    return $s;
}

### This table drives the decoding process

use constant pdu_tab => {
    0x80000000 => { cmd => 'generic_nack', decode => \&decode_empty, }, # i
    0x00000001 => { cmd => 'bind_receiver', decode => \&decode_bind, }, # i
    0x80000001 => { cmd => 'bind_receiver_resp', decode => \&decode_bind_resp_v34, }, # i
    0x00000002 => { cmd => 'bind_transmitter', decode => \&decode_bind, },        # i
    0x80000002 => { cmd => 'bind_transmitter_resp', decode => \&decode_bind_resp_v34, }, # i
    0x00000003 => { cmd => 'query_sm', decode => \&decode_query_v34, },               # i
    0x80000003 => { cmd => 'query_sm_resp', decode => \&decode_query_resp_v34, },     # i
    0x00000004 => { cmd => 'submit_sm', decode => \&decode_submit_v34, },             # i
    0x80000004 => { cmd => 'submit_sm_resp', decode => \&decode_submit_resp_v34, },   # i
    0x00000005 => { cmd => 'deliver_sm', decode => \&decode_submit_v34, },            # i
    0x80000005 => { cmd => 'deliver_sm_resp', decode => \&decode_submit_resp_v34, },  # i
    0x00000006 => { cmd => 'unbind', decode => \&decode_empty, },       # i
    0x80000006 => { cmd => 'unbind_resp', decode => \&decode_empty, },  # i
    0x00000007 => { cmd => 'replace_sm', decode => \&decode_replace_sm_v34, }, # i
    0x80000007 => { cmd => 'replace_sm_resp', decode => \&decode_empty, }, # i
    0x00000008 => { cmd => 'cancel_sm', decode => \&decode_cancel, },      # i
    0x80000008 => { cmd => 'cancel_sm_resp', decode => \&decode_empty, },  # i
    0x00000009 => { cmd => 'bind_transceiver', decode => \&decode_bind, }, # i
    0x80000009 => { cmd => 'bind_transceiver_resp', decode => \&decode_bind_resp_v34, }, # i
    0x0000000b => { cmd => 'outbind', decode => \&decode_outbind_v34, },         # i
    0x00000015 => { cmd => 'enquire_link', decode => \&decode_empty, },      # i
    0x80000015 => { cmd => 'enquire_link_resp', decode => \&decode_empty, }, # i
    0x00000021 => { cmd => 'submit_multi', decode => \&decode_submit_multi, }, # i
    0x80000021 => { cmd => 'submit_multi_resp', decode => \&decode_submit_multi_resp, }, # i
    0x00000102 => { cmd => 'alert_notification', decode => \&decode_alert_notification, }, # i
    0x00000103 => { cmd => 'data_sm', decode => \&decode_data_sm, },          # i
    0x80000103 => { cmd => 'data_sm_resp', decode => \&decode_submit_resp_v34, }, # i

#4#cut
    # v4 codes

    0x80010000 => { cmd => 'generic_nack_v4', decode => \&decode_empty, }, # i
    0x00010001 => { cmd => 'bind_receiver_v4', decode => \&decode_bind, }, # i
    0x80010001 => { cmd => 'bind_receiver_resp_v4', decode => \&decode_bind_resp_v4, }, # i
    0x00010002 => { cmd => 'bind_transmitter_v4', decode => \&decode_bind, },        # i
    0x80010002 => { cmd => 'bind_transmitter_resp_v4', decode => \&decode_bind_resp_v4, }, # i
    0x00010003 => { cmd => 'query_sm_v4', decode => \&decode_query_v4, },               # i
    0x80010003 => { cmd => 'query_sm_resp_v4', decode => \&decode_query_resp_v4, },     # i
    0x00010004 => { cmd => 'submit_sm_v4', decode => \&decode_submit_v4, },             # i
    0x80010004 => { cmd => 'submit_sm_resp_v4', decode => \&decode_submit_sm_resp_v4, },   # i
    0x00010005 => { cmd => 'deliver_sm_v4', decode => \&decode_deliver_sm_v4, },            # i
    0x80010005 => { cmd => 'deliver_sm_resp_v4', decode => \&decode_empty, },  # i
    0x00010006 => { cmd => 'unbind_v4', decode => \&decode_empty, },       # i
    0x80010006 => { cmd => 'unbind_resp_v4', decode => \&decode_empty, },  # i
    0x00010007 => { cmd => 'replace_sm_v4', decode => \&decode_replace_sm_v4, }, # i
    0x80010007 => { cmd => 'replace_sm_resp_v4', decode => \&decode_empty, }, # i
    0x00010008 => { cmd => 'cancel_sm_v4', decode => \&decode_cancel, },      # i
    0x80010008 => { cmd => 'cancel_sm_resp_v4', decode => \&decode_empty, },  # i
    0x00010009 => { cmd => 'delivery_receipt_v4', decode => \&decode_delivery_receipt, }, # ***
    0x80010009 => { cmd => 'delivery_receipt_resp_v4', decode => \&decode_empty, },  # i
    0x0001000a => { cmd => 'enquire_link_v4', decode => \&decode_empty, },      # i  v4
    0x8001000a => { cmd => 'enquire_link_resp_v4', decode => \&decode_empty, }, # i  v4
    0x0001000b => { cmd => 'outbind_v4', decode => \&decode_outbind_v4, },         # i
#4#end
};

package Net::SMPP::PDU;

sub message_id {
    my $me = shift;
    return $me->{message_id};
}

sub status {
    my $me = shift;
    return $me->{status};
    #return ${$me}{status};
    #return ${*$me}{status};
}

sub seq {
    my $me = shift;
    return $me->{seq};
}

sub explain_status {
    my $me = shift;
    return sprintf("%s (%s=0x%08X)",
		   Net::SMPP::status_code->{$me->{status}}->{msg},
		   Net::SMPP::status_code->{$me->{status}}->{code},
		   $me->{status});
}

sub cmd {
    my $me = shift;
    return $me->{cmd};
}

sub explain_cmd {
    my $me = shift;
    my $cmd = Net::SMPP::pdu_tab->{$me->{cmd}}
    || { cmd => sprintf(q{Unknown(0x%08X)}, $me->{cmd}) };
    return $cmd->{cmd};
}

package Net::SMPP;

### Try real hard to read something, i.e. block until the thing has
### been entirely read.

sub read_hard {
    my ($me, $len, $dr, $offset) = @_;
    while (length($$dr) < $len+$offset) {
	my $n = length($$dr) - $offset;
	eval {
	    local $SIG{ALRM} = sub { die "alarm\n" }; # NB: \n required
	    alarm ${*$me}{enquire_interval} if ${*$me}{enquire_interval};
	    warn "read $n/$len enqint(${*$me}{enquire_interval})" if $trace>1;
	    while (1) {
		$n = $me->sysread($$dr, $len-$n, $n+$offset);
		next if $! =~ /^Interrupted/;
		last;
	    }
	    alarm 0;
	};
	if ($@) {
	    warn "ENQUIRE $@" if $trace;
	    die unless $@ eq "alarm\n";   # propagate unexpected errors
	    $me->enquire_link();   # Send a periodic ping
	} else {
	    if (!defined($n)) {
		warn "error reading header from socket: $!";
		${*$me}{smpperror} = "read_hard I/O error: $!";
		${*$me}{smpperrorcode} = 1;
		return undef;
	    }
	    if (!$n) {
		warn "premature eof reading from socket";
		${*$me}{smpperror} = "read_hard premature eof";
		${*$me}{smpperrorcode} = 2;
		return undef;
	    }
	}
    }
    #warn "read complete";
    return 1;
}

### read pdu from wire and decode it, if PDU is understood

sub read_pdu {
    my $me = shift;
    my $header = '';
    my $len;
    my $head_len = ${*$me}{head_len};
    $me->read_hard($head_len, \$header, 0) or return undef;
    my $pdu = { cmd => 0, status => 0, seq => 0, data => '', };
    ($len,
     $pdu->{cmd},
     $pdu->{status},
     $pdu->{seq},
     $pdu->{reserved}) = unpack ${*$me}{head_templ}, $header;
    if ($len < $head_len) {
	warn "Too short length $len < ${*$me}{head_len}, cmd=$pdu->{cmd}, status=$pdu->{status}, seq=$pdu->{seq}";
        ${*$me}{smpperror} = "read_pdu: Too short length $len < ${*$me}{head_len}, cmd=$pdu->{cmd}, status=$pdu->{status}, seq=$pdu->{seq}";
        ${*$me}{smpperrorcode} = 3;
	return undef;
    }
    warn "read Header:\n".hexdump($header, "\t") if $trace;
    
    $len -= $head_len;
    $me->read_hard($len, \$pdu->{data}, 0) or do {
        ${*$me}{smpperror} = "read_pdu: invalid length cmd=$pdu->{cmd},status=$pdu->{status}, seq=$pdu->{seq}";
        ${*$me}{smpperrorcode} = 3;
        return undef;
    };
    warn "read Body:\n".hexdump($pdu->{data}, "\t") if $trace;
    
    ### Check if we know this PDU and decode it
    
    if (defined pdu_tab->{$pdu->{cmd}}) {
	$pdu->{known_pdu} = 1;
	my $pdu_templ = pdu_tab->{$pdu->{cmd}};
	my $mandat_len = &{$pdu_templ->{decode}}($pdu, $me);
	decode_optional_params($pdu, $mandat_len) if $mandat_len < $len;
    }

    return bless $pdu => 'Net::SMPP::PDU';
}

sub wait_pdu {
    my ($me, $look_for_me, $seq) = @_;
    while (1) {
	my $pdu = $me->read_pdu() || return undef;
	return $pdu if $pdu->{cmd} == $look_for_me && $pdu->{seq} == $seq;

	### Check if PDU has a handlers (e.g. its enquire_link)

	if (exists ${*$me}{handlers}->{$pdu->{cmd}}) {
	    &{${*$me}{handlers}->{$pdu->{cmd}}}($me, $pdu);
	}
	
	### *** effectively all other PDUs get ignored
	warn "looking for $look_for_me seq=$seq, skipping cmd=$pdu->{cmd} seq=$pdu->{seq}" if $trace;
    }
}

### Send a response to enquire_link

sub handle_enquire_link {
    my ($me, $pdu) = @_;
    $me->enquire_link_resp(seq => $pdu->{seq});
}

### GSM often uses 7bit encoding to squeeze 160 7bit characters
### in 140 octets. This encoding is not automatically done by
### this module, but following routines allow one to do it
### manually.
###
### In general we can fit 8 7bit characters in 7 octets.
###
### Packing method:
###
### BIT:  76543210 76543210 76543210 76543210 76543210 76543210 76543210
### BYTE: 0        1        2        3        4        5        6
### CHAR: BAAAAAAA CCBBBBBB DDDCCCCC EEEEDDDD FFFFFEEE GGGGGGFF HHHHHHHG
###
### So as can be seen, the characters are encoded lowest bit to lowest
### available bit position, just wrapping around. Another possiblity
### would be as follows
###
### BIT:  76543210 76543210 76543210 76543210 76543210 76543210 76543210
### BYTE: 0        1        2        3        4        5        6
### CHAR: HAAAAAAA HBBBBBBB HCCCCCCC HDDDDDDD HEEEEEEE HFFFFFFF HGGGGGGG
###
### In this scheme the last character is distributed over the high bits
### of the other bytes. while bytes A-G would just be normal.
###
### These routines still have some issues in handling the padding. Especially
### unpack_7bit may leave some artifacts in the end.

sub pack_7bit {
    my ($s) = @_;
    $s = unpack 'b*', $s;
    $s =~ s/(.{7})./$1/g;    # Zap the high order (8th) bits
    return pack 'b*', $s;
}

sub unpack_7bit {
    my ($s) = @_;
    $s = unpack 'b*', $s;
    $s =~ s/(.{7})/${1}0/g;  # Stuff in high order (8th) bits
    $s = pack 'b*', $s;
    chop $s if substr($s, -1, 1) eq "\x00";
    return $s;
#    return pack 'b*', $s;
}

# "Gema niskazhu" <gemochka@gmail.com>

1;
__END__

=head1 NAME

Net::SMPP - pure Perl implementation of SMPP 3.4 over TCP

=head1 SYNOPSIS

  use Net::SMPP;
  $smpp = Net::SMPP->new_transceiver($host, port=>$port,
			system_id => 'yourusername',
			password  => 'secret',
			) or die;

=head1 DESCRIPTION

Implements Short Message Peer to Peer protocol, which is frequently used to
pass short messages between mobile operators implementing short message
service (SMS). This is applicable to both european GSM and american CDMA/TDMA
systems.

This documentation is not intended to be complete reference to SMPP
protocol - use the SMPP specification documents (see references
section) to obtain exact operation and parameter names and their
meaning. You may also need to obtain site specific documentation about
the remote end and any protocol extensions that it supports or demands
before you start a project. This document follows the convention of
spelling parameter names exactly as they appear in the SMPP v3.4
documentation. SMPP v4.0 support also follows the respective
documentation, except where v4.0 usage is in conflict with v3.4 usage,
in which case the latter prevails (in practise I believe no such
conflicts remain in the madule at present). For a complete list of error
code and optional parameter enumerations, the reader is encouraged to
consult the source code or SMPP speciofications.

Despite its name, SMPP protocol defines a client (ESME) and a server
(often called SMSC in the mobile operator world). Client usually
initiates the TCP connection and does I<bind> to log in. After
binding, a series of request response pairs, called PDUs (protocol
data units) is exchanged. Request can be initiated by either end
(hence "peer-to-peer"?) and the other end reponds. Requests are
numbered with a sequence number and each response has corresponding
sequence number. This allows several requests to be pending at the
same time. Conceptually this is similar to IMAP or LDAP message IDs.
Usually the $smpp object maintains the sequence numbers by itself and
the programmer need not concern himself with their exact values, but
should a need to override them arise, the seq argument can be supplied
to any request or response method.

Normally this module operates in synchronous mode, meaning that a
method that sends a request will also block until it gets the
corresponding response. Internal command used for waiting for response is

    $resp_pdu = $smpp->wait_pdu($cmd_id, $seq);

If, while waiting for a particular response, other PDUs are received
they are either handled by handlers (set up by constructor) or
discarded. Both command code and sequence number must match. Typically
a handler for enquire command is set up while all other commands are
silently dropped. This practise may not be very suitable for
transceiver mode of operation and certainly is not suitable for
implementing a SMSC.

Synchronous operation makes it impossible to interleave SMPP
operations, thus it should be regarded as a simplified programming
model for simple tasks. Anyone requiring more advanced control has to
use the asynchronous mode and take up the burden of understanding and
implementing more of the message flow logic in his own application.

In synchronous mode request PDU methods return a Net::SMPP::PDU object
representing the response, if all went well protocolwise, or undef if
there was a protocol level error. If undef was returned, the reason
for the failure can be extracted from ${*$smpp}{smpperror} and
${*$smpp}{smpperrorcode} (actual codes are undocumented at the moment,
but are guaranteed not to change) variables and the global variable
$!. These variables are meaningless if anything else than undef was
returned. The response itself may be an error response if there was an
application level error in the remote end. In this case the application
level error can be determined from $pdu->{status} field. Some
responses also have optional parameters that further clarify the failure,
see documentation for each operation.

If a protocol level error happens, probably the only safe action is
to destroy the connection object (e.g. undef $smpp). If an application
level error happens, then depending on how the remote end has been
implemented it may be possible to continue operation.

Module can also be used asynchronously by specifying async=>1 to the
constructor. In this mode command methods return immediately with the
sequence number of the PDU and user should poll for any responses
using

    $pdu = $smpp->wait_pdu($cmd_id, $seq);

Typically wait_pdu() is used to wait for a response, but if wait_pdu()
is used to wait for a command, the caller should generate appropriate
response.

If caller wants to receive next available PDU, he can call

    $pdu = $smpp->read_pdu();

which will block until a PDU is received from the stream. The caller would
then have to check if the PDU is a response or a request and take appropriate
action. The smsc.pl example program supplied with this distribution
demonstrates a possible framework for handling both requests and responses.

If the caller does not want to block on wait_pdu() or read_pdu(), he
must use select() to determine if the socket is readable (*** what if
SSL layer gets inserted?). Even if the socket selects for reading,
there may not be enough data to complete the PDU, so the call may
still block. Currently there is no reliable mechanism for avoiding
this. If this bothers you, you may consider allocating a separate
process for each connection so that blocking does not matter, or you
may set up some sort of timeout (see perlipc(1) man page) or you may
rewrite this module and contribute patches.

Response methods always return the sequence number, irrespective
of synchronous or asynchronous mode, or undef if an error happened.

=head1 CONSTRUCTORS

=over 4

=item new()

Do not call. Has special internal meaning during accepting connections
from listening socket.

=item new_connect()

Create a new SMPP client object and open conncetion to SMSC host

    $smpp = Net::SMPP->new_connect($host,
       system_id => 'username',   # usually needed (default '')
       password => 'secret',      # usually needed (default '')
       system_type => '',         # default ok, often not needed
       interface_version => 0x34, # default ok, almost never needed
       addr_ton => 0x00,          # default ok, type of number unknwn
       addr_npi => 0x00,          # default ok, number plan indicator
       address_range => '',       # default ok, regex matching nmbrs
       ) or die;

Usually this constructor is not called directly. Use
new_transceiver(), new_transmitter(), and new_receiver() instead.

=item new_transceiver()

=item new_transmitter()

=item new_receiver()

These constructors first construct the object using new_connect() and
then bind using given type of bind request. See bind family of
methods, below. These constructors are usually used to implement
ESME type functionality.

=item new_listen('localhost', port=>2251)

Create new SMPP server object and open socket to listen on
given port. This constructor is usually used to implement a SMSC.

=back

=head1 REQUEST PDU METHODS

Each request PDU method constructs a PDU from list of arguments supplied
and sends it to the wire.

If async mode has been enabled (by specifying "async=>1" in the constructor
or as an argument to the method), the methods return sequence number of
the PDU just sent. This number can be later used to match up the response,
like this:

    $seq = $smpp->query_sm(message_id => $msg_id) or die;
    ...
    $resp_pdu = $smpp->wait_pdu(Net::SMPP::CMD_query_sm_resp, $seq)
       or die;
    die "Response indicated error: " . $resp_pdu->explain_status()
       if $resp_pdu->status;

If async mode is not enabled (i.e. "async=>1" was not specified
neither in constructor nor the method), the method will wait for the
corresponding response and return Net::SMPP::PDU object representing
that response. The application should check the outcome of the
operation from the status field of the response PDU, like this:

    $resp_pdu = $smpp->query_sm(message_id => $msg_id) or die;
    die "Response indicated error: " . $resp_pdu->explain_status()
       if $resp_pdu->status;

All request PDU methods optionally take "seq=>123" argument that
allows explicit specification of the sequence number. The default is
to increment internally stored sequence number by one and use that.

Most PDUs have mandatory parameters and optional parameters. If
mandatory parameter is not supplied, it is inherited from the smpp
object. This means that the parameter can either be set as an argument
to the constructor or it is inherited from built-in defaults in the
innards of Net::SMPP (see C<Default> table from line 217
onwards). Some mandatory parameters can not be defaulted - if they are
missing a die results. In descriptions below, defaultable mandatory
parameters are show with the default value and comment indicating that
its defaultable.

Optional parameters can be supplied to all PDUs (although the SMPP
spec does not allow optional parameters for some PDUs, the module does
not check for this) by listing them in the order that they should be
appended to the end of the PDU. Optional parameters can not be
defaulted - if the parameter is not supplied, it simply is not
included in the PDU. Optional parameters are not supported
by previous versions of the SMPP protocol (up to and including 3.3).
Applications wishing to be downwards compatible should not make
use of optional parameters.

Standard optional parameters can be supplied by their name (see
C<param_tab> in the Net::SMPP source code, around line 345, for list of
known optional parameters), but the programmer still needs to supply
the value of the parameter in the expected format (one often has to
use pack to construct the value). Consult SMPP specifications for
the correct format.

It is possible to supply arbitrary unsupported optional parameters
by simply supplying the parameter tag as a decimal number. Consult
your site dependent documentation to figure out the correct tags and
to determine the correct format for the value.

When optional parameters are returned in response PDUs, they are
decoded and made available under both numeric tag and symbolic tag, if
known. For example the delivery_failure_reson of data_sm_resp can be
accessed both as $resp->{delivery_failure_reson} and $resp->{1061}.
The application needs to interpret the formatting of optional
parameters itself. The module always assumes they are strings, while
often they actually are interpretted as integers. Consult SMPP
specifications and site dependent documentation for correct format and
use unpack to obtain the numbers.

If an unknown nonnumeric parameter tags are supplied a warning is
issued and parameter is skipped.

In general the Net::SMPP module does not enforce SMPP
specifications. This means that it will happily accept too long or too
short values for manatory or optional parameters. Also the internal
formatting of the parameter values is not checked in any way. The
programmer should consult the SMPP specifications to learn the correct
length and format of each mandatory and optional parameter.

Similarily, if the remote end returns incorrect PDUs and Net::SMPP is
able to parse them (usually because length fields match), then Net::SMPP
will not perform any further checks. This means that some fields
may be longer than allowed for in the specifications.

I opted to leave the checks out at this stage because I needed a flexible
module that allowed me to explore even nonconformant SMSC implementations.
If the lack of sanity checks bothers you, formulate such checks and
submit me a patch. Ideally one could at construction time supply an
argument like "strict=>1" to enable the sanity checks.

=over 4

=item alert_notification() (4.12.1, p.108)

Sent by SMSC to ESME when particular mobile subscriber has become
available. source_addr specifies which mobile subscriber. esme_addr
specifies which esme the message is destined to. Alert notifications
can arise if delivery pending flag had been set
for the subscriber from previous data_sm operation.

There is no response PDU.

    $smpp->alert_notification(
			      source_addr_ton => 0x00, # default ok
			      source_addr_npi => 0x00, # default ok
			      source_addr => '',       # default ok
			      esme_addr_ton => 0x00,   # default ok
			      esme_addr_npi => 0x00,   # default ok
			      esme_addr => $esme_addr, # mandatory
			      ) or die;

=item bind_transceiver() (4.1.5, p.51)

=item bind_transmitter() (4.1.1, p.46)

=item bind_receiver() (4.1.3, p.48)

Bind family of methods is used to authenticate the client (ESME) to
the server (SMSC). Usually bind happens as part of corresponding
constructor C<new_transceiver()>, C<new_transmitter()>, or
C<new_receiver()> so these methods are rarely called directly. These
methods take a plethora of options, which are largely the same as the
options taken by the constructors and can safely be defaulted.

    $smpp->bind_transceiver(
       system_id => 'username',   # usually needed (default '')
       password => 'secret',      # usually needed (default '')
       system_type => '',         # default ok, often not needed
       interface_version => 0x34, # default ok, almost never needed
       addr_ton => 0x00,          # default ok, type of number unkwn
       addr_npi => 0x00,          # default ok, number plan indic.
       address_range => '',       # default ok, regex matching tels
       ) or die;

Typically it would be called like:

    $resp_pdu = $smpp->bind_transceiver(system_id => 'username',
					password => 'secret') or die;
    die "Response indicated error: " . $resp_pdu->explain_status()
       if $resp_pdu->status;

or to inform SMSC that you can handle all Spanish numbers:

    $resp_pdu = $smpp->bind_transceiver(system_id => 'username',
					password => 'secret',
					address_range => '^\+?34')
       or die;
    die "Response indicated error: " . $resp_pdu->explain_status()
       if $resp_pdu->status;

=item cancel_sm() (4.9.1, p.98)

Issued by ESME to cancel one or more short messages. Two principal
modes of operation are:

1. if message_id is supplied, other fields can be left at
defaults. This mode deletes just one message.

2. if message_id is not supplied (or is empty string), then
the other fields must be supplied and all messages matching
the criteria reflected by the other fields are deleted.

    $smpp->cancel_sm(
		     service_type => '',      # default ok
		     message_id => '', # default ok, but often given
		     source_addr_ton => 0x00, # default ok
		     source_addr_npi => 0x00, # default ok
		     source_addr => '',       # default ok
		     dest_addr_ton => 0x00,   # default ok
		     dest_addr_npi => 0x00,   # default ok
		     destination_addr => '',  # default ok
		   ) or die;

For example

   $resp_pdu = $smpp->submit_sm(destination_addr => '+447799658372',
				 short_message => 'test message')
      or die;
   die "Response indicated error: " . $resp_pdu->explain_status()
       if $resp_pdu->status;
   $msg_id = $resp_pdu->{message_id};

   $resp_pdu = $smpp->query_sm(message_id => $msg_id) or die;
   die "Response indicated error: " . $resp_pdu->explain_status()
       if $resp_pdu->status;
   print "Message state is $resp_pdu->{message_state}\n";

   $resp_pdu = $smpp->replace_sm(message_id => $msg_id,
				 short_message => 'another test')
      or die;
   die "Response indicated error: " . $resp_pdu->explain_status()
       if $resp_pdu->status;

   $resp_pdu = $smpp->cancel_sm(message_id => $msg_id) or die;
   die "Response indicated error: " . $resp_pdu->explain_status()
       if $resp_pdu->status;

=item data_sm() (4.7.1, p.87)

Newer alternative to submit_sm and deliver_sm. In addition to that
data_sm can be used to pass special messages such as SMSC Delivery
Receipt, SME Delivery Acknowledgement, SME Manual/User
Acknowledgement, Intermediate notification.

Unlike submit_sm and deliver_sm, the short_message parameter is not
mandatory. Never-the-less, the optional parameter message_payload must
be supplied for things to work correctly.

    $smpp->data_sm(
		   service_type => '',      # default ok
		   source_addr_ton => 0x00, # default ok
		   source_addr_npi => 0x00, # default ok
		   source_addr => '',       # default ok
		   dest_addr_ton => 0x00,   # default ok
		   dest_addr_npi => 0x00,   # default ok
		   destination_addr => $tel,  # mandatory
		   esm_class => 0x00,       # default ok
		   registered_delivery => 0x00, #default ok
		   data_coding => 0x00,     # default ok
		   message_payload => 'test msg', # opt, but needed
		   ) or die;

For example

   $resp_pdu = $smpp->data_sm(destination_addr => '+447799658372',
			      message_payload => 'test message')
      or die;
   die "Response indicated error: " . $resp_pdu->explain_status()
       if $resp_pdu->status;

=item deliver_sm() (4.6.1, p.79)

Issued by SMSC to send message to an ESME. Further more SMSC
can transfer following special messages: 1. SMSC delivery receipt,
2. SME delivery acknowledgement, 3. SME Manual/User Acknowledgement,
4. Intermediate notification. These messages are sent in response
to SMS message whose registered_delivery parameter requested them.

If message data is longer than 254 bytes, the optional parameter
C<message_payload> should be used to store the message and
C<short_message> should be set to empty string. N.B. although protocol
has mechanism for sending fairly large messages, the underlying mobile
network usually does not support very large messages. GSM supports
only up to 160 characters, other systems 128 or even just 100 characters.

    $smpp->deliver_sm(
		   service_type => '',      # default ok
		   source_addr_ton => 0x00, # default ok
		   source_addr_npi => 0x00, # default ok
		   source_addr => '',       # default ok
		   dest_addr_ton => 0x00,   # default ok
		   dest_addr_npi => 0x00,   # default ok
		   destination_addr => $t,  # mandatory
		   esm_class => 0x00,       # default ok
		   protocol_id => 0x00,     # default ok on CDMA,TDMA
		                            #   on GSM value needed
		   priority_flag => 0x00,   # default ok
		   schedule_delivery_time => '', # default ok
		   validity_period => '',        # default ok
		   registered_delivery => 0x00,  # default ok
		   replace_if_present_flag => 0x00, # default ok
		   data_coding => 0x00,     # default ok
		   sm_default_msg_id => 0x00,    # default ok
		   short_message => '',     # default ok, but
		                            #   usually supplied
		   ) or die;

For example

   $resp_pdu = $smpp->deliver_sm(destination_addr => '+447799658372',
				 short_message => 'test message')
      or die;
   die "Response indicated error: " . $resp_pdu->explain_status()
       if $resp_pdu->status;

=item enquire_link() (4.11.1, p.106)

Used by either ESME or SMSC to "ping" the other side. Takes no
parameters.

    $smpp->enquire_link() or die;

=item outbind() (4.1.7, p.54, 2.2.1, p.16)

Used by SMSC to signal ESME to originate a C<bind_receiver> request to
the SMSC. C<system_id> and C<password> authenticate the SMSC to the
ESME.  The C<outbind> is used when SMSC initiates the TCP session and
needs to trigger ESME to perform a C<bind_receiver>. It is not needed
if the ESME initiates the TCP connection (e.g. sec 2.7.1, p.27).

There is not response PDU for C<outbind>, instead the ESME is
expected to issue C<bind_receiver>.

    $smpp->outbind(
		   system_id => '',  # default ok, but usually given
		   password => '',   # default ok, but usually given
		   ) or die;

=item query_sm() (4.8.1, p.95)

Used by ESME to query status of a submitted short message. Both
message_id and source_addr must match (if source_addr was defaulted to
NULL during submit, it must be NULL here, too). See example near
C<cancel_sm>.


    $smpp->query_sm(
		   message_id => $msg_id,   # mandatory
		   source_addr_ton => 0x00, # default ok
		   source_addr_npi => 0x00, # default ok
		   source_addr => '',       # default ok
		   ) or die;


=item replace_sm() (4.10.1, p.102)

Used by ESME to replace a previously submitted short message, provided
it is still pending delivery. Both message_id and source_addr must
match (if source_addr was defaulted to NULL during submit, it must be
NULL here, too). See example near C<cancel_sm>.

    $smpp->replace_sm(
		   message_id => $msg_id,   # mandatory
		   source_addr_ton => 0x00, # default ok
		   source_addr_npi => 0x00, # default ok
		   source_addr => '',       # default ok
		   schedule_delivery_time => '', # default ok
		   validity_period => '',        # default ok
		   registered_delivery => 0x00,  # default ok
		   sm_default_msg_id => 0x00,    # default ok
		   short_message => '',     # default ok, but
		                            #   usually supplied		   
		   ) or die;

=item submit_sm() (4.4.1, p.59)

Used by ESME to submit short message to the SMSC for onward
transmission to the specified short message entity (SME). The
submit_sm does not support the transaction message mode.

If message data is longer than 254 bytes, the optional parameter
C<message_payload> should be used to store the message and
C<short_message> should be set to empty string. N.B. although protocol
has mechanism for sending fairly large messages, the underlying mobile
network usually does not support very large messages. GSM supports
only up to 160 characters.

    $smpp->submit_sm(
		   service_type => '',      # default ok
		   source_addr_ton => 0x00, # default ok
		   source_addr_npi => 0x00, # default ok
		   source_addr => '',       # default ok
		   dest_addr_ton => 0x00,   # default ok
		   dest_addr_npi => 0x00,   # default ok
		   destination_addr => $t,  # mandatory
		   esm_class => 0x00,       # default ok
		   protocol_id => 0x00,     # default ok on CDMA,TDMA
		                            #   on GSM value needed
		   priority_flag => 0x00,   # default ok
		   schedule_delivery_time => '', # default ok
		   validity_period => '',        # default ok
		   registered_delivery => 0x00,  # default ok
		   replace_if_present_flag => 0x00, # default ok
		   data_coding => 0x00,     # default ok
		   sm_default_msg_id => 0x00,    # default ok
		   short_message => '',     # default ok, but
		                            #   usually supplied
		   ) or die;

For example

   $resp_pdu = $smpp->submit_sm(destination_addr => '+447799658372',
				 short_message => 'test message')
      or die;
   die "Response indicated error: " . $resp_pdu->explain_status()
       if $resp_pdu->status;

Or

   $resp_pdu = $smpp->submit_sm(destination_addr => '+447799658372',
				short_message => '',
				message_payload => 'a'x500) or die;
   die "Response indicated error: " . $resp_pdu->explain_status()
       if $resp_pdu->status;

=item submit_multi() (4.5.1, p.69)

Used by ESME to submit short message to the SMSC for onward
transmission to the specified short message entities (SMEs). This
command is especially destined for multiple recepients.

If message data is longer than 254 bytes, the optional parameter
C<message_payload> should be used to store the message and
C<short_message> should be set to empty string. N.B. although protocol
has mechanism for sending fairly large messages, the underlying mobile
network usually does not support very large messages. GSM supports
only up to 160 characters.

    $smpp->submit_multi(
		   service_type => '',      # default ok
		   source_addr_ton => 0x00, # default ok
		   source_addr_npi => 0x00, # default ok
		   source_addr => '',       # default ok
		   dest_flag =>             # default ok
			[ MULTIDESTFLAG_SME_Address,
			  MULTIDESTFLAG_dist_list, ... ],
		   dest_addr_ton =>         # default ok
			[ 0x00, 0x00, ... ],
		   dest_addr_npi =>         # default ok
			[ 0x00, 0x00, ... ],
		   destination_addr =>      # mandatory
			[ $t1, $t2, ... ],
		   esm_class => 0x00,       # default ok
		   protocol_id => 0x00,     # default ok on CDMA,TDMA
		                            #   on GSM value needed
		   priority_flag => 0x00,   # default ok
		   schedule_delivery_time => '', # default ok
		   validity_period => '',        # default ok
		   registered_delivery => 0x00,  # default ok
		   replace_if_present_flag => 0x00, # default ok
		   data_coding => 0x00,     # default ok
		   sm_default_msg_id => 0x00,    # default ok
		   short_message => '',     # default ok, but
		                            #   usually supplied
		   ) or die;

For example

   $resp_pdu = $smpp->submit_multi(destination_addr =>
				   [ '+447799658372', '+447799658373' ],
				   short_message => 'test message')
      or die;
   die "Response indicated error: " . $resp_pdu->explain_status()
       if $resp_pdu->status;

The destinations are specified as an array reference. dest_flag,
dest_addr_ton, and dest_addr_npi must have same cardinality as
destination_addr if they are present. Default for dest_flag
is MULTIDESTFLAG_SME_Address, i.e. normal phone number.

=item unbind() (4.2, p.56)

Used by ESME to unregisters ESME from SMSC. Does not take any
parameters.

    $smpp->unbind() or die;

=back

=head1 RESPONSE PDU METHODS

Response PDU methods are used to indicate outcome of requested
commands. Typically these methods would be used by someone
implementing a server (SMSC).

Response PDUs do not have separate asynchronous behaviour pattern.

=over

=item bind_receiver_resp()

=item bind_transmitter_resp()

=item bind_transceiver_resp()

    $smpp->bind_transceiver_resp(
				 system_id => '', # default ok
				 ) or die;

=item cancel_sm_resp() (4.9.2, p.100)

    $smpp->cancel_sm_resp() or die;

=item data_sm_resp()

    $smpp->data_sm_resp(message_id => $msg_id) or die;

=item deliver_sm_resp()

    $smpp->deliver_sm_resp(message_id => $msg_id) or die;

=item enquire_link_resp() (4.11.2, p.106)

    $smpp->enquire_link_resp() or die;

=item generic_nack() (4.3.1, p.57)

    $smpp->generic_nack() or die;

=item query_sm_resp() (4.6.2, p.96)

    $smpp->query_sm_resp(
			 message_id => $msg_id,   # mandatory
			 final_date => '',        # default ok
			 message_state => $state, # mandatory
			 error_code => 0x00,      # default ok
		   ) or die;

=item replace_sm_resp() (4.10.2, p.104)

    $smpp->replace_sm_resp() or die;

=item submit_sm_resp() (4.4.2, p.67)

    $smpp->submit_sm_resp(message_id => $msg_id) or die;

=item submit_multi_resp() (4.5.2, p.76)

    $smpp->submit_multi_resp(message_id => $msg_id
			     dest_addr_ton => [], # default ok
			     dest_addr_npi => [], # default ok
			     destination_addr => [],  # mandatory
			     error_status_code => [], # mandatory
			     ) or die;

=item unbind_resp() (4.2.2, p.56)

    $smpp->unbind_resp() or die;

=back

=head1 MESSAGE ENCODING AND LENGTH

=over 4

Many SMS technologies have inherent message length limits. For example
GSM specifies length to be 140 bytes. Using 7 bit encoding, this holds
the 160 characters that people are familiar with. Net::SMPP does not
enforce this limit in any way, i.e. if you create too long message,
then it is your problem. You should at application layer make sure
you stay within limits.

Net::SMPP also does not automatically perform the encoding, not even
if you set data_encoding parameter. Application layer is responsible
for performing the encoding and setting the data_encoding parameter
accordingly.

To assist in performing the usual 7 bit encoding, following functions
are provided (but you have to call them explicitly):

=over

=item pack_7bit()

=item unpack_7bit()

Example

   $resp_pdu = $smpp->submit_sm(destination_addr => '+447799658372',
                                data_encoding => 0x00,
				short_message => pack_7bit('test message'))
      or die;

=back

The rationale for leaving encoding and length issues at application
layer is two fold: 1. often the data is just copied through to another
message or protocol, thus we do not really care how it is encoded or
how long it is. Presumably it was valid at origin. 2. This policy
avoids underlying technology dependencies in the module. Often local
deployments have all the manner of hacks that make this area very
difficult to chart. So I leave it to local application developer to
find out what is locally needed.

=back

=head1 OTHER METHODS

=over 4

=item read_pdu()

Reads a PDU from stream and analyzes it into Net::SMPP::PDU
object (if PDU is of known type). Blocks until PDU is available.
If you do not want it to block, do select on the socket to
make sure some data is available (unfortunately some data
may be available, but not enough, so it can still block).

read_pdu() is very useful for implementing main loop of SMSC
where unknown PDUs must be received in random order and
processed.

    $pdu = $smpp->read_pdu() or die;

=item wait_pdu()

Reads PDUs from stream and handles or discards them until matching PDU
is found. Blocks until success. Typically wait_pdu() is used
internally by request methods when operating in synchronous mode.  The
PDUs to handle are specified by C<${*$me}{handlers}->{$command_id}>.
The handlers table is initially populated to handle enquire_link PDUs
automatically, but this can be altered using C<handlers> argument to
constructor.

    $pdu = $smpp->wait_pdu($cmd_id_to_wait, $seq_to_wait) or die;

=item set_version($vers)

Sets the protocol version of the object either to 0x40 or 0x34. Its
important to use this method instead of altering $smpp->{smpp_version}
field directly because there are several other fields that have to be
set in tandem.

=back

=head1 EXAMPLES

Typical client:

  use Net::SMPP;
  $smpp = Net::SMPP->new_transceiver('smsc.foo.net', port=>2552) or die;
  $resp_pdu = $smpp->submit_sm(destination_addr => '447799658372',
			       data => 'test message') or die;
  ***

Typical server, run from inetd:

  ***

See test.pl for good templates with all official parameters, but
beware that the actual parameter values are ficticious as is the flow
of the dialog.

=head1 MULTIPART MESSAGE

Reportedly (Zeus Panchenko) multipart messages can be gotten to work with

  while (length ($msgtext)) {
    if ($multimsg_maxparts) {
      @udh_ar = map { sprintf "%x", $_ } $origref, $multimsg_maxparts, $multimsg_curpart;
      $udh = pack("hhhhhh",0x05, 0x00, 0x03 , @udh_ar);
      $resp_pdu = $smpp->submit_sm(destination_addr => $phone,
                           ...
                           short_message => $udh . $msgtext,
                         );
      ...
    }
  }

#4#cut
=head1 VERSION 4.0 SUPPORT

Net::SMPP was originally written for version 3.4 of SMPP protocol. I
have since then gotten specifications for an earlier protocol, the
version 4.0 (Logical, eh? (pun intended)). In my understanding the
relevant differences are as follows (n.b. (ok) marks difference
that has already been implemented):

1. A reserved (always 0x00000000) field in message
   header (v4 p. 21) (ok)

2. Connection can not be opened in transceiver mode (this
   module will not enforce this restriction) (ok)

3. Command versioning. Version 0x01 == V4 (v4 p. 22) (ok)

4. Support for extended facilities has to be requested
   during bind (ok)

5. bind_* PDUs have facilities_mask field (v4 p. 25) (ok)

6. bind_*_resp PDUs have facilities_mask field (v4 p. 27) (ok)

7. outbind lacks system ID field (v4 p.30, v3.4 p. 54) (ok)

8. submit_sm lacks service_type and adds
   message_class (v4 p. 34, v3.4 p. 59) (ok)

9. submit_sm: telematic_interworking == protocol_id (ok)

10. submit_sm: starting from number of destinations and
    destination address the message format is substantially
    different. Actually the message format is somewhat
    similar to v3.4 submit_multi. (ok)

11. submit_sm: validity period encoded as an integer
    relative offset (was absolute time as C string) (ok)

12. submit_sm: replace_if_present flag missing (ok)

13. submit_sm: sm_length field is 2 octets (was one) (ok)

14. submit_sm_resp is completely different, but actually
    equal to v3.4 submit_multi_resp (v4 p. 37,
    v3.4 pp. 67,75) (ok)

15. submit_sm vs submit_multi: lacks service_type,
    adds message_class (ok)

16. submit_sm vs submit_multi: number_of_dests increased
    from 1 byte to 4 (ok)

17. submit_sm vs submit_multi: esm_class lacking, adds
    messaging_mode and msg_reference (ok)

18. submit_sm vs submit_multi: telematic_interworking == protocol_id (ok)

19. submit_sm vs submit_multi: replace_if_present missing (ok)

20. submit_sm vs submit_multi: sm_length is 2 bytes (was one) (ok)

21. submit_sm vs submit_multi: lacks dest_flag and distribution_list_name (ok)

22. deliver_sm: lacks service_type (ok)

23. deliver_sm: lacks esm_class, adds msg_reference and message_class (ok)

24. deliver_sm: telematic_interworking == protocol_id (ok)

25. deliver_sm: priority_level == priority_flag (ok)

26. deliver_sm: submit_time_stamp == schedule_delivery_time (ok)

27. deliver_sm: lacks validity_period, registered_delivery,
    and replace_if_present_flag (ok)

28. deliver_sm: lacks sm_default_msg_id (ok)

29. deliver_sm: sm_length is now 2 bytes (was one) (ok)

30. deliver_sm_resp: lacks message_id (v3.4 has the field, but its unused) (ok)

31. New command: delivery_receipt (ok)

32. New response: delivery_receipt_resp (ok)

33. query_sm: dest_addr_* fields added (v4 p. 46, v3.4 p. 95) (ok)

34. query_sm_resp: error_code renamed to network_error_code
    and increased in size from one to 4 bytes (ok)

35. cancel_sm: service_type renamed to message_class, also
    type changed (ok)

36. replace_sm: added dest_addr_* fields (ok)

37. replace_sm: data type of validity_period changed (ok)

38. replace_sm: added data_coding field (ok)

39. replace_sm: sm_length field increased from one to two bytes (ok)

40. In v3.4 command code 0x0009 means bind_transceiver,
    in v4.0 this very same code means delivery_receipt (bummer) (ok)

41. In v3.4 enquire_link is 0x0015 where as in v4 it is 0x000a (ok)


To create version 4 connection, you must specify smpp_version => 0x40
and you should not bind as transceiver as that is not supported by the
specification.

As v3.4 specification seems more mature, I recommend that where attributes
have been renamed between v4 and v3.4 you stick to using v3.4 names. I
have tried to provide compatibility code whenever possible.

#4#end

=head1 MISC. NOTES

Unless you wrote your program to be multithreaded or
multiprocess, everything will happen in one thread of execution.
Thus if you get unbind while doing something else (e.g. checking
your spool directory), it stays in operating system level buffers until
you actually call read_pdu(). Knowing about unbind or not is of little
use. You can write your program to assume the network traffic arrives
only exactly when you call read_pdu().

Regarding the unbind, it is normally handled by a dispatch table
automatically if you use wait_pdu() to receive your traffic. But
if you created your own dispatch table, you will have to add it
there yourself. If you are calling read_pdu() then you have
to handle it yourslef. Even if you are using the
supplied table, you may want to double check - there could be a bug.

One more thing: if your problem is knowing whether wait_pdu() or
read_pdu() would block, then you have two possible solutions:

	1. use select(2) systemcall to determine for the socket
	   is ready for reading
	2. structure your program as several processes (e.g. one
	   for sending and one for receiving) so that you
	   can afford to block

The above two tricks are not specific to this module. Consult any standard
text book on TCP/IP network programming.

=head1 ERRORS

Please consult C<status_code> table in the beginning of the source code or
SMPP specification section 5.1.3, table 5-2, pp.112-114.

=head1 EXPORT

None by default.

=head1 TESTS / WHAT IS KNOWN TO WORK

Interoperates with itself.

=head1 TO DO AND BUGS

=over 4

=item read_pdu() can block even if socket selects for reading.

=item The submit_multi command has not been implemented.

=back

=head1 AUTHOR AND COPYRIGHT

Sampo Kellomaki <sampo@symlabs.com>

Net::SMPP is copyright (c) 2001-2010 by Sampo Kellomaki, All rights reserved.
Portions copyright (c) 2001-2005 by Symlabs, All rights reserved.
You may use and distribute Net::SMPP under same terms as perl itself.

NET::SMPP COMES WITH ABSOLUTELY NO WARRANTY.

=head1 PLUG

This work was sponsored by Symlabs, the LDAP and directory experts
(www.symlabs.com).

=head1 SEE ALSO

=over 4

=item test.pl from this package

=item Short Message Peer to Peer Protocol Specification v3.4, 12-Oct-1999, Issue 1.2

=item www.etsi.fr

=item GSM 03.40, v5.7.1

=item www.wapforum.org

=item Short Message Peer to Peer (SMPP) V4 Protocol Specification, 29-Apr-1997, Version 1.1 (from Aldiscon/Logica)  #4

=item http://www.hsl.uk.com/documents/advserv-sms-smpp.pdf

=item http://www.mobilesms.com/developers.asp

=item http://opensmpp.logica.com

=item www.smpp.org (it appears as of July 2007 domain squatters have taken over the site and it is no longer useful)

=item http://www.smsforum.net/  -- New place for info (as of 20081214). However, this page announces the death of itself as of July 27, 2007. Great. The SMS folks really do not want anyone to implement their protocols from specifications.

=item "Short Message Peer to Peer Protocol Specification v5.0 19-February-2003", http://www.csoft.co.uk/documents/smppv50.pdf (good as of 20081214)

=item http://freshmeat.net/projects/netsmpp/ (announcements about Net::SMPP)

=item http://zxid.org/smpp/net-smpp.html (home page)

=item http://cpan.org/modules/by-module/Net/Net-SMPP-1.12.tar.gz (download from CPAN)

=item perl(1)

=back

=cut
