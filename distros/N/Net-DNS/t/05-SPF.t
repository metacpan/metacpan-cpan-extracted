# $Id: 05-SPF.t 1362 2015-06-23 08:47:14Z willem $	-*-perl-*-

use strict;
use Test::More tests => 10;


use Net::DNS;


my $name = 'SPF.example';
my $type = 'SPF';
my $code = 99;
my @attr = qw( spfdata );
my @data = ('v=spf1 +mx a:colo.example.com/28 -all');
my @also = qw( txtdata );

my $wire = '25763d73706631202b6d7820613a636f6c6f2e6578616d706c652e636f6d2f3238202d616c6c';


{
	my $typecode = unpack 'xn', new Net::DNS::RR(". $type")->encode;
	is( $typecode, $code, "$type RR type code = $code" );

	my $hash = {};
	@{$hash}{@attr} = @data;

	my $rr = new Net::DNS::RR(
		name => $name,
		type => $type,
		%$hash
		);

	my $string = $rr->string;
	my $rr2	   = new Net::DNS::RR($string);
	is( $rr2->string, $string, 'new/string transparent' );

	is( $rr2->encode, $rr->encode, 'new($string) and new(%hash) equivalent' );

	foreach (@attr) {
		my $r1 = join '', $rr->$_;
		is( $r1, $hash->{$_}, "expected result from rr->$_()" );
	}

	foreach (@also) {
		my $r1 = join '', $rr->$_;
		my $r2 = join '', $rr2->$_;
		is( $r2, $r1, "additional attribute rr->$_()" );
	}


	my $null    = new Net::DNS::RR("$name NULL")->encode;
	my $empty   = new Net::DNS::RR("$name $type")->encode;
	my $rxbin   = decode Net::DNS::RR( \$empty )->encode;
	my $txtext  = new Net::DNS::RR("$name $type")->string;
	my $rxtext  = new Net::DNS::RR($txtext)->encode;
	my $encoded = $rr->encode;
	my $decoded = decode Net::DNS::RR( \$encoded );
	my $hex1    = unpack 'H*', $encoded;
	my $hex2    = unpack 'H*', $decoded->encode;
	my $hex3    = unpack 'H*', substr( $encoded, length $null );
	is( $hex2,	     $hex1,	    'encode/decode transparent' );
	is( $hex3,	     $wire,	    'encoded RDATA matches example' );
	is( length($empty),  length($null), 'encoded RDATA can be empty' );
	is( length($rxbin),  length($null), 'decoded RDATA can be empty' );
	is( length($rxtext), length($null), 'string RDATA can be empty' );
}


exit;

