# =============================================================================
package Net::SNMP::Util::TC;
# -----------------------------------------------------------------------------
$Net::SNMP::Util::TC::VERSION = '1.04';
# -----------------------------------------------------------------------------
use warnings;
use strict;

=head1 NAME

Net::SNMP::Util::TC - Giving Textual Convention of MIBs

=head1 SYNOPSIS

    use Net::SNMP::Util;
    use Net::SNMP::Util::OID qw(if*);
    use Net::SNMP::Util::TC qw(updown iftype);

    $r = snmpget(
        snmp => { -hostname => $host },
        oids => { map oidp("$_.1"), qw/ifName ifType ifAdminStatus ifOperStatus/ }
    );
    my $tc = Net::SNMP::Util::TC->new();

    printf "port:%s index:%d type:%s astat:%s ostat:%s\n",
        $r->{"ifName.1"}, $index, $tc->ifType($r->{"ifType.1"}),
            updown($r->{"ifAdminStatus.1"}),
            updown($r->{"ifOperStatus.1" });


=head1 DESCRIPTION

Module C<Net::SNMP::Util::TC> gives the way to convert some MIB values to
humans recognizable text.

=head1 EXPORT

This module, C<Net::SNMP::Util::OID>, exports C<isup()> and C<updown()>
defalut which are for ifAdminStatus and ifOperStatus to check up or down
simply.

To know status, kind or type fully, make object first and than call method
with MIB value to convert like below;

    $tc = Net::SNMP::Util::TC->new();
    $status = $tc->ifAdminStatus($value);


=cut

use Carp qw();

use constant DEBUG => 0;

use base qw( Exporter );
our (@EXPORT, @EXPORT_OK, %EXPORT_TAGS, $VERSION);
@EXPORT = qw( isup updown );
@EXPORT_OK = qw( updown ifadminstatus ifoperstatus iftype ifrcvaddresstype );


