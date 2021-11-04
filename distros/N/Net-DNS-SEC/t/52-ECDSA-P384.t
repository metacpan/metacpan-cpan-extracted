#!/usr/bin/perl
# $Id: 52-ECDSA-P384.t 1830 2021-01-26 09:08:12Z willem $	-*-perl-*-
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

plan skip_all => 'disabled ECDSA'
		unless eval { Net::DNS::SEC::libcrypto->can('EVP_PKEY_new_ECDSA') };

plan tests => 8;


my %filename;

END {
	foreach ( values %filename ) {
		unlink($_) if -e $_;
	}
}


use_ok('Net::DNS::SEC');
use_ok('Net::DNS::SEC::Private');
use_ok( my $class = 'Net::DNS::SEC::ECDSA' );


my $key = Net::DNS::RR->new( <<'END' );
ECDSAP384SHA384.example.	IN	DNSKEY	256 3 14 (
	K4t0AhWiJcLZ25BlpvfxCi2KMlkBr14zECH3Y2imMYOzn5zcMpOh0iPbI9Hnfep8L+BBzQrRFNmc
	5r3r0l0y+snHIc/npdK/1Ks0ZG/aMB5r/PfJGeB5MLdtcanFir2S ; Key ID = 25812
	)
END

ok( $key, 'set up ECDSA public key' );


my $keyfile = $filename{keyfile} = $key->privatekeyname;

my $privatekey = IO::File->new( $keyfile, '>' ) or die qq(open: "$keyfile" $!);
print $privatekey <<'END';
Private-key-format: v1.3
Algorithm: 14 (ECDSAP384SHA384)
PrivateKey: mvuhyr+QDMqo4bpeREFRM2w8qZsBiLiCouR0sihdinvpRA3zA/dByohgH4CLI7Kr
Created: 20141209021155
Publish: 20141209021155
Activate: 20141209021155
END
close($privatekey);

my $private = Net::DNS::SEC::Private->new($keyfile);
ok( $private, 'set up ECDSA private key' );


my $sigdata = 'arbitrary data';
my $corrupt = 'corrupted data';

my $signature = $class->sign( $sigdata, $private );
ok( $signature, 'signature created using private key' );


my $verified = $class->verify( $sigdata, $key, $signature );
is( $verified, 1, 'signature verified using public key' );


my $verifiable = $class->verify( $corrupt, $key, $signature );
is( $verifiable, 0, 'signature not verifiable if data corrupted' );


exit;

__END__

