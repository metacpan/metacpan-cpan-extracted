#!/usr/bin/perl
# $Id: 23-RSA-SHA256.t 1830 2021-01-26 09:08:12Z willem $	-*-perl-*-
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
RSASHA256.example.	IN	DNSKEY	256 3 8 (
	AwEAAZRSF/5NLnExp5n4M6ynF2Yok3N2aG9AWu8/vKQrZGFQcbL+WPGYbWUtMpiNXmvzTr2j86kN
	QU4wBawm589mjzXgVQRfXYDMMFhHMtagzEKOiNy2ojhhFyS7r2O2vUbo4hGbnM54ynSM1al+ygKU
	Gy1TNzHuYMiwh+gsQCsC5hfJ ; Key ID = 35418
	)
END

ok( $key, 'set up RSA public key' );


my $keyfile = $filename{keyfile} = $key->privatekeyname;

my $privatekey = IO::File->new( $keyfile, '>' ) or die qq(open: "$keyfile" $!);
print $privatekey <<'END';
Private-key-format: v1.2
Algorithm: 8 (RSASHA256)
Modulus: lFIX/k0ucTGnmfgzrKcXZiiTc3Zob0Ba7z+8pCtkYVBxsv5Y8ZhtZS0ymI1ea/NOvaPzqQ1BTjAFrCbnz2aPNeBVBF9dgMwwWEcy1qDMQo6I3LaiOGEXJLuvY7a9RujiEZucznjKdIzVqX7KApQbLVM3Me5gyLCH6CxAKwLmF8k=
PublicExponent: AQAB
PrivateExponent: c74UZyhHo6GCDs73VDYYNmpXlnTCTn7D94ufY+VQsfgaofmF4xJ128yHfTBkjI0T1z1H+ZYUbjVfV9YMc3avLcXAb4YOEuNw0CSZrtTFc/oTvAyM9tKoa7hB9MSlYtmYvaWiEatHzKL0wYvo71jtfoTyDLQTISzrBWsA+K1a3hk=
Prime1: wvw2lVu+kepiu0fasCrA3BlemVJ3XvWdd/y0sB5+egVGIJCn1bgkaSL/IP+683K28tN7hQYzMGiDBPymu3FeAw==
Prime2: wruzE41ctH5D2SLhW4pi/pz+WSyeBUSvsmUe5kr4c9mlIqYUK1k72kmsjjZtD4eJsjq3xb/VGi+pcMuK2t1/Qw==
Exponent1: lgk3AxTWfjcqA8wVpesv/ezzku0W95Xtto9YhhDg54m5XYOR8e1A7znDsaO2OnAyAIXlDQYpS32QG71Bmwhv+w==
Exponent2: KyNVekFYhgtqkFFvxs2TPIAewDZoExayLTzFaZK2E0PllxVfZnLwFV04wpA//K6zzC3BxCbI2HIygPA2JGHo7Q==
Coefficient: R3pSnerhKwfAHrH3iyojUzKzhM+AQ+97CWavx36eyKT3Yr/SIDANeeXGlT9U7RdxbkZzyeWbFNCnT+b89UX1RQ==
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

