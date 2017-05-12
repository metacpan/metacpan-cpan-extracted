# $Id: 65-RRSIG-RSASHA1.t 1392 2015-09-13 16:30:51Z willem $	-*-perl-*-
#

use strict;
use Test::More;

my @prerequisite = qw(
		MIME::Base64
		Time::Local
		Net::DNS::RR::RRSIG
		Net::DNS::SEC
		Net::DNS::SEC::RSA
		Crypt::OpenSSL::Bignum
		Crypt::OpenSSL::RSA
		);

foreach my $package (@prerequisite) {
	next if eval "require $package";
	plan skip_all => "$package not installed";
	exit;
}

plan tests => 30;

use_ok('Net::DNS::SEC');


my $ksk = new Net::DNS::RR <<'END';
RSASHA1.example.	IN	DNSKEY	257 3 5 (
	AwEAAefP0RzK3K39a5wznjeWA1PssI2dxqPb9SL+ppY8wcimOuEBmSJP5n6/bwg923VFlRiYJHe5
	if4saxWCYenQ46hWz44sK943K03tfHkxo54ayAk/7dMj1wQ7Dby5FJ1AAMGZZO65BlKSD+2BTcwp
	IL9mAYuhHYfkG6FTEEKgHVmOVmtyKWA3gl3RrSSgXzTWnUS5b/jEeh2SflXG9eXabaoVXEHQN+oJ
	dTiAiErZW4+Zlx5pIrSycZBpIdWvn4t71L3ik6GctQqG9ln12j2ngji3blVI3ENMnUc237jUeYsy
	k7E5TughQctLYOFXHaeTMgJt0LUTyv3gIgDTRmvgQDU= ; Key ID = 4501
	)
END

ok( $ksk, 'set up RSA public ksk' );


my $keyfile = $ksk->privatekeyname;

END { unlink($keyfile) if defined $keyfile; }

open( KSK, ">$keyfile" ) or die "$keyfile $!";
print KSK <<'END';
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
close(KSK);


my $bad1 = new Net::DNS::RR <<'END';
RSASHA1.example.	IN	DNSKEY	256 3 5 (
	AwEAAZHbngk6sMoFHN8fsYY6bmGR4B9UYJIqDp+mORLEH53Xg0f6RMDtfx+H3/x7bHTUikTr26bV
	AqsxOs2KxyJ2Xx9RGG0DB9O4gpANljtTq2tLjvaQknhJpSq9vj4CqUtr6Wu152J2aQYITBoQLHDV
	i8mIIunparIKDmhy8TclVXg9 ; Key ID = 1623
	)
END


my $bad2 = new Net::DNS::RR <<'END';
ECDSAP256SHA256.example.	IN	DNSKEY	( 256 3 13
	7Y4BZY1g9uzBwt3OZexWk7iWfkiOt0PZ5o7EMip0KBNxlBD+Z58uWutYZIMolsW8v/3rfgac45lO
	IikBZK4KZg== ; Key ID = 44222
	)
END


my @rrset = ( $bad1, $ksk );
my @badrrset = ($bad1);

{
	my $object = create Net::DNS::RR::RRSIG( \@rrset, $keyfile );
	ok( $object->sig(), 'create RRSIG over rrset using private ksk' );

	my $verified = $object->verify( \@rrset, $ksk );
	ok( $verified, 'verify using public ksk' );
	is( $object->vrfyerrstr, '', 'observe no object->vrfyerrstr' );
}


{
	my $object = create Net::DNS::RR::RRSIG( \@rrset, $keyfile );

	my $verified = $object->verify( \@badrrset, $bad1 );
	ok( !$verified,		 'verify fails using wrong key' );
	ok( $object->vrfyerrstr, 'observe rrsig->vrfyerrstr' );
}


{
	my $object = create Net::DNS::RR::RRSIG( \@rrset, $keyfile );

	my $verified = $object->verify( \@badrrset, $bad2 );
	ok( !$verified,		 'verify fails using key with wrong algorithm' );
	ok( $object->vrfyerrstr, 'observe rrsig->vrfyerrstr' );
}


{
	my $object = create Net::DNS::RR::RRSIG( \@rrset, $keyfile );

	my $verified = $object->verify( \@rrset, [$bad1, $bad2, $ksk] );
	ok( $verified, 'verify using array of keys' );
	is( $object->vrfyerrstr, '', 'observe no rrsig->vrfyerrstr' );
}


