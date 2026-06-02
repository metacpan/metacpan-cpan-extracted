#!/usr/bin/env perl
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
use strictures 2;
use Test2::Tools::Exception qw( dies );
use Test2::V1 -ipP, qw(is ok done_testing);            ## no critic (Subroutines::ProhibitCallsToUndeclaredSubs)

use lib 't/lib';
use lib 'lib';

use Net::DHCPv6::Option;
use Net::DHCPv6::Option::Generic;
use Net::DHCPv6::Option::ClientId;
use Net::DHCPv6::Option::ServerId;
use Net::DHCPv6::DUID;
use Net::DHCPv6::Option::ORO;
use Net::DHCPv6::Option::Preference;
use Net::DHCPv6::Option::ElapsedTime;
use Net::DHCPv6::Option::StatusCode;
use Net::DHCPv6::Option::RapidCommit;
use Net::DHCPv6::Option::IANA;
use Net::DHCPv6::Option::IATA;
use Net::DHCPv6::Option::IAAddr;
use Net::DHCPv6::Option::IAPD;
use Net::DHCPv6::Option::IAPrefix;
use Net::DHCPv6::OptionList;
use Net::DHCPv6::Constants;
my $EMPTY = q();

# Generic option
my $gen = Net::DHCPv6::Option::Generic->new( code => 99, data => pack( 'H*', '0102' ) );
is( $gen->code, 99,                   'Generic code' );
is( $gen->data, pack( 'H*', '0102' ), 'Generic data' );
is( $gen->type, undef,                'Generic type (unknown)' );

# Generic round-trip
my $gen_bytes = $gen->as_bytes;
my ( $gen_parsed ) = Net::DHCPv6::Option->from_bytes( $gen_bytes );
ok( $gen_parsed->isa( 'Net::DHCPv6::Option::Generic' ), 'Generic parsed class' );
is( $gen_parsed->code, 99,                   'Generic parsed code' );
is( $gen_parsed->data, pack( 'H*', '0102' ), 'Generic parsed data' );

# ClientId
my $mac  = pack( 'H*', '001122334455' );
my $duid = Net::DHCPv6::DUID->new_llt( $LINK_TYPE_ETHERNET, 123_456, $mac );
my $cid  = Net::DHCPv6::Option::ClientId->new( duid => $duid );
is( $cid->code,            1,         'ClientId code' );
is( $cid->duid->duid_type, $DUID_LLT, 'ClientId DUID type' );

my $bytes = $cid->as_bytes;
ok( CORE::length( $bytes ) > 4, 'ClientId as_bytes has TLV header' );

# Parse back from bytes
my ( $parsed, $remain ) = Net::DHCPv6::Option->from_bytes( $bytes );
ok( $parsed->isa( 'Net::DHCPv6::Option::ClientId' ), 'parsed ClientId class' );
is( $parsed->duid->time, 123_456, 'parsed ClientId DUID time' );
is( $remain,             $EMPTY,  'no trailing data' );

ok( dies { Net::DHCPv6::Option::ClientId->new }, 'ClientId dies without duid' );
ok( dies { Net::DHCPv6::Option::ClientId::from_bytes_inner( undef, 1, pack( 'H*', '0001' ) ) },
    'ClientId dies on truncated DUID data' );

# ServerId
my $sid = Net::DHCPv6::Option::ServerId->new( duid => $duid );
is( $sid->code, 2, 'ServerId code' );

# ServerId round-trip
my $sid_bytes = $sid->as_bytes;
my ( $sid_parsed ) = Net::DHCPv6::Option->from_bytes( $sid_bytes );
ok( $sid_parsed->isa( 'Net::DHCPv6::Option::ServerId' ), 'ServerId parsed class' );
is( $sid_parsed->duid->time, 123_456, 'ServerId parsed DUID time' );

ok( dies { Net::DHCPv6::Option::ServerId->new }, 'ServerId dies without duid' );
ok( dies { Net::DHCPv6::Option::ServerId::from_bytes_inner( undef, 2, pack( 'H*', '0001' ) ) },
    'ServerId dies on truncated DUID data' );

