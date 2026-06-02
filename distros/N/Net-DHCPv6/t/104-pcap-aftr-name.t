#!/usr/bin/env perl
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
use strictures 2;
use Test2::V1 -ipP, qw(is ok subtest like diag done_testing);    ## no critic (Subroutines::ProhibitCallsToUndeclaredSubs)

use lib 't/lib';
use lib 'lib';

use Net::DHCPv6;
use Net::DHCPv6::Constants;
use Net::DHCPv6::OptionList;

# Hex fixtures extracted from t/data/dhcpv6-AFTR-Name-RFC6334.pcap
# Origin: https://git.codelinaro.org/clo/la/platform/external/tcpdump/-/tree/aosp-new/aosp-new/master/tests
my @entries = (
    [
        'solicit',
        pack( 'H*',
            '01d81eb80001000a0003000100010203040500060004001700400008000200000019000c0203040500000e1000001518', ),
    ],
    [
        'advertise',
        pack( 'H*',
'02d81eb8001900290203040500000096000000fa001a0019000000fa0000012c382a0000010001010000000000000000000001000a000300010001020304050002000e00010001183f4ef0001122334455000700010a001700102a0100000000000000000000000000010040001809616674722d6e616d65086d79646f6d61696e036e657400',
        ),
    ],
    [
        'request',
        pack( 'H*',
'031e291d0001000a000300010001020304050002000e00010001183f4ef00011223344550006000400170040000800020000001900290203040500000e1000001518001a001900001c2000001d4c382a000001000101000000000000000000',
        ),
    ],
    [
        'reply',
        pack( 'H*',
'071e291d001900290203040500000096000000fa001a0019000000fa0000012c382a0000010001010000000000000000000001000a000300010001020304050002000e00010001183f4ef0001122334455000700010a001700102a0100000000000000000000000000010040001809616674722d6e616d65086d79646f6d61696e036e657400',
        ),
    ],
);

my @expect = (
    { msg_type => 1, transaction_id => 0xD81EB8 },
    { msg_type => 2, transaction_id => 0xD81EB8 },
    { msg_type => 3, transaction_id => 0x1E291D },
    { msg_type => 7, transaction_id => 0x1E291D },
);

for my $i ( 0 .. $#entries ) {
    my ( $desc, $bytes ) = @{ $entries[$i] };
    my $exp = $expect[$i];

    my ( $msg, $err ) = Net::DHCPv6->decode_with_error( $bytes );
    if ( $err ) { diag "err: $err"; next }

    subtest $desc => sub {
        is( $msg->msg_type,       $exp->{msg_type},       "Checking msg_type is $exp->{msg_type}" );
        is( $msg->transaction_id, $exp->{transaction_id}, 'Checking transaction_id' );
        ok( $msg->options->isa( 'Net::DHCPv6::OptionList' ), 'options is an OptionList' );
    };
}

subtest 'solicit options' => sub {
    my ( $msg ) = Net::DHCPv6->decode_or_croak( $entries[0][1] );
    my $ol = $msg->options;

    my $cid = $ol->get_option( 1 );
    ok( $cid, 'CLIENTID present' );
    is( $cid->duid->duid_type,                  3,                   'ClientId duid_type=3 (LL)' );
    is( $cid->duid->link_layer_type,            $LINK_TYPE_ETHERNET, 'ClientId hwtype=1 (Ethernet)' );
    is( unpack( 'H*', $cid->duid->identifier ), '000102030405',      'ClientId MAC' );

    my $oro = $ol->get_option( 6 );
    ok( $oro, 'ORO present' );
    is( $oro->requested_options, [ 23, 64 ], 'ORO requests [23, 64]' );

    my $et = $ol->get_option( 8 );
    ok( $et, 'ELAPSED_TIME present' );
    is( $et->centiseconds, 0, 'ElapsedTime is 0' );

    my $pd = $ol->get_option( 25 );
    ok( $pd, 'IA_PD present' );
    is( $pd->t1, 3600, 'IA_PD t1' );
    is( $pd->t2, 5400, 'IA_PD t2' );
    ok( !@{ $pd->options->options }, 'IA_PD no sub-options in solicit' );
};

subtest 'advertise options' => sub {
    my ( $msg ) = Net::DHCPv6->decode_or_croak( $entries[1][1] );
    my $ol = $msg->options;

    my $pd = $ol->get_option( 25 );
    ok( $pd, 'IA_PD present' );
    is( $pd->t1, 150, 'IA_PD t1' );
    is( $pd->t2, 250, 'IA_PD t2' );

    my $pfx = $pd->get_option( 26 );
    ok( $pfx, 'IAPREFIX present' );
    is( $pfx->preferred_lifetime,          250,                                'IAPREFIX preferred' );
    is( $pfx->valid_lifetime,              300,                                'IAPREFIX valid' );
    is( $pfx->prefix_length,               56,                                 'IAPREFIX prefix_len=56' );
    is( unpack( 'H*', $pfx->address_raw ), '2a000001000101000000000000000000', 'IAPREFIX address_raw' );
    is( $pfx->address,                     '2a00:1:1:100::',                   'IAPREFIX address' );

    my $pref = $ol->get_option( 7 );
    ok( $pref, 'PREFERENCE present' );
    is( $pref->value, 10, 'Preference value=10' );

    my $dns = $ol->get_option( 23 );
    ok( $dns, 'DNS_SERVERS present' );
    is( scalar @{ $dns->servers }, 1, 'One DNS server' );

    my $aftr = $ol->get_option( 64 );
    ok( $aftr, 'OPTION_64 (AFTR-Name-like) present' );
    like( $aftr->data, qr/aftr-name/, 'OPTION_64 data contains aftr-name' );
};

subtest 'request options' => sub {
    my ( $msg ) = Net::DHCPv6->decode_or_croak( $entries[2][1] );
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
    my ( $msg ) = Net::DHCPv6->decode_or_croak( $entries[3][1] );
    my $ol = $msg->options;

    my $pd = $ol->get_option( 25 );
    ok( $pd, 'IA_PD present' );
    is( $pd->t1, 150, 'IA_PD t1' );
    is( $pd->t2, 250, 'IA_PD t2' );

    my $pfx = $pd->get_option( 26 );
    ok( $pfx, 'IAPREFIX present' );
    is( $pfx->preferred_lifetime, 250, 'IAPREFIX preferred' );
    is( $pfx->valid_lifetime,     300, 'IAPREFIX valid' );

    my $pref = $ol->get_option( 7 );
    ok( $pref, 'PREFERENCE present' );
    is( $pref->value, 10, 'Preference value=10' );

    my $aftr = $ol->get_option( 64 );
    ok( $aftr, 'OPTION_64 (AFTR-Name-like) present' );
};

## use critic (ValuesAndExpressions::ProhibitMagicNumbers)
done_testing;
