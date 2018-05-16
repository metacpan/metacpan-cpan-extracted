# $Id: 51-ECDSA-P256.t 1668 2018-04-23 13:36:44Z willem $	-*-perl-*-
#

use strict;
use Test::More;

my %prerequisite = (
	'Net::DNS::SEC'	=> 1.01,
	'MIME::Base64'	=> 2.13,
	);

foreach my $package ( sort keys %prerequisite ) {
	my @revision = grep $_, $prerequisite{$package};
	next if eval "use $package @revision; 1;";
	plan skip_all => "missing prerequisite $package @revision";
	exit;
}

plan skip_all => 'disabled ECDSA'
		unless eval { Net::DNS::SEC::libcrypto->can('EVP_PKEY_assign_EC_KEY') };

plan tests => 13;


my %filename;

END {
	foreach ( values %filename ) {
		unlink($_) if -e $_;
	}
}


use_ok('Net::DNS::SEC');
use_ok('Net::DNS::SEC::Private');
use_ok('Net::DNS::SEC::ECDSA');


my $key = new Net::DNS::RR <<'END';
ECDSAP256SHA256.example.	IN	DNSKEY	256 3 13 (
	7Y4BZY1g9uzBwt3OZexWk7iWfkiOt0PZ5o7EMip0KBNxlBD+Z58uWutYZIMolsW8v/3rfgac45lO
	IikBZK4KZg== ) ; Key ID = 44222
END

ok( $key, 'set up ECDSA public key' );


my $keyfile = $filename{keyfile} = $key->privatekeyname;

open( KEY, ">$keyfile" ) or die "$keyfile $!";
print KEY <<'END';
Private-key-format: v1.3
Algorithm: 13 (ECDSAP256SHA256)
PrivateKey: m/dWhFblAGQnabJoKbs0vXoQidjNzlTcbPAqntUXWi0=
Created: 20141209020038
Publish: 20141209020038
Activate: 20141209020038
END
close(KEY);

my $private = new Net::DNS::SEC::Private($keyfile);
ok( $private, 'set up ECDSA private key' );


my $wrongkey = new Net::DNS::RR <<'END';
RSASHA1.example.	IN	DNSKEY	256 3 5 (
	AwEAAZHbngk6sMoFHN8fsYY6bmGR4B9UYJIqDp+mORLEH53Xg0f6RMDtfx+H3/x7bHTUikTr26bV
	AqsxOs2KxyJ2Xx9RGG0DB9O4gpANljtTq2tLjvaQknhJpSq9vj4CqUtr6Wu152J2aQYITBoQLHDV
	i8mIIunparIKDmhy8TclVXg9 ; Key ID = 1623
END

ok( $wrongkey, 'set up non-ECDSA public key' );


my $wrongfile = $filename{wrongfile} = $wrongkey->privatekeyname;

open( KEY, ">$wrongfile" ) or die "$wrongfile $!";
print KEY <<'END';
Private-key-format: v1.2
Algorithm: 5 (RSASHA1)
Modulus: kdueCTqwygUc3x+xhjpuYZHgH1RgkioOn6Y5EsQfndeDR/pEwO1/H4ff/HtsdNSKROvbptUCqzE6zYrHInZfH1EYbQMH07iCkA2WO1Ora0uO9pCSeEmlKr2+PgK
pS2vpa7XnYnZpBghMGhAscNWLyYgi6elqsgoOaHLxNyVVeD0=
PublicExponent: AQAB
PrivateExponent: Vd6cuMRDxnuiFr367pJB39FYyDkNrZ9zAoyCt0idcHirglmV1ps7px2AQY2MOW/Tg2Xz59EqBA00mEOmnuRfdRXraqo1mxA9C2qGR2xHltNH2RVR5oT
lahZLRUYZTDuLI7G/3IiPKrf5z/HFm2DkkzuxGqC8hWf9FOni49CqhYE=
Prime1: waSsFnVlQrG/3SGh5GNV5o50PS8gE5L0/+GP2MIjkR3px1zR+LjfkVii1EaTda+Sq7B0ROI+M+R0JLh98Rr6XQ==
Prime2: wNOsL3isJAE89C2XaESsJnm46vPZrqZ4XATub1dwOWNqVOji6KI9yTBc3MfmXkZVmy0I8Rm4ILLh5m/+0LNXYQ==
Exponent1: muRjmptQ4iZYOEOcwZkLrx4nsIEvgTi9rKf6bgHsfTmWNBf1BKSsgBCMPowti6djBN5iQm9OHigRFwZUBzXzKQ==
Exponent2: KE8Xe4T6Vzx7BYBSWlWgtxpS8aqwIrZiCrptLZFVwGlr3PwiEwd3awtVHkIbgjGpy5qKd/wsZYl/d7CJ0A7tgQ==
Coefficient: p9WMT9cDpT7BXcKBXnrMLV8O31ujZ17nwlmlFe3+0n2VCx2T/CSz72xssffn0n2q0DaHHfu9SxR1RLgmDUzVEA==
END
close(KEY);

my $wrongprivate = new Net::DNS::SEC::Private($wrongfile);
ok( $wrongprivate, 'set up non-ECDSA private key' );


my $sigdata = 'arbitrary data';

my $signature = Net::DNS::SEC::ECDSA->sign( $sigdata, $private );
ok( $signature, 'signature created using private key' );


my $verified = Net::DNS::SEC::ECDSA->verify( $sigdata, $key, $signature );
ok( $verified, 'signature verified using public key' );


my $corrupt = 'corrupted data';
my $verifiable = Net::DNS::SEC::ECDSA->verify( $corrupt, $key, $signature );
ok( !$verifiable, 'signature not verifiable if data corrupted' );


ok( !eval { Net::DNS::SEC::ECDSA->sign( $sigdata, $wrongprivate ) },
	'signature not created using wrong private key' );

ok( !eval { Net::DNS::SEC::ECDSA->verify( $sigdata, $wrongkey, $signature ) },
	'signature not verifiable using wrong public key' );

ok( !eval { Net::DNS::SEC::ECDSA->verify( $sigdata, $key, undef ) },
	'verify fails if signature undefined' );

exit;

__END__

