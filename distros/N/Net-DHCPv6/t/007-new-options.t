#!/usr/bin/env perl
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
use strictures 2;
use Test2::Tools::Exception qw( dies );
use Net::DHCPv6::OptionList ();
use Test2::V1 -ipP,         qw(is ok done_testing);    ## no critic (Subroutines::ProhibitCallsToUndeclaredSubs)

use lib 't/lib';
use lib 'lib';

use Net::DHCPv6::Option                      ();
use Net::DHCPv6::Option::AftrName            ();
use Net::DHCPv6::Option::Auth                ();
use Net::DHCPv6::Option::BootfileParam       ();
use Net::DHCPv6::Option::BootfileUrl         ();
use Net::DHCPv6::Option::CaptivePortal       ();
use Net::DHCPv6::Option::ClientArchType      ();
use Net::DHCPv6::Option::ClientFqdn          ();
use Net::DHCPv6::Option::ClientId            ();
use Net::DHCPv6::Option::ClientLinkLayerAddr ();
use Net::DHCPv6::Option::DnsServers          ();
use Net::DHCPv6::Option::DomainList          ();
use Net::DHCPv6::Option::InfMaxRt            ();
use Net::DHCPv6::Option::InfoRefreshTime     ();
use Net::DHCPv6::Option::InterfaceId         ();
use Net::DHCPv6::Option::NewPosixTimezone    ();
use Net::DHCPv6::Option::NewTzdbTimezone     ();
use Net::DHCPv6::Option::NisDomainName       ();
use Net::DHCPv6::Option::NisServers          ();
use Net::DHCPv6::Option::NispDomainName      ();
use Net::DHCPv6::Option::NispServers         ();
use Net::DHCPv6::Option::SntpServers         ();
use Net::DHCPv6::Option::NtpServer           ();
use Net::DHCPv6::Option::PdExclude           ();
use Net::DHCPv6::Option::ReconfAccept        ();
use Net::DHCPv6::Option::ReconfMsg           ();
use Net::DHCPv6::Option::RelayMsg            ();
use Net::DHCPv6::Option::RemoteId            ();
use Net::DHCPv6::Option::RSOO                ();
use Net::DHCPv6::Option::SipServerA          ();
use Net::DHCPv6::Option::SipServerD          ();
use Net::DHCPv6::Option::MudUrl              ();
use Net::DHCPv6::Option::SolMaxRt            ();
use Net::DHCPv6::Option::SubscriberId        ();
use Net::DHCPv6::Option::Unicast             ();
use Net::DHCPv6::Option::UserClass           ();
use Net::DHCPv6::Option::VendorClass         ();
use Net::DHCPv6::Option::VendorOpts          ();
use Net::DHCPv6::Constants                   qw(
    $CLIENT_ARCH_X86_UEFI $CLIENT_FQDN_S $LINK_TYPE_ETHERNET
    $OPTION_AFTR_NAME $OPTION_AUTH $OPTION_BOOTFILE_PARAM $OPTION_BOOTFILE_URL
    $OPTION_CAPTIVE_PORTAL $OPTION_CLIENT_ARCH_TYPE $OPTION_CLIENT_FQDN
    $OPTION_CLIENT_LINKLAYER_ADDR $OPTION_DNS_SERVERS $OPTION_DOMAIN_LIST
    $OPTION_INF_MAX_RT $OPTION_INFORMATION_REFRESH_TIME $OPTION_INTERFACE_ID
    $OPTION_MUD_URL $OPTION_NEW_POSIX_TIMEZONE $OPTION_NEW_TZDB_TIMEZONE
    $OPTION_NIS_DOMAIN_NAME $OPTION_NISP_DOMAIN_NAME $OPTION_NISP_SERVERS
    $OPTION_NIS_SERVERS $OPTION_PD_EXCLUDE $OPTION_RECONF_ACCEPT
    $OPTION_RECONF_MSG $OPTION_RELAY_MSG $OPTION_REMOTE_ID $OPTION_RSOO
    $OPTION_SIP_SERVER_A $OPTION_SIP_SERVER_D $OPTION_SNTP_SERVERS
    $OPTION_SOL_MAX_RT $OPTION_SUBSCRIBER_ID $OPTION_UNICAST
    $OPTION_USER_CLASS $OPTION_VENDOR_CLASS $OPTION_VENDOR_OPTS
);
use Test::Net::DHCPv6 qw(bytes2hex);
my $EMPTY = q();

# ----------------------------------------------------------------
# ReconfAccept (20) -- zero-length
# ----------------------------------------------------------------
{
    my $ra = Net::DHCPv6::Option::ReconfAccept->new;
    is( $ra->code, $OPTION_RECONF_ACCEPT, 'ReconfAccept code' );
    is( $ra->data, $EMPTY,                'ReconfAccept empty data' );

    my $bytes = $ra->as_bytes;
    is( bytes2hex( $bytes ), '00140000', 'ReconfAccept wire' );

    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::ReconfAccept' ), 'ReconfAccept parsed class' );
}

# ----------------------------------------------------------------
# ReconfMsg (19) -- 1-byte msg_type
# ----------------------------------------------------------------
{
    my $rm = Net::DHCPv6::Option::ReconfMsg->new( msg_type => 5 );
    is( $rm->code,     $OPTION_RECONF_MSG, 'ReconfMsg code' );
    is( $rm->msg_type, 5,                  'ReconfMsg msg_type' );

    my $bytes = $rm->as_bytes;
    is( bytes2hex( $bytes ), '0013000105', 'ReconfMsg wire' );

    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::ReconfMsg' ), 'ReconfMsg parsed class' );
    is( $parsed->msg_type, 5, 'ReconfMsg parsed msg_type' );

    ok( dies { Net::DHCPv6::Option::ReconfMsg->new }, 'ReconfMsg dies without msg_type' );
    ok( dies { Net::DHCPv6::Option::ReconfMsg::from_bytes_inner( undef, $OPTION_RECONF_MSG, $EMPTY ) },
        'ReconfMsg dies on truncated data' );
}

