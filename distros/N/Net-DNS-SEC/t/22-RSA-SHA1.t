# $Id: 22-RSA-SHA1.t 1494 2016-08-22 09:34:07Z willem $	-*-perl-*-
#

use Test::More;

my %prerequisite = (
	Crypt::OpenSSL::Bignum	=> 0,
	Crypt::OpenSSL::RSA	=> 0,
	Net::DNS		=> 1.01,
	Net::DNS::SEC::Private	=> 0,
	);

foreach my $package ( sort keys %prerequisite ) {
	my @revision = grep $_, $prerequisite{$package};
	eval "use $package @revision";
	next unless $@;
	plan skip_all => "missing prerequisite $package @revision";
	exit;
}

plan tests => 7;


my %filename;

END {
	foreach ( values %filename ) {
		unlink($_) if -e $_;
	}
}


use_ok('Net::DNS');
use_ok('Net::DNS::SEC::Private');
use_ok('Net::DNS::SEC::RSA');


my $key = new Net::DNS::RR <<'END';
RSASHA1.example.	IN	DNSKEY	256 3 5 (
	AwEAAZHbngk6sMoFHN8fsYY6bmGR4B9UYJIqDp+mORLEH53Xg0f6RMDtfx+H3/x7bHTUikTr26bV
	AqsxOs2KxyJ2Xx9RGG0DB9O4gpANljtTq2tLjvaQknhJpSq9vj4CqUtr6Wu152J2aQYITBoQLHDV
	i8mIIunparIKDmhy8TclVXg9 ; Key ID = 1623
	)
END

ok( $key, 'set up RSA public key' );


my $keyfile = $filename{keyfile} = $key->privatekeyname;

open( KEY, ">$keyfile" ) or die "$keyfile $!";
print KEY <<'END';
Private-key-format: v1.2
Algorithm: 5 (RSASHA1)
Modulus: kdueCTqwygUc3x+xhjpuYZHgH1RgkioOn6Y5EsQfndeDR/pEwO1/H4ff/HtsdNSKROvbptUCqzE6zYrHInZfH1EYbQMH07iCkA2WO1Ora0uO9pCSeEmlKr2+PgKpS2vpa7XnYnZpBghMGhAscNWLyYgi6elqsgoOaHLxNyVVeD0=
PublicExponent: AQAB
PrivateExponent: Vd6cuMRDxnuiFr367pJB39FYyDkNrZ9zAoyCt0idcHirglmV1ps7px2AQY2MOW/Tg2Xz59EqBA00mEOmnuRfdRXraqo1mxA9C2qGR2xHltNH2RVR5oTlahZLRUYZTDuLI7G/3IiPKrf5z/HFm2DkkzuxGqC8hWf9FOni49CqhYE=
Prime1: waSsFnVlQrG/3SGh5GNV5o50PS8gE5L0/+GP2MIjkR3px1zR+LjfkVii1EaTda+Sq7B0ROI+M+R0JLh98Rr6XQ==
Prime2: wNOsL3isJAE89C2XaESsJnm46vPZrqZ4XATub1dwOWNqVOji6KI9yTBc3MfmXkZVmy0I8Rm4ILLh5m/+0LNXYQ==
Exponent1: muRjmptQ4iZYOEOcwZkLrx4nsIEvgTi9rKf6bgHsfTmWNBf1BKSsgBCMPowti6djBN5iQm9OHigRFwZUBzXzKQ==
Exponent2: KE8Xe4T6Vzx7BYBSWlWgtxpS8aqwIrZiCrptLZFVwGlr3PwiEwd3awtVHkIbgjGpy5qKd/wsZYl/d7CJ0A7tgQ==
Coefficient: p9WMT9cDpT7BXcKBXnrMLV8O31ujZ17nwlmlFe3+0n2VCx2T/CSz72xssffn0n2q0DaHHfu9SxR1RLgmDUzVEA==
END
close(KEY);

my $private = new Net::DNS::SEC::Private($keyfile);
ok( $private, 'set up RSA private key' );


my $sigdata = 'arbitrary data';

my $signature = Net::DNS::SEC::RSA->sign( $sigdata, $private );
ok( $signature, 'signature created using private key' );


my $validated = Net::DNS::SEC::RSA->verify( $sigdata, $key, $signature );
ok( $validated, 'signature validated using public key' );


exit;

__END__

