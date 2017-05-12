#
# $Id$
#
package Net::OpenFlow::Protocol;

#use bigint;
use strict;
use warnings;
use Carp;


=head1 NAME

Net::OpenFlow::Protocol - Protocol library for OpenFlow.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

This module allows encoding and decoding of OpenFlow messages from an OpenFlow switch.

use Net::OpenFlow::Protocol;


my $ofp = Net::OpenFlow::Protocol->new;

my $of_message = $ofp->ofpt_decode(\$of_message);

my $of_message_type = $of_message->{'ofp_header'}{'type'};

=head1 FUNCTIONS

=over

=cut

our $VERSION = 0.01;

our $openflow_version = 0x01;

my $misc_defines = {
	0x01 => {
		OFPFW_NW_SRC_SHIFT => 8,
		OFPFW_NW_SRC_BITS => 6,
		OFPFW_NW_DST_SHIFT => 14,
		OFPFW_NW_DST_BITS => 6,
		OFPP_NONE => 0xffff,
	},
};

my $ofp_enums = {};

$ofp_enums->{'ofp_action_type'} = {
	0x01 => {
		0x0000 => q{OFPAT_OUTPUT},
		0x0001 => q{OFPAT_SET_VLAN_VID},
		0x0002 => q{OFPAT_SET_VLAN_PCP},
		0x0003 => q{OFPAT_STRIP_VLAN},
		0x0004 => q{OFPAT_SET_DL_SRC},
		0x0005 => q{OFPAT_SET_DL_DST},
		0x0006 => q{OFPAT_SET_NW_SRC},
		0x0007 => q{OFPAT_SET_NW_DST},
		0x0008 => q{OFPAT_SET_NW_TOS},
		0x0009 => q{OFPAT_SET_TP_SRC},
		0x000a => q{OFPAT_SET_TP_DST},
		0x000b => q{OFPAT_ENQUEUE},
		0xffff => q{OFPAT_VENDOR},
	},
	0x02 => {
		0x0000 => q{OFPAT_OUTPUT},
		0x0001 => q{OFPAT_SET_VLAN_VID},
		0x0002 => q{OFPAT_SET_VLAN_PCP},
		0x0004 => q{OFPAT_SET_DL_SRC},
		0x0005 => q{OFPAT_SET_DL_DST},
		0x0006 => q{OFPAT_SET_NW_SRC},
		0x0007 => q{OFPAT_SET_NW_DST},
		0x0008 => q{OFPAT_SET_NW_TOS},
		0x0009 => q{OFPAT_SET_TP_SRC},
		0x000a => q{OFPAT_SET_TP_DST},
		0x000b => q{OFPAT_COPY_TTL_OUT},
		0x000c => q{OFPAT_COPY_TTL_IN},
		0x000d => q{OFPAT_SET_MPLS_LABEL},
		0x000e => q{OFPAT_SET_MPLS_TC},
		0x000f => q{OFPAT_SET_MPLS_TTL},
		0x0010 => q{OFPAT_DEC_MPLS_TTL},
		0x0011 => q{OFPAT_PUSH_VLAN},
		0x0012 => q{OFPAT_POP_VLAN},
		0x0013 => q{OFPAT_PUSH_MPLS},
		0x0014 => q{OFPAT_POP_MPLS},
		0x0015 => q{OFPAT_SET_QUEUE},
		0x0016 => q{OFPAT_GROUP},
		0x0017 => q{OFPAT_SET_NW_TTL},
		0x0018 => q{OFPAT_DEC_NW_TTL},
		0xffff => q{OFPAT_EXPERIMENTER},
	},
};

$ofp_enums->{'ofp_bad_action_code'} = {
	0x01 => {
		0x0000 => q{OFPBAC_BAD_TYPE},
		0x0001 => q{OFPBAC_BAD_LEN},
		0x0002 => q{OFPBAC_BAD_VENDOR},
		0x0003 => q{OFPBAC_BAD_VENDOR_TYPE},
		0x0004 => q{OFPBAC_BAD_OUT_PORT},
		0x0005 => q{OFPBAC_BAD_ARGUMENT},
		0x0006 => q{OFPBAC_EPERM},
		0x0007 => q{OFPBAC_TOO_MANY},
		0x0008 => q{OFPBAC_BAD_QUEUE},
	},
	0x02 => {
		0x0000 => q{OFPBAC_BAD_TYPE},
		0x0001 => q{OFPBAC_BAD_LEN},
		0x0002 => q{OFPBAC_BAD_EXPERMIMENTER},
		0x0003 => q{OFPBAC_BAD_EXPERMIMENTER_TYPE},
		0x0004 => q{OFPBAC_BAD_OUT_PORT},
		0x0005 => q{OFPBAC_BAD_ARGUMENT},
		0x0006 => q{OFPBAC_EPERM},
		0x0007 => q{OFPBAC_TOO_MANY},
		0x0008 => q{OFPBAC_BAD_QUEUE},
		0x0009 => q{OFPBAC_BAD_OUT_GROUP},
		0x000a => q{OFPBAC_MATCH_INCONSISTENT},
		0x000b => q{OFPBAC_UNSUPPORTED_ORDER},
		0x000c => q{OFPBAC_BAD_TAG},
	},
};

$ofp_enums->{'ofp_bad_instruction_code'} = {
	0x02 => {
		0x0000 => q{OFPBIC_UNKNOWN_INST},
		0x0001 => q{OFPBIC_UNSUP_INST},
		0x0002 => q{OFPBIC_BAD_TABLE_ID},
		0x0003 => q{OFPBIC_UNSUP_METADATA},
		0x0004 => q{OFPBIC_UNSUP_METADATA_MASK},
		0x0005 => q{OFPBIC_UNSUP_EXP_INST},
	},
};

$ofp_enums->{'ofp_bad_match_code'} = {
	0x02 => {
		0x0000 => q{OFPBMC_BAD_TYPE},
		0x0001 => q{OFPBMC_BAD_LEN},
		0x0002 => q{OFPBMC_BAD_TAG},
		0x0003 => q{OFPBMC_BAD_DL_ADDR_MASK},
		0x0004 => q{OFPBMC_BAD_NW_ADDR_MASK},
		0x0005 => q{OFPBMC_BAD_WILDCARDS},
		0x0006 => q{OFPBMC_BAD_FIELD},
		0x0007 => q{OFPBMC_BAD_VALUE},
	},
};

$ofp_enums->{'ofp_bad_request_code'} = {
	0x01 => {
		0x0000 => q{OFPBRC_BAD_VERSION},
		0x0001 => q{OFPBRC_BAD_TYPE},
		0x0002 => q{OFPBRC_BAD_STAT},
		0x0003 => q{OFPBRC_BAD_VENDOR},
		0x0004 => q{OFPBRC_BAD_SUBTYPE},
		0x0005 => q{OFPBRC_EPERM},
		0x0006 => q{OFPBRC_BAD_LEN},
		0x0007 => q{OFPBRC_BUFFER_EMPTY},
		0x0008 => q{OFPBRC_BUFFER_UNKNOWN},
	},
	0x02 => {
		0x0000 => q{OFPBRC_BAD_VERSION},
		0x0001 => q{OFPBRC_BAD_TYPE},
		0x0002 => q{OFPBRC_BAD_STAT},
		0x0003 => q{OFPBRC_BAD_EXPERMIMENTER},
		0x0004 => q{OFPBRC_BAD_SUBTYPE},
		0x0005 => q{OFPBRC_EPERM},
		0x0006 => q{OFPBRC_BAD_LEN},
		0x0007 => q{OFPBRC_BUFFER_EMPTY},
		0x0008 => q{OFPBRC_BUFFER_UNKNOWN},
		0x0009 => q{OFPBRC_BAD_TABLE_ID},
	},
};

$ofp_enums->{'ofp_capabilities'} = {
	bitfield => q{},
	0x01 => {
		(1 << 0) => q{OFPC_FLOW_STATS},
		(1 << 1) => q{OFPC_TABLE_STATS},
		(1 << 2) => q{OFPC_PORT_STATS},
		(1 << 3) => q{OFPC_STP},
		(1 << 4) => q{OFPC_RESERVED},
		(1 << 5) => q{OFPC_IP_REASM},
		(1 << 6) => q{OFPC_QUEUE_STATS},
		(1 << 7) => q{OFPC_ARP_MATCH_IP},
	},
};

$ofp_enums->{'ofp_config_flags'} = {
	0x01 => {
		0x0000 => q{OFPC_FRAG_NORMAL},
		0x0001 => q{OFPC_FRAG_DROP},
		0x0002 => q{OFPC_FRAG_REASM},
		0x0003 => q{OFPC_FRAG_MASK},
	},
};