# ----------------------------------------------------------------
# Unicast (12) -- 16-byte IPv6 address
# ----------------------------------------------------------------
{
    my $raw = pack( 'H*', '20010db8000000000000000000000001' );
    my $uc  = Net::DHCPv6::Option::Unicast->new( address => '2001:db8::1' );
    is( $uc->code,        $OPTION_UNICAST, 'Unicast code' );
    is( $uc->address,     '2001:db8::1',   'Unicast address text' );
    is( $uc->address_raw, $raw,            'Unicast address_raw bytes' );

    my $bytes = $uc->as_bytes;
    is( bytes2hex( $bytes ), '000c001020010db8000000000000000000000001', 'Unicast wire' );

    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::Unicast' ), 'Unicast parsed class' );
    is( $parsed->address,     '2001:db8::1', 'Unicast parsed address text' );
    is( $parsed->address_raw, $raw,          'Unicast parsed address_raw' );

    ok( dies { Net::DHCPv6::Option::Unicast->new }, 'Unicast dies without address' );
    ok( dies { Net::DHCPv6::Option::Unicast->new( address => pack( 'C*', ( 1 ) x 4 ) ) },
        'Unicast dies with short address' );
}

# ----------------------------------------------------------------
# InterfaceId (18) -- opaque bytes
# ----------------------------------------------------------------
{
    my $iid = Net::DHCPv6::Option::InterfaceId->new( interface_id => 'eth0' );
    is( $iid->code,         $OPTION_INTERFACE_ID, 'InterfaceId code' );
    is( $iid->interface_id, 'eth0',               'InterfaceId data' );

    my $bytes = $iid->as_bytes;
    is( bytes2hex( $bytes ), '0012000465746830', 'InterfaceId wire' );

    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::InterfaceId' ), 'InterfaceId parsed class' );
    is( $parsed->interface_id, 'eth0', 'InterfaceId parsed data' );

    my $empty = Net::DHCPv6::Option::InterfaceId->new;
    is( $empty->interface_id, $EMPTY, 'InterfaceId defaults to empty' );
}

# ----------------------------------------------------------------
# RelayMsg (9) -- opaque relayed message bytes
# ----------------------------------------------------------------
{
    my $msg = pack( 'H*', '0101e2400001000e000100010001e240001122334455' );
    my $rm  = Net::DHCPv6::Option::RelayMsg->new( message => $msg );
    is( $rm->code,    $OPTION_RELAY_MSG, 'RelayMsg code' );
    is( $rm->message, $msg,              'RelayMsg message' );

    my $bytes = $rm->as_bytes;
    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::RelayMsg' ), 'RelayMsg parsed class' );
    is( $parsed->message, $msg, 'RelayMsg parsed message' );
}

# ----------------------------------------------------------------
# RSOO (66) -- opaque relay-supplied option data
# ----------------------------------------------------------------
{
    my $rsoo = Net::DHCPv6::Option::RSOO->new( option_data => pack( 'H*', '00010203' ) );
    is( $rsoo->code,        $OPTION_RSOO,             'RSOO code' );
    is( $rsoo->option_data, pack( 'H*', '00010203' ), 'RSOO data' );

    my $bytes = $rsoo->as_bytes;
    is( bytes2hex( $bytes ), '0042000400010203', 'RSOO wire' );

    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::RSOO' ), 'RSOO parsed class' );
    is( $parsed->option_data, pack( 'H*', '00010203' ), 'RSOO parsed data' );
}

# ----------------------------------------------------------------
# VendorClass (16) -- enterprise-number + opaque items
# ----------------------------------------------------------------
{
    my $vc = Net::DHCPv6::Option::VendorClass->new(
        enterprise_number => 12_345,
        vendor_data       => [ 'foo', 'bar' ],
    );
    is( $vc->code,              $OPTION_VENDOR_CLASS, 'VendorClass code' );
    is( $vc->enterprise_number, 12_345,               'VendorClass enterprise_number' );
    is( $vc->vendor_data,       [ 'foo', 'bar' ],     'VendorClass vendor_data' );

    my $bytes = $vc->as_bytes;
    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::VendorClass' ), 'VendorClass parsed class' );
    is( $parsed->enterprise_number, 12_345,           'VendorClass parsed enterprise_number' );
    is( $parsed->vendor_data,       [ 'foo', 'bar' ], 'VendorClass parsed vendor_data' );

    ok( dies { Net::DHCPv6::Option::VendorClass->new( vendor_data => ['x'] ) },
        'VendorClass dies without enterprise_number' );

    my $empty = Net::DHCPv6::Option::VendorClass->new(
        enterprise_number => 0,
        vendor_data       => [],
    );
    is( $empty->enterprise_number, 0,  'VendorClass zero enterprise_number' );
    is( $empty->vendor_data,       [], 'VendorClass empty data list' );
}

# ----------------------------------------------------------------
# VendorOpts (17) -- enterprise-number + opaque sub-option data
# ----------------------------------------------------------------
{
    my $vo = Net::DHCPv6::Option::VendorOpts->new(
        enterprise_number => 999,
        sub_options       => pack( 'H*', '0102' ),
    );
    is( $vo->code,              $OPTION_VENDOR_OPTS, 'VendorOpts code' );
    is( $vo->enterprise_number, 999,                 'VendorOpts enterprise_number' );

    my $bytes = $vo->as_bytes;
    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::VendorOpts' ), 'VendorOpts parsed class' );
    is( $parsed->enterprise_number, 999, 'VendorOpts parsed enterprise_number' );

    ok( dies { Net::DHCPv6::Option::VendorOpts->new }, 'VendorOpts dies without enterprise_number' );
}

