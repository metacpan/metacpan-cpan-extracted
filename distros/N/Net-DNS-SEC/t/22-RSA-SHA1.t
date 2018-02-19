# $Id: 22-RSA-SHA1.t 1619 2018-01-24 08:24:17Z willem $	-*-perl-*-
#

use strict;
use Test::More;

my %prerequisite = (
	'Digest::SHA'  => 5.23,
	'Net::DNS'     => 1.01,
	'MIME::Base64' => 2.13,
	);

foreach my $package ( sort keys %prerequisite ) {
	my @revision = grep $_, $prerequisite{$package};
	next if eval "use $package @revision; 1;";
	plan skip_all => "missing prerequisite $package @revision";
	exit;
}

plan tests => 17;


my %filename;

END {
	foreach ( values %filename ) {
		unlink($_) if -e $_;
	}
}


use_ok('Net::DNS::SEC');
use_ok('Net::DNS::SEC::Private');
use_ok('Net::DNS::SEC::RSA');


my $key = new Net::DNS::RR <<'END';
RSASHA1.example.	IN	DNSKEY	256 3 5 (
	AwEAAZHbngk6sMoFHN8fsYY6bmGR4B9UYJIqDp+mORLEH53Xg0f6RMDtfx+H3/x7bHTUikTr26bV
	AqsxOs2KxyJ2Xx9RGG0DB9O4gpANljtTq2tLjvaQknhJpSq9vj4CqUtr6Wu152J2aQYITBoQLHDV
	i8mIIunparIKDmhy8TclVXg9 ; Key ID = 1623
	)
END

ok( $key, 'set up RSA public key' );


my $keyfile = $filename{keyfile} = $key->privatekeyname;

open( KEY, ">$keyfile" ) or die "$keyfile $!";
print KEY <<'END';
Private-key-format: v1.2
; comment discarded

; empty line discarded
Algorithm: 5 (RSASHA1)
Modulus: kdueCTqwygUc3x+xhjpuYZHgH1RgkioOn6Y5EsQfndeDR/pEwO1/H4ff/HtsdNSKROvbptUCqzE6zYrHInZfH1EYbQMH07iCkA2WO1Ora0uO9pCSeEmlKr2+PgKpS2vpa7XnYnZpBghMGhAscNWLyYgi6elqsgoOaHLxNyVVeD0=
PublicExponent: AQAB
PrivateExponent: Vd6cuMRDxnuiFr367pJB39FYyDkNrZ9zAoyCt0idcHirglmV1ps7px2AQY2MOW/Tg2Xz59EqBA00mEOmnuRfdRXraqo1mxA9C2qGR2xHltNH2RVR5oTlahZLRUYZTDuLI7G/3IiPKrf5z/HFm2DkkzuxGqC8hWf9FOni49CqhYE=
Prime1: waSsFnVlQrG/3SGh5GNV5o50PS8gE5L0/+GP2MIjkR3px1zR+LjfkVii1EaTda+Sq7B0ROI+M+R0JLh98Rr6XQ==
Prime2: wNOsL3isJAE89C2XaESsJnm46vPZrqZ4XATub1dwOWNqVOji6KI9yTBc3MfmXkZVmy0I8Rm4ILLh5m/+0LNXYQ==
Exponent1: muRjmptQ4iZYOEOcwZkLrx4nsIEvgTi9rKf6bgHsfTmWNBf1BKSsgBCMPowti6djBN5iQm9OHigRFwZUBzXzKQ==
Exponent2: KE8Xe4T6Vzx7BYBSWlWgtxpS8aqwIrZiCrptLZFVwGlr3PwiEwd3awtVHkIbgjGpy5qKd/wsZYl/d7CJ0A7tgQ==
Coefficient: p9WMT9cDpT7BXcKBXnrMLV8O31ujZ17nwlmlFe3+0n2VCx2T/CSz72xssffn0n2q0DaHHfu9SxR1RLgmDUzVEA==
END
close(KEY);

my $private = new Net::DNS::SEC::Private($keyfile);
ok( $private, 'set up RSA private key' );


my $sigdata = 'arbitrary data';

my $signature = Net::DNS::SEC::RSA->sign( $sigdata, $private );
ok( $signature, 'signature created using private key' );


my $verified = Net::DNS::SEC::RSA->verify( $sigdata, $key, $signature );
ok( $verified, 'signature verified using public key' );


# The following tests are not replicated for other RSA/SHA flavours

