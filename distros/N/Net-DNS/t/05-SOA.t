#!/usr/bin/perl
# $Id: 05-SOA.t 1910 2023-03-30 19:16:30Z willem $	-*-perl-*-
#

use strict;
use warnings;
use integer;
use Test::More tests => 35;

use Net::DNS;


my $name = 'SOA.example';
my $type = 'SOA';
my $code = 6;
my @attr = qw( mname rname serial refresh retry expire minimum );
my @data = qw( ns.example.net rp@example.com 0 14400 1800 604800 7200 );
my @also = qw( );

my $wire = '026e73076578616d706c65036e657400027270076578616d706c6503636f6d0000000000000038400000070800093a8000001c20';

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


for my $rr ( Net::DNS::RR->new("name SOA mname rname 0") ) {
	use integer;			## exercise 32-bit compatibility code on 64-bit hardware
	ok( $rr->serial(-1), 'ordering function 32-bit compatibility' );

	my $initial = 0;		## test serial number partial ordering function
	foreach my $serial ( 2E9, 3E9, 4E9, 1E9, 2E9, 4E9, 1E9, 3E9 ) {
		$rr->serial($initial);
		is(	sprintf( '%u', $rr->serial($serial) ),
			sprintf( '%u', $serial ),
			"rr->serial($serial) steps from $initial to $serial"
			);
		$initial = $serial;
	}
}


for my $rr ( Net::DNS::RR->new('name SOA mname rname 1') ) {
	my $initial = $rr->serial;
	is( $rr->serial(SEQUENTIAL), ++$initial, 'rr->serial(SEQUENTIAL) increments existing serial number' );

	my $pre31wrap  = 0x7FFFFFFF;
	my $post31wrap = 0x80000000;
	$rr->serial($pre31wrap);
	is(	sprintf( '%x', $rr->serial(SEQUENTIAL) ),
		sprintf( '%x', $post31wrap ),
		"rr->serial(SEQUENTIAL) wraps from $pre31wrap to $post31wrap"
		);

	my $pre32wrap  = 0xFFFFFFFF;
	my $post32wrap = 0x00000000;
	$rr->serial($pre32wrap);
	is(	sprintf( '%x', $rr->serial(SEQUENTIAL) ),
		sprintf( '%x', $post32wrap ),
		"rr->serial(SEQUENTIAL) wraps from $pre32wrap to $post32wrap"
		);
}


for my $rr ( Net::DNS::RR->new('name SOA mname rname 2000000000') ) {
	my $predate  = $rr->serial;
	my $postdate = YYYYMMDDxx;
	my $postincr = $postdate + 1;
	is( $rr->serial($postdate), $postdate, "rr->serial(YYYYMMDDxx) steps from $predate to $postdate" );
	is( $rr->serial($postdate), $postincr, "rr->serial(YYYYMMDDxx) increments $postdate to $postincr" );
}


for my $rr ( Net::DNS::RR->new('name SOA mname rname') ) {
	my $pretime  = time() - 10;
	my $posttime = UNIXTIME;
	my $postincr = $posttime + 1;
	$rr->serial($pretime);
	is( $rr->serial($posttime), $posttime, "rr->serial(UNIXTIME) steps from $pretime to $posttime" );
	is( $rr->serial($posttime), $postincr, "rr->serial(UNIXTIME) increments $posttime to $postincr" );
}


for my $rr ( Net::DNS::RR->new("$name $type @data") ) {
	$rr->serial(YYYYMMDDxx);
	$rr->print;
}

exit;

