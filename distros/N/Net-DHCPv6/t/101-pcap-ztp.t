#!/usr/bin/env perl
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
use strictures 2;
use Test2::V1 -ipP, qw(is ok subtest like diag done_testing);    ## no critic (Subroutines::ProhibitCallsToUndeclaredSubs)

use lib 't/lib';
use lib 'lib';

use Net::DHCPv6;
use Net::DHCPv6::Constants;
use Net::DHCPv6::OptionList;

# Hex fixtures extracted from t/data/ztp-pcap-dhcpv6.pcap
# Origin: https://github.com/ios-xr/ztp-pcap/blob/master/6225/pcap/dhcpv6.pcap
my @entries = (
    [
        'solicit',
        pack( 'H*',
'019a0006000100120002000000094647453139343731345153000006000e0017001800f300f2003b00f20027000800020000000f000a6578722d636f6e6669670010003300000009002d505845436c69656e743a417263683a30303030393a554e44493a3030333031303a5049443a4e43532d353530380003000c1d00fcea00000e1000001518',
        ),
    ],
    [
        'advertise',
        pack( 'H*',
'029a0006000300281d00fcea00000000000000000005001820010dba0100000000000000000000300000017700000258000100120002000000094647453139343731345153000002000e000100012154eee7000c29703dd80017001020010dba0100000000000000000000010018000d05636973636f056c6f63616c00003b0036687474703a2f2f5b323030313a6462613a3130303a3a315d3a393039302f657868617573746976655f7a74705f7363726970742e7079',
        ),
    ],
    [
        'request',
        pack( 'H*',
'03cd0220000100120002000000094647453139343731345153000002000e000100012154eee7000c29703dd80006000e0017001800f300f2003b00f20027000800020000000f000a6578722d636f6e6669670010003300000009002d505845436c69656e743a417263683a30303030393a554e44493a3030333031303a5049443a4e43532d35353038000300281d00fcea00000e10000015180005001820010dba01000000000000000000003000001c2000001d4c',
        ),
    ],
    [
        'reply',
        pack( 'H*',
'07cd0220000300281d00fcea00000000000000000005001820010dba0100000000000000000000300000017700000258000100120002000000094647453139343731345153000002000e000100012154eee7000c29703dd80017001020010dba0100000000000000000000010018000d05636973636f056c6f63616c00003b0036687474703a2f2f5b323030313a6462613a3130303a3a315d3a393039302f657868617573746976655f7a74705f7363726970742e7079',
        ),
    ],
);

my @expect = (
    { msg_type => 1, transaction_id => 0x9A0006 },    ## no critic (ValuesAndExpressions::RequireNumberSeparators)
    { msg_type => 2, transaction_id => 0x9A0006 },    ## no critic (ValuesAndExpressions::RequireNumberSeparators)
    { msg_type => 3, transaction_id => 0xCD0220 },    ## no critic (ValuesAndExpressions::RequireNumberSeparators)
    { msg_type => 7, transaction_id => 0xCD0220 },    ## no critic (ValuesAndExpressions::RequireNumberSeparators)
);

for my $i ( 0 .. $#entries ) {
    my ( $desc, $bytes ) = @{ $entries[$i] };
    my $exp = $expect[$i];

    my ( $msg, $err ) = Net::DHCPv6->decode_with_error( $bytes );
    if ( $err ) { diag "err: $err"; next }

    subtest $desc => sub {
        is( $msg->msg_type,       $exp->{msg_type},       "Checking msg_type is $exp->{msg_type}" );
        is( $msg->transaction_id, $exp->{transaction_id}, 'Checking transaction_id is ' . $exp->{transaction_id} );
    };
}

subtest 'solicit options' => sub {
    my ( $msg ) = Net::DHCPv6->decode_or_croak( $entries[0][1] );
    my $ol = $msg->options;

    my $cid = $ol->get_option( 1 );
    ok( $cid, 'CLIENTID present' );
    is( $cid->duid->duid_type,                  2,                          'ClientId duid_type=2 (EN)' );
    is( $cid->duid->enterprise_number,          9,                          'ClientId enterprise_number=9' );
    is( unpack( 'H*', $cid->duid->identifier ), '464745313934373134515300', 'ClientId identifier hex' );

    my $oro = $ol->get_option( 6 );
    ok( $oro, 'ORO present' );
    is( $oro->requested_options, [ 23, 24, 243, 242, 59, 242, 39 ], 'ORO requested options' );

    my $et = $ol->get_option( 8 );
    ok( $et, 'ELAPSED_TIME present' );
    is( $et->centiseconds, 0, 'ElapsedTime is 0' );

    my $uc = $ol->get_option( 15 );
    ok( $uc, 'USER_CLASS present (Generic)' );
    is( unpack( 'H*', $uc->data ), '6578722d636f6e666967', 'USER_CLASS data = hex of "exr-config"' );

    my $vc = $ol->get_option( 16 );
    ok( $vc, 'VENDOR_CLASS present' );
    is( $vc->enterprise_number, 9, 'VENDOR_CLASS enterprise=9 (Cisco)' );
    like( $vc->data, qr/PXE/, 'VENDOR_CLASS data contains PXE string' );

    my $ia = $ol->get_option( 3 );
    ok( $ia, 'IA_NA present' );
    is( $ia->iaid, 486_604_010, 'IA_NA iaid' );
    is( $ia->t1,   3600,        'IA_NA t1' );
    is( $ia->t2,   5400,        'IA_NA t2' );
    ok( !@{ $ia->options->options }, 'IA_NA no sub-options in solicit' );
};