# ORO
my $oro = Net::DHCPv6::Option::ORO->new( requested_options => [ 23, 24 ] );
is( $oro->code,              6,          'ORO code' );
is( $oro->requested_options, [ 23, 24 ], 'ORO requested opts' );

# ORO round-trip
my $oro_bytes = $oro->as_bytes;
my ( $oro_parsed ) = Net::DHCPv6::Option->from_bytes( $oro_bytes );
ok( $oro_parsed->isa( 'Net::DHCPv6::Option::ORO' ), 'ORO parsed class' );
is( $oro_parsed->requested_options, [ 23, 24 ], 'ORO parsed options' );

ok( dies { Net::DHCPv6::Option::ORO::from_bytes_inner( undef, 6, chr( 1 ) ) }, 'ORO dies on odd-length data' );

# Preference
my $pref = Net::DHCPv6::Option::Preference->new( value => 255 );
is( $pref->value, 255, 'Preference value' );

# Preference round-trip
my $pref_bytes = $pref->as_bytes;
my ( $pref_parsed ) = Net::DHCPv6::Option->from_bytes( $pref_bytes );
ok( $pref_parsed->isa( 'Net::DHCPv6::Option::Preference' ), 'Preference parsed class' );
is( $pref_parsed->value, 255, 'Preference parsed value' );

ok( dies { Net::DHCPv6::Option::Preference->new }, 'Preference dies without value' );
ok( dies { Net::DHCPv6::Option::Preference::from_bytes_inner( undef, 7, pack( 'H*', '0102' ) ) },
    'Preference dies on data != 1 byte' );

# ElapsedTime
my $elapsed = Net::DHCPv6::Option::ElapsedTime->new( centiseconds => 1000 );
is( $elapsed->centiseconds, 1000, 'ElapsedTime centiseconds' );

# ElapsedTime round-trip
my $elapsed_bytes = $elapsed->as_bytes;
my ( $elapsed_parsed ) = Net::DHCPv6::Option->from_bytes( $elapsed_bytes );
ok( $elapsed_parsed->isa( 'Net::DHCPv6::Option::ElapsedTime' ), 'ElapsedTime parsed class' );
is( $elapsed_parsed->centiseconds, 1000, 'ElapsedTime parsed centiseconds' );

ok( dies { Net::DHCPv6::Option::ElapsedTime->new }, 'ElapsedTime dies without centiseconds' );
ok( dies { Net::DHCPv6::Option::ElapsedTime::from_bytes_inner( undef, 8, chr( 1 ) ) },
    'ElapsedTime dies on data != 2 bytes' );

# StatusCode
my $sc = Net::DHCPv6::Option::StatusCode->new( status_code => 0, message => 'Success' );
is( $sc->status_code, 0,         'StatusCode code' );
is( $sc->message,     'Success', 'StatusCode message' );

# StatusCode round-trip
my $sc_bytes = $sc->as_bytes;
my ( $sc_parsed ) = Net::DHCPv6::Option->from_bytes( $sc_bytes );
ok( $sc_parsed->isa( 'Net::DHCPv6::Option::StatusCode' ), 'StatusCode parsed class' );
is( $sc_parsed->status_code, 0,         'StatusCode parsed code' );
is( $sc_parsed->message,     'Success', 'StatusCode parsed message' );

ok( dies { Net::DHCPv6::Option::StatusCode->new }, 'StatusCode dies without status_code' );
ok( dies { Net::DHCPv6::Option::StatusCode::from_bytes_inner( undef, 13, chr( 0 ) ) },
    'StatusCode dies on data < 2 bytes' );

# RapidCommit
my $rc = Net::DHCPv6::Option::RapidCommit->new;
is( $rc->code, 14,     'RapidCommit code' );
is( $rc->data, $EMPTY, 'RapidCommit empty data' );