$ofp_enums->{'ofp_error_type'} = {
	0x01 => {
		0x0000 => q{OFPET_HELLO_FAILED},
		0x0001 => q{OFPET_BAD_REQUEST},
		0x0002 => q{OFPET_BAD_ACTION},
		0x0003 => q{OFPET_FLOW_MOD_FAILED},
		0x0004 => q{OFPET_PORT_MOD_FAILED},
		0x0005 => q{OFPET_QUEUE_OP_FAILED},
	},
	0x02 => {
		0x0000 => q{OFPET_HELLO_FAILED},
		0x0001 => q{OFPET_BAD_REQUEST},
		0x0002 => q{OFPET_BAD_ACTION},
		0x0003 => q{OFPET_BAD_INSTRUCTION},
		0x0004 => q{OFPET_BAD_MATCH},
		0x0005 => q{OFPET_FLOW_MOD_FAILED},
		0x0006 => q{OFPET_GROUP_MOD_FAILED},
		0x0007 => q{OFPET_PORT_MOD_FAILED},
		0x0008 => q{OFPET_TABLE_MOD_FAILED},
		0x0009 => q{OFPET_QUEUE_OP_FAILED},
		0x000a => q{OFPET_SWITCH_CONFIG_FAILED},
	}
};

$ofp_enums->{'ofp_flow_mod_command'} = {
	0x01 => {
		0x0000 => q{OFPFC_ADD},
		0x0001 => q{OFPFC_MODIFY},
		0x0002 => q{OFPFC_MODIFY_STRICT},
		0x0003 => q{OFPFC_DELETE},
		0x0004 => q{OFPFC_DELETE_STRICT},
	},
};

$ofp_enums->{'ofp_flow_mod_failed_code'} = {
	0x01 => {
		0x0000 => q{OFPFMFC_ALL_TABLES_FULL},
		0x0001 => q{OFPFMFC_OVERLAP},
		0x0002 => q{OFPFMFC_EPERM},
		0x0003 => q{OFPFMFC_BAD_EMERG_TIMEOUT},
		0x0004 => q{OFPFMFC_BAD_COMMAND},
		0x0005 => q{OFPFMFC_UNSUPPORTED},
	},
};

$ofp_enums->{'ofp_flow_mod_flags'} = {
	bitfield => q{},
	0x01 => {
		(1 << 0) => q{OFPFF_SEND_FLOW_REM},
		(1 << 1) => q{OFPFF_CHECK_OVERLAP},
		(1 << 2) => q{OFPFF_EMERG},
	},
};

$ofp_enums->{'ofp_flow_wildcards'} = {
	bitfield => q{},
	0x01 => {
		(1 << 0) => q{OFPFW_IN_PORT},
		(1 << 1) => q{OFPFW_DL_VLAN},
		(1 << 2) => q{OFPFW_DL_SRC},
		(1 << 3) => q{OFPFW_DL_DST},
		(1 << 4) => q{OFPFW_DL_TYPE},
		(1 << 5) => q{OFPFW_NW_PROTO},
		(1 << 6) => q{OFPFW_TP_SRC},
		(1 << 7) => q{OFPFW_TP_DST},
		(((1 << $misc_defines->{0x01}{'OFPFW_NW_SRC_BITS'}) - 1) << $misc_defines->{0x01}{'OFPFW_NW_SRC_SHIFT'}) => q{OFPFW_NW_SRC_MASK},
		(32 << $misc_defines->{0x01}{'OFPFW_NW_SRC_SHIFT'}) => q{OFPFW_NW_SRC_ALL},
		(((1 << $misc_defines->{0x01}{'OFPFW_NW_DST_BITS'}) - 1) << $misc_defines->{0x01}{'OFPFW_NW_DST_SHIFT'}) => q{OFPFW_NW_DST_MASK},
		(32 << $misc_defines->{0x01}{'OFPFW_NW_DST_SHIFT'}) => q{OFPFW_NW_DST_ALL},
		(1 << 20) => q{OFPFW_DL_VLAN_PCP},
		(1 << 21) => q{OFPFW_NW_TOS},
		((1 << 22) - 1) => q{OFPFW_ALL},
	},
	0x02 => {
		(1 << 0) => q{OFPFW_IN_PORT},
		(1 << 1) => q{OFPFW_DL_VLAN},
		(1 << 2) => q{OFPFW_DL_VLAN_PCP},
		(1 << 3) => q{OFPFW_DL_TYPE},
		(1 << 4) => q{OFPFW_NW_TOS},
		(1 << 5) => q{OFPFW_NW_PROTO},
		(1 << 6) => q{OFPFW_TP_SRC},
		(1 << 7) => q{OFPFW_TP_DST},
		((1 << 10) - 1) => q{OFPFW_ALL},
	}
};

$ofp_enums->{'ofp_hello_failed_code'} = {
	0x01 => {
		0x0000 => q{OFPHFC_INCOMPATIBLE},
		0x0001 => q{OFPHFC_EPERM},
	},
};

$ofp_enums->{'ofp_hello_failed_code'}{0x02} = $ofp_enums->{'ofp_hello_failed_code'}{0x01};

$ofp_enums->{'ofp_packet_in_reason'} = {
	0x01 => {
		0x00 => q{OFPR_NO_MATCH},
		0x01 => q{OFPR_ACTION},
	},
};

$ofp_enums->{'ofp_port_config'} = {
	bitfield => q{},
	0x01 => {
		(1 << 0) => q{OFPPC_PORT_DOWN},
		(1 << 1) => q{OFPPC_NO_STP},
		(1 << 2) => q{OFPPC_NO_RECV},
		(1 << 3) => q{OFPPC_NO_RECV_STP},
		(1 << 4) => q{OFPPC_NO_FLOOD},
		(1 << 5) => q{OFPPC_NO_FWD},
		(1 << 6) => q{OFPPC_NO_PACKET_IN},
	},
};

$ofp_enums->{'ofp_port_features'} = {
	bitfield => q{},
	0x01 => {
		(1 << 0) => q{OFPPF_10MB_HD},
		(1 << 1) => q{OFPPF_10MB_FD},
		(1 << 2) => q{OFPPF_100MB_HD},
		(1 << 3) => q{OFPPF_100MB_FD},
		(1 << 4) => q{OFPPF_1GB_HD},
		(1 << 5) => q{OFPPF_1GB_FD},
		(1 << 6) => q{OFPPF_10GB_FD},
		(1 << 7) => q{OFPPF_COPPER},
		(1 << 8) => q{OFPPF_FIBER},
		(1 << 9) => q{OFPPF_AUTONEG},
		(1 << 10) => q{OFPPF_PAUSE},
		(1 << 11) => q{OFPPF_PAUSE_ASYM},
	},
};

$ofp_enums->{'ofp_port_mod_failed_code'} = {
	0x01 => {
		0x0000 => q{OFPPMFC_BAD_PORT},
		0x0001 => q{OFPPMFC_BAD_HW_ADDR},
	},
	0x02 => {
		0x0000 => q{OFPPMFC_BAD_PORT},
		0x0001 => q{OFPPMFC_BAD_HW_ADDR},
		0x0002 => q{OFPPMFC_BAD_CONFIG},
		0x0003 => q{OFPPMFC_BAD_ADVERTISE},
	},
};

$ofp_enums->{'ofp_port_reason'} = {
	0x01 => {
		0x00 => q{OFPPR_ADD},
		0x01 => q{OFPPR_DELETE},
		0x02 => q{OFPPR_MODIFY},
	},
};

$ofp_enums->{'ofp_port_state'} = {
	bitfield => q{},
	0x01 => {
		(1 << 0) => q{OFPPS_LINK_DOWN},
		(0 << 8) => q{OFPPS_STP_LISTEN},
		(1 << 8) => q{OFPPS_STP_LEARN},
		(2 << 8) => q{OFPPS_STP_FORWARD},
		(3 << 8) => q{OFPPS_STP_BLOCK},
		(4 << 8) => q{OFPPS_STP_MASK},
	},
};

$ofp_enums->{'ofp_queue_op_failed_code'} = {
	0x01 => {
		0x0000 => q{OFPQOFC_BAD_PORT},
		0x0001 => q{OFPQOFC_BAD_QUEUE},
		0x0002 => q{OFPQOFC_EPERM},
	},
};

$ofp_enums->{'ofp_queue_properties'} = {
	0x01 => {
		0x00 => q{OFPQT_NONE},
		0x01 => q{OFPQT_MIN_RATE},
	},
};

$ofp_enums->{'ofp_stats_req_flags'} = {
	bitfield => q{},
	0x01 => {
		(1 << 0) => q{OFPSF_REPLY_MORE},
	},
};

$ofp_enums->{'ofp_stats_types'} = {
	0x01 => {
		0x0000 => q{OFPST_DESC},
		0x0001 => q{OFPST_FLOW},
		0x0002 => q{OFPST_AGGREGATE},
		0x0003 => q{OFPST_TABLE},
		0x0004 => q{OFPST_PORT},
		0x0005 => q{OFPST_QUEUE},
		0xffff => q{OFPST_VENDOR},
	},
	0x02 => {
		0x0000 => q{OFPST_DESC},
		0x0001 => q{OFPST_FLOW},
		0x0002 => q{OFPST_AGGREGATE},
		0x0003 => q{OFPST_TABLE},
		0x0004 => q{OFPST_PORT},
		0x0005 => q{OFPST_QUEUE},
		0x0006 => q{OFPST_GROUP},
		0x0007 => q{OFPST_GROUP_DESC},
		0xffff => q{OFPST_EXPERIMENTER},
	},
};

