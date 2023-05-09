#!/usr/bin/perl
# $Id: 05-CERT.t 1910 2023-03-30 19:16:30Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More;
use TestToolkit;

use Net::DNS;

my @prerequisite = qw(
		MIME::Base64
		);

foreach my $package (@prerequisite) {
	next if eval "require $package";	## no critic
	plan skip_all => "$package not installed";
	exit;
}

plan tests => 21;


my $name = 'CERT.example';
my $type = 'CERT';
my $code = 37;
my @attr = qw( certtype keytag algorithm cert );
my @data = qw( 1 2 3 MTIzNDU2Nzg5YWJjZGVmZ2hpamtsbW5vcHFyc3R1dnd4eXo= );
my @also = qw( certificate format tag );

my $wire = '00010002033132333435363738396162636465666768696a6b6c6d6e6f707172737475767778797a';

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
		next if /certificate/;
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


for my $rr ( Net::DNS::RR->new('foo IN CERT 1 2 3 foo=') ) {
	is( $rr->algorithm('MNEMONIC'), 'DSA', 'algorithm mnemonic' );
	$rr->algorithm(255);
	is( $rr->algorithm('MNEMONIC'), 255, 'algorithm with no mnemonic' );
	exception( 'unknown algorithm mnemonic', sub { $rr->algorithm('X') } );

	noexception( 'valid certtype mnemonic', sub { $rr->certtype('PKIX') } );
	exception( 'unknown certtype mnemonic', sub { $rr->certtype('X') } );
}


is( Net::DNS::RR->new('foo IN CERT 0 2 3 foo=')->certtype,  0,	'certtype may be zero' );
is( Net::DNS::RR->new('foo IN CERT 1 0 3 foo=')->keytag,    0,	'keytag may be zero' );
is( Net::DNS::RR->new('foo IN CERT 1 2 0 foo=')->algorithm, 0,	'algorithm may be zero' );
is( Net::DNS::RR->new('foo IN CERT 1 2 3 ""  ')->cert,	    "", 'cert may be empty' );


exit;

