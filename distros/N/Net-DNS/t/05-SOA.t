# $Id: 05-SOA.t 1381 2015-08-25 07:36:09Z willem $	-*-perl-*-

use strict;
use Test::More tests => 40;


use Net::DNS;


my $name = 'SOA.example';
my $type = 'SOA';
my $code = 6;
my @attr = qw( mname rname serial refresh retry expire minimum );
my @data = qw( ns.example.net rp@example.com 0 14400 1800 604800 7200 );
my @also = qw( );

my $wire = '026e73076578616d706c65036e657400027270076578616d706c6503636f6d0000000000000038400000070800093a8000001c20';


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
	ok( length $compressed < length $predecessor, 'encoded RDATA compressible' );
	isnt( $rr->encode, $lc->encode, 'encoded RDATA names not downcased' );
	is( $rr->canonical, $lc->encode, 'canonical RDATA names downcased' );
}


{
	use integer;
	my $initial = -1;		## exercise 32-bit compatibility code on 64-bit hardware
	foreach my $serial ( 2E9, 3E9, 4E9, 1E9, 2E9, 4E9, 1E9, 3E9 ) {
		my $rr = new Net::DNS::RR("name SOA mname rname $initial");
		$rr->serial($serial);
		is( $rr->serial, 0 + $serial, "rr->serial($serial) steps from $initial to $serial" );
		$initial = $serial;
	}
}


{
	use integer;
	my $rr	    = new Net::DNS::RR('name SOA mname rname 1');
	my $initial = $rr->serial;
	$rr->serial(SEQUENTIAL);
	is( $rr->serial, ++$initial, 'rr->serial(SEQUENTIAL) increments existing serial number' );

	my $pre31wrap  = 0x7FFFFFFF;
	my $post31wrap = 0x80000000;
	$rr->serial($pre31wrap);
	$rr->serial(SEQUENTIAL);
	is( $rr->serial, 0 + $post31wrap, "rr->serial(SEQUENTIAL) wraps from $pre31wrap to $post31wrap" );

	my $pre32wrap  = 0xFFFFFFFF;
	my $post32wrap = 0x00000000;
	$rr->serial($pre32wrap);
	$rr->serial(SEQUENTIAL);
	is( $rr->serial, 0 + $post32wrap, "rr->serial(SEQUENTIAL) wraps from $pre32wrap to $post32wrap" );
}


{
	use integer;
	my $rr	     = new Net::DNS::RR('name SOA mname rname 2000000000');
	my $predate  = $rr->serial;
	my $postdate = YYYYMMDDxx;
	my $postincr = $postdate + 1;
	is( $rr->serial($postdate), $postdate, "rr->serial(YYYYMMDDxx) steps from $predate to $postdate" );
	is( $rr->serial($postdate), $postincr, "rr->serial(YYYYMMDDxx) increments $postdate to $postincr" );
}


{
	use integer;
	my $pretime = UNIXTIME;
	my $rr	    = new Net::DNS::RR("name SOA mname rname $pretime");
	sleep 5;
	my $posttime = UNIXTIME;
	my $postincr = $posttime + 1;
	is( $rr->serial($posttime), $posttime, "rr->serial(UNIXTIME) steps from $pretime to $posttime" );
	is( $rr->serial($posttime), $postincr, "rr->serial(UNIXTIME) increments $posttime to $postincr" );
}


{
	my $rr = new Net::DNS::RR(". $type");
	foreach (@attr) {
		ok( !$rr->$_(), "'$_' attribute of empty RR undefined" );
	}
}


{
	my $rr = new Net::DNS::RR("$name $type @data");
	$rr->serial(YYYYMMDDxx);
	$rr->print;
}


exit;

