#!/usr/bin/perl
# $Id: 52-DS-SHA256.t 1855 2021-11-26 11:33:48Z willem $	-*-perl-*-
#

use strict;
use warnings;
use Test::More;
use Net::DNS;

my @prerequisite = qw(
		Digest::SHA
		MIME::Base64
		Net::DNS::RR::DNSKEY
		Net::DNS::RR::DS
		);

foreach my $package (@prerequisite) {
	next if eval "require $package";	## no critic
	plan skip_all => "$package not installed";
	exit;
}

plan tests => 3;


# Simple known-answer tests based upon the examples given in RFC4509, section 2.3
my $RFC = 'RFC4509';

my $dnskey = Net::DNS::RR->new( <<'END' );
dskey.example.com.	86400	IN	DNSKEY	256 3 5 (
	AQOeiiR0GOMYkDshWoSKz9XzfwJr1AYtsmx3TGkJaNXVbfi/2pHm822aJ5iI9BMzNXxeYCmZDRD9
	9WYwYqUSdjMmmAphXdvxegXd/M5+X7OrzKBaMbCVdFLUUh6DhweJBjEVv5f2wwjM9XzcnOf+EPbt
	G9DMBmADjFDc2w/rljwvFw== ) ; Key ID = 60485
END

my $ds = Net::DNS::RR->new( <<'END' );
dskey.example.com.	86400	IN	DS	60485 5 2 (
	D4B7D520E7BB5F0F67674A0CCEB1E3E0614B93C4F9E99B8383F6A1E4469DA50A )
END


my $test = Net::DNS::RR::DS->create( $dnskey, digtype => $ds->digtype, ttl => $ds->ttl );

is( $test->string, $ds->string, "created DS matches $RFC example DS" );

ok( $test->verify($dnskey), "created DS verifies $RFC example DNSKEY" );

ok( $ds->verify($dnskey), "$RFC example DS verifies DNSKEY" );

$test->print;

__END__


