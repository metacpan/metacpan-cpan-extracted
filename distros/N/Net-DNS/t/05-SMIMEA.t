# $Id: 05-SMIMEA.t 1449 2016-02-01 12:27:12Z willem $	-*-perl-*-

use strict;
use Test::More tests => 19;


use Net::DNS;


my $name = 'c93f1e400f26708f98cb19d936620da35eec8f72e57f9eec01c1afd6._smimecert.example.com';
my $type = 'SMIMEA';
my $code = 53;
my @attr = qw( usage selector matchingtype certificate );
my @data = qw( 1 1 1 d2abde240d7cd3ee6b4b28c54df034b97983a1d16e8a410e4561cb106618e971 );
my @also = qw( certbin babble );

my $wire = qw( 010101d2abde240d7cd3ee6b4b28c54df034b97983a1d16e8a410e4561cb106618e971 );


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
	is( length($rxtext), length($null), 'string RDATA can be empty' )
}


{
	my $rr = new Net::DNS::RR(". $type @data");
	eval { $rr->certificate('123456789XBCDEF'); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "corrupt hexadecimal\t[$exception]" );
}


{
	my $rr = new Net::DNS::RR(". $type");
	foreach (@attr) {
		ok( !$rr->$_(), "'$_' attribute of empty RR undefined" );
	}
}


{
	my $rr = new Net::DNS::RR("$name $type @data");
	$rr->print;
}


exit;

