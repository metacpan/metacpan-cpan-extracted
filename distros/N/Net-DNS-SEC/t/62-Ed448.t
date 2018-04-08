# $Id: 62-Ed448.t 1664 2018-04-05 10:03:14Z willem $	-*-perl-*-
#

use strict;
use Test::More;

my %prerequisite = (
	'Net::DNS::SEC' => 1.04,
	'MIME::Base64'	=> 2.13,
	);

foreach my $package ( sort keys %prerequisite ) {
	my @revision = grep $_, $prerequisite{$package};
	next if eval "use $package @revision; 1;";
	plan skip_all => "missing prerequisite $package @revision";
	exit;
}

plan skip_all => "disabled EdDSA"
		unless eval { Net::DNS::SEC::libcrypto->can('EdDSA_sign') };

plan tests => 8;


my %filename;

END {
	foreach ( values %filename ) {
		unlink($_) if -e $_;
	}
}


use_ok('Net::DNS::SEC');
use_ok('Net::DNS::SEC::Private');
use_ok('Net::DNS::SEC::EdDSA');


#	Specimen private and public keys taken from RFC8080

my $key = new Net::DNS::RR <<'END';
ED448.example.com.	IN	DNSKEY	( 257 3 16
	3kgROaDjrh0H2iuixWBrc8g2EpBBLCdGzHmn+G2MpTPhpj/OiBVHHSfPodx1FYYUcJKm1MDpJtIA )
	; Key ID = 9713
END

ok( $key, 'set up EdDSA public key' );


my $keyfile = $filename{keyfile} = $key->privatekeyname;

open( KEY, ">$keyfile" ) or die "$keyfile $!";
print KEY <<'END';
Private-key-format: v1.2
Algorithm: 16 (ED448)
PrivateKey: xZ+5Cgm463xugtkY5B0Jx6erFTXp13rYegst0qRtNsOYnaVpMx0Z/c5EiA9x8wWbDDct/U3FhYWA
END
close(KEY);

my $private = new Net::DNS::SEC::Private($keyfile);
ok( $private, 'set up EdDSA private key' );


my $sigdata = 'arbitrary data';		## Note: ED448 signing is deterministic
my $signature = pack 'H*', join '', qw(
		01f546bfe2fd040170133b3797c1c95a31dbb2f216d95f44ced76998f7dc8e16
		8f7082550a83eea4ebeb66e34696249d790db5ba76047ca9002a3dedc10e6d26
		bddc8378ff1a81815aa146e72a0d9672553b2aa5cc38354cbdf2b9c4b8e36a1c
		f7651f828fb64c200e2ee5d0686490910c00
		);

my $signed = eval { Net::DNS::SEC::EdDSA->sign( $sigdata, $private ) } || '';
ok( $signed eq $signature, 'signature created using private key' );


{
	my $verified = Net::DNS::SEC::EdDSA->verify( $sigdata, $key, $signature );
	ok( $verified, 'signature verified using public key' );
}


{
	my $corrupt = 'corrupted data';
	my $verified = Net::DNS::SEC::EdDSA->verify( $corrupt, $key, $signature );
	ok( !$verified, 'signature over corrupt data not verified' );
}

exit;

__END__

