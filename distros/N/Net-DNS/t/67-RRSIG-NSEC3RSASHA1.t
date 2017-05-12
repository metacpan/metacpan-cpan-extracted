# $Id: 67-RRSIG-NSEC3RSASHA1.t 1360 2015-06-15 09:58:53Z willem $	-*-perl-*-
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
NSEC3RSASHA1.example.	IN	DNSKEY	257 3 7 (
	AwEAAbHJTox3ouUUnzmoD+0QIf0BKjr9N2eVxhozx/LBIdVO3GdCcsXD0M7zwfkPB9FvU1LIdgGm
	b8I4VVildoBttlRoXsoTHHf0a2fab0WYpJ4HQGlS6BaQh+Rhbtbc7yGf9HOa+sTa2OpGeqy+vYWO
	Egvi6do0zrzYVzXsXZrZj/Q+cZP9j//uY/CoLLOBSYHNE+Fd8D4BMLp4Uh74l7I/yVqQBYy24riY
	X3TKwrfrNRcQ6/GFjNezAZjLo3Vlm1jjhmWqNLsOeMp04nIbkDMYdnJ2dCseBDYm45fS86ggTxhG
	A60vzcaBRvi5dxpCq39yjdgTq/RAzmcPS35wpZprxss= ; Key ID = 27099
	)
END

ok( $ksk, 'set up RSA public ksk' );


my $keyfile = $ksk->privatekeyname;

END { unlink($keyfile) if defined $keyfile; }

open( KSK, ">$keyfile" ) or die "$keyfile $!";
print KSK <<'END';
Private-key-format: v1.2
Algorithm: 7 (NSEC3RSASHA1)
Modulus: sclOjHei5RSfOagP7RAh/QEqOv03Z5XGGjPH8sEh1U7cZ0JyxcPQzvPB+Q8H0W9TUsh2AaZvwjhVWKV2gG22VGheyhMcd/RrZ9pvRZikngdAaVLoFpCH5GFu1tzvIZ/0c5r6xNrY6kZ6rL69hY4SC+Lp2jTOvNhXNexdmtmP9D5xk/2P/+5j8Kgss4FJgc0T4V3wPgEwunhSHviXsj/JWpAFjLbiuJhfdMrCt+s1FxDr8YWM17MBmMujdWWbWOOGZao0uw54ynTichuQMxh2cnZ0Kx4ENibjl9LzqCBPGEYDrS/NxoFG+Ll3GkKrf3KN2BOr9EDOZw9LfnClmmvGyw==
PublicExponent: AQAB
PrivateExponent: OU9ROMqgAgSBx047xAl9S1eCy30wzP1k3LFwdPp484/2UHsFEGcs+mltT+HefU7Lp1XjZGjIge0y5d6AsqmrKs5yL+W1OZ3auaGaWO75sc9YnhsRoaR5ic82saCKnWY4oMOGrsp1Ph/2D5V09oZzns1I4QRA2HNMuZ82FWKomuy0iR4vR87macOuOB4erhZeSuEO/5EHXh6rDlWKoBCcIYBr4bjGQ4IsYyFVvBPUaEMX3NO0ahHFHM3QeEvVNyplUhNpODSd1bRK1mZoiGSTv7fJ/UygC2OJsoBzpAVqeTKJKBJWBU3Jp3Alg7IOOnaIdeapa/doCcEURuWVZx9LgQ==
Prime1: 2+e0aqqdaF8rXG9X1aH6ho8ZmrwHReHQin0Bylc6YOmNlvQfIMifAxfs/MQZsdcR8wsIH/GW5pWBruBd6yNRF73QDITW0/O0f9Rk738TMEmUQw9cRhq2dNoKhpT44r7kiH9n7HJDBjT9vzle5/fWMlCmzFLUGGFt/DJNH03Kdms=
Prime2: zvfLgQQyoxm9Fh2TKIw4rQ4HCzfdFwm7X0MlvBrIL8cDxb7N5mJcSqF7AMFEssZW8h2IunSQZcXEkmDfGYZakD2L1hs+xMcFZsa0b2wyfvCjcxavIz3ucbjJ4OQG/XbQkpU/mkZbyNUQaPH7ILWHI+c2+19lolpYEc/oub4qSSE=
Exponent1: FYS13d42KvltF815bdk815/3JHIT0B3Jt1OGMlOYzdTs2wGmbiHTlYzozs8tqH5gLkU9FUshtgyZNRCVgCXjkIwtaJwzHWhymDOjcOAhc48vp+Q/5khE5GhVsVewhxeg6050T+nabygOUID/rXlOB3xm5gWQ5ZXbGludult1XWM=
Exponent2: udGQTI1QSU9ajPiQnt8GI5lsiY3mWkDKkYTf5DrHcN3lbS0Z/7Zf1kGVBeB/pWKdvVL25zCwVC9zhVij9W7C8K3RVrGvcUyedOACL+ecjovOtA2xwJph8ohN+DPCct6x9Gk7aW+yCGYDDbX0GjHg20NEAfxsa49hctyPvfQWUwE=
Coefficient: iqzKS1qZPOmFj/ZlZSEyLDDoXNfXg1KwTqPAYWM+2Ppq15U0kb+SUidI8pWisatryznRTcdfkYbkcZqcUq1Xkg0DyUVLo80ld9iTTxyc/gPFvEfs8eubDYlC3ZQEaWRb+JQ6jY+NWJnjTqegEGymY/4KTD4WIM7WnIBbNxzrsS8=
END
close(KSK);


my $key = new Net::DNS::RR <<'END';
NSEC3RSASHA1.example.	IN	DNSKEY	256 3 7 (
	AwEAAcNz+cEA/Zkl/8u5/kfJKPNSbmXbdMpk6jM4bMWTEhZlaEOJE+GYsbM+HvjMgEMz00eDpvDR
	XEMl1o4x60SgW8ap44deky/KAYzDC80rIZrvjDx8DPzF3yIikrGc8P7Eq+0zbWrYyiHRg5DllIT4
	5NCz6EMtji1RQloWCaXuAzCN ; Key ID = 23540
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