$ofp_enums->{ofp_switch_config_failed_code} = {
	0x02 => {
		0x00 => q{OFPSCFC_BAD_FLAGS},
		0x01 => q{OFPSCFC_BAD_LEN},
	},
};

$ofp_enums->{'ofp_table_mod_failed_code'} = {
	0x02 => {
		0x00 => q{OFPTMFC_BAD_TABLE},
		0x01 => q{OFPTMFC_BAD_CONFIG},
	},
};

$ofp_enums->{'ofp_type'} = {
	0x01 => {
		0x00 => q{OFPT_HELLO},
		0x01 => q{OFPT_ERROR},
		0x02 => q{OFPT_ECHO_REQUEST},
		0x03 => q{OFPT_ECHO_REPLY},
		0x04 => q{OFPT_VENDOR},
		0x05 => q{OFPT_FEATURES_REQUEST},
		0x06 => q{OFPT_FEATURES_REPLY},
		0x07 => q{OFPT_GET_CONFIG_REQUEST},
		0x08 => q{OFPT_GET_CONFIG_REPLY},
		0x09 => q{OFPT_SET_CONFIG},
		0x0a => q{OFPT_PACKET_IN},
		0x0b => q{OFPT_FLOW_REMOVED},
		0x0c => q{OFPT_PORT_STATUS},
		0x0d => q{OFPT_PACKET_OUT},
		0x0e => q{OFPT_FLOW_MOD},
		0x0f => q{OFPT_PORT_MOD},
		0x10 => q{OFPT_STATS_REQUEST},
		0x11 => q{OFPT_STATS_REPLY},
		0x12 => q{OFPT_BARRIER_REQUEST},
		0x13 => q{OFPT_BARRIER_REPLY},
		0x14 => q{OFPT_QUEUE_GET_CONFIG_REQUEST},
		0x15 => q{OFPT_QUEUE_GET_CONFIG_REPLY},
	},
	0x02 => {
		0x00 => q{OFPT_HELLO},
		0x01 => q{OFPT_ERROR},
		0x02 => q{OFPT_ECHO_REQUEST},
		0x03 => q{OFPT_ECHO_REPLY},
		0x04 => q{OFPT_EXPERIMENTER},
		0x05 => q{OFPT_FEATURES_REQUEST},
		0x06 => q{OFPT_FEATURES_REPLY},
		0x07 => q{OFPT_GET_CONFIG_REQUEST},
		0x08 => q{OFPT_GET_CONFIG_REPLY},
		0x09 => q{OFPT_SET_CONFIG},
		0x0a => q{OFPT_PACKET_IN},
		0x0b => q{OFPT_FLOW_REMOVED},
		0x0c => q{OFPT_PORT_STATUS},
		0x0d => q{OFPT_PACKET_OUT},
		0x0e => q{OFPT_FLOW_MOD},
		0x0f => q{OFPT_GROUP_MOD},
		0x10 => q{OFPT_PORT_MOD},
		0x11 => q{OFPT_TABLE_MOD},
		0x12 => q{OFPT_STATS_REQUEST},
		0x13 => q{OFPT_STATS_REPLY},
		0x14 => q{OFPT_BARRIER_REQUEST},
		0x15 => q{OFPT_BARRIER_REPLY},
		0x16 => q{OFPT_QUEUE_GET_CONFIG_REQUEST},
		0x17 => q{OFPT_QUEUE_GET_CONFIG_REPLY},
	},
};

my $struct_types = {
	ofp_header => {
		0x01 => {
			format => q{C C n N},
			length => 8,
		},
	},
	ofp_match => {
		0x01 => {
			format => q{N n H12 H12 n C x n C C x2 N N n n},
			length => 40,
		},
		0x02 => {
			format => q{n n N N H12 H12 H12 H12 n C x n C C N N N N n n N C x Q> Q>},
			length => 88,
		},
	},
};

our $header_length = __PACKAGE__->struct_sizeof(0x01, q{ofp_header});

$struct_types->{'ofp_action_dl_addr'}{0x01} = {
	format => q{n H12 x6},
	length => 16,
};

$struct_types->{'ofp_action_enqueue'}{0x01} = {
	format => q{n n n x6 N},
	length => 16,
};

$struct_types->{'ofp_action_header'}{0x01} = {
	format => q{n n x4},
	length => 8,
};

$struct_types->{'ofp_action_nw_addr'}{0x01} = {
	format => q{n n N},
	length => 8,
};

$struct_types->{'ofp_action_nw_tos'}{0x01} = {
	format => q{n n C C3},
	length => 8,
};

$struct_types->{'ofp_action_output'}{0x01} = {
	format => q{n n n n},
	length => 8,
};

$struct_types->{'ofp_action_tp_port'}{0x01} = {
	format => q{n n n C2},
	length => 8,
};

$struct_types->{'ofp_action_vendor_header'}{0x01} = {
	format => q{n n N},
	length => 8,
};

$struct_types->{'ofp_action_vlan_pcp'}{0x01} = {
	format => q{n n C x3},
	length => 8,
};

$struct_types->{'ofp_action_vlan_vid'}{0x01} = {
	format => q{n n n x2},
	length => 8,
};

$struct_types->{'ofp_desc_stats'}{0x01} = {
	format => q{Z256 Z256 Z256 Z32 Z256},
	length => 1056,
};

$struct_types->{'ofp_error_msg'}{0x01} = {
	format => qq/(a$header_length) n n/,
	length => 12,
};

$struct_types->{'ofp_flow_mod'} = {
	0x01 => {
		format => qq/(a$header_length) (a$struct_types->{'ofp_match'}{0x01}{'length'}) Q> n n n n N n n/,
		length => 72,
	},
};

$struct_types->{'ofp_flow_stats'} = {
	0x01 => {
		format => qq/n C x (a$struct_types->{'ofp_match'}{0x01}{'length'}) N N n n n x6 Q> Q> Q>/,
		length => 88,
	},
};

$struct_types->{'ofp_flow_stats_request'} = {
	0x01 => {
		format => qq/(a$struct_types->{'ofp_match'}{0x01}{'length'}) C x n/,
		length => 44,
	},
};

$struct_types->{'ofp_packet_in'}{0x01} = {
	format => qq/(a$header_length) N n n C x/,
	length => 20,
};

$struct_types->{'ofp_packet_out'}{0x01} = {
	format => qq/(a$header_length) N n n/,
	length => 16,
};

$struct_types->{'ofp_packet_queue'}{0x01} = {
	format => q/N n x2/,
	length => 8,
};

$struct_types->{'ofp_phy_port'}{0x01} = {
	format => q{n H12 A16 N N N N N N},
	length => 48,
};

$struct_types->{'ofp_port_mod'}{0x01} = {
	format => qq/(a$header_length) n H12 N N N x4/,
	length => 32,
};

$struct_types->{'ofp_port_stats'}{0x01} = {
	format => q{n x6 Q>12},
	length => 104,
};

$struct_types->{'ofp_port_stats_request'}{0x01} = {
	format => q{n x6},
	length => 8,
};

$struct_types->{'ofp_port_status'}{0x01} = {
	format => qq/(a$header_length) C x7 a48/,
	length => 64,
};

$struct_types->{'ofp_queue_get_config_reply'}{0x01} = {
	format => qq/(a$header_length) n x6/,
	length => 16,
};

$struct_types->{'ofp_queue_get_config_request'}{0x01} = {
	format => qq/(a$header_length) n x2/,
	length => 12,
};

$struct_types->{'ofp_queue_prop_header'}{0x01} = {
	format => q{n n x4},
	length => 8,
};

$struct_types->{'ofp_queue_prop_min_rate'}{0x01} = {
	format => q{n x6},
	length => 16,
};

$struct_types->{'ofp_stats_reply'}{0x01} = {
	format => qq/(a$header_length) n n/,
	length => 12,
};

$struct_types->{'ofp_stats_request'}{0x01} = {
	format => qq/(a$header_length) n n/,
	length => 12,
};

$struct_types->{'ofp_switch_config'}{0x01} = {
	format => qq/(a$header_length) n n/,
	length => 12,
};

$struct_types->{'ofp_switch_features'}{0x01} = {
	format => qq/(a$header_length) H16 N C x3 N N/,
	length => 32,
};

$struct_types->{'ofp_table_stats'}{0x01} = {
	format => q/C x3 a32 N N N Q> Q>/,
	length => 64,
};

$struct_types->{'ofp_experimenter_header'} = {
	0x02 => {
		format => qq/(a$header_length) N x4/,
		length => 16,
	},
};

=item C<< bitfield_decode >>

This function will decode the bitfield specified by $bitfield into the $enum_type.

my $ret = $ofp->bitfield_decode($of_version, $enum_type, $bitfield);

=cut

sub bitfield_decode($$$$) {
	my $self = shift;
	my ($version, $enum_type, $bitfield) = @_;

	unless (
		defined($ofp_enums->{$enum_type}{$version})
		and
		(ref($ofp_enums->{$enum_type}{$version}) eq q{HASH})
		and
		defined($ofp_enums->{$enum_type}{'bitfield'})
	) {
		croak qq{Invalid bitfield type [$version][$enum_type]};
	}

	my $ret = [];

	foreach my $enum (sort {$a <=> $b} keys(%{$ofp_enums->{$enum_type}{$version}})) {
		if (($bitfield & $enum) == $enum) {
			push @{$ret}, $ofp_enums->{$enum_type}{$version}{$enum};
		}
	}

	return $ret;
}

