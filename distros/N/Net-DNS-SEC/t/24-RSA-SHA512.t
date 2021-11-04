#!/usr/bin/perl
# $Id: 24-RSA-SHA512.t 1830 2021-01-26 09:08:12Z willem $	-*-perl-*-
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
RSASHA512.example.	IN	DNSKEY	256 3 10 (
	AwEAAdLaxcxvgdQKF3zSOuXQgwWPQ+dKzJ3Ob4w3r+o73i2MnhE0HBHuTzUZGVjGR05VGqZaJx64
	LNt0Wlxxoxt3Uwaq55t5MzN3LYYYEcMQ1XPhPG1nNuD0LiqlqL+KmQqlAo3cm4F71gr/GXQiPG3O
	WM11ulruDKZpyfYg1NWryu3F ; Key ID = 35741
	)
END

ok( $key, 'set up RSA public key' );


my $keyfile = $filename{keyfile} = $key->privatekeyname;

my $privatekey = IO::File->new( $keyfile, '>' ) or die qq(open: "$keyfile" $!);
print $privatekey <<'END';
Private-key-format: v1.3
Algorithm: 10 (RSASHA512)
Modulus: 0trFzG+B1AoXfNI65dCDBY9D50rMnc5vjDev6jveLYyeETQcEe5PNRkZWMZHTlUaplonHrgs23RaXHGjG3dTBqrnm3kzM3cthhgRwxDVc+E8bWc24PQuKqWov4qZCqUCjdybgXvWCv8ZdCI8bc5YzXW6Wu4MpmnJ9iDU1avK7cU=
PublicExponent: AQAB
PrivateExponent: hTutzo8LBzPVQY8JnluR3rp3Grgd8P0XaQ9q/eQUcM2wt4go0H+31wJkDL9FIU8PRtwiafvQhF7SFiXL/bf5YlCBhCNnYmz8fZuIsZr9OC5tYDFU43AziHYrwhE0myYMJF16nrJTe8RfGnvkvsBUJovu92L86lUOexTQCeIJPeE=
Prime1: 7Pq9K1h4B8UfhEH1+zh+LW4BS6OHPVt7WGPSob/8EqirMqsv1xNxfp/La9abLEJemyXJUZ7SjTN6MbNMHfH1rQ==
Prime2: 48c9vC+ynHyq5mNbVr2pQKoWVdCoeK6wgMHXnoSyMnxwmnP+NNXM1NKDSX7TIJOmGerRL7MGsiTSf3W39IjreQ==
Exponent1: I9lCaJ43eiVtwRohVeGT5NdxRrn0KWn/XL2tDV73iPMPAtk2oXiFgLw3j5alXqqjmSC8Naaq/0U8ROx0pUsG+Q==
Exponent2: ulbOrFsg9WAPt3ZkzKtQATSkHQQcLs5KWqs5p9bKqP6gZ9qohbS6Ywjsmn2EXswrQFyXUTxWJ/pzsg4ttYElkQ==
Coefficient: kZkMqvGGOYegRIujd89qRGgHR/A8RN/BUXiuS3GbUemX9RtFRwtf12BfTAf5glTBL+7kOojarbt+CD+qkFbd6A==
Created: 20141208233433
Publish: 20141208233433
Activate: 20141208233433
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

