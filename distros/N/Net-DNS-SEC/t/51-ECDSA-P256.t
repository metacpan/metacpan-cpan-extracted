# $Id: 51-ECDSA-P256.t 1616 2018-01-22 08:54:52Z willem $	-*-perl-*-
#

use strict;
use Test::More;

my %prerequisite = (
	'Digest::SHA'  => 5.23,
	'Net::DNS'     => 1.01,
	'MIME::Base64' => 2.13,
	);

foreach my $package ( sort keys %prerequisite ) {
	my @revision = grep $_, $prerequisite{$package};
	next if eval "use $package @revision; 1;";
	plan skip_all => "missing prerequisite $package @revision";
	exit;
}

plan tests => 12;


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
ECDSAP256SHA256.example.	IN	DNSKEY	256 3 13 (
	7Y4BZY1g9uzBwt3OZexWk7iWfkiOt0PZ5o7EMip0KBNxlBD+Z58uWutYZIMolsW8v/3rfgac45lO
	IikBZK4KZg== ; Key ID = 44222
	)
END

ok( $key, 'set up ECDSA public key' );


my $keyfile = $filename{keyfile} = $key->privatekeyname;

open( KEY, ">$keyfile" ) or die "$keyfile $!";
print KEY <<'END';
Private-key-format: v1.3
Algorithm: 13 (ECDSAP256SHA256)
PrivateKey: m/dWhFblAGQnabJoKbs0vXoQidjNzlTcbPAqntUXWi0=
Created: 20141209020038
Publish: 20141209020038
Activate: 20141209020038
END
close(KEY);

my $private = new Net::DNS::SEC::Private($keyfile);
ok( $private, 'set up ECDSA private key' );


my $wrongkey = new Net::DNS::RR <<'END';
ecc-gost.example.	IN	DNSKEY	256 3 12 (
	6VwgNT1BXxXNVpTQXcJQ82PcsCYmI60oN88Plbl028ruvl6DqJby/uBGULHT5FXmZiXBJozE6kP0
	+BirN9YPBQ== ; Key ID = 46387
	)
END

ok( $wrongkey, 'set up non-ECDSA public key' );


my $wrongfile = $filename{wrongfile} = $wrongkey->privatekeyname;

open( KEY, ">$wrongfile" ) or die "$wrongfile $!";
print KEY <<'END';
Private-key-format: v1.3
Algorithm: 12 (ECC-GOST)
PrivateKey: nBnGCP/hYTdJX0znDstyFTVYSA6b0nFeHy0FJUj7LhU=
Created: 20150102211707
Publish: 20150102211707
Activate: 20150102211707
END
close(KEY);

my $wrongprivate = new Net::DNS::SEC::Private($wrongfile);
ok( $wrongprivate, 'set up non-ECDSA private key' );


my $sigdata = 'arbitrary data';

my $signature = Net::DNS::SEC::ECDSA->sign( $sigdata, $private );
ok( $signature, 'signature created using private key' );

my $verified = Net::DNS::SEC::ECDSA->verify( $sigdata, $key, $signature );
ok( $verified, 'signature verified using public key' );


ok( !eval { Net::DNS::SEC::ECDSA->sign( $sigdata, $wrongprivate ) },
	'signature not created using wrong private key' );

ok( !eval { Net::DNS::SEC::ECDSA->verify( $sigdata, $wrongkey, $signature ) },
	'signature not verified using wrong public key' );

ok( !eval { Net::DNS::SEC::ECDSA->verify( $sigdata, $key, undef ) },
	'signature not verified if empty or undefined' );


exit;

__END__

