# $Id: 05-CDS.t 1586 2017-08-15 09:01:57Z willem $	-*-perl-*-

use strict;
use Test::More tests => 31;


use Net::DNS;


my $name = 'CDS.example';
my $type = 'CDS';
my $code = 59;
my @attr = qw( keytag algorithm digtype digest );
my @data = ( 60485, 5, 1, '2bb183af5f22588179a53b0a98631fad1a292118' );
my @also = qw( digestbin babble );

my $wire = join '', qw( EC45 05 01 2BB183AF5F22588179A53B0A98631FAD1A292118 );


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


	my $empty   = new Net::DNS::RR("$name $type");
	my $encoded = $rr->encode;
	my $decoded = decode Net::DNS::RR( \$encoded );
	my $hex1    = uc unpack 'H*', $decoded->encode;
	my $hex2    = uc unpack 'H*', $encoded;
	my $hex3    = uc unpack 'H*', substr( $encoded, length $empty->encode );
	is( $hex1, $hex2, 'encode/decode transparent' );
	is( $hex3, $wire, 'encoded RDATA matches example' );
}


{
	my $rr = new Net::DNS::RR(". $type");
	foreach ( @attr, 'rdstring' ) {
		ok( !$rr->$_(), "'$_' attribute of empty RR undefined" );
	}
}


{
	my $rr = new Net::DNS::RR(". $type");

	$rr->algorithm(255);
	is( $rr->algorithm(), 255, 'algorithm number accepted' );
	$rr->algorithm('RSASHA1');
	is( $rr->algorithm(),		5,	   'algorithm mnemonic accepted' );
	is( $rr->algorithm('MNEMONIC'), 'RSASHA1', 'rr->algorithm("MNEMONIC") returns mnemonic' );
	is( $rr->algorithm(),		5,	   'rr->algorithm("MNEMONIC") preserves value' );

	$rr->digtype('SHA-256');
	is( $rr->digtype(),	      2,	 'digest type mnemonic accepted' );
	is( $rr->digtype('MNEMONIC'), 'SHA-256', 'rr->digtype("MNEMONIC") returns mnemonic' );
	is( $rr->digtype(),	      2,	 'rr->digtype("MNEMONIC") preserves value' );
}


{
	my @arg = qw(0 0 0 00);					# per RFC8078(4), erratum 5049
	my $rr	= new Net::DNS::RR("$name. $type @arg");
	ok( ref($rr), "DS delete: $name. $type @arg" );
	is( $rr->keytag(),    0, 'DS delete: keytag 0' );
	is( $rr->algorithm(), 0, 'DS delete: algorithm 0' );
	is( $rr->digtype(),   0, 'DS delete: digtype 0' );

	is( $rr->string(), "$name.\tIN\t$type\t@arg", 'DS delete: presentation format' );

	my $rdata = unpack 'H*', $rr->rdata();
	is( $rdata, '0000000000', 'DS delete: rdata wire-format' );
}


{
	my @arg = qw(0 0 0 0);					# per RFC8078(4) as published
	my $rr	= new Net::DNS::RR("$name. $type @arg");
	is( $rr->rdstring(), '0 0 0 00', 'DS delete: accept old format' );
}


{
	my @arg = qw(0 0 0 -);					# unexpected empty field
	my $rr	= new Net::DNS::RR("$name. $type @arg");
	is( $rr->rdstring(), '0 0 0 -', 'DS delete: represent empty digest' );
}


{
	my $rr = new Net::DNS::RR("$name $type @data");
	$rr->print;
}


exit;

