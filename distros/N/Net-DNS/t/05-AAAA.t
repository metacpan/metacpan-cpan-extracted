# $Id: 05-AAAA.t 1354 2015-06-05 08:20:53Z willem $	-*-perl-*-

use strict;
use Test::More tests => 136;


use Net::DNS;


my $name = 'AAAA.example';
my $type = 'AAAA';
my $code = 28;
my @attr = qw( address );
my @data = qw( 1:203:405:607:809:a0b:c0d:e0f );
my @also = qw( );

my $wire = '000102030405060708090a0b0c0d0e0f';


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
	my %testcase = (
		'0:0:0:0:0:0:0:0' => '::',
		'0:0:0:0:0:0:0:8' => '::8',
		'0:0:0:0:0:0:7:0' => '::7:0',
		'0:0:0:0:0:6:0:0' => '::6:0:0',
		'0:0:0:0:0:6:0:8' => '::6:0:8',
		'0:0:0:0:5:0:0:0' => '::5:0:0:0',
		'0:0:0:0:5:0:0:8' => '::5:0:0:8',
		'0:0:0:0:5:0:7:0' => '::5:0:7:0',
		'0:0:0:4:0:0:0:0' => '0:0:0:4::',
		'0:0:0:4:0:0:0:8' => '::4:0:0:0:8',
		'0:0:0:4:0:0:7:0' => '::4:0:0:7:0',
		'0:0:0:4:0:6:0:0' => '::4:0:6:0:0',
		'0:0:0:4:0:6:0:8' => '::4:0:6:0:8',
		'0:0:3:0:0:0:0:0' => '0:0:3::',
		'0:0:3:0:0:0:0:8' => '0:0:3::8',
		'0:0:3:0:0:0:7:0' => '0:0:3::7:0',
		'0:0:3:0:0:6:0:0' => '::3:0:0:6:0:0',
		'0:0:3:0:0:6:0:8' => '::3:0:0:6:0:8',
		'0:0:3:0:5:0:0:0' => '0:0:3:0:5::',
		'0:0:3:0:5:0:0:8' => '::3:0:5:0:0:8',
		'0:0:3:0:5:0:7:0' => '::3:0:5:0:7:0',
		'0:2:0:0:0:0:0:0' => '0:2::',
		'0:2:0:0:0:0:0:8' => '0:2::8',
		'0:2:0:0:0:0:7:0' => '0:2::7:0',
		'0:2:0:0:0:6:0:0' => '0:2::6:0:0',
		'0:2:0:0:0:6:0:8' => '0:2::6:0:8',
		'0:2:0:0:5:0:0:0' => '0:2:0:0:5::',
		'0:2:0:0:5:0:0:8' => '0:2::5:0:0:8',
		'0:2:0:0:5:0:7:0' => '0:2::5:0:7:0',
		'0:2:0:4:0:0:0:0' => '0:2:0:4::',
		'0:2:0:4:0:0:0:8' => '0:2:0:4::8',
		'0:2:0:4:0:0:7:0' => '0:2:0:4::7:0',
		'0:2:0:4:0:6:0:0' => '0:2:0:4:0:6::',
		'0:2:0:4:0:6:0:8' => '0:2:0:4:0:6:0:8',
		'1:0:0:0:0:0:0:0' => '1::',
		'1:0:0:0:0:0:0:8' => '1::8',
		'1:0:0:0:0:0:7:0' => '1::7:0',
		'1:0:0:0:0:6:0:0' => '1::6:0:0',
		'1:0:0:0:0:6:0:8' => '1::6:0:8',
		'1:0:0:0:5:0:0:0' => '1::5:0:0:0',
		'1:0:0:0:5:0:0:8' => '1::5:0:0:8',
		'1:0:0:0:5:0:7:0' => '1::5:0:7:0',
		'1:0:0:4:0:0:0:0' => '1:0:0:4::',
		'1:0:0:4:0:0:0:8' => '1:0:0:4::8',
		'1:0:0:4:0:0:7:0' => '1::4:0:0:7:0',
		'1:0:0:4:0:6:0:0' => '1::4:0:6:0:0',
		'1:0:0:4:0:6:0:8' => '1::4:0:6:0:8',
		'1:0:3:0:0:0:0:0' => '1:0:3::',
		'1:0:3:0:0:0:0:8' => '1:0:3::8',
		'1:0:3:0:0:0:7:0' => '1:0:3::7:0',
		'1:0:3:0:0:6:0:0' => '1:0:3::6:0:0',
		'1:0:3:0:0:6:0:8' => '1:0:3::6:0:8',
		'1:0:3:0:5:0:0:0' => '1:0:3:0:5::',
		'1:0:3:0:5:0:0:8' => '1:0:3:0:5::8',
		'1:0:3:0:5:0:7:0' => '1:0:3:0:5:0:7:0',
		);

	foreach my $address ( sort keys %testcase ) {
		my $compact = $testcase{$address};
		my $rr1 = new Net::DNS::RR( name => $name, type => $type, address => $address );
		is( $rr1->address_short, $compact, "address compression:\t$address" );
		my $rr2 = new Net::DNS::RR( name => $name, type => $type, address => $compact );
		is( $rr2->address_long, $address, "address expansion:\t$compact" );
	}
}


{
	my %testcase = (
		'1'		 => '1:0:0:0:0:0:0:0',
		'1:'		 => '1:0:0:0:0:0:0:0',
		'1:2'		 => '1:2:0:0:0:0:0:0',
		'1:2:'		 => '1:2:0:0:0:0:0:0',
		'1:2:3'		 => '1:2:3:0:0:0:0:0',
		'1:2:3:'	 => '1:2:3:0:0:0:0:0',
		'1:2:3:4'	 => '1:2:3:4:0:0:0:0',
		'1:2:3:4:'	 => '1:2:3:4:0:0:0:0',
		'1:2:3:4:5'	 => '1:2:3:4:5:0:0:0',
		'1:2:3:4:5:'	 => '1:2:3:4:5:0:0:0',
		'1:2:3:4:5:6'	 => '1:2:3:4:5:6:0:0',
		'1:2:3:4:5:6:'	 => '1:2:3:4:5:6:0:0',
		'1:2:3:4:5:6:7'	 => '1:2:3:4:5:6:7:0',
		'1:2:3:4:5:6:7:' => '1:2:3:4:5:6:7:0',
		'::ffff:1.2.3.4' => '0:0:0:0:0:ffff:102:304',
		'::ffff:1.2.4'	 => '0:0:0:0:0:ffff:102:4',
		'::ffff:1.4'	 => '0:0:0:0:0:ffff:100:4',
		);

	foreach my $address ( sort keys %testcase ) {
		my $expect = new Net::DNS::RR( name => $name, type => $type, address => $testcase{$address} );
		my $rr	   = new Net::DNS::RR( name => $name, type => $type, address => $address );
		is( $rr->address, $expect->address, "address completion:\t$address" );
	}
}


exit;

