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
my $acct_flags    = TAC_PLUS_ACCT_FLAG_START;
my $authen_method = TAC_PLUS_AUTHEN_METH_RADIUS;
my $priv_lvl      = TAC_PLUS_PRIV_LVL_ROOT;
my $authen_type   = TAC_PLUS_AUTHEN_TYPE_PAP;
my $service       = TAC_PLUS_AUTHEN_SVC_ENABLE;
my $user          = 'user123';
my $port          = 'port123456';
my $rem_addr      = '1.2.3.4';
my @args          = qw{
	123
	456
	abcdef
	qwertyuiop
};


$pkt = Net::TacacsPlus::Packet::AccountRequestBody->new(
	'acct_flags'    => $acct_flags,
	'authen_method' => $authen_method,
	'authen_type'   => $authen_type,
	'service'       => $service,
	'user'          => $user,
	'port'          => $port,
	'rem_addr'      => $rem_addr,
	'args'          => \@args,
);

isa_ok($pkt, 'Net::TacacsPlus::Packet::AccountRequestBody');
#check methods
can_ok($pkt, qw{
	raw
	decode
});

#check properties
can_ok($pkt, qw{
	acct_flags
	authen_method
	priv_lvl
	authen_type
	service
	user
	port
	rem_addr
	args
});

my $raw = $pkt->raw;
is(length($raw),
	9
	+scalar(@args)
	+length($user)
	+length($port)
	+length($rem_addr)
	+length(join('', @args)),

	'check final length of packet body'
);

$pkt = undef;
$pkt = Net::TacacsPlus::Packet::AccountRequestBody->new(
	'raw_body' => $raw,
);

is($pkt->acct_flags, $acct_flags, 'check acct_flags');
is($pkt->authen_method, $authen_method, 'check authen_method');
is($pkt->authen_type, $authen_type, 'check authen_type');
is($pkt->service, $service, 'check service');
is($pkt->user, $user, 'check user');
is($pkt->port, $port, 'check port');
is($pkt->rem_addr, $rem_addr, 'check rem_addr');
is_deeply( $pkt->args, \@args, 'check args');