# RapidCommit round-trip
my $rc_bytes = $rc->as_bytes;
my ( $rc_parsed ) = Net::DHCPv6::Option->from_bytes( $rc_bytes );
ok( $rc_parsed->isa( 'Net::DHCPv6::Option::RapidCommit' ), 'RapidCommit parsed class' );
is( $rc_parsed->data, $EMPTY, 'RapidCommit parsed empty data' );

ok( dies { Net::DHCPv6::Option::RapidCommit::from_bytes_inner( undef, 14, chr( 1 ) ) },
    'RapidCommit dies on non-empty data' );

# OptionList
my $ol = Net::DHCPv6::OptionList->new;
$ol->add_option( $cid );
$ol->add_option( $sid );
$ol->add_option( $oro );

is( $ol->get_option( 1 )->code, 1, 'OptionList get ClientId' );
is( $ol->get_option( 2 )->code, 2, 'OptionList get ServerId' );
is( $ol->get_option( 6 )->code, 6, 'OptionList get ORO' );

my $opts = $ol->options;
is( scalar @{$opts}, 3, 'OptionList order preserved with 3 options' );

# OptionList from_bytes / as_bytes
my $ol_bytes = $ol->as_bytes;
my $ol2      = Net::DHCPv6::OptionList->from_bytes( $ol_bytes );
is( $ol2->get_option( 1 )->code, 1, 'OptionList parse ClientId' );
is( $ol2->get_option( 2 )->code, 2, 'OptionList parse ServerId' );
is( $ol2->get_option( 6 )->code, 6, 'OptionList parse ORO' );

# OptionList remove_option
my $ol3 = Net::DHCPv6::OptionList->new;
$ol3->add_option( $cid );
$ol3->add_option( $sid );
$ol3->add_option( $oro );
is( $ol3->get_option( 2 )->code, 2, 'remove_option: ServerId present before remove' );
$ol3->remove_option( 2 );
ok( !defined $ol3->get_option( 2 ), 'remove_option: ServerId gone after remove' );
is( $ol3->get_option( 1 )->code, 1, 'remove_option: ClientId still present' );
is( $ol3->get_option( 6 )->code, 6, 'remove_option: ORO still present' );

# remove_option preserves order of remaining options
my $remaining = $ol3->options;
is( scalar @{$remaining},  2, 'remove_option: 2 options remain' );
is( $remaining->[0]->code, 1, 'remove_option: first remaining is ClientId' );
is( $remaining->[1]->code, 6, 'remove_option: second remaining is ORO' );

# remove_option on non-existent code is a no-op
$ol3->remove_option( 99 );
is( scalar @{ $ol3->options }, 2, 'remove_option: non-existent code does not change count' );

# remove_option all options leaves empty list
$ol3->remove_option( 1 );
$ol3->remove_option( 6 );
is( $ol3->options, [], 'remove_option: no options returns empty arrayref' );
ok( !defined $ol3->get_option( 1 ), 'remove_option: all gone, get returns undef' );

# IANA option with sub-options
my $iana = Net::DHCPv6::Option::IANA->new( iaid => 42, t1 => 3600, t2 => 5400 );
$iana->add_option( $elapsed );
is( $iana->iaid,                          42,   'IANA iaid' );
is( $iana->t1,                            3600, 'IANA t1' );
is( $iana->t2,                            5400, 'IANA t2' );
is( $iana->get_option( 8 )->centiseconds, 1000, 'IANA sub-option ElapsedTime' );

$bytes = $iana->as_bytes;
my $iana2 = Net::DHCPv6::Option::IANA->from_bytes_inner( $OPTION_IA_NA, substr( $bytes, 4 ) );
is( $iana2->iaid,                          42,   'parse IANA iaid' );
is( $iana2->get_option( 8 )->centiseconds, 1000, 'parse IANA sub-option' );

ok( dies { Net::DHCPv6::Option::IANA->new }, 'IANA dies without iaid' );
ok( dies { Net::DHCPv6::Option::IANA::from_bytes_inner( undef, 3, pack( 'C*', ( 1 ) x 11 ) ) },
    'IANA dies on data < 12 bytes' );