=item C<< bitfield_encode >>

This function will encode bits specified into the bitfield $enum_type.

my $ret = $ofp->bitfield_encode($of_version, $enum_type, $bits);

=cut

sub bitfield_encode($$$$) {
	my $self = shift;
	my ($version, $enum_type, $bits) = @_;

	unless (
		defined($ofp_enums->{$enum_type}{$version})
		and
		(ref($ofp_enums->{$enum_type}{$version}) eq q{HASH})
		and
		defined($ofp_enums->{$enum_type}{'bitfield'})
	) {
		croak qq{Invalid bitfield type [$version][$enum_type]};
	}

	my $ret = 0;

	foreach my $enum (keys %{$ofp_enums->{$enum_type}{$version}}) {
		foreach (@{$bits}) {
			if ($_ eq $ofp_enums->{$enum_type}{$version}{$enum}) {
				$ret |= $enum;
				last;
			}
		}
	}

	return $ret;
}

=item C<< enum_lookup >>

This function will 

my $ret = $ofp->enum_lookup($of_version, $enum_type, $lookup);

=cut

sub enum_lookup($$$$) {
	my $self = shift;
	my ($version, $enum_type, $lookup) = @_;

	unless (defined($ofp_enums->{$enum_type}{$version}) and (ref($ofp_enums->{$enum_type}{$version}) eq q{HASH})) {
		croak qq{Invalid enum type [$version][$enum_type]};
	}

	my $ret;

	$ret = $ofp_enums->{$enum_type}{$version}{$lookup};

	return $ret;
}

=item C<< enum_lookup__by_value >>

This function will 

my $ret = $ofp->enum_lookup__by_value($of_version, $enum_type, $lookup);

=cut

sub enum_lookup__by_value($$$$) {
	my $self = shift;
	my ($version, $enum_type, $lookup) = @_;

	unless (defined($ofp_enums->{$enum_type}{$version}) and (ref($ofp_enums->{$enum_type}{$version}) eq q{HASH})) {
		croak qq{Invalid enum type [$version][$enum_type]};
	}

	my @sorted_enum = sort {$a <=> $b} keys(%{$ofp_enums->{$enum_type}{$version}});

	my $ret;

	foreach (@sorted_enum) {
		if ($ofp_enums->{$enum_type}{$version}{$_} eq $lookup) {
			$ret = $_;
			last;
		}
	}

	return $ret;
}

=item C<< new >>

This is the constructor for the Net::OpenFlow::Protocol module.

my $ofp = Net::OpenFlow::Protocol->new;

=cut

sub new {
	my $class = shift;

	my $self = {};

	bless $self, $class;

	$self->new_init(@_);

	return $self;
}

sub new_init {
	my $self = shift;
}

=item C<< ofpt_decode >>

This function decodes OpenFlow messages.
The input is a reference to a scalar containing the OpenFlow message.
The returned value is a hash reference containing the decoded message parameters.
This always contains a ofp_header hash in the returned value which will have a type describing the message received.
Based on this value the other parameters may be interpreted.

my $ret = $ofp->ofpt_decode(\$of_message);

my $of_message_type = $ret->{'ofp_header'}{'type'};

=cut

