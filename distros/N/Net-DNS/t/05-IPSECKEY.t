# $Id: 05-IPSECKEY.t 1381 2015-08-25 07:36:09Z willem $	-*-perl-*-
#

use strict;
use Test::More;
use Net::DNS;

my @prerequisite = qw(
		MIME::Base64
		);

foreach my $package (@prerequisite) {
	next if eval "require $package";
	plan skip_all => "$package not installed";
	exit;
}

plan tests => 39;


my $name = '38.2.0.192.in-addr.arpa';
my $type = 'IPSECKEY';
my $code = 45;
my @attr = qw( precedence gatetype algorithm gateway key );
my @data = qw( 10 3 2 gateway.example.com AQNRU3mG7TVTO2BkR47usntb102uFJtugbo6BSGvgqt4AQ== );
my @also = qw( pubkey keybin );

my $wire =
'0a03020767617465776179076578616d706c6503636f6d00010351537986ed35533b6064478eeeb27b5bd74dae149b6e81ba3a0521af82ab7801';


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
	foreach ( undef, qw(192.0.2.38 2001:db8:0:8002:0:0:2000:1 gateway.example.com) ) {
		my $gateway = $_ || '.';
		$rr->gateway($gateway);
		is( scalar( $rr->gateway ), $_, "rr->gateway( '$gateway' )" );
		my $rr2 = new Net::DNS::RR( $rr->string );
		is( $rr2->rdstring, $rr->rdstring, 'new/string transparent' );
		my $encoded = $rr->encode;
		my $decoded = decode Net::DNS::RR( \$encoded );
		is( $decoded->rdstring, $rr->rdstring, 'encode/decode transparent' );
	}
}


{
	my $rr = eval { new Net::DNS::RR( type => $type, gateway => 'X' ); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "unrecognised gateway type\t[$exception]" );
}


{
	my $rr = eval { new Net::DNS::RR(". $type \\# 3 01ff05"); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "exception raised in decode\t[$exception]" );
}


{
	my $rr = new Net::DNS::RR(". $type @data");
	$rr->{gatetype} = 255;
	$rr->encode;
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "exception raised in encode\t[$exception]" );
}


{
	my $rr = new Net::DNS::RR(". $type @data");
	$rr->{gatetype} = 255;
	eval { my $gateway = $rr->gateway; };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "exception raised in gateway\t[$exception]" );
}


{
	my $rr = new Net::DNS::RR(". $type");
	foreach (@attr) {
		ok( !$rr->$_(), "$_ attribute of empty RR undefined" );
	}
}


{
	my $rr = new Net::DNS::RR("$name $type @data");
	$rr->print;
}

exit;