# ----------------------------------------------------------------
# DnsServers (23) -- list of IPv6 addresses
# ----------------------------------------------------------------
{
    my $addr1 = pack( 'H*', '20010db8000000000000000000000001' );
    my $addr2 = pack( 'H*', '20010db8000000000000000000000002' );
    my $ds    = Net::DHCPv6::Option::DnsServers->new( servers => [ '2001:db8::1', '2001:db8::2' ], );
    is( $ds->code,        $OPTION_DNS_SERVERS, 'DnsServers code' );
    is( $ds->servers,     [ '2001:db8::1', '2001:db8::2' ], 'DnsServers list' );
    is( $ds->servers_raw, [ $addr1, $addr2 ], 'DnsServers raw list' );

    my $bytes = $ds->as_bytes;
    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::DnsServers' ), 'DnsServers parsed class' );
    is( $parsed->servers->[0],     '2001:db8::1', 'DnsServers parsed first addr' );
    is( $parsed->servers->[1],     '2001:db8::2', 'DnsServers parsed second addr' );
    is( $parsed->servers_raw->[0], $addr1,        'DnsServers parsed first raw' );
    is( $parsed->servers_raw->[1], $addr2,        'DnsServers parsed second raw' );

    ok(
        dies {
            Net::DHCPv6::Option::DnsServers::from_bytes_inner( undef, $OPTION_DNS_SERVERS, pack( 'H*', '0102' ) )
        },
        'DnsServers dies on truncated data (non-16-byte-aligned)'
    );
}

# ----------------------------------------------------------------
# NisServers (27) -- list of IPv6 addresses
# ----------------------------------------------------------------
{
    my $addr = pack( 'H*', '20010db8000000000000000000000001' );
    my $ns   = Net::DHCPv6::Option::NisServers->new( servers => ['2001:db8::1'], );
    is( $ns->code,             $OPTION_NIS_SERVERS, 'NisServers code' );
    is( $ns->servers->[0],     '2001:db8::1',       'NisServers address' );
    is( $ns->servers_raw->[0], $addr,               'NisServers raw address' );

    my $bytes = $ns->as_bytes;
    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::NisServers' ), 'NisServers parsed class' );
    is( $parsed->servers->[0],     '2001:db8::1', 'NisServers parsed address' );
    is( $parsed->servers_raw->[0], $addr,         'NisServers parsed raw' );

    ok(
        dies {
            Net::DHCPv6::Option::NisServers::from_bytes_inner( undef, $OPTION_NIS_SERVERS, pack( 'C*', ( 1 ) x 15 ) )
        },
        'NisServers dies on non-16-byte-aligned data'
    );
}

# ----------------------------------------------------------------
# SntpServers (31) -- list of IPv6 addresses (SNTP_SERVERS per RFC 4075)
# ----------------------------------------------------------------
{
    my $addr = pack( 'H*', '20010db8000000000000000000000001' );
    my $ns   = Net::DHCPv6::Option::SntpServers->new( servers => ['2001:db8::1'], );
    is( $ns->code,             $OPTION_SNTP_SERVERS, 'SntpServers code (SNTP_SERVERS)' );
    is( $ns->servers->[0],     '2001:db8::1',        'SntpServers address' );
    is( $ns->servers_raw->[0], $addr,                'SntpServers raw address' );

    my $bytes = $ns->as_bytes;
    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::SntpServers' ), 'SntpServers parsed class' );
    is( $parsed->servers->[0],     '2001:db8::1', 'SntpServers parsed address' );
    is( $parsed->servers_raw->[0], $addr,         'SntpServers parsed raw' );

    ok(
        dies {
            Net::DHCPv6::Option::SntpServers::from_bytes_inner( undef, $OPTION_SNTP_SERVERS, pack( 'C*', ( 1 ) x 15 ) )
        },
        'SntpServers dies on non-16-byte-aligned data'
    );
}

# ----------------------------------------------------------------
# DomainList (24) -- RFC 1035 domain names
# ----------------------------------------------------------------
{
    my $dl = Net::DHCPv6::Option::DomainList->new( domains => [ 'example.com', 'test.net' ] );
    is( $dl->code,    $OPTION_DOMAIN_LIST,           'DomainList code' );
    is( $dl->domains, [ 'example.com', 'test.net' ], 'DomainList names' );

    my $bytes = $dl->as_bytes;
    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::DomainList' ), 'DomainList parsed class' );
    is( $parsed->domains, [ 'example.com', 'test.net' ], 'DomainList parsed names' );
}

# ----------------------------------------------------------------
# DomainList (24) -- compression pointer edge cases
# ----------------------------------------------------------------
{
    my $compressed = pack( 'H*', '076578616d706c6503636f6d000474657374c000' );
    ok(
        dies {
            Net::DHCPv6::Option::DomainList::from_bytes_inner( 'Net::DHCPv6::Option::DomainList',
                $OPTION_DOMAIN_LIST, $compressed )
        },
        'DomainList croaks on compression pointer in strict mode'
    );

    my $badlen = pack( 'H*', '7f00' );
    ok(
        dies {
            Net::DHCPv6::Option::DomainList::from_bytes_inner( 'Net::DHCPv6::Option::DomainList',
                $OPTION_DOMAIN_LIST, $badlen )
        },
        'DomainList croaks on invalid label length 127'
    );

    {
        local $Net::DHCPv6::Option::FOLLOW_COMPRESSION = 1;
        my $ptr = pack( 'H*', '076578616d706c6503636f6d000474657374c000' );
        my $dl  = Net::DHCPv6::Option::DomainList::from_bytes_inner( 'Net::DHCPv6::Option::DomainList',
            $OPTION_DOMAIN_LIST, $ptr );
        is(
            $dl->domains,
            [ 'example.com', 'test.example.com' ],
            'DomainList follows pointer when FOLLOW_COMPRESSION is set'
        );
    }

    # truncated compression pointer (only 1 byte of a 2-byte pointer)
    my $trunc_ptr = pack( 'H*', '03' );
    ok(
        dies {
            Net::DHCPv6::Option::DomainList::from_bytes_inner( 'Net::DHCPv6::Option::DomainList',
                $OPTION_DOMAIN_LIST, $trunc_ptr )
        },
        'DomainList croaks on truncated pointer (no room for 2nd byte)'
    );

    # truncated label (label length says 10 but only 3 bytes remain)
    my $trunc_label = pack( 'H*', '0a666f6f' );
    ok(
        dies {
            Net::DHCPv6::Option::DomainList::from_bytes_inner( 'Net::DHCPv6::Option::DomainList',
                $OPTION_DOMAIN_LIST, $trunc_label )
        },
        'DomainList croaks on truncated domain label'
    );

    # out-of-range pointer
    {
        local $Net::DHCPv6::Option::FOLLOW_COMPRESSION = 1;
        my $oor = pack( 'H*', '03666f6fc0ff' );
        ok(
            dies {
                Net::DHCPv6::Option::DomainList::from_bytes_inner( 'Net::DHCPv6::Option::DomainList',
                    $OPTION_DOMAIN_LIST, $oor )
            },
            'DomainList croaks on out-of-range compression pointer'
        );
    }
}

