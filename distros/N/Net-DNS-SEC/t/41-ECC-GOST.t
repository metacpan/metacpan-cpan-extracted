# $Id: 41-ECC-GOST.t 1494 2016-08-22 09:34:07Z willem $	-*-perl-*-
#

use Test::More;

my %prerequisite = (
	Crypt::OpenSSL::Bignum	=> 0,
	Crypt::OpenSSL::EC	=> 1.01,
	Crypt::OpenSSL::ECDSA	=> 0.06,
	Digest::GOST		=> 0.06,
	Digest::GOST::CryptoPro	=> 0,
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

plan tests => 11;


my %filename;

END {
	foreach ( values %filename ) {
		unlink($_) if -e $_;
	}
}


use_ok('Net::DNS');
use_ok('Net::DNS::SEC::Private');
use_ok('Net::DNS::SEC::ECCGOST');


my $key = new Net::DNS::RR <<'END';
ecc-gost.example.	IN	DNSKEY	256 3 12 (
	6VwgNT1BXxXNVpTQXcJQ82PcsCYmI60oN88Plbl028ruvl6DqJby/uBGULHT5FXmZiXBJozE6kP0
	+BirN9YPBQ== ; Key ID = 46387
	)
END

ok( $key, 'set up ECC-GOST public key' );


my $keyfile = $filename{keyfile} = $key->privatekeyname;

open( KEY, ">$keyfile" ) or die "$keyfile $!";
print KEY <<'END';
Private-key-format: v1.3
Algorithm: 12 (ECC-GOST)
PrivateKey: nBnGCP/hYTdJX0znDstyFTVYSA6b0nFeHy0FJUj7LhU=
Created: 20150102211707
Publish: 20150102211707
Activate: 20150102211707
END
close(KEY);

my $private = new Net::DNS::SEC::Private($keyfile);
ok( $private, 'set up ECC-GOST private key' );


my $wrongkey = new Net::DNS::RR <<'END';
ECDSAP256SHA256.example.	IN	DNSKEY	256 3 13 (
	7Y4BZY1g9uzBwt3OZexWk7iWfkiOt0PZ5o7EMip0KBNxlBD+Z58uWutYZIMolsW8v/3rfgac45lO
	IikBZK4KZg== ; Key ID = 44222
	)
END

ok( $wrongkey, 'set up non-ECC-GOST public key' );


my $wrongfile = $filename{wrongfile} = $wrongkey->privatekeyname;

open( KEY, ">$wrongfile" ) or die "$wrongfile $!";
print KEY <<'END';
Private-key-format: v1.3
Algorithm: 13 (ECDSAP256SHA256)
PrivateKey: m/dWhFblAGQnabJoKbs0vXoQidjNzlTcbPAqntUXWi0=
Created: 20141209020038
Publish: 20141209020038
Activate: 20141209020038
END
close(KEY);

my $wrongprivate = new Net::DNS::SEC::Private($wrongfile);
ok( $wrongprivate, 'set up non-ECC-GOST private key' );


my $sigdata = 'arbitrary data';

my $signature = Net::DNS::SEC::ECCGOST->sign( $sigdata, $private );
ok( $signature, 'signature created using private key' );

my $validated = Net::DNS::SEC::ECCGOST->verify( $sigdata, $key, $signature );
ok( $validated, 'signature validated using public key' );


ok( !eval { Net::DNS::SEC::ECCGOST->sign( $sigdata, $wrongprivate ) },
	'signature not generated using wrong private key' );

ok( !eval { Net::DNS::SEC::ECCGOST->verify( $sigdata, $wrongkey, $signature ) },
	'signature not validated using wrong public key' );


exit;

__END__

