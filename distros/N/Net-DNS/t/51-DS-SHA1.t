#!/usr/bin/perl
# $Id: 51-DS-SHA1.t 1855 2021-11-26 11:33:48Z willem $	-*-perl-*-
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


# Simple known-answer tests based upon the examples given in RFC4034, section 5.4
my $RFC = 'RFC4034';

my $dnskey = Net::DNS::RR->new( <<'END' );
dskey.example.com.	86400	IN	DNSKEY	256 3 5 (
	AQOeiiR0GOMYkDshWoSKz9XzfwJr1AYtsmx3TGkJaNXVbfi/2pHm822aJ5iI9BMzNXxeYCmZDRD9
	9WYwYqUSdjMmmAphXdvxegXd/M5+X7OrzKBaMbCVdFLUUh6DhweJBjEVv5f2wwjM9XzcnOf+EPbt
	G9DMBmADjFDc2w/rljwvFw== ) ; Key ID = 60485
END

my $ds = Net::DNS::RR->new( <<'END' );
dskey.example.com.	86400	IN	DS	60485 5 1 (
	2BB183AF5F22588179A53B0A98631FAD1A292118 )
	; xepor-cybyp-zulyd-dekom-civip-hovob-pikek-fylop-tekyd-namac-moxex
END


my $test = Net::DNS::RR::DS->create( $dnskey, digtype => $ds->digtype, ttl => $ds->ttl );

is( $test->string, $ds->string, "created DS matches $RFC example DS" );

ok( $test->verify($dnskey), "created DS verifies $RFC example DNSKEY" );

ok( $ds->verify($dnskey), "$RFC example DS verifies DNSKEY" );

$test->print;

__END__