# ----------------------------------------------------------------
# NisDomainName (29) -- single RFC 1035 domain name
# ----------------------------------------------------------------
{
    my $nd = Net::DHCPv6::Option::NisDomainName->new( domain_name => 'nis.example.com' );
    is( $nd->code,        $OPTION_NIS_DOMAIN_NAME, 'NisDomainName code' );
    is( $nd->domain_name, 'nis.example.com',       'NisDomainName domain name' );

    my $bytes = $nd->as_bytes;
    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::NisDomainName' ), 'NisDomainName parsed class' );
    is( $parsed->domain_name, 'nis.example.com', 'NisDomainName parsed name' );

    ok( dies { Net::DHCPv6::Option::NisDomainName->new }, 'NisDomainName dies without domain_name' );
}

# ----------------------------------------------------------------
# ClientFqdn (39) -- flags + RFC 1035 domain name
# ----------------------------------------------------------------
{
    my $cf = Net::DHCPv6::Option::ClientFqdn->new(
        flags       => $CLIENT_FQDN_S,
        domain_name => 'client.example.com',
    );
    is( $cf->code,        $OPTION_CLIENT_FQDN,  'ClientFqdn code' );
    is( $cf->flags,       $CLIENT_FQDN_S,       'ClientFqdn flags' );
    is( $cf->domain_name, 'client.example.com', 'ClientFqdn domain name' );

    my $bytes = $cf->as_bytes;
    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::ClientFqdn' ), 'ClientFqdn parsed class' );
    is( $parsed->flags,       $CLIENT_FQDN_S,       'ClientFqdn parsed flags' );
    is( $parsed->domain_name, 'client.example.com', 'ClientFqdn parsed name' );

    ok( dies { Net::DHCPv6::Option::ClientFqdn->new( domain_name => 'x' ) }, 'ClientFqdn dies without flags' );
}

# ----------------------------------------------------------------
# AftrName (64) -- RFC 6334 domain name
# ----------------------------------------------------------------
{
    my $an = Net::DHCPv6::Option::AftrName->new( domain_name => 'aftr.example.com' );
    is( $an->code,        $OPTION_AFTR_NAME,  'AftrName code' );
    is( $an->domain_name, 'aftr.example.com', 'AftrName domain name' );

    my $bytes = $an->as_bytes;
    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::AftrName' ), 'AftrName parsed class' );
    is( $parsed->domain_name, 'aftr.example.com', 'AftrName parsed name' );

    ok( dies { Net::DHCPv6::Option::AftrName->new }, 'AftrName dies without domain_name' );
}

# ----------------------------------------------------------------
# AftrName (64) -- compression pointer rejects
# ----------------------------------------------------------------
{
    # pointer embedded within single domain name: test + \xC0\x09 => "example.com"
    # "test" + pointer-to-offset-9 reads "example.com" = "test.example.com"
    my $ptr = pack( 'H*', '0474657374c009076578616d706c6503636f6d00' );
    ok(
        dies {
            Net::DHCPv6::Option::AftrName::from_bytes_inner( 'Net::DHCPv6::Option::AftrName', $OPTION_AFTR_NAME, $ptr );
            ## use critic
        },
        'AftrName croaks on compression pointer in strict mode'
    );
}

# ----------------------------------------------------------------
# Auth (11) -- protocol/algorithm/rdm/replay/auth-info
# ----------------------------------------------------------------
{
    my $replay    = pack( 'H*', '0102030405060708' );
    my $auth_info = pack( 'H*', 'deadbeef' );
    my $auth      = Net::DHCPv6::Option::Auth->new(
        protocol  => 3,
        algorithm => 1,
        rdm       => 0,
        replay    => $replay,
        auth_info => $auth_info,
    );
    is( $auth->code,      $OPTION_AUTH, 'Auth code' );
    is( $auth->protocol,  3,            'Auth protocol' );
    is( $auth->algorithm, 1,            'Auth algorithm' );
    is( $auth->rdm,       0,            'Auth rdm' );
    is( $auth->replay,    $replay,      'Auth replay' );
    is( $auth->auth_info, $auth_info,   'Auth auth_info' );

    my $bytes = $auth->as_bytes;
    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::Auth' ), 'Auth parsed class' );
    is( $parsed->protocol,  3,          'Auth parsed protocol' );
    is( $parsed->algorithm, 1,          'Auth parsed algorithm' );
    is( $parsed->rdm,       0,          'Auth parsed rdm' );
    is( $parsed->replay,    $replay,    'Auth parsed replay' );
    is( $parsed->auth_info, $auth_info, 'Auth parsed auth_info' );

    ok( dies { Net::DHCPv6::Option::Auth->new( protocol => 1 ) }, 'Auth dies without algorithm' );
    ok(
        dies {
            Net::DHCPv6::Option::Auth->new(
                protocol  => 1,
                algorithm => 1,
                rdm       => 0,
            )
        },
        'Auth dies without replay'
    );
    ok(
        dies {
            Net::DHCPv6::Option::Auth::from_bytes_inner( undef, $OPTION_AUTH, pack( 'H*', '000000' ) )
        },
        'Auth dies on truncated data (< 11 bytes)'
    );
}

