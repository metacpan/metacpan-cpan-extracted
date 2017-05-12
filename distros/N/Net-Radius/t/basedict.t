#!/usr/bin/perl

# Test the simple parsing of the dictionaries enclosed with this
# distribution

# $Id: basedict.t 27 2006-08-09 16:00:01Z lem $

use IO::File;
#use Data::Dumper;
use Test::More;
use Net::Radius::Dictionary;

my $dictfile = "dict$$.tmp";

END 
{
    unlink $dictfile;
};

my @dicts = ();

{
    local $/ = "EOD\n";
    @dicts = map { (s/EOD\n$//, $_)[1] } <DATA>;
};

sub _write
{
    my $dict = shift;
    my $fh = new IO::File;
    $fh->open($dictfile, "w") or diag "Failed to write dict $dictfile: $!";
    print $fh $dict;
    $fh->close;
}

plan tests => 18 * scalar @dicts;

for my $i (0 .. $#dicts)
{
    _write($dicts[$i]);
    my $d = undef;
    eval { $d = Net::Radius::Dictionary->new($dictfile); };
    isa_ok($d, 'Net::Radius::Dictionary');
    ok(!$@, "No errors or warnings during parse");
    diag $@ if $@;
#    print Data::Dumper->Dump([$d]);
    for my $k (qw(attr rattr val rval vsattr vsaval rvsaval vendors))
    {
	ok(exists $d->{$k}, "->{$k}");
	isa_ok($d->{$k}, "HASH");
    }
}


__END__
# Simple vendor example
VENDORATTR	9	cisco-avpair	1	string
VENDORATTR	9	cisco-funny	2	integer
VENDORVALUE	9	cisco-funny	foo		1
VENDORVALUE	9	cisco-funny	bar		2
VENDORVALUE	9	cisco-funny	baz		3
EOD
# FreeRadius vendor syntax
VENDOR		Cisco			9
ATTRIBUTE	cisco-avpair		1	string	Cisco
ATTRIBUTE	cisco-funny		2	integer	Cisco
VALUE		cisco-funny	foo	1
VALUE		cisco-funny	bar	2
VALUE		cisco-funny	baz	3
EOD
# This is the enclosed dictionary file...
ATTRIBUTE	User-Name		1	string
ATTRIBUTE	User-Password		2	string
ATTRIBUTE	CHAP-Password		3	string
ATTRIBUTE	NAS-IP-Address		4	ipaddr
ATTRIBUTE	NAS-Port		5	integer
ATTRIBUTE	Service-Type		6	integer
ATTRIBUTE	Framed-Protocol		7	integer
ATTRIBUTE	Framed-IP-Address	8	ipaddr
ATTRIBUTE	Framed-IP-Netmask	9	ipaddr
ATTRIBUTE	Framed-Routing		10	integer
ATTRIBUTE	Filter-Id		11	string
ATTRIBUTE	Framed-MTU		12	integer
ATTRIBUTE	Framed-Compression	13	integer
ATTRIBUTE	Login-IP-Host		14	ipaddr
ATTRIBUTE	Login-Service		15	integer
ATTRIBUTE	Login-TCP-Port		16	integer
ATTRIBUTE	Reply-Message		18	string
ATTRIBUTE	Callback-Number		19	string
ATTRIBUTE	Callback-Id		20	string
ATTRIBUTE	Expiration		21	date
ATTRIBUTE	Framed-Route		22	string
ATTRIBUTE	Framed-IPX-Network	23	ipaddr
ATTRIBUTE	State			24	string
ATTRIBUTE	Session-Timeout		27	integer
ATTRIBUTE	Idle-Timeout		28	integer
ATTRIBUTE	Termination-Action	29	integer
ATTRIBUTE	Called-Station-Id	30	string
ATTRIBUTE	Calling-Station-Id	31	string
ATTRIBUTE	Acct-Status-Type	40	integer
ATTRIBUTE	Acct-Delay-Time		41	integer
ATTRIBUTE	Acct-Input-Octets	42	integer
ATTRIBUTE	Acct-Output-Octets	43	integer
ATTRIBUTE	Acct-Session-Id		44	string
ATTRIBUTE	Acct-Authentic		45	integer
ATTRIBUTE	Acct-Session-Time	46	integer
ATTRIBUTE	Acct-Terminate-Cause	49	integer
ATTRIBUTE	NAS-Port-Type		61	integer
ATTRIBUTE	Port-Limit		62	integer


#
#	Integer Translations
#

#	User Types

VALUE		Service-Type	Login-User		1
VALUE		Service-Type	Framed-User		2
VALUE		Service-Type	Callback-Login-User	3
VALUE		Service-Type	Callback-Framed-User	4
VALUE		Service-Type	Outbound-User		5
VALUE		Service-Type	Administrative-User	6
VALUE		Service-Type	NAS-Prompt-User		7

#	Framed Protocols

VALUE		Framed-Protocol		PPP			1
VALUE		Framed-Protocol		SLIP			2

#	Framed Routing Values

VALUE		Framed-Routing		None			0
VALUE		Framed-Routing		Broadcast		1
VALUE		Framed-Routing		Listen			2
VALUE		Framed-Routing		Broadcast-Listen	3

#	Framed Compression Types

VALUE		Framed-Compression	None			0
VALUE		Framed-Compression	Van-Jacobson-TCP-IP	1

#	Login Services

VALUE		Login-Service		Telnet			0
VALUE		Login-Service		Rlogin			1
VALUE		Login-Service		TCP-Clear		2
VALUE		Login-Service		PortMaster		3

#	Status Types

VALUE		Acct-Status-Type	Start			1
VALUE		Acct-Status-Type	Stop			2

#	Authentication Types

VALUE		Acct-Authentic		RADIUS			1
VALUE		Acct-Authentic		Local			2
VALUE		Acct-Authentic		PowerLink128		100

#	Termination Options

VALUE		Termination-Action	Default			0
VALUE		Termination-Action	RADIUS-Request		1

#	NAS Port Types, available in ComOS 3.3.1 and later

VALUE		NAS-Port-Type		Async			0
VALUE		NAS-Port-Type		Sync			1
VALUE		NAS-Port-Type		ISDN			2
VALUE		NAS-Port-Type		ISDN-V120		3
VALUE		NAS-Port-Type		ISDN-V110		4

#	Acct Terminate Causes, available in ComOS 3.3.2 and later

VALUE		Acct-Terminate-Cause	User-Request		1
VALUE		Acct-Terminate-Cause	Lost-Carrier		2
VALUE		Acct-Terminate-Cause	Lost-Service		3
VALUE		Acct-Terminate-Cause	Idle-Timeout		4
VALUE		Acct-Terminate-Cause	Session-Timeout		5
VALUE		Acct-Terminate-Cause	Admin-Reset		6
VALUE		Acct-Terminate-Cause	Admin-Reboot		7
VALUE		Acct-Terminate-Cause	Port-Error		8
VALUE		Acct-Terminate-Cause	NAS-Error		9
VALUE		Acct-Terminate-Cause	NAS-Request		10
VALUE		Acct-Terminate-Cause	NAS-Reboot		11
VALUE		Acct-Terminate-Cause	Port-Unneeded		12
VALUE		Acct-Terminate-Cause	Port-Preempted		13
VALUE		Acct-Terminate-Cause	Port-Suspended		14
VALUE		Acct-Terminate-Cause	Service-Unavailable	15
VALUE		Acct-Terminate-Cause	Callback		16
VALUE		Acct-Terminate-Cause	User-Error		17
VALUE		Acct-Terminate-Cause	Host-Request		18


#
# Obsolete names for backwards compatibility with older users files
# If you want RADIUS accounting logs to use the new names instead of
# these, move this section to the beginning of the dictionary file
# and kill and restart radiusd
# If you don't have a RADIUS 1.16 users file that you're still using,
# you can delete or ignore this section.
#
ATTRIBUTE	Client-Id		4	ipaddr
ATTRIBUTE	Client-Port-Id		5	integer
ATTRIBUTE	User-Service-Type	6	integer
ATTRIBUTE	Framed-Address		8	ipaddr
ATTRIBUTE	Framed-Netmask		9	ipaddr
ATTRIBUTE	Framed-Filter-Id	11	string
ATTRIBUTE	Login-Host		14	ipaddr
ATTRIBUTE	Login-Port		16	integer
ATTRIBUTE	Old-Password		17	string
ATTRIBUTE	Port-Message		18	string
ATTRIBUTE	Dialback-No		19	string
ATTRIBUTE	Dialback-Name		20	string
ATTRIBUTE	Challenge-State		24	string
VALUE		Service-Type		Dialback-Login-User	3
VALUE		Service-Type		Dialback-Framed-User	4
VALUE		Service-Type		Shell-User		6
VALUE		Framed-Compression	Van-Jacobsen-TCP-IP	1

VENDORATTR	9	cisco-avpair	1	string
EOD
# This is the distributed dictionary.3com file...
ATTRIBUTE	User-Name		1	string
ATTRIBUTE	User-Password		2	string
ATTRIBUTE	CHAP-Password		3	string
ATTRIBUTE	NAS-IP-Address		4	ipaddr
ATTRIBUTE	NAS-Port		5	integer
ATTRIBUTE	Service-Type		6	integer
ATTRIBUTE	Framed-Protocol		7	integer
ATTRIBUTE	Framed-IP-Address	8	ipaddr
ATTRIBUTE	Framed-IP-Netmask	9	ipaddr
ATTRIBUTE	Framed-Routing		10	integer
ATTRIBUTE	Filter-Id		11	string
ATTRIBUTE	Framed-MTU		12	integer
ATTRIBUTE	Framed-Compression	13	integer
ATTRIBUTE	Login-IP-Host		14	ipaddr
ATTRIBUTE	Login-Service		15	integer
ATTRIBUTE	Login-TCP-Port		16	integer
ATTRIBUTE	Reply-Message		18	string
ATTRIBUTE	Callback-Number		19	string
ATTRIBUTE	Callback-Id		20	string
ATTRIBUTE	Expiration		21	date
ATTRIBUTE	Framed-Route		22	string
ATTRIBUTE	Framed-IPX-Network	23	ipaddr
ATTRIBUTE	State			24	string
ATTRIBUTE	Session-Timeout		27	integer
ATTRIBUTE	Idle-Timeout		28	integer
ATTRIBUTE	Termination-Action	29	integer
ATTRIBUTE	Called-Station-Id	30	string
ATTRIBUTE	Calling-Station-Id	31	string
ATTRIBUTE	NAS-Identifier		32	string
ATTRIBUTE	Acct-Status-Type	40	integer
ATTRIBUTE	Acct-Delay-Time		41	integer
ATTRIBUTE	Acct-Input-Octets	42	integer
ATTRIBUTE	Acct-Output-Octets	43	integer
ATTRIBUTE	Acct-Session-Id		44	string
ATTRIBUTE	Acct-Authentic		45	integer
ATTRIBUTE	Acct-Session-Time	46	integer
ATTRIBUTE	Acct-Terminate-Cause	49	integer
ATTRIBUTE	NAS-Port-Type		61	integer
ATTRIBUTE	Port-Limit		62	integer


#
#	Integer Translations
#

#	User Types

VALUE		Service-Type	Login-User		1
VALUE		Service-Type	Framed-User		2
VALUE		Service-Type	Callback-Login-User	3
VALUE		Service-Type	Callback-Framed-User	4
VALUE		Service-Type	Outbound-User		5
VALUE		Service-Type	Administrative-User	6
VALUE		Service-Type	NAS-Prompt-User		7

#	Framed Protocols

VALUE		Framed-Protocol		PPP			1
VALUE		Framed-Protocol		SLIP			2

#	Framed Routing Values

VALUE		Framed-Routing		None			0
VALUE		Framed-Routing		Broadcast		1
VALUE		Framed-Routing		Listen			2
VALUE		Framed-Routing		Broadcast-Listen	3

#	Framed Compression Types

VALUE		Framed-Compression	None			0
VALUE		Framed-Compression	Van-Jacobson-TCP-IP	1

#	Login Services

VALUE		Login-Service		Telnet			0
VALUE		Login-Service		Rlogin			1
VALUE		Login-Service		TCP-Clear		2
VALUE		Login-Service		PortMaster		3

#	Status Types

VALUE		Acct-Status-Type	Start			1
VALUE		Acct-Status-Type	Stop			2

#	Authentication Types

VALUE		Acct-Authentic		RADIUS			1
VALUE		Acct-Authentic		Local			2
VALUE		Acct-Authentic		PowerLink128		100

#	Termination Options

VALUE		Termination-Action	Default			0
VALUE		Termination-Action	RADIUS-Request		1

#	NAS Port Types, available in ComOS 3.3.1 and later

VALUE		NAS-Port-Type		Async			0
VALUE		NAS-Port-Type		Sync			1
VALUE		NAS-Port-Type		ISDN			2
VALUE		NAS-Port-Type		ISDN-V120		3
VALUE		NAS-Port-Type		ISDN-V110		4

#	Acct Terminate Causes, available in ComOS 3.3.2 and later

VALUE		Acct-Terminate-Cause	User-Request		1
VALUE		Acct-Terminate-Cause	Lost-Carrier		2
VALUE		Acct-Terminate-Cause	Lost-Service		3
VALUE		Acct-Terminate-Cause	Idle-Timeout		4
VALUE		Acct-Terminate-Cause	Session-Timeout		5
VALUE		Acct-Terminate-Cause	Admin-Reset		6
VALUE		Acct-Terminate-Cause	Admin-Reboot		7
VALUE		Acct-Terminate-Cause	Port-Error		8
VALUE		Acct-Terminate-Cause	NAS-Error		9
VALUE		Acct-Terminate-Cause	NAS-Request		10
VALUE		Acct-Terminate-Cause	NAS-Reboot		11
VALUE		Acct-Terminate-Cause	Port-Unneeded		12
VALUE		Acct-Terminate-Cause	Port-Preempted		13
VALUE		Acct-Terminate-Cause	Port-Suspended		14
VALUE		Acct-Terminate-Cause	Service-Unavailable	15
VALUE		Acct-Terminate-Cause	Callback		16
VALUE		Acct-Terminate-Cause	User-Error		17
VALUE		Acct-Terminate-Cause	Host-Request		18


#
# Obsolete names for backwards compatibility with older users files
# If you want RADIUS accounting logs to use the new names instead of
# these, move this section to the beginning of the dictionary file
# and kill and restart radiusd
# If you don't have a RADIUS 1.16 users file that you're still using,
# you can delete or ignore this section.
#
ATTRIBUTE	Client-Id		4	ipaddr
ATTRIBUTE	Client-Port-Id		5	integer
ATTRIBUTE	User-Service-Type	6	integer
ATTRIBUTE	Framed-Address		8	ipaddr
ATTRIBUTE	Framed-Netmask		9	ipaddr
ATTRIBUTE	Framed-Filter-Id	11	string
ATTRIBUTE	Login-Host		14	ipaddr
ATTRIBUTE	Login-Port		16	integer
ATTRIBUTE	Old-Password		17	string
ATTRIBUTE	Port-Message		18	string
ATTRIBUTE	Dialback-No		19	string
ATTRIBUTE	Dialback-Name		20	string
ATTRIBUTE	Challenge-State		24	string
VALUE		Service-Type		Dialback-Login-User	3
VALUE		Service-Type		Dialback-Framed-User	4
VALUE		Service-Type		Shell-User		6
VALUE		Framed-Compression	Van-Jacobsen-TCP-IP	1
#VALUE		Auth-Type		Unix			1
#
# END of obsolete names for backwards compatibility
#

#
#	Configuration Values
#	uncomment out these two lines to turn account expiration on
#

#VALUE		Server-Config		Password-Expiration	30
#VALUE		Server-Config		Password-Warning	5

##
## VENDOR SPECIFIC ATTRIBUTES
##
## The following entries demonstrate the use of VSAs
##

# cisco-avpair is used for various functions by cisco IOS. Most
# notably, it's used to create VPDN tunnels.
#
VENDORATTR	9	cisco-avpair	1	string

# This is a fake attribute to demonstrate how to write named-value
# attributes.
#VENDORATTR	1	ibm-enum	254	integer
#VENDORVALUE	1	ibm-enum	value-1	1
#VENDORVALUE	1	ibm-enum	value-2	2
#VENDORVALUE	1	ibm-enum	value-3	3

#3COM specific values

#
# dictionary.usr	USR Robotics dictionary.
#
#		Taken from the dictionary included with the USR RADIUS server,
#		and adjusted a bit.
#
# Version:	@(#)dictionary.usr  1.10  11-Nov-1998  miquels@cistron.nl
#

#
#	USR specific attributes
#
# Prompt value should be 1 for echo, 0 for no echo, default 1.
#ATTRIBUTE	Prompt			64	integer
ATTRIBUTE	Multi-Link-Flag		126	integer
ATTRIBUTE	Char-Noecho		250	integer

#
#	USR specific Integer Translations
#

VALUE		Termination-Action	Manage-Resources	2

VALUE		Service-Type		Authenticate-User	8
VALUE		Service-Type		Dialback-NAS-User	9

VALUE		Acct-Status-Type	Modem-Start		4
VALUE		Acct-Status-Type	Modem-Stop		5
VALUE		Acct-Status-Type	Cancel			6

VALUE		Multi-Link-Flag		True			1
VALUE		Multi-Link-Flag		False			0

#	USR specific Authentication Types

VALUE		Acct-Authentic		None			0
VALUE		Acct-Authentic		Remote			3
VALUE		Acct-Authentic		RADIUS			4
VALUE		Acct-Authentic		MNET			5
VALUE		Acct-Authentic		KCHAP			6
VALUE		Acct-Authentic		TACACS			7
VALUE		Acct-Authentic		Realm			8
VALUE		Acct-Authentic		Local			9
VALUE		Acct-Authentic		File			10
VALUE		Acct-Authentic		Local-VPN		11

#
#	USR Extensions: USR Vendor-Specific stuff.
#
#	For now in NMC format (whatever that stands for), though the
#	normal vendor-specific format would work just as well.
#
#

#ATTRIB_NMC	USR-Last-Number-Dialed-Out		0x0066	string
VENDORATTR 	429	USR-Last-Number-Dialed-Out		0x0066	string
VENDORATTR 	429	USR-Last-Number-Dialed-In-DNIS		0x00E8	string
VENDORATTR 	429	USR-Last-Callers-Number-ANI		0x00E9	string
VENDORATTR 	429	USR-Channel				0xBF38	integer 
VENDORATTR 	429	USR-Event-Id				0xBFBE	integer
VENDORATTR 	429	USR-Event-Date-Time			0xBF2F	date
VENDORATTR 	429	USR-Call-Start-Date-Time		0xBFF7	date
VENDORATTR 	429	USR-Call-End-Date-Time			0xBFF6	date
VENDORATTR 	429	USR-Default-DTE-Data-Rate		0x005E	integer
VENDORATTR 	429	USR-Initial-Rx-Link-Data-Rate		0xBF2D	integer
VENDORATTR 	429	USR-Final-Rx-Link-Data-Rate		0xBF2C	integer
VENDORATTR 	429	USR-Initial-Tx-Link-Data-Rate		0x006A	integer
VENDORATTR 	429	USR-Final-Tx-Link-Data-Rate		0x006B	integer
VENDORATTR 	429	USR-Chassis-Temperature			0xBF31	integer
VENDORATTR 	429	USR-Chassis-Temp-Threshold		0xBE84	integer
VENDORATTR 	429	USR-Actual-Voltage			0xBF32	integer
VENDORATTR 	429	USR-Expected-Voltage			0xBF33	integer
VENDORATTR 	429	USR-Power-Supply-Number			0xBF34	integer
VENDORATTR 	429	USR-Card-Type				0xBE85	integer
VENDORATTR 	429	USR-Chassis-Slot			0xBF39	integer
VENDORATTR 	429	USR-Sync-Async-Mode			0x0067	integer
VENDORATTR 	429	USR-Originate-Answer-Mode		0x0068	integer
VENDORATTR 	429	USR-Modulation-Type			0x006C	integer
VENDORATTR 	429	USR-Connect-Term-Reason			0x009B	integer
VENDORATTR 	429	USR-Failure-to-Connect-Reason		0x0069	integer
VENDORATTR 	429	USR-Equalization-Type			0x006F	integer
VENDORATTR 	429	USR-Fallback-Enabled			0x0070	integer
VENDORATTR 	429	USR-Connect-Time-Limit			0xBFE7	integer
VENDORATTR 	429	USR-Number-of-Rings-Limit		0xBFE6	integer
VENDORATTR 	429	USR-DTE-Data-Idle-Timout		0x0048	integer
VENDORATTR 	429	USR-Characters-Sent			0x0071	integer
VENDORATTR 	429	USR-Characters-Received			0x0072	integer
VENDORATTR 	429	USR-Blocks-Sent				0x0075	integer
VENDORATTR 	429	USR-Blocks-Received			0x0076	integer
VENDORATTR 	429	USR-Blocks-Resent			0x0077	integer
VENDORATTR 	429	USR-Retrains-Requested			0x0078	integer
VENDORATTR 	429	USR-Retrains-Granted			0x0079	integer
VENDORATTR 	429	USR-Line-Reversals			0x007A	integer
VENDORATTR 	429	USR-Number-Of-Characters-Lost		0x007B	integer
VENDORATTR 	429	USR-Number-of-Blers			0x007D	integer
VENDORATTR 	429	USR-Number-of-Link-Timeouts		0x007E	integer
VENDORATTR 	429	USR-Number-of-Fallbacks			0x007F	integer
VENDORATTR 	429	USR-Number-of-Upshifts			0x0080	integer
VENDORATTR 	429	USR-Number-of-Link-NAKs			0x0081	integer
VENDORATTR 	429	USR-DTR-False-Timeout			0x00BE	integer
VENDORATTR 	429	USR-Fallback-Limit			0x00BF	integer
VENDORATTR 	429	USR-Block-Error-Count-Limit		0x00C0	integer
VENDORATTR 	429	USR-DTR-True-Timeout			0x00DA	integer
VENDORATTR 	429	USR-Security-Login-Limit		0xBEDE	integer
VENDORATTR 	429	USR-Security-Resp-Limit			0xBEFA	integer
VENDORATTR 	429	USR-DTE-Ring-No-Answer-Limit		0xBF17	integer
VENDORATTR 	429	USR-Back-Channel-Data-Rate		0x007C	integer
VENDORATTR 	429	USR-Simplified-MNP-Levels		0x0099	integer
VENDORATTR 	429	USR-Simplified-V42bis-Usage		0x00C7	integer
VENDORATTR 	429	USR-Mbi_Ct_PRI_Card_Slot		0x0184	integer
VENDORATTR 	429	USR-Mbi_Ct_TDM_Time_Slot		0x0185	integer
VENDORATTR 	429	USR-Mbi_Ct_PRI_Card_Span_Line		0x0186	integer
VENDORATTR 	429	USR-Mbi_Ct_BChannel_Used		0x0187	integer
VENDORATTR 	429	USR-Physical-State			0xBE77	integer
VENDORATTR 	429	USR-Packet-Bus-Session			0xBF14	integer
VENDORATTR 	429	USR-Server-Time				0xF000	date

# 0xBE5D-0xBE63 sent with Event-Id 79
VENDORATTR 	429	USR-Channel-Connected-To		0xBE5D	integer
VENDORATTR 	429	USR-Slot-Connected-To			0xBE5E	integer 
VENDORATTR 	429	USR-Device-Connected-To			0xBE5F	integer
VENDORATTR 	429	USR-NFAS-ID				0xBE60	integer
VENDORATTR 	429	USR-Q931-Call-Reference-Value		0xBE61	integer
VENDORATTR 	429	USR-Call-Event-Code			0xBE62	integer
VENDORATTR 	429	USR-DS0					0xBE63	integer
# DS0s sent with Event-Id 77,78
VENDORATTR 	429	USR-DS0s				0xBE64	string
# Gateway-IP-Address sent with Event-Id 71,72
VENDORATTR 	429	USR-Gateway-IP-Address			0xBE66	ipaddr


#
# These are CCA Radius attributes
#
VENDORATTR 	429	USR-PW_USR_IFilter_IP			0x9000	string
VENDORATTR 	429	USR-PW_USR_IFilter_IPX			0x9001	string
VENDORATTR 	429	USR-PW_USR_OFilter_IP			0x9003	string
VENDORATTR 	429	USR-PW_USR_OFilter_IPX			0x9004	string
VENDORATTR 	429	USR-PW_USR_OFilter_SAP			0x9005	string
VENDORATTR 	429	USR-PW_VPN_ID				0x9006	string
VENDORATTR 	429	USR-PW_VPN_Name				0x9007	string
VENDORATTR 	429	USR-PW_VPN_Neighbor			0x9008	string
VENDORATTR 	429	USR-PW_Framed_Routing_V2		0x9009	string
VENDORATTR 	429	USR-PW_VPN_Gateway			0x900a	string
VENDORATTR 	429	USR-PW_Tunnel_Authentication		0x900b	string
VENDORATTR 	429	USR-PW_Index				0x900c	string
VENDORATTR 	429	USR-PW_Cutoff				0x900d	string
VENDORATTR 	429	USR-PW_Packet				0x900e	string
VENDORATTR 	429	USR-Primary_DNS_Server			0x900f	ipaddr
VENDORATTR 	429	USR-Secondary_DNS_Server		0x9010	ipaddr
VENDORATTR 	429	USR-Primary_NBNS_Server			0x9011	ipaddr
VENDORATTR 	429	USR-Secondary_NBNS_Server		0x9012	ipaddr
VENDORATTR 	429	USR-Syslog-Tap				0x9013	integer
VENDORATTR 	429	USR-Chassis-Call-Slot			0x9019	integer
VENDORATTR 	429	USR-Chassis-Call-Span			0x901A	integer
VENDORATTR 	429	USR-Chassis-Call-Channel		0x901B	integer
VENDORATTR 	429	USR-Keypress-Timeout			0x901C	integer
VENDORATTR 	429	USR-Unauthenticated-Time		0x901D	integer
VENDORATTR 	429	USR-Connect-Speed			0x9023	integer
VENDORATTR 	429	USR-Framed_IP_Address_Pool_Name		0x9024	string
VENDORATTR 	429	USR-MP-EDO				0x9025	string	

#
# Pilgrim attributes
# 
VENDORATTR 	429	USR-Bearer-Capabilities			0x9800	integer
VENDORATTR 	429	USR-Speed-Of-Connection			0x9801	integer
VENDORATTR 	429	USR-Max-Channels			0x9802	integer
VENDORATTR 	429	USR-Channel-Expansion			0x9803	integer
VENDORATTR 	429	USR-Channel-Decrement			0x9804	integer
VENDORATTR 	429	USR-Expansion-Algorithm			0x9805	integer
VENDORATTR 	429	USR-Compression-Algorithm		0x9806	integer
VENDORATTR 	429	USR-Receive-Acc-Map			0x9807	integer
VENDORATTR 	429	USR-Transmit-Acc-Map			0x9808	integer
VENDORATTR 	429	USR-Compression-Reset-Mode		0x980a	integer
VENDORATTR 	429	USR-Min-Compression-Size		0x980b	integer
VENDORATTR 	429	USR-IP					0x980c	integer
VENDORATTR 	429	USR-IPX					0x980d	integer
VENDORATTR 	429	USR-Filter-Zones			0x980e	integer
VENDORATTR 	429	USR-Appletalk				0x980f	integer
VENDORATTR 	429	USR-Bridging				0x9810	integer
VENDORATTR 	429	USR-Spoofing				0x9811	integer
VENDORATTR 	429	USR-Host-Type				0x9812	integer
VENDORATTR 	429	USR-Send-Name				0x9813	string
VENDORATTR 	429	USR-Send-Password			0x9814	string
VENDORATTR 	429	USR-Start-Time				0x9815	integer
VENDORATTR 	429	USR-End-Time				0x9816	integer
VENDORATTR 	429	USR-Send-Script1			0x9817	string
VENDORATTR 	429	USR-Reply-Script1			0x9818	string
VENDORATTR 	429	USR-Send-Script2			0x9819	string
VENDORATTR 	429	USR-Reply-Script2			0x981a	string
VENDORATTR 	429	USR-Send-Script3			0x981b	string
VENDORATTR 	429	USR-Reply-Script3			0x981c	string
VENDORATTR 	429	USR-Send-Script4			0x981d	string
VENDORATTR 	429	USR-Reply-Script4			0x981e	string
VENDORATTR 	429	USR-Send-Script5			0x981f	string
VENDORATTR 	429	USR-Reply-Script5			0x9820	string
VENDORATTR 	429	USR-Send-Script6			0x9821	string
VENDORATTR 	429	USR-Reply-Script6			0x9822	string
VENDORATTR 	429	USR-Terminal-Type			0x9823	string
VENDORATTR 	429	USR-Appletalk-Network-Range		0x9824	integer
VENDORATTR 	429	USR-Local-IP-Address			0x9825	string
VENDORATTR 	429	USR-Routing-Protocol			0x9826	integer
VENDORATTR 	429	USR-Modem-Group				0x9827	integer
VENDORATTR 	429	USR-Modem-Training-Time			0x9842	integer
VENDORATTR 	429	USR-Interface-Index			0x9843	integer
VENDORATTR 	429	USR-MP-MRRU				0x982f	integer

VENDORATTR 	429	USR-SAP-Filter-In			0x9002	string
VENDORATTR 	429	USR-MIC					0x9014	string
VENDORATTR 	429	USR-Log-Filter-Packets			0x9017	string
VENDORATTR 	429	USR-VPN-Encrypter			0x901e	integer
VENDORATTR 	429	USR-Re-Chap-Timeout			0x9020	integer
VENDORATTR 	429	USR-Tunnel-Switch-Endpoint		0x9868	string

VENDORATTR 	429	USR-IP-SAA-Filter			0x9870	integer
VENDORATTR 	429	Initial-Modulation-Type			0x0923	integer
VENDORATTR 	429	USR-VTS-Session-Key			0x9856	string
VENDORATTR 	429	USR-Orig-NAS-Type			0x9857	string
VENDORATTR 	429	USR-Call-Arrival-Time			0x9858	integer
VENDORATTR 	429	USR-Call-End-Time			0x9859	integer
VENDORATTR 	429	USR-Tunnel-Auth-Hostname		0x986b	string
VENDORATTR 	429	USR-Acct-Reason-Code			0x986c	integer
VENDORATTR 	429	USR-Supports-Tags			0x9889	integer
VENDORATTR 	429	USR-HARC-Disconnect-Code		0x988b	integer
VENDORATTR 	429	USR-RMMIE-Status			0x01cd	integer
VENDORATTR 	429	USR-RMMIE-Last-Update-Event		0x0901	integer
VENDORATTR 	429	USR-RMMIE-x2-Status			0x0909	integer
VENDORATTR 	429	USR-RMMIE-Planned-Disconnect		0x090a	integer
VENDORATTR 	429	USR-VPN-GW-Location-Id			0x901f	string
VENDORATTR 	429	USR-CCP-Algorithm			0x9021	integer
VENDORATTR 	429	USR-ACCM-Type				0x9022	integer
VENDORATTR 	429	USR-Local-Framed-IP-Addr		0x9026	ipaddr
VENDORATTR 	429	USR-IPX-Routing				0x9828	integer
VENDORATTR 	429	USR-IPX-WAN				0x9829	integer
VENDORATTR 	429	USR-IP-RIP-Policies			0x982a	integer
VENDORATTR 	429	USR-IP-RIP-Simple-Auth-Password		0x982b	string
VENDORATTR 	429	USR-IP-RIP-Input-Filter			0x982c	string
VENDORATTR 	429	USR-IP-Call-Input-Filter		0x982d	string
VENDORATTR 	429	USR-IPX-RIP-Input-Filter		0x982e	string
VENDORATTR 	429	USR-IPX-Call-Input-Filter		0x9830	string
VENDORATTR 	429	USR-AT-Input-Filter			0x9831	string
VENDORATTR 	429	USR-AT-RTMP-Input-Filter		0x9832	string
VENDORATTR 	429	USR-AT-Zip-Input-Filter			0x9833	string
VENDORATTR 	429	USR-AT-Call-Input-Filter		0x9834	string
VENDORATTR 	429	USR-ET-Bridge-Input-Filter		0x9835	string
VENDORATTR 	429	USR-IP-RIP-Output-Filter		0x9836	string
VENDORATTR 	429	USR-IP-Call-Output-Filter		0x9837	string
VENDORATTR 	429	USR-IPX-RIP-Output-Filter		0x9838	string
VENDORATTR 	429	USR-IPX-Call-Output-Filter		0x9839	string
VENDORATTR 	429	USR-AT-Output-Filter			0x983a	string
VENDORATTR 	429	USR-AT-RTMP-Output-Filter		0x983b	string
VENDORATTR 	429	USR-AT-Zip-Output-Filter		0x983c	string
VENDORATTR 	429	USR-AT-Call-Output-Filter		0x983d	string
VENDORATTR 	429	USR-ET-Bridge-Output-Filter		0x983e	string
# This item name is too long for Cistron to parse; had to chop the r off.
VENDORATTR 	429	USR-ET-Bridge-Call-Output-Filte		0x983f	string
VENDORATTR 	429	USR-IP-Default-Route-Option		0x9840	integer
VENDORATTR 	429	USR-MP-EDO-HIPER			0x9841	string
VENDORATTR 	429	USR-Tunnel-Security			0x9844	integer
VENDORATTR 	429	USR-Port-Tap				0x9845	integer
VENDORATTR 	429	USR-Port-Tap-Format			0x9846	integer
VENDORATTR 	429	USR-Port-Tap-Output			0x9847	integer
VENDORATTR 	429	USR-Port-Tap-Facility			0x9848	integer
VENDORATTR 	429	USR-Port-Tap-Priority			0x9849	integer
VENDORATTR 	429	USR-Port-Tap-Address			0x984a	ipaddr
VENDORATTR 	429	USR-MobileIP-Home-Agent-Address		0x984b	ipaddr
VENDORATTR 	429	USR-Tunneled-MLPP			0x984c	integer
VENDORATTR 	429	USR-Multicast-Proxy			0x984d	integer
VENDORATTR 	429	USR-Multicast-Receive			0x984e	integer
VENDORATTR 	429	USR-Multicast-Forwarding		0x9850	integer
VENDORATTR 	429	USR-IGMP-Query-Interval			0x9851	integer
VENDORATTR 	429	USR-IGMP-Maximum-Response-Time		0x9852	integer
VENDORATTR 	429	USR-IGMP-Robustness			0x9853	integer
VENDORATTR 	429	USR-IGMP-Version			0x9854	integer
VENDORATTR 	429	USR-Callback-Type			0x986a	integer
VENDORATTR 	429	USR-Request-Type			0xf001	integer
VENDORATTR 	429	USR-RMMIE-Num-Of-Updates		0x01ce	integer
VENDORATTR 	429	USR-RMMIE-Manufacturer-ID		0x01df	integer
VENDORATTR 	429	USR-RMMIE-Product-Code			0x01e0	string
VENDORATTR 	429	USR-RMMIE-Serial-Number			0x01e1	string
VENDORATTR 	429	USR-RMMIE-Firmware-Version		0x01e2	string
VENDORATTR 	429	USR-RMMIE-Firmware-Build-Date		0x01e3	string
VENDORATTR 	429	USR-Call-Arrival-in-GMT			0xbe52	date
VENDORATTR 	429	USR-Call-Connect-in-GMT			0xbe51	date
VENDORATTR 	429	USR-Call-Terminate-in-GMT		0xbe50	date
VENDORATTR 	429	USR-IDS0-Call-Type			0xbe4f	integer
VENDORATTR 	429	USR-Call-Reference-Number		0xbe7d	integer
VENDORATTR 	429	USR-CDMA-Call-Reference-Number		0x0183	integer
VENDORATTR 	429	USR-Mobile-IP-Address			0x088e	ipaddr
VENDORATTR 	429	USR-IWF-IP-Address			0x03f4	ipaddr
VENDORATTR 	429	USR-Called-Party-Number			0x0890	string
VENDORATTR 	429	USR-Calling-Party-Number		0x088f	string
VENDORATTR 	429	USR-Call-Type				0x0891	integer
VENDORATTR 	429	USR-ESN					0x0892	string
VENDORATTR 	429	USR-IWF-Call-Identifier			0x0893	integer
VENDORATTR 	429	USR-IMSI				0x0894	string
VENDORATTR 	429	USR-Service-Option			0x0895	integer
VENDORATTR 	429	USR-Disconnect-Cause-Indicator		0x0896	integer
VENDORATTR 	429	USR-Mobile-NumBytes-Txed		0x0897	integer
VENDORATTR 	429	USR-Mobile-NumBytes-Rxed		0x0898	integer
VENDORATTR 	429	USR-Num-Fax-Pages-Processed		0x0899	integer
VENDORATTR 	429	USR-Compression-Type			0x089a	integer
VENDORATTR 	429	USR-Call-Error-Code			0x089b	integer
VENDORATTR 	429	USR-Modem-Setup-Time			0x089c	integer
VENDORATTR 	429	USR-Call-Connecting-Time		0x089d	integer
VENDORATTR 	429	USR-Connect-Time			0x089e	integer
VENDORATTR 	429	USR-RMMIE-Last-Update-Time		0x0900	integer	
VENDORATTR 	429	USR-RMMIE-Rcv-Tot-PwrLvl		0x0902	integer
VENDORATTR 	429	USR-RMMIE-Rcv-PwrLvl-3300Hz		0x0903	integer
VENDORATTR 	429	USR-RMMIE-Rcv-PwrLvl-3750Hz		0x0904	integer
VENDORATTR 	429	USR-RMMIE-PwrLvl-NearEcho-Canc		0x0905	integer
VENDORATTR 	429	USR-RMMIE-PwrLvl-FarEcho-Canc		0x0906	integer
VENDORATTR 	429	USR-RMMIE-PwrLvl-Noise-Lvl		0x0907	integer
VENDORATTR 	429	USR-RMMIE-PwrLvl-Xmit-Lvl		0x0908	integer
VENDORATTR 	429	USR-Framed-IPX-Route			0x9027	ipaddr
VENDORATTR 	429	USR-MPIP-Tunnel-Originator		0x9028	ipaddr
VENDORATTR 	429	USR-IGMP-Routing			0x9855	integer
VENDORATTR 	429	USR-Rad-Multicast-Routing-Ttl		0x9860	integer
# again, too long for cistron to parse "rate-limit", "protocol" and "boundary"
VENDORATTR 	429	USR-Rad-Multicast-Routing-RtLim		0x9861	integer
VENDORATTR 	429	USR-Rad-Multicast-Routing-Proto		0x9862	integer
VENDORATTR 	429	USR-Rad-Multicast-Routing-Bound		0x9863	string
VENDORATTR 	429	USR-Rad-Dvmrp-Metric			0x9864	integer
VENDORATTR 	429	USR-Chat-Script-Name			0x9865	string
VENDORATTR 	429	USR-CUSR-hat-Script-Rules		0x9866	string
VENDORATTR 	429	USR-Rad-Location-Type			0x9867	integer
VENDORATTR 	429	USR-OSPF-Addressless-Index		0x9869	integer
VENDORATTR 	429	USR-DNIS-ReAuthentication		0x9875	integer
VENDORATTR 	429	USR-NAS-Type				0xf002	integer
VENDORATTR 	429	USR-Auth-Mode				0xf003	integer
#
#	Integer Translations
#

#VENDORVALUE 	429	USR-Character-Echo	Echo-On			0
#VENDORVALUE 	429	USR-Character-Echo	Echo-Off		1

#VENDORVALUE 	429	USR-RIPV2		Off			0
#VENDORVALUE 	429	USR-RIPV2		On			1

VENDORVALUE 	429	USR-Syslog-Tap		Off			0
VENDORVALUE 	429	USR-Syslog-Tap		On-Raw			1
VENDORVALUE 	429	USR-Syslog-Tap		On-Framed		2
VENDORVALUE 	429	USR-Syslog-Tap		Unknown	       4294967295


#	Event Indentifiers

VENDORVALUE 	429	USR-Event-Id	Module-Inserted			6
VENDORVALUE 	429	USR-Event-Id	Module-Removed			7
VENDORVALUE 	429	USR-Event-Id	PSU-Voltage-Alarm		8
VENDORVALUE 	429	USR-Event-Id	PSU-Failed			9
VENDORVALUE 	429	USR-Event-Id	HUB-Temp-Out-of-Range		10
VENDORVALUE 	429	USR-Event-Id	Fan-Failed			11
VENDORVALUE 	429	USR-Event-Id	Watchdog-Timeout		12
VENDORVALUE 	429	USR-Event-Id	Mgmt-Bus-Failure		13
VENDORVALUE 	429	USR-Event-Id	In-Connection-Est		14
VENDORVALUE 	429	USR-Event-Id	Out-Connection-Est		15
VENDORVALUE 	429	USR-Event-Id	In-Connection-Term		16
VENDORVALUE 	429	USR-Event-Id	Out-Connection-Term		17
VENDORVALUE 	429	USR-Event-Id	Connection-Failed		18
VENDORVALUE 	429	USR-Event-Id	Connection-Timeout		19
VENDORVALUE 	429	USR-Event-Id	DTE-Transmit-Idle		20
VENDORVALUE 	429	USR-Event-Id	DTR-True			21
VENDORVALUE 	429	USR-Event-Id	DTR-False			22
VENDORVALUE 	429	USR-Event-Id	Block-Error-at-Threshold	23
VENDORVALUE 	429	USR-Event-Id	Fallbacks-at-Threshold		24
VENDORVALUE 	429	USR-Event-Id	No-Dial-Tone-Detected		25
VENDORVALUE 	429	USR-Event-Id	No-Loop-Current-Detected	26
VENDORVALUE 	429	USR-Event-Id	Yellow-Alarm			27
VENDORVALUE 	429	USR-Event-Id	Red-Alarm			28
VENDORVALUE 	429	USR-Event-Id	Loss-Of-Signal			29
VENDORVALUE 	429	USR-Event-Id	Rcv-Alrm-Ind-Signal		30
VENDORVALUE 	429	USR-Event-Id	Timing-Source-Switch		31
VENDORVALUE 	429	USR-Event-Id	Modem-Reset-by-DTE		32
VENDORVALUE 	429	USR-Event-Id	Modem-Ring-No-Answer		33
VENDORVALUE 	429	USR-Event-Id	DTE-Ring-No-Answer		34
VENDORVALUE 	429	USR-Event-Id	Pkt-Bus-Session-Active		35
VENDORVALUE 	429	USR-Event-Id	Pkt-Bus-Session-Congestion	36
VENDORVALUE 	429	USR-Event-Id	Pkt-Bus-Session-Lost		37
VENDORVALUE 	429	USR-Event-Id	Pkt-Bus-Session-Inactive	38
VENDORVALUE 	429	USR-Event-Id	User-Interface-Reset		39
VENDORVALUE 	429	USR-Event-Id	Gateway-Port-Out-of-Service	40
VENDORVALUE 	429	USR-Event-Id	Gateway-Port-Link-Active	41
VENDORVALUE 	429	USR-Event-Id	Dial-Out-Login-Failure		42
VENDORVALUE 	429	USR-Event-Id	Dial-In-Login-Failure		43
VENDORVALUE 	429	USR-Event-Id	Dial-Out-Restricted-Number	44
VENDORVALUE 	429	USR-Event-Id	Dial-Back-Restricted-Number	45
VENDORVALUE 	429	USR-Event-Id	User-Blacklisted		46
VENDORVALUE 	429	USR-Event-Id	Attempted-Login-Blacklisted	47
VENDORVALUE 	429	USR-Event-Id	Response-Attempt-Limit-Exceeded 48
VENDORVALUE 	429	USR-Event-Id	Login-Attempt-Limit-Exceeded	49
VENDORVALUE 	429	USR-Event-Id	Dial-Out-Call-Duration		50
VENDORVALUE 	429	USR-Event-Id	Dial-In-Call-Duration		51
VENDORVALUE 	429	USR-Event-Id	Pkt-Bus-Session-Err-Status	52
VENDORVALUE 	429	USR-Event-Id	NMC-AutoRespnse-Trap		53
VENDORVALUE 	429	USR-Event-Id	Acct-Server-Contact-Loss	54
VENDORVALUE 	429	USR-Event-Id	Yellow-Alarm-Clear		55
VENDORVALUE 	429	USR-Event-Id	Red-Alarm-Clear			56
VENDORVALUE 	429	USR-Event-Id	Loss-Of-Signal-Clear		57
VENDORVALUE 	429	USR-Event-Id	Rcv-Alrm-Ind-Signal-Clear	58
VENDORVALUE 	429	USR-Event-Id	Incoming-Connection-Established 59
VENDORVALUE 	429	USR-Event-Id	Outgoing-Connection-Established 60
VENDORVALUE 	429	USR-Event-Id	Incoming-Connection-Terminated	61
VENDORVALUE 	429	USR-Event-Id	Outgoing-Connection-Terminated	62
VENDORVALUE 	429	USR-Event-Id	Connection-Attempt-Failure	63
VENDORVALUE 	429	USR-Event-Id	Continuous-CRC-Alarm		64
VENDORVALUE 	429	USR-Event-Id	Continuous-CRC-Alarm-Clear	65
VENDORVALUE 	429	USR-Event-Id	Physical-State-Change		66
VENDORVALUE 	429	USR-Event-Id	Gateway-Network-Failed		71
VENDORVALUE 	429	USR-Event-Id	Gateway-Network-Restored	72
VENDORVALUE 	429	USR-Event-Id	Packet-Bus-Clock-Lost		73
VENDORVALUE 	429	USR-Event-Id	Packet-Bus-Clock-Restored	74
VENDORVALUE 	429	USR-Event-Id	D-Channel-In-Service		75
VENDORVALUE 	429	USR-Event-Id	D-Channel-Out-of-Service	76
VENDORVALUE 	429	USR-Event-Id	DS0s-In-Service			77
VENDORVALUE 	429	USR-Event-Id	DS0s-Out-of-Service		78
VENDORVALUE 	429	USR-Event-Id	T1/T1PRI/E1PRI-Call-Event	79
VENDORVALUE 	429	USR-Event-Id	Psu-Incompatible		80
VENDORVALUE 	429	USR-Event-Id	T1,T1-E1/PRI-Call-Arrive-Event	81
VENDORVALUE 	429	USR-Event-Id	T1,T1-E1/PRI-Call-Connect-Event	82
VENDORVALUE 	429	USR-Event-Id	T1,T1-E1/PRI-Call-Termina-Event	83
VENDORVALUE 	429	USR-Event-Id	T1,T1-E1/PRI-Call-Failed-Event	84
VENDORVALUE 	429	USR-Event-Id	DNS-Contact-Lost		85
VENDORVALUE 	429	USR-Event-Id	NTP-Contact-Lost		86
VENDORVALUE 	429	USR-Event-Id	NTP-Contact-Restored		87
VENDORVALUE 	429	USR-Event-Id	IPGW-Link-Up			88
VENDORVALUE 	429	USR-Event-Id	IPGW-Link-Down			89
VENDORVALUE 	429	USR-Event-Id	NTP-Contact-Degraded		90
VENDORVALUE 	429	USR-Event-Id	In-Connection-Failed		91
VENDORVALUE 	429	USR-Event-Id	Out-Connection-Failed		92
VENDORVALUE 	429	USR-Event-Id	Application-ProcessorReset	93
VENDORVALUE 	429	USR-Event-Id	DSP-Reset			94
VENDORVALUE 	429	USR-Event-Id	Changed-to-Maint-Srvs-State	95
VENDORVALUE 	429	USR-Event-Id	Loop-Back-cleared-on-channel	96
VENDORVALUE 	429	USR-Event-Id	Loop-Back-on-channel		97
VENDORVALUE 	429	USR-Event-Id	Telco-Abnormal-Response		98
VENDORVALUE 	429	USR-Event-Id	DNS-Contact-Restored		99
VENDORVALUE 	429	USR-Event-Id	DNS-Contact-Degraded		100
VENDORVALUE 	429	USR-Event-Id	RADIUS-Accounting-Restored	101
VENDORVALUE 	429	USR-Event-Id	RADIUS-Accounting-Group-Restore	102
VENDORVALUE 	429	USR-Event-Id	RADIUS-Accounting-Group-Degrade	103
VENDORVALUE 	429	USR-Event-Id	RADIUS-Accounting-Group-NonOper	104
VENDORVALUE 	429	USR-Event-Id	T1/T1-E1/PRI-InCall-Fail-Event	119
VENDORVALUE 	429	USR-Event-Id	T1/T1-E1/PRI-OutCall-Fail-Event	120
VENDORVALUE 	429	USR-Event-Id	RMMIE-Retrain-Event		121
VENDORVALUE 	429	USR-Event-Id	RMMIE-Speed-Shift-Event		122
VENDORVALUE 	429	USR-Event-Id	CDMA-Call-Start			191
VENDORVALUE 	429	USR-Event-Id	CDMA-Call-End			192


VENDORVALUE 	429	USR-Card-Type	SlotEmpty			1
VENDORVALUE 	429	USR-Card-Type	SlotUnknown			2
VENDORVALUE 	429	USR-Card-Type	NetwMgtCard			3
VENDORVALUE 	429	USR-Card-Type	DualT1NAC			4
VENDORVALUE 	429	USR-Card-Type	DualModemNAC			5
VENDORVALUE 	429	USR-Card-Type	QuadModemNAC			6
VENDORVALUE 	429	USR-Card-Type	TrGatewayNAC			7
VENDORVALUE 	429	USR-Card-Type	X25GatewayNAC			8
VENDORVALUE 	429	USR-Card-Type	DualV34ModemNAC			9
VENDORVALUE 	429	USR-Card-Type	QuadV32DigitalModemNAC		10
VENDORVALUE 	429	USR-Card-Type	QuadV32AnalogModemNAC		11
VENDORVALUE 	429	USR-Card-Type	QuadV32DigAnlModemNAC		12
VENDORVALUE 	429	USR-Card-Type	QuadV34DigModemNAC		13
VENDORVALUE 	429	USR-Card-Type	QuadV34AnlModemNAC		14
VENDORVALUE 	429	USR-Card-Type	QuadV34DigAnlModemNAC		15
VENDORVALUE 	429	USR-Card-Type	SingleT1NAC			16
VENDORVALUE 	429	USR-Card-Type	EthernetGatewayNAC		17
VENDORVALUE 	429	USR-Card-Type	AccessServer			18
VENDORVALUE 	429	USR-Card-Type	486TrGatewayNAC			19
VENDORVALUE 	429	USR-Card-Type	486EthernetGatewayNAC		20
VENDORVALUE 	429	USR-Card-Type	DualRS232NAC			22
VENDORVALUE 	429	USR-Card-Type	486X25GatewayNAC		23
VENDORVALUE 	429	USR-Card-Type	ApplicationServerNAC		25
VENDORVALUE 	429	USR-Card-Type	ISDNGatewayNAC			26
VENDORVALUE 	429	USR-Card-Type	ISDNpriT1NAC			27
VENDORVALUE 	429	USR-Card-Type	ClkedNetMgtCard			28
VENDORVALUE 	429	USR-Card-Type	ModemPoolManagementNAC		29
VENDORVALUE 	429	USR-Card-Type	ModemPoolNetserverNAC		30
VENDORVALUE 	429	USR-Card-Type	ModemPoolV34ModemNAC		31
VENDORVALUE 	429	USR-Card-Type	ModemPoolISDNNAC		32
VENDORVALUE 	429	USR-Card-Type	NTServerNAC			33
VENDORVALUE 	429	USR-Card-Type	QuadV34DigitalG2NAC		34
VENDORVALUE 	429	USR-Card-Type	QuadV34AnalogG2NAC		35
VENDORVALUE 	429	USR-Card-Type	QuadV34DigAnlgG2NAC		36
VENDORVALUE 	429	USR-Card-Type	NETServerFrameRelayNAC		37
VENDORVALUE 	429	USR-Card-Type	NETServerTokenRingNAC		38
VENDORVALUE 	429	USR-Card-Type	X2524ChannelNAC			39
VENDORVALUE 	429	USR-Card-Type	WirelessGatewayNac		42

VENDORVALUE 	429	USR-Card-Type	EnhancedAccessServer		  44
VENDORVALUE 	429	USR-Card-Type	EnhancedISDNGatewayNAC		  45

VENDORVALUE 	429	USR-Card-Type	DualT1NIC			1001
VENDORVALUE 	429	USR-Card-Type	DualAlogMdmNIC			1002
VENDORVALUE 	429	USR-Card-Type	QuadDgtlMdmNIC			1003
VENDORVALUE 	429	USR-Card-Type	QuadAlogDgtlMdmNIC		1004
VENDORVALUE 	429	USR-Card-Type	TokenRingNIC			1005
VENDORVALUE 	429	USR-Card-Type	SingleT1NIC			1006
VENDORVALUE 	429	USR-Card-Type	EthernetNIC			1007
VENDORVALUE 	429	USR-Card-Type	ShortHaulDualT1NIC		1008
VENDORVALUE 	429	USR-Card-Type	DualAlogMgdIntlMdmNIC		1009
VENDORVALUE 	429	USR-Card-Type	X25NIC				1010
VENDORVALUE 	429	USR-Card-Type	QuadAlogNonMgdMdmNIC		1011
VENDORVALUE 	429	USR-Card-Type	QuadAlogMgdIntlMdmNIC		1012
VENDORVALUE 	429	USR-Card-Type	QuadAlogNonMgdIntlMdmNIC	1013
VENDORVALUE 	429	USR-Card-Type	QuadLsdLiMgdMdmNIC		1014
VENDORVALUE 	429	USR-Card-Type	QuadLsdLiNonMgdMdmNIC		1015
VENDORVALUE 	429	USR-Card-Type	QuadLsdLiMgdIntlMdmNIC		1016
VENDORVALUE 	429	USR-Card-Type	QuadLsdLiNonMgdIntlMdmNIC	1017
VENDORVALUE 	429	USR-Card-Type	HSEthernetWithV35NIC		1018
VENDORVALUE 	429	USR-Card-Type	HSEthernetWithoutV35NIC		1019
VENDORVALUE 	429	USR-Card-Type	DualHighSpeedV35NIC		1020
VENDORVALUE 	429	USR-Card-Type	QuadV35RS232LowSpeedNIC		1021
VENDORVALUE 	429	USR-Card-Type	DualE1NIC			1022
VENDORVALUE 	429	USR-Card-Type	ShortHaulDualE1NIC		1023
VENDORVALUE 	429	USR-Card-Type	BellcoreLongHaulDualT1NIC	1025
VENDORVALUE 	429	USR-Card-Type	BellcoreShrtHaulDualT1NIC	1026
VENDORVALUE 	429	USR-Card-Type	SCSIEdgeServerNIC		1027


VENDORVALUE 	429	USR-Default-DTE-Data-Rate	      110-BPS	      1
VENDORVALUE 	429	USR-Default-DTE-Data-Rate	      300-BPS	      2
VENDORVALUE 	429	USR-Default-DTE-Data-Rate	      600-BPS	      3
VENDORVALUE 	429	USR-Default-DTE-Data-Rate	      1200-BPS	      4
VENDORVALUE 	429	USR-Default-DTE-Data-Rate	      2400-BPS	      5
VENDORVALUE 	429	USR-Default-DTE-Data-Rate	      4800-BPS	      6
VENDORVALUE 	429	USR-Default-DTE-Data-Rate	      7200-BPS	      7
VENDORVALUE 	429	USR-Default-DTE-Data-Rate	      9600-BPS	      8
VENDORVALUE 	429	USR-Default-DTE-Data-Rate	      12K-BPS	      9
VENDORVALUE 	429	USR-Default-DTE-Data-Rate	      14.4K-BPS	      10
VENDORVALUE 	429	USR-Default-DTE-Data-Rate	      16.8-BPS	      11
VENDORVALUE 	429	USR-Default-DTE-Data-Rate	      19.2K-BPS	      12
VENDORVALUE 	429	USR-Default-DTE-Data-Rate	      38.4K-BPS	      13
VENDORVALUE 	429	USR-Default-DTE-Data-Rate	      75-BPS	      14
VENDORVALUE 	429	USR-Default-DTE-Data-Rate	      450-BPS	      15
VENDORVALUE 	429	USR-Default-DTE-Data-Rate	      UNKNOWN-BPS     16
VENDORVALUE 	429	USR-Default-DTE-Data-Rate	      57.6K-BPS	      17
VENDORVALUE 	429	USR-Default-DTE-Data-Rate	      21.6K-BPS	      18
VENDORVALUE 	429	USR-Default-DTE-Data-Rate	      24K-BPS	      19
VENDORVALUE 	429	USR-Default-DTE-Data-Rate	      26K-BPS	      20
VENDORVALUE 	429	USR-Default-DTE-Data-Rate	      28K-BPS	      21
VENDORVALUE 	429	USR-Default-DTE-Data-Rate	      115K-BPS	      22


VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		110-BPS		1
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		300-BPS		2
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		600-BPS		3
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		1200-BPS	4
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		2400-BPS	5
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		4800-BPS	6
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		7200-BPS	7
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		9600-BPS	8
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		12000-BPS	9
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		14400-BPS	10
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		16800-BPS	11
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		19200-BPS	12
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		38400-BPS	13
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		75-BPS		14
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		450-BPS		15
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		UNKNOWN-BPS	16
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		57600-BPS	17
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		21600-BPS	18
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		24000-BPS	19
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		26400-BPS	20
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		28800-BPS	21
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		115200-BPS	22
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		31200-BPS	23
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		33600-BPS	24
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		25333-BPS	25
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		26666-BPS	26
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		28000-BPS	27
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		29333-BPS	28
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		30666-BPS	29
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		32000-BPS	30
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		33333-BPS	31
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		34666-BPS	32
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		36000-BPS	33
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		37333-BPS	34
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		38666-BPS	35
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		40000-BPS	36
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		41333-BPS	37
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		42666-BPS	38
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		44000-BPS	39
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		45333-BPS	40
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		46666-BPS	41
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		48000-BPS	42	
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		49333-BPS	43	
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		50666-BPS	44
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		52000-BPS	45	
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		53333-BPS	46	
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		54666-BPS	47	
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		56000-BPS	48	
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		57333-BPS	49	
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		58666-BPS	50	
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		60000-BPS	51	
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		61333-BPS	52	
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		62666-BPS	53	
VENDORVALUE 	429	USR-Initial-Rx-Link-Data-Rate		64000-BPS	54	



VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		110-BPS		1
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		300-BPS		2
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		600-BPS		3
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		1200-BPS	4
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		2400-BPS	5
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		4800-BPS	6
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		7200-BPS	7
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		9600-BPS	8
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		12000-BPS	9
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		14400-BPS	10
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		16800-BPS	11
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		19200-BPS	12
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		38400-BPS	13
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		75-BPS		14
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		450-BPS		15
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		UNKNOWN-BPS	16
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		57600-BPS	17
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		21600-BPS	18
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		24000-BPS	19
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		26400-BPS	20
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		28800-BPS	21
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		115200-BPS	22
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		31200-BPS	23
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		33600-BPS	24
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		25333-BPS	25
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		26666-BPS	26
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		28000-BPS	27
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		29333-BPS	28
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		30666-BPS	29
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		32000-BPS	30
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		33333-BPS	31
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		34666-BPS	32
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		36000-BPS	33
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		37333-BPS	34
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		38666-BPS	35
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		40000-BPS	36
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		41333-BPS	37
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		42666-BPS	38
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		44000-BPS	39
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		45333-BPS	40
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		46666-BPS	41
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		48000-BPS	42	
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		49333-BPS	43	
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		50666-BPS	44
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		52000-BPS	45	
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		53333-BPS	46	
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		54666-BPS	47	
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		56000-BPS	48	
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		57333-BPS	49	
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		58666-BPS	50	
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		60000-BPS	51	
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		61333-BPS	52	
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		62666-BPS	53	
VENDORVALUE 	429	USR-Final-Rx-Link-Data-Rate		64000-BPS	54	


VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		110-BPS		1
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		300-BPS		2
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		600-BPS		3
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		1200-BPS	4
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		2400-BPS	5
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		4800-BPS	6
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		7200-BPS	7
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		9600-BPS	8
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		12000-BPS	9
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		14400-BPS	10
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		16800-BPS	11
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		19200-BPS	12
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		38400-BPS	13
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		75-BPS		14
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		450-BPS		15
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		UNKNOWN-BPS	16
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		57600-BPS	17
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		21600-BPS	18
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		24000-BPS	19
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		26400-BPS	20
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		28800-BPS	21
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		115200-BPS	22
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		31200-BPS	23
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		33600-BPS	24
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		25333-BPS	25
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		26666-BPS	26
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		28000-BPS	27
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		29333-BPS	28
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		30666-BPS	29
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		32000-BPS	30
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		33333-BPS	31
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		34666-BPS	32
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		36000-BPS	33
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		37333-BPS	34
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		38666-BPS	35
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		40000-BPS	36
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		41333-BPS	37
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		42666-BPS	38
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		44000-BPS	39
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		45333-BPS	40
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		46666-BPS	41
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		48000-BPS	42	
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		49333-BPS	43	
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		50666-BPS	44
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		52000-BPS	45	
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		53333-BPS	46	
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		54666-BPS	47	
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		56000-BPS	48	
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		57333-BPS	49	
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		58666-BPS	50	
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		60000-BPS	51	
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		61333-BPS	52	
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		62666-BPS	53	
VENDORVALUE 	429	USR-Initial-Tx-Link-Data-Rate		64000-BPS	54	



VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		110-BPS		1
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		300-BPS		2
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		600-BPS		3
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		1200-BPS	4
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		2400-BPS	5
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		4800-BPS	6
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		7200-BPS	7
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		9600-BPS	8
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		12000-BPS	9
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		14400-BPS	10
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		16800-BPS	11
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		19200-BPS	12
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		38400-BPS	13
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		75-BPS		14
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		450-BPS		15
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		UNKNOWN-BPS	16
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		57600-BPS	17
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		21600-BPS	18
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		24000-BPS	19
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		26400-BPS	20
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		28800-BPS	21
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		115200-BPS	22
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		31200-BPS	23
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		33600-BPS	24
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		25333-BPS	25
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		26666-BPS	26
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		28000-BPS	27
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		29333-BPS	28
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		30666-BPS	29
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		32000-BPS	30
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		33333-BPS	31
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		34666-BPS	32
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		36000-BPS	33
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		37333-BPS	34
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		38666-BPS	35
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		40000-BPS	36
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		41333-BPS	37
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		42666-BPS	38
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		44000-BPS	39
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		45333-BPS	40
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		46666-BPS	41
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		48000-BPS	42	
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		49333-BPS	43	
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		50666-BPS	44
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		52000-BPS	45	
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		53333-BPS	46	
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		54666-BPS	47	
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		56000-BPS	48	
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		57333-BPS	49	
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		58666-BPS	50	
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		60000-BPS	51	
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		61333-BPS	52	
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		62666-BPS	53	
VENDORVALUE 	429	USR-Final-Tx-Link-Data-Rate		64000-BPS	54	


# Value Connect Speed  /* Added by Krish */

VENDORVALUE 	429	USR-Connect-Speed  NONE	    0 
VENDORVALUE 	429	USR-Connect-Speed  300_BPS	    1 
VENDORVALUE 	429	USR-Connect-Speed  1200_BPS	     2 
VENDORVALUE 	429	USR-Connect-Speed  2400_BPS	     3 
VENDORVALUE 	429	USR-Connect-Speed  4800_BPS	     4 
VENDORVALUE 	429	USR-Connect-Speed  7200_BPS	     5 
VENDORVALUE 	429	USR-Connect-Speed  9600_BPS	     6 
VENDORVALUE 	429	USR-Connect-Speed  12000_BPS      7 
VENDORVALUE 	429	USR-Connect-Speed  14400_BPS      8 
VENDORVALUE 	429	USR-Connect-Speed  16800_BPS      9
VENDORVALUE 	429	USR-Connect-Speed  19200_BPS     10 
VENDORVALUE 	429	USR-Connect-Speed  21600_BPS     11 
VENDORVALUE 	429	USR-Connect-Speed  28800_BPS     12 
VENDORVALUE 	429	USR-Connect-Speed  38400_BPS     13 
VENDORVALUE 	429	USR-Connect-Speed  57600_BPS     14 
VENDORVALUE 	429	USR-Connect-Speed  44000_BPS     27 
VENDORVALUE 	429	USR-Connect-Speed  45333_BPS     28 
VENDORVALUE 	429	USR-Connect-Speed  46666_BPS     29 
VENDORVALUE 	429	USR-Connect-Speed  48000_BPS     30 
VENDORVALUE 	429	USR-Connect-Speed  49333_BPS     31 
VENDORVALUE 	429	USR-Connect-Speed  50666_BPS     32 
VENDORVALUE 	429	USR-Connect-Speed  52000_BPS     33 
VENDORVALUE 	429	USR-Connect-Speed  53333_BPS     34 
VENDORVALUE 	429	USR-Connect-Speed  54666_BPS     35 
VENDORVALUE 	429	USR-Connect-Speed  56000_BPS     36 
VENDORVALUE 	429	USR-Connect-Speed  57333_BPS     37 
VENDORVALUE 	429	USR-Connect-Speed  64000_BPS     38 
VENDORVALUE 	429	USR-Connect-Speed  25333_BPS     39 
VENDORVALUE 	429	USR-Connect-Speed  26666_BPS      40
VENDORVALUE 	429	USR-Connect-Speed  28000_BPS      41 
VENDORVALUE 	429	USR-Connect-Speed  115200_BPS     15 
VENDORVALUE 	429	USR-Connect-Speed  288000_BPS      16
VENDORVALUE 	429	USR-Connect-Speed  75_1200_BPS    17 
VENDORVALUE 	429	USR-Connect-Speed  1200_75_BPS    18
VENDORVALUE 	429	USR-Connect-Speed  24000_BPS      19
VENDORVALUE 	429	USR-Connect-Speed  26400_BPS      20
VENDORVALUE 	429	USR-Connect-Speed  31200_BPS      21
VENDORVALUE 	429	USR-Connect-Speed  33600_BPS      22
VENDORVALUE 	429	USR-Connect-Speed  33333_BPS      23
VENDORVALUE 	429	USR-Connect-Speed  37333_BPS      24
VENDORVALUE 	429	USR-Connect-Speed  41333_BPS      25
VENDORVALUE 	429	USR-Connect-Speed  42666_BPS      26
VENDORVALUE 	429	USR-Connect-Speed  29333_BPS      42 
VENDORVALUE 	429	USR-Connect-Speed  30666_BPS      43
VENDORVALUE 	429	USR-Connect-Speed  32000_BPS      44 
VENDORVALUE 	429	USR-Connect-Speed  34666_BPS      45 
VENDORVALUE 	429	USR-Connect-Speed  36000_BPS      46 
VENDORVALUE 	429	USR-Connect-Speed  38666_BPS      47 
VENDORVALUE 	429	USR-Connect-Speed  40000_BPS      48 
VENDORVALUE 	429	USR-Connect-Speed  58666_BPS      49 
VENDORVALUE 	429	USR-Connect-Speed  60000_BPS      50 
VENDORVALUE 	429	USR-Connect-Speed  61333_BPS      51 
VENDORVALUE 	429	USR-Connect-Speed  62666_BPS      52 

# End of Connect-Speed / * Added by Krish */

#

VENDORVALUE 	429	USR-Sync-Async-Mode		Asynchronous			1
VENDORVALUE 	429	USR-Sync-Async-Mode		Synchronous			2

VENDORVALUE 	429	USR-Originate-Answer-Mode	Originate_in_Originate_Mode	1
VENDORVALUE 	429	USR-Originate-Answer-Mode	Originate_in_Answer_Mode	2
VENDORVALUE 	429	USR-Originate-Answer-Mode	Answer_in_Originate_Mode	3
VENDORVALUE 	429	USR-Originate-Answer-Mode	Answer_in_Answer_Mode		4

VENDORVALUE 	429	USR-Modulation-Type		usRoboticsHST			1
VENDORVALUE 	429	USR-Modulation-Type		ccittV32			2
VENDORVALUE 	429	USR-Modulation-Type		ccittV22bis			3
VENDORVALUE 	429	USR-Modulation-Type		bell103				4
VENDORVALUE 	429	USR-Modulation-Type		ccittV21			5
VENDORVALUE 	429	USR-Modulation-Type		bell212				6
VENDORVALUE 	429	USR-Modulation-Type		ccittV32bis			7
VENDORVALUE 	429	USR-Modulation-Type		ccittV23			8
VENDORVALUE 	429	USR-Modulation-Type		negotiationFailed		9
VENDORVALUE 	429	USR-Modulation-Type		bell208b			10
VENDORVALUE 	429	USR-Modulation-Type		v21FaxClass1			11
VENDORVALUE 	429	USR-Modulation-Type		v27FaxClass1			12
VENDORVALUE 	429	USR-Modulation-Type		v29FaxClass1			13
VENDORVALUE 	429	USR-Modulation-Type		v17FaxClass1			14
VENDORVALUE 	429	USR-Modulation-Type		v21FaxClass2			15
VENDORVALUE 	429	USR-Modulation-Type		v27FaxClass2			16
VENDORVALUE 	429	USR-Modulation-Type		v29FaxClass2			17
VENDORVALUE 	429	USR-Modulation-Type		v17FaxClass2			18
VENDORVALUE 	429	USR-Modulation-Type		v32Terbo			19
VENDORVALUE 	429	USR-Modulation-Type		v34				20
VENDORVALUE 	429	USR-Modulation-Type		vFC				21
VENDORVALUE 	429	USR-Modulation-Type		v34plus				22
VENDORVALUE 	429	USR-Modulation-Type		x2				23
VENDORVALUE 	429	USR-Modulation-Type		v110				24
VENDORVALUE 	429	USR-Modulation-Type		v120				25
VENDORVALUE 	429	USR-Modulation-Type		x75				26
VENDORVALUE 	429	USR-Modulation-Type		asyncSyncPPP			27
VENDORVALUE 	429	USR-Modulation-Type		clearChannel			28
VENDORVALUE 	429	USR-Modulation-Type		x2client			29
VENDORVALUE 	429	USR-Modulation-Type		x2symmetric			30
VENDORVALUE 	429	USR-Modulation-Type		piafs				31
VENDORVALUE 	429	USR-Modulation-Type		x2version2			32
VENDORVALUE 	429	USR-Modulation-Type		v90Analog			33
VENDORVALUE 	429	USR-Modulation-Type		v90Digital			34
VENDORVALUE 	429	USR-Modulation-Type		v90AllDigital			35

VENDORVALUE 	429	Initial-Modulation-Type		usRoboticsHST			1
VENDORVALUE 	429	Initial-Modulation-Type		ccittV32			2
VENDORVALUE 	429	Initial-Modulation-Type		ccittV22bis			3
VENDORVALUE 	429	Initial-Modulation-Type		bell103				4
VENDORVALUE 	429	Initial-Modulation-Type		ccittV21			5
VENDORVALUE 	429	Initial-Modulation-Type		bell212				6
VENDORVALUE 	429	Initial-Modulation-Type		ccittV32bis			7
VENDORVALUE 	429	Initial-Modulation-Type		ccittV23			8
VENDORVALUE 	429	Initial-Modulation-Type		negotiationFailed		9
VENDORVALUE 	429	Initial-Modulation-Type		bell208b			10
VENDORVALUE 	429	Initial-Modulation-Type		v21FaxClass1			11
VENDORVALUE 	429	Initial-Modulation-Type		v27FaxClass1			12
VENDORVALUE 	429	Initial-Modulation-Type		v29FaxClass1			13
VENDORVALUE 	429	Initial-Modulation-Type		v17FaxClass1			14
VENDORVALUE 	429	Initial-Modulation-Type		v21FaxClass2			15
VENDORVALUE 	429	Initial-Modulation-Type		v27FaxClass2			16
VENDORVALUE 	429	Initial-Modulation-Type		v29FaxClass2			17
VENDORVALUE 	429	Initial-Modulation-Type		v17FaxClass2			18
VENDORVALUE 	429	Initial-Modulation-Type		v32Terbo			19
VENDORVALUE 	429	Initial-Modulation-Type		v34				20
VENDORVALUE 	429	Initial-Modulation-Type		vFC				21
VENDORVALUE 	429	Initial-Modulation-Type		v34plus				22
VENDORVALUE 	429	Initial-Modulation-Type		x2				23
VENDORVALUE 	429	Initial-Modulation-Type		v110				24
VENDORVALUE 	429	Initial-Modulation-Type		v120				25
VENDORVALUE 	429	Initial-Modulation-Type		x75				26
VENDORVALUE 	429	Initial-Modulation-Type		asyncSyncPPP			27
VENDORVALUE 	429	Initial-Modulation-Type		clearChannel			28
VENDORVALUE 	429	Initial-Modulation-Type		x2client			29
VENDORVALUE 	429	Initial-Modulation-Type		x2symmetric			30
VENDORVALUE 	429	Initial-Modulation-Type		piafs				31
VENDORVALUE 	429	Initial-Modulation-Type		x2version2			32
VENDORVALUE 	429	Initial-Modulation-Type		v90Analogue			33
VENDORVALUE 	429	Initial-Modulation-Type		v90Digital			34
VENDORVALUE 	429	Initial-Modulation-Type		v90AllDigital			35

VENDORVALUE 	429	USR-Connect-Term-Reason	dtrDrop				1
VENDORVALUE 	429	USR-Connect-Term-Reason	escapeSequence			2
VENDORVALUE 	429	USR-Connect-Term-Reason	athCommand			3
VENDORVALUE 	429	USR-Connect-Term-Reason	carrierLoss			4
VENDORVALUE 	429	USR-Connect-Term-Reason	inactivityTimout		5
VENDORVALUE 	429	USR-Connect-Term-Reason	mnpIncompatible			6
VENDORVALUE 	429	USR-Connect-Term-Reason	undefined			7
VENDORVALUE 	429	USR-Connect-Term-Reason	remotePassword			8
VENDORVALUE 	429	USR-Connect-Term-Reason	linkPassword			9
VENDORVALUE 	429	USR-Connect-Term-Reason	retransmitLimit			10
VENDORVALUE 	429	USR-Connect-Term-Reason	linkDisconnectMsgReceived	11
VENDORVALUE 	429	USR-Connect-Term-Reason	noLoopCurrent			12
VENDORVALUE 	429	USR-Connect-Term-Reason	invalidSpeed			13
VENDORVALUE 	429	USR-Connect-Term-Reason	unableToRetrain			14
VENDORVALUE 	429	USR-Connect-Term-Reason	managementCommand		15
VENDORVALUE 	429	USR-Connect-Term-Reason	noDialTone			16
VENDORVALUE 	429	USR-Connect-Term-Reason	keyAbort			17
VENDORVALUE 	429	USR-Connect-Term-Reason	lineBusy			18
VENDORVALUE 	429	USR-Connect-Term-Reason	noAnswer			19
VENDORVALUE 	429	USR-Connect-Term-Reason	voice				20
VENDORVALUE 	429	USR-Connect-Term-Reason	noAnswerTone			21
VENDORVALUE 	429	USR-Connect-Term-Reason	noCarrier			22
VENDORVALUE 	429	USR-Connect-Term-Reason	undetermined			23
VENDORVALUE 	429	USR-Connect-Term-Reason	v42SabmeTimeout			24
VENDORVALUE 	429	USR-Connect-Term-Reason	v42BreakTimeout			25
VENDORVALUE 	429	USR-Connect-Term-Reason	v42DisconnectCmd		26
VENDORVALUE 	429	USR-Connect-Term-Reason	v42IdExchangeFail		27
VENDORVALUE 	429	USR-Connect-Term-Reason	v42BadSetup			28
VENDORVALUE 	429	USR-Connect-Term-Reason	v42InvalidCodeWord		29
VENDORVALUE 	429	USR-Connect-Term-Reason	v42StringToLong			30
VENDORVALUE 	429	USR-Connect-Term-Reason	v42InvalidCommand		31
VENDORVALUE 	429	USR-Connect-Term-Reason	none				32	
VENDORVALUE 	429	USR-Connect-Term-Reason	v32Cleardown			33
VENDORVALUE 	429	USR-Connect-Term-Reason	dialSecurity			34
VENDORVALUE 	429	USR-Connect-Term-Reason	remoteAccessDenied		35
VENDORVALUE 	429	USR-Connect-Term-Reason	loopLoss			36
VENDORVALUE 	429	USR-Connect-Term-Reason	ds0Teardown			37
VENDORVALUE 	429	USR-Connect-Term-Reason	promptNotEnabled		38
VENDORVALUE 	429	USR-Connect-Term-Reason	noPromptingInSync		39
VENDORVALUE 	429	USR-Connect-Term-Reason	nonArqMode			40
VENDORVALUE 	429	USR-Connect-Term-Reason	modeIncompatible		41
VENDORVALUE 	429	USR-Connect-Term-Reason	noPromptInNonARQ		42
VENDORVALUE 	429	USR-Connect-Term-Reason	dialBackLink			43
VENDORVALUE 	429	USR-Connect-Term-Reason	linkAbort			44
VENDORVALUE 	429	USR-Connect-Term-Reason	autopassFailed			45
VENDORVALUE 	429	USR-Connect-Term-Reason	pbGenericError			46
VENDORVALUE 	429	USR-Connect-Term-Reason	pbLinkErrTxPreAck		47
VENDORVALUE 	429	USR-Connect-Term-Reason	pbLinkErrTxTardyACK		48
VENDORVALUE 	429	USR-Connect-Term-Reason	pbTransmitBusTimeout		49
VENDORVALUE 	429	USR-Connect-Term-Reason	pbReceiveBusTimeout		50
VENDORVALUE 	429	USR-Connect-Term-Reason	pbLinkErrTxTAL			51
VENDORVALUE 	429	USR-Connect-Term-Reason	pbLinkErrRxTAL			52
VENDORVALUE 	429	USR-Connect-Term-Reason	pbTransmitMasterTimeout		53
VENDORVALUE 	429	USR-Connect-Term-Reason	pbClockMissing			54
VENDORVALUE 	429	USR-Connect-Term-Reason	pbReceivedLsWhileLinkUp		55
VENDORVALUE 	429	USR-Connect-Term-Reason	pbOutOfSequenceFrame		56
VENDORVALUE 	429	USR-Connect-Term-Reason	pbBadFrame			57
VENDORVALUE 	429	USR-Connect-Term-Reason	pbAckWaitTimeout		58
VENDORVALUE 	429	USR-Connect-Term-Reason	pbReceivedAckSeqErr		59
VENDORVALUE 	429	USR-Connect-Term-Reason	pbReceiveOvrflwRNRFail		60
VENDORVALUE 	429	USR-Connect-Term-Reason	pbReceiveMsgBufOvrflw		61
VENDORVALUE 	429	USR-Connect-Term-Reason	rcvdGatewayDiscCmd		62
VENDORVALUE 	429	USR-Connect-Term-Reason	tokenPassingTimeout		63
VENDORVALUE 	429	USR-Connect-Term-Reason	dspInterruptTimeout		64
VENDORVALUE 	429	USR-Connect-Term-Reason	mnpProtocolViolation		65
VENDORVALUE 	429	USR-Connect-Term-Reason	class2FaxHangupCmd		66
VENDORVALUE 	429	USR-Connect-Term-Reason	hstSpeedSwitchTimeout		67
VENDORVALUE 	429   USR-Connect-Term-Reason	tooManyUnacked          68
VENDORVALUE 	429   USR-Connect-Term-Reason	timerExpired            69
VENDORVALUE 	429   USR-Connect-Term-Reason	t1Glare         70
VENDORVALUE 	429   USR-Connect-Term-Reason	priDialoutRqTimeout             71
VENDORVALUE 	429   USR-Connect-Term-Reason	abortAnlgDstOvrIsdn             72
VENDORVALUE 	429   USR-Connect-Term-Reason	normalUserCallClear             73
VENDORVALUE 	429   USR-Connect-Term-Reason	normalUnspecified               74
VENDORVALUE 	429   USR-Connect-Term-Reason	bearerIncompatibility           75
VENDORVALUE 	429   USR-Connect-Term-Reason	protocolErrorEvent              76
VENDORVALUE 	429   USR-Connect-Term-Reason	abnormalDisconnect              77
VENDORVALUE 	429   USR-Connect-Term-Reason	invalidCauseValue               78
VENDORVALUE 	429   USR-Connect-Term-Reason	resourceUnavailable             79
VENDORVALUE 	429   USR-Connect-Term-Reason	remoteHungUpDuringTraining              80
VENDORVALUE 	429   USR-Connect-Term-Reason	trainingTimeout         81
VENDORVALUE 	429   USR-Connect-Term-Reason	incomingModemNotAvailable               82
VENDORVALUE 	429   USR-Connect-Term-Reason	incomingInvalidBearerCap                83
VENDORVALUE 	429   USR-Connect-Term-Reason	incomingInvalidChannelID                84
VENDORVALUE 	429   USR-Connect-Term-Reason	incomingInvalidProgInd          85
VENDORVALUE 	429   USR-Connect-Term-Reason	incomingInvalidCallingPty               86
VENDORVALUE 	429   USR-Connect-Term-Reason	incomingInvalidCalledPty                87
VENDORVALUE 	429   USR-Connect-Term-Reason	incomingCallBlock               88
VENDORVALUE 	429   USR-Connect-Term-Reason	incomingLoopStNoRingOff         89
VENDORVALUE 	429   USR-Connect-Term-Reason	outgoingTelcoDisconnect         90
VENDORVALUE 	429   USR-Connect-Term-Reason	outgoingEMWinkTimeout           91
VENDORVALUE 	429   USR-Connect-Term-Reason	outgoingEMWinkTooShort          92
VENDORVALUE 	429   USR-Connect-Term-Reason	outgoingNoChannelAvail          93
VENDORVALUE 	429   USR-Connect-Term-Reason	dspReboot               94
VENDORVALUE 	429   USR-Connect-Term-Reason	noDSPRespToKA           95
VENDORVALUE 	429   USR-Connect-Term-Reason	noDSPRespToDisc         96
VENDORVALUE 	429   USR-Connect-Term-Reason	dspTailPtrInvalid               97
VENDORVALUE 	429   USR-Connect-Term-Reason	dspHeadPtrInvalid               98

VENDORVALUE 	429	USR-Failure-to-Connect-Reason	dtrDrop			1
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	escapeSequence		2
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	athCommand		3
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	carrierLoss		4
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	inactivityTimout	5
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	mnpIncompatible		6
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	undefined		7
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	remotePassword		8
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	linkPassword		9
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	retransmitLimit		10
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	linkDisconnectMsgRec	11
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	noLoopCurrent		12
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	invalidSpeed		13
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	unableToRetrain		14
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	managementCommand	15
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	noDialTone		16
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	keyAbort		17
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	lineBusy		18
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	noAnswer		19
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	voice			20
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	noAnswerTone		21
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	noCarrier		22
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	undetermined		23
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	v42SabmeTimeout		24
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	v42BreakTimeout		25
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	v42DisconnectCmd	26
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	v42IdExchangeFail	27
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	v42BadSetup		28
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	v42InvalidCodeWord	29
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	v42StringToLong		30
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	v42InvalidCommand	31
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	none			32	
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	v32Cleardown		33
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	dialSecurity		34
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	remoteAccessDenied	35
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	loopLoss		36
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	ds0Teardown		37
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	promptNotEnabled	38
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	noPromptingInSync	39
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	nonArqMode		40
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	modeIncompatible	41
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	noPromptInNonARQ	42
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	dialBackLink		43
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	linkAbort		44
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	autopassFailed		45
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	pbGenericError		46
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	pbLinkErrTxPreAck	47
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	pbLinkErrTxTardyACK	48
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	pbTransmitBusTimeout	49
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	pbReceiveBusTimeout	50
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	pbLinkErrTxTAL		51
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	pbLinkErrRxTAL		52
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	pbTransmitMasterTimeout 53
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	pbClockMissing		54
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	pbReceivedLsWhileLinkUp 55
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	pbOutOfSequenceFrame	56
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	pbBadFrame		57
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	pbAckWaitTimeout	58
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	pbReceivedAckSeqErr	59
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	pbReceiveOvrflwRNRFail	60
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	pbReceiveMsgBufOvrflw	61
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	rcvdGatewayDiscCmd	62
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	tokenPassingTimeout	63
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	dspInterruptTimeout	64
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	mnpProtocolViolation	65
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	class2FaxHangupCmd	66
VENDORVALUE 	429	USR-Failure-to-Connect-Reason	hstSpeedSwitchTimeout	67
VENDORVALUE 	429   USR-Failure-to-Connect-Reason     tooManyUnacked          68
VENDORVALUE 	429   USR-Failure-to-Connect-Reason     timerExpired            69
VENDORVALUE 	429   USR-Failure-to-Connect-Reason     t1Glare         70
VENDORVALUE 	429   USR-Failure-to-Connect-Reason     priDialoutRqTimeout             71
VENDORVALUE 	429   USR-Failure-to-Connect-Reason     abortAnlgDstOvrIsdn             72
VENDORVALUE 	429   USR-Failure-to-Connect-Reason     normalUserCallClear             73
VENDORVALUE 	429   USR-Failure-to-Connect-Reason     normalUnspecified               74
VENDORVALUE 	429   USR-Failure-to-Connect-Reason     bearerIncompatibility           75
VENDORVALUE 	429   USR-Failure-to-Connect-Reason     protocolErrorEvent              76
VENDORVALUE 	429   USR-Failure-to-Connect-Reason     abnormalDisconnect              77
VENDORVALUE 	429   USR-Failure-to-Connect-Reason     invalidCauseValue               78
VENDORVALUE 	429   USR-Failure-to-Connect-Reason     resourceUnavailable             79
VENDORVALUE 	429   USR-Failure-to-Connect-Reason     remoteHungUpDuringTraining              80
VENDORVALUE 	429   USR-Failure-to-Connect-Reason     trainingTimeout         81
VENDORVALUE 	429   USR-Failure-to-Connect-Reason     incomingModemNotAvailable               82
VENDORVALUE 	429   USR-Failure-to-Connect-Reason     incomingInvalidBearerCap                83
VENDORVALUE 	429   USR-Failure-to-Connect-Reason     incomingInvalidChannelID                84
VENDORVALUE 	429   USR-Failure-to-Connect-Reason     incomingInvalidProgInd          85
VENDORVALUE 	429   USR-Failure-to-Connect-Reason     incomingInvalidCallingPty               86
VENDORVALUE 	429   USR-Failure-to-Connect-Reason     incomingInvalidCalledPty                87
VENDORVALUE 	429   USR-Failure-to-Connect-Reason     incomingCallBlock               88
VENDORVALUE 	429   USR-Failure-to-Connect-Reason     incomingLoopStNoRingOff         89
VENDORVALUE 	429   USR-Failure-to-Connect-Reason     outgoingTelcoDisconnect         90
VENDORVALUE 	429   USR-Failure-to-Connect-Reason     outgoingEMWinkTimeout           91
VENDORVALUE 	429   USR-Failure-to-Connect-Reason     outgoingEMWinkTooShort          92
VENDORVALUE 	429   USR-Failure-to-Connect-Reason     outgoingNoChannelAvail          93
VENDORVALUE 	429   USR-Failure-to-Connect-Reason     dspReboot               94
VENDORVALUE 	429   USR-Failure-to-Connect-Reason     noDSPRespToKA           95
VENDORVALUE 	429   USR-Failure-to-Connect-Reason     noDSPRespToDisc         96
VENDORVALUE 	429   USR-Failure-to-Connect-Reason     dspTailPtrInvalid               97
VENDORVALUE 	429   USR-Failure-to-Connect-Reason     dspHeadPtrInvalid               98

VENDORVALUE 	429	USR-Simplified-MNP-Levels		none			1
VENDORVALUE 	429	USR-Simplified-MNP-Levels		mnpLevel3		2
VENDORVALUE 	429	USR-Simplified-MNP-Levels		mnpLevel4		3
VENDORVALUE 	429	USR-Simplified-MNP-Levels		ccittV42		4
VENDORVALUE 	429	USR-Simplified-MNP-Levels		usRoboticsHST		5
VENDORVALUE 	429	USR-Simplified-MNP-Levels		synchronousNone		6
VENDORVALUE 	429	USR-Simplified-MNP-Levels		mnpLevel2		7
VENDORVALUE 	429	USR-Simplified-MNP-Levels		mnp10			8
VENDORVALUE 	429	USR-Simplified-MNP-Levels		v42Etc			9
VENDORVALUE 	429   USR-Simplified-MNP-Levels		mnp10Etc		10
VENDORVALUE 	429   USR-Simplified-MNP-Levels		lapmEtc			11
VENDORVALUE 	429   USR-Simplified-MNP-Levels		v42Etc2			12
VENDORVALUE 	429   USR-Simplified-MNP-Levels		v42SRej			13
VENDORVALUE 	429   USR-Simplified-MNP-Levels		piafs			14

VENDORVALUE 	429	USR-Simplified-V42bis-Usage		none			1
VENDORVALUE 	429	USR-Simplified-V42bis-Usage		ccittV42bis		2
VENDORVALUE 	429	USR-Simplified-V42bis-Usage		mnpLevel5		3

VENDORVALUE 	429	USR-Equalization-Type		Long		1
VENDORVALUE 	429	USR-Equalization-Type		Short		2


VENDORVALUE 	429	USR-Fallback-Enabled		Disabled	1
VENDORVALUE 	429	USR-Fallback-Enabled		Enabled		2


VENDORVALUE 	429	USR-Back-Channel-Data-Rate		450BPS		1
VENDORVALUE 	429	USR-Back-Channel-Data-Rate		300BPS		2
VENDORVALUE 	429	USR-Back-Channel-Data-Rate		None		3

VENDORVALUE 	429	USR-Device-Connected-To		None		1
VENDORVALUE 	429	USR-Device-Connected-To		isdnGateway	2
VENDORVALUE 	429	USR-Device-Connected-To		quadModem	3

VENDORVALUE 	429	USR-Call-Event-Code			notSupported	      1
VENDORVALUE 	429	USR-Call-Event-Code			setup		      2
VENDORVALUE 	429	USR-Call-Event-Code			usrSetup	      3
VENDORVALUE 	429	USR-Call-Event-Code			telcoDisconnect	      4
VENDORVALUE 	429	USR-Call-Event-Code			usrDisconnect	      5
VENDORVALUE 	429	USR-Call-Event-Code			noFreeModem	      6
VENDORVALUE 	429	USR-Call-Event-Code			modemsNotAllowed      7
VENDORVALUE 	429	USR-Call-Event-Code			modemsRejectCall      8
VENDORVALUE 	429	USR-Call-Event-Code			modemSetupTimeout     9
VENDORVALUE 	429	USR-Call-Event-Code			noFreeIGW	      10
VENDORVALUE 	429	USR-Call-Event-Code			igwRejectCall	      11
VENDORVALUE 	429	USR-Call-Event-Code			igwSetupTimeout	      12
VENDORVALUE 	429	USR-Call-Event-Code			noFreeTdmts	      13
VENDORVALUE 	429	USR-Call-Event-Code			bcReject	      14
VENDORVALUE 	429	USR-Call-Event-Code			ieReject	      15
VENDORVALUE 	429	USR-Call-Event-Code			chidReject	      16
VENDORVALUE 	429	USR-Call-Event-Code			progReject	      17
VENDORVALUE 	429	USR-Call-Event-Code			callingPartyReject    18
VENDORVALUE 	429	USR-Call-Event-Code			calledPartyReject     19
VENDORVALUE 	429	USR-Call-Event-Code			blocked		      20
VENDORVALUE 	429	USR-Call-Event-Code			analogBlocked	      21
VENDORVALUE 	429	USR-Call-Event-Code			digitalBlocked	      22
VENDORVALUE 	429	USR-Call-Event-Code			outOfService	      23
VENDORVALUE 	429	USR-Call-Event-Code			busy		      24
VENDORVALUE 	429	USR-Call-Event-Code			congestion	      25
VENDORVALUE 	429	USR-Call-Event-Code			protocolError	      26 
VENDORVALUE 	429	USR-Call-Event-Code			noFreeBchannel	      27
VENDORVALUE 	429	USR-Call-Event-Code			inOutCallCollision    28
VENDORVALUE 	429	USR-Call-Event-Code			inCallArrival		29
VENDORVALUE 	429	USR-Call-Event-Code			outCallArrival		30
VENDORVALUE 	429	USR-Call-Event-Code			inCallConnect		31
VENDORVALUE 	429	USR-Call-Event-Code			outCallConnect		32

VENDORVALUE 	429	USR-HARC-Disconnect-Code		No-Error		0
VENDORVALUE 	429	USR-HARC-Disconnect-Code		No-Carrier		1
VENDORVALUE 	429	USR-HARC-Disconnect-Code		No-DSR			2
VENDORVALUE 	429	USR-HARC-Disconnect-Code		Timeout			3
VENDORVALUE 	429	USR-HARC-Disconnect-Code		Reset			4
VENDORVALUE 	429	USR-HARC-Disconnect-Code		Call-Drop-Req		5
VENDORVALUE 	429	USR-HARC-Disconnect-Code		Idle-Timeout		6
VENDORVALUE 	429	USR-HARC-Disconnect-Code		Session-Timeout		7
VENDORVALUE 	429	USR-HARC-Disconnect-Code		User-Req-Drop		8
VENDORVALUE 	429	USR-HARC-Disconnect-Code		Host-Req-Drop		9
VENDORVALUE 	429	USR-HARC-Disconnect-Code		Service-Interruption	10
VENDORVALUE 	429	USR-HARC-Disconnect-Code		Service-Unavailable	11
VENDORVALUE 	429	USR-HARC-Disconnect-Code		User-Input-Error	12
VENDORVALUE 	429	USR-HARC-Disconnect-Code		NAS-Drop-For-Callback	13
VENDORVALUE 	429	USR-HARC-Disconnect-Code		NAS-Drop-Misc-Non-Error	14
VENDORVALUE 	429	USR-HARC-Disconnect-Code		NAS-Internal-Error	15
VENDORVALUE 	429	USR-HARC-Disconnect-Code		Line-Busy		16
VENDORVALUE 	429	USR-HARC-Disconnect-Code		RESERVED		17
VENDORVALUE 	429	USR-HARC-Disconnect-Code		RESERVED		18
VENDORVALUE 	429	USR-HARC-Disconnect-Code		Tunnel-Term-Unreach	19
VENDORVALUE 	429	USR-HARC-Disconnect-Code		Tunnel-Refused		20
VENDORVALUE 	429	USR-HARC-Disconnect-Code		Tunnel-Auth-Failed	21
VENDORVALUE 	429	USR-HARC-Disconnect-Code		Tunnel-Session-Timeout	22
VENDORVALUE 	429	USR-HARC-Disconnect-Code		Tunnel-Timeout		23
VENDORVALUE 	429	USR-HARC-Disconnect-Code		RESERVED		24
VENDORVALUE 	429	USR-HARC-Disconnect-Code		Radius-Res-Reclaim	25
VENDORVALUE 	429	USR-HARC-Disconnect-Code		DNIS-Auth-Failed	26
VENDORVALUE 	429	USR-HARC-Disconnect-Code		PAP-Auth-Failure	27
VENDORVALUE 	429	USR-HARC-Disconnect-Code		CHAP-Auth-Failure	28
VENDORVALUE 	429	USR-HARC-Disconnect-Code		PPP-LCP-Failed		29
VENDORVALUE 	429	USR-HARC-Disconnect-Code		PPP-NCP-Failed		30
VENDORVALUE 	429	USR-HARC-Disconnect-Code		Radius-Timeout		31

VENDORVALUE 	429	USR-CCP-Algorithm			NONE			1
VENDORVALUE 	429	USR-CCP-Algorithm			Stac			2
VENDORVALUE 	429	USR-CCP-Algorithm			MS			3
VENDORVALUE 	429	USR-CCP-Algorithm			Any			4

VENDORVALUE 	429	USR-Tunnel-Security			None			0
VENDORVALUE 	429	USR-Tunnel-Security			Control-Only		1
VENDORVALUE 	429	USR-Tunnel-Security			Data-Only		2
VENDORVALUE 	429	USR-Tunnel-Security			Both-Data-and-Control	3

VENDORVALUE 	429	USR-RMMIE-Status			notEnabledInLocalModem	1
VENDORVALUE 	429	USR-RMMIE-Status			notDetectedInRemoteModem	2
VENDORVALUE 	429	USR-RMMIE-Status			ok			3

VENDORVALUE 	429	USR-RMMIE-x2-Status			notOperational		1
VENDORVALUE 	429	USR-RMMIE-x2-Status			operational		2
VENDORVALUE 	429	USR-RMMIE-x2-Status			x2Disabled		3
VENDORVALUE 	429	USR-RMMIE-x2-Status			v8Disabled		4
VENDORVALUE 	429	USR-RMMIE-x2-Status			remote3200Disabled	5
VENDORVALUE 	429	USR-RMMIE-x2-Status			invalidSpeedSetting	6
VENDORVALUE 	429	USR-RMMIE-x2-Status			v8NotDetected		7
VENDORVALUE 	429	USR-RMMIE-x2-Status			x2NotDetected		8
VENDORVALUE 	429	USR-RMMIE-x2-Status			incompatibleVersion	9
VENDORVALUE 	429	USR-RMMIE-x2-Status			incompatibleModes	10
VENDORVALUE 	429	USR-RMMIE-x2-Status			local3200Disabled	11
VENDORVALUE 	429	USR-RMMIE-x2-Status			excessHighFrequencyAtten	12
VENDORVALUE 	429	USR-RMMIE-x2-Status			connectNotSupport3200	13
VENDORVALUE 	429	USR-RMMIE-x2-Status			retrainBeforeConnection	14

VENDORVALUE 	429	USR-RMMIE-Planned-Disconnect		none			1
VENDORVALUE 	429	USR-RMMIE-Planned-Disconnect		dteNotReady		2
VENDORVALUE 	429	USR-RMMIE-Planned-Disconnect		dteInterfaceError	3
VENDORVALUE 	429	USR-RMMIE-Planned-Disconnect		dteRequest		4
VENDORVALUE 	429	USR-RMMIE-Planned-Disconnect		escapeToOnlineCommandMode	5
VENDORVALUE 	429	USR-RMMIE-Planned-Disconnect		athCommand		6
VENDORVALUE 	429	USR-RMMIE-Planned-Disconnect		inactivityTimeout	7
VENDORVALUE 	429	USR-RMMIE-Planned-Disconnect		arqProtocolError	8
VENDORVALUE 	429	USR-RMMIE-Planned-Disconnect		arqProtocolRetransmitLim	9
VENDORVALUE 	429	USR-RMMIE-Planned-Disconnect		invalidComprDataCodeword	10
VENDORVALUE 	429	USR-RMMIE-Planned-Disconnect		invalidComprDataStringLen	11
VENDORVALUE 	429	USR-RMMIE-Planned-Disconnect		invalidComprDataCommand	12

VENDORVALUE 	429	USR-RMMIE-Last-Update-Event		none			1
VENDORVALUE 	429	USR-RMMIE-Last-Update-Event		initialConnection	2
VENDORVALUE 	429	USR-RMMIE-Last-Update-Event		retrain			3
VENDORVALUE 	429	USR-RMMIE-Last-Update-Event		speedShift		4
VENDORVALUE 	429	USR-RMMIE-Last-Update-Event		plannedDisconnect	5

VENDORVALUE 	429	USR-Request-Type			Access-Request		1
VENDORVALUE 	429	USR-Request-Type			Access-Accept		2
VENDORVALUE 	429	USR-Request-Type			Access-Reject		3
VENDORVALUE 	429	USR-Request-Type			Accounting-Request	4
VENDORVALUE 	429	USR-Request-Type			Accounting-Response	5
VENDORVALUE 	429	USR-Request-Type			Access-Password-Change	7
VENDORVALUE 	429	USR-Request-Type			Access-Password-Ack	8
VENDORVALUE 	429	USR-Request-Type			Access-Password-Reject	9
VENDORVALUE 	429	USR-Request-Type			Access-Challenge	11
VENDORVALUE 	429	USR-Request-Type			Status-Server		12
VENDORVALUE 	429	USR-Request-Type			Status-Client		13
VENDORVALUE 	429	USR-Request-Type			Resource-Free-Request	21
VENDORVALUE 	429	USR-Request-Type			Resource-Free-Response	22
VENDORVALUE 	429	USR-Request-Type			Resource-Query-Request	23
VENDORVALUE 	429	USR-Request-Type			Resource-Query-Response	24
VENDORVALUE 	429	USR-Request-Type			Disconnect-User		25
VENDORVALUE 	429	USR-Request-Type			NAS-Reboot-Request	26
VENDORVALUE 	429	USR-Request-Type			NAS-Reboot-Response	27
VENDORVALUE 	429	USR-Request-Type			Tacacs-Message		253
VENDORVALUE 	429	USR-Request-Type			Reserved		255

VALUE 	NAS-Port-Type				Virtual			5
VALUE 	NAS-Port-Type				PIAFS			6
VALUE 	NAS-Port-Type				HDLC-Clear-Channel	7
VALUE 	NAS-Port-Type				X.25			8
VALUE 	NAS-Port-Type				X.75			9

VENDORVALUE 	429	USR-PW_Framed_Routing_V2		Off			0
VENDORVALUE 	429	USR-PW_Framed_Routing_V2		On			1

VENDORVALUE 	429	USR-Syslog-Tap				Off			0
VENDORVALUE 	429	USR-Syslog-Tap				Raw			1
VENDORVALUE 	429	USR-Syslog-Tap				Framed			2

VENDORVALUE 	429	USR-Speed-Of-Connection			Auto			0
VENDORVALUE 	429	USR-Speed-Of-Connection			56			1
VENDORVALUE 	429	USR-Speed-Of-Connection			64			2
VENDORVALUE 	429	USR-Speed-Of-Connection			Voice			3

VENDORVALUE 	429	USR-Expansion-Algorithm			Constant		1
VENDORVALUE 	429	USR-Expansion-Algorithm			Linear			2

VENDORVALUE 	429	USR-Compression-Algorithm		None			0
VENDORVALUE 	429	USR-Compression-Algorithm		Stac			1
VENDORVALUE 	429	USR-Compression-Algorithm		Ascend			2
VENDORVALUE 	429	USR-Compression-Algorithm		Microsoft		3
VENDORVALUE 	429	USR-Compression-Algorithm		Auto			4

VENDORVALUE 	429	USR-Compression-Reset-Mode		Auto			0
VENDORVALUE 	429	USR-Compression-Reset-Mode		Reset-Every-Packet	1
VENDORVALUE 	429	USR-Compression-Reset-Mode		Reset-On-Error		2

VENDORVALUE 	429	USR-Filter-Zones			enabled			1
VENDORVALUE 	429	USR-Filter-Zones			disabled		2

VENDORVALUE 	429	USR-Bridging				enabled			1
VENDORVALUE 	429	USR-Bridging				disabled		2

VENDORVALUE 	429	USR-Appletalk				enabled			1
VENDORVALUE 	429	USR-Appletalk				disabled		2

VENDORVALUE 	429	USR-Spoofing				enabled			1
VENDORVALUE 	429	USR-Spoofing				disabled		2

VENDORVALUE 	429	USR-Routing-Protocol			Rip1			1
VENDORVALUE 	429	USR-Routing-Protocol			Rip2			2

VENDORVALUE 	429	USR-IPX-Routing				none			0
VENDORVALUE 	429	USR-IPX-Routing				send			1
VENDORVALUE 	429	USR-IPX-Routing				listen			2
VENDORVALUE 	429	USR-IPX-Routing				respond			3
VENDORVALUE 	429	USR-IPX-Routing				all			4

VENDORVALUE 	429	USR-IPX-WAN				enabled			1
VENDORVALUE 	429	USR-IPX-WAN				disabled		2

VENDORVALUE 	429	USR-IP-Default-Route-Option		enabled			1
VENDORVALUE 	429	USR-IP-Default-Route-Option		disabled		2

VENDORVALUE 	429	USR-IP-RIP-Policies			SendDefault		0x0
VENDORVALUE 	429	USR-IP-RIP-Policies			SendRoutes		0x2
VENDORVALUE 	429	USR-IP-RIP-Policies			SendSubnets		0x4
VENDORVALUE 	429	USR-IP-RIP-Policies			AcceptDefault		0x8
VENDORVALUE 	429	USR-IP-RIP-Policies			SplitHorizon		0x10
VENDORVALUE 	429	USR-IP-RIP-Policies			PoisonReserve		0x20
VENDORVALUE 	429	USR-IP-RIP-Policies			FlashUpdate		0x40
VENDORVALUE 	429	USR-IP-RIP-Policies			SimpleAuth		0x80
VENDORVALUE 	429	USR-IP-RIP-Policies			V1Send			0x100
VENDORVALUE 	429	USR-IP-RIP-Policies			V1Receive		0x200
VENDORVALUE 	429	USR-IP-RIP-Policies			V2Receive		0x400
VENDORVALUE 	429	USR-IP-RIP-Policies			Silent			0x80000000

VENDORVALUE 	429	USR-Callback-Type			Normal			1
VENDORVALUE 	429	USR-Callback-Type			ANI			2
VENDORVALUE 	429	USR-Callback-Type			Static			3
VENDORVALUE 	429	USR-Callback-Type			Dynamic			4

VENDORVALUE 	429	USR-Request-Type			Access-Request		1
VENDORVALUE 	429	USR-Request-Type			Access-Accept		2
VENDORVALUE 	429	USR-Request-Type			Access-Reject		3
VENDORVALUE 	429	USR-Request-Type			Accounting-Request	4
VENDORVALUE 	429	USR-Request-Type			Accounting-Response	5
# The next three non standard packet types are used by
# US Robotics Security/Accounting Server
VENDORVALUE 	429	USR-Request-Type			Access-Password-Change	7
VENDORVALUE 	429	USR-Request-Type			Access-Password-Ack	8
VENDORVALUE 	429	USR-Request-Type			Access-Password-Reject	9
VENDORVALUE 	429	USR-Request-Type			Access-Challenge	11
VENDORVALUE 	429	USR-Request-Type			Status-Server		12
VENDORVALUE 	429	USR-Request-Type			Status-Client		13
# Non standard packet types used by NetServer to implement
# resource management and NAS reboot conditions
VENDORVALUE 	429	USR-Request-Type			Resource-Free-Request	21
VENDORVALUE 	429	USR-Request-Type			Resource-Free-Response	22
VENDORVALUE 	429	USR-Request-Type			Resource-Query-Request	23
VENDORVALUE 	429	USR-Request-Type			Resource-Query-Response	24
VENDORVALUE 	429	USR-Request-Type			Disconnect-User		25
VENDORVALUE 	429	USR-Request-Type			NAS-Reboot-Request	26
VENDORVALUE 	429	USR-Request-Type			NAS-Reboot-Response	27
# This value is used for Tacacs Plus translation
VENDORVALUE 	429	USR-Request-Type			Tacacs-Message		253
VENDORVALUE 	429	USR-Request-Type			Reserved		255

VENDORVALUE 	429	USR-NAS-Type				3Com-NMC		0
VENDORVALUE 	429	USR-NAS-Type				3Com-NETServer		1
VENDORVALUE 	429	USR-NAS-Type				3Com-HiPerArc		2
VENDORVALUE 	429	USR-NAS-Type				TACACS+-Server		3
VENDORVALUE 	429	USR-NAS-Type				3Com-SA-Server		4
VENDORVALUE 	429	USR-NAS-Type				Ascend			5
VENDORVALUE 	429	USR-NAS-Type				Generic-RADIUS		6
VENDORVALUE 	429	USR-NAS-Type				3Com-NETBuilder-II	7

VENDORVALUE 	429	USR-Auth-Mode				Auth-3Com		0
VENDORVALUE 	429	USR-Auth-Mode				Auth-Ace		1
VENDORVALUE 	429	USR-Auth-Mode				Auth-Safeword		2
VENDORVALUE 	429	USR-Auth-Mode				Auth-UNIX-PW		3
VENDORVALUE 	429	USR-Auth-Mode				Auth-Defender		4
VENDORVALUE 	429	USR-Auth-Mode				Auth-TACACSP		5
VENDORVALUE 	429	USR-Auth-Mode				Auth-Netware		6
VENDORVALUE 	429	USR-Auth-Mode				Auth-Skey		7
VENDORVALUE 	429	USR-Auth-Mode				Auth-EAP-Proxy		8
VENDORVALUE 	429	USR-Auth-Mode				Auth-UNIX-Crypt		9
EOD
# This is a dictionary file included with FreeRadius

VENDOR		Cisco		9

#
#	Standard attribute
#
ATTRIBUTE	Cisco-AVPair		1	string		Cisco
ATTRIBUTE	Cisco-NAS-Port		2	string		Cisco

#
#  T.37 Store-and-Forward attributes.
#
ATTRIBUTE       Cisco-Fax-Account-Id-Origin     3       string          Cisco
ATTRIBUTE       Cisco-Fax-Msg-Id                4       string          Cisco
ATTRIBUTE       Cisco-Fax-Pages                 5       string          Cisco
ATTRIBUTE       Cisco-Fax-Coverpage-Flag        6       string          Cisco
ATTRIBUTE       Cisco-Fax-Modem-Time            7       string          Cisco
ATTRIBUTE       Cisco-Fax-Connect-Speed         8       string          Cisco
ATTRIBUTE       Cisco-Fax-Recipient-Count       9       string          Cisco
ATTRIBUTE       Cisco-Fax-Process-Abort-Flag    10      string          Cisco
ATTRIBUTE       Cisco-Fax-Dsn-Address           11      string          Cisco
ATTRIBUTE       Cisco-Fax-Dsn-Flag              12      string          Cisco
ATTRIBUTE       Cisco-Fax-Mdn-Address           13      string          Cisco
ATTRIBUTE       Cisco-Fax-Mdn-Flag              14      string          Cisco
ATTRIBUTE       Cisco-Fax-Auth-Status           15      string          Cisco
ATTRIBUTE       Cisco-Email-Server-Address      16      string          Cisco
ATTRIBUTE       Cisco-Email-Server-Ack-Flag     17      string          Cisco
ATTRIBUTE       Cisco-Gateway-Id                18      string          Cisco
ATTRIBUTE       Cisco-Call-Type                 19      string          Cisco
ATTRIBUTE       Cisco-Port-Used                 20      string          Cisco
ATTRIBUTE       Cisco-Abort-Cause               21      string          Cisco

ATTRIBUTE	h323-remote-address		23	string		Cisco
ATTRIBUTE	h323-conf-id			24	string		Cisco
ATTRIBUTE	h323-setup-time			25	string		Cisco
ATTRIBUTE	h323-call-origin		26	string		Cisco
ATTRIBUTE	h323-call-type			27	string		Cisco
ATTRIBUTE	h323-connect-time		28	string		Cisco
ATTRIBUTE	h323-disconnect-time		29	string		Cisco
ATTRIBUTE	h323-disconnect-cause		30	string		Cisco
ATTRIBUTE	h323-voice-quality		31	string		Cisco
ATTRIBUTE	h323-gw-id			33	string		Cisco
ATTRIBUTE	h323-incoming-conf-id		35	string		Cisco

ATTRIBUTE	h323-credit-amount		101	string		Cisco
ATTRIBUTE	h323-credit-time		102	string		Cisco
ATTRIBUTE	h323-return-code		103	string		Cisco
ATTRIBUTE	h323-prompt-id			104	string		Cisco
ATTRIBUTE	h323-time-and-day		105	string		Cisco
ATTRIBUTE	h323-redirect-number		106	string		Cisco
ATTRIBUTE	h323-preferred-lang		107	string		Cisco
ATTRIBUTE	h323-redirect-ip-address	108	string		Cisco
ATTRIBUTE	h323-billing-model		109	string		Cisco
ATTRIBUTE	h323-currency			110	string		Cisco
ATTRIBUTE	Cisco-Multilink-ID              187     integer		Cisco
ATTRIBUTE	Cisco-Num-In-Multilink          188     integer		Cisco
ATTRIBUTE	Cisco-Pre-Input-Octets          190     integer		Cisco
ATTRIBUTE	Cisco-Pre-Output-Octets         191     integer		Cisco
ATTRIBUTE	Cisco-Pre-Input-Packets         192     integer		Cisco
ATTRIBUTE	Cisco-Pre-Output-Packets        193     integer		Cisco
ATTRIBUTE	Cisco-Maximum-Time              194     integer		Cisco
ATTRIBUTE	Cisco-Disconnect-Cause          195     integer		Cisco
ATTRIBUTE	Cisco-Data-Rate                 197     integer		Cisco
ATTRIBUTE	Cisco-PreSession-Time           198     integer		Cisco
ATTRIBUTE	Cisco-PW-Lifetime               208     integer		Cisco
ATTRIBUTE	Cisco-IP-Direct                 209     integer		Cisco
ATTRIBUTE	Cisco-PPP-VJ-Slot-Comp          210     integer		Cisco
ATTRIBUTE	Cisco-PPP-Async-Map             212     integer		Cisco
ATTRIBUTE	Cisco-IP-Pool-Definition        217     integer		Cisco
ATTRIBUTE	Cisco-Assign-IP-Pool		218     integer		Cisco
ATTRIBUTE	Cisco-Route-IP                  228     integer		Cisco
ATTRIBUTE	Cisco-Link-Compression          233     integer		Cisco
ATTRIBUTE	Cisco-Target-Util               234     integer		Cisco
ATTRIBUTE	Cisco-Maximum-Channels          235     integer		Cisco
ATTRIBUTE	Cisco-Data-Filter               242     integer		Cisco
ATTRIBUTE	Cisco-Call-Filter               243     integer		Cisco
ATTRIBUTE	Cisco-Idle-Limit                244     integer		Cisco
ATTRIBUTE	Cisco-Account-Info		250	string		Cisco
ATTRIBUTE	Cisco-Service-Info		251	string		Cisco
ATTRIBUTE	Cisco-Command-Code		252	string		Cisco
ATTRIBUTE	Cisco-Control-Info		253	string		Cisco
ATTRIBUTE	Cisco-Xmit-Rate                 255     integer		Cisco

VALUE		Cisco-Disconnect-Cause        Unknown                 2
VALUE		Cisco-Disconnect-Cause        CLID-Authentication-Failure     4
VALUE		Cisco-Disconnect-Cause        No-Carrier              10
VALUE		Cisco-Disconnect-Cause        Lost-Carrier            11
VALUE		Cisco-Disconnect-Cause        No-Detected-Result-Codes   12
VALUE		Cisco-Disconnect-Cause        User-Ends-Session       20
VALUE		Cisco-Disconnect-Cause        Idle-Timeout            21
VALUE		Cisco-Disconnect-Cause        Exit-Telnet-Session     22
VALUE		Cisco-Disconnect-Cause        No-Remote-IP-Addr       23
VALUE		Cisco-Disconnect-Cause        Exit-Raw-TCP            24
VALUE		Cisco-Disconnect-Cause        Password-Fail           25
VALUE		Cisco-Disconnect-Cause        Raw-TCP-Disabled        26
VALUE		Cisco-Disconnect-Cause        Control-C-Detected      27
VALUE		Cisco-Disconnect-Cause        EXEC-Program-Destroyed  28
VALUE		Cisco-Disconnect-Cause        Timeout-PPP-LCP         40
VALUE		Cisco-Disconnect-Cause        Failed-PPP-LCP-Negotiation  41
VALUE		Cisco-Disconnect-Cause        Failed-PPP-PAP-Auth-Fail    42
VALUE		Cisco-Disconnect-Cause        Failed-PPP-CHAP-Auth    43
VALUE		Cisco-Disconnect-Cause        Failed-PPP-Remote-Auth  44
VALUE		Cisco-Disconnect-Cause        PPP-Remote-Terminate    45
VALUE		Cisco-Disconnect-Cause        PPP-Closed-Event        46
VALUE		Cisco-Disconnect-Cause        Session-Timeout         100
VALUE		Cisco-Disconnect-Cause        Session-Failed-Security 101
VALUE		Cisco-Disconnect-Cause        Session-End-Callback    102
VALUE		Cisco-Disconnect-Cause        Invalid-Protocol        120