subtest 'advertise options' => sub {
    my ( $msg ) = Net::DHCPv6->decode_or_croak( $entries[1][1] );
    my $ol = $msg->options;

    my $ia = $ol->get_option( 3 );
    ok( $ia, 'IA_NA present' );
    is( $ia->iaid, 486_604_010, 'IA_NA iaid' );
    is( $ia->t1,   0,           'IA_NA t1=0' );
    is( $ia->t2,   0,           'IA_NA t2=0' );

    my $addr = $ia->get_option( 5 );
    ok( $addr, 'IAADDR present' );
    is( $addr->address,            '2001:dba:100::30',                               'IAADDR = 2001:dba:100::30' );
    is( $addr->address_raw,        pack( 'H*', '20010dba010000000000000000000030' ), 'IAADDR address_raw' );
    is( $addr->preferred_lifetime, 375,                                              'IAADDR preferred' );
    is( $addr->valid_lifetime,     600,                                              'IAADDR valid' );

    my $cid = $ol->get_option( 1 );
    ok( $cid, 'CLIENTID present' );
    is( $cid->duid->duid_type, 2, 'ClientId duid_type=2' );

    my $sid = $ol->get_option( 2 );
    ok( $sid, 'SERVERID present' );
    is( $sid->duid->duid_type,                  1,                   'ServerId duid_type=1 (LLT)' );
    is( $sid->duid->link_layer_type,            $LINK_TYPE_ETHERNET, 'ServerId hwtype=1' );
    is( unpack( 'H*', $sid->duid->identifier ), '000c29703dd8',      'ServerId MAC' );

    my $dns = $ol->get_option( 23 );
    ok( $dns, 'DNS_SERVERS present' );
    is( $dns->servers->[0],                     '2001:dba:100::1',                  'DNS server address' );
    is( unpack( 'H*', $dns->servers_raw->[0] ), '20010dba010000000000000000000001', 'DNS server address hex' );

    my $dl = $ol->get_option( 24 );
    ok( $dl, 'DOMAIN_LIST present' );
    is( $dl->domains, ['cisco.local'], 'Domain list' );

    my $bf = $ol->get_option( 59 );
    ok( $bf, 'BOOTFILE_URL present (Generic)' );
    like( $bf->data, qr{\Qhttp://[2001:dba:100::1]:9090/\E}, 'BOOTFILE_URL contains URL' );
};

subtest 'request options' => sub {
    my ( $msg ) = Net::DHCPv6->decode_or_croak( $entries[2][1] );
    my $ol = $msg->options;

    my $ia = $ol->get_option( 3 );
    ok( $ia, 'IA_NA present' );
    is( $ia->t1, 3600, 'IA_NA t1' );
    is( $ia->t2, 5400, 'IA_NA t2' );

    my $addr = $ia->get_option( 5 );
    ok( $addr, 'IAADDR present' );
    is( $addr->address,            '2001:dba:100::30',                               'IAADDR address' );
    is( $addr->address_raw,        pack( 'H*', '20010dba010000000000000000000030' ), 'IAADDR address_raw' );
    is( $addr->preferred_lifetime, 7200,                                             'IAADDR preferred' );
    is( $addr->valid_lifetime,     7500,                                             'IAADDR valid' );
};

subtest 'reply options' => sub {
    my ( $msg ) = Net::DHCPv6->decode_or_croak( $entries[3][1] );
    my $ol = $msg->options;

    my $ia = $ol->get_option( 3 );
    ok( $ia, 'IA_NA present' );
    is( $ia->t1, 0, 'IA_NA t1=0' );
    is( $ia->t2, 0, 'IA_NA t2=0' );

    my $addr = $ia->get_option( 5 );
    ok( $addr, 'IAADDR present' );
    is( $addr->preferred_lifetime, 375, 'IAADDR preferred' );
    is( $addr->valid_lifetime,     600, 'IAADDR valid' );
};

## use critic (ValuesAndExpressions::ProhibitMagicNumbers)
done_testing;
