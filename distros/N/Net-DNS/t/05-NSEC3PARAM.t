# $Id: 05-NSEC3PARAM.t 1362 2015-06-23 08:47:14Z willem $	-*-perl-*-

use strict;
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
	my $rr = new Net::DNS::RR(". $type");
	foreach (@attr) {
		ok( !$rr->$_(), "'$_' attribute of empty RR undefined" );
	}
}


{
	# check parsing of RR with null salt (RT#95034)
	my $string = 'nosalt.example.	IN	NSEC3PARAM	2 0 12 -';
	my $rr = eval { Net::DNS::RR->new($string) };
	diag $@ if $@;
	ok( $rr, 'NSEC3PARAM created with null salt' );
	is( $rr->salt, '', 'NSEC3PARAM null salt value' );
	is( unpack( 'H*', $rr->saltbin ), '', 'NSEC3PARAM null salt binary value' );
	is( $rr->string, $string, 'NSEC3PARAM null salt binary value' );
}


{
	my $rr = eval { Net::DNS::RR->new('corrupt.example NSEC3PARAM 2 0 12 aabbccfs') };
	ok( !$rr, 'NSEC3PARAM not created with corrupt hex data' );
}


exit;

