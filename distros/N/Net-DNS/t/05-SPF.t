#!/usr/bin/perl
# $Id: 05-SPF.t 1910 2023-03-30 19:16:30Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More tests => 7;

use Net::DNS;


my $name = 'SPF.example';
my $type = 'SPF';
my $code = 99;
my @attr = qw( spfdata );
my @data = ('v=spf1 +mx a:colo.example.com/28 -all');
my @also = qw( txtdata );

my $wire = '25763d73706631202b6d7820613a636f6c6f2e6578616d706c652e636f6d2f3238202d616c6c';

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
		my $r1 = join '', $rr->$_;
		is( $r1, $hash->{$_}, "expected result from rr->$_()" );
	}

	foreach (@also) {
		my $r1 = join '', $rr->$_;
		my $r2 = join '', $rr2->$_;
		is( $r2, $r1, "additional attribute rr->$_()" );
	}

	my $encoded = $rr->encode;
	my $decoded = Net::DNS::RR->decode( \$encoded );
	my $hex1    = unpack 'H*', $encoded;
	my $hex2    = unpack 'H*', $decoded->encode;
	my $hex3    = unpack 'H*', $rr->rdata;
	is( $hex2, $hex1, 'encode/decode transparent' );
	is( $hex3, $wire, 'encoded RDATA matches example' );
}


exit;

