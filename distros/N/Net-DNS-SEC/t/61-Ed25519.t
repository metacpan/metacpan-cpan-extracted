# $Id: 61-Ed25519.t 1668 2018-04-23 13:36:44Z willem $	-*-perl-*-
#

use strict;
use Test::More;

my %prerequisite = (
	'Net::DNS::SEC' => 1.05,
	'MIME::Base64'	=> 2.13,
	);

foreach my $package ( sort keys %prerequisite ) {
	my @revision = grep $_, $prerequisite{$package};
	next if eval "use $package @revision; 1;";
	plan skip_all => "missing prerequisite $package @revision";
	exit;
}

plan skip_all => "disabled EdDSA"
		unless eval { Net::DNS::SEC::libcrypto->can('EVP_PKEY_new_raw_private_key') };

plan tests => 13;


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
ED25519.example.	IN	DNSKEY	( 257 3 15
	l02Woi0iS8Aa25FQkUd9RMzZHJpBoRQwAQEX1SxZJA4= ) ; Key ID = 3613
END

ok( $key, 'set up EdDSA public key' );


my $keyfile = $filename{keyfile} = $key->privatekeyname;

open( KEY, ">$keyfile" ) or die "$keyfile $!";
print KEY <<'END';
Private-key-format: v1.2
Algorithm: 15 (ED25519)
PrivateKey: ODIyNjAzODQ2MjgwODAxMjI2NDUxOTAyMDQxNDIyNjI=
END
close(KEY);

my $private = new Net::DNS::SEC::Private($keyfile);
ok( $private, 'set up EdDSA private key' );


my $wrongkey = new Net::DNS::RR <<'END';
ECDSAP256SHA256.example.	IN	DNSKEY	256 3 13 (
	7Y4BZY1g9uzBwt3OZexWk7iWfkiOt0PZ5o7EMip0KBNxlBD+Z58uWutYZIMolsW8v/3rfgac45lO
	IikBZK4KZg== ; Key ID = 44222
	)
END

ok( $wrongkey, 'set up non-EdDSA public key' );


my $wrongfile = $filename{wrongfile} = $wrongkey->privatekeyname;

open( KEY, ">$wrongfile" ) or die "$wrongfile $!";
print KEY <<'END';
Private-key-format: v1.2
Algorithm: 13 (ECDSAP256SHA256)
PrivateKey: m/dWhFblAGQnabJoKbs0vXoQidjNzlTcbPAqntUXWi0=
END
close(KEY);

my $wrongprivate = new Net::DNS::SEC::Private($wrongfile);
ok( $wrongprivate, 'set up non-EdDSA private key' );


my $sigdata = 'arbitrary data';		## Note: ED25519 signing is deterministic
my $signature = pack 'H*', join '', qw(
		cb7a60fedc08b09995d522410962c6eb0fd0ea34e16fe094c99582fbb14e7a87
		c14292cf8c28af0efe6ee30cbf9d643cba3ab56f1e1ae27b6074147ed9c55a0e
		);

my $signed = eval { Net::DNS::SEC::EdDSA->sign( $sigdata, $private ); } || '';
ok( $signed eq $signature, 'signature created using private key' );


my $verified = Net::DNS::SEC::EdDSA->verify( $sigdata, $key, $signature );
ok( $verified, 'signature verified using public key' );


my $corrupt = 'corrupted data';
my $verifiable = Net::DNS::SEC::EdDSA->verify( $corrupt, $key, $signature );
ok( !$verifiable, 'signature not verifiable if data corrupted' );


ok( !eval { Net::DNS::SEC::EdDSA->sign( $sigdata, $wrongprivate ) },
	'signature not created using wrong private key' );

ok( !eval { Net::DNS::SEC::EdDSA->verify( $sigdata, $wrongkey, $signature ) },
	'signature not verifiable using wrong public key' );

ok( !eval { Net::DNS::SEC::EdDSA->verify( $sigdata, $key, undef ) },
	'verify fails if signature undefined' );

exit;

__END__

