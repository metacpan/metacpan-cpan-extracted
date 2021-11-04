#!/usr/bin/perl
# $Id: 51-ECDSA-P256.t 1830 2021-01-26 09:08:12Z willem $	-*-perl-*-
#

use strict;
use warnings;
use IO::File;
use Test::More;

my %prerequisite = (
	'Net::DNS::SEC' => 1.01,
	'MIME::Base64'	=> 2.13,
	);

foreach my $package ( sort keys %prerequisite ) {
	my @revision = grep {$_} $prerequisite{$package};
	next if eval "use $package @revision; 1;";		## no critic
	plan skip_all => "missing prerequisite $package @revision";
	exit;
}

plan skip_all => 'disabled ECDSA'
		unless eval { Net::DNS::SEC::libcrypto->can('EVP_PKEY_new_ECDSA') };

plan tests => 13;


my %filename;

END {
	foreach ( values %filename ) {
		unlink($_) if -e $_;
	}
}


use_ok('Net::DNS::SEC');
use_ok('Net::DNS::SEC::Private');
use_ok( my $class = 'Net::DNS::SEC::ECDSA' );


my $key = Net::DNS::RR->new( <<'END' );
ECDSAP256SHA256.example.	IN	DNSKEY	( 257 3 13
	IYHbvpnqrhxM4i0SuOyAq9hk19tNXpjja7jCQnfAjZBFBfcLorJPnq4FWMVDg6QT2C4JeW0yCxK4
	iEhb4w9KWQ== ) ; Key ID = 27566
END

ok( $key, 'set up ECDSA public key' );


my $keyfile = $filename{keyfile} = $key->privatekeyname;

my $privatekey = IO::File->new( $keyfile, '>' ) or die qq(open: "$keyfile" $!);
print $privatekey <<'END';
Private-key-format: v1.3
Algorithm: 13 (ECDSAP256SHA256)
PrivateKey: w+AjPo650IA8DWeEq5QqZ2LWYpuC/oeEaYaGE1ZvKyA=
Created: 20141209015301
Publish: 20141209015301
Activate: 20141209015301
END
close($privatekey);

my $private = Net::DNS::SEC::Private->new($keyfile);
ok( $private, 'set up ECDSA private key' );


my $wrongkey = Net::DNS::RR->new( <<'END' );
RSASHA1.example.	IN	DNSKEY	( 256 3 5
	AwEAAZHbngk6sMoFHN8fsYY6bmGR4B9UYJIqDp+mORLEH53Xg0f6RMDtfx+H3/x7bHTUikTr26bV
	AqsxOs2KxyJ2Xx9RGG0DB9O4gpANljtTq2tLjvaQknhJpSq9vj4CqUtr6Wu152J2aQYITBoQLHDV
	i8mIIunparIKDmhy8TclVXg9 ) ; Key ID = 1623
END

ok( $wrongkey, 'set up non-ECDSA public key' );


my $wrongfile = $filename{wrongfile} = $wrongkey->privatekeyname;

my $handle = IO::File->new( $wrongfile, '>' ) or die qq(open: "$wrongfile" $!);
print $handle <<'END';
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
close($handle);

my $wrongprivate = Net::DNS::SEC::Private->new($wrongfile);
ok( $wrongprivate, 'set up non-ECDSA private key' );


my $sigdata = 'arbitrary data';
my $corrupt = 'corrupted data';

my $signature = $class->sign( $sigdata, $private );
ok( $signature, 'signature created using private key' );


my $verified = $class->verify( $sigdata, $key, $signature );
is( $verified, 1, 'signature verified using public key' );


my $verifiable = $class->verify( $corrupt, $key, $signature );
is( $verifiable, 0, 'signature not verifiable if data corrupted' );


is( eval { $class->sign( $sigdata, $wrongprivate ) }, undef, 'signature not created using wrong private key' );

is( eval { $class->verify( $sigdata, $wrongkey, $signature ) }, undef, 'verify fails using wrong public key' );

is( eval { $class->verify( $sigdata, $key, undef ) }, undef, 'verify fails if signature undefined' );

exit;

__END__

