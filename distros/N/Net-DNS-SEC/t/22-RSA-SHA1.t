#!/usr/bin/perl
# $Id: 22-RSA-SHA1.t 1937 2023-09-11 09:27:16Z willem $	-*-perl-*-
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
	next if eval "use $package @revision; 1;";	## no critic
	plan skip_all => "missing prerequisite $package @revision";
	exit;
}

plan skip_all => 'disabled RSA'
		unless eval { Net::DNS::SEC::libcrypto->can('EVP_PKEY_new_RSA') };

plan skip_all => 'disabled SHA1'
		unless eval { Net::DNS::SEC::libcrypto->can('EVP_sha1') };

plan tests => 8;


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


my $sigdata = Net::DNS::RR->new('. TXT arbitrary data')->txtdata;    # character set independent
my $corrupt = 'corrupted data';

my $signature = $class->sign( $sigdata, $private );
ok( $signature, 'signature created using private key' );


my $verified = $class->verify( $sigdata, $key, $signature );
is( $verified, 1, 'signature verified using public key' );


my $verifiable = $class->verify( $corrupt, $key, $signature );
is( $verifiable, 0, 'signature not verifiable if data corrupted' );


exit;

__END__

