#!/usr/bin/perl
# $Id: 21-RSA-MD5.t 1830 2021-01-26 09:08:12Z willem $	-*-perl-*-
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
RSAMD5.example.	IN	KEY	512 3 1 (
	AwEAAc6K704XNTQYlCPw1R5qBNdPg3SxOdhEWdDFlPdCeeBL1UDSdUG1ijcNkoGCKpFXLaTqeJAH
	+VkXhOGUSvFxIOOmtxb3ubwFf80Up1iKwACNmfCgDlGm8EzGKVoPGcuXkwcxFsQtBoKqT6lWR3at
	6MT/bnuwIIVaD91u1L+/tVw7 ; Key ID = 46428
	)
END

ok( $key, 'set up RSA public key' );


my $keyfile = $filename{keyfile} = $key->privatekeyname;

my $privatekey = IO::File->new( $keyfile, '>' ) or die qq(open: "$keyfile" $!);
print $privatekey <<'END';
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
is( $verifiable, 0, 'signature not verifiable if data corrupt' );


exit;

__END__

