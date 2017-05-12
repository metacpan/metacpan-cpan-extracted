# $Id: 54-DS-SHA384.t 1352 2015-06-02 08:13:13Z willem $	-*-perl-*-
#

use strict;
use Test::More;
use Net::DNS;

my @prerequisite = qw(
		Digest::SHA
		MIME::Base64
		Net::DNS::RR::DNSKEY
		Net::DNS::RR::DS
		);

foreach my $package (@prerequisite) {
	next if eval "require $package";
	plan skip_all => "$package not installed";
	exit;
}

plan tests => 3;


# Simple known-answer tests based upon the examples given in RFC6605, section 6.2

my $dnskey = new Net::DNS::RR <<'END';
example.net. 3600 IN DNSKEY 257 3 14 (
	   xKYaNhWdGOfJ+nPrL8/arkwf2EY3MDJ+SErKivBVSum1
	   w/egsXvSADtNJhyem5RCOpgQ6K8X1DRSEkrbYQ+OB+v8
	   /uX45NBwY8rp65F6Glur8I/mlVNgF6W/qTI37m40 )
END

my $ds = new Net::DNS::RR <<'END';
example.net. 3600 IN DS 10771 14 4 (
	   72d7b62976ce06438e9c0bf319013cf801f09ecc84b8
	   d7e9495f27e305c6a9b0563a9b5f4d288405c3008a94
	   6df983d6 )
END


my $test = create Net::DNS::RR::DS(
	$dnskey,
	digtype => 'SHA384',
	ttl	=> 3600
	);

is( $test->string, $ds->string, 'created DS matches RFC6605 example DS' );

ok( $test->verify($dnskey), 'created DS verifies RFC6605 example DNSKEY' );

ok( $ds->verify($dnskey), 'RFC6605 example DS verifies DNSKEY' );

$ds->print;

__END__