# =============================================================================
my %_TC_base = (

    'ifAdminStatus' => {
        1   => "up",                            # ready to pass packets
        2   => "down",
        3   => "testing",                       # in some test mode
    },

    'ifOperStatus' => {
        1   => "up",                            # ready to pass packets
        2   => "down",
        3   => "testing",                       # in some test mode
        4   => "unknown",                       # status can not be determined
                                                # for some reason.
        5   => "dormant",
        6   => "notPresent",                    # some component is missing
        7   => "lowerLayerDown",                # down due to state of
                                                # lower-layer interface(s)
    },

    # IANAifType ( http://www.iana.org/assignments/ianaiftype-mib )
    # version : "201009210000Z"  -- September 21, 2010
    'ifType' => {
        1   => "other",                         # none of the following
        2   => "regular1822",
        3   => "hdh1822",
        4   => "ddn-x25",
        5   => "rfc877-x25",
        6   => "ethernet-csmacd",               # for all ethernet-like interfaces,
                                                # regardless of speed, as per RFC3635
        7   => "iso88023-csmacd",               # Deprecated via RFC3635
                                                # ethernetCsmacd (6) should be used instead
        8   => "iso88024-tokenBus",
        9   => "iso88025-tokenRing",
        10  => "iso88026-man",
        11  => "starLan",                       # Deprecated via RFC3635
                                                # ethernetCsmacd(6) should be used instead
        12  => "proteon-10Mbit",
        13  => "proteon-80Mbit",
        14  => "hyperchannel",
        15  => "fddi",
        16  => "lapb",
        17  => "sdlc",
        18  => "ds1",                           # DS1-MIB
        19  => "e1",                            # Obsolete see DS1-MIB
        20  => "basicISDN",                     # no longer used. see also RFC2127
        21  => "primaryISDN",                   # no longer used. see also RFC2127
        22  => "propPointToPointSerial",        # proprietary serial
        23  => "ppp",
        24  => "softwareLoopback",
        25  => "eon",                           # CLNP over IP
        26  => "ethernet-3Mbit",
        27  => "nsip",                          # XNS over IP
        28  => "slip",                          # generic SLIP
        29  => "ultra",                         # ULTRA technologies
        30  => "ds3",                           # DS3-MIB
        31  => "sip",                           # SMDS, coffee
        32  => "frame-relay",                   # DTE only.
        33  => "rs232",
        34  => "para",                          # parallel-port
        35  => "arcnet",                        # arcnet
        36  => "arcnetPlus",                    # arcnet plus
        37  => "atm",                           # ATM cells
        38  => "miox25",
        39  => "sonet",                         # SONET or SDH 
        40  => "x25ple",
        41  => "iso88022llc",
        42  => "localTalk",
        43  => "smdsDxi",
        44  => "frameRelayService",             # FRNETSERV-MIB
        45  => "v35",
        46  => "hssi",
        47  => "hippi",
        48  => "modem",                         # Generic modem
        49  => "aal5",                          # AAL5 over ATM
        50  => "sonetPath",
        51  => "sonetVT",
        52  => "smdsIcip",                      # SMDS InterCarrier Interface
        53  => "propVirtual",                   # proprietary virtual/internal
        54  => "propMultiplexor",               # proprietary multiplexing
        55  => "ieee80212",                     # 100BaseVG
        56  => "fibreChannel",                  # Fibre Channel
        57  => "hippiInterface",                # HIPPI interfaces
        58  => "frameRelayInterconnect",        # Obsolete
                                                # use either frameRelay(32) or frameRelayService(44)
        59  => "aflane8023",                    # ATM Emulated LAN for 802.3
        60  => "aflane8025",                    # ATM Emulated LAN for 802.5
        61  => "cctEmul",                       # ATM Emulated circuit
        62  => "fastEther",                     # Obsoleted via RFC3635
                                                # ethernetCsmacd(6) should be used instead
        63  => "isdn",                          # ISDN and X.25
        64  => "v11",                           # CCITT V.11/X.21
        65  => "v36",                           # CCITT V.36
        66  => "g703at64k",                     # CCITT G703 at 64Kbps
        67  => "g703at2mb",                     # Obsolete see DS1-MIB
        68  => "qllc",                          # SNA QLLC
        69  => "fastEtherFX",                   # Obsoleted via RFC3635
                                                # ethernetCsmacd(6) should be used instead
        70  => "channel",                       # channel
        71  => "ieee80211",                     # radio spread spectrum
        72  => "ibm370parChan",                 # IBM System 360/370 OEMI Channel
        73  => "escon",                         # IBM Enterprise Systems Connection
        74  => "dlsw",                          # Data Link Switching
        75  => "isdns",                         # ISDN S/T interface
        76  => "isdnu",                         # ISDN U interface
        77  => "lapd",                          # Link Access Protocol D
        78  => "ipSwitch",                      # IP Switching Objects
        79  => "rsrb",                          # Remote Source Route Bridging
        80  => "atmLogical",                    # ATM Logical Port
        81  => "ds0",                           # Digital Signal Level 0
        82  => "ds0Bundle",                     # group of ds0s on the same ds1
        83  => "bsc",                           # Bisynchronous Protocol
        84  => "async",                         # Asynchronous Protocol
        85  => "cnr",                           # Combat Net Radio
        86  => "iso88025Dtr",                   # ISO 802.5r DTR
        87  => "eplrs",                         # Ext Pos Loc Report Sys
        88  => "arap",                          # Appletalk Remote Access Protocol
        89  => "propCnls",                      # Proprietary Connectionless Protocol
        90  => "hostPad",                       # CCITT-ITU X.29 PAD Protocol
        91  => "termPad",                       # CCITT-ITU X.3 PAD Facility
        92  => "frameRelayMPI",                 # Multiproto Interconnect over FR
        93  => "x213",                          # CCITT-ITU X213
        94  => "adsl",                          # Asymmetric Digital Subscriber Loop
        95  => "radsl",                         # Rate-Adapt. Digital Subscriber Loop
        96  => "sdsl",                          # Symmetric Digital Subscriber Loop
        97  => "vdsl",                          # Very H-Speed Digital Subscrib. Loop
        98  => "iso88025CRFPInt",               # ISO 802.5 CRFP
        99  => "myrinet",                       # Myricom Myrinet
        100 => "voiceEM",                       # voice recEive and transMit
        101 => "voiceFXO",                      # voice Foreign Exchange Office
        102 => "voiceFXS",                      # voice Foreign Exchange Station
        103 => "voiceEncap",                    # voice encapsulation
        104 => "voiceOverIp",                   # voice over IP encapsulation
        105 => "atmDxi",                        # ATM DXI
        106 => "atmFuni",                       # ATM FUNI
        107 => "atmIma",                        # ATM IMA
        108 => "pppMultilinkBundle",            # PPP Multilink Bundle
        109 => "ipOverCdlc",                    # IBM ipOverCdlc
        110 => "ipOverClaw",                    # IBM Common Link Access to Workstn
        111 => "stackToStack",                  # IBM stackToStack
        112 => "virtualIpAddress",              # IBM VIPA
        113 => "mpc",                           # IBM multi-protocol channel support
        114 => "ipOverAtm",                     # IBM ipOverAtm
        115 => "iso88025Fiber",                 # ISO 802.5j Fiber Token Ring
        116 => "tdlc",	                        # IBM twinaxial data link control
        117 => "gigabitEthernet",               # Obsoleted via RFC3635
                                                # ethernetCsmacd(6) should be used instead
        118 => "hdlc",                          # HDLC
        119 => "lapf",	                        # LAP F
        120 => "v37",	                        # V.37
        121 => "x25mlp",                        # Multi-Link Protocol
        122 => "x25huntGroup",                  # X25 Hunt Group
        123 => "transpHdlc",                    # Transp HDLC
        124 => "interleave",                    # Interleave channel
        125 => "fast",                          # Fast channel
        126 => "ip",	                        # IP (for APPN HPR in IP networks)
        127 => "docsCableMaclayer",             # CATV Mac Layer
        128 => "docsCableDownstream",           # CATV Downstream interface
        129 => "docsCableUpstream",             # CATV Upstream interface
        130 => "a12MppSwitch",                  # Avalon Parallel Processor
        131 => "tunnel",                        # Encapsulation interface
        132 => "coffee",                        # coffee pot
        133 => "ces",                           # Circuit Emulation Service
        134 => "atmSubInterface",               # ATM Sub Interface
        135 => "l2vlan",                        # Layer 2 Virtual LAN using 802.1Q
        136 => "l3ipvlan",                      # Layer 3 Virtual LAN using IP
        137 => "l3ipxvlan",                     # Layer 3 Virtual LAN using IPX
        138 => "digitalPowerline",              # IP over Power Lines	
        139 => "mediaMailOverIp",               # Multimedia Mail over IP
        140 => "dtm",                           # Dynamic syncronous Transfer Mode
        141 => "dcn",                           # Data Communications Network
        142 => "ipForward",                     # IP Forwarding Interface
        143 => "msdsl",                         # Multi-rate Symmetric DSL
        144 => "ieee1394",                      # IEEE1394 High Performance Serial Bus
        145 => "if-gsn",                        # HIPPI-6400
        146 => "dvbRccMacLayer",                # DVB-RCC MAC Layer
        147 => "dvbRccDownstream",              # DVB-RCC Downstream Channel
        148 => "dvbRccUpstream",                # DVB-RCC Upstream Channel
        149 => "atmVirtual",                    # ATM Virtual Interface
        150 => "mplsTunnel",                    # MPLS Tunnel Virtual Interface
        151 => "srp",                           # Spatial Reuse Protocol
        152 => "voiceOverAtm",                  # Voice Over ATM
        153 => "voiceOverFrameRelay",           # Voice Over Frame Relay
        154 => "idsl",                          # Digital Subscriber Loop over ISDN
        155 => "compositeLink",                 # Avici Composite Link Interface
        156 => "ss7SigLink",                    # SS7 Signaling Link
        157 => "propWirelessP2P",               # Prop. P2P wireless interface
        158 => "frForward",                     # Frame Forward Interface
        159 => "rfc1483",                       # Multiprotocol over ATM AAL5
        160 => "usb",                           # USB Interface
        161 => "ieee8023adLag",                 # IEEE 802.3ad Link Aggregate
        162 => "bgppolicyaccounting",           # BGP Policy Accounting
        163 => "frf16MfrBundle",                # FRF .16 Multilink Frame Relay
        164 => "h323Gatekeeper",                # H323 Gatekeeper
        165 => "h323Proxy",                     # H323 Voice and Video Proxy
        166 => "mpls",                          # MPLS
        167 => "mfSigLink",                     # Multi-frequency signaling link
        168 => "hdsl2",                         # High Bit-Rate DSL - 2nd generation
        169 => "shdsl",                         # Multirate HDSL2
        170 => "ds1FDL",                        # Facility Data Link 4Kbps on a DS1
        171 => "pos",                           # Packet over SONET/SDH Interface
        172 => "dvbAsiIn",                      # DVB-ASI Input
        173 => "dvbAsiOut",                     # DVB-ASI Output
        174 => "plc",                           # Power Line Communtications
        175 => "nfas",                          # Non Facility Associated Signaling
        176 => "tr008",                         # TR008
        177 => "gr303RDT",                      # Remote Digital Terminal
        178 => "gr303IDT",                      # Integrated Digital Terminal
        179 => "isup",                          # ISUP
        180 => "propDocsWirelessMaclayer",      # Cisco proprietary Maclayer
        181 => "propDocsWirelessDownstream",    # Cisco proprietary Downstream
        182 => "propDocsWirelessUpstream",      # Cisco proprietary Upstream
        183 => "hiperlan2",                     # HIPERLAN Type 2 Radio Interface
        184 => "propBWAp2Mp",                   # PropBroadbandWirelessAccesspt2multipt
                                                # use of this iftype for IEEE 802.16 WMAN
                                                # interfaces as per IEEE Std 802.16f is
                                                # deprecated and ifType 237 should be used instead.
        185 => "sonetOverheadChannel",          # SONET Overhead Channel
        186 => "digitalWrapperOverheadChannel", # Digital Wrapper
        187 => "aal2",                          # ATM adaptation layer 2
        188 => "radioMAC",                      # MAC layer over radio links
        189 => "atmRadio",                      # ATM over radio links
        190 => "imt",                           # Inter Machine Trunks
        191 => "mvl",                           # Multiple Virtual Lines DSL
        192 => "reachDSL",                      # Long Reach DSL
        193 => "frDlciEndPt",                   # Frame Relay DLCI End Point
        194 => "atmVciEndPt",                   # ATM VCI End Point
        195 => "opticalChannel",                # Optical Channel
        196 => "opticalTransport",              # Optical Transport
        197 => "propAtm",                       #  Proprietary ATM
        198 => "voiceOverCable",                # Voice Over Cable Interface
        199 => "infiniband",                    # Infiniband
        200 => "teLink",                        # TE Link
        201 => "q2931",                         # Q.2931
        202 => "virtualTg",                     # Virtual Trunk Group
        203 => "sipTg",                         # SIP Trunk Group
        204 => "sipSig",                        # SIP Signaling
        205 => "docsCableUpstreamChannel",      # CATV Upstream Channel
        206 => "econet",                        # Acorn Econet
        207 => "pon155",                        # FSAN 155Mb Symetrical PON interface
        208 => "pon622",                        # FSAN622Mb Symetrical PON interface
        209 => "bridge",                        # Transparent bridge interface
        210 => "linegroup",                     # Interface common to multiple lines
        211 => "voiceEMFGD",                    # voice E&M Feature Group D
        212 => "voiceFGDEANA",                  # voice FGD Exchange Access North American
        213 => "voiceDID",                      # voice Direct Inward Dialing
        214 => "mpegTransport",                 # MPEG transport interface
        215 => "sixToFour",                     # 6to4 interface (DEPRECATED)
        216 => "gtp",                           # GTP (GPRS Tunneling Protocol)
        217 => "pdnEtherLoop1",                 # Paradyne EtherLoop 1
        218 => "pdnEtherLoop2",                 # Paradyne EtherLoop 2
        219 => "opticalChannelGroup",           # Optical Channel Group
        220 => "homepna",                       # HomePNA ITU-T G.989
        221 => "gfp",                           # Generic Framing Procedure (GFP)
        222 => "ciscoISLvlan",                  # Layer 2 Virtual LAN using Cisco ISL
        223 => "actelisMetaLOOP",               # Acteleis proprietary MetaLOOP High Speed Link
        224 => "fcipLink",                      # FCIP Link
        225 => "rpr",                           # Resilient Packet Ring Interface Type
        226 => "qam",                           # RF Qam Interface
        227 => "lmp",                           # Link Management Protocol
        228 => "cblVectaStar",                  # Cambridge Broadband Networks Limited VectaStar
        229 => "docsCableMCmtsDownstream",      # CATV Modular CMTS Downstream Interface
        230 => "adsl2",                         # Asymmetric Digital Subscriber Loop Version 2
                                                # (DEPRECATED/OBSOLETED - please use adsl2plus 238 instead)
        231 => "macSecControlledIF",            # MACSecControlled
        232 => "macSecUncontrolledIF",          # MACSecUncontrolled
        233 => "aviciOpticalEther",             # Avici Optical Ethernet Aggregate
        234 => "atmbond",                       # atmbond
        235 => "voiceFGDOS",                    # voice FGD Operator Services
        236 => "mocaVersion1",                  # MultiMedia over Coax Alliance (MoCA) Interface
                                                # as documented in information provided privately to IANA
        237 => "ieee80216WMAN",                 # IEEE 802.16 WMAN interface
        238 => "adsl2plus",                     # Asymmetric Digital Subscriber Loop Version 2,
                                                # Version 2 Plus and all variants
        239 => "dvbRcsMacLayer",                # DVB-RCS MAC Layer
        240 => "dvbTdm",                        # DVB Satellite TDM
        241 => "dvbRcsTdma",                    # DVB-RCS TDMA
        242 => "x86Laps",                       # LAPS based on ITU-T X.86/Y.1323
        243 => "wwanPP",                        # 3GPP WWAN
        244 => "wwanPP2",                       # 3GPP2 WWAN
        245 => "voiceEBS",                      # voice P-phone EBS physical interface
        246 => "ifPwType",                      # Pseudowire interface type
        247 => "ilan",                          # Internal LAN on a bridge per IEEE 802.1ap
        248 => "pip",                           # Provider Instance Port on a bridge per IEEE 802.1ah PBB
        249 => "aluELP",                        # Alcatel-Lucent Ethernet Link Protection
        250 => "gpon",                          # Gigabit-capable passive optical networks (G-PON) as per ITU-T G.948
        251 => "vdsl2",                         # Very high speed digital subscriber line Version 2
                                                # (as per ITU-T Recommendation G.993.2)
        252 => "capwapDot11Profile",            # WLAN Profile Interface
        253 => "capwapDot11Bss",                # WLAN BSS Interface
        254 => "capwapWtpVirtualRadio",         # WTP Virtual Radio Interface
        255 => "bits",                          # bitsport
        256 => "docsCableUpstreamRfPort",       # DOCSIS CATV Upstream RF Port
        257 => "cableDownstreamRfPort "         # CATV downstream RF port
    },

    'ifRcvAddressType' => {
        1   => "other",
        2   => "volatile",
        3   => "nonVolatile",
    },

    # SNMPv2-TC
    'TruthValue' => {   # RFC-1903
        1   => 'true',
        2   => 'false',
    },

    'StorageType' => {
        1   => "other",
        2   => "volatile",                      # e.g., in RAM
        3   => "nonVolatile",                   # e.g., in NVRAM
        4   => "permanent",                     # e.g., partially in ROM
        5   => "readOnly",                      # e.g., completely in ROM
    },

);