# ----------------------------------------------------------------
# SipServerD (21) -- list of RFC 1035 domain names
# ----------------------------------------------------------------
{
    my $sd = Net::DHCPv6::Option::SipServerD->new( domains => [ 'sip1.example.com', 'sip2.example.org' ], );
    is( $sd->code,    $OPTION_SIP_SERVER_D,                       'SipServerD code' );
    is( $sd->domains, [ 'sip1.example.com', 'sip2.example.org' ], 'SipServerD domains' );

    my $bytes = $sd->as_bytes;
    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::SipServerD' ), 'SipServerD parsed class' );
    is( $parsed->domains, [ 'sip1.example.com', 'sip2.example.org' ], 'SipServerD parsed domains' );

    my $empty = Net::DHCPv6::Option::SipServerD->new;
    is( $empty->domains, [], 'SipServerD defaults to empty list' );
}

# ----------------------------------------------------------------
# SipServerD (21) -- compression pointer edge case
# ----------------------------------------------------------------
{
    {
        local $Net::DHCPv6::Option::FOLLOW_COMPRESSION = 1;
        my $ptr = pack( 'H*', '0473697031076578616d706c6503636f6d000474657374c005' );
        my $sd  = Net::DHCPv6::Option::SipServerD::from_bytes_inner( 'Net::DHCPv6::Option::SipServerD',
            $OPTION_SIP_SERVER_D, $ptr );
        is(
            $sd->domains,
            [ 'sip1.example.com', 'test.example.com' ],
            'SipServerD follows pointer when FOLLOW_COMPRESSION is set'
        );
    }

    # strict mode rejects compression pointer
    my $ptr = pack( 'H*', '0473697031076578616d706c6503636f6d000474657374c005' );
    ok(
        dies {
            Net::DHCPv6::Option::SipServerD::from_bytes_inner( 'Net::DHCPv6::Option::SipServerD',
                $OPTION_SIP_SERVER_D, $ptr )
        },
        'SipServerD croaks on compression pointer in strict mode'
    );
}

# ----------------------------------------------------------------
# MudUrl (112) -- URL string
# ----------------------------------------------------------------
{
    my $url = 'https://mud.example.com/device.json';
    my $mu  = Net::DHCPv6::Option::MudUrl->new( url => $url );
    is( $mu->code, $OPTION_MUD_URL, 'MudUrl code' );
    is( $mu->url,  $url,            'MudUrl url' );

    my $bytes = $mu->as_bytes;
    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::MudUrl' ), 'MudUrl parsed class' );
    is( $parsed->url, $url, 'MudUrl parsed url' );

    ok( dies { Net::DHCPv6::Option::MudUrl->new }, 'MudUrl dies without url' );
    ok(
        dies {
            Net::DHCPv6::Option::MudUrl::from_bytes_inner( undef, $OPTION_MUD_URL, $EMPTY )
        },
        'MudUrl dies on empty data'
    );
}

# ----------------------------------------------------------------
# UserClass (15) -- list of opaque data items
# ----------------------------------------------------------------
{
    my $uc = Net::DHCPv6::Option::UserClass->new( user_class_data => [ 'foo', 'bar' ], );
    is( $uc->code,            $OPTION_USER_CLASS, 'UserClass code' );
    is( $uc->user_class_data, [ 'foo', 'bar' ],   'UserClass data' );

    my $bytes = $uc->as_bytes;
    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::UserClass' ), 'UserClass parsed class' );
    is( $parsed->user_class_data, [ 'foo', 'bar' ], 'UserClass parsed data' );

    my $empty = Net::DHCPv6::Option::UserClass->new;
    is( $empty->user_class_data, [], 'UserClass defaults to empty list' );
}

# ----------------------------------------------------------------
# SolMaxRt (82) -- 32-bit integer
# ----------------------------------------------------------------
{
    my $sm = Net::DHCPv6::Option::SolMaxRt->new( value => 3600 );
    is( $sm->code,  $OPTION_SOL_MAX_RT, 'SolMaxRt code' );
    is( $sm->value, 3600,               'SolMaxRt value' );

    my $bytes = $sm->as_bytes;
    is( bytes2hex( $bytes ), '0052000400000e10', 'SolMaxRt wire' );

    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::SolMaxRt' ), 'SolMaxRt parsed class' );
    is( $parsed->value, 3600, 'SolMaxRt parsed value' );

    ok( dies { Net::DHCPv6::Option::SolMaxRt->new }, 'SolMaxRt dies without value' );
    ok(
        dies {
            Net::DHCPv6::Option::SolMaxRt::from_bytes_inner( undef, $OPTION_SOL_MAX_RT, pack( 'H*', '010203' ) )
        },
        'SolMaxRt dies on data != 4 bytes'
    );
}

# ----------------------------------------------------------------
# SipServerA (22) -- list of IPv6 addresses
# ----------------------------------------------------------------
{
    my $addr = pack( 'H*', '20010db8000000000000000000000001' );
    my $sa   = Net::DHCPv6::Option::SipServerA->new( servers => ['2001:db8::1'], );
    is( $sa->code,             $OPTION_SIP_SERVER_A, 'SipServerA code' );
    is( $sa->servers->[0],     '2001:db8::1',        'SipServerA address' );
    is( $sa->servers_raw->[0], $addr,                'SipServerA raw address' );

    my $bytes = $sa->as_bytes;
    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::SipServerA' ), 'SipServerA parsed class' );
    is( $parsed->servers->[0],     '2001:db8::1', 'SipServerA parsed address' );
    is( $parsed->servers_raw->[0], $addr,         'SipServerA parsed raw' );

    ok(
        dies {
            Net::DHCPv6::Option::SipServerA::from_bytes_inner( undef, $OPTION_SIP_SERVER_A, pack( 'C*', ( 1 ) x 15 ) )
        },
        'SipServerA dies on non-16-byte-aligned data'
    );
}

