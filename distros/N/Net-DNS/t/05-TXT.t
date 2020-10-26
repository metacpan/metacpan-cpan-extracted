#!/usr/bin/perl
# $Id: 05-TXT.t 1815 2020-10-14 21:55:18Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More tests => 52;

use Net::DNS;


my $name = 'TXT.example';
my $type = 'TXT';
my $code = 16;
my @attr = qw( txtdata );
my @data = qw( arbitrary_text );

my $wire = '0e6172626974726172795f74657874';


{
	my $typecode = unpack 'xn', Net::DNS::RR->new(". $type")->encode;
	is( $typecode, $code, "$type RR type code = $code" );

	my $hash = {};
	@{$hash}{@attr} = @data;

	my $rr = Net::DNS::RR->new(
		name => $name,
		type => $type,
		%$hash
		);

	my $string = $rr->string;
	my $rr2	   = Net::DNS::RR->new($string);
	is( $rr2->string, $string, 'new/string transparent' );

	is( $rr2->encode, $rr->encode, 'new($string) and new(%hash) equivalent' );

	foreach (@attr) {
		is( $rr->$_, $hash->{$_}, "expected result from rr->$_()" );
	}


	my $null    = Net::DNS::RR->new("$name NULL")->encode;
	my $empty   = Net::DNS::RR->new("$name $type")->encode;
	my $rxbin   = Net::DNS::RR->decode( \$empty )->encode;
	my $txtext  = Net::DNS::RR->new("$name $type")->string;
	my $rxtext  = Net::DNS::RR->new($txtext)->encode;
	my $encoded = $rr->encode;
	my $decoded = Net::DNS::RR->decode( \$encoded );
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
	eval { Net::DNS::RR->decode( \$wireformat ); };
	my ($exception) = split /\n/, "$@\n";
	ok( $exception, "corrupt wire-format\t[$exception]" );
}


{
	foreach my $testcase (
		q|contiguous|,	q|three unquoted strings|,
		q|"in quotes"|, q|"two separate" "quoted strings"|,
		q|"" empty|,	q|" " space|,
		q|!|,		q|\"|,
		q|#|,		q|$|,
		q|%|,		q|&|,
		q|'|,		q|\(|,
		q|\)|,		q|*|,
		q|+|,		q|,|,
		q|-|,		q|.|,
		q|/|,		q|:|,
		q|\;|,		q|<|,
		q|=|,		q|>|,
		q|?|,		q|@|,
		q|[|,		q|\\\\|,
		q|]|,		q|^|,
		q|_|,		q|`|,
		q|{|,		q(|),
		q|}|,		q|~|,
		q|0|,		q|1|,
		join( q|\227\128\128|,
			q|\229\143\164\230\177\160\227\130\132|,
			q|\232\155\153\233\163\155\232\190\188\227\130\128|,
			q|\230\176\180\227\129\174\233\159\179| )
		) {
		my $string = "$name.	TXT	$testcase";
		my $expect = Net::DNS::RR->new($string)->string; # test for consistent parsing
		my $result = Net::DNS::RR->new($expect)->string;
		is( $result, $expect, $string );
	}
}


{
	my $rr = Net::DNS::RR->new(". $type");
	foreach (@attr) {
		ok( !$rr->$_(), "'$_' attribute of empty RR undefined" );
	}
}


exit;

__END__
