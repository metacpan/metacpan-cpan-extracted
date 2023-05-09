#!/usr/bin/perl
# $Id: 05-HIP.t 1910 2023-03-30 19:16:30Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More;
use TestToolkit;

use Net::DNS;

my @prerequisite = qw(
		MIME::Base64
		);

foreach my $package (@prerequisite) {
	next if eval "require $package";	## no critic
	plan skip_all => "$package not installed";
	exit;
}

plan tests => 19;


my $name = 'HIP.example';
my $type = 'HIP';
my $code = 55;
my @attr = qw( algorithm hit key servers );
my @data = qw( 2 200100107b1a74df365639cc39f1d578
		AwEAAbdxyhNuSutc5EMzxTs9LBPCIkOFH8cIvM4p9+LrV4e19WzK00+CI6zBCQTdtWsuxKbWIy87UOoJTwkUs7lBu+Upr1gsNrut79ryra+bSRGQb1slImA8YVJyuIDsj7kwzG7jnERNqnWxZ48AWkskmdHaVDP4BcelrTI3rMXdXF5D
		rvs1.example.com
		rvs2.example.com );
my @also = qw( keybin );

my $wire = join '', qw( 10020084200100107b1a74df365639cc39f1d57803010001b771ca136e4aeb5c
		e44333c53b3d2c13c22243851fc708bcce29f7e2eb5787b5f56ccad34f8223ac
		c10904ddb56b2ec4a6d6232f3b50ea094f0914b3b941bbe529af582c36bbadef
		daf2adaf9b4911906f5b2522603c615272b880ec8fb930cc6ee39c444daa75b1
		678f005a4b2499d1da5433f805c7a5ad3237acc5dd5c5e430472767331076578
		616d706c6503636f6d000472767332076578616d706c6503636f6d00
		);

my $typecode = unpack 'xn', Net::DNS::RR->new( type => $type )->encode;
is( $typecode, $code, "$type RR type code = $code" );

my $hash = {};
@{$hash}{@attr} = @data;


for my $rr ( Net::DNS::RR->new( name => $name, type => $type, %$hash ) ) {
	my $string = $rr->string;
	my $rr2	   = Net::DNS::RR->new($string);
	is( $rr2->string, $string, 'new/string transparent' );

	is( $rr2->encode, $rr->encode, 'new($string) and new(%hash) equivalent' );

	foreach (@attr) {
		next if /server/;
		is( $rr->$_, $hash->{$_}, "expected result from rr->$_()" );
	}

	for (qw(servers)) {
		my ($rvs) = $rr->$_;				# test limitation: single element list
		is( $rvs, $hash->{$_}, "expected result from rr->$_()" );
	}

	foreach (@also) {
		is( $rr2->$_, $rr->$_, "additional attribute rr->$_()" );
	}
}


for my $rr ( Net::DNS::RR->new("$name $type @data") ) {
	my $encoded = $rr->encode;
	my $decoded = Net::DNS::RR->decode( \$encoded );
	my $hex1    = unpack 'H*', $encoded;
	my $hex2    = unpack 'H*', $decoded->encode;
	my $hex3    = unpack 'H*', $rr->rdata;
	is( $hex2, $hex1, 'encode/decode transparent' );
	is( $hex3, $wire, 'encoded RDATA matches example' );

	my $emptyrr = Net::DNS::RR->new("$name $type")->encode;
	my $corrupt = pack 'a*X2na*', $emptyrr, $decoded->rdlength - 1, $rr->rdata;
	exception( 'corrupt wire-format', sub { Net::DNS::RR->decode( \$corrupt ) } );
}


for my $rr ( Net::DNS::RR->new(". $type") ) {
	foreach (@attr) {
		ok( !$rr->$_(), "'$_' attribute of empty RR undefined" );
	}

	exception( 'corrupt hexadecimal', sub { $rr->hit('123456789XBCDEF') } );

	noexception( 'deprecate pkalgorithm',	    sub { $rr->pkalgorithm	 for ( 1 .. 2 ) } );
	noexception( 'deprecate pubkey',	    sub { $rr->pubkey		 for ( 1 .. 2 ) } );
	noexception( 'deprecate rendezvousservers', sub { $rr->rendezvousservers for ( 1 .. 2 ) } );

}


Net::DNS::RR->new("$name $type @data")->print;

exit;

