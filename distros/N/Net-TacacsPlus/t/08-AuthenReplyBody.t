#!/usr/bin/perl

use strict;
use warnings;

use Test::More; # 'no_plan';
BEGIN { plan tests => 10 };

use English;

BEGIN {
	use_ok ( 'Net::TacacsPlus::Packet' ) or exit;
	use_ok ( 'Net::TacacsPlus::Constants' ) or exit;
}

my $pkt;
my $flags       = 12;
my $status      = 21;
my $server_msg  = 'my server '.chr(10).' message';
my $data        = 'your server '.chr(1).' data';

$pkt = Net::TacacsPlus::Packet::AuthenReplyBody->new(
	'status'     => $status,
	'flags'      => $flags,
	'server_msg' => $server_msg,
	'data'       => $data,
);

isa_ok($pkt, 'Net::TacacsPlus::Packet::AuthenReplyBody');
#check methods
can_ok($pkt, qw{
	raw
	decode
});

#check properties
can_ok($pkt, qw{
	status
	flags
	server_msg
	data
});

my $raw = $pkt->raw;
is(length($raw),
	1+1+2+2
	+length($server_msg)
	+length($data)
	,
	'check final length of packet body'
);

$pkt = undef;
$pkt = Net::TacacsPlus::Packet::AuthenReplyBody->new(
	'raw_body' => $raw,
);

is($pkt->status, $status, 'check cstatus');
is($pkt->flags, $flags, 'check flags');
is($pkt->server_msg, $server_msg, 'check server_msg');
is($pkt->data, $data, 'check data');
