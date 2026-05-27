#!/usr/bin/env perl
use strictures 2;
use Test2::V1 -ipP;
use lib 't/lib';
use lib 'lib';

use Net::DHCPv6;
use Net::DHCPv6::Constants;
use Net::DHCPv6::OptionList;

# Hex fixture extracted from t/data/dhcpv6-mud.pcap (1st of 5 identical RELAY_FORW)
# Origin: https://git.codelinaro.org/clo/la/platform/external/tcpdump/-/tree/aosp-new/aosp-new/master/tests
my $hex =
'0c00200108a810060003022584fffedb2380fe80000000000000ba27ebfffeb853c8000900c60178244b0001000e000100011e62770bb827ebb853c80008000200000010003300009f08002d6468637063642d362e31312e353a4c696e75782d342e312e31382d76372b3a61726d76376c3a42434d32373039000e00000003000cebb853c800000000000000000027000d010b72617370626572727970690070003668747470733a2f2f6d756463746c2e6578616d706c652e636f6d2f2e77656c6c2d6b6e6f776e2f6d75642f76312f7261736270313031001400000006000c00170018001f0027005200530012000400000008';
my $bytes = pack( "H*", $hex );

my ( $msg, $err ) = Net::DHCPv6->decode_with_error( $bytes );
ok( !$err, 'relay-forward: decode succeeds' ) or do { diag "err: $err"; done_testing; exit };

subtest 'relay-forward' => sub {
    is( $msg->msg_type, 12, 'Checking msg_type is 12 (RELAY_FORW)' );
    ok( $msg->options->isa( 'Net::DHCPv6::OptionList' ), 'options is an OptionList' );
};

subtest 'relay-forward options' => sub {
    my $ol = $msg->options;

    my $relay_msg = $ol->get_option( 9 );
    ok( $relay_msg, 'RELAY_MSG (option 9) present' );

    my $iface = $ol->get_option( 18 );
    ok( $iface, 'INTERFACE_ID (option 18) present' );
};

subtest 'inner solicit' => sub {
    my $relay_msg = $msg->options->get_option( 9 );
    my ( $inner ) = Net::DHCPv6->decode_with_error( $relay_msg->data );
    ok( $inner, 'inner SOLICIT decodes successfully' );

    is( $inner->msg_type, 1, 'Inner msg_type is 1 (SOLICIT)' );

    my $ol = $inner->options;
    ok( $ol->get_option( 1 ),  'CLIENTID present' );
    ok( $ol->get_option( 8 ),  'ELAPSED_TIME present' );
    ok( $ol->get_option( 16 ), 'VENDOR_CLASS present' );
    ok( $ol->get_option( 14 ), 'RAPID_COMMIT present' );
    ok( $ol->get_option( 3 ),  'IA_NA present' );
    ok( $ol->get_option( 39 ), 'CLIENT_FQDN present' );
    ok( $ol->get_option( 6 ),  'ORO present' );

    my $mud = $ol->get_option( 112 );
    ok( $mud, 'MUD_URL (option 112) present' );
    like( $mud->url, qr{mudctl\.example\.com}, 'MUD URL contains expected domain' );
    ok( $mud->isa( 'Net::DHCPv6::Option::MudUrl' ), 'MUD_URL parsed as MudUrl class' );

    my $accept = $ol->get_option( 20 );
    ok( $accept, 'RECONF_ACCEPT present' );

    my $ia_na = $ol->get_option( 3 );
    ok( !@{ $ia_na->options->options }, 'IA_NA no sub-options in solicit' );
};

done_testing;
