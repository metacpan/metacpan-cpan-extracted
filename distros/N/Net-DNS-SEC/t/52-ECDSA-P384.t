# $Id: 52-ECDSA-P384.t 1656 2018-03-22 14:36:14Z willem $	-*-perl-*-
#

use strict;
use Test::More;

my %prerequisite = (
	'Digest::SHA'	=> 5.23,
	'Net::DNS::SEC'	=> 1.01,
	'MIME::Base64'	=> 2.13,
	);

foreach my $package ( sort keys %prerequisite ) {
	my @revision = grep $_, $prerequisite{$package};
	next if eval "use $package @revision; 1;";
	plan skip_all => "missing prerequisite $package @revision";
	exit;
}

plan skip_all => 'disabled ECDSA'
		unless eval { Net::DNS::SEC::libcrypto->can('ECDSA_sign') };

plan tests => 8;


my %filename;

END {
	foreach ( values %filename ) {
		unlink($_) if -e $_;
	}
}


use_ok('Net::DNS::SEC');
use_ok('Net::DNS::SEC::Private');
use_ok('Net::DNS::SEC::ECDSA');


my $key = new Net::DNS::RR <<'END';
ECDSAP384SHA384.example.	IN	DNSKEY	256 3 14 (
	K4t0AhWiJcLZ25BlpvfxCi2KMlkBr14zECH3Y2imMYOzn5zcMpOh0iPbI9Hnfep8L+BBzQrRFNmc
	5r3r0l0y+snHIc/npdK/1Ks0ZG/aMB5r/PfJGeB5MLdtcanFir2S ; Key ID = 25812
	)
END

ok( $key, 'set up ECDSA public key' );


my $keyfile = $filename{keyfile} = $key->privatekeyname;

open( KEY, ">$keyfile" ) or die "$keyfile $!";
print KEY <<'END';
Private-key-format: v1.3
Algorithm: 14 (ECDSAP384SHA384)
PrivateKey: mvuhyr+QDMqo4bpeREFRM2w8qZsBiLiCouR0sihdinvpRA3zA/dByohgH4CLI7Kr
Created: 20141209021155
Publish: 20141209021155
Activate: 20141209021155
END
close(KEY);

my $private = new Net::DNS::SEC::Private($keyfile);
ok( $private, 'set up ECDSA private key' );


my $sigdata = 'arbitrary data';

my $signature = Net::DNS::SEC::ECDSA->sign( $sigdata, $private );
ok( $signature, 'signature created using private key' );


{
	my $verified = Net::DNS::SEC::ECDSA->verify( $sigdata, $key, $signature );
	ok( $verified, 'signature verified using public key' );
}


{
	my $corrupt = 'corrupted data';
	my $verified = Net::DNS::SEC::ECDSA->verify( $corrupt, $key, $signature );
	ok( !$verified, 'signature over corrupt data not verified' );
}

exit;

__END__

