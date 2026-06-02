#!/usr/bin/env perl
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
use strictures 2;
use Test2::V1 -ipP, qw(is ok subtest diag done_testing);    ## no critic (Subroutines::ProhibitCallsToUndeclaredSubs)

use lib 't/lib';
use lib 'lib';

use Net::DHCPv6;
use Net::DHCPv6::Constants;
use Net::DHCPv6::OptionList;

# Hex fixtures extracted from t/data/wireshark-sample-DHCPv6.pcap
# Origin: https://wiki.wireshark.org/samplecaptures
my @entries = (
    [
        'solicit',
        pack( 'H*',
            '011008740001000e000100011c39cf88080027fe8f9500060004001700180008000200000019000c27fe8f9500000e1000001518',
        ),
    ],
    [
        'advertise',
        pack( 'H*',
'021008740019002927fe8f950000000000000000001a00190000119400001c2040200100000000fe0000000000000000000001000e000100011c39cf88080027fe8f950002000e000100011c3825e8080027d410bb',
        ),
    ],
    [
        'request',
        pack( 'H*',
'0349174e0001000e000100011c39cf88080027fe8f950002000e000100011c3825e8080027d410bb00060004001700180008000200000019002927fe8f9500000e1000001518001a001900001c2000001d4c40200100000000fe000000000000000000',
        ),
    ],
    [
        'reply',
        pack( 'H*',
'0749174e0019002927fe8f950000000000000000001a00190000119400001c2040200100000000fe0000000000000000000001000e000100011c39cf88080027fe8f950002000e000100011c3825e8080027d410bb',
        ),
    ],
    [
        'release',
        pack( 'H*',
'08c789b00001000e000100011c39cf88080027fe8f950002000e000100011c3825e8080027d410bb00060004001700180008000200000019002927fe8f950000000000000000001a0019000000000000000040200100000000fe000000000000000000',
        ),
    ],
    [
        'reply2',
        pack( 'H*',
'07c789b00001000e000100011c39cf88080027fe8f950002000e000100011c3825e8080027d410bb000d0013000052656c656173652072656365697665642e',
        ),
    ],
);

my @expect = (
    {    # solicit
        msg_type       => 1,
        transaction_id => 0x100874,    ## no critic (ValuesAndExpressions::RequireNumberSeparators)
    },
    {                                  # advertise
        msg_type       => 2,
        transaction_id => 0x100874,    ## no critic (ValuesAndExpressions::RequireNumberSeparators)
    },
    {                                  # request
        msg_type       => 3,
        transaction_id => 0x49174E,    ## no critic (ValuesAndExpressions::RequireNumberSeparators)
    },
    {                                  # reply
        msg_type       => 7,
        transaction_id => 0x49174E,    ## no critic (ValuesAndExpressions::RequireNumberSeparators)
    },
    {                                  # release
        msg_type       => 8,
        transaction_id => 0xC789B0,
    },
    {                                  # reply2
        msg_type       => 7,
        transaction_id => 0xC789B0,
    },
);

for my $i ( 0 .. $#entries ) {
    my ( $desc, $bytes ) = @{ $entries[$i] };
    my $exp = $expect[$i];

    my ( $msg, $err ) = Net::DHCPv6->decode_with_error( $bytes );
    if ( $err ) { diag "err: $err"; next }

    subtest $desc => sub {
        is( $msg->msg_type,       $exp->{msg_type},       "Checking msg_type is $exp->{msg_type}" );
        is( $msg->transaction_id, $exp->{transaction_id}, 'Checking transaction_id is ' . $exp->{transaction_id} );

        ok( $msg->options->isa( 'Net::DHCPv6::OptionList' ), 'options is an OptionList' );
    };
}

