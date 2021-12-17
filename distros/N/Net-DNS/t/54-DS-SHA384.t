#!/usr/bin/perl
# $Id: 54-DS-SHA384.t 1855 2021-11-26 11:33:48Z willem $	-*-perl-*-
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


# Simple known-answer tests based upon the examples given in RFC6605, section 6.2
my $RFC = 'RFC6605';

my $dnskey = Net::DNS::RR->new( <<'END' );
example.net.	3600	IN	DNSKEY	257 3 14 (
	xKYaNhWdGOfJ+nPrL8/arkwf2EY3MDJ+SErKivBVSum1w/egsXvSADtNJhyem5RCOpgQ6K8X1DRS
	EkrbYQ+OB+v8/uX45NBwY8rp65F6Glur8I/mlVNgF6W/qTI37m40 ) ; Key ID = 10771
END

my $ds = Net::DNS::RR->new( <<'END' );
example.net.	3600	IN	DS	10771 14 4 (
	72D7B62976CE06438E9C0BF319013CF801F09ECC84B8D7E9495F27E305C6A9B0
	563A9B5F4D288405C3008A946DF983D6 )
END


my $test = Net::DNS::RR::DS->create( $dnskey, digtype => $ds->digtype, ttl => $ds->ttl );

is( $test->string, $ds->string, "created DS matches $RFC example DS" );

ok( $test->verify($dnskey), "created DS verifies $RFC example DNSKEY" );

ok( $ds->verify($dnskey), "$RFC example DS verifies DNSKEY" );

$ds->print;

__END__


