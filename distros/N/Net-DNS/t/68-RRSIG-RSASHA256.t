# $Id: 68-RRSIG-RSASHA256.t 1360 2015-06-15 09:58:53Z willem $	-*-perl-*-
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

plan tests => 7;

use_ok('Net::DNS::SEC');


my $ksk = new Net::DNS::RR <<'END';
RSASHA256.example.	IN	DNSKEY	257 3 8 (
	AwEAAcXr1phQtnOdThOrgcwRplS/btblbtLGeHQoba55Gr8Scbx7AAw+LjwtFmbPlDhklC8+4BAf
	QB+6Jv7hOFT45J/RqDV3W5p0qDYcLYJObNbiFxQ64ogMYHx62w4oUeTS5CvpHNzSoiyhhFlf71RL
	EVeBK798h+hdPeEWvHdzbwwMxZGIXP/eNN5u5tkNExuuqq3e6BeguCLsuLgMzHdfpl7W20z3BExD
	c28DgPRWHJtJcB+iUd5oQdrw+G9qSq4kb7vk3OZUGrgkZskicT1A5rQsOgc4SrT4d25Qd6fthmi2
	hZ86Y/2DP/NfR1mwWaN8ty7daqdcNpFQmKwQ+qpIV5c= ; Key ID = 63427
	)
END

ok( $ksk, 'set up RSA public ksk' );


my $keyfile = $ksk->privatekeyname;

END { unlink($keyfile) if defined $keyfile; }

open( KSK, ">$keyfile" ) or die "$keyfile $!";
print KSK <<'END';
Private-key-format: v1.2
Algorithm: 8 (RSASHA256)
Modulus: xevWmFC2c51OE6uBzBGmVL9u1uVu0sZ4dChtrnkavxJxvHsADD4uPC0WZs+UOGSULz7gEB9AH7om/uE4VPjkn9GoNXdbmnSoNhwtgk5s1uIXFDriiAxgfHrbDihR5NLkK+kc3NKiLKGEWV/vVEsRV4Erv3yH6F094Ra8d3NvDAzFkYhc/9403m7m2Q0TG66qrd7oF6C4Iuy4uAzMd1+mXtbbTPcETENzbwOA9FYcm0lwH6JR3mhB2vD4b2pKriRvu+Tc5lQauCRmySJxPUDmtCw6BzhKtPh3blB3p+2GaLaFnzpj/YM/819HWbBZo3y3Lt1qp1w2kVCYrBD6qkhXlw==
PublicExponent: AQAB
PrivateExponent: S3dyet+Dwi+/3pYtxr8QGg5oV/5htHLC6R+lOrqorSR+Q6zuxrxK6t0SRp9t19bZ/e3Oh7cyvyY+yj7cOOIyYpIRvllFj25d2UwDOkVnEMRiom8Vg2ScwboinpJXL5YONIQNYlHaToRDr8R5wD1jXmc9ZCU6uSocdyAxOqbEN+ZWNnzGHjs4onoGMLyc7f2NbMhSHVW9tp7zilCQ1W3OF6coWI/L/vGk1xBQZ+OtkRRbJCTca3qflLm/1vPq8/H3gS5adrJcO+/mUlhPoKxEqekZZp+FQJVHTYp3MyGTVXVl2M8sozf9lU/malzlqve5snMLfCOWH8MOdsx7eo0N+Q==
Prime1: +ajh2Bbk8r2DBvCw3u3ipji7zeD1LLMRdYlSuCpyIWGGoiCJrqX34zFCdDOO1gKa2QQG3OAGk3hZ1ddcgr+bnVNIEuVxJXe0Wg4e0ZPNMCe1333Hyt7ws2U+zosYNfrxOdPkj/S5XZkVyRE1Ixa79WCBJms+zgDPx30AUQXblw0=
Prime2: yvKWeFcJhIleHVNwEkNtq+aOgcIhS2ex7zc/zKFGSGYXdWIl17oM3ohiPgmLVznJtIkCIcYoxbfxuLW0NDe2OJC7PUjOB3lAmtHAH3ZafNbr/PdlAZzHUZiLsiHF/m5wd+pN37rCj7emjASwsGjcx3rRsJQvqVZARj/TXe9eQDM=
Exponent1: nMBIbKCTR0VtyyG8K3w43hyo7e7cgSA9SgragP9FgWf2XD0JtTpHlcIL82GbwQsJplA87tlJx7W80eLSFtWvIuxzSEn+7INoHVLYTsX6As4sBxK2Ks4nWruq34u9u8a/Rouf6jLBX98KKqA/OLTBdqMM885KNJWV367AUB7ZbNE=
Exponent2: FyUHR/4VFcpcs1d6pnqOHVaT1fR/u4u93Rwd6IZT75nE/xwMWMfdA9vl6FFKVM5AVJhzZ8qjh7jsljYSsQnRfC31TI3rASsw1Pcqw+vJcgdIrnbATCjHCmUtOUlkvRl3NhXAf81atu0ozzsRs2yiERXOqCaeMN+nQNuyjTnpM8U=
Coefficient: iUz9xrXzP2UaBruIps61HAbh6MV+OYDmliSnudXW5Ii1s3ANXMJodzgwqD+VesjC9dDE2nXMTCXKhpk46Qy8i3OYJ4T7vxoyHEYfID1PM0+whAwebRoKHBqQDEYgwTcqDX+qD4MMc1TaG/do/cgNc/1EyE03DP1plH6HhItECIo=
END
close(KSK);


my $key = new Net::DNS::RR <<'END';
RSASHA256.example.	IN	DNSKEY	256 3 8 (
	AwEAAZRSF/5NLnExp5n4M6ynF2Yok3N2aG9AWu8/vKQrZGFQcbL+WPGYbWUtMpiNXmvzTr2j86kN
	QU4wBawm589mjzXgVQRfXYDMMFhHMtagzEKOiNy2ojhhFyS7r2O2vUbo4hGbnM54ynSM1al+ygKU
	Gy1TNzHuYMiwh+gsQCsC5hfJ ; Key ID = 35418
	)
END

ok( $key, 'set up RSA public key' );


my @rrset = ( $key, $ksk );
my $rrsig = create Net::DNS::RR::RRSIG( \@rrset, $keyfile );
ok( $rrsig, 'create RRSIG over rrset using private ksk' );

my $verify = $rrsig->verify( \@rrset, $ksk );
ok( $verify, 'verify RRSIG over rrset using public ksk' ) || diag $rrsig->vrfyerrstr;

ok( !$rrsig->verify( \@rrset, $key ), 'verify fails using wrong key' );

my @badrrset = ($key);
ok( !$rrsig->verify( \@badrrset, $ksk ), 'verify fails using wrong rrset' );


exit;

__END__

