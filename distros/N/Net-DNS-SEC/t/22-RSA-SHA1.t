#!/usr/bin/perl
# $Id: 22-RSA-SHA1.t 1830 2021-01-26 09:08:12Z willem $	-*-perl-*-
#

use strict;
use warnings;
use IO::File;
use Test::More;

my %prerequisite = (
	'Net::DNS::SEC' => 1.15,
	'MIME::Base64'	=> 2.13,
	);

foreach my $package ( sort keys %prerequisite ) {
	my @revision = grep {$_} $prerequisite{$package};
	next if eval "use $package @revision; 1;";		## no critic
	plan skip_all => "missing prerequisite $package @revision";
	exit;
}

plan skip_all => 'disabled RSA'
		unless eval { Net::DNS::SEC::libcrypto->can('EVP_PKEY_new_RSA') };

plan tests => 17;


my %filename;

END {
	foreach ( values %filename ) {
		unlink($_) if -e $_;
	}
}


use_ok('Net::DNS::SEC');
use_ok('Net::DNS::SEC::Private');
use_ok( my $class = 'Net::DNS::SEC::RSA' );


my $key = Net::DNS::RR->new( <<'END' );
RSASHA1.example.	IN	DNSKEY	( 257 3 5
	AwEAAefP0RzK3K39a5wznjeWA1PssI2dxqPb9SL+ppY8wcimOuEBmSJP5n6/bwg923VFlRiYJHe5
	if4saxWCYenQ46hWz44sK943K03tfHkxo54ayAk/7dMj1wQ7Dby5FJ1AAMGZZO65BlKSD+2BTcwp
	IL9mAYuhHYfkG6FTEEKgHVmOVmtyKWA3gl3RrSSgXzTWnUS5b/jEeh2SflXG9eXabaoVXEHQN+oJ
	dTiAiErZW4+Zlx5pIrSycZBpIdWvn4t71L3ik6GctQqG9ln12j2ngji3blVI3ENMnUc237jUeYsy
	k7E5TughQctLYOFXHaeTMgJt0LUTyv3gIgDTRmvgQDU= ) ; Key ID = 4501
END

ok( $key, 'set up RSA public key' );


my $keyfile = $filename{keyfile} = $key->privatekeyname;

my $privatekey = IO::File->new( $keyfile, '>' ) or die qq(open: "$keyfile" $!);
print $privatekey <<'END';
Private-key-format: v1.2
; comment discarded

; empty line discarded
Algorithm: 5 (RSASHA1)
Modulus: 58/RHMrcrf1rnDOeN5YDU+ywjZ3Go9v1Iv6mljzByKY64QGZIk/mfr9vCD3bdUWVGJgkd7mJ/ixrFYJh6dDjqFbPjiwr3jcrTe18eTGjnhrICT/t0yPXBDsNvLkUnUAAwZlk7rkGUpIP7YFNzCkgv2YBi6Edh+QboVMQQqAdWY5Wa3IpYDeCXdGtJKBfNNadRLlv+MR6HZJ+Vcb15dptqhVcQdA36gl1OICIStlbj5mXHmkitLJxkGkh1a+fi3vUveKToZy1Cob2WfXaPaeCOLduVUjcQ0ydRzbfuNR5izKTsTlO6CFBy0tg4Vcdp5MyAm3QtRPK/eAiANNGa+BANQ==
PublicExponent: AQAB
PrivateExponent: qVfDp4j61ZAAAMgkmO7Z14FdKNdNuX6CAeKNx8rytaXZ9W25dLtx4r3uWtL1cyI13RWn7l54VFoWkEwDQ0/6P4vLbE0QbvFWjUMkX1TH9kQSRc+R6WCRPuH1Ex0R1h5fbw6kEVDRMZjKUfLX5oFVDv1xu5Mjg5Y8KQoJIuLdDgHtRRV7ZETcGcSXBQ1eY2rNxui2YzM0mtqzApgGq7pLb3GfiM5aqW5fSdRaFajGC2VIXkN3jZYxAryT8EYJ6uRFJk0X3VegEwj6keHOem/tBV2DaNlv1JWidauPeU67evKNTQVW3h3AbQxnOtegdWrRKoa9Ksf27bgoKAlveHIfsQ==
Prime1: +s1y+iP+AoB4UVS4S5njIZD21AWm36JTaqEvRPdevjuzc9q7yJATROdRdcAitdSPHeRC8xtQw/C9zGhJRdynlxfmUTeyYgM0EYHYiG7PLwkW5Wu9EeXJ7/Fpct51L+ednloQ0d7tYP/5QUd6cqbFGGKH0yF5zZMO0k+ZZ/saeCs=
Prime2: 7J2eVZ5Psue4BTNya8PMA89cC0Gf51zFeQ8dPBZIOpN28DJN2EN6C6fwGtnr6BO+M/6loXzcekPGgRkpNcQ6MzJup8hZQmU8RxESAMlmQzOtaBbtmMwPa0p6IcZBUWpbRaKwQ4ZjAUS9R13PFwgEU+a855o0XRRTupdmyZ6OmR8=
Exponent1: nGakbdMmIx9EaMuhRhwIJTWGhz+jCdDrnhI4LRTqM019oiDke7VFHvH1va18t9F/Ek/3ZC1Dl304jxD1qKhqpnGUAk/uYOrIfKZxhts7PoS3j4g5VsDqxkPQ035gq+gPReG6nXYcqCHYqVnOxVK0lHlVZFd64rTzSDm1W7+eiRM=
Exponent2: evAuKygVGsxghXtEkQ9rOfOMTGDtdyVxiMO8mdKt9plV69kHLz1n9RRtoVXmx28ynQtK/YvFdlUulzb+fWwWHTGv4scq8V9uITKSWwxJcNMx3upCyugDfuh0aoX6vBV5lMXBtWPmnusbOTBZgArvTLSPI/qwCEiedE1j34/dYVs=
Coefficient: JTEzUDflC+G0if7uqsJ2sw/x2aCHMjsCxYSmx2bJOW/nhQTQpzafL0N8E6WmKuEP4qAaqQjWrDyxy0XcAJrfcojJb+a3j2ndxYpev7Rq8f7P6M7qqVL0Nzj9rWFH7pyvWMnH584viuhPcDogy8ymHpNNuAF+w98qjnGD8UECiV4=
END
close($privatekey);

my $private = Net::DNS::SEC::Private->new($keyfile);
ok( $private, 'set up RSA private key' );


my $sigdata = 'arbitrary data';
my $corrupt = 'corrupted data';

my $signature = $class->sign( $sigdata, $private );
ok( $signature, 'signature created using private key' );


my $verified = $class->verify( $sigdata, $key, $signature );
is( $verified, 1, 'signature verified using public key' );


my $verifiable = $class->verify( $corrupt, $key, $signature );
is( $verifiable, 0, 'signature not verifiable if data corrupted' );


# The following tests are not replicated for other RSA/SHA flavours

my $wrongkey = Net::DNS::RR->new( <<'END' );
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

my $handle = IO::File->new( $wrongfile, '>' ) or die qq(open: "$wrongfile" $!);
print $handle <<'END';
Private-key-format: v1.2
Algorithm: 3 (DSA)
Prime(p): x5C6cruWvStVum6/YulcR7MHeujx9c2iBDbo3kW4X8/l+qgk7ZEZ+yV5lphWtJMmMtOHIU+YdAhgLpt84NKhcupWL8wfuBW/97cqIv5Z+51fwn0YEAcZsoCrE0nL5+31VfkK9LTNuVo38hsbWa3eWZFalID5NesF6sJRgXZoAyc=
Subprime(q): wrOwJpPYnLXD+w92mKAQT6dt4n8=
Base(g): gB+OhEFQqtVAZ52h7Jb0g5HW/mdZE2zEOuGVSP7AUV0W6iHA5V1Wbqwkw1eyS/SmcMH3sq0HJ1cmIeZnRz7F26V+TUCb6Kj4L0WVgaT+IaY5AJvVK1G6MPZmjwkNSUNybolOW7ofXIwCPkCMhjLoyi09jrKIEmQ9iBVHImmQS/4=
Private_value(x): vdClrOqZ1qONKg0CZH5hVnq1i40=
Public_value(y): tJ7SCYBS/SpetzOYhgVQKhEZnr6UpWpBDp/ZTsayvrNFt4k34kJUPoEnnbOMtRpZQ8dtqSFlv/Aw7uuhf+2cD/DOgNgEggXvK5FhZuWA9cElMrYGnTvGt7yUoJFvNjgn9VdkXOJmAeByf22Qeet+i/ThQb3OVYR1PpcT/rQeOs8=
END
close($handle);

my $wrongprivate = Net::DNS::SEC::Private->new($wrongfile);
ok( $wrongprivate, 'set up non-RSA private key' );


is( eval { $class->sign( $sigdata, $wrongprivate ) }, undef, 'signature not created using wrong private key' );

is( eval { $class->verify( $sigdata, $wrongkey, $signature ) }, undef, 'verify fails using wrong public key' );

is( eval { $class->verify( $sigdata, $key, undef ) }, undef, 'verify fails if signature undefined' );


# test detection of invalid private key descriptors
eval { Net::DNS::SEC::Private->new('Kinvalid.private') };
my ($exception1) = split /\n/, "$@\n";
ok( $exception1, "invalid keyfile:	[$exception1]" );

eval { Net::DNS::SEC::Private->new('Kinvalid.+0+0.private') };
my ($exception2) = split /\n/, "$@\n";
ok( $exception2, "missing keyfile:	[$exception2]" );

eval { Net::DNS::SEC::Private->new( signame => 'private' ) };
my ($exception3) = split /\n/, "$@\n";
ok( $exception3, "unspecified algorithm:	[$exception3]" );

eval { Net::DNS::SEC::Private->new( algorithm => 1 ) };
my ($exception4) = split /\n/, "$@\n";
ok( $exception4, "unspecified signame:	[$exception4]" );


# exercise code for key with long exponent (not required for DNSSEC)
eval {
	my $longformat = pack 'xn a*', unpack 'C a*', $key->keybin;
	$key->keybin($longformat);
	$class->verify( $sigdata, $key, $signature );
};


exit;

__END__