my $wrongkey = new Net::DNS::RR <<'END';
DSA.example.	IN	DNSKEY	256 3 3 (
	CMKzsCaT2Jy1w/sPdpigEE+nbeJ/x5C6cruWvStVum6/YulcR7MHeujx9c2iBDbo3kW4X8/l+qgk
	7ZEZ+yV5lphWtJMmMtOHIU+YdAhgLpt84NKhcupWL8wfuBW/97cqIv5Z+51fwn0YEAcZsoCrE0nL
	5+31VfkK9LTNuVo38hsbWa3eWZFalID5NesF6sJRgXZoAyeAH46EQVCq1UBnnaHslvSDkdb+Z1kT
	bMQ64ZVI/sBRXRbqIcDlXVZurCTDV7JL9KZwwfeyrQcnVyYh5mdHPsXbpX5NQJvoqPgvRZWBpP4h
	pjkAm9UrUbow9maPCQ1JQ3JuiU5buh9cjAI+QIyGMujKLT2OsogSZD2IFUciaZBL/rSe0gmAUv0q
	XrczmIYFUCoRGZ6+lKVqQQ6f2U7Gsr6zRbeJN+JCVD6BJ52zjLUaWUPHbakhZb/wMO7roX/tnA/w
	zoDYBIIF7yuRYWblgPXBJTK2Bp07xre8lKCRbzY4J/VXZFziZgHgcn9tkHnrfov04UG9zlWEdT6X
	E/60HjrP ; Key ID = 53244
	)
END

ok( $wrongkey, 'set up non-RSA public key' );


my $wrongfile = $filename{wrongfile} = $wrongkey->privatekeyname;

open( KEY, ">$wrongfile" ) or die "$wrongfile $!";
print KEY <<'END';
Private-key-format: v1.2
Algorithm: 3 (DSA)
Prime(p): x5C6cruWvStVum6/YulcR7MHeujx9c2iBDbo3kW4X8/l+qgk7ZEZ+yV5lphWtJMmMtOHIU+YdAhgLpt84NKhcupWL8wfuBW/97cqIv5Z+51fwn0YEAcZsoCrE0nL5+31VfkK9LTNuVo38hsbWa3eWZFalID5NesF6sJRgXZoAyc=
Subprime(q): wrOwJpPYnLXD+w92mKAQT6dt4n8=
Base(g): gB+OhEFQqtVAZ52h7Jb0g5HW/mdZE2zEOuGVSP7AUV0W6iHA5V1Wbqwkw1eyS/SmcMH3sq0HJ1cmIeZnRz7F26V+TUCb6Kj4L0WVgaT+IaY5AJvVK1G6MPZmjwkNSUNybolOW7ofXIwCPkCMhjLoyi09jrKIEmQ9iBVHImmQS/4=
Private_value(x): vdClrOqZ1qONKg0CZH5hVnq1i40=
Public_value(y): tJ7SCYBS/SpetzOYhgVQKhEZnr6UpWpBDp/ZTsayvrNFt4k34kJUPoEnnbOMtRpZQ8dtqSFlv/Aw7uuhf+2cD/DOgNgEggXvK5FhZuWA9cElMrYGnTvGt7yUoJFvNjgn9VdkXOJmAeByf22Qeet+i/ThQb3OVYR1PpcT/rQeOs8=
END
close(KEY);

my $wrongprivate = new Net::DNS::SEC::Private($wrongfile);
ok( $wrongprivate, 'set up non-RSA private key' );


ok( !eval { Net::DNS::SEC::RSA->sign( $sigdata, $wrongprivate ) },
	'signature not created using wrong private key' );

ok( !eval { Net::DNS::SEC::RSA->verify( $sigdata, $wrongkey, $signature ) },
	'signature not verified using wrong public key' );

ok( !eval { Net::DNS::SEC::RSA->verify( $sigdata, $key, undef ) },
	'signature not verified if empty or not defined' );


# test detection of invalid private key descriptors
my $invalid1 = eval { Net::DNS::SEC::Private->new('Kinvalid.private') };
chomp $@;
is( $invalid1, undef, "invalid keyfile:	[$@]" );

my $invalid2 = eval { Net::DNS::SEC::Private->new('Kinvalid.+0+0.private') };
chomp $@;
is( $invalid2, undef, "missing keyfile:	[$@]" );

my $invalid3 = eval { Net::DNS::SEC::Private->new( signame => 'private' ) };
chomp $@;
is( $invalid3, undef, "undef algorithm:	[$@]" );

my $invalid4 = eval { Net::DNS::SEC::Private->new( algorithm => 1 ) };
chomp $@;
is( $invalid4, undef, "undef signame:	[$@]" );


# exercise code for key with long exponent (not required for DNSSEC)
eval {
	my $longformat = pack 'xn a*', unpack 'C a*', $key->keybin;
	$key->keybin($longformat);
	Net::DNS::SEC::RSA->verify( $sigdata, $key, $signature );
};


# test coverage only for RSA key generation
eval {
	local $SIG{__WARN__} = sub { };
	my $private = Net::DNS::SEC::Private->generate_rsa(qw(domain 256 1024));
};

eval {
	local $SIG{__WARN__} = sub { };
	my $keyblob = '';
	my $private = Net::DNS::SEC::Private->new_rsa_priv( $keyblob, qw(domain 256 1024) );
};


# test coverage only for deprecated dump_rsa_??? warning
eval {
	local $SIG{__WARN__} = sub { };
	$private->dump_rsa_keytag;
};


is( $private->DESTROY, undef, 'DESTROY() required to defeat pre-5.18 AUTOLOAD' );


exit;

__END__

