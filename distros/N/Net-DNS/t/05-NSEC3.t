# $Id: 05-NSEC3.t 1389 2015-09-09 13:09:43Z willem $	-*-perl-*-
#

use strict;
use Test::More tests => 26;
use Net::DNS;


my $name = '0p9mhaveqvm6t7vbl5lop2u3t2rp3tom.example';
my $type = 'NSEC3';
my $code = 50;
my @attr = qw( algorithm flags iterations salt hnxtname typelist );
my @data = qw( 1 1 12 aabbccdd 2t7b4g4vsa5smi47k61mv5bv1a22bojr NS SOA MX RRSIG DNSKEY NSEC3PARAM );
my @hash = ( qw( 1 1 12 aabbccdd 2t7b4g4vsa5smi47k61mv5bv1a22bojr ), q(NS SOA MX RRSIG DNSKEY NSEC3PARAM) );
my @also = qw( hashalgo optout );

my $wire = '0101000c04aabbccdd14174eb2409fe28bcb4887a1836f957f0a8425e27b000722010000000290';


{
	my $typecode = unpack 'xn', new Net::DNS::RR(". $type")->encode;
	is( $typecode, $code, "$type RR type code = $code" );

	my $hash = {};
	@{$hash}{@attr} = @hash;

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
		my $a = join ' ', sort split /\s+/, $rr->$_;	# typelist order unspecified
		my $b = join ' ', sort split /\s+/, $hash->{$_};
		is( $a, $b, "expected result from rr->$_()" );
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
	my @rdata = qw(1 1 12 - 2t7b4g4vsa5smi47k61mv5bv1a22bojr A);
	my $rr	  = new Net::DNS::RR(". $type @rdata");
	my $class = ref($rr);

	$rr->algorithm('SHA-1');
	is( $rr->algorithm(),		1,	 'algorithm mnemonic accepted' );
	is( $rr->algorithm('MNEMONIC'), 'SHA-1', "rr->algorithm('MNEMONIC')" );
	is( $class->algorithm('SHA-1'), 1,	 "class method algorithm('SHA-1')" );
	is( $class->algorithm(1),	'SHA-1', "class method algorithm(1)" );
	is( $class->algorithm(255),	255,	 "class method algorithm(255)" );

	eval { $rr->algorithm('X'); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "unknown mnemonic\t[$exception]" );
}


{
	my @rdata = qw(1 1 12 - 2t7b4g4vsa5smi47k61mv5bv1a22bojr A);
	my $rr	  = new Net::DNS::RR(". $type @rdata");
	is( $rr->salt,	   '',	     'parse RR with salt field placeholder' );
	is( $rr->rdstring, "@rdata", 'placeholder denotes empty salt field' );
	is( unpack( 'H*', $rr->saltbin ), '', 'null salt binary value' );

	eval { $rr->salt('123456789XBCDEF'); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "corrupt hexadecimal\t[$exception]" );
}


{
	my $rr = new Net::DNS::RR("$name $type @data");
	$rr->print;
}

exit;