# ----------------------------------------------------------------
# InfoRefreshTime (32) -- 32-bit integer
# ----------------------------------------------------------------
{
    my $irt = Net::DHCPv6::Option::InfoRefreshTime->new( value => 86_400 );
    is( $irt->code,  $OPTION_INFORMATION_REFRESH_TIME, 'InfoRefreshTime code' );
    is( $irt->value, 86_400,                           'InfoRefreshTime value' );

    my $bytes = $irt->as_bytes;
    is( bytes2hex( $bytes ), '0020000400015180', 'InfoRefreshTime wire' );

    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::InfoRefreshTime' ), 'InfoRefreshTime parsed class' );
    is( $parsed->value, 86_400, 'InfoRefreshTime parsed value' );

    ok( dies { Net::DHCPv6::Option::InfoRefreshTime->new }, 'InfoRefreshTime dies without value' );
}

# ----------------------------------------------------------------
# InfMaxRt (83) -- 32-bit integer
# ----------------------------------------------------------------
{
    my $imr = Net::DHCPv6::Option::InfMaxRt->new( value => 3600 );
    is( $imr->code,  $OPTION_INF_MAX_RT, 'InfMaxRt code' );
    is( $imr->value, 3600,               'InfMaxRt value' );

    my $bytes = $imr->as_bytes;
    is( bytes2hex( $bytes ), '0053000400000e10', 'InfMaxRt wire' );

    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::InfMaxRt' ), 'InfMaxRt parsed class' );
    is( $parsed->value, 3600, 'InfMaxRt parsed value' );

    ok( dies { Net::DHCPv6::Option::InfMaxRt->new }, 'InfMaxRt dies without value' );
}

# ----------------------------------------------------------------
# RemoteId (37) -- enterprise-number + opaque data
# ----------------------------------------------------------------
{
    my $rid = Net::DHCPv6::Option::RemoteId->new(
        enterprise_number => 9,
        remote_data       => pack( 'H*', '00010203' ),
    );
    is( $rid->code,              $OPTION_REMOTE_ID,        'RemoteId code' );
    is( $rid->enterprise_number, 9,                        'RemoteId enterprise_number' );
    is( $rid->remote_data,       pack( 'H*', '00010203' ), 'RemoteId remote_data' );

    my $bytes = $rid->as_bytes;
    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::RemoteId' ), 'RemoteId parsed class' );
    is( $parsed->enterprise_number, 9,                        'RemoteId parsed enterprise_number' );
    is( $parsed->remote_data,       pack( 'H*', '00010203' ), 'RemoteId parsed remote_data' );

    ok( dies { Net::DHCPv6::Option::RemoteId->new( enterprise_number => 1 ) }, 'RemoteId dies without remote_data' );
    ok( dies { Net::DHCPv6::Option::RemoteId->new( remote_data       => $EMPTY ) },
        'RemoteId dies without enterprise_number' );
}

# ----------------------------------------------------------------
# SubscriberId (38) -- opaque data
# ----------------------------------------------------------------
{
    my $sid = Net::DHCPv6::Option::SubscriberId->new( subscriber_id => pack( 'H*', '000102' ) );
    is( $sid->code,          $OPTION_SUBSCRIBER_ID,  'SubscriberId code' );
    is( $sid->subscriber_id, pack( 'H*', '000102' ), 'SubscriberId data' );

    my $bytes = $sid->as_bytes;
    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::SubscriberId' ), 'SubscriberId parsed class' );
    is( $parsed->subscriber_id, pack( 'H*', '000102' ), 'SubscriberId parsed data' );

    my $empty = Net::DHCPv6::Option::SubscriberId->new;
    is( $empty->subscriber_id, $EMPTY, 'SubscriberId defaults to empty' );
}

# ----------------------------------------------------------------
# BootfileUrl (59) -- URL string
# ----------------------------------------------------------------
{
    my $url = 'tftp://192.0.2.1/bootfile';
    my $bu  = Net::DHCPv6::Option::BootfileUrl->new( url => $url );
    is( $bu->code, $OPTION_BOOTFILE_URL, 'BootfileUrl code' );
    is( $bu->url,  $url,                 'BootfileUrl url' );

    my $bytes = $bu->as_bytes;
    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::BootfileUrl' ), 'BootfileUrl parsed class' );
    is( $parsed->url, $url, 'BootfileUrl parsed url' );

    ok( dies { Net::DHCPv6::Option::BootfileUrl->new }, 'BootfileUrl dies without url' );
    ok(
        dies {
            Net::DHCPv6::Option::BootfileUrl::from_bytes_inner( undef, $OPTION_BOOTFILE_URL, $EMPTY )
        },
        'BootfileUrl dies on empty data'
    );
}

# ----------------------------------------------------------------
# CaptivePortal (103) -- URI string
# ----------------------------------------------------------------
{
    my $uri = 'https://example.com/portal';
    my $cp  = Net::DHCPv6::Option::CaptivePortal->new( uri => $uri );
    is( $cp->code, $OPTION_CAPTIVE_PORTAL, 'CaptivePortal code' );
    is( $cp->uri,  $uri,                   'CaptivePortal uri' );

    my $bytes = $cp->as_bytes;
    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::CaptivePortal' ), 'CaptivePortal parsed class' );
    is( $parsed->uri, $uri, 'CaptivePortal parsed uri' );

    ok( dies { Net::DHCPv6::Option::CaptivePortal->new }, 'CaptivePortal dies without uri' );
    ok(
        dies {
            Net::DHCPv6::Option::CaptivePortal::from_bytes_inner( undef, $OPTION_CAPTIVE_PORTAL, $EMPTY )
        },
        'CaptivePortal dies on empty data'
    );
}

