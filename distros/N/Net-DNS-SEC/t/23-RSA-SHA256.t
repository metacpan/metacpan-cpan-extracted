# $Id: 23-RSA-SHA256.t 1758 2019-10-14 13:17:11Z willem $	-*-perl-*-
#

use strict;
use Test::More;

my %prerequisite = (
	'Net::DNS::SEC' => 1.01,
	'MIME::Base64'	=> 2.13,
	);

foreach my $package ( sort keys %prerequisite ) {
	my @revision = grep $_, $prerequisite{$package};
	next if eval "use $package @revision; 1;";
	plan skip_all => "missing prerequisite $package @revision";
	exit;
}

plan skip_all => 'disabled RSA'
		unless eval { Net::DNS::SEC::libcrypto->can('EVP_PKEY_assign_RSA') };

plan tests => 8;


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
RSASHA256.example.	IN	DNSKEY	256 3 8 (
	AwEAAZRSF/5NLnExp5n4M6ynF2Yok3N2aG9AWu8/vKQrZGFQcbL+WPGYbWUtMpiNXmvzTr2j86kN
	QU4wBawm589mjzXgVQRfXYDMMFhHMtagzEKOiNy2ojhhFyS7r2O2vUbo4hGbnM54ynSM1al+ygKU
	Gy1TNzHuYMiwh+gsQCsC5hfJ ; Key ID = 35418
	)
END

ok( $key, 'set up RSA public key' );


my $keyfile = $filename{keyfile} = $key->privatekeyname;

open( KEY, ">$keyfile" ) or die "$keyfile $!";
print KEY <<'END';
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
close(KEY);

my $private = new Net::DNS::SEC::Private($keyfile);
ok( $private, 'set up RSA private key' );


my $sigdata = 'arbitrary data';

my $signature = Net::DNS::SEC::RSA->sign( $sigdata, $private );
ok( $signature, 'signature created using private key' );


my $verified = Net::DNS::SEC::RSA->verify( $sigdata, $key, $signature );
ok( $verified, 'signature verified using public key' );


my $corrupt = 'corrupted data';
my $verifiable = Net::DNS::SEC::RSA->verify( $corrupt, $key, $signature );
ok( !$verifiable, 'signature not verifiable if data corrupt' );


exit;

__END__