sub ofpt_decode($$) {
	my $self = shift;
	my $message = shift;

	unless (defined($message) and (ref($message) eq q{SCALAR})) {
		croak q{Invalid OFPT message};
	}

	my ($pdu_version, $pdu_type) = unpack(q{C C}, ${$message});

unless ($pdu_version) {
croak $self->__debug($self->__hex_preview(${$message}, 32));
}

	$pdu_type = $self->enum_lookup($pdu_version, q{ofp_type}, $pdu_type);

	my $ret = {};

	if ($pdu_type eq q{OFPT_BARRIER_REPLY}) {
		$ret->{'ofp_header'} = $self->struct_decode__ofp_header($message);
		$ret->{'ofp_header'}{'type'} = $pdu_type;
	}
	elsif ($pdu_type eq q{OFPT_BARRIER_REQUEST}) {
# N/A - Controller -> Datapath
	}
	elsif ($pdu_type eq q{OFPT_ECHO_REPLY}) {
		$ret->{'ofp_header'} = $self->struct_decode__ofp_header($message);
		$ret->{'ofp_header'}{'type'} = $pdu_type;

		$self->struct_chomp($pdu_version, q{ofp_header}, $message);
		$ret->{'body'} = ${$message};
	}
	elsif ($pdu_type eq q{OFPT_ECHO_REQUEST}) {
		$ret->{'ofp_header'} = $self->struct_decode__ofp_header($message);
		$ret->{'ofp_header'}{'type'} = $pdu_type;

		$self->struct_chomp($pdu_version, q{ofp_header}, $message);
		$ret->{'body'} = ${$message};
	}
	elsif ($pdu_type eq q{OFPT_ERROR}) {
		my $struct_values = $self->struct_decode($pdu_version, q{ofp_error_msg}, $message);
		my $pdu_length = $self->struct_chomp($pdu_version, q{ofp_error_msg}, $message);

		$ret->{'ofp_header'} = $self->struct_decode__ofp_header(\$struct_values->[0]);
		$ret->{'ofp_header'}{'type'} = $pdu_type;

		my $ofpet = $self->enum_lookup($pdu_version, q{ofp_error_type}, $struct_values->[1]);
		$ret->{'type'} = $ofpet;

		if ($ofpet eq q{OFPET_HELLO_FAILED}) {
			$ret->{'code'} = $self->enum_lookup($pdu_version, q{ofp_hello_failed_code}, $struct_values->[2]);
		}
		elsif ($ofpet eq q{OFPET_BAD_REQUEST}) {
			$ret->{'code'} = $self->enum_lookup($pdu_version, q{ofp_bad_request_code}, $struct_values->[2]);
		}
		elsif ($ofpet eq q{OFPET_BAD_ACTION}) {
			$ret->{'code'} = $self->enum_lookup($pdu_version, q{ofp_bad_action_code}, $struct_values->[2]);
		}
		elsif ($ofpet eq q{OFPET_FLOW_MOD_FAILED}) {
			$ret->{'code'} = $self->enum_lookup($pdu_version, q{ofp_flow_mod_failed_code}, $struct_values->[2]);
		}
		elsif ($ofpet eq q{OFPET_PORT_MOD_FAILED}) {
			$ret->{'code'} = $self->enum_lookup($pdu_version, q{ofp_port_mod_fail_code}, $struct_values->[2]);
		}
		elsif ($ofpet eq q{OFPET_QUEUE_OP_FAILED}) {
			$ret->{'code'} = $self->enum_lookup($pdu_version, q{ofp_queue_op_failed_code}, $struct_values->[2]);
		}
		else {
			$ret->{'code'} = $struct_values->[2];
		}

		if ($pdu_length) {
			$ret->{'data'} = ${$message};
		}
	}
	elsif ($pdu_type eq q{OFPT_FEATURES_REPLY}) {
		my $struct_values = $self->struct_decode($pdu_version, q{ofp_switch_features}, $message);

		$ret->{'ofp_header'} = $self->struct_decode__ofp_header(\$struct_values->[0]);
		$ret->{'ofp_header'}{'type'} = $pdu_type;

		$ret->{'datapath_id'} = $self->__format_pretty__hex_string($struct_values->[1]);
		$ret->{'n_buffers'} = $struct_values->[2];
		$ret->{'n_tables'} = $struct_values->[3];
		$ret->{'capabilities'} = $struct_values->[4];
		$ret->{'actions'} = $struct_values->[5];

		my $pdu_length = $self->struct_chomp($pdu_version, q{ofp_switch_features}, $message);

		if (($pdu_length % $self->struct_sizeof($pdu_version, q{ofp_phy_port})) == 0) {
			while($pdu_length) {
				push @{$ret->{'body'}}, $self->struct_decode__ofp_phy_port($pdu_version, $message);

				$pdu_length = $self->struct_chomp($pdu_version, q{ofp_phy_port}, $message);
			}
		}
		else {
			carp qq{Bad format packet};
		}
	}
	elsif ($pdu_type eq q{OFPT_FEATURES_REQUEST}) {
# N/A - Controller -> Datapath
	}
	elsif ($pdu_type eq q{OFPT_FLOW_MOD}) {
# N/A - Controller -> Datapath
	}
	elsif ($pdu_type eq q{OFPT_FLOW_REMOVED}) {
		my $struct_values = $self->struct_decode($pdu_version, q{ofp_flow_removed}, $message);

		$ret->{'ofp_header'} = $self->struct_decode__ofp_header(\$struct_values->[0]);
		$ret->{'ofp_header'}{'type'} = $pdu_type;

		$ret->{'match'} = $self->struct_decode__ofp_match($pdu_version, \$struct_values->[1]);
		$ret->{'cookie'} = $struct_values->[2];
		$ret->{'priority'} = $struct_values->[3];
		$ret->{'reason'} = $self->enum_lookup($pdu_version, q{ofp_flow_removed_reason}, $struct_values->[4]);
		$ret->{'duation_sec'} = $struct_values->[5];
		$ret->{'duation_nsec'} = $struct_values->[6];
		$ret->{'idle_timeout'} = $struct_values->[7];
		$ret->{'packet_count'} = $struct_values->[8];
		$ret->{'byte_count'} = $struct_values->[9];
	}
	elsif ($pdu_type eq q{OFPT_GET_CONFIG_REPLY}) {
		my $struct_values = $self->struct_decode($pdu_version, q{ofp_switch_config}, $message);

		$ret->{'ofp_header'} = $self->struct_decode__ofp_header(\$struct_values->[0]);
		$ret->{'ofp_header'}{'type'} = $pdu_type;

		$ret->{'flags'} = $struct_values->[1];
		$ret->{'miss_send_len'} = $struct_values->[2];
	}
	elsif ($pdu_type eq q{OFPT_GET_CONFIG_REQUEST}) {
# N/A - Controller -> Datapath
	}
	elsif ($pdu_type eq q{OFPT_HELLO}) {
		$ret = $self->struct_decode__ofp_header($message);
		$ret->{'type'} = $pdu_type;
	}
	elsif ($pdu_type eq q{OFPT_PACKET_IN}) {
		my $struct_values = $self->struct_decode($pdu_version, q{ofp_packet_in}, $message);

		$ret->{'ofp_header'} = $self->struct_decode__ofp_header(\$struct_values->[0]);
		$ret->{'ofp_header'}{'type'} = $pdu_type;

		$ret->{'buffer_id'} = $struct_values->[1];
		$ret->{'total_len'} = $struct_values->[2];
		$ret->{'in_port'} = $struct_values->[3];
		$ret->{'reason'} = $struct_values->[4];
	}
	elsif ($pdu_type eq q{OFPT_PACKET_OUT}) {
# N/A - Controller -> Datapath
	}
	elsif ($pdu_type eq q{OFPT_PORT_MOD}) {
# N/A - Controller -> Datapath
	}
	elsif ($pdu_type eq q{OFPT_PORT_STATUS}) {
		my $struct_values = $self->struct_decode($pdu_version, q{ofp_port_status}, $message);

		$ret->{'ofp_header'} = $self->struct_decode__ofp_header(\$struct_values->[0]);
		$ret->{'ofp_header'}{'type'} = $pdu_type;

		$ret->{'reason'} = $struct_values->[1];
		$ret->{'ofp_phy_port'} = $self->struct_decode__ofp_phy_port($pdu_version, \$struct_values->[2]);
	}
	elsif ($pdu_type eq q{OFPT_QUEUE_GET_CONFIG_REPLY}) {
		my $struct_values = $self->struct_decode($pdu_version, q{ofp_queue_get_config_reply}, $message);
		my $pdu_length = $self->struct_chomp($pdu_version, q{ofp_queue_get_config_reply}, $message);

		$ret->{'ofp_header'} = $self->struct_decode__ofp_header(\$struct_values->[0]);
		$ret->{'ofp_header'}{'type'} = $pdu_type;

		$ret->{'port'} = $struct_values->[1];

		while ($pdu_length >= $self->struct_sizeof($pdu_version, q{ofp_packet_queue})) {
			my $struct_values = $self->struct_decode($pdu_version, q{ofp_packet_queue}, $message);
			$pdu_length = $self->struct_chomp($pdu_version, q{ofp_packet_queue}, $message);

			$ret->{'queue_id'} = $struct_values->[0];

			my $remaining_bytes = ($struct_values->[1] - $self->struct_sizeof($pdu_version, q{ofp_packet_queue}));

			my $properties = [];

			if (($remaining_bytes % $self->struct_sizeof($pdu_version, q{ofp_queue_prop_header})) == 0) {
#				while ($remaining_bytes) {
#				}
			}
			else {
			}
		}
	}
	elsif ($pdu_type eq q{OFPT_QUEUE_GET_CONFIG_REQUEST}) {
# N/A - Controller -> Datapath
	}
	elsif ($pdu_type eq q{OFPT_SET_CONFIG} ){
# N/A - Controller -> Datapath
	}
	elsif ($pdu_type eq q{OFPT_STATS_REQUEST}) {
# N/A - Controller -> Datapath
	}
	elsif ($pdu_type eq q{OFPT_STATS_REPLY}) {
		my $struct_values = $self->struct_decode($pdu_version, q{ofp_stats_reply}, $message);
		my $pdu_length = $self->struct_chomp($pdu_version, q{ofp_stats_reply}, $message);

		$ret->{'ofp_header'} = $self->struct_decode__ofp_header(\$struct_values->[0]);
		$ret->{'ofp_header'}{'type'} = $pdu_type;

		my $ofpst = $self->enum_lookup($pdu_version, q{ofp_stats_types}, $struct_values->[1]);

		$ret->{'type'} = $ofpst;
		$ret->{'flags'} = $struct_values->[2];

		if ($ofpst eq q{OFPST_DESC}) {
			if (($pdu_length % $self->struct_sizeof($pdu_version, q{ofp_desc_stats})) == 0) {
				while ($pdu_length) {
					my $struct_values = $self->struct_decode($pdu_version, q{ofp_desc_stats}, $message);
					$pdu_length = $self->struct_chomp($pdu_version, q{ofp_desc_stats}, $message);

					push @{$ret->{'body'}}, {
						q{mfr_desc} => $struct_values->[0],
						q{hw_desc} => $struct_values->[1],
						q{sw_desc} => $struct_values->[2],
						q{serial_num} => $struct_values->[3],
						q{dp_desc} => $struct_values->[4],
					};
				}
			}
			else {
			}
		}
		elsif ($ofpst eq q{OFPST_FLOW}) {
			while ($pdu_length >= $self->struct_sizeof($pdu_version, q{ofp_flow_stats})) {
				my $struct_values = $self->struct_decode($pdu_version, q{ofp_flow_stats}, $message);
				$pdu_length = $self->struct_chomp($pdu_version, q{ofp_flow_stats}, $message);

				my $remaining_bytes = ($struct_values->[0] - $self->struct_sizeof($pdu_version, q{ofp_flow_stats}));

				my $actions = [];

				if (($remaining_bytes % $self->struct_sizeof($pdu_version, q{ofp_action_header})) == 0) {
					while ($remaining_bytes) {
						my ($action_type, $action_length) = unpack(q{n n}, ${$message});
						$action_type = $self->enum_lookup($pdu_version, q{ofp_action_type}, $action_type);

						my $action = {
							q{type} => $action_type,
							length => $action_length
						};

						if ($action_type eq q{OFPAT_OUTPUT}) {
							my $ofp_action_output = $self->struct_decode($pdu_version, q{ofp_action_output}, $message);
							$pdu_length = $self->struct_chomp($pdu_version, q{ofp_action_output}, $message);

							$action->{'port'} = $ofp_action_output->[2];
							$action->{'max_len'} = $ofp_action_output->[3];
						}
						elsif ($action_type eq q{OFPAT_SET_VLAN_VID}) {
							my $ofp_action_vlan_vid = $self->struct_decode($pdu_version, q{ofp_action_vlan_vid}, $message);
							$pdu_length = $self->struct_chomp($pdu_version, q{ofp_action_vlan_vid}, $message);

							$action->{'vlan_vid'} = $ofp_action_vlan_vid->[2];
						}
						elsif ($action_type eq q{OFPAT_SET_VLAN_PCP}) {
							my $ofp_action_vlan_pcp = $self->struct_decode($pdu_version, q{ofp_action_vlan_pcp}, $message);
							$pdu_length = $self->struct_chomp($pdu_version, q{ofp_action_vlan_pcp}, $message);

							$action->{'vlan_pcp'} = $ofp_action_vlan_pcp->[2];
						}
						elsif ($action_type eq q{OFPAT_STRIP_VLAN}) {
						}
						elsif ($action_type eq q{OFPAT_SET_DL_SRC}) {
							my $ofp_action_dl_addr = $self->struct_decode($pdu_version, q{ofp_action_dl_addr}, $message);
							$pdu_length = $self->struct_chomp($pdu_version, q{ofp_action_dl_addr}, $message);

							$action->{'dl_addr'} = $self->__format_pretty__hex_string($ofp_action_dl_addr->[2]);
						}
						elsif ($action_type eq q{OFPAT_SET_DL_DST}) {
							my $ofp_action_dl_addr = $self->struct_decode($pdu_version, q{ofp_action_dl_addr}, $message);
							$pdu_length = $self->struct_chomp($pdu_version, q{ofp_action_dl_addr}, $message);

							$action->{'dl_addr'} = $self->__format_pretty__hex_string($ofp_action_dl_addr->[2]);
						}
						elsif ($action_type eq q{OFPAT_SET_NW_SRC}) {
							my $ofp_action_nw_addr = $self->struct_decode($pdu_version, q{ofp_action_nw_addr}, $message);
							$pdu_length = $self->struct_chomp($pdu_version, q{ofp_action_nw_addr}, $message);

							$action->{'nw_addr'} = $ofp_action_nw_addr->[2];
						}
						elsif ($action_type eq q{OFPAT_SET_NW_DST}) {
							my $ofp_action_nw_addr = $self->struct_decode($pdu_version, q{ofp_action_nw_addr}, $message);
							$pdu_length = $self->struct_chomp($pdu_version, q{ofp_action_nw_addr}, $message);

							$action->{'nw_addr'} = $ofp_action_nw_addr->[2];
						}
						elsif ($action_type eq q{OFPAT_SET_NW_TOS}) {
							my $ofp_action_nw_tos = $self->struct_decode($pdu_version, q{ofp_action_nw_tos}, $message);
							$pdu_length = $self->struct_chomp($pdu_version, q{ofp_action_nw_tos}, $message);

							$action->{'nw_tos'} = $ofp_action_nw_tos->[2];
						}
						elsif ($action_type eq q{OFPAT_SET_TP_SRC}) {
							my $ofp_action_tp_port = $self->struct_decode($pdu_version, q{ofp_action_tp_port}, $message);
							$pdu_length = $self->struct_chomp($pdu_version, q{ofp_action_tp_port}, $message);

							$action->{'tp_port'} = $ofp_action_tp_port->[2];
						}
						elsif ($action_type eq q{OFPAT_SET_TP_DST}) {
							my $ofp_action_tp_port = $self->struct_decode($pdu_version, q{ofp_action_tp_port}, $message);
							$pdu_length = $self->struct_chomp($pdu_version, q{ofp_action_tp_port}, $message);

							$action->{'tp_port'} = $ofp_action_tp_port->[2];
						}
						elsif ($action_type eq q{OFPAT_ENQUEUE}) {
							my $ofp_action_enqueue = $self->struct_decode($pdu_version, q{ofp_action_enqueue}, $message);
							$pdu_length = $self->struct_chomp($pdu_version, q{ofp_action_enqueue}, $message);

							$action->{'port'} = $ofp_action_enqueue->[2];
							$action->{'queue_id'} = $ofp_action_enqueue->[3];
						}
						elsif ($action_type eq q{OFPAT_VENDOR}) {
							my $ofp_action_vendor = $self->struct_decode($pdu_version, q{ofp_action_vendor}, $message);
							$pdu_length = $self->struct_chomp($pdu_version, q{ofp_action_vendor}, $message);
						}
						else {
						}

						push @{$actions}, $action;

						$remaining_bytes -= $action_length;
					}
				}

				push @{$ret->{'body'}}, {
					length => $struct_values->[0],
					table_id => $struct_values->[1],
					match => $self->struct_decode__ofp_match($pdu_version, \$struct_values->[2]),
					duration_sec => $struct_values->[3],
					duration_nsec => $struct_values->[4],
					priority => $struct_values->[5],
					idle_timeout => $struct_values->[6],
					hard_timeout => $struct_values->[7],
					cookie => $struct_values->[8],
					packet_count => $struct_values->[9],
					byte_count => $struct_values->[10],
					actions => $actions,
				};
			}
		}
		elsif ($ofpst eq q{OFPST_TABLE}) {
			if (($pdu_length % $self->struct_sizeof($pdu_version, q{ofp_table_stats})) == 0) {
				while ($pdu_length) {
					my $struct_values = $self->struct_decode($pdu_version, q{ofp_table_stats}, $message);
					$pdu_length = $self->struct_chomp($pdu_version, q{ofp_table_stats}, $message);

					push @{$ret->{'body'}}, {
						table_id => $struct_values->[0],
						name => $struct_values->[1],
						wildcards => $struct_values->[2],
						max_entries => $struct_values->[3],
						active_count => $struct_values->[4],
						lookup_count => $struct_values->[5],
						matched_count => $struct_values->[6],
					};
				}
			}
			else {
			}
		}
		elsif ($ofpst eq q{OFPST_PORT}) {
			if (($pdu_length % $self->struct_sizeof($pdu_version, q{ofp_port_stats})) == 0) {
				while ($pdu_length) {
					my $struct_values = $self->struct_decode($pdu_version, q{ofp_port_stats}, $message);
					$pdu_length = $self->struct_chomp($pdu_version, q{ofp_port_stats}, $message);

					push @{$ret->{'body'}}, {
						port_no => $struct_values->[0],
						rx_packets => $struct_values->[1],
						tx_packets => $struct_values->[2],
						rx_bytes => $struct_values->[3],
						tx_bytes => $struct_values->[4],
						rx_dropped => $struct_values->[5],
						tx_dropped => $struct_values->[6],
						rx_errors => $struct_values->[7],
						tx_errors => $struct_values->[8],
						rx_frame_err => $struct_values->[9],
						rx_over_err => $struct_values->[10],
						rx_crc_err => $struct_values->[11],
						collisions => $struct_values->[12],
					};
				}
			}
			else {
			}
		}
		else {
			carp qq{Invalid OFPST type [$ofpst]};
		}
	}
	elsif ($pdu_type eq q{OFPT_VENDOR}) {
	}
	else {
		carp qq{Invalid type [$pdu_version][$pdu_type]};
	}

	return $ret;
}