# =============================================================================


=head1 FUNCTIONS

=head2 isup()

    isup( $value );

If $value is "1", function returns 1. If values else this returns 0.

=head2 updown()

    updown( $value );

If $value is "1", function returns string 'up'. Else returns 'down'.

=cut

# -----------------------------------------------------------------------------
sub isup
{
    my $value = shift || 0;
    return ($value eq "1")? 1: 0;
}

sub updown
{
    return isup(@_)? 'up': 'down';
}

# =============================================================================
=head1 METHODS

=head2 new()

    $tc = Net::SNMP::Util::TC->new();

First creat an object for conversion. No arguments are need for this class.
Then call method, which name is same as MIB name, with passing value you want to
convert. e.g.;

    $type = $tc->ifType( 132 );     # "coffee"

=head2 Avaiable Methods

Textual conversion methods now avaiable are;

=over

=item ifAdminStatus()

For conversion value of MIB ifAdminStatus.

=item ifOperStatus()

For conversion value of MIB ifOperStatus.

=item ifType()

For conversion value of MIB ifType. MIB ifType is now defined as IANAifType.

=item ifRcvAddressType()

For conversion value of MIB ifRcvAddressType.

=item TruthValue()

For conversion value of MIB TruthValue.

=item StorageType()

For conversion value of MIB StorageType.

