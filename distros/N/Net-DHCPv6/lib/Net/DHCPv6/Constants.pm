#!/bin/false
# ABSTRACT: DHCPv6 numeric constants (message types, option codes, status codes, DUID types, client architecture types, link-layer types)
# PODNAME: Net::DHCPv6::Constants
use strictures 2;

package Net::DHCPv6::Constants;
$Net::DHCPv6::Constants::VERSION = '0.002';
use Const::Fast::Exporter qw( const );

# Message types (RFC 8415 Section 14)
const our $SOLICIT             => 1;
const our $ADVERTISE           => 2;
const our $REQUEST             => 3;
const our $CONFIRM             => 4;
const our $RENEW               => 5;
const our $REBIND              => 6;
const our $REPLY               => 7;
const our $RELEASE             => 8;
const our $DECLINE             => 9;
const our $RECONFIGURE         => 10;
const our $INFORMATION_REQUEST => 11;
const our $RELAY_FORW          => 12;
const our $RELAY_REPLY         => 13;

# Option codes (RFC 8415 Section 21)
const our $OPTION_CLIENTID                 => 1;
const our $OPTION_SERVERID                 => 2;
const our $OPTION_IA_NA                    => 3;
const our $OPTION_IA_TA                    => 4;
const our $OPTION_IAADDR                   => 5;
const our $OPTION_ORO                      => 6;
const our $OPTION_PREFERENCE               => 7;
const our $OPTION_ELAPSED_TIME             => 8;
const our $OPTION_RELAY_MSG                => 9;
const our $OPTION_AUTH                     => 11;
const our $OPTION_UNICAST                  => 12;
const our $OPTION_STATUS_CODE              => 13;
const our $OPTION_RAPID_COMMIT             => 14;
const our $OPTION_USER_CLASS               => 15;
const our $OPTION_VENDOR_CLASS             => 16;
const our $OPTION_VENDOR_OPTS              => 17;
const our $OPTION_INTERFACE_ID             => 18;
const our $OPTION_RECONF_MSG               => 19;
const our $OPTION_RECONF_ACCEPT            => 20;
const our $OPTION_SIP_SERVER_D             => 21;
const our $OPTION_SIP_SERVER_A             => 22;
const our $OPTION_DNS_SERVERS              => 23;
const our $OPTION_DOMAIN_LIST              => 24;
const our $OPTION_IA_PD                    => 25;
const our $OPTION_IAPREFIX                 => 26;
const our $OPTION_NIS_SERVERS              => 27;
const our $OPTION_NISP_SERVERS             => 28;
const our $OPTION_NIS_DOMAIN_NAME          => 29;
const our $OPTION_NISP_DOMAIN_NAME         => 30;
const our $OPTION_SNTP_SERVERS             => 31;
const our $OPTION_INFORMATION_REFRESH_TIME => 32;
const our $OPTION_REMOTE_ID                => 37;
const our $OPTION_SUBSCRIBER_ID            => 38;
const our $OPTION_CLIENT_FQDN              => 39;
const our $OPTION_NEW_POSIX_TIMEZONE       => 41;
const our $OPTION_NEW_TZDB_TIMEZONE        => 42;
const our $OPTION_NTP_SERVER               => 56;
const our $OPTION_BOOTFILE_URL             => 59;
const our $OPTION_BOOTFILE_PARAM           => 60;
const our $OPTION_CLIENT_ARCH_TYPE         => 61;
const our $OPTION_AFTR_NAME                => 64;
const our $OPTION_RSOO                     => 66;
const our $OPTION_PD_EXCLUDE               => 67;
const our $OPTION_CLIENT_LINKLAYER_ADDR    => 79;
const our $OPTION_SOL_MAX_RT               => 82;
const our $OPTION_INF_MAX_RT               => 83;
const our $OPTION_CAPTIVE_PORTAL           => 103;
const our $OPTION_MUD_URL                  => 112;

# Client FQDN flags (RFC 4704 Section 4)
const our $CLIENT_FQDN_S => 0x01;    # Server should NOT update DNS
const our $CLIENT_FQDN_O => 0x02;    # Server override
const our $CLIENT_FQDN_N => 0x04;    # Server should update DNS