# Spot-check specific option values per packet
subtest 'solicit options' => sub {
    my ( $msg ) = Net::DHCPv6->decode_or_croak( $entries[0][1] );
    my $ol = $msg->options;

    my $cid = $ol->get_option( 1 );
    ok( $cid, 'CLIENTID present' );
    is( $cid->duid->duid_type,                  1,                   'ClientId duid_type=1 (LLT)' );
    is( $cid->duid->link_layer_type,            $LINK_TYPE_ETHERNET, 'ClientId hwtype=1 (Ethernet)' );
    is( $cid->duid->time,                       473_550_728,         'ClientId time' );
    is( unpack( 'H*', $cid->duid->identifier ), '080027fe8f95',      'ClientId MAC' );

    my $oro = $ol->get_option( 6 );
    ok( $oro, 'ORO present' );
    is( $oro->requested_options, [ 23, 24 ], 'ORO requests DNS + Domain' );

    my $et = $ol->get_option( 8 );
    ok( $et, 'ELAPSED_TIME present' );
    is( $et->centiseconds, 0, 'ElapsedTime is 0' );

    my $pd = $ol->get_option( 25 );
    ok( $pd, 'IA_PD present' );
    is( $pd->iaid, 670_994_325, 'IA_PD iaid' );
    is( $pd->t1,   3600,        'IA_PD t1' );
    is( $pd->t2,   5400,        'IA_PD t2' );
    ok( !@{ $pd->options->options }, 'IA_PD no sub-options in solicit' );
};

subtest 'advertise options' => sub {
    my ( $msg ) = Net::DHCPv6->decode_or_croak( $entries[1][1] );
    my $ol = $msg->options;

    my $pd = $ol->get_option( 25 );
    ok( $pd, 'IA_PD present' );
    is( $pd->iaid, 670_994_325, 'IA_PD iaid' );
    is( $pd->t1,   0,           'IA_PD t1=0' );
    is( $pd->t2,   0,           'IA_PD t2=0' );

    my $pfx = $pd->get_option( 26 );
    ok( $pfx, 'IAPREFIX present' );
    is( $pfx->preferred_lifetime,          4500,                               'IAPREFIX preferred' );
    is( $pfx->valid_lifetime,              7200,                               'IAPREFIX valid' );
    is( $pfx->prefix_length,               64,                                 'IAPREFIX prefix_len' );
    is( unpack( 'H*', $pfx->address_raw ), '200100000000fe000000000000000000', 'IAPREFIX address hex' );

    my $cid = $ol->get_option( 1 );
    ok( $cid, 'CLIENTID present' );
    is( $cid->duid->duid_type, 1, 'ClientId duid_type=1' );

    my $sid = $ol->get_option( 2 );
    ok( $sid, 'SERVERID present' );
    is( $sid->duid->time,                       473_441_768,    'ServerId time' );
    is( unpack( 'H*', $sid->duid->identifier ), '080027d410bb', 'ServerId MAC' );
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
};

subtest 'reply options' => sub {
    my ( $msg ) = Net::DHCPv6->decode_or_croak( $entries[3][1] );
    my $ol = $msg->options;

    my $pd = $ol->get_option( 25 );
    ok( $pd, 'IA_PD present' );
    is( $pd->t1, 0, 'IA_PD t1=0' );
    is( $pd->t2, 0, 'IA_PD t2=0' );

    my $pfx = $pd->get_option( 26 );
    is( $pfx->preferred_lifetime, 4500, 'IAPREFIX preferred' );
    is( $pfx->valid_lifetime,     7200, 'IAPREFIX valid' );
};

subtest 'release options' => sub {
    my ( $msg ) = Net::DHCPv6->decode_or_croak( $entries[4][1] );
    my $ol = $msg->options;

    my $pd = $ol->get_option( 25 );
    ok( $pd, 'IA_PD present' );
    is( $pd->t1, 0, 'IA_PD t1=0' );
    is( $pd->t2, 0, 'IA_PD t2=0' );

    my $pfx = $pd->get_option( 26 );
    ok( $pfx, 'IAPREFIX present' );
    is( $pfx->preferred_lifetime, 0, 'IAPREFIX preferred=0 in release' );
    is( $pfx->valid_lifetime,     0, 'IAPREFIX valid=0 in release' );
};

subtest 'reply2 (release ack) options' => sub {
    my ( $msg ) = Net::DHCPv6->decode_or_croak( $entries[5][1] );
    my $ol = $msg->options;

    my $sc = $ol->get_option( 13 );
    ok( $sc, 'STATUS_CODE present' );
    is( $sc->status_code, 0,                   'StatusCode success (0)' );
    is( $sc->message,     'Release received.', 'StatusCode message' );
};

## use critic (ValuesAndExpressions::ProhibitMagicNumbers)
done_testing;
