#!/usr/bin/perl
# $Id: 10-keyset.t 1924 2023-05-17 13:56:25Z willem $	-*-perl-*-
#

use strict;
use warnings;
use IO::File;
use Test::More;
use TestToolkit;

my %prerequisite = (
	'Net::DNS::SEC' => 1.15,
	'Digest::SHA'	=> 5.23,
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

plan tests => 27;


use_ok('Net::DNS::SEC::Keyset');


my %filename = (
	set1 => 'keyset-test.tld.',
	set2 => 'prefix-test.tld.',
	set3 => 'keyset-corrupt-test.tld.',
	);

END {
	foreach ( values %filename ) {
		unlink($_) if -e $_;
	}
}


#
# RSA keypair 1
#
my $keyrr1 = Net::DNS::RR->new( <<'END' );
test.tld.	IN	DNSKEY	( 257 3 10
	AwEAAb/7yz0lSf3nFy7MPhkbnqOlaExKlJ8rMmYVEhFYZ5qS/ufQbfQ3stb0opr68eitrauolthm
	P325OvNxdzSq5rgURjx9ZitDlhxDyPfQhDzY+/CBhY/z++DRIr+v3AN/7kRW8sYwC+2Hoa1+VxQZ
	1fSQ4J46ZwoN5slpar9G/Gv5aPgsvweQDI285eQVlIQ9NL00bODOHzoKvh9BAx07MOOcT9q6r9xs
	MPg6M4C8ykH2zVY5x1iGxT8Syzh/mecSiJtv+b1W4j49pCNj19uenW3oUnyfHg/FBmQpxTiHqs6b
	1ZfVH7akvsQqwk12xT0hDEfeyj4jswDiSsEsLqt1DM0= ) ; Key ID = 39948
END

ok( $keyrr1, join ' ', algorithm( $keyrr1->algorithm ), 'public key created' );

my $keyfile1 = $filename{key1} = $keyrr1->privatekeyname;
my $handle1  = IO::File->new( $keyfile1, '>' ) or die qq(open: "$keyfile1" $!);
print $handle1 <<'END';
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
close($handle1);


#
# RSA keypair 2
#
my $keyrr2 = Net::DNS::RR->new( <<'END' );
test.tld.	IN	DNSKEY	( 256 3 8
	AwEAAcXr1phQtnOdThOrgcwRplS/btblbtLGeHQoba55Gr8Scbx7AAw+LjwtFmbPlDhklC8+4BAf
	QB+6Jv7hOFT45J/RqDV3W5p0qDYcLYJObNbiFxQ64ogMYHx62w4oUeTS5CvpHNzSoiyhhFlf71RL
	EVeBK798h+hdPeEWvHdzbwwMxZGIXP/eNN5u5tkNExuuqq3e6BeguCLsuLgMzHdfpl7W20z3BExD
	c28DgPRWHJtJcB+iUd5oQdrw+G9qSq4kb7vk3OZUGrgkZskicT1A5rQsOgc4SrT4d25Qd6fthmi2
	hZ86Y/2DP/NfR1mwWaN8ty7daqdcNpFQmKwQ+qpIV5c= ) ; Key ID = 63427
END

ok( $keyrr2, join ' ', algorithm( $keyrr2->algorithm ), 'public key created' );

my $keyfile2 = $filename{key2} = $keyrr2->privatekeyname;
my $handle2  = IO::File->new( $keyfile2, '>' ) or die qq(open: "$keyfile2" $!);
print $handle2 <<'END';
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
close($handle2);


# Create keysets

my $keyrrset = [$keyrr1, $keyrr2];

my $sigrr1 = Net::DNS::RR::RRSIG->create( $keyrrset, $keyfile1, ttl => 3600 );

ok( $sigrr1, join ' ', algorithm( $sigrr1->algorithm ), 'signature created' );

my $sigrr2 = Net::DNS::RR::RRSIG->create( $keyrrset, $keyfile2, ttl => 3600 );

ok( $sigrr2, join ' ', algorithm( $sigrr2->algorithm ), 'signature created' );


my $keyset = Net::DNS::SEC::Keyset->new($keyrrset);
is( ref($keyset), "Net::DNS::SEC::Keyset", "Keyset object created" );


ok( $keyset->string, '$keyset->string' );


$keyset->writekeyset;
ok( Net::DNS::SEC::Keyset->new( $filename{set1} ), "write Keyset object" );

$keyset->writekeyset('prefix-');

my $read = Net::DNS::SEC::Keyset->new( $filename{set2} );
is( ref($read), "Net::DNS::SEC::Keyset", "read Keyset object" );


my @ds = $keyset->extract_ds( digtype => 'SHA-256' );

my $string0 = $ds[0]->string;
my $string1 = $ds[1]->string;

my $expect0 = Net::DNS::RR->new('test.tld. IN DS 39948 10 2 94e22598a45d485926d8e3944f871dc605ef52db59f346066bf2b0d20d6d8ed4')->string;
my $expect1 = Net::DNS::RR->new('test.tld. IN DS 63426 8  2 ee74fe86f0d9499ef1abe414039ffaf34f05d3e71a4899882c714395d9047368')->string;

my $alg0 = algorithm( $ds[0]->algorithm );
my $dig0 = digtype( $ds[0]->digtype );
is( $string0, $expect0, "DS ($alg0/$dig0) created from keyset" );

my $alg1 = algorithm( $ds[1]->algorithm );
my $dig1 = digtype( $ds[1]->digtype );
is( $string1, $expect1, "DS ($alg1/$dig1) created from keyset" );


##
#  Corrupted keyset

my $handle3 = IO::File->new( $filename{set3}, '>' ) or die qq(open: "$filename{set3}" $!);

print $handle3 $keyrr1->string, "\n";
print $handle3 $keyrr2->string, "\n";

my $sigstr = lc $sigrr1->string;				# corrupt the base64 signature
$sigstr =~ s/in.rrsig/IN RRSIG/;				# fix collateral damage
$sigstr =~ s/dnskey/DNSKEY/;

print $handle3 $sigstr . "\n";
print $handle3 $sigrr2->string . "\n";

close($handle3);

my $corrupt = Net::DNS::SEC::Keyset->new( $filename{set3} );

ok( !$corrupt, "Corrupted keyset not loaded" );
my $corrupt_keyset = Net::DNS::SEC::Keyset->keyset_err;
like( $corrupt_keyset, '/failed.+key/', "Expected error [$corrupt_keyset]" );


my @keyrr = ( $keyrr1, $keyrr2 );
my @sigrr = ( $sigrr1, $sigrr2 );

my $ks = Net::DNS::SEC::Keyset->new( [@keyrr], [@sigrr] );

ok( $ks, "Keyset created from two arrays." );

my @ks_sigs = $ks->sigs;
ok( eq_array( [@ks_sigs], [@sigrr] ), "Sigs out equal to sigs in" );

my @ks_keys = $ks->keys;
my @keydiff = key_difference( [@keyrr], [@ks_keys] );

is( scalar(@keydiff), 0, "Keys out equal to keys in" );


my @keytags = $ks->verify;
is( scalar(@keytags), 2, "Verify method returned the keytags" );

my $good_tag = 39948;
ok( $ks->verify($good_tag), "Verification against keytag $good_tag" );

my $bad_tag = 9734;
ok( !$ks->verify($bad_tag), "Verification against keytag $bad_tag failed" );
my $missing_signature = Net::DNS::SEC::Keyset->keyset_err;
like( $missing_signature, "/No signature.+$bad_tag/", "Expected error [$missing_signature]" );


my $corruptible	 = Net::DNS::RR::RRSIG->create( $keyrrset, $keyfile1, ttl => 3600 );
my $unverifiable = Net::DNS::SEC::Keyset->new( $keyrrset, [$corruptible] );
my $badsig	 = Net::DNS::RR::RRSIG->create( [$sigrr1], $keyfile1, ttl => 3600 );
$corruptible->sigbin( $badsig->sigbin );

is( scalar( $unverifiable->extract_ds ), 0, 'No DS from unverifiable keyset' );


my $bogus = Net::DNS::RR->new( <<'END' );
bogus.tld.	IN	DNSKEY	257 3 5 (
	AQO1gY5UFltQ4f0ZHnXPFQZfcQQNpXK5r0Rk05rLLmY0XeA1lu8ek7W1VHsBjkge9WU7efdp3U4a
	mxULRMQj7F0ByOK318agap2sIWYN13jV1RLxF5GPyLq+tp2ihEyI8x0P8c9RzgVn1ix4Xcoq+vKm
	WqDT1jHE4oBY/DzI8gyuJw== ; Key ID = 15792
	)
END

my $mixed = Net::DNS::SEC::Keyset->new( [$bogus], [$sigrr1] );
ok( !$mixed, "Mixed keyset not loaded" );
like( Net::DNS::SEC::Keyset->keyset_err, '/No signature.+SEP/', 'Expected "No signature for KSK" error' );
like( Net::DNS::SEC::Keyset->keyset_err, '/Multiple names/',	'Expected "Multiple names" error' );


my $packet = Net::DNS::Packet->new( 'test.tld', 'DNSKEY' );
$packet->push( answer => @keyrr, @sigrr );
ok( Net::DNS::SEC::Keyset->new($packet)->verify(), "Verify keyset extracted from packet" );


ok( Net::DNS::SEC::Keyset->new( [$keyrr2] )->verify(), "Verify keyset with no KSK" );


exception( 'unwritable file', sub { $keyset->writekeyset( File::Spec->rel2abs('nonexdir') ) } );


# 0.17 backward compatibility (exercise code for test coverage only)
eval { my $scalar = key_difference( [@keyrr], [@ks_sigs], [] ); };
eval { my @array = key_difference( [@keyrr], [@ks_sigs] ); };


exit;

__END__