# ----------------------------------------------------------------
# NispServers (28) -- list of IPv6 addresses
# ----------------------------------------------------------------
{
    my $addr = pack( 'H*', '20010db8000000000000000000000001' );
    my $ns   = Net::DHCPv6::Option::NispServers->new( servers => ['2001:db8::1'], );
    is( $ns->code,             $OPTION_NISP_SERVERS, 'NispServers code' );
    is( $ns->servers->[0],     '2001:db8::1',        'NispServers address' );
    is( $ns->servers_raw->[0], $addr,                'NispServers raw address' );

    my $bytes = $ns->as_bytes;
    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::NispServers' ), 'NispServers parsed class' );
    is( $parsed->servers->[0],     '2001:db8::1', 'NispServers parsed address' );
    is( $parsed->servers_raw->[0], $addr,         'NispServers parsed raw' );

    ok(
        dies {
            Net::DHCPv6::Option::NispServers::from_bytes_inner( undef, $OPTION_NISP_SERVERS, pack( 'C*', ( 1 ) x 15 ) )
        },
        'NispServers dies on non-16-byte-aligned data'
    );
}

# ----------------------------------------------------------------
# NispDomainName (30) -- domain name string
# ----------------------------------------------------------------
{
    my $nd = Net::DHCPv6::Option::NispDomainName->new( domain_name => 'nis.example.com' );
    is( $nd->code,        $OPTION_NISP_DOMAIN_NAME, 'NispDomainName code' );
    is( $nd->domain_name, 'nis.example.com',        'NispDomainName domain name' );

    my $bytes = $nd->as_bytes;
    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::NispDomainName' ), 'NispDomainName parsed class' );
    is( $parsed->domain_name, 'nis.example.com', 'NispDomainName parsed name' );

    ok( dies { Net::DHCPv6::Option::NispDomainName->new }, 'NispDomainName dies without domain_name' );
}

# ----------------------------------------------------------------
# NewPosixTimezone (41) -- POSIX timezone string
# ----------------------------------------------------------------
{
    my $npt = Net::DHCPv6::Option::NewPosixTimezone->new( tz_string => 'EST5EDT' );
    is( $npt->code,      $OPTION_NEW_POSIX_TIMEZONE, 'NewPosixTimezone code' );
    is( $npt->tz_string, 'EST5EDT',                  'NewPosixTimezone tz_string' );

    my $bytes = $npt->as_bytes;
    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::NewPosixTimezone' ), 'NewPosixTimezone parsed class' );
    is( $parsed->tz_string, 'EST5EDT', 'NewPosixTimezone parsed tz_string' );

    ok( dies { Net::DHCPv6::Option::NewPosixTimezone->new }, 'NewPosixTimezone dies without tz_string' );
}

# ----------------------------------------------------------------
# NewTzdbTimezone (42) -- IANA timezone name
# ----------------------------------------------------------------
{
    my $ntt = Net::DHCPv6::Option::NewTzdbTimezone->new( tz_name => 'America/New_York' );
    is( $ntt->code,    $OPTION_NEW_TZDB_TIMEZONE, 'NewTzdbTimezone code' );
    is( $ntt->tz_name, 'America/New_York',        'NewTzdbTimezone tz_name' );

    my $bytes = $ntt->as_bytes;
    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::NewTzdbTimezone' ), 'NewTzdbTimezone parsed class' );
    is( $parsed->tz_name, 'America/New_York', 'NewTzdbTimezone parsed tz_name' );

    ok( dies { Net::DHCPv6::Option::NewTzdbTimezone->new }, 'NewTzdbTimezone dies without tz_name' );
}

# ----------------------------------------------------------------
# BootfileParam (60) -- list of opaque items
# ----------------------------------------------------------------
{
    my $bp = Net::DHCPv6::Option::BootfileParam->new( parameters => [ 'foo', 'bar' ], );
    is( $bp->code,       $OPTION_BOOTFILE_PARAM, 'BootfileParam code' );
    is( $bp->parameters, [ 'foo', 'bar' ],       'BootfileParam params' );

    my $bytes = $bp->as_bytes;
    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::BootfileParam' ), 'BootfileParam parsed class' );
    is( $parsed->parameters, [ 'foo', 'bar' ], 'BootfileParam parsed params' );

    my $empty = Net::DHCPv6::Option::BootfileParam->new;
    is( $empty->parameters, [], 'BootfileParam defaults to empty list' );
}

# ----------------------------------------------------------------
# ClientArchType (61) -- 16-bit type
# ----------------------------------------------------------------
{
    my $cat = Net::DHCPv6::Option::ClientArchType->new( type => $CLIENT_ARCH_X86_UEFI );
    is( $cat->code, $OPTION_CLIENT_ARCH_TYPE, 'ClientArchType code' );
    is( $cat->type, $CLIENT_ARCH_X86_UEFI,    'ClientArchType type' );

    my $bytes = $cat->as_bytes;
    is( bytes2hex( $bytes ), '003d00020006', 'ClientArchType wire' );

    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::ClientArchType' ), 'ClientArchType parsed class' );
    is( $parsed->type, $CLIENT_ARCH_X86_UEFI, 'ClientArchType parsed type' );

    ok( dies { Net::DHCPv6::Option::ClientArchType->new }, 'ClientArchType dies without type' );
    ok(
        dies {
            Net::DHCPv6::Option::ClientArchType::from_bytes_inner( undef, $OPTION_CLIENT_ARCH_TYPE, chr( 1 ) )
        },
        'ClientArchType dies on data != 2 bytes'
    );
}

# ----------------------------------------------------------------
# PdExclude (67) -- prefix-length + address
# ----------------------------------------------------------------
{
    my $addr    = pack( 'H*', '20010db8000000000000000000000000' );
    my $pd_addr = substr( $addr, 0, 6 );
    my $pe      = Net::DHCPv6::Option::PdExclude->new(
        prefix_length => 48,
        address       => '2001:db8::',
    );
    is( $pe->code,          $OPTION_PD_EXCLUDE, 'PdExclude code' );
    is( $pe->prefix_length, 48,                 'PdExclude prefix_length' );
    is( $pe->address,       $pd_addr,           'PdExclude address (truncated)' );
    is( $pe->address_raw,   $pd_addr,           'PdExclude address_raw' );

    my $bytes = $pe->as_bytes;
    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::PdExclude' ), 'PdExclude parsed class' );
    is( $parsed->prefix_length, 48, 'PdExclude parsed prefix_length' );

    # address is variable-length per RFC 6603; round-trip truncates to ceil(48/8)=6 bytes
    is( $parsed->address,     $pd_addr, 'PdExclude parsed address' );
    is( $parsed->address_raw, $pd_addr, 'PdExclude parsed address_raw' );

    ok( dies { Net::DHCPv6::Option::PdExclude->new( prefix_length => 48 ) }, 'PdExclude dies without address' );
    ok( dies { Net::DHCPv6::Option::PdExclude->new( address => $addr ) },    'PdExclude dies without prefix_length' );
}

