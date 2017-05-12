# $Id: 05-APL.t 1362 2015-06-23 08:47:14Z willem $	-*-perl-*-

use strict;
use Test::More tests => 31;


use Net::DNS;


my $name = 'APL.example';
my $type = 'APL';
my $code = 42;
my @attr = qw( aplist );
my @data = qw( 1:224.0.0.0/4 2:FF00::0/16 !1:192.168.38.0/28 1:224.0.0.0/0 2:FF00::0/0 );
my @also = qw( string negate family address );			# apitem attributes

my $wire = '00010401e000021001ff00011c83c0a8260001000000020000';


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
}


{
	my $rr = new Net::DNS::RR("$name $type @data");
	foreach my $item ( $rr->aplist ) {
		foreach (@also) {
			ok( defined( $item->$_ ), "aplist item->$_() attribute" );
		}
	}
}


{
	my $rr	    = new Net::DNS::RR("$name $type @data");
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

	my @wire = unpack 'C*', $encoded;
	$wire[length($empty) - 1]--;
	my $wireformat = pack 'C*', @wire;
	eval { decode Net::DNS::RR( \$wireformat ); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "corrupt wire-format\t[$exception]" );
}


{
	eval { new Net::DNS::RR("$name $type 0:0::0/0"); };
	my $exception = $1 if $@ =~ /^(.+)\n/;
	ok( $exception ||= '', "unknown address family\t[$exception]" );
}


exit;