=back

=cut

sub new {
    my $class = shift;
    bless \eval{ my $s }, $class;
}

# =============================================================================

=head1 METHODS

=cut

sub AUTOLOAD
{
    my ($self, $value) = @_;
    my $method = our $AUTOLOAD;     # $method = MIB name

    $method =~ s/.*:://o;

    if ( exists $_TC_base{$method} )
    {
        no strict 'refs';
        *{$method} = sub {
            my ($s,$v) = @_;
            if ( defined $v ){
                return $_TC_base{$method}->{$v};
            } else {
                Carp("Undefined value was given");
            }
            return undef;
        };
        return $method->($self,$value);
    }
    return undef;
}

sub DESTROY {}

# -----------------------------------------------------------------------------

=head2 TRUE()

This method always returns 1 which is defined as true value in MIB TruthValue
at RFC-1903.

=head2 FALSE()

This method always returns 2 which is defined as false value in MIB TruthValue
at RFC-1903.

=cut

# -----------------------------------------------------------------------------
sub TRUE  { 1 };
sub FALSE { 2 };


# =============================================================================

=head1 AUTHOR

t.onodera, C<< <cpan :: garakuta.net> >>

=head1 SEE ALSO

L<Net::SNMP::Util>, L<Net::SNMP::Util::OID>

=head1 LICENSE AND COPYRIGHT

Copyright(C) 2010 Takahiro Ondoera.

This program is free software; you may redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

1; # End of Net::SNMP::Util::TC