# $Id: 31-DSA-SHA1.t 1494 2016-08-22 09:34:07Z willem $	-*-perl-*-
#

use Test::More;

my %prerequisite = (
	Crypt::OpenSSL::Bignum	=> 0,
	Crypt::OpenSSL::DSA	=> 0,
	Digest::SHA		=> 0,
	Net::DNS		=> 1.01,
	Net::DNS::SEC::Private	=> 0,
	);

foreach my $package ( sort keys %prerequisite ) {
	my @revision = grep $_, $prerequisite{$package};
	eval "use $package @revision";
	next unless $@;
	plan skip_all => "missing prerequisite $package @revision";
	exit;
}

plan tests => 11;


my %filename;

END {
	foreach ( values %filename ) {
		unlink($_) if -e $_;
	}
}


use_ok('Net::DNS');
use_ok('Net::DNS::SEC::Private');
use_ok('Net::DNS::SEC::DSA');


my $key = new Net::DNS::RR <<'END';
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

ok( $key, 'set up DSA public key' );


my $keyfile = $filename{keyfile} = $key->privatekeyname;

open( KEY, ">$keyfile" ) or die "$keyfile $!";
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

my $private = new Net::DNS::SEC::Private($keyfile);
ok( $private, 'set up DSA private key' );


my $wrongkey = new Net::DNS::RR <<'END';
RSAMD5.example. IN	KEY	512 3 1 (
	AwEAAc6K704XNTQYlCPw1R5qBNdPg3SxOdhEWdDFlPdCeeBL1UDSdUG1ijcNkoGCKpFXLaTqeJAH
	+VkXhOGUSvFxIOOmtxb3ubwFf80Up1iKwACNmfCgDlGm8EzGKVoPGcuXkwcxFsQtBoKqT6lWR3at
	6MT/bnuwIIVaD91u1L+/tVw7 ; Key ID = 46428
	)
END

ok( $wrongkey, 'set up non-DSA public key' );


my $wrongfile = $filename{wrongfile} = $wrongkey->privatekeyname;

open( KEY, ">$wrongfile" ) or die "$wrongfile $!";
print KEY <<'END';
Private-key-format: v1.2
Algorithm: 1 (RSA)
Modulus: zorvThc1NBiUI/DVHmoE10+DdLE52ERZ0MWU90J54EvVQNJ1QbWKNw2SgYIqkVctpOp4kAf5WReE4ZRK8XEg46a3Fve5vAV/zRSnWIrAAI2Z8KAOUabwTMYpWg8Zy5eTBzEWxC0GgqpPqVZHdq3oxP9ue7AghVoP3W7Uv7+1XDs=
PublicExponent: AQAB
PrivateExponent: hMPcJddXNMCj4SJ67Az8Rabv+j+9zh3JmiCXrAUIMLyuPPfLtcxLJy5LQYJ5eGmQhpTNoM/vYWxz10kqj17H40ZpAbrfD8/TZtQDnEA2Nzlp3F+qswpmMRih82LzqzpBm0l8lbqnyIRthHfytisG52YWW8pZ0jlBuQb7whO+ajk=
Prime1: 6hj6OPHOP/1AuLiiQo8FcxFyES6WAKvJlcqKX2wb7Gxz6yPfTQlR7WcueEn60r75rF9VAS46qxa3XIsvBuETJw==
Prime2: 4d35IrQ/bVCtdQ7A9DyUNmOVtS6bPCJBEVLI+M6dmj1icGJiiwNdCXbX3uaOG0SEh2/oXGBbw9wX8D1xDWqKzQ==
Exponent1: FvM17Mk/+CQC6Vkohy/wT9ShAzA3An/U9ntxz2MQ5b/IKYBNzwaf4o9gDejqzyhr38tE0SXQGJ/UgB0hEiKUtw==
Exponent2: KEOs3Q3q3K7sLRjzNtbxyPxZvNHRJJgqp07tusUCfXOB7+zqCkQQOtavxvGs1ZmSUp6VeppG4ZSDw/UACVc75Q==
Coefficient: QIVRcEFrFbmhJntBjCZOgJ4tKaiJJ3s4J97RMR6xQ1pLVwlOKKozJbjVx2tZyb11/UQliVTHlgrqYGL/oWBMKw==
END
close(KEY);

my $wrongprivate = new Net::DNS::SEC::Private($wrongfile);
ok( $wrongprivate, 'set up non-DSA private key' );


my $sigdata = 'arbitrary data';

my $signature = Net::DNS::SEC::DSA->sign( $sigdata, $private );
ok( $signature, 'signature generated using private key' );

my $validated = Net::DNS::SEC::DSA->verify( $sigdata, $key, $signature );
ok( $validated, 'signature validated using public key' );


ok( !eval { Net::DNS::SEC::DSA->sign( $sigdata, $wrongprivate ) },
	'signature not generated using wrong private key' );

ok( !eval { Net::DNS::SEC::DSA->verify( $sigdata, $wrongkey, $signature ) },
	'signature not validated using wrong public key' );


exit;

__END__

