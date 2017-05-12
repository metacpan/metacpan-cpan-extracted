# $Id: 52-DS-SHA256.t 1352 2015-06-02 08:13:13Z willem $	-*-perl-*-
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


# Simple known-answer tests based upon the examples given in RFC4509, section 2.3

my $dnskey = new Net::DNS::RR <<'END';
dskey.example.com. 86400 IN DNSKEY 256 3 5 (	AQOeiiR0GOMYkDshWoSKz9Xz
						fwJr1AYtsmx3TGkJaNXVbfi/
						2pHm822aJ5iI9BMzNXxeYCmZ
						DRD99WYwYqUSdjMmmAphXdvx
						egXd/M5+X7OrzKBaMbCVdFLU
						Uh6DhweJBjEVv5f2wwjM9Xzc
						nOf+EPbtG9DMBmADjFDc2w/r
						ljwvFw==
						) ;  key id = 60485
END

my $ds = new Net::DNS::RR <<'END';
dskey.example.com. 86400 IN DS 60485 5 2   (	D4B7D520E7BB5F0F67674A0C
						CEB1E3E0614B93C4F9E99B83
						83F6A1E4469DA50A )
END


my $test = create Net::DNS::RR::DS( $dnskey, digtype => 'SHA256' );

is( $test->string, $ds->string, 'created DS matches RFC4509 example DS' );

ok( $test->verify($dnskey), 'created DS verifies RFC4509 example DNSKEY' );

ok( $ds->verify($dnskey), 'RFC4509 example DS verifies DNSKEY' );

$test->print;

__END__


