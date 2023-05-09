#!/usr/bin/perl
# $Id: 05-NSEC3PARAM.t 1910 2023-03-30 19:16:30Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More tests => 17;
use TestToolkit;

use Net::DNS;


my $name = 'example';
my $type = 'NSEC3PARAM';
my $code = 51;
my @attr = qw( algorithm flags iterations salt );
my @data = qw( 1 1 12 aabbccdd );
my @also = qw( hashalgo );

my $wire = '0101000c04aabbccdd';

my $typecode = unpack 'xn', Net::DNS::RR->new( type => $type )->encode;
is( $typecode, $code, "$type RR type code = $code" );

my $hash = {};
@{$hash}{@attr} = @data;


for my $rr ( Net::DNS::RR->new( name => $name, type => $type, %$hash ) ) {
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

	my $encoded = $rr->encode;
	my $decoded = Net::DNS::RR->decode( \$encoded );
	my $hex1    = unpack 'H*', $encoded;
	my $hex2    = unpack 'H*', $decoded->encode;
	my $hex3    = unpack 'H*', $rr->rdata;
	is( $hex2, $hex1, 'encode/decode transparent' );
	is( $hex3, $wire, 'encoded RDATA matches example' );
}


for my $rr ( Net::DNS::RR->new(". $type") ) {
	foreach (@attr) {
		ok( !$rr->$_(), "'$_' attribute of empty RR undefined" );
	}
}


for my $rr ( Net::DNS::RR->new(<<'END') ) {	## RR with null salt (RT#95034)
nosalt.example.	IN	NSEC3PARAM	2 0 12 -
END
	ok( $rr->string, 'NSEC3PARAM created' );
	is( unpack( 'H*', $rr->saltbin ), '', 'NSEC3PARAM null salt value' );
}


exception( 'NSEC3PARAM with corrupt salt', sub { Net::DNS::RR->new('corrupt NSEC3PARAM 2 0 12 aabbccfs') } );


exit;

