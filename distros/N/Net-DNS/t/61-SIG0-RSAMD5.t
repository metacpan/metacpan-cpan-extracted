# $Id: 61-SIG0-RSAMD5.t 1385 2015-09-03 06:13:24Z willem $	-*-perl-*-
#

use strict;
use Test::More;

my @prerequisite = qw(
		MIME::Base64
		Time::Local
		Net::DNS::RR::SIG
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

plan tests => 29;

use_ok('Net::DNS::SEC');


my $key = new Net::DNS::RR <<'END';
RSAMD5.example.		IN	KEY	512 3 1 (
	AwEAAcUHtdNvhdBKMkUle+MJ+ntJ148yfsITtZC0g93EguURfU113BQVk6tzgXP/aXs4OptkCgrL
	sTapAZr5+vQ8jNbLp/uUTqEUzBRMBqi0W78B3aEb7vEsC0FB6VLoCcjylDcKzzWHm4rj1ACN2Zbu
	6eT88lDYHTPiGQskw5LGCze7 ; Key ID = 2871
	)
END

ok( $key, 'set up RSA public key' );


my $keyfile = $key->privatekeyname;

END { unlink($keyfile) if defined $keyfile; }

open( KEY, ">$keyfile" ) or die "$keyfile $!";
print KEY <<'END';
Private-key-format: v1.2
Algorithm: 1 (RSA)
Modulus: xQe102+F0EoyRSV74wn6e0nXjzJ+whO1kLSD3cSC5RF9TXXcFBWTq3OBc/9pezg6m2QKCsuxNqkBmvn69DyM1sun+5ROoRTMFEwGqLRbvwHdoRvu8SwLQUHpUugJyPKUNwrPNYebiuPUAI3Zlu7p5PzyUNgdM+IZCyTDksYLN7s=
PublicExponent: AQAB
PrivateExponent: yOATgH0y8Ci1F8ofhFmoBgpCurvAgB2X/vALgQ3YZbJvDYob1l4pL6OTV7AO2pF5LvPPSTJielfUSyyRrnANJSST/Dr19DgpSpnY2GWE7xmJ6/QqnIaJ2+10pFzVRXShijJZjt9dY7JXmNIoQ+JseE08aquKHFEGVfsvkThk8Q==
Prime1: 9lyWnGhbZZwVQo/qNHjVeWEDyc0hsc/ynT4Qp/AjVhROY+eJnBEvhtmqj3sq2gDQm2ZfT8uubSH5ZkNrnJjL2Q==
Prime2: zL0L5kwZXqUyRiPqZgbhFEib210WZne+AI88iyi39tU/Iplx1Q6DhHmOuPhUgCCj2nqQhWs9BAkQwemLylfHsw==
Exponent1: rcETgHChtYJmBDIYTrXCaf8get2wnAY76ObzPF7DrVxZBWExzt7YFFXEU7ncuTDF8DQ9mLvg45uImLWIWkPx0Q==
Exponent2: qtb8vPi3GrDCGKETkHshCank09EDRhGY7CKZpI0fpMogWqCrydrIh5xfKZ2d9SRHVaF8QrhPO7TM1OIqkXdZ3Q==
Coefficient: IUxSSCxp+TotMTbloOt/aTtxlaz0b5tSS7dBoLa7//tmHZvHQjftEw8KbXC89QhHd537YZX4VcK/uYbU6SesRA==
END
close(KEY);


my $bad1 = new Net::DNS::RR <<'END';
RSAMD5.example.		IN	KEY	512 3 1 (
	AwEAAdDembFMoX8rZTqTjHT8PbCZHbTJpDgtuL0uXpJqPZ6ZKnGdQsXVn4BSs8VJlH7+NEv+7Spq
	Ncxjx6o86HhrvFg5DsDMhEi5MIqlt1OcUYa0zUhFSkb+yzOSnPL7doSoaW8pxoX4uDemkfyOY9xN
	tNCNBJcvmp1Uvdnttf7LUorD ; Key ID = 21130
	)
END


my $bad2 = new Net::DNS::RR <<'END';
RSASHA1.example.	IN	KEY	( 512 3 5
	AwEAAcosvYOe384kf7szGV4YxwfliKk9VTlO8HEQnlQs4glpMwtwCm8E9zxQRMG1W9CsM7tcHKq8
	52KcapenPMkYCseeI7sRtD4k5eF6Us7SaYNRYG6qBhXkSRr41aTroqq+I9IMgAGMzUpC2a9rzn+f
	Hs5pZA2CKzoR1+9Jv4vKu5MF ; Key ID = 16351
	)
END


{
	my $packet = new Net::DNS::Packet('example');
	$packet->sign_sig0($keyfile);
	$packet->data;
	ok( $packet->sigrr->sigbin, 'sign packet using private key' );

	my $verified = $packet->verify($key);
	ok( $verified, 'verify packet using public key' );
	is( $packet->verifyerr, '', 'observe no packet->verifyerr' );
}


{
	my $packet = new Net::DNS::Packet('example');
	$packet->sign_sig0($keyfile);
	my $buffer = $packet->data;

	my $decoded  = new Net::DNS::Packet( \$buffer );
	my $verified = $decoded->verify($key);
	ok( $verified, 'verify decoded packet using public key' );
	is( $decoded->verifyerr, '', 'observe no packet->verifyerr' );
}


{
	my $packet = new Net::DNS::Packet('example');
	$packet->sign_sig0($keyfile);
	$packet->data;

	my $verified = $packet->verify($bad1);
	ok( !$verified,		'verify fails using wrong key' );
	ok( $packet->verifyerr, 'observe packet->verifyerr' );
}


{
	my $packet = new Net::DNS::Packet('example');
	$packet->sign_sig0($keyfile);
	$packet->data;

	my $verified = $packet->verify($bad2);
	ok( !$verified,		'verify fails using wrong key' );
	ok( $packet->verifyerr, 'observe packet->verifyerr' );
}


{
	my $packet = new Net::DNS::Packet('example');
	$packet->sign_sig0($keyfile);
	$packet->data;

	$packet->push( answer => rr_add('bogus. A 10.1.2.3') );
	my $verified = $packet->verify($key);
	ok( !$verified,		'verify fails for modified packet' );
	ok( $packet->verifyerr, 'observe packet->verifyerr' );
}


{
	my $packet = new Net::DNS::Packet('example');
	$packet->sign_sig0($keyfile);
	$packet->data;

	my $verified = $packet->verify( [$bad1, $bad2, $key] );
	ok( $verified, 'verify packet using array of keys' );
	is( $packet->verifyerr, '', 'observe no packet->verifyerr' );
}


{
	my $packet = new Net::DNS::Packet('example');
	$packet->sign_sig0($keyfile);
	$packet->data;

	$packet->push( answer => rr_add('bogus. A 10.1.2.3') );
	my $verified = $packet->verify( [$bad1, $bad2, $key] );
	ok( !$verified,		'verify failure using array of keys' );
	ok( $packet->verifyerr, 'observe packet->verifyerr' );
}


{
	my $data = new Net::DNS::Packet('example')->data;
	my $sig = create Net::DNS::RR::SIG( $data, $keyfile );
	ok( $sig->sigbin, 'create SIG over data using private key' );

	my $verified = $sig->verify( $data, $key );
	ok( $verified, 'verify data using public key' );
	is( $sig->vrfyerrstr, '', 'observe no sig->vrfyerrstr' );
}


{
	my $data = new Net::DNS::Packet('example')->data;
	my $time = time() + 3;
	my %args = (
		siginception  => $time,
		sigexpiration => $time,
		);
	my $object = create Net::DNS::RR::SIG( $data, $keyfile, %args );

	ok( !$object->verify( $data, $key ), 'verify fails for postdated SIG' );
	ok( $object->vrfyerrstr, 'observe sig->vrfyerrstr' );
	sleep 1 until $time < time();
	ok( !$object->verify( $data, $key ), 'verify fails for expired SIG' );
	ok( $object->vrfyerrstr, 'observe sig->vrfyerrstr' );
}


{
	my $object = new Net::DNS::RR( type => 'SIG' );
	my $keyrec = new Net::DNS::RR( type => 'KEY' );
	my $nonkey = new Net::DNS::RR( type => 'DS' );
	my $packet = new Net::DNS::Packet();
	my $array  = [];
	my @testcase = (		## test verify() with invalid arguments
		[$array,  $keyrec],
		[$object, $keyrec],
		[$packet, $keyrec],
		[$packet, $nonkey],
		);

	foreach my $arglist (@testcase) {
		my @argtype = map ref($_), @$arglist;
		$object->typecovered('A');			# induce failure
		eval { $object->verify(@$arglist); };
		my $exception = $1 if $@ =~ /^(.*)\n*/;
		ok( defined $exception, "verify(@argtype)\t[$exception]" );
	}
}


{
	my $packet = new Net::DNS::Packet('query.example');
	$packet->sign_sig0($keyfile);
	my $signed = $packet->data;				# signing occurs in SIG->encode
	$packet->sigrr->sigbin('');				# signature destroyed
	my $unsigned = $packet->data;				# unable to regenerate SIG0
	ok( length($unsigned) < length($signed), 'handled exception: missing key reference' );
}


exit;

__END__

