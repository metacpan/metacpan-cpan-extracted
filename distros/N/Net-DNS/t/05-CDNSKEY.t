#!/usr/bin/perl
# $Id: 05-CDNSKEY.t 1910 2023-03-30 19:16:30Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More;

use Net::DNS;

my @prerequisite = qw(
		MIME::Base64
		);

foreach my $package (@prerequisite) {
	next if eval "require $package";	## no critic
	plan skip_all => "$package not installed";
	exit;
}

plan tests => 34;


my $name = 'CDNSKEY.example';
my $type = 'CDNSKEY';
my $code = 60;
my @attr = qw( flags protocol algorithm publickey );

my $typecode = unpack 'xn', Net::DNS::RR->new( type => $type )->encode;
is( $typecode, $code, "$type RR type code = $code" );

my @data = (
	256, 3, 5, join '', qw(
			AQPSKmynfzW4kyBv015MUG2DeIQ3
			Cbl+BBZH4b/0PY1kxkmvHjcZc8no
			kfzj31GajIQKY+5CptLr3buXA10h
			WqTkF7H6RfoRqXQeogmMHfpftf6z
			Mv1LyBUgia7za6ZEzOJBOztyvhjL
			742iU/TpPSEDhm2SNKLijfUppn1U
			aNvv4w== )
			);
my @also = qw( keybin keylength keytag privatekeyname zone revoke sep );

my $wire = join '', qw( 010003050103D22A6CA77F35B893206FD35E4C506D8378843709B97E041647E1
		BFF43D8D64C649AF1E371973C9E891FCE3DF519A8C840A63EE42A6D2EBDDBB97
		035D215AA4E417B1FA45FA11A9741EA2098C1DFA5FB5FEB332FD4BC8152089AE
		F36BA644CCE2413B3B72BE18CBEF8DA253F4E93D2103866D9234A2E28DF529A6
		7D5468DBEFE3 );


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
	my $hex1    = uc unpack 'H*', $decoded->encode;
	my $hex2    = uc unpack 'H*', $encoded;
	my $hex3    = uc unpack 'H*', $rr->rdata;
	is( $hex1, $hex2, 'encode/decode transparent' );
	is( $hex3, $wire, 'encoded RDATA matches example' );
}


for my $rr ( Net::DNS::RR->new(". $type") ) {
	foreach ( @attr, qw(keylength keytag rdstring) ) {
		ok( !$rr->$_(), "'$_' attribute of empty RR undefined" );
	}

	$rr->algorithm(255);
	is( $rr->algorithm(), 255, 'algorithm number accepted' );
	$rr->algorithm('RSASHA1');
	is( $rr->algorithm(),		5,	   'algorithm mnemonic accepted' );
	is( $rr->algorithm('MNEMONIC'), 'RSASHA1', 'rr->algorithm("MNEMONIC") returns mnemonic' );
	is( $rr->algorithm(),		5,	   'rr->algorithm("MNEMONIC") preserves value' );
}


for my $rr ( Net::DNS::RR->new("$name. $type 0 3 0 AA==") ) {	# per RFC8078(4), erratum 5049
	ok( ref($rr), "DNSKEY delete: $name. $type 0 3 0 AA==" );
	is( $rr->flags(),     0, 'DNSKEY delete: flags 0' );
	is( $rr->protocol(),  3, 'DNSKEY delete: protocol 3' );
	is( $rr->algorithm(), 0, 'DNSKEY delete: algorithm 0' );

	my $rdata = unpack 'H*', $rr->rdata();
	is( $rdata, '0000030000', 'DNSKEY delete: rdata wire-format' );

	is( $rr->rdstring(), '0 3 0 AA==', 'DNSKEY delete: presentation format' );
}


for my $rr ( Net::DNS::RR->new("$name. $type 0 3 0 0") ) {	# per RFC8078(4) as published
	is( $rr->rdstring(), '0 3 0 AA==', 'DNSKEY delete: accept old format' );
}


Net::DNS::RR->new("$name $type @data")->print;

exit;

