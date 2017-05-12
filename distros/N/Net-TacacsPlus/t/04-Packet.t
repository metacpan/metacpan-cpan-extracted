#!/usr/bin/perl

use strict;
use warnings;

use Test::More; # 'no_plan';
BEGIN { plan tests => 4 };

use English;

BEGIN {
	use_ok ( 'Net::TacacsPlus::Packet' ) or exit;
	use_ok ( 'Net::TacacsPlus::Constants' ) or exit;
}

my $pkt;

$pkt = Net::TacacsPlus::Packet->new(
	#header
	'type' => TAC_PLUS_AUTHEN,
	'seq_no' => 1,
	'flags' => 0,
	'session_id' => 123456,
	#start
	'action' => TAC_PLUS_AUTHEN_LOGIN,
	'authen_type' => TAC_PLUS_AUTHEN_TYPE_PAP,
	'key' => 'topsecret',
);

isa_ok($pkt, 'Net::TacacsPlus::Packet');
can_ok($pkt, qw{
	check_reply
	decode_raw
	raw
	raw_xor_body
	compute_pseudo_pad
	send
	type
});
