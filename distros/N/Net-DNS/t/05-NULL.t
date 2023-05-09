#!/usr/bin/perl
# $Id: 05-NULL.t 1910 2023-03-30 19:16:30Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More tests => 6;

use Net::DNS;


my $name = 'NULL.example';
my $type = 'NULL';
my $code = 10;
my @attr = qw( );
my @data = ('\# 4 61626364');
my @also = qw( rdlength rdata );

my $wire = '61626364';

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

	$rr->ttl(1234);
	my $encoded = $rr->encode;
	my $decoded = Net::DNS::RR->decode( \$encoded );
	is( $decoded->string, $rr->string, 'encode/decode transparent' );
}


exit;

