#!/usr/bin/env perl
use strictures 2;
use Test2::V1 -ipP;
use lib 't/lib';
use lib 'lib';

use Net::DHCPv6;
use Net::DHCPv6::Constants;
use Net::DHCPv6::OptionList;

# Hex fixtures extracted from t/data/dhcpv6-ia-ta.pcap
# Origin: https://git.codelinaro.org/clo/la/platform/external/tcpdump/-/tree/aosp-new/aosp-new/master/tests
my @data = (
    [ 'solicit', pack( "H*", "0128b0400001000a0003000100010203040500060004001700180008000200000004000402030405" ) ],
    [
        'advertise',
        pack( "H*",
"0228b0400004002002030405000500182a000001000102005da2f92084c488cc0000119400001c200001000a000300010001020304050002000e00010001184647f0001122334455"
        )
    ],
    [
        'request',
        pack( "H*",
"032b0e450001000a000300010001020304050002000e00010001184647f000112233445500060004001700180008000200000004002002030405000500182a000001000102005da2f92084c488cc00001c2000001d4c"
        )
    ],
    [
        'reply',
        pack( "H*",
"072b0e450004002002030405000500182a000001000102005da2f92084c488cc0000119400001c200001000a000300010001020304050002000e00010001184647f0001122334455"
        )
    ],
);

my @expect = (
    { msg_type => 1, transaction_id => 0x28B040 },
    { msg_type => 2, transaction_id => 0x28B040 },
    { msg_type => 3, transaction_id => 0x2B0E45 },
    { msg_type => 7, transaction_id => 0x2B0E45 },
);

for my $i ( 0 .. $#data ) {
    my ( $desc, $bytes ) = @{ $data[$i] };
    my $exp = $expect[$i];

    my ( $msg, $err ) = Net::DHCPv6->decode_with_error( $bytes );
    ok( !$err, "$desc: decode succeeds" ) or do { diag "err: $err"; next };

    subtest $desc => sub {
        is( $msg->msg_type,       $exp->{msg_type},       "Checking msg_type is $exp->{msg_type}" );
        is( $msg->transaction_id, $exp->{transaction_id}, "Checking transaction_id" );
        ok( $msg->options->isa( 'Net::DHCPv6::OptionList' ), 'options is an OptionList' );
    };
}

subtest 'solicit options' => sub {
    my ( $msg ) = Net::DHCPv6->decode_or_croak( $data[0][1] );
    my $ol = $msg->options;

    my $cid = $ol->get_option( 1 );
    ok( $cid, 'CLIENTID present' );
    is( $cid->duid->duid_type,       3, 'ClientId duid_type=3 (LL)' );
    is( $cid->duid->link_layer_type, 1, 'ClientId hwtype=1 (Ethernet)' );

    my $oro = $ol->get_option( 6 );
    ok( $oro, 'ORO present' );
    is( $oro->requested_options, [ 23, 24 ], 'ORO requests DNS + Domain' );

    my $et = $ol->get_option( 8 );
    ok( $et, 'ELAPSED_TIME present' );
    is( $et->centiseconds, 0, 'ElapsedTime is 0' );

    my $ta = $ol->get_option( 4 );
    ok( $ta, 'IA_TA present' );
    is( $ta->iaid, 33752069, 'IA_TA iaid' );
    ok( !@{ $ta->options->options }, 'IA_TA no sub-options in solicit' );
};

subtest 'advertise options' => sub {
    my ( $msg ) = Net::DHCPv6->decode_or_croak( $data[1][1] );
    my $ol = $msg->options;

    my $ta = $ol->get_option( 4 );
    ok( $ta, 'IA_TA present' );
    is( $ta->iaid, 33752069, 'IA_TA iaid' );

    my $addr = $ta->get_option( 5 );
    ok( $addr, 'IAADDR present' );
    is( $addr->preferred_lifetime, 4500, 'IAADDR preferred_lifetime' );
    is( $addr->valid_lifetime,     7200, 'IAADDR valid_lifetime' );

    my $cid = $ol->get_option( 1 );
    ok( $cid, 'CLIENTID present' );
    is( $cid->duid->duid_type, 3, 'ClientId duid_type=3' );

    my $sid = $ol->get_option( 2 );
    ok( $sid, 'SERVERID present' );
    is( $sid->duid->duid_type, 1, 'ServerId duid_type=1 (LLT)' );
};

subtest 'request options' => sub {
    my ( $msg ) = Net::DHCPv6->decode_or_croak( $data[2][1] );
    my $ol = $msg->options;

    my $ta = $ol->get_option( 4 );
    ok( $ta, 'IA_TA present' );

    my $addr = $ta->get_option( 5 );
    ok( $addr, 'IAADDR present' );
    is( $addr->preferred_lifetime, 7200, 'IAADDR preferred_lifetime' );
    is( $addr->valid_lifetime,     7500, 'IAADDR valid_lifetime' );
};

subtest 'reply options' => sub {
    my ( $msg ) = Net::DHCPv6->decode_or_croak( $data[3][1] );
    my $ol = $msg->options;

    my $ta = $ol->get_option( 4 );
    ok( $ta, 'IA_TA present' );

    my $addr = $ta->get_option( 5 );
    ok( $addr, 'IAADDR present' );
    is( $addr->preferred_lifetime, 4500, 'IAADDR preferred_lifetime' );
    is( $addr->valid_lifetime,     7200, 'IAADDR valid_lifetime' );
};

done_testing;
