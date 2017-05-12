# $Id: 01-resolver-flags.t 1444 2016-01-05 10:01:10Z willem $  -*-perl-*-

use strict;
use Test::More tests => 23;

use Net::DNS;


my $res = Net::DNS::Resolver->new();
ok( $res->isa('Net::DNS::Resolver'), 'new() created object' );


ok( !$res->dnssec(), "default dnssec flag off" );
my $udpsize = $res->udppacketsize();

$res->dnssec(1);
ok( $res->dnssec(), "dnssec flag toggles on" );
my $size = $res->udppacketsize();
isnt( $size, $udpsize, "dnssec(1) sets udppacketsize ($size)" );

$res->dnssec(0);
ok( !$res->dnssec(), "dnssec flag toggles off" );


my @flag = qw(adflag cdflag force_v4 force_v6 prefer_v4 prefer_v6);
foreach my $flag (@flag) {
	my $default = $res->$flag();
	my $changed = $default ? 0 : 1;
	ok( defined $default, "default $flag $default" );
	$res->$flag($changed);
	is( $res->$flag(), $changed, "toggle $flag $changed" );
	$res->$flag($default);
	is( $res->$flag(), $default, "toggle $flag $default" );
}


exit;

