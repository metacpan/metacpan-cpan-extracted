#!/usr/bin/perl

use strict;
use warnings;

use Test::More; # 'no_plan';
BEGIN { plan tests => 8 };

use English;

BEGIN {
	use_ok ( 'Net::TacacsPlus::Packet' ) or exit;
	use_ok ( 'Net::TacacsPlus::Constants' ) or exit;
}

my $pkt;
my $server_msg = 'mess'.chr(1).chr(2).'age';
my $data       = 'da'.chr(3).chr(4).'ta';

$pkt = Net::TacacsPlus::Packet::AccountReplyBody->new(
	'status'     => 100,
	'server_msg' => $server_msg,
	'data'       => $data,
);

isa_ok($pkt, 'Net::TacacsPlus::Packet::AccountReplyBody');
can_ok($pkt, qw{
	raw
	decode
});

my $raw = $pkt->raw;
is(length($raw), 2+2+1+length($server_msg)+length($data), 'check final length of packet body');

$pkt = undef;
$pkt = Net::TacacsPlus::Packet::AccountReplyBody->new(
	'raw_body' => $raw,
);

is($pkt->status, 100, 'check status');
is($pkt->server_msg, $server_msg, 'check server_msg');
is($pkt->data, $data, 'check data');