# IAAddr option
my $addr   = pack( 'H*', '20010db8000000000000000000000001' );
my $iaaddr = Net::DHCPv6::Option::IAAddr->new(
    address            => '2001:db8::1',
    preferred_lifetime => 7200,
    valid_lifetime     => 86_400,
);
is( $iaaddr->address,            '2001:db8::1', 'IAAddr address' );
is( $iaaddr->address_raw,        $addr,         'IAAddr address_raw' );
is( $iaaddr->preferred_lifetime, 7200,          'IAAddr preferred' );
is( $iaaddr->valid_lifetime,     86_400,        'IAAddr valid' );

# IAAddr round-trip
my $iaaddr_bytes = $iaaddr->as_bytes;
my ( $iaaddr_parsed ) = Net::DHCPv6::Option->from_bytes( $iaaddr_bytes );
ok( $iaaddr_parsed->isa( 'Net::DHCPv6::Option::IAAddr' ), 'IAAddr parsed class' );
is( $iaaddr_parsed->address,            '2001:db8::1', 'IAAddr parsed address' );
is( $iaaddr_parsed->address_raw,        $addr,         'IAAddr parsed address_raw' );
is( $iaaddr_parsed->preferred_lifetime, 7200,          'IAAddr parsed preferred' );
is( $iaaddr_parsed->valid_lifetime,     86_400,        'IAAddr parsed valid' );

ok( dies { Net::DHCPv6::Option::IAAddr->new }, 'IAAddr dies without address' );
ok( dies { Net::DHCPv6::Option::IAAddr::from_bytes_inner( undef, 5, pack( 'C*', ( 1 ) x 23 ) ) },
    'IAAddr dies on data < 24 bytes' );

# IATA option
my $iata = Net::DHCPv6::Option::IATA->new( iaid => 99 );
is( $iata->code, 4,       'IATA code' );
is( $iata->type, 'IA_TA', 'IATA type' );
is( $iata->iaid, 99,      'IATA iaid' );
ok( $iata->options->isa( 'Net::DHCPv6::OptionList' ), 'IATA options container' );

$iata->add_option( $elapsed );
is( $iata->get_option( 8 )->centiseconds, 1000, 'IATA sub-option ElapsedTime' );

$bytes = $iata->as_bytes;
my $iata2 = Net::DHCPv6::Option::IATA->from_bytes_inner( $OPTION_IA_TA, substr( $bytes, 4 ) );
is( $iata2->iaid,                          99,   'parse IATA iaid' );
is( $iata2->get_option( 8 )->centiseconds, 1000, 'parse IATA sub-option' );

ok( dies { Net::DHCPv6::Option::IATA->new },                                  'IATA dies without iaid' );
ok( dies { Net::DHCPv6::Option::IATA::from_bytes_inner( undef, 4, $EMPTY ) }, 'IATA dies on data < 4 bytes' );

# IAPD option (prefix delegation)
my $iapd = Net::DHCPv6::Option::IAPD->new( iaid => 7, t1 => 3600, t2 => 5400 );
is( $iapd->code, 25,      'IAPD code' );
is( $iapd->type, 'IA_PD', 'IAPD type' );
is( $iapd->iaid, 7,       'IAPD iaid' );
is( $iapd->t1,   3600,    'IAPD t1' );
is( $iapd->t2,   5400,    'IAPD t2' );

# IAPrefix sub-option
my $prefix_addr = pack( 'H*', '20010db8000000000000000000000000' );
my $iaprefix    = Net::DHCPv6::Option::IAPrefix->new(
    address            => '2001:db8::',
    preferred_lifetime => 7200,
    valid_lifetime     => 86_400,
    prefix_length      => 64,
);
is( $iaprefix->code,               26,           'IAPrefix code' );
is( $iaprefix->type,               'IAPREFIX',   'IAPrefix type' );
is( $iaprefix->address,            '2001:db8::', 'IAPrefix address' );
is( $iaprefix->address_raw,        $prefix_addr, 'IAPrefix address_raw' );
is( $iaprefix->preferred_lifetime, 7200,         'IAPrefix preferred' );
is( $iaprefix->valid_lifetime,     86_400,       'IAPrefix valid' );
is( $iaprefix->prefix_length,      64,           'IAPrefix prefix_len' );

