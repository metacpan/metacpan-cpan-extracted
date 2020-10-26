#!/usr/bin/perl
# $Id: 05-MX.t 1815 2020-10-14 21:55:18Z willem $	-*-perl-*-
#

use strict;
use warnings;
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
	my $typecode = unpack 'xn', Net::DNS::RR->new(". $type")->encode;
	is( $typecode, $code, "$type RR type code = $code" );

	my $hash = {};
	@{$hash}{@attr} = @data;

	my $rr = Net::DNS::RR->new(
		name => $name,
		type => $type,
		%$hash
		);

	my $string = $rr->string;
	my $rr2	   = Net::DNS::RR->new($string);
	is( $rr2->string, $string, 'new/string transparent' );

	is( $rr2->encode, $rr->encode, 'new($string) and new(%hash) equivalent' );

	foreach (@attr) {
		is( $rr->$_, $hash->{$_}, "expected result from rr->$_()" );
	}

	foreach (@also) {
		is( $rr2->$_, $rr->$_, "additional attribute rr->$_()" );
	}


	my $null    = Net::DNS::RR->new("$name NULL")->encode;
	my $empty   = Net::DNS::RR->new("$name $type")->encode;
	my $rxbin   = Net::DNS::RR->decode( \$empty )->encode;
	my $txtext  = Net::DNS::RR->new("$name $type")->string;
	my $rxtext  = Net::DNS::RR->new($txtext)->encode;
	my $encoded = $rr->encode;
	my $decoded = Net::DNS::RR->decode( \$encoded );
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
	my $lc		= Net::DNS::RR->new( lc ". $type @data" );
	my $rr		= Net::DNS::RR->new( uc ". $type @data" );
	my $hash	= {};
	my $predecessor = $rr->encode( 0,		    $hash );
	my $compressed	= $rr->encode( length $predecessor, $hash );
	ok( length $compressed < length $predecessor, 'encoded RDATA compressible' );
	isnt( $rr->encode, $lc->encode, 'encoded RDATA names not downcased' );
	is( $rr->canonical, $lc->encode, 'canonical RDATA names downcased' );
}


{					## incomplete RR (specimen test for widely used constructs)
	my $empty = Net::DNS::RR->new( type => $type );
	is( $empty->preference, 0,     'unspecified integer returns 0 (not default value)' );
	is( $empty->exchange,	undef, 'unspecified domain name returns undefined' );

	my $part = Net::DNS::RR->new( type => $type, exchange => 'mx.example' );
	is( $part->preference, 10, 'unspecified integer returns default value' );
	ok( $part->exchange, 'domain name defined as expected' );
	is( $part->preference(0), 0, 'zero integer replaces default value' );
}


exit;

