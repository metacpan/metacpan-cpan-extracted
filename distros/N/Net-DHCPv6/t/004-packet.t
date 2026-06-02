#!/usr/bin/env perl
## no critic (ValuesAndExpressions::ProhibitMagicNumbers)
use strictures 2;
use Test2::V1 -ipP, qw(is ok done_testing);    ## no critic (Subroutines::ProhibitCallsToUndeclaredSubs)

use lib 't/lib';
use lib 'lib';

use Net::DHCPv6::Packet;
use Net::DHCPv6::Message::Solicit;
use Net::DHCPv6::Message::Advertise;
use Net::DHCPv6::Message::Request;
use Net::DHCPv6::Message::Confirm;
use Net::DHCPv6::Message::Renew;
use Net::DHCPv6::Message::Rebind;
use Net::DHCPv6::Message::Reply;
use Net::DHCPv6::Message::Release;
use Net::DHCPv6::Message::Decline;
use Net::DHCPv6::Message::Reconfigure;
use Net::DHCPv6::Message::InformationRequest;
use Net::DHCPv6::Message::RelayForw;
use Net::DHCPv6::Message::RelayReply;
use Net::DHCPv6::DUID;
use Net::DHCPv6::Option::ClientId;
use Net::DHCPv6::Option::ServerId;
use Net::DHCPv6::Option::ORO;
use Net::DHCPv6::Option::IANA;
use Net::DHCPv6::Option::IAAddr;
use Net::DHCPv6::Constants;
use Test::Net::DHCPv6       qw(hex2bytes);
use Test2::Tools::Exception qw( dies );

# Solicit construction
my $duid    = Net::DHCPv6::DUID->new_llt( $LINK_TYPE_ETHERNET, 123_456, pack( 'H*', '001122334455' ) );
my $cid     = Net::DHCPv6::Option::ClientId->new( duid           => $duid );
my $solicit = Net::DHCPv6::Message::Solicit->new( transaction_id => 123_456 );
$solicit->add_option( $cid );

is( $solicit->msg_type,       1,         'Solicit msg_type' );
is( $solicit->type,           'SOLICIT', 'Solicit type()' );
is( $solicit->transaction_id, 123_456,   'Solicit transaction_id' );

# Advertise
my $sid = Net::DHCPv6::Option::ServerId->new(
    duid => Net::DHCPv6::DUID->new_llt( $LINK_TYPE_ETHERNET, 999_999, pack( 'H*', 'aabbccddeeff' ) ) );
my $adv = Net::DHCPv6::Message::Advertise->new( transaction_id => 456_789 );
$adv->add_option( $sid );
is( $adv->msg_type, 2, 'Advertise msg_type' );

# Request with ORO
my $oro = Net::DHCPv6::Option::ORO->new( requested_options => [ 23, 24 ] );
my $req = Net::DHCPv6::Message::Request->new( transaction_id => 789_012 );
$req->add_option( $cid );
$req->add_option( $sid );
$req->add_option( $oro );
is( $req->msg_type, 3, 'Request msg_type' );

# Confirm
my $con = Net::DHCPv6::Message::Confirm->new( transaction_id => 333_333 );
is( $con->msg_type, 4,         'Confirm msg_type' );
is( $con->type,     'CONFIRM', 'Confirm type()' );

# Renew
my $ren = Net::DHCPv6::Message::Renew->new( transaction_id => 111_111 );
is( $ren->msg_type, 5, 'Renew msg_type' );

# Rebind
my $reb = Net::DHCPv6::Message::Rebind->new( transaction_id => 444_444 );
is( $reb->msg_type, 6,        'Rebind msg_type' );
is( $reb->type,     'REBIND', 'Rebind type()' );

# Reply with IA_NA + IAAddr
my $iana   = Net::DHCPv6::Option::IANA->new( iaid => 42, t1 => 3600, t2 => 5400 );
my $addr   = pack( 'H*', '20010db8000000000000000000000001' );
my $iaaddr = Net::DHCPv6::Option::IAAddr->new(
    address            => $addr,
    preferred_lifetime => 7200,
    valid_lifetime     => 86_400,
);
$iana->add_option( $iaaddr );
my $reply = Net::DHCPv6::Message::Reply->new( transaction_id => 314_159 );
$reply->add_option( $iana );
is( $reply->msg_type,              7,  'Reply msg_type' );
is( $reply->get_option( 3 )->iaid, 42, 'Reply IA_NA iaid' );

# Release
my $rel = Net::DHCPv6::Message::Release->new( transaction_id => 222_222 );
is( $rel->msg_type, 8, 'Release msg_type' );

# Decline
my $dec = Net::DHCPv6::Message::Decline->new( transaction_id => 555_555 );
is( $dec->msg_type, 9,         'Decline msg_type' );
is( $dec->type,     'DECLINE', 'Decline type()' );