# Status codes (RFC 8415 Section 18.3)
const our $STATUS_SUCCESS         => 0;
const our $STATUS_UNSPEC_FAIL     => 1;
const our $STATUS_NO_ADDRS_AVAIL  => 2;
const our $STATUS_NO_BINDING      => 3;
const our $STATUS_NOT_ON_LINK     => 4;
const our $STATUS_USE_MULTICAST   => 5;
const our $STATUS_NO_PREFIX_AVAIL => 6;

# DUID types (RFC 8415 Section 11)
const our $DUID_LLT  => 1;
const our $DUID_EN   => 2;
const our $DUID_LL   => 3;
const our $DUID_UUID => 4;

# Client architecture types (IANA Processor Architecture Types, RFC 5970)
const our $CLIENT_ARCH_X86_BIOS               => 0;
const our $CLIENT_ARCH_NEC_PC98               => 1;    # DEPRECATED
const our $CLIENT_ARCH_ITANIUM                => 2;
const our $CLIENT_ARCH_DEC_ALPHA              => 3;    # DEPRECATED
const our $CLIENT_ARCH_ARC_X86                => 4;    # DEPRECATED
const our $CLIENT_ARCH_INTEL_LEAN_CLIENT      => 5;    # DEPRECATED
const our $CLIENT_ARCH_X86_UEFI               => 6;
const our $CLIENT_ARCH_X64_UEFI               => 7;
const our $CLIENT_ARCH_EFI_XSCALE             => 8;    # DEPRECATED
const our $CLIENT_ARCH_EBC                    => 9;
const our $CLIENT_ARCH_ARM_32_UEFI            => 10;
const our $CLIENT_ARCH_ARM_64_UEFI            => 11;
const our $CLIENT_ARCH_PPC_OPEN_FIRMWARE      => 12;
const our $CLIENT_ARCH_PPC_EPAPR              => 13;
const our $CLIENT_ARCH_POWER_OPAL_V3          => 14;
const our $CLIENT_ARCH_X86_UEFI_HTTP          => 15;
const our $CLIENT_ARCH_X64_UEFI_HTTP          => 16;
const our $CLIENT_ARCH_EBC_HTTP               => 17;
const our $CLIENT_ARCH_ARM_32_UEFI_HTTP       => 18;
const our $CLIENT_ARCH_ARM_64_UEFI_HTTP       => 19;
const our $CLIENT_ARCH_PC_AT_BIOS_HTTP        => 20;
const our $CLIENT_ARCH_ARM_32_UBOOT           => 21;
const our $CLIENT_ARCH_ARM_64_UBOOT           => 22;
const our $CLIENT_ARCH_ARM_UBOOT_32_HTTP      => 23;
const our $CLIENT_ARCH_ARM_UBOOT_64_HTTP      => 24;
const our $CLIENT_ARCH_RISCV_32_UEFI          => 25;
const our $CLIENT_ARCH_RISCV_32_UEFI_HTTP     => 26;
const our $CLIENT_ARCH_RISCV_64_UEFI          => 27;
const our $CLIENT_ARCH_RISCV_64_UEFI_HTTP     => 28;
const our $CLIENT_ARCH_RISCV_128_UEFI         => 29;
const our $CLIENT_ARCH_RISCV_128_UEFI_HTTP    => 30;
const our $CLIENT_ARCH_S390_BASIC             => 31;
const our $CLIENT_ARCH_S390_EXTENDED          => 32;
const our $CLIENT_ARCH_MIPS_32_UEFI           => 33;
const our $CLIENT_ARCH_MIPS_64_UEFI           => 34;
const our $CLIENT_ARCH_SUNWAY_32_UEFI         => 35;
const our $CLIENT_ARCH_SUNWAY_64_UEFI         => 36;
const our $CLIENT_ARCH_LOONGARCH_32_UEFI      => 37;
const our $CLIENT_ARCH_LOONGARCH_32_UEFI_HTTP => 38;
const our $CLIENT_ARCH_LOONGARCH_64_UEFI      => 39;
const our $CLIENT_ARCH_LOONGARCH_64_UEFI_HTTP => 40;
const our $CLIENT_ARCH_ARM_RPIBOOT            => 41;

