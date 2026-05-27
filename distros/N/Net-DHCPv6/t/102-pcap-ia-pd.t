#!/usr/bin/env perl
use strictures 2;
use Test2::V1 -ipP;
use lib 't/lib';
use lib 'lib';

use Net::DHCPv6;
use Net::DHCPv6::Constants;
use Net::DHCPv6::OptionList;

# Hex fixtures extracted from t/data/dhcpv6-ia-pd.pcap
# Origin: https://github.com/aosp-mirror/platform_external_tcpdump/blob/master/tests/dhcpv6-ia-pd.pcap
my @data = (
    [
        'solicit',
        pack(
            "H*", "01e1e0930001000a0003000100010203040500060004001700180008000200000019000c0203040500000e1000001518"
        )
    ],
    [
        'advertise',
        pack( "H*",
"02e1e093001900290203040500000e1000001518001a00190000119400001c20382a0000010001010000000000000000000001000a000300010001020304050002000e0001000118464999001122334455"
        )
    ],
    [
        'request',
        pack( "H*",
"0312b08a0001000a000300010001020304050002000e00010001184649990011223344550006000400170018000800020000001900290203040500000e1000001518001a001900001c2000001d4c382a000001000101000000000000000000"
        )
    ],
    [
        'reply',
        pack( "H*",
"0712b08a001900290203040500000e1000001518001a00190000119400001c20382a0000010001010000000000000000000001000a000300010001020304050002000e0001000118464999001122334455"
        )
    ],
);

my @expect = (
    { msg_type => 1, transaction_id => 0xE1E093 },
    { msg_type => 2, transaction_id => 0xE1E093 },
    { msg_type => 3, transaction_id => 0x12B08A },
    { msg_type => 7, transaction_id => 0x12B08A },
);

for my $i ( 0 .. $#data ) {
    my ( $desc, $bytes ) = @{ $data[$i] };
    my $exp = $expect[$i];

    my ( $msg, $err ) = Net::DHCPv6->decode_with_error( $bytes );
    ok( !$err, "$desc: decode succeeds" ) or do { diag "err: $err"; next };

    subtest $desc => sub {
        is( $msg->msg_type,       $exp->{msg_type},       "Checking msg_type is $exp->{msg_type}" );
        is( $msg->transaction_id, $exp->{transaction_id}, "Checking transaction_id is " . $exp->{transaction_id} );
    };
}

subtest 'solicit options' => sub {
    my ( $msg ) = Net::DHCPv6->decode_or_croak( $data[0][1] );
    my $ol = $msg->options;

    my $cid = $ol->get_option( 1 );
    ok( $cid, 'CLIENTID present' );
    is( $cid->duid->duid_type,                  3,              'ClientId duid_type=3 (LL)' );
    is( $cid->duid->link_layer_type,            1,              'ClientId hwtype=1 (Ethernet)' );
    is( unpack( 'H*', $cid->duid->identifier ), '000102030405', 'ClientId MAC' );

    my $oro = $ol->get_option( 6 );
    ok( $oro, 'ORO present' );
    is( $oro->requested_options, [ 23, 24 ], 'ORO requests DNS + Domain' );

    my $et = $ol->get_option( 8 );
    ok( $et, 'ELAPSED_TIME present' );
    is( $et->centiseconds, 0, 'ElapsedTime is 0' );

    my $pd = $ol->get_option( 25 );
    ok( $pd, 'IA_PD present' );
    is( $pd->iaid, 33752069, 'IA_PD iaid' );
    is( $pd->t1,   3600,     'IA_PD t1' );
    is( $pd->t2,   5400,     'IA_PD t2' );
    ok( !@{ $pd->options->options }, 'IA_PD no sub-options in solicit' );
};

subtest 'advertise options' => sub {
    my ( $msg ) = Net::DHCPv6->decode_or_croak( $data[1][1] );
    my $ol = $msg->options;

    my $pd = $ol->get_option( 25 );
    ok( $pd, 'IA_PD present' );
    is( $pd->iaid, 33752069, 'IA_PD iaid' );
    is( $pd->t1,   3600,     'IA_PD t1' );
    is( $pd->t2,   5400,     'IA_PD t2' );

    my $pfx = $pd->get_option( 26 );
    ok( $pfx, 'IAPREFIX present' );
    is( $pfx->preferred_lifetime, 4500,                                             'IAPREFIX preferred' );
    is( $pfx->valid_lifetime,     7200,                                             'IAPREFIX valid' );
    is( $pfx->prefix_length,      56,                                               'IAPREFIX prefix_len=56' );
    is( $pfx->address,            pack( 'H*', '2a000001000101000000000000000000' ), 'IAPREFIX address' );

    my $cid = $ol->get_option( 1 );
    ok( $cid, 'CLIENTID present' );
    is( $cid->duid->duid_type, 3, 'ClientId duid_type=3' );

    my $sid = $ol->get_option( 2 );
    ok( $sid, 'SERVERID present' );
    is( $sid->duid->duid_type,                  1,              'ServerId duid_type=1 (LLT)' );
    is( $sid->duid->link_layer_type,            1,              'ServerId hwtype=1' );
    is( $sid->duid->time,                       407259545,      'ServerId time' );
    is( unpack( 'H*', $sid->duid->identifier ), '001122334455', 'ServerId MAC' );
};

subtest 'request options' => sub {
    my ( $msg ) = Net::DHCPv6->decode_or_croak( $data[2][1] );
    my $ol = $msg->options;

    my $pd = $ol->get_option( 25 );
    ok( $pd, 'IA_PD present' );
    is( $pd->t1, 3600, 'IA_PD t1' );
    is( $pd->t2, 5400, 'IA_PD t2' );

    my $pfx = $pd->get_option( 26 );
    ok( $pfx, 'IAPREFIX present' );
    is( $pfx->preferred_lifetime, 7200, 'IAPREFIX preferred' );
    is( $pfx->valid_lifetime,     7500, 'IAPREFIX valid' );
    is( $pfx->prefix_length,      56,   'IAPREFIX prefix_len=56' );
};

subtest 'reply options' => sub {
    my ( $msg ) = Net::DHCPv6->decode_or_croak( $data[3][1] );
    my $ol      = $msg->options;
    my $pd      = $ol->get_option( 25 );

    my $pfx = $pd->get_option( 26 );
    ok( $pfx, 'IAPREFIX present' );
    is( $pfx->preferred_lifetime, 4500, 'IAPREFIX preferred' );
    is( $pfx->valid_lifetime,     7200, 'IAPREFIX valid' );
    is( $pfx->prefix_length,      56,   'IAPREFIX prefix_len=56' );
};

done_testing;
