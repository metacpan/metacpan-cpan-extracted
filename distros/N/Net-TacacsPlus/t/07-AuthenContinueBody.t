#!/usr/bin/perl

use strict;
use warnings;

use Test::More; # 'no_plan';
BEGIN { plan tests => 9 };

use English;

BEGIN {
	use_ok ( 'Net::TacacsPlus::Packet' ) or exit;
	use_ok ( 'Net::TacacsPlus::Constants' ) or exit;
}

my $pkt;
my $continue_flags = 12;
my $user_msg       = 'my '.chr(10).' message';
my $data           = 'your '.chr(1).' data';

$pkt = Net::TacacsPlus::Packet::AuthenContinueBody->new(
	'continue_flags' => $continue_flags,
	'user_msg'       => $user_msg,
	'data'           => $data,
);

isa_ok($pkt, 'Net::TacacsPlus::Packet::AuthenContinueBody');
#check methods
can_ok($pkt, qw{
	raw
	decode
});

#check properties
can_ok($pkt, qw{
	continue_flags
	user_msg
	data
});

my $raw = $pkt->raw;
is(length($raw),
	2+2+1
	+length($user_msg)
	+length($data)
	,
	'check final length of packet body'
);

$pkt = undef;
$pkt = Net::TacacsPlus::Packet::AuthenContinueBody->new(
	'raw_body' => $raw,
);

is($pkt->continue_flags, $continue_flags, 'check continue_flags');
is($pkt->user_msg, $user_msg, 'check user message');
is($pkt->data, $data, 'check data');
