# $Id: 05-AMTRELAY.t 1779 2020-05-11 09:11:17Z willem $	-*-perl-*-
#

use strict;
use Test::More;
use Net::DNS;

plan tests => 32;


my $name = '12.100.51.198.in-addr.arpa';
my $type = 'AMTRELAY';
my $code = 260;
my @attr = qw( precedence D relaytype relay );
my @data = qw( 10 1 3 amtrelays.example.com );
my @also = qw( );

my $wire = '0a8309616d7472656c617973076578616d706c6503636f6d00';


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
	my $lc		= new Net::DNS::RR( lc ". $type @data" );
	my $rr		= new Net::DNS::RR( uc ". $type @data" );
	my $hash	= {};
	my $predecessor = $rr->encode( 0, $hash );
	my $compressed	= $rr->encode( length $predecessor, $hash );
	ok( length $compressed == length $predecessor, 'encoded RDATA not compressible' );
	isnt( $rr->encode,    $lc->encode, 'encoded RDATA names not downcased' );
	isnt( $rr->canonical, $lc->encode, 'canonical RDATA names not downcased' );
}


{
	my $rr = new Net::DNS::RR("$name $type @data");
	foreach ( undef, qw(192.0.2.38 2001:db8:0:8002:0:0:2000:1 relay.example.com) ) {
		my $relay = $_ || '.';
		$rr->D( !$rr->D );				# toggle D-bit
		$rr->relay($relay);
		is( scalar( $rr->relay ), $_, "rr->relay( '$relay' )" );
		my $rr2 = new Net::DNS::RR( $rr->string );
		is( $rr2->rdstring, $rr->rdstring, 'new/string transparent' );
		my $encoded = $rr->encode;
		my $decoded = decode Net::DNS::RR( \$encoded );
		is( $decoded->rdstring, $rr->rdstring, 'encode/decode transparent' );
	}
}


{
	my $rr = new Net::DNS::RR(". $type");
	foreach (@attr) {
		ok( !$rr->$_(), "$_ attribute of empty RR undefined" );
	}
}


{
	my $rr = eval { new Net::DNS::RR( type => $type, relay => 'X' ); };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "unrecognised relay type\t[$exception]" );
}


{
	my $rr = new Net::DNS::RR("$name $type @data");
	$rr->print;
}

exit;


