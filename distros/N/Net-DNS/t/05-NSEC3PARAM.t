#!/usr/bin/perl
# $Id: 05-NSEC3PARAM.t 1815 2020-10-14 21:55:18Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More tests => 22;

use Net::DNS;


my $name = 'example';
my $type = 'NSEC3PARAM';
my $code = 51;
my @attr = qw( algorithm flags iterations salt );
my @data = qw( 1 1 12 aabbccdd );
my @also = qw( hashalgo );

my $wire = '0101000c04aabbccdd';


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
	my $rr = Net::DNS::RR->new(". $type");
	foreach (@attr) {
		ok( !$rr->$_(), "'$_' attribute of empty RR undefined" );
	}
}


{
	# check parsing of RR with null salt (RT#95034)
	my $string = 'nosalt.example.	IN	NSEC3PARAM	2 0 12 -';
	my $rr	   = eval { Net::DNS::RR->new($string) };
	diag $@ if $@;
	ok( $rr, 'NSEC3PARAM created with null salt' );
	is( $rr->salt,			  '',	   'NSEC3PARAM null salt value' );
	is( unpack( 'H*', $rr->saltbin ), '',	   'NSEC3PARAM null salt binary value' );
	is( $rr->string,		  $string, 'NSEC3PARAM null salt binary value' );
}


{
	my $rr = eval { Net::DNS::RR->new('corrupt.example NSEC3PARAM 2 0 12 aabbccfs') };
	ok( !$rr, 'NSEC3PARAM not created with corrupt hex data' );
}


exit;

