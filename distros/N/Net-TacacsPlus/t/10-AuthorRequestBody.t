#!/usr/bin/perl

use strict;
use warnings;

use Test::More; # 'no_plan';
BEGIN { plan tests => 14 };

use Test::Differences;
use English;

BEGIN {
	use_ok ( 'Net::TacacsPlus::Packet' ) or exit;
	use_ok ( 'Net::TacacsPlus::Constants' ) or exit;
}

my $pkt            = 9;
my $authen_method  = 8;
my $priv_lvl       = 7;
my $authen_type    = 6;
my $authen_service = 5;
my $user           = 'you';
my $port           = 'our port';
my $rem_addr       = '1.2.3.4';
my @args           = (
	'123456',
	'abcdefgh',
	'zxcvbnm'
);

$pkt = Net::TacacsPlus::Packet::AuthorRequestBody->new(
	'authen_method'  => $authen_method,
	'priv_lvl'       => $priv_lvl,
	'authen_type'    => $authen_type,
	'authen_service' => $authen_service,
	'user'           => $user,
	'port'           => $port,
	'rem_addr'       => $rem_addr,
	'args'           => \@args,
);

isa_ok($pkt, 'Net::TacacsPlus::Packet::AuthorRequestBody');
#check methods
can_ok($pkt, qw{
	raw
	decode
});

#check properties
can_ok($pkt, qw{
	authen_method
	priv_lvl
	authen_type
	authen_service
	user
	port
	rem_addr
	args
});

my $raw = $pkt->raw;
is(length($raw),
	8
	+scalar(@args)
	+length($user)
	+length($port)
	+length($rem_addr)
	+length(join('', @args))
	,
	'check final length of packet body'
);

$pkt = undef;
$pkt = Net::TacacsPlus::Packet::AuthorRequestBody->new(
	'raw_body' => $raw,
);

is($pkt->authen_method, $authen_method, 'check authen_method');
is($pkt->priv_lvl, $priv_lvl, 'check priv_lvl');
is($pkt->authen_type, $authen_type, 'check authen_type');
is($pkt->authen_service, $authen_service, 'check authen_service');
is($pkt->user, $user, 'check user');
is($pkt->port, $port, 'check port');
is($pkt->rem_addr, $rem_addr, 'check rem_addr');
eq_or_diff($pkt->args, \@args, 'check args');
