#!/usr/bin/env perl
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
use strictures 2;
use Test2::V1 -ipP, qw(is ok subtest like diag done_testing);    ## no critic (Subroutines::ProhibitCallsToUndeclaredSubs)

use lib 't/lib';
use lib 'lib';

use Net::DHCPv6                    ();
use Net::DHCPv6::OptionList        ();
use Net::DHCPv6::Option::NtpServer ();

# Hex fixture extracted from t/data/dhcpv6-ntp-server.pcap
# Origin: https://git.codelinaro.org/clo/la/platform/external/tcpdump/-/tree/aosp-new/aosp-new/master/tests
my $hex =
'07f69b570001000e0001000118f00b3f000c2938f3680002000e0001000118ef951b000c299ba1530038003d000100102a01000000000000000000000000000100020010ff05000000000000000000000000010100030011036e7470076578616d706c6503636f6d00';
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
    is( $msg->transaction_id, 0xF69B57, 'Checking transaction_id' );
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

    my $ntp = $ol->get_option( 56 );
    ok( $ntp, 'NTP_SERVER (option 56) present' );
    like( $ntp->data, qr/ntp/, 'NTP data contains ntp domain' );
    ok( $ntp->entries, 'NtpServer has entries' );
    is( scalar @{ $ntp->entries },    3,        'NtpServer has 3 sub-entries' );
    is( $ntp->entries->[2]->{type},   'domain', 'third entry is domain type' );
    is( $ntp->entries->[2]->{subopt}, 3,        'domain subopt code is 3' );
    my $domain_bytes = $ntp->entries->[2]->{value};
    like( $domain_bytes, qr/ntp/, 'domain value contains ntp' );
};

## use critic (ValuesAndExpressions::ProhibitMagicNumbers)
done_testing;
