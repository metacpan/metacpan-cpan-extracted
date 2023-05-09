#!/usr/bin/perl
# $Id: 05-IPSECKEY.t 1911 2023-04-17 12:30:59Z willem $	-*-perl-*-
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

plan tests => 31;


my $name = '38.2.0.192.in-addr.arpa';
my $type = 'IPSECKEY';
my $code = 45;
my @attr = qw( precedence gatetype algorithm gateway key );
my @data = qw( 10 3 2 gateway.example.com AQNRU3mG7TVTO2BkR47usntb102uFJtugbo6BSGvgqt4AQ== );
my @also = qw( pubkey keybin );

my $wire =
'0a03020767617465776179076578616d706c6503636f6d00010351537986ed35533b6064478eeeb27b5bd74dae149b6e81ba3a0521af82ab7801';

my $typecode = unpack 'xn', Net::DNS::RR->new( type => $type )->encode;
is( $typecode, $code, "$type RR type code = $code" );

my $hash = {};
@{$hash}{@attr} = @data;


for my $rr ( Net::DNS::RR->new( name => $name, type => $type, %$hash ) ) {
	my $string = $rr->string;
	my $rr2	   = Net::DNS::RR->new($string);
	is( $rr2->string, $string,     'new/string transparent' );
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


for my $rr ( Net::DNS::RR->new("$name $type @data") ) {
	foreach ( undef, qw(192.0.2.38 2001:db8:0:8002:0:0:2000:1 gateway.example.com) ) {
		my $gateway = $_ || '.';
		$rr->gateway($gateway);
		is( scalar( $rr->gateway ), $_, "rr->gateway( '$gateway' )" );
		my $rr2 = Net::DNS::RR->new( $rr->string );
		is( $rr2->rdstring, $rr->rdstring, 'new/string transparent' );
		my $encoded = $rr->encode;
		my $decoded = Net::DNS::RR->decode( \$encoded );
		is( $decoded->rdstring, $rr->rdstring, 'encode/decode transparent' );
	}
}


for my $rr ( Net::DNS::RR->new(". $type") ) {
	foreach (@attr) {
		ok( !$rr->$_(), "$_ attribute of empty RR undefined" );
	}
}


exception( 'exception raised in decode', sub { Net::DNS::RR->new(". $type \\# 3 01ff05") } );

exception( 'exception raised in gateway', sub { Net::DNS::RR->new( type => $type )->gateway('X') } );


Net::DNS::RR->new("$name $type @data")->print;

exit;