# Link-layer types (IANA ARP Hardware Type registry)
const our $LINK_TYPE_RESERVED        => 0;
const our $LINK_TYPE_ETHERNET        => 1;
const our $LINK_TYPE_EXP_ETHERNET    => 2;
const our $LINK_TYPE_AX25            => 3;
const our $LINK_TYPE_PRONET          => 4;
const our $LINK_TYPE_CHAOS           => 5;
const our $LINK_TYPE_IEEE802         => 6;
const our $LINK_TYPE_ARCNET          => 7;
const our $LINK_TYPE_HYPERCHANNEL    => 8;
const our $LINK_TYPE_LANSTAR         => 9;
const our $LINK_TYPE_AUTONET         => 10;
const our $LINK_TYPE_LOCALTALK       => 11;
const our $LINK_TYPE_LOCALNET        => 12;
const our $LINK_TYPE_ULTRA           => 13;
const our $LINK_TYPE_SMDS            => 14;
const our $LINK_TYPE_FRAME_RELAY     => 15;
const our $LINK_TYPE_ATM             => 16;
const our $LINK_TYPE_HDLC            => 17;
const our $LINK_TYPE_FIBRE_CHANNEL   => 18;
const our $LINK_TYPE_ATM_RFC2225     => 19;
const our $LINK_TYPE_SERIAL          => 20;
const our $LINK_TYPE_ATM_ALT         => 21;
const our $LINK_TYPE_MIL_STD_188_220 => 22;
const our $LINK_TYPE_METRICOM        => 23;
const our $LINK_TYPE_IEEE1394        => 24;
const our $LINK_TYPE_MAPOS           => 25;
const our $LINK_TYPE_TWINAXIAL       => 26;
const our $LINK_TYPE_EUI64           => 27;
const our $LINK_TYPE_HIPARP          => 28;
const our $LINK_TYPE_ISO7816         => 29;
const our $LINK_TYPE_ARP_SEC         => 30;
const our $LINK_TYPE_IPSEC_TUNNEL    => 31;
const our $LINK_TYPE_INFINIBAND      => 32;
const our $LINK_TYPE_TIA_102         => 33;
const our $LINK_TYPE_WIEGAND         => 34;
const our $LINK_TYPE_PURE_IP         => 35;
const our $LINK_TYPE_HW_EXP1         => 36;
const our $LINK_TYPE_HFI             => 37;
const our $LINK_TYPE_UNIFIED_BUS     => 38;
const our $LINK_TYPE_HW_EXP2         => 256;
const our $LINK_TYPE_AETHERNET       => 257;
const our $LINK_TYPE_RESERVED_HIGH   => 65_535;

# Reverse lookup hashes
our %REV_CLIENT_ARCH;
our %REV_DUID_TYPE;
our %REV_LINK_TYPE;
our %REV_MESSAGE_TYPE;
our %REV_OPTION_CODE;
our %REV_STATUS_CODE;

# Wire-format sizes (byte lengths of protocol fields)
const our $IPV6_ADDR_LEN => 16;

# Domain name label compression (RFC 1035 Section 4.1.4)
const our $DN_COMPRESS_MASK => 0xC0;
const our $DN_LABEL_MASK    => 0x3F;

# placed after const declarations so const remains available during compile-time declarations;
# Const::Fast::Exporter installs `import` at use-time, so it must survive namespace::clean
use namespace::clean ();