# PdExclude prefix-length=0 edge cases (RFC 6603)
{
    $EMPTY = q();

    # Build with prefix_length=0, address_raw => '' (valid: 0 bytes of prefix)
    {
        my $pe = Net::DHCPv6::Option::PdExclude->new(
            prefix_length => 0,
            address_raw   => $EMPTY,
        );
        is( $pe->code,          $OPTION_PD_EXCLUDE, 'PdExclude plen=0 code' );
        is( $pe->prefix_length, 0,                  'PdExclude plen=0 prefix_length' );
        is( $pe->address,       $EMPTY,             'PdExclude plen=0 address (empty)' );
        is( $pe->address_raw,   $EMPTY,             'PdExclude plen=0 address_raw (empty)' );
    }

    # Build with prefix_length=0, address => '::' (text, truncated to 0 bytes)
    {
        my $pe = Net::DHCPv6::Option::PdExclude->new(
            prefix_length => 0,
            address       => q{::},
        );
        is( $pe->prefix_length, 0,      'PdExclude plen=0 text address prefix_length' );
        is( $pe->address,       $EMPTY, 'PdExclude plen=0 text address (empty after truncation)' );
    }

    # Wire decode of 1-byte payload (prefix-len=0, zero address bytes)
    {
        my ( $parsed ) = Net::DHCPv6::Option->from_bytes( pack( 'nnC', $OPTION_PD_EXCLUDE, 1, 0 ) );
        ok( $parsed->isa( 'Net::DHCPv6::Option::PdExclude' ), 'PdExclude plen=0 parsed class' );
        is( $parsed->prefix_length, 0,      'PdExclude plen=0 parsed prefix_length' );
        is( $parsed->address_raw,   $EMPTY, 'PdExclude plen=0 parsed address (empty)' );
    }

    # Round-trip: build -> as_bytes -> parse -> match
    {
        my $pe = Net::DHCPv6::Option::PdExclude->new(
            prefix_length => 0,
            address_raw   => $EMPTY,
        );
        my $bytes = $pe->as_bytes;
        my ( $got ) = Net::DHCPv6::Option->from_bytes( $bytes );
        is( $got->prefix_length, 0,      'PdExclude plen=0 round-trip prefix_length' );
        is( $got->address_raw,   $EMPTY, 'PdExclude plen=0 round-trip address' );
    }
}

# ----------------------------------------------------------------
# ClientLinkLayerAddr (79) -- link-layer type + address
# ----------------------------------------------------------------
{
    my $clla = Net::DHCPv6::Option::ClientLinkLayerAddr->new(
        link_layer_type => $LINK_TYPE_ETHERNET,
        link_layer_addr => pack( 'H*', '001122334455' ),
    );
    is( $clla->code,            $OPTION_CLIENT_LINKLAYER_ADDR, 'ClientLinkLayerAddr code' );
    is( $clla->link_layer_type, $LINK_TYPE_ETHERNET,           'ClientLinkLayerAddr type' );
    is( $clla->link_layer_addr, pack( 'H*', '001122334455' ),  'ClientLinkLayerAddr addr' );

    my $bytes = $clla->as_bytes;
    my ( $parsed ) = Net::DHCPv6::Option->from_bytes( $bytes );
    ok( $parsed->isa( 'Net::DHCPv6::Option::ClientLinkLayerAddr' ), 'ClientLinkLayerAddr parsed class' );
    is( $parsed->link_layer_type, $LINK_TYPE_ETHERNET,          'ClientLinkLayerAddr parsed type' );
    is( $parsed->link_layer_addr, pack( 'H*', '001122334455' ), 'ClientLinkLayerAddr parsed addr' );

    ok( dies { Net::DHCPv6::Option::ClientLinkLayerAddr->new( link_layer_type => $LINK_TYPE_ETHERNET ) },
        'ClientLinkLayerAddr dies without link_layer_addr' );
    ok(
        dies {
            Net::DHCPv6::Option::ClientLinkLayerAddr::from_bytes_inner( undef, $OPTION_CLIENT_LINKLAYER_ADDR,
                pack( 'H*', '0001' ) )
        },
        'ClientLinkLayerAddr dies on truncated data (< 3 bytes)'
    );
}

# ----------------------------------------------------------------
# Integration: round-trip via OptionList
# ----------------------------------------------------------------
{
    my $ol = Net::DHCPv6::OptionList->new;
    $ol->add_option(
        Net::DHCPv6::Option::Unicast->new(
            address => '2001:db8::1'
        )
    );
    $ol->add_option(
        Net::DHCPv6::Option::DnsServers->new(
            servers => ['2001:db8::1']
        )
    );
    $ol->add_option(
        Net::DHCPv6::Option::Auth->new(
            protocol  => 3,
            algorithm => 1,
            rdm       => 0,
            replay    => chr( 0 ) x 8,
            auth_info => $EMPTY,
        )
    );

    my $bytes = $ol->as_bytes;
    my $ol2   = Net::DHCPv6::OptionList->from_bytes( $bytes );
    is( $ol2->get_option( $OPTION_UNICAST )->code,     $OPTION_UNICAST,     'Integration Unicast' );
    is( $ol2->get_option( $OPTION_DNS_SERVERS )->code, $OPTION_DNS_SERVERS, 'Integration DnsServers' );
    is( $ol2->get_option( $OPTION_AUTH )->code,        $OPTION_AUTH,        'Integration Auth' );
}

## use critic (ValuesAndExpressions::ProhibitMagicNumbers)
done_testing;
