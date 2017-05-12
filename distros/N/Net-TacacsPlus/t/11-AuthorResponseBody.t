#!/usr/bin/perl

use strict;
use warnings;

use Test::More 'no_plan';
#BEGIN { plan tests => 14 };

use Test::Differences;
use English;

BEGIN {
	use_ok ( 'Net::TacacsPlus::Packet' ) or exit;
	use_ok ( 'Net::TacacsPlus::Constants' ) or exit;
}

my $pkt;
my $status     = 123;
my $server_msg = 'ha ha ha';
my $data       = 'pypypy';
my @args           = (
	'123456',
	'abcdefgh',
	'zxcvbnm'
);

$pkt = Net::TacacsPlus::Packet::AuthorResponseBody->new(
	'status'     => $status,
	'server_msg' => $server_msg,
	'data'       => $data,
	'args'       => \@args,
);

isa_ok($pkt, 'Net::TacacsPlus::Packet::AuthorResponseBody');
#check methods
can_ok($pkt, qw{
	raw
	decode
});

#check properties
can_ok($pkt, qw{
	status
	server_msg
	data
	args
});

my $raw = $pkt->raw;
is(length($raw),
	1+1+2+2+scalar(@args)
	+length($server_msg)
	+length($data)
	+length(join('', @args))
	,
	'check final length of packet body'
);

$pkt = undef;
$pkt = Net::TacacsPlus::Packet::AuthorResponseBody->new(
	'raw_body' => $raw,
);

is($pkt->status, $status, 'check status');
is($pkt->server_msg, $server_msg, 'check server_msg');
is($pkt->data, $data, 'check data');
eq_or_diff($pkt->args, \@args, 'check args');