BEGIN {    ## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
    %REV_CLIENT_ARCH = (
        0  => 'X86_BIOS',
        1  => 'NEC_PC98',
        2  => 'ITANIUM',
        3  => 'DEC_ALPHA',
        4  => 'ARC_X86',
        5  => 'INTEL_LEAN_CLIENT',
        6  => 'X86_UEFI',
        7  => 'X64_UEFI',
        8  => 'EFI_XSCALE',
        9  => 'EBC',
        10 => 'ARM_32_UEFI',
        11 => 'ARM_64_UEFI',
        12 => 'PPC_OPEN_FIRMWARE',
        13 => 'PPC_EPAPR',
        14 => 'POWER_OPAL_V3',
        15 => 'X86_UEFI_HTTP',
        16 => 'X64_UEFI_HTTP',
        17 => 'EBC_HTTP',
        18 => 'ARM_32_UEFI_HTTP',
        19 => 'ARM_64_UEFI_HTTP',
        20 => 'PC_AT_BIOS_HTTP',
        21 => 'ARM_32_UBOOT',
        22 => 'ARM_64_UBOOT',
        23 => 'ARM_UBOOT_32_HTTP',
        24 => 'ARM_UBOOT_64_HTTP',
        25 => 'RISCV_32_UEFI',
        26 => 'RISCV_32_UEFI_HTTP',
        27 => 'RISCV_64_UEFI',
        28 => 'RISCV_64_UEFI_HTTP',
        29 => 'RISCV_128_UEFI',
        30 => 'RISCV_128_UEFI_HTTP',
        31 => 'S390_BASIC',
        32 => 'S390_EXTENDED',
        33 => 'MIPS_32_UEFI',
        34 => 'MIPS_64_UEFI',
        35 => 'SUNWAY_32_UEFI',
        36 => 'SUNWAY_64_UEFI',
        37 => 'LOONGARCH_32_UEFI',
        38 => 'LOONGARCH_32_UEFI_HTTP',
        39 => 'LOONGARCH_64_UEFI',
        40 => 'LOONGARCH_64_UEFI_HTTP',
        41 => 'ARM_RPIBOOT',
    );

    %REV_LINK_TYPE = (
        0      => 'RESERVED',
        1      => 'ETHERNET',
        2      => 'EXP_ETHERNET',
        3      => 'AX25',
        4      => 'PRONET',
        5      => 'CHAOS',
        6      => 'IEEE802',
        7      => 'ARCNET',
        8      => 'HYPERCHANNEL',
        9      => 'LANSTAR',
        10     => 'AUTONET',
        11     => 'LOCALTALK',
        12     => 'LOCALNET',
        13     => 'ULTRA',
        14     => 'SMDS',
        15     => 'FRAME_RELAY',
        16     => 'ATM',
        17     => 'HDLC',
        18     => 'FIBRE_CHANNEL',
        19     => 'ATM_RFC2225',
        20     => 'SERIAL',
        21     => 'ATM_ALT',
        22     => 'MIL_STD_188_220',
        23     => 'METRICOM',
        24     => 'IEEE1394',
        25     => 'MAPOS',
        26     => 'TWINAXIAL',
        27     => 'EUI64',
        28     => 'HIPARP',
        29     => 'ISO7816',
        30     => 'ARP_SEC',
        31     => 'IPSEC_TUNNEL',
        32     => 'INFINIBAND',
        33     => 'TIA_102',
        34     => 'WIEGAND',
        35     => 'PURE_IP',
        36     => 'HW_EXP1',
        37     => 'HFI',
        38     => 'UNIFIED_BUS',
        256    => 'HW_EXP2',
        257    => 'AETHERNET',
        65_535 => 'RESERVED_HIGH',
    );

    %REV_DUID_TYPE = (
        1 => 'DUID_LLT',
        2 => 'DUID_EN',
        3 => 'DUID_LL',
        4 => 'DUID_UUID',
    );

    %REV_MESSAGE_TYPE = (
        1  => 'SOLICIT',
        2  => 'ADVERTISE',
        3  => 'REQUEST',
        4  => 'CONFIRM',
        5  => 'RENEW',
        6  => 'REBIND',
        7  => 'REPLY',
        8  => 'RELEASE',
        9  => 'DECLINE',
        10 => 'RECONFIGURE',
        11 => 'INFORMATION_REQUEST',
        12 => 'RELAY_FORW',
        13 => 'RELAY_REPLY',
    );

    %REV_OPTION_CODE = (
        1   => 'CLIENTID',
        2   => 'SERVERID',
        3   => 'IA_NA',
        4   => 'IA_TA',
        5   => 'IAADDR',
        6   => 'ORO',
        7   => 'PREFERENCE',
        8   => 'ELAPSED_TIME',
        9   => 'RELAY_MSG',
        11  => 'AUTH',
        12  => 'UNICAST',
        13  => 'STATUS_CODE',
        14  => 'RAPID_COMMIT',
        15  => 'USER_CLASS',
        16  => 'VENDOR_CLASS',
        17  => 'VENDOR_OPTS',
        18  => 'INTERFACE_ID',
        19  => 'RECONF_MSG',
        20  => 'RECONF_ACCEPT',
        21  => 'SIP_SERVER_D',
        22  => 'SIP_SERVER_A',
        23  => 'DNS_SERVERS',
        24  => 'DOMAIN_LIST',
        25  => 'IA_PD',
        26  => 'IAPREFIX',
        27  => 'NIS_SERVERS',
        28  => 'NISP_SERVERS',
        29  => 'NIS_DOMAIN_NAME',
        30  => 'NISP_DOMAIN_NAME',
        31  => 'SNTP_SERVERS',
        32  => 'INFORMATION_REFRESH_TIME',
        37  => 'REMOTE_ID',
        38  => 'SUBSCRIBER_ID',
        39  => 'CLIENT_FQDN',
        41  => 'NEW_POSIX_TIMEZONE',
        42  => 'NEW_TZDB_TIMEZONE',
        56  => 'NTP_SERVER',
        59  => 'BOOTFILE_URL',
        60  => 'BOOTFILE_PARAM',
        61  => 'CLIENT_ARCH_TYPE',
        64  => 'AFTR_NAME',
        66  => 'RSOO',
        67  => 'PD_EXCLUDE',
        79  => 'CLIENT_LINKLAYER_ADDR',
        82  => 'SOL_MAX_RT',
        83  => 'INF_MAX_RT',
        103 => 'CAPTIVE_PORTAL',
        112 => 'MUD_URL',
    );

    %REV_STATUS_CODE = (
        0 => 'SUCCESS',
        1 => 'UNSPEC_FAIL',
        2 => 'NO_ADDRS_AVAIL',
        3 => 'NO_BINDING',
        4 => 'NOT_ON_LINK',
        5 => 'USE_MULTICAST',
        6 => 'NO_PREFIX_AVAIL',
    );
}

