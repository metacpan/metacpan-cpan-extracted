#!/usr/bin/perl

use strict;
use warnings;

use Test::More; # 'no_plan';
BEGIN { plan tests => 14 };

use English;

BEGIN {
	use_ok ( 'Net::TacacsPlus::Packet' ) or exit;
	use_ok ( 'Net::TacacsPlus::Constants' ) or exit;
}

my $pkt;
my $action      = 1;
my $priv_lvl    = 2;
my $authen_type = 3;
my $service     = 4;
my $user        = 'you';
my $data        = 'topsecret';
my $port        = 'server port';
my $rem_addr    = '1.2.3.4';

$pkt = Net::TacacsPlus::Packet::AuthenStartBody->new(
	'action'      => $action,
	'priv_lvl'    => $priv_lvl,
	'authen_type' => $authen_type,
	'service'     => $service,
	'user'        => $user,
	'data'        => $data,
	'port'        => $port,
	'rem_addr'    => $rem_addr,
);

isa_ok($pkt, 'Net::TacacsPlus::Packet::AuthenStartBody');
#check methods
can_ok($pkt, qw{
	raw
	decode
});

#check properties
can_ok($pkt, qw{
	action
	priv_lvl
	authen_type
	service
	user
	data
	port
	rem_addr
});

my $raw = $pkt->raw;
is(length($raw),
	8
	+length($user)
	+length($port)
	+length($rem_addr)
	+length($data)
	,
	'check final length of packet body'
);

$pkt = undef;
$pkt = Net::TacacsPlus::Packet::AuthenStartBody->new(
	'raw_body' => $raw,
);

is($pkt->action, $action, 'check action');
is($pkt->priv_lvl, $priv_lvl, 'check priv_lvl');
is($pkt->authen_type, $authen_type, 'check authen_type');
is($pkt->service, $service, 'check service');
is($pkt->user, $user, 'check user');
is($pkt->data, $data, 'check data');
is($pkt->port, $port, 'check port');
is($pkt->rem_addr, $rem_addr, 'check rem_addr');
