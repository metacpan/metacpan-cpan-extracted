# $Id: 70-RRSIG-RSASHA512.t 1360 2015-06-15 09:58:53Z willem $	-*-perl-*-
#

use strict;
use Test::More;
use Net::DNS;

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
RSASHA512.example.	IN	DNSKEY	257 3 10 (
	AwEAAb/7yz0lSf3nFy7MPhkbnqOlaExKlJ8rMmYVEhFYZ5qS/ufQbfQ3stb0opr68eitrauolthm
	P325OvNxdzSq5rgURjx9ZitDlhxDyPfQhDzY+/CBhY/z++DRIr+v3AN/7kRW8sYwC+2Hoa1+VxQZ
	1fSQ4J46ZwoN5slpar9G/Gv5aPgsvweQDI285eQVlIQ9NL00bODOHzoKvh9BAx07MOOcT9q6r9xs
	MPg6M4C8ykH2zVY5x1iGxT8Syzh/mecSiJtv+b1W4j49pCNj19uenW3oUnyfHg/FBmQpxTiHqs6b
	1ZfVH7akvsQqwk12xT0hDEfeyj4jswDiSsEsLqt1DM0= ; Key ID = 39948
	)
END

ok( $ksk, 'set up RSA public ksk' );


my $keyfile = $ksk->privatekeyname;

END { unlink($keyfile) if defined $keyfile; }

open( KSK, ">$keyfile" ) or die "$keyfile $!";
print KSK <<'END';
::::::::::::::
Private-key-format: v1.2
Algorithm: 10 (RSASHA512)
Modulus: v/vLPSVJ/ecXLsw+GRueo6VoTEqUnysyZhUSEVhnmpL+59Bt9Dey1vSimvrx6K2tq6iW2GY/fbk683F3NKrmuBRGPH1mK0OWHEPI99CEPNj78IGFj/P74NEiv6/cA3/uRFbyxjAL7YehrX5XFBnV9JDgnjpnCg3myWlqv0b8a/lo+Cy/B5AMjbzl5BWUhD00vTRs4M4fOgq+H0EDHTsw45xP2rqv3Gww+DozgLzKQfbNVjnHWIbFPxLLOH+Z5xKIm2/5vVbiPj2kI2PX256dbehSfJ8eD8UGZCnFOIeqzpvVl9UftqS+xCrCTXbFPSEMR97KPiOzAOJKwSwuq3UMzQ==
PublicExponent: AQAB
PrivateExponent: MnqyZdF4MxqgLd3mNhPdEopbcjPqADALgGvp5EWqeCpOfAWB48UBcSPB3Z4+HUANeiVKBHxeFWCu73PWNDL7l0s9bIpMYvPSdHweS4q4OoeTNxnXVJKCmAplaKGE6CarL6ztCM95U2tmR4gAvXhNmZC+ftw8W5hsJmlheAniNUFaRK28K0+Tlge7XkRxSwK63sjMRHHxAbclr8K2j/GUVkXG9yOrMqgXUJ0WOg9E5BTW+gdkGl4kB5U2gvgRwxkEwY9x7yzrg2cUxrEi9hDlS9HiG5NZizcQqAWkKcdHo28ZB5E4NZBLrKQFjrkOQz3ZjtpUcsTRf/lOvkCOoaveAQ==
Prime1: 7lgM8XyKy3IHYC3+GX1bS0LZFqBhUvYuZ52i2dfKoG9XglVKKe0Pmu/Hkgkdc2/mottVdYHpMZ4t/Wt0OXdqfttoYTgIOFTw4t3Jk9HV4aPIRvVD7LRnRQiKEW9OiS9ixplatrlgMqyOIpx3bou6eRzOs1yfBsNSr+LZbHQ50/U=
Prime2: zjSQ7ylj386G6bFXMKLAjApYy7cQA9T4/URnonUYjXwzQRaDvfAGoRNRA4e0RagVd/x2Dk5hs2UYLMIhpmQWNoSK/ZAFS02RzapMZTV2jya4cJZ83qjYtMYEx8Lff5dHX3lz/uAkcJCasIbyEodi0btJkCZQFAsCMbGlhguTpnk=
Exponent1: U8jEFAfRyp61FQxV7KPyecxv/9I1JDLCMU5qtuVyp188heZxgbeB6tcrcpydq7zEeK9dpUcbsIOIazNg0eq2lw2N7c8CpLrHSxjoCXyUERPADaGeVRE91DiiQGq+Ut9De8jg6KbVuDqMZIJYQZYA4R5NUyPWC0ySPp4iDEv3IBk=
Exponent2: tJ867SM2Rs6jQoSCuSl2u7Q8f4UE1DZzO3X1yUoEjbpjMvpDv9ZGGEXRSuRNtk47L/TGfFWQIxHEkUAjNZqqEmsbTGwhFwsFUj9/149zIIVsPcKz8l24JPDnMwuxthOPA0RhpLo1cRxZQ5OQ60YH+2qwT0IgFs5lx52yPa5aURE=
Coefficient: Y7KhcJe8vcW9h/bxClHMjlB0sYYvdqo7/iwjxiaCD4suPAUpLMxNgeR3TJHT1RYaHQSuFB3Mc9f58hoHe3dncxF+Eey9SdTH53c0+V95tJpAsqirFaqvei+xgikcmhYsWLOQHayul5ZMsfpiph3R90QUYg3Kpbni4W0ALeGswv4=
END
close(KSK);


my $key = new Net::DNS::RR <<'END';
RSASHA512.example.	IN	DNSKEY	256 3 10 (
	AwEAAdLaxcxvgdQKF3zSOuXQgwWPQ+dKzJ3Ob4w3r+o73i2MnhE0HBHuTzUZGVjGR05VGqZaJx64
	LNt0Wlxxoxt3Uwaq55t5MzN3LYYYEcMQ1XPhPG1nNuD0LiqlqL+KmQqlAo3cm4F71gr/GXQiPG3O
	WM11ulruDKZpyfYg1NWryu3F ; Key ID = 35741
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


