# $Id: 05-DNSKEY.t 1526 2017-01-16 09:17:54Z willem $	-*-perl-*-
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

plan tests => 32;


my $name = 'DNSKEY.example';
my $type = 'DNSKEY';
my $code = 48;
my @attr = qw( flags protocol algorithm publickey );

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


	my $empty   = new Net::DNS::RR("$name NULL");
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
	foreach ( @attr, qw(keylength keytag rdstring) ) {
		ok( !$rr->$_(), "'$_' attribute of empty RR undefined" );
	}
}


{
	my $rr	  = new Net::DNS::RR(". $type @data");
	my $class = ref($rr);

	$rr->algorithm(255);
	is( $rr->algorithm(), 255, 'algorithm number accepted' );
	$rr->algorithm('RSASHA1');
	is( $rr->algorithm(),		5,	   'algorithm mnemonic accepted' );
	is( $rr->algorithm('MNEMONIC'), 'RSASHA1', 'rr->algorithm("MNEMONIC") returns mnemonic' );
	is( $rr->algorithm(),		5,	   'rr->algorithm("MNEMONIC") preserves value' );

	eval { $rr->algorithm('X'); };
	my $exception1 = $1 if $@ =~ /^(.+)\n/;
	ok( $exception1 ||= '', "unknown mnemonic\t[$exception1]" );

	eval { $rr->algorithm(0); };
	my $exception2 = $1 if $@ =~ /^(.+)\n/;
	ok( $exception2 ||= '', "disallowed algorithm 0\t[$exception2]" );

	is( $class->algorithm('RSASHA256'), 8,		 'class method algorithm("RSASHA256")' );
	is( $class->algorithm(8),	    'RSASHA256', 'class method algorithm(8)' );
	is( $class->algorithm(255),	    255,	 'class method algorithm(255)' );
}


{
	my $rr = new Net::DNS::RR("$name $type @data");
	$rr->print;
}


exit;