$iapd->add_option( $iaprefix );
is( $iapd->get_option( 26 )->prefix_length, 64, 'IAPD IAPrefix sub-option' );

# IAPD round-trip via Option::from_bytes
$bytes = $iapd->as_bytes;
my ( $iapd2 ) = Net::DHCPv6::Option->from_bytes( $bytes );
ok( $iapd2->isa( 'Net::DHCPv6::Option::IAPD' ), 'parse IAPD class' );
is( $iapd2->iaid, 7,    'parse IAPD iaid' );
is( $iapd2->t1,   3600, 'parse IAPD t1' );
is( $iapd2->t2,   5400, 'parse IAPD t2' );

my $iaprefix2 = $iapd2->get_option( 26 );
ok( $iaprefix2->isa( 'Net::DHCPv6::Option::IAPrefix' ), 'parse IAPD IAPrefix sub-option' );
is( $iaprefix2->address,            '2001:db8::', 'parse IAPrefix address' );
is( $iaprefix2->address_raw,        $prefix_addr, 'parse IAPrefix address_raw' );
is( $iaprefix2->preferred_lifetime, 7200,         'parse IAPrefix preferred' );
is( $iaprefix2->valid_lifetime,     86_400,       'parse IAPrefix valid' );
is( $iaprefix2->prefix_length,      64,           'parse IAPrefix prefix_len' );

ok( dies { Net::DHCPv6::Option::IAPD->new }, 'IAPD dies without iaid' );
ok( dies { Net::DHCPv6::Option::IAPD::from_bytes_inner( undef, 25, pack( 'C*', ( 1 ) x 11 ) ) },
    'IAPD dies on data < 12 bytes' );

# type() on parsed options
is( $cid->type,  'CLIENTID', 'ClientId type from construction' );
is( $iana->type, 'IA_NA',    'IANA type from construction' );

# Multiple options with same code
$ol->add_option( $cid );
$ol->add_option( $cid );
my $all_opts  = $ol->options;
my $cid_count = scalar grep { $_->code == 1 } @{$all_opts};
is( $cid_count,                       3,       'three ClientId options in list' );
is( $ol->get_option( 1 )->duid->time, 123_456, 'get_option returns first' );

# OptionList trailing garbage
my $extra_opt = Net::DHCPv6::Option::Generic->new( code => 99, data => chr( 0 ) );
my $trailing  = $ol->as_bytes . $extra_opt->as_bytes . chr( 0x42 );
my ( $parsed_ol, $parse_err ) = Net::DHCPv6::OptionList->try_from_bytes( $trailing );
ok( defined $parsed_ol, 'trailing garbage returns OptionList' );
ok( defined $parse_err, 'trailing garbage returns error' );
like( $parse_err, qr/Trailing garbage/, 'error mentions trailing garbage' );

# OptionList non-X exception from option class stops parsing
{

    package Net::DHCPv6::Option::BadTest;
    use strictures 2;
    sub from_bytes_inner { die 'kaboom' }
}
my $saved_class = $Net::DHCPv6::OptionList::OPTION_CLASS{99};
$Net::DHCPv6::OptionList::OPTION_CLASS{99} = 'Net::DHCPv6::Option::BadTest';
my ( $bad_opt, $bad_err ) = Net::DHCPv6::OptionList->try_from_bytes( $extra_opt->as_bytes );
ok( defined $bad_opt, 'non-X exception returns OptionList' );
ok( defined $bad_err, 'non-X exception returns error' );
like( $bad_err, qr/Option 99 parse error/, 'error mentions parse error' );
$Net::DHCPv6::OptionList::OPTION_CLASS{99} = $saved_class;

## use critic (ValuesAndExpressions::ProhibitMagicNumbers)
done_testing;