=item C<< ofpt_encode >>

This function encodes OpenFlow messages.
The inputs are the OpenFlow protocol version, the type of message to be encoded, the xid, arguements to the type of message and any message body.
The struct_args are the members of the relevant OpenFlow struct. THe struct_body is any optional payload that will be attached to the message.

my $ret = $ofp->ofpt_encode($of_version, $of_type, $xid, $struct_args, $struct_body);

=cut

sub ofpt_encode($$$;$$) {
	my $self = shift;
	my ($version, $type, $xid, $struct_args, $struct_body) = @_;

	if (defined $struct_args) {
		unless (ref($struct_args) eq q{ARRAY}) {
			croak qq{Invalid struct args [$version][$type][$xid]};
		}
	}

	my $ret;

	my $ofp_type;

	if ($type =~ m{^\d+$}) {
		$ofp_type = $self->enum_lookup($version, q{ofp_type}, $type);
	}
	else {
		$ofp_type = $type;

		$type = $self->enum_lookup__by_value($version, q{ofp_type}, $ofp_type);
	}

	if ($ofp_type eq q{OFPT_HELLO}) {
		$ret = $self->struct_encode(
			$version,
			q{ofp_header},
			[
				$version,
				$type,
				$self->struct_sizeof($version, q{ofp_header}),
				$xid
			]
		);
	}
	elsif ($ofp_type eq q{OFPT_ERROR}) {
		if (scalar(@{$struct_args}) == 2) {
			unshift @{$struct_args}, $self->struct_encode(
				$version,
				q{ofp_header},
				[
					$version,
					$type,
					($self->struct_sizeof($version, q{ofp_error_msg}) + length(($struct_body // q{}))),
					$xid
				]
			);
		}

		$ret = $self->struct_encode($version, q{ofp_error_msg}, @{$struct_args}, $struct_body);
	}
	elsif ($ofp_type eq q{OFPT_ECHO_REQUEST}) {
		$ret = $self->struct_encode(
			$version,
			q{ofp_header},
			[
				$version,
				$type,
				($self->struct_sizeof($version, q{ofp_header}) + length(($struct_body // q{}))),
				$xid
			],
			$struct_body,
		);
	}
	elsif ($ofp_type eq q{OFPT_ECHO_REPLY}) {
		$ret = $self->struct_encode(
			$version,
			q{ofp_header},
			[
				$version,
				$type,
				($self->struct_sizeof($version, q{ofp_header}) + length(($struct_body // q{}))),
				$xid
			],
			$struct_body,
		);
	}
	elsif ($ofp_type eq q{OFPT_VENDOR}) {
	}
	elsif ($ofp_type eq q{OFPT_FEATURES_REQUEST}) {
		$ret = $self->struct_encode(
			$version,
			q{ofp_header},
			[
				$version,
				$type,
				$self->struct_sizeof($version, q{ofp_header}),
				$xid
			],
		);
	}
	elsif ($ofp_type eq q{OFPT_FEATURES_REPLY}) {
# N/A
	}
	elsif ($ofp_type eq q{OFPT_GET_CONFIG_REQUEST}) {
		$ret = $self->struct_encode(
			$version,
			q{ofp_header},
			[
				$version,
				$type,
				$self->struct_sizeof($version, q{ofp_header}),
				$xid
			]
		);
	}
	elsif ($ofp_type eq q{OFPT_GET_CONFIG_REPLY}) {
# N/A
	}
	elsif ($ofp_type eq q{OFPT_SET_CONFIG}) {
	}
	elsif ($ofp_type eq q{OFPT_PACKET_IN}) {
# N/A
	}
	elsif ($ofp_type eq q{OFPT_FLOW_REMOVED}) {
# N/A
	}
	elsif ($ofp_type eq q{OFPT_PORT_STATUS}) {
# N/A
	}
	elsif ($ofp_type eq q{OFPT_PACKET_OUT}) {
		if (scalar(@{$struct_args}) == 3) {
			unshift @{$struct_args}, $self->struct_encode(
				$version,
				q{ofp_header},
				[
					$version,
					$type,
					($self->struct_sizeof($version, q{ofp_packet_out}) + length(($struct_body // q{}))),
					$xid
				]
			);
		}

		$ret = $self->struct_encode($version, q{ofp_packet_out}, $struct_args, $struct_body);
	}
	elsif ($ofp_type eq q{OFPT_FLOW_MOD}) {
		if (scalar(@{$struct_args}) == 9) {
			unshift @{$struct_args}, $self->struct_encode(
				$version,
				q{ofp_header},
				[
					$version,
					$type,
					($self->struct_sizeof($version, q{ofp_flow_mod}) + length(($struct_body // q{}))),
					$xid
				]
			);
		}

		$ret = $self->struct_encode($version, q{ofp_flow_mod}, $struct_args, $struct_body);
	}
	elsif ($ofp_type eq q{OFPT_PORT_MOD}) {
		if (scalar(@{$struct_args}) == 5) {
			unshift @{$struct_args}, $self->struct_encode(
				$version,
				q{ofp_header},
				[
					$version,
					$type,
					($self->struct_sizeof($version, q{ofp_port_mod}) + length(($struct_body // q{}))),
					$xid
				]
			);
		}

		$ret = $self->struct_encode($version, q{ofp_port_mod}, $struct_args);
	}
	elsif ($ofp_type eq q{OFPT_STATS_REQUEST}) {
		if (scalar(@{$struct_args}) == 2) {
			unshift @{$struct_args}, $self->struct_encode(
				$version,
				q{ofp_header},
				[
					$version,
					$type,
					($self->struct_sizeof($version, q{ofp_stats_request}) + length(($struct_body // q{}))),
					$xid
				]
			);
		}

		$ret = $self->struct_encode($version, q{ofp_stats_request}, $struct_args, $struct_body);
	}
	elsif ($ofp_type eq q{OFPT_STATS_REPLY}) {
# N/A
	}
	elsif ($ofp_type eq q{OFPT_BARRIER_REQUEST}) {
		$ret = $self->struct_encode(
			$version,
			q{ofp_header},
			[
				$version,
				$type,
				$self->struct_sizeof($version, q{ofp_header}),
				$xid
			]
		);
	}
	elsif ($ofp_type eq q{OFPT_BARRIER_REPLY}) {
# N/A
	}
	elsif ($ofp_type eq q{OFPT_QUEUE_GET_CONFIG_REQUEST}) {
		if (scalar(@{$struct_args}) == 1) {
			unshift @{$struct_args}, $self->struct_encode(
				$version,
				q{ofp_header},
				[
					$version,
					$type,
					$self->struct_sizeof($version, q{ofp_queue_get_config_request}),
					$xid
				]
			);
		}

		$ret = $self->struct_encode($version, q{ofp_queue_get_config_request}, $struct_args);
	}
	elsif ($ofp_type eq q{OFPT_QUEUE_GET_CONFIG_REPLY}) {
# N/A
	}
	else {
		croak qq{Invalid ofp type [$version][$ofp_type]};
	}

	return $ret;
}

sub struct_chomp($$$$) {
	my $self = shift;
	my ($version, $struct_type, $struct_data) = @_;

	my $struct_type__length = $self->struct_sizeof($version, $struct_type);

	${$struct_data} = substr(${$struct_data}, $struct_type__length, (length(${$struct_data}) - $struct_type__length));

	my $ret = length(${$struct_data});

	return $ret;
}

sub struct_decode($$$$) {
	my $self = shift;
	my ($version, $struct_type, $struct_data) = @_;

	unless (defined($struct_types->{$struct_type}{$version}) and (ref($struct_types->{$struct_type}{$version}) eq q{HASH})) {
		croak qq{Invalid struct type [$version][$struct_type]};
	}

	unless (defined($struct_data) and (ref($struct_data) eq q{SCALAR})) {
		croak qq{Invalid struct data [$struct_type]};
	}

	my $ret;

	my $struct_data__length = length(${$struct_data});
	my $struct_type__length = $self->struct_sizeof($version, $struct_type);

	if ($struct_data__length >= $struct_type__length) {
		$ret = [unpack($struct_types->{$struct_type}{$version}{'format'}, ${$struct_data})];
	}
	else {
		croak qq{sizeof($struct_type) < $struct_type__length [$struct_data__length]};
	}

	return $ret;
}

sub struct_decode__ofp_header($$) {
	my $self = shift;
	my ($struct_data) = @_;

	my $ofp_header = $self->struct_decode(0x01, q{ofp_header}, $struct_data);

	my $ret = {
		version => $ofp_header->[0],
		type => $ofp_header->[1],
		length => $ofp_header->[2],
		xid => $ofp_header->[3],
	};

	return $ret;
}

sub struct_decode__ofp_match($$$) {
	my $self = shift;
	my ($version, $struct_data) = @_;

	my $ofp_match = $self->struct_decode($version, q{ofp_match}, $struct_data);

	my $ret;

	if ($version == 0x01) {
		$ret = {
			wildcards => $ofp_match->[0],
			in_port => $ofp_match->[1],
			dl_src => $self->__format_pretty__hex_string($ofp_match->[2]),
			dl_dst => $self->__format_pretty__hex_string($ofp_match->[3]),
			dl_vlan => $ofp_match->[4],
			dl_vlan_pcp => $ofp_match->[5],
			dl_type => sprintf(q{0x%0.4x}, $ofp_match->[6]),
			nw_tos => $ofp_match->[7],
			nw_proto => $ofp_match->[8],
			nw_src => $ofp_match->[9],
			nw_dst => $ofp_match->[10],
			tp_src => $ofp_match->[11],
			tp_dst => $ofp_match->[12],
		};
	}
	elsif ($version == 0x02) {
		$ret = {
			type => $ofp_match->[0],
			length => $ofp_match->[1],
			in_port => $ofp_match->[2],
			wildcards => $ofp_match->[3],
			dl_src => $self->__format_pretty__hex_string($ofp_match->[4]),
			dl_src_mask => $ofp_match->[5],
			dl_dst => $self->__format_pretty__hex_string($ofp_match->[6]),
			dl_dst_mask => $ofp_match->[7],
			dl_vlan => $ofp_match->[8],
			dl_vlan_pcp => $ofp_match->[9],
			dl_type => sprintf(q{0x%0.4x}, $ofp_match->[10]),
			nw_tos => $ofp_match->[11],
			nw_proto => $ofp_match->[12],
			nw_src => $ofp_match->[13],
			nw_src_mask => $ofp_match->[14],
			nw_dst => $ofp_match->[15],
			nw_dst_mask => $ofp_match->[16],
			tp_src => $ofp_match->[17],
			tp_dst => $ofp_match->[18],
			mpls_label => $ofp_match->[19],
			mpls_tc => $ofp_match->[20],
			metadata => $ofp_match->[21],
			metadata_mask => $ofp_match->[22],
		};
	}
	else {
		croak qq{Unsupported version [$version]};
	}

	foreach my $wildcard (@{$self->bitfield_decode($version, q{ofp_flow_wildcards}, $ret->{'wildcards'})}) {
		if ($wildcard eq q{OFPFW_IN_PORT}) {
			if ($ret->{'in_port'} == 0) {
				$ret->{'in_port'} = q{*};
			}
		}
		elsif ($wildcard eq q{OFPFW_DL_VLAN}) {
			if ($ret->{'dl_vlan'} == 0) {
				$ret->{'dl_vlan'} = q{*};
			}
		}
		elsif ($wildcard eq q{OFPFW_DL_SRC}) {
			if ($ret->{'dl_src'} == 0) {
				$ret->{'dl_src'} = q{*};
			}
		}
		elsif ($wildcard eq q{OFPFW_DL_DST}) {
			if ($ret->{'dl_dst'} == 0) {
				$ret->{'dl_dst'} = q{*};
			}
		}
		elsif ($wildcard eq q{OFPFW_DL_TYPE}) {
			if ($ret->{'dl_type'} == 0) {
				$ret->{'dl_type'} = q{*};
			}
		}
		elsif ($wildcard eq q{OFPFW_NW_PROTO}) {
			if ($ret->{'nw_proto'} == 0) {
				$ret->{'nw_proto'} = q{*};
			}
		}
		elsif ($wildcard eq q{OFPFW_TP_SRC}) {
			if ($ret->{'tp_src'} == 0) {
				$ret->{'tp_src'} = q{*};
			}
		}
		elsif ($wildcard eq q{OFPFW_TP_DST}) {
			if ($ret->{'tp_dst'} == 0) {
				$ret->{'tp_dst'} = q{*};
			}
		}
		elsif ($wildcard eq q{OFPFW_DL_VLAN_PCP}) {
			if ($ret->{'dl_vlan_pcp'} == 0) {
				$ret->{'dl_vlan_pcp'} = q{*};
			}
		}
		elsif ($wildcard eq q{OFPFW_NW_TOS}) {
			if ($ret->{'nw_tos'} == 0) {
				$ret->{'nw_tos'} = q{*};
			}
		}
	}

	return $ret;
}

sub struct_decode__ofp_phy_port($$$) {
	my $self = shift;
	my ($version, $struct_data) = @_;

	my $ofp_phy_port = $self->struct_decode($version, q{ofp_phy_port}, $struct_data);

	my $ret = {
		port_no => $ofp_phy_port->[0],
		hw_addr => $self->__format_pretty__hex_string($ofp_phy_port->[1]),
		name => $ofp_phy_port->[2],
		config => $ofp_phy_port->[3],
		state => $ofp_phy_port->[4],
		curr => $ofp_phy_port->[5],
		advertised => $ofp_phy_port->[6],
		supported => $ofp_phy_port->[7],
		peer => $ofp_phy_port->[8],
	};

	return $ret;
}

sub struct_encode($$$;$$) {
	my $self = shift;
	my ($version, $struct_type, $struct_args, $struct_body) = @_;

	unless (defined($struct_types->{$struct_type}{$version}) and (ref($struct_types->{$struct_type}{$version}) eq q{HASH})) {
		croak qq{Invalid struct type [$version][$struct_type]};
	}

	my $ret;

	$ret = pack($struct_types->{$struct_type}{$version}{'format'}, @{$struct_args});

	my $ret_length = length($ret);
	my $struct_type__length = $self->struct_sizeof($version, $struct_type);

	unless ($ret_length == $struct_type__length) {
		carp qq{sizeof(struct $struct_type) != $struct_type__length [$ret_length]};
	}

	if (defined $struct_body) {
		$ret .= $struct_body;
	}

	return $ret;
}

sub struct_encode__ofp_match($$$) {
	my $self = shift;
	my ($version, $ofp_match) = @_;

	my $wildcards = ($ofp_match->{'wildcards'} // $self->bitfield_encode(
			$version,
			q{ofp_flow_wildcards},
			[
				q{OFPFW_ALL},
			],
		)
	);
	my $in_port = ($ofp_match->{'in_port'} // 0);
	my $dl_src = ($ofp_match->{'dl_src'} // 0);
	my $dl_dst = ($ofp_match->{'dl_dst'} // 0);
	my $dl_vlan = ($ofp_match->{'dl_vlan'} // 0);
	my $dl_vlan_pcp = ($ofp_match->{'dl_vlan_pcp'} // 0);
	my $dl_type = ($ofp_match->{'dl_type'} // 0);
	my $nw_tos = ($ofp_match->{'nw_tos'} // 0);
	my $nw_proto = ($ofp_match->{'nw_proto'} // 0);
	my $nw_src = ($ofp_match->{'nw_src'} // 0);
	my $nw_dst = ($ofp_match->{'nw_dst'} // 0);
	my $tp_src = ($ofp_match->{'tp_src'} // 0);
	my $tp_dst = ($ofp_match->{'tp_dst'} // 0);

	my $ret = $self->struct_encode(
		$version,
		q{ofp_match},
		[
			$wildcards,
			$in_port,
			$dl_src,
			$dl_dst,
			$dl_vlan,
			$dl_vlan_pcp,
			$dl_type,
			$nw_tos,
			$nw_proto,
			$nw_src,
			$nw_dst,
			$tp_src,
			$tp_dst,
		]
	);

	return $ret;
}

sub struct_sizeof($$$) {
	my $self = shift;
	my ($version, $struct_type) = @_;

	my $ret = $struct_types->{$struct_type}{$version}{'length'};

	return $ret;
}

sub __format_pretty__arrayref {
	my $self = shift;
	my $a = shift;

	my $ret = [];

	foreach (@{$a}) {
		if (ref($_) eq q{ARRAY}) {
			push @{$ret}, (q{[} . join(q{, }, @{$self->__format_pretty__arrayref($_)}) . q{]});
		}
		elsif (ref($_) eq q{SCALAR}) {
			push @{$ret}, $self->__format_pretty__bit_string(${$_});
		}
		else {
			push @{$ret}, $self->__format_pretty__bit_string($_);
		}
	}

	return $ret;
}

sub __format_pretty__bit_string {
	my $self = shift;
	my ($bit_string, $len) = @_;

	$len //= 16;

	my $ret;

	if (defined $bit_string) {
		if ($bit_string =~ /^[\x20-\x7e]+$/) {
			$ret = $bit_string;
		}
		else {
			$ret = (q/{/ . $self->__hex_preview($bit_string, $len) . q/}:/ . length($bit_string));
		}
	}
	else {
		$ret = q{undef};
	}

	return $ret;
}

sub __format_pretty__hex_string {
	my $self = shift;
	my $hex_string = shift;

	my $ret = join(q{:}, unpack(q{(a2)*}, $hex_string));

	return $ret;
}

sub __hex_preview($$$) {
	my $self = shift;
	my ($data, $len) = @_;

	$len //= 8;

	return join(q{ }, unpack(q{(a2)*}, unpack(qq{H$len}, $data)));
}

=back

=cut

package Net::OpenFlow::Protocol::Debug;

use parent qw{Net::OpenFlow::Protocol};
use strict;
use warnings;


sub bitfield_decode($$$$) {
	my $self = shift;
	my ($version, $enum_type, $bitfield) = @_;

	my $ret = $self->SUPER::bitfield_decode($version, $enum_type, $bitfield);

	print STDERR $self->__function_debug(q{bitfield_decode}, $ret, [$version, $enum_type, $bitfield]) . qq{\n};

	return $ret;
}


sub bitfield_encode($$$$) {
	my $self = shift;
	my ($version, $enum_type, $bits) = @_;

	my $ret = $self->SUPER::bitfield_encode($version, $enum_type, $bits);

	print STDERR $self->__function_debug(q{bitfield_encode}, $ret, [$version, $enum_type, $bits]) . qq{\n};

	return $ret;
}

sub enum_lookup($$$$) {
	my $self = shift;
	my ($version, $enum_type, $lookup) = @_;

	my $ret = $self->SUPER::enum_lookup($version, $enum_type, $lookup);

	print STDERR $self->__function_debug(q{enum_lookup}, $ret, [$version, $enum_type, $lookup]) . qq{\n};

	return $ret;
}

sub enum_lookup__by_value($$$$) {
	my $self = shift;

	my $ret = $self->SUPER::enum_lookup__by_value(@_);

	print STDERR $self->__function_debug(q{enum_lookup__by_value}, $ret, [@_]) . qq{\n};

	return $ret;
}

sub ofpt_encode($$$;$$) {
	my $self = shift;

	my $ret = $self->SUPER::ofpt_encode(@_);

	print STDERR $self->__function_debug(q{ofpt_encode}, $self->__format_pretty__bit_string($ret), [@_]) . qq{\n};

	return $ret;
}

sub ofpt_decode($$) {
	my $self = shift;
	my $message = shift;

	my $__debug__message = $self->__format_pretty__bit_string(${$message});

	my $ret = $self->SUPER::ofpt_decode($message);

	print STDERR $self->__function_debug(q{ofpt_decode}, $ret, [$__debug__message]) . qq{\n};

	return $ret;
}

sub struct_chomp($$$$) {
	my $self = shift;
	my ($version, $struct_type, $struct_data) = @_;

	my $ret = $self->SUPER::struct_chomp($version, $struct_type, $struct_data);

	print STDERR $self->__function_debug(q{struct_chomp}, $ret, [$version, $struct_type, $self->__format_pretty__bit_string(${$struct_data})]) . qq{\n};

	return $ret;
}

sub struct_encode($$$;$$) {
	my $self = shift;
	my ($version, $struct_type, $struct_args, $struct_body) = @_;

	my $ret = $self->SUPER::struct_encode($version, $struct_type, $struct_args, $struct_body);

	print STDERR $self->__function_debug(q{struct_encode}, $self->__format_pretty__bit_string($ret, 32), [$version, $struct_type, $struct_args, $struct_body]) . qq{\n};

	return $ret;
}

sub struct_decode($$$$) {
	my $self = shift;
	my ($version, $struct_type, $struct_data) = @_;

	my $__debug__struct_data = $self->__format_pretty__bit_string(${$struct_data});

	my $ret = $self->SUPER::struct_decode($version, $struct_type, $struct_data);

	print STDERR $self->__function_debug(q{struct_decode}, $ret, [$version, $struct_type, $__debug__struct_data]) . qq{\n};

	return $ret;
}

sub __function_debug {
	my $self = shift;
	my ($name, $retval, $args) = @_;

	$name //= q{UNKNOWN};
	$retval //= q{undef};
	$args //= q{};

	my $formatted_retval;

	if (ref($retval) eq q{ARRAY}) {
		$formatted_retval = join(q{, }, @{$self->__format_pretty__arrayref($retval)});
	}
	elsif (ref($retval) eq q{SCALAR}) {
		$formatted_retval = ${$retval};
	}
	else {
		$formatted_retval = $retval;
	}

	my $formatted_args;

	if (ref($args) eq q{ARRAY}) {
		$formatted_args = join(q{, }, @{$self->__format_pretty__arrayref($args)});
	}
	else {
		$formatted_args = $args;
	}

	return ((ref($self) or $self) . q{::} . $name . qq{($formatted_args) = [$formatted_retval]});
}

1;
