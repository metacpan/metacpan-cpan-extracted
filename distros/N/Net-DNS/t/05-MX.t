# $Id: 05-MX.t 1354 2015-06-05 08:20:53Z willem $	-*-perl-*-

use strict;
use Test::More tests => 18;


use Net::DNS;


my $name = 'MX.example';
my $type = 'MX';
my $code = 15;
my @attr = qw( preference exchange );
my @data = qw( 10 mx.example.com );
my @also = qw( );

my $wire = '000a026d78076578616d706c6503636f6d00';


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
		is( $rr->$_, $hash->{$_}, "expected result from rr->$_()" );
	}

	foreach (@also) {
		is( $rr2->$_, $rr->$_, "additional attribute rr->$_()" );
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


{
	my $lc		= new Net::DNS::RR( lc ". $type @data" );
	my $rr		= new Net::DNS::RR( uc ". $type @data" );
	my $hash	= {};
	my $predecessor = $rr->encode( 0, $hash );
	my $compressed	= $rr->encode( length $predecessor, $hash );
	ok( length $compressed < length $predecessor, 'encoded RDATA compressible' );
	isnt( $rr->encode, $lc->encode, 'encoded RDATA names not downcased' );
	is( $rr->canonical, $lc->encode, 'canonical RDATA names downcased' );
}


{					## incomplete RR (specimen test for widely used constructs)
	my $empty = new Net::DNS::RR( type => $type );
	is( $empty->preference, 0,     'unspecified integer returns 0 (not default value)' );
	is( $empty->exchange,	undef, 'unspecified domain name returns undefined' );

	my $part = new Net::DNS::RR( type => $type, exchange => 'mx.example' );
	is( $part->preference, 10, 'unspecified integer returns default value' );
	ok( $part->exchange, 'domain name defined as expected' );
	is( $part->preference(0), 0, 'zero integer replaces default value' );
}


exit;

