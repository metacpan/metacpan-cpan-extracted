#!/usr/bin/perl
# $Id: 31-DSA-SHA1.t 1830 2021-01-26 09:08:12Z willem $	-*-perl-*-
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


plan skip_all => "disabled DSA"
		unless eval { Net::DNS::SEC::libcrypto->can('EVP_PKEY_new_DSA') };

plan tests => 13;


my %filename;

END {
	foreach ( values %filename ) {
		unlink($_) if -e $_;
	}
}


use_ok('Net::DNS::SEC');
use_ok('Net::DNS::SEC::Private');
use_ok( my $class = 'Net::DNS::SEC::DSA' );


my $key = Net::DNS::RR->new( <<'END' );
DSA.example.	IN	DNSKEY	( 257 3 3
	CKrKbLrir4slVXYFrA4Y8Rik/UxzkCo1Rp0Spz907VrJL8u3I/YKTTvoMh/GL2n3/NL/KgzNRWb8
	pLB3FIWHjXXhn3r3sbld180DI4tv98CZKr86UDP0UUHVE/DkkEZw5PAy2nyhhKTJRvbR4ZT0OSZY
	+GZA2hIzmMYk4gR2mwa3jCmAGqw2i0OtAYzSOe06uoELZLl96kRsFk69OcQxzrDKz5BEZZpNBpfZ
	UBk/CRPDxBE2xjJkq3VpehAUCMOFpPQlEuW2D6CNuIbJY5pNpOF3RF17vkvxQx6678ZLIN3PdeG/
	nGwoJJArbt7Y/q+b/NxnIu6RwApE40p/7pOq6qKcqPVU2oHR/N7oNiyHnh68gSonUFfy5lETiyw8
	vDaJS/JhC2WQKzxxBo4oa/KFXFAd6NR6bE5h5XRWWqZvm2sBgcy+sKTbKcR4PDvaAoMguBjDeigm
	/NV6phNbARV926NyQZOi5uUeBYA16v1KnUll7A3I9wt3ykVIbx0WqB4Ozzk2PF/3vH3wudO5bL72
	zK1Yox60 ) ; Key ID = 53264
END

ok( $key, 'set up DSA public key' );


my $keyfile = $filename{keyfile} = $key->privatekeyname;

my $privatekey = IO::File->new( $keyfile, '>' ) or die qq(open: "$keyfile" $!);
print $privatekey <<'END';
Private-key-format: v1.2
Algorithm: 3 (DSA)
Prime(p): kCo1Rp0Spz907VrJL8u3I/YKTTvoMh/GL2n3/NL/KgzNRWb8pLB3FIWHjXXhn3r3sbld180DI4tv98CZKr86UDP0UUHVE/DkkEZw5PAy2nyhhKTJRvbR4ZT0OSZY+GZA2hIzmMYk4gR2mwa3jCmAGqw2i0OtAYzSOe06uoELZLk=
Subprime(q): qspsuuKviyVVdgWsDhjxGKT9THM=
Base(g): fepEbBZOvTnEMc6wys+QRGWaTQaX2VAZPwkTw8QRNsYyZKt1aXoQFAjDhaT0JRLltg+gjbiGyWOaTaThd0Rde75L8UMeuu/GSyDdz3Xhv5xsKCSQK27e2P6vm/zcZyLukcAKRONKf+6TquqinKj1VNqB0fze6DYsh54evIEqJ1A=
Private_value(x): drOKJBTwCM0O9U6tpIgymGyBrao=
Public_value(y): V/LmUROLLDy8NolL8mELZZArPHEGjihr8oVcUB3o1HpsTmHldFZapm+bawGBzL6wpNspxHg8O9oCgyC4GMN6KCb81XqmE1sBFX3bo3JBk6Lm5R4FgDXq/UqdSWXsDcj3C3fKRUhvHRaoHg7POTY8X/e8ffC507lsvvbMrVijHrQ=
END
close($privatekey);

my $private = Net::DNS::SEC::Private->new($keyfile);
ok( $private, 'set up DSA private key' );


my $wrongkey = Net::DNS::RR->new( <<'END' );
RSAMD5.example.	IN	KEY	( 512 3 1
	AwEAAcUHtdNvhdBKMkUle+MJ+ntJ148yfsITtZC0g93EguURfU113BQVk6tzgXP/aXs4OptkCgrL
	sTapAZr5+vQ8jNbLp/uUTqEUzBRMBqi0W78B3aEb7vEsC0FB6VLoCcjylDcKzzWHm4rj1ACN2Zbu
	6eT88lDYHTPiGQskw5LGCze7 ) ; Key ID = 2871
END

ok( $wrongkey, 'set up non-DSA public key' );


my $wrongfile = $filename{wrongfile} = $wrongkey->privatekeyname;

my $handle = IO::File->new( $wrongfile, '>' ) or die qq(open: "$wrongfile" $!);
print $handle <<'END';
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
close($handle);

my $wrongprivate = Net::DNS::SEC::Private->new($wrongfile);
ok( $wrongprivate, 'set up non-DSA private key' );


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

