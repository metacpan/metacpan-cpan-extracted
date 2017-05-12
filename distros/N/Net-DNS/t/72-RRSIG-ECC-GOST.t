# $Id: 72-RRSIG-ECC-GOST.t 1360 2015-06-15 09:58:53Z willem $	-*-perl-*-
#

use strict;
use Test::More;

my @prerequisite = qw(
		MIME::Base64
		Time::Local
		Net::DNS::RR::RRSIG
		Net::DNS::SEC
		Net::DNS::SEC::ECCGOST
		Crypt::OpenSSL::Bignum
		Crypt::OpenSSL::EC
		Crypt::OpenSSL::ECDSA
		Digest::GOST
		);

foreach my $package (@prerequisite) {
	next if eval "require $package";
	plan skip_all => "$package not installed";
	exit;
}

plan tests => 7;

use_ok('Net::DNS::SEC');


my $ksk = new Net::DNS::RR <<'END';
ecc-gost.example.	IN	DNSKEY	257 3 12 (
	6VwgNT1BXxXNVpTQXcJQ82PcsCYmI60oN88Plbl028ruvl6DqJby/uBGULHT5FXmZiXBJozE6kP0
	+BirN9YPBQ== ; Key ID = 46388
	)
END

ok( $ksk, 'set up ECC-GOST public ksk' );


my $keyfile = $ksk->privatekeyname;

END { unlink($keyfile) if defined $keyfile; }

open( KSK, ">$keyfile" ) or die "$keyfile $!";
print KSK <<'END';
Private-key-format: v1.3
Algorithm: 12 (ECC-GOST)
PrivateKey: nBnGCP/hYTdJX0znDstyFTVYSA6b0nFeHy0FJUj7LhU=
Created: 20150102211707
Publish: 20150102211707
Activate: 20150102211707
END
close(KSK);


my $key = new Net::DNS::RR <<'END';
ecc-gost.example.	IN	DNSKEY	256 3 12 (
	LMgXRHzSbIJGn6i16K+sDjaDf/k1o9DbxScOgEYqYS/rlh2Mf+BRAY3QHPbwoPh2fkDKBroFSRGR
	7ZYcx+YIQw== ; Key ID = 40691
	)
END

ok( $key, 'set up ECC-GOST public key' );


my @rrset = ( $key, $ksk );
my $rrsig = create Net::DNS::RR::RRSIG( \@rrset, $keyfile );
ok( $rrsig, 'create RRSIG over rrset using private ksk' );

my $verify = $rrsig->verify( \@rrset, $ksk );
ok( $verify, 'verify RRSIG using ksk' ) || diag $rrsig->vrfyerrstr;

ok( !$rrsig->verify( \@rrset, $key ), 'verify fails using wrong key' );

my @badrrset = ($key);
ok( !$rrsig->verify( \@badrrset, $ksk ), 'verify fails using wrong rrset' );


exit;

__END__

