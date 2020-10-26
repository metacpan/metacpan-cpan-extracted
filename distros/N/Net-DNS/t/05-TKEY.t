#!/usr/bin/perl
# $Id: 05-TKEY.t 1815 2020-10-14 21:55:18Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More tests => 24;

use Net::DNS;


my $name = 'TKEY.example';
my $type = 'TKEY';
my $code = 249;
my @attr = qw( algorithm inception expiration mode error key other );
my $fake = pack 'H*', '64756d6d79';
my @data = ( qw( alg.example 1434806118 1434806118 1 17 ), $fake, $fake );
my @also = qw( other_data );

my $wire = '03616c67076578616d706c6500558567665585676600010011000564756d6d79000564756d6d79';


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

	my @wire = unpack 'C*', $encoded;
	$wire[length($empty) - 1]--;
	my $wireformat = pack 'C*', @wire;
	eval { Net::DNS::RR->decode( \$wireformat ); };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "corrupt wire-format\t[$exception]" );
}


{
	my $rr = Net::DNS::RR->new(". $type");
	foreach (@attr) {
		ok( !$rr->$_(), "'$_' attribute of empty RR undefined" );
	}
}


exit;