# Reconfigure
my $rec = Net::DHCPv6::Message::Reconfigure->new( transaction_id => 666_666 );
is( $rec->msg_type, 10,            'Reconfigure msg_type' );
is( $rec->type,     'RECONFIGURE', 'Reconfigure type()' );

# InformationRequest
my $inf = Net::DHCPv6::Message::InformationRequest->new( transaction_id => 777_777 );
is( $inf->msg_type, 11,                    'InformationRequest msg_type' );
is( $inf->type,     'INFORMATION_REQUEST', 'InformationRequest type()' );

# RelayForw
my $link_addr_raw = pack( 'H*', '20010db8000000000000000000000001' );
my $peer_addr_raw = pack( 'H*', '20010db8000000000000000000000002' );
my $relay_forw    = Net::DHCPv6::Message::RelayForw->new(
    hop_count    => 0,
    link_address => '2001:db8::1',
    peer_address => '2001:db8::2',
);
$relay_forw->add_option( $cid );
is( $relay_forw->msg_type,         12,             'RelayForw msg_type' );
is( $relay_forw->type,             'RELAY_FORW',   'RelayForw type()' );
is( $relay_forw->hop_count,        0,              'RelayForw hop_count' );
is( $relay_forw->link_address,     '2001:db8::1',  'RelayForw link_address' );
is( $relay_forw->link_address_raw, $link_addr_raw, 'RelayForw link_address_raw' );
is( $relay_forw->peer_address,     '2001:db8::2',  'RelayForw peer_address' );
is( $relay_forw->peer_address_raw, $peer_addr_raw, 'RelayForw peer_address_raw' );
ok( $relay_forw->get_option( 1 )->isa( 'Net::DHCPv6::Option::ClientId' ), 'RelayForw has ClientId' );

# RelayReply
my $relay_reply = Net::DHCPv6::Message::RelayReply->new(
    hop_count    => 1,
    link_address => '2001:db8::2',
    peer_address => '2001:db8::1',
);
$relay_reply->add_option( $sid );
is( $relay_reply->msg_type,         13,             'RelayReply msg_type' );
is( $relay_reply->type,             'RELAY_REPLY',  'RelayReply type()' );
is( $relay_reply->hop_count,        1,              'RelayReply hop_count' );
is( $relay_reply->link_address,     '2001:db8::2',  'RelayReply link_address' );
is( $relay_reply->link_address_raw, $peer_addr_raw, 'RelayReply link_address_raw' );
is( $relay_reply->peer_address,     '2001:db8::1',  'RelayReply peer_address' );
is( $relay_reply->peer_address_raw, $link_addr_raw, 'RelayReply peer_address_raw' );

# Round-trip: Solicit
my $bytes   = $solicit->as_bytes;
my $decoded = Net::DHCPv6::Packet->from_bytes( $bytes );
ok( $decoded->isa( 'Net::DHCPv6::Message::Solicit' ), 'Solicit class preserved' );
is( $decoded->transaction_id,              123_456, 'Solicit tid round-trip' );
is( $decoded->get_option( 1 )->duid->time, 123_456, 'Solicit ClientId preserved' );

# Round-trip: Advertise
$bytes   = $adv->as_bytes;
$decoded = Net::DHCPv6::Packet->from_bytes( $bytes );
ok( $decoded->isa( 'Net::DHCPv6::Message::Advertise' ), 'Advertise class preserved' );
is( $decoded->transaction_id, 456_789, 'Advertise tid round-trip' );

# Round-trip: Request
$bytes   = $req->as_bytes;
$decoded = Net::DHCPv6::Packet->from_bytes( $bytes );
ok( $decoded->isa( 'Net::DHCPv6::Message::Request' ), 'Request class preserved' );
is( $decoded->get_option( 6 )->requested_options->[1], 24, 'Request ORO preserved' );

# Round-trip: Reply
$bytes   = $reply->as_bytes;
$decoded = Net::DHCPv6::Packet->from_bytes( $bytes );
ok( $decoded->isa( 'Net::DHCPv6::Message::Reply' ), 'Reply class preserved' );
my $d_iana = $decoded->get_option( 3 );
is( $d_iana->iaid, 42, 'Reply IA_NA iaid round-trip' );
my $d_iaaddr = $d_iana->get_option( 5 );
is( $d_iaaddr->address,            '2001:db8::1', 'Reply IAAddr address round-trip' );
is( $d_iaaddr->address_raw,        $addr,         'Reply IAAddr address_raw round-trip' );
is( $d_iaaddr->preferred_lifetime, 7200,          'Reply IAAddr preferred round-trip' );

