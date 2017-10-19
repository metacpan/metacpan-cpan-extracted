# $Id: 05-DS.t 1595 2017-09-12 09:10:56Z willem $	-*-perl-*-

use strict;
use Test::More tests => 37;


use Net::DNS;


my $name = 'DS.example';
my $type = 'DS';
my $code = 43;
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
	my $rr	  = new Net::DNS::RR(". $type @data");
	my $class = ref($rr);

	$rr->digtype('SHA256');
	is( $rr->digtype(),	      2,	 'digest type mnemonic accepted' );
	is( $rr->digtype('MNEMONIC'), 'SHA-256', 'rr->digtype("MNEMONIC") returns mnemonic' );
	is( $rr->digtype(),	      2,	 'rr->digtype("MNEMONIC") preserves value' );

	eval { $rr->digtype(0); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "disallowed digtype 0\t[$exception]" );

	is( $class->digtype('SHA256'), 2,	  'class method digtype("SHA256")' );
	is( $class->digtype(2),	       'SHA-256', 'class method digtype(2)' );
	is( $class->digtype(255),      255,	  'class method digtype(255)' );
}


{
	my $rr = new Net::DNS::RR(". $type @data");
	eval { $rr->digest('123456789XBCDEF'); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "corrupt hexadecimal\t[$exception]" );
}


{
	my $keyrr = new Net::DNS::RR( type => 'DNSKEY', keybin => '' );
	eval { create Net::DNS::RR::DS( $keyrr, ( 'digtype' => 255 ) ); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "create: wrong digtype\t[$exception]" );
}


{
	my $keyrr = new Net::DNS::RR( type => 'DNSKEY', protocol => 0 );
	eval { create Net::DNS::RR::DS($keyrr); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "create: non-DNSSEC key\t[$exception]" );
}


{
	my $keyrr = new Net::DNS::RR( type => 'DNSKEY', flags => 0x8000 );
	eval { create Net::DNS::RR::DS($keyrr); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "create: non-auth key\t[$exception]" );
}


{
	my $keyrr = new Net::DNS::RR( type => 'DNSKEY', flags => 0x200 );
	eval { create Net::DNS::RR::DS($keyrr); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "create: non-ZONE key\t[$exception]" );
}


{
	my $rr = new Net::DNS::RR("$name $type @data");
	$rr->print;
}


exit;