sub message_type_name {
    my ( $code ) = @_;
    return $REV_MESSAGE_TYPE{$code};
}

sub option_name {
    my ( $code ) = @_;
    return $REV_OPTION_CODE{$code};
}

sub status_name {
    my ( $code ) = @_;
    return $REV_STATUS_CODE{$code};
}

sub is_valid_message_type {
    my ( $code ) = @_;
    return exists $REV_MESSAGE_TYPE{$code};
}

sub arch_name {
    my ( $code ) = @_;
    return $REV_CLIENT_ARCH{$code};
}

sub link_type_name {
    my ( $code ) = @_;
    return $REV_LINK_TYPE{$code};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Net::DHCPv6::Constants - DHCPv6 numeric constants (message types, option codes, status codes, DUID types, client architecture types, link-layer types)

=head1 VERSION

version 0.002

=head1 SYNOPSIS

  use Net::DHCPv6::Constants;

  print $CLIENT_ARCH_X86_UEFI;    # 6
  print $DUID_LLT;                # 1
  print $LINK_TYPE_ETHERNET;      # 1
  print $SOLICIT;                 # 1
  print $OPTION_CLIENTID;         # 1
  print $CLIENT_FQDN_S;           # 1
  print $STATUS_SUCCESS;          # 0

  print arch_name(6);             # X86_UEFI
  print is_valid_message_type(1); # 1
  print link_type_name(1);        # ETHERNET
  print message_type_name(1);     # SOLICIT
  print option_name(23);          # DNS_SERVERS
  print status_name(0);           # SUCCESS

=head1 DESCRIPTION

Defines all DHCPv6 numeric constants as read-only package variables:
message types, option codes, status codes, DUID types, client
architecture types per RFC 8415 and RFC 5970, and link-layer types
from the IANA ARP Hardware Type registry.
All constants are exported by default via L<Const::Fast::Exporter>.

=head1 ALPHA STATUS

B<ALPHA SOFTWARE.> This is an early release.  The interface is
experimental and subject to change without notice.

=head1 CONSTANTS

=head2 Message Types (RFC 8415 E<167>14)

=over

=item C<$SOLICIT> (1)

=item C<$ADVERTISE> (2)

=item C<$REQUEST> (3)

=item C<$CONFIRM> (4)

=item C<$RENEW> (5)

=item C<$REBIND> (6)

=item C<$REPLY> (7)

=item C<$RELEASE> (8)

=item C<$DECLINE> (9)

=item C<$RECONFIGURE> (10)

=item C<$INFORMATION_REQUEST> (11)

=item C<$RELAY_FORW> (12)

=item C<$RELAY_REPLY> (13)

=back

=head2 Option Codes (RFC 8415 E<167>21)

=over

=item C<$OPTION_CLIENTID> (1)

=item C<$OPTION_SERVERID> (2)

=item C<$OPTION_IA_NA> (3)

=item C<$OPTION_IA_TA> (4)

=item C<$OPTION_IAADDR> (5)

=item C<$OPTION_ORO> (6)

=item C<$OPTION_PREFERENCE> (7)

=item C<$OPTION_ELAPSED_TIME> (8)

=item C<$OPTION_RELAY_MSG> (9)

=item C<$OPTION_AUTH> (11)

=item C<$OPTION_UNICAST> (12)

=item C<$OPTION_STATUS_CODE> (13)

=item C<$OPTION_RAPID_COMMIT> (14)

=item C<$OPTION_USER_CLASS> (15)

=item C<$OPTION_VENDOR_CLASS> (16)

=item C<$OPTION_VENDOR_OPTS> (17)

=item C<$OPTION_INTERFACE_ID> (18)

=item C<$OPTION_RECONF_MSG> (19)

=item C<$OPTION_RECONF_ACCEPT> (20)

=item C<$OPTION_SIP_SERVER_D> (21)

=item C<$OPTION_SIP_SERVER_A> (22)

=item C<$OPTION_DNS_SERVERS> (23)

=item C<$OPTION_DOMAIN_LIST> (24)

=item C<$OPTION_IA_PD> (25)

=item C<$OPTION_IAPREFIX> (26)

=item C<$OPTION_NIS_SERVERS> (27)

=item C<$OPTION_NISP_SERVERS> (28)

=item C<$OPTION_NIS_DOMAIN_NAME> (29)

=item C<$OPTION_NISP_DOMAIN_NAME> (30)

=item C<$OPTION_SNTP_SERVERS> (31)

=item C<$OPTION_INFORMATION_REFRESH_TIME> (32)

=item C<$OPTION_REMOTE_ID> (37)

=item C<$OPTION_SUBSCRIBER_ID> (38)

=item C<$OPTION_CLIENT_FQDN> (39)

=item C<$OPTION_NEW_POSIX_TIMEZONE> (41)

=item C<$OPTION_NEW_TZDB_TIMEZONE> (42)

=item C<$OPTION_NTP_SERVER> (56)

=item C<$OPTION_BOOTFILE_URL> (59)

=item C<$OPTION_BOOTFILE_PARAM> (60)

=item C<$OPTION_CLIENT_ARCH_TYPE> (61)

=item C<$OPTION_AFTR_NAME> (64)

=item C<$OPTION_RSOO> (66)

=item C<$OPTION_PD_EXCLUDE> (67)

=item C<$OPTION_CLIENT_LINKLAYER_ADDR> (79)

=item C<$OPTION_SOL_MAX_RT> (82)

=item C<$OPTION_INF_MAX_RT> (83)

=item C<$OPTION_CAPTIVE_PORTAL> (103)

=item C<$OPTION_MUD_URL> (112)

=back

B<NOTE>: The constants above cover the most commonly used DHCPv6
option codes from RFC 8415 E<167>21 and related RFCs.  Approximately 85
additional option codes are registered with IANA (leasequery, MIP6,
S46, ANI, KRB, bulk leasequery, and others).  If you need a constant
or subclass for one of those codes, either add it to your own code
following the pattern in this module's source or file a feature
request.

=head2 Status Codes (RFC 8415 E<167>18.3)

=over

=item C<$STATUS_SUCCESS> (0)

=item C<$STATUS_UNSPEC_FAIL> (1)

=item C<$STATUS_NO_ADDRS_AVAIL> (2)

=item C<$STATUS_NO_BINDING> (3)

=item C<$STATUS_NOT_ON_LINK> (4)

=item C<$STATUS_USE_MULTICAST> (5)

=item C<$STATUS_NO_PREFIX_AVAIL> (6)

=back

=head2 DUID Types (RFC 8415 E<167>11)

=over

=item C<$DUID_LLT> (1)

=item C<$DUID_EN> (2)

=item C<$DUID_LL> (3)

=item C<$DUID_UUID> (4)

=back

=head2 Client Architecture Types (RFC 5970)

=over

=item C<$CLIENT_ARCH_X86_BIOS> (0)

=item C<$CLIENT_ARCH_NEC_PC98> (1) -- DEPRECATED

=item C<$CLIENT_ARCH_ITANIUM> (2)

=item C<$CLIENT_ARCH_DEC_ALPHA> (3) -- DEPRECATED

=item C<$CLIENT_ARCH_ARC_X86> (4) -- DEPRECATED

=item C<$CLIENT_ARCH_INTEL_LEAN_CLIENT> (5) -- DEPRECATED

=item C<$CLIENT_ARCH_X86_UEFI> (6)

=item C<$CLIENT_ARCH_X64_UEFI> (7)

=item C<$CLIENT_ARCH_EFI_XSCALE> (8) -- DEPRECATED

=item C<$CLIENT_ARCH_EBC> (9)

=item C<$CLIENT_ARCH_ARM_32_UEFI> (10)

=item C<$CLIENT_ARCH_ARM_64_UEFI> (11)

=item C<$CLIENT_ARCH_PPC_OPEN_FIRMWARE> (12)

=item C<$CLIENT_ARCH_PPC_EPAPR> (13)

=item C<$CLIENT_ARCH_POWER_OPAL_V3> (14)

=item C<$CLIENT_ARCH_X86_UEFI_HTTP> (15)

=item C<$CLIENT_ARCH_X64_UEFI_HTTP> (16)

=item C<$CLIENT_ARCH_EBC_HTTP> (17)

=item C<$CLIENT_ARCH_ARM_32_UEFI_HTTP> (18)

=item C<$CLIENT_ARCH_ARM_64_UEFI_HTTP> (19)

=item C<$CLIENT_ARCH_PC_AT_BIOS_HTTP> (20)

=item C<$CLIENT_ARCH_ARM_32_UBOOT> (21)

=item C<$CLIENT_ARCH_ARM_64_UBOOT> (22)

=item C<$CLIENT_ARCH_ARM_UBOOT_32_HTTP> (23)

=item C<$CLIENT_ARCH_ARM_UBOOT_64_HTTP> (24)

=item C<$CLIENT_ARCH_RISCV_32_UEFI> (25)

=item C<$CLIENT_ARCH_RISCV_32_UEFI_HTTP> (26)

=item C<$CLIENT_ARCH_RISCV_64_UEFI> (27)

=item C<$CLIENT_ARCH_RISCV_64_UEFI_HTTP> (28)

=item C<$CLIENT_ARCH_RISCV_128_UEFI> (29)

=item C<$CLIENT_ARCH_RISCV_128_UEFI_HTTP> (30)

=item C<$CLIENT_ARCH_S390_BASIC> (31)

=item C<$CLIENT_ARCH_S390_EXTENDED> (32)

=item C<$CLIENT_ARCH_MIPS_32_UEFI> (33)

=item C<$CLIENT_ARCH_MIPS_64_UEFI> (34)

=item C<$CLIENT_ARCH_SUNWAY_32_UEFI> (35)

=item C<$CLIENT_ARCH_SUNWAY_64_UEFI> (36)

=item C<$CLIENT_ARCH_LOONGARCH_32_UEFI> (37)

=item C<$CLIENT_ARCH_LOONGARCH_32_UEFI_HTTP> (38)

=item C<$CLIENT_ARCH_LOONGARCH_64_UEFI> (39)

=item C<$CLIENT_ARCH_LOONGARCH_64_UEFI_HTTP> (40)

=item C<$CLIENT_ARCH_ARM_RPIBOOT> (41)

=back

=head2 Link-layer Types (IANA ARP Hardware Type registry)

=over

=item C<$LINK_TYPE_RESERVED> (0)

=item C<$LINK_TYPE_ETHERNET> (1)

=item C<$LINK_TYPE_EXP_ETHERNET> (2)

=item C<$LINK_TYPE_AX25> (3)

=item C<$LINK_TYPE_PRONET> (4)

=item C<$LINK_TYPE_CHAOS> (5)

=item C<$LINK_TYPE_IEEE802> (6)

=item C<$LINK_TYPE_ARCNET> (7)

=item C<$LINK_TYPE_HYPERCHANNEL> (8)

=item C<$LINK_TYPE_LANSTAR> (9)

=item C<$LINK_TYPE_AUTONET> (10)

=item C<$LINK_TYPE_LOCALTALK> (11)

=item C<$LINK_TYPE_LOCALNET> (12)

=item C<$LINK_TYPE_ULTRA> (13)

=item C<$LINK_TYPE_SMDS> (14)

=item C<$LINK_TYPE_FRAME_RELAY> (15)

=item C<$LINK_TYPE_ATM> (16)

=item C<$LINK_TYPE_HDLC> (17)

=item C<$LINK_TYPE_FIBRE_CHANNEL> (18)

=item C<$LINK_TYPE_ATM_RFC2225> (19)

=item C<$LINK_TYPE_SERIAL> (20)

=item C<$LINK_TYPE_ATM_ALT> (21)

=item C<$LINK_TYPE_MIL_STD_188_220> (22)

=item C<$LINK_TYPE_METRICOM> (23)

=item C<$LINK_TYPE_IEEE1394> (24)

=item C<$LINK_TYPE_MAPOS> (25)

=item C<$LINK_TYPE_TWINAXIAL> (26)

=item C<$LINK_TYPE_EUI64> (27)

=item C<$LINK_TYPE_HIPARP> (28)

=item C<$LINK_TYPE_ISO7816> (29)

=item C<$LINK_TYPE_ARP_SEC> (30)

=item C<$LINK_TYPE_IPSEC_TUNNEL> (31)

=item C<$LINK_TYPE_INFINIBAND> (32)

=item C<$LINK_TYPE_TIA_102> (33)

=item C<$LINK_TYPE_WIEGAND> (34)

=item C<$LINK_TYPE_PURE_IP> (35)

=item C<$LINK_TYPE_HW_EXP1> (36)

=item C<$LINK_TYPE_HFI> (37)

=item C<$LINK_TYPE_UNIFIED_BUS> (38)

=item C<$LINK_TYPE_HW_EXP2> (256)

=item C<$LINK_TYPE_AETHERNET> (257)

=item C<$LINK_TYPE_RESERVED_HIGH> (65_535)

=back

=head2 Client FQDN Flags (RFC 4704 E<167>4)

=over

=item C<$CLIENT_FQDN_S> (0x01) -- Server should NOT update DNS

=item C<$CLIENT_FQDN_O> (0x02) -- Server override

=item C<$CLIENT_FQDN_N> (0x04) -- Server should update DNS

=back

=head1 LOOKUP HELPERS

=over

=item B<message_type_name>($code)

Returns the message type name string (e.g. C<SOLICIT>) for a numeric code,
or C<undef> if unknown.

=item B<option_name>($code)

Returns the option name string (e.g. C<CLIENTID>) for a numeric code,
or C<undef> if unknown.

=item B<status_name>($code)

Returns the status name string (e.g. C<SUCCESS>) for a numeric code,
or C<undef> if unknown.

=item B<is_valid_message_type>($code)

Returns true if the numeric code corresponds to a known message type.

=item B<arch_name>($code)

Returns the client architecture type name string (e.g. C<X86_UEFI>) for a numeric code,
or C<undef> if unknown.

=item B<link_type_name>($code)

Returns the link-layer type name string (e.g. C<ETHERNET>) for a numeric code,
or C<undef> if unknown.

=back

=head1 REVERSE HASHES

The following package hashes are available for direct lookup:

=over

=item C<%REV_MESSAGE_TYPE>

=item C<%REV_OPTION_CODE>

=item C<%REV_STATUS_CODE>

=item C<%REV_DUID_TYPE>

=item C<%REV_LINK_TYPE>

=item C<%REV_CLIENT_ARCH>

=back

=head1 SEE ALSO

L<Net::DHCPv6>, RFC 8415

=head1 AUTHOR

Dean Hamstead <dean@fragfest.com.au>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2026 by Dean Hamstead.

This is free software, licensed under:

  The MIT (X11) License

=cut
