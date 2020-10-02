#!/usr/bin/perl
# $Id: 61-Ed25519.t 1808 2020-09-28 22:08:11Z willem $	-*-perl-*-
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

plan tests => 13;


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
ED25519.example.	IN	DNSKEY	( 257 3 15
	l02Woi0iS8Aa25FQkUd9RMzZHJpBoRQwAQEX1SxZJA4= ) ; Key ID = 3613
END

ok( $key, 'set up EdDSA public key' );


my $keyfile = $filename{keyfile} = $key->privatekeyname;

my $privatekey = IO::File->new( $keyfile, '>' ) or die qq(open: "$keyfile" $!);
print $privatekey <<'END';
Private-key-format: v1.2
Algorithm: 15 (ED25519)
PrivateKey: ODIyNjAzODQ2MjgwODAxMjI2NDUxOTAyMDQxNDIyNjI=
END
close($privatekey);

my $private = Net::DNS::SEC::Private->new($keyfile);
ok( $private, 'set up EdDSA private key' );


my $wrongkey = Net::DNS::RR->new( <<'END' );
ECDSAP256SHA256.example.	IN	DNSKEY	256 3 13 (
	7Y4BZY1g9uzBwt3OZexWk7iWfkiOt0PZ5o7EMip0KBNxlBD+Z58uWutYZIMolsW8v/3rfgac45lO
	IikBZK4KZg== ; Key ID = 44222
	)
END

ok( $wrongkey, 'set up non-EdDSA public key' );


my $wrongfile = $filename{wrongfile} = $wrongkey->privatekeyname;

my $handle = IO::File->new( $wrongfile, '>' ) or die qq(open: "$wrongfile" $!);
print $handle <<'END';
Private-key-format: v1.2
Algorithm: 13 (ECDSAP256SHA256)
PrivateKey: m/dWhFblAGQnabJoKbs0vXoQidjNzlTcbPAqntUXWi0=
END
close($handle);

my $wrongprivate = Net::DNS::SEC::Private->new($wrongfile);
ok( $wrongprivate, 'set up non-EdDSA private key' );


my $sigdata = 'arbitrary data';		## Note: ED25519 signing is deterministic
my $corrupt = 'corrupted data';

my $signature = pack 'H*', join '', qw(
		cb7a60fedc08b09995d522410962c6eb0fd0ea34e16fe094c99582fbb14e7a87
		c14292cf8c28af0efe6ee30cbf9d643cba3ab56f1e1ae27b6074147ed9c55a0e
		);

my $signed = eval { $class->sign( $sigdata, $private ); } || '';
ok( $signed eq $signature, 'signature created using private key' );


my $verified = $class->verify( $sigdata, $key, $signature );
is( $verified, 1, 'signature verified using public key' );


my $verifiable = $class->verify( $corrupt, $key, $signature );
is( $verifiable, 0, 'signature not verifiable if data corrupted' );


is( eval { $class->sign( $sigdata, $wrongprivate ) }, undef, 'signature not created using wrong private key' );

is( eval { $class->verify( $sigdata, $wrongkey, $signature ) }, undef, 'verify fails using wrong public key' );

is( eval { $class->verify( $sigdata, $key, undef ) }, undef, 'verify fails if signature undefined' );

exit;

__END__

