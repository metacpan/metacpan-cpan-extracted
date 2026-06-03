#!/usr/bin/env perl
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
use strictures 2;
use Test2::V1 -ipP, qw(is ok subtest diag done_testing);    ## no critic (Subroutines::ProhibitCallsToUndeclaredSubs)

use lib 't/lib';
use lib 'lib';

use Net::DHCPv6             ();
use Net::DHCPv6::OptionList ();

# Hex fixture extracted from t/data/dhcpv6-sip-server-d.pcap
# Origin: https://git.codelinaro.org/clo/la/platform/external/tcpdump/-/tree/aosp-new/aosp-new/master/tests
my $hex =
'076890d80001000e0001000118f00b3f000c2938f3680002000e0001000118ef951b000c299ba1530015003e0473697031096d792d646f6d61696e036e6574000473697032076578616d706c6503636f6d00047369703303737562096d792d646f6d61696e036f726700';
my $bytes = pack( 'H*', $hex );

my ( $msg, $err ) = Net::DHCPv6->decode_with_error( $bytes );
if ( $err ) {
    diag "err: $err";
    done_testing;
    exit;
}
ok( 1, 'decode succeeds' );

subtest 'reply' => sub {
    is( $msg->msg_type,       7,        'Checking msg_type is 7 (REPLY)' );
    is( $msg->transaction_id, 0x6890D8, 'Checking transaction_id' );          ## no critic (ValuesAndExpressions::RequireNumberSeparators)
    ok( $msg->options->isa( 'Net::DHCPv6::OptionList' ), 'options is an OptionList' );
};

subtest 'reply options' => sub {
    my $ol = $msg->options;

    my $cid = $ol->get_option( 1 );
    ok( $cid, 'CLIENTID present' );
    is( $cid->duid->duid_type, 1,           'ClientId duid_type=1 (LLT)' );
    is( $cid->duid->time,      418_384_703, 'ClientId time' );

    my $sid = $ol->get_option( 2 );
    ok( $sid, 'SERVERID present' );
    is( $sid->duid->duid_type, 1,           'ServerId duid_type=1 (LLT)' );
    is( $sid->duid->time,      418_354_459, 'ServerId time' );

    my $sip = $ol->get_option( 21 );
    ok( $sip,                                           'SIP_SERVER_D (option 21) present' );
    ok( $sip->isa( 'Net::DHCPv6::Option::SipServerD' ), 'SIP_SERVER_D parsed as SipServerD class' );
    is(
        $sip->domains,
        [ 'sip1.my-domain.net', 'sip2.example.com', 'sip3.sub.my-domain.org' ],
        'SipServerD parsed domain list'
    );
};

## use critic (ValuesAndExpressions::ProhibitMagicNumbers)
done_testing;