{
	my $object = create Net::DNS::RR::RRSIG( \@rrset, $keyfile );

	my $verified = $object->verify( \@badrrset, [$bad1, $bad2, $ksk] );
	ok( !$verified,		 'verify fails using wrong rrset' );
	ok( $object->vrfyerrstr, 'observe rrsig->vrfyerrstr' );
}


{
	my $wild   = new Net::DNS::RR('*.example. A 10.1.2.3');
	my $match  = new Net::DNS::RR('leaf.twig.example. A 10.1.2.3');
	my $object = create Net::DNS::RR::RRSIG( [$wild], $keyfile );

	my $verified = $object->verify( [$match], $ksk );
	ok( $verified, 'wildcard matches child domain name' );
	is( $object->vrfyerrstr, '', 'observe no rrsig->vrfyerrstr' );
}


{
	my $wild   = new Net::DNS::RR('*.example. A 10.1.2.3');
	my $bogus  = new Net::DNS::RR('example. A 10.1.2.3');
	my $object = create Net::DNS::RR::RRSIG( [$wild], $keyfile );

	my $verified = $object->verify( [$bogus], $ksk );
	ok( !$verified,		 'wildcard does not match parent domain' );
	ok( $object->vrfyerrstr, 'observe rrsig->vrfyerrstr' );
}


{
	my $time = time() + 3;
	my %args = (
		siginception  => $time,
		sigexpiration => $time,
		);
	my $object = create Net::DNS::RR::RRSIG( \@rrset, $keyfile, %args );

	ok( !$object->verify( \@rrset, $ksk ), 'verify fails for postdated RRSIG' );
	ok( $object->vrfyerrstr, 'observe rrsig->vrfyerrstr' );
	sleep 1 until $time < time();
	ok( !$object->verify( \@rrset, $ksk ), 'verify fails for expired RRSIG' );
	ok( $object->vrfyerrstr, 'observe rrsig->vrfyerrstr' );
}


{
	my $object   = new Net::DNS::RR( type => 'RRSIG' );
	my $class    = ref($object);
	my $array    = [];
	my $dnskey   = new Net::DNS::RR( type => 'DNSKEY' );
	my $private  = new Net::DNS::SEC::Private($keyfile);
	my $packet   = new Net::DNS::Packet();
	my $rr1	     = new Net::DNS::RR( name => 'example', type => 'A' );
	my $rr2	     = new Net::DNS::RR( name => 'differs', type => 'A' );
	my $rr3	     = new Net::DNS::RR( type => 'A', ttl => 1 );
	my $rr4	     = new Net::DNS::RR( type => 'A', ttl => 2 );
	my $rr5	     = new Net::DNS::RR( class => 'IN', type => 'A' );
	my $rr6	     = new Net::DNS::RR( class => 'ANY', type => 'A' );
	my $rr7	     = new Net::DNS::RR( type => 'A' );
	my $rr8	     = new Net::DNS::RR( type => 'AAAA' );
	my @testcase = (		## test create() with invalid arguments
		[$dnskey, $dnskey],
		[$array,  $private],
		[[$rr1, $rr2], $private],
		[[$rr3, $rr4], $private],
		[[$rr5, $rr6], $private],
		[[$rr7, $rr8], $private],
		);

	foreach my $arglist (@testcase) {
		my @argtype = map ref($_), @$arglist;
		eval { $class->create(@$arglist); };
		my $exception = $1 if $@ =~ /^(.*)\n*/;
		ok( defined $exception, "create(@argtype)\t[$exception]" );
	}
}


{
	my $object   = new Net::DNS::RR( type => 'RRSIG' );
	my $packet   = new Net::DNS::Packet();
	my $dnskey   = new Net::DNS::RR( type => 'DNSKEY' );
	my $dsrec    = new Net::DNS::RR( type => 'DS' );
	my $scalar   = 'SCALAR';
	my @testcase = (		## test verify() with invalid arguments
		[$packet, $dnskey],
		[$dnskey, $dsrec],
		[$dnskey, $scalar],
		);

	foreach my $arglist (@testcase) {
		my @argtype = map ref($_) || $_, @$arglist;
		eval { $object->verify(@$arglist); };
		my $exception = $1 if $@ =~ /^(.*)\n*/;
		ok( defined $exception, "verify(@argtype)\t[$exception]" );
	}
}


exit;

__END__

