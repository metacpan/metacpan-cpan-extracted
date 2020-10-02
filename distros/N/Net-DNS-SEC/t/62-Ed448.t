#!/usr/bin/perl
# $Id: 62-Ed448.t 1808 2020-09-28 22:08:11Z willem $	-*-perl-*-
#

use strict;
use warnings;
use IO::File;
use Test::More;

my %prerequisite = (
	'Net::DNS::SEC' => 1.05,
	'MIME::Base64'	=> 2.13,
	);

foreach my $package ( sort keys %prerequisite ) {
	my @revision = grep {$_} $prerequisite{$package};
	next if eval "use $package @revision; 1;";		## no critic
	plan skip_all => "missing prerequisite $package @revision";
	exit;
}

plan skip_all => "disabled EdDSA"
		unless eval { Net::DNS::SEC::libcrypto->can('EVP_PKEY_new_raw_private_key') };

plan tests => 8;


my %filename;

END {
	foreach ( values %filename ) {
		unlink($_) if -e $_;
	}
}


use_ok('Net::DNS::SEC');
use_ok('Net::DNS::SEC::Private');
use_ok( my $class = 'Net::DNS::SEC::EdDSA' );


#	Specimen private and public keys taken from RFC8080

my $key = Net::DNS::RR->new( <<'END' );
ED448.example.com.	IN	DNSKEY	( 257 3 16
	3kgROaDjrh0H2iuixWBrc8g2EpBBLCdGzHmn+G2MpTPhpj/OiBVHHSfPodx1FYYUcJKm1MDpJtIA )
	; Key ID = 9713
END

ok( $key, 'set up EdDSA public key' );


my $keyfile = $filename{keyfile} = $key->privatekeyname;

my $privatekey = IO::File->new( $keyfile, '>' ) or die qq(open: "$keyfile" $!);
print $privatekey <<'END';
Private-key-format: v1.2
Algorithm: 16 (ED448)
PrivateKey: xZ+5Cgm463xugtkY5B0Jx6erFTXp13rYegst0qRtNsOYnaVpMx0Z/c5EiA9x8wWbDDct/U3FhYWA
END
close($privatekey);

my $private = Net::DNS::SEC::Private->new($keyfile);
ok( $private, 'set up EdDSA private key' );


my $sigdata = 'arbitrary data';		## Note: ED448 signing is deterministic
my $corrupt = 'corrupted data';

my $signature = pack 'H*', join '', qw(
		01f546bfe2fd040170133b3797c1c95a31dbb2f216d95f44ced76998f7dc8e16
		8f7082550a83eea4ebeb66e34696249d790db5ba76047ca9002a3dedc10e6d26
		bddc8378ff1a81815aa146e72a0d9672553b2aa5cc38354cbdf2b9c4b8e36a1c
		f7651f828fb64c200e2ee5d0686490910c00
		);

my $signed = eval { $class->sign( $sigdata, $private ) } || '';
ok( $signed eq $signature, 'signature created using private key' );


my $verified = $class->verify( $sigdata, $key, $signature );
is( $verified, 1, 'signature verified using public key' );


my $verifiable = $class->verify( $corrupt, $key, $signature );
is( $verifiable, 0, 'signature not verifiable if data corrupt' );


exit;

__END__