# Confirm round-trip
$bytes   = $con->as_bytes;
$decoded = Net::DHCPv6::Packet->from_bytes( $bytes );
ok( $decoded->isa( 'Net::DHCPv6::Message::Confirm' ), 'Confirm class preserved' );
is( $decoded->transaction_id, 333_333, 'Confirm tid round-trip' );

# Rebind round-trip
$bytes   = $reb->as_bytes;
$decoded = Net::DHCPv6::Packet->from_bytes( $bytes );
ok( $decoded->isa( 'Net::DHCPv6::Message::Rebind' ), 'Rebind class preserved' );
is( $decoded->transaction_id, 444_444, 'Rebind tid round-trip' );

# Decline round-trip
$bytes   = $dec->as_bytes;
$decoded = Net::DHCPv6::Packet->from_bytes( $bytes );
ok( $decoded->isa( 'Net::DHCPv6::Message::Decline' ), 'Decline class preserved' );
is( $decoded->transaction_id, 555_555, 'Decline tid round-trip' );

# Reconfigure round-trip
$bytes   = $rec->as_bytes;
$decoded = Net::DHCPv6::Packet->from_bytes( $bytes );
ok( $decoded->isa( 'Net::DHCPv6::Message::Reconfigure' ), 'Reconfigure class preserved' );
is( $decoded->transaction_id, 666_666, 'Reconfigure tid round-trip' );

# InformationRequest round-trip
$bytes   = $inf->as_bytes;
$decoded = Net::DHCPv6::Packet->from_bytes( $bytes );
ok( $decoded->isa( 'Net::DHCPv6::Message::InformationRequest' ), 'InformationRequest class preserved' );
is( $decoded->transaction_id, 777_777, 'InformationRequest tid round-trip' );

# RelayForw round-trip
$bytes   = $relay_forw->as_bytes;
$decoded = Net::DHCPv6::Packet->from_bytes( $bytes );
ok( $decoded->isa( 'Net::DHCPv6::Message::RelayForw' ), 'RelayForw class preserved' );
is( $decoded->hop_count,        0,              'RelayForw hop_count round-trip' );
is( $decoded->link_address,     '2001:db8::1',  'RelayForw link_address round-trip' );
is( $decoded->link_address_raw, $link_addr_raw, 'RelayForw link_address_raw round-trip' );
is( $decoded->peer_address,     '2001:db8::2',  'RelayForw peer_address round-trip' );
is( $decoded->peer_address_raw, $peer_addr_raw, 'RelayForw peer_address_raw round-trip' );
ok( $decoded->get_option( 1 )->isa( 'Net::DHCPv6::Option::ClientId' ), 'RelayForw ClientId round-trip' );
ok( !defined( $decoded->transaction_id ),                              'RelayForw has no transaction_id' );

# RelayReply round-trip
$bytes   = $relay_reply->as_bytes;
$decoded = Net::DHCPv6::Packet->from_bytes( $bytes );
ok( $decoded->isa( 'Net::DHCPv6::Message::RelayReply' ), 'RelayReply class preserved' );
is( $decoded->hop_count,        1,              'RelayReply hop_count round-trip' );
is( $decoded->link_address,     '2001:db8::2',  'RelayReply link_address round-trip' );
is( $decoded->link_address_raw, $peer_addr_raw, 'RelayReply link_address_raw round-trip' );
is( $decoded->peer_address,     '2001:db8::1',  'RelayReply peer_address round-trip' );
is( $decoded->peer_address_raw, $link_addr_raw, 'RelayReply peer_address_raw round-trip' );
ok( $decoded->get_option( 2 )->isa( 'Net::DHCPv6::Option::ServerId' ), 'RelayReply ServerId round-trip' );

# Unknown message type defaults to Packet
my $unknown_hex = 'ff 111111';
$bytes   = hex2bytes( $unknown_hex );
$decoded = Net::DHCPv6::Packet->from_bytes( $bytes );
is( $decoded->msg_type, 255, 'Unknown msg_type preserved' );
ok( !$decoded->isa( 'Net::DHCPv6::Message::Solicit' ), 'Unknown msg_type not subclassed' );

# msg_type_name alias
is( $solicit->msg_type_name,    'SOLICIT',    'msg_type_name Solicit' );
is( $relay_forw->msg_type_name, 'RELAY_FORW', 'msg_type_name RelayForw' );

# Relay truncation error
ok( dies { Net::DHCPv6::Packet->from_bytes( hex2bytes( '0c 00 20010db8000000000000000000000001 20010db80000' ) ) },
    'relay from_bytes with < 34 bytes dies' );
ok( dies { Net::DHCPv6::Packet->from_bytes( hex2bytes( '0d 00 20010db8000000000000000000000001 20010db80000' ) ) },
    'relay-reply from_bytes with < 34 bytes dies' );

## use critic (ValuesAndExpressions::ProhibitMagicNumbers)
done_testing;
