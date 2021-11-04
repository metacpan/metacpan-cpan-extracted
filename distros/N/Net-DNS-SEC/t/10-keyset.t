#!/usr/bin/perl
# $Id: 10-keyset.t 1830 2021-01-26 09:08:12Z willem $	-*-perl-*-
#

use strict;
use warnings;
use IO::File;
use Test::More;

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

plan tests => 29;


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
test.tld.	IN	DNSKEY	( 256 3 5
	AQO1gY5UFltQ4f0ZHnXPFQZfcQQNpXK5r0Rk05rLLmY0XeA1lu8ek7W1VHsBjkge9WU7efdp3U4a
	mxULRMQj7F0ByOK318agap2sIWYN13jV1RLxF5GPyLq+tp2ihEyI8x0P8c9RzgVn1ix4Xcoq+vKm
	WqDT1jHE4oBY/DzI8gyuJw== ) ; Key ID = 15791
END

ok( $keyrr1, join ' ', algorithm( $keyrr1->algorithm ), 'public key created' );

my $keyfile1 = $filename{key1} = $keyrr1->privatekeyname;
my $handle1  = IO::File->new( $keyfile1, '>' ) or die qq(open: "$keyfile1" $!);
print $handle1 <<'END';
Private-key-format: v1.2
Algorithm: 5 (RSASHA1)
Modulus: tYGOVBZbUOH9GR51zxUGX3EEDaVyua9EZNOayy5mNF3gNZbvHpO1tVR7AY5IHvVlO3n3ad1OGpsVC0TEI+xdAcjit9fGoGqdrCFmDdd41dUS8ReRj8i6vradooRMiPMdD/HPUc4FZ9YseF3KKvryplqg09YxxOKAWPw8yPIMric=
PublicExponent: Aw==
PrivateExponent: eQEJjWQ84Jaou2mj32NZlPYCs8Oh0R+C7eJnMh7uzZPqzmSfabfOeOL8q7QwFKOY0lFPm+jevGdjXNiCwp2TVWZrFINEMwUpxPJCvQQLh0k9Ah3NN2ELPBSlUjkRa10KaRSVSdDaYUM9X1/ZT/9RQagi4ckuy0x6UcRmoSng/Ms=
Prime1: 3SNqKvY2geGDxgpqUKy2gGKq2LBRZ0CruBsVQXtoBH2dwq1bUScC9HxrTYaGxn2BELZsYRMeGVqZ1WqzsLXeTw==
Prime2: 0h6u5+odYP2A7/eIALrUZtTDEi1rT+k434qR7Tb/4w/UkEIHw5bS/NP+AH2sNXtCzbYUx1h11m5EgDgjgoVUqQ==
Exponent1: k2zxcfl5q+utLrGcNch5quxx5crg74Byery41lJFWFO+gcjni29XTahHiQRZ2akAtc7y62IUEOcROPHNIHk+3w==
Exponent2: jBR0mpwTlf5V9U+wAHyNmeMstsjyNUYl6lxhSM9VQgqNtYFagmSMqI1UAFPII6eB3nljL5BOjvQtqtAXrFjjGw==
Coefficient: YJYWzNpbdj/11mE4kUwaiH9GQbY+uA28tv4aVAwAEcKPaU1QQ2k8Jlm+VXxh9v02QCFJYln3416972oeCx9eyw==
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

my $datarrset = [$keyrr1, $keyrr2];

my $sigrr1 = Net::DNS::RR::RRSIG->create( $datarrset, $keyfile1, ttl => 3600 );

ok( $sigrr1, join ' ', algorithm( $sigrr1->algorithm ), 'signature created' );

my $sigrr2 = Net::DNS::RR::RRSIG->create( $datarrset, $keyfile2, ttl => 3600 );

ok( $sigrr2, join ' ', algorithm( $sigrr2->algorithm ), 'signature created' );


my $keyset = Net::DNS::SEC::Keyset->new($datarrset);
is( ref($keyset), "Net::DNS::SEC::Keyset", "Keyset object created" );


ok( $keyset->string, '$keyset->string' );


$keyset->writekeyset;
ok( Net::DNS::SEC::Keyset->new( $filename{set1} ), "write Keyset object" );

$keyset->writekeyset('prefix-');

my $read = Net::DNS::SEC::Keyset->new( $filename{set2} );
is( ref($read), "Net::DNS::SEC::Keyset", "read Keyset object" );


my @ds = $keyset->extract_ds;

my $string0 = $ds[0]->string;
my $string1 = $ds[1]->string;

my $expect0 = Net::DNS::RR->new('test.tld. IN DS 15791 5 1 C355F0F3F30C69BF2F7EA253ED82FBC280C2496B')->string;
my $expect1 = Net::DNS::RR->new('test.tld. IN DS 63426 8 1 6173eae9bf79853e2c041b1cda02a3d70c86a20b')->string;

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
like( Net::DNS::SEC::Keyset->keyset_err, '/failed.+key/', 'Expected error message' );


#
# The packet contains a keyset as returned from a bind nameserver
# the keyset is signed with a signature valid until 2030 06 ..
#  After that the test may fail :-(

# This is the code snippet used to get such a little packet as below.
#use Net::DNS::Resolver;
#my $res=Net::DNS::Resolver->new();
#$res->nameserver("10.0.53.204");
#$res->dnssec(1);
#my $a_packet=$res->send("sub.tld","DNSKEY");
#$a_packet->print;
#print unpack("H*",$a_packet->data);


my $HexadecimalPacket = "e6cc81a000010004000000010373756203746c
 640000300001c00c00300001000000200086010103050103bc54beaee1
 1dc1a29ba945bf69d0db27b364b2dfe60396efff4c6fb359127ea696e1
 4c66e1c6d23cd6f6c335e1679c61dd3fa4d68a689b8709ea686e43f175
 6831193903613f6a5f3ff039b21eed9faad4edcb43191c76490ca0947a
 9fa726740bc4449d6c58472a605913337d2dbddc94a7271d25c358fdaa
 60fe1272a5f8b9c00c00300001000000200086010003050103f6d63a8a
 b9f775a0c7194d67edb5f249bf398c3d27d2985facf6fb7e25cc35c876
 2eb8ea22200c847963442fb6634916dc2ec21cdbf2c7378799b8e7e399
 e751ca1e25133349cab52ebf3fe8a5bc0239c28d64f4d8f609c191a7d2
 d364578a159701ef73af93946b281f0aac42b42be17362c68d7a54bbb8
 fa7bc6f70f455a75c00c002e000100000020009b003005020000006470
 dc814040c02ced39d40373756203746c6400a7d9db75a4115794f871ec
 71fc7469c74a6be1cf95434a00363506b354bf15656f7556c51355c8dc
 ac7f6c0a4061c0923e0bf341094e586619c2cb316949772ce5bd1e9949
 f91b016f7e6bee0f6878e16b6e59ece086f8d5df68f048524e1bff3c09
 dd15c203d28416600e936451d1646e71611ec95e12d709839369cbc442
 c0c00c002e000100000020009b003005020000006470dc814040c02ced
 fbaf0373756203746c640017c6e59f317119da812c6b1e175e8aaec742
 35a4bfad777e7759fa2daf7959f9611c26e11adde9bdc901c624ca6965
 7b79653495e22647c5e0e5bedfe5524397d769d816746d10b2067472b4
 f9b04fbde8e39d7861bd6773c80f632f55b46c7a537a83f0b5a50200c9
 d2847b71d9dfaa643f558383e6e13d4e75f70029849444000029100000
 0080000000";

$HexadecimalPacket =~ s/\n//g;
$HexadecimalPacket =~ s/\s//g;

my $packetdata = pack( "H*", $HexadecimalPacket );
my $packet     = Net::DNS::Packet->new( \$packetdata );


$keyset = Net::DNS::SEC::Keyset->new($packet);
is( ref($keyset), "Net::DNS::SEC::Keyset", "Keyset object from packet" );

is( join( " ", sort( $keyset->verify ) ), "14804 64431", "Verify method returned the two proper keytags" );


my $keyset2 = Net::DNS::SEC::Keyset->new($datarrset);
is( ref($keyset2), "Net::DNS::SEC::Keyset", "Keyset object from DNSKEY RRset" );

#print $Net::DNS::SEC::Keyset->keyset_err;
#$keyset->print;

#########

my $rr;
my @keyrr;
my @sigrr;


# Note that the order of pushing the RRs is important for successful testing.

# All signatures have expiration date in 2030... this test should work for a while

push( @keyrr, Net::DNS::RR->new( <<'END' ) );
example.com	100 IN	DNSKEY	256 3 5 (
	AQOxFlzX8vShSG3JG2J/fngkgy64RoWr8ovGe7MuvPJqOMHTLM5V8+TJIahSoyUd990ictNv
	hDegUqLtZ8k5oQq44viFCU/H1apdEaJnLnXscVo+08ATlEb90MYznK9K0pm2ixbyspzRrrXp
	nPi9vo9iU2xqWqw/Efha4vfi6QVs4w== )
END


push( @keyrr, Net::DNS::RR->new( <<'END' ) );
example.com	100 IN	DNSKEY	256 3 5 (
	AQO4jhl6ilWV2mYjwWl7kcxrYyQsnnbV7pxXm48p+SgAr+R5SKyihkjg86IjZBQHFJKZ8RsZ
	dhclH2dikM+53uUEhrqVGhsqF8FsNi4nE9aMISiX9Zs61pTYGYboYDvgpD1WwFbD4YVVlfk7
	rCDP/zOE7H/AhkOenK2w7oiO0Jehcw== )
END


push( @keyrr, Net::DNS::RR->new( <<'END' ) );
example.com	100 IN	DNSKEY	256 3 5 (
	AQO5fWabr7bNxDXT8YrIeclI9nvYYdKni3efgJfU749O3QVX9MON6WK0ed00odQF4cLeN3vP
	SdhasLDI3Z3TzyAPBQS926oodxe78K9zwtPT1kzJxvunOdJr6+6a7/+B6rF/cwfWTW50I0+q
	FykldldB44a1uS34u3HgZRQXDmAesw== )
END


push( @keyrr, Net::DNS::RR->new( <<'END' ) );
example.com	100 IN	DNSKEY	256 3 5 (
	AQO6uGWsox2oH36zusGA0+w3uxkZMdByanSCjiaRHtkOA+gIxT8jmFvohxQBpVfYD+xG2pt+
	qUWauWPFPjsIUBoFqHNpqr2/B4CTiZm/rSayHDghZBIMceMa6t4NpaOep79QmiE6oGq6yWRB
	swBkPZx9uZE7BqG+WLKEp136iwWyyQ== )
END


push( @sigrr, Net::DNS::RR->new( <<'END' ) );
example.com	100 IN	RRSIG	DNSKEY 5 2 100 20300101000000 (
	20040601105519 11354 example.com.
	GTqyJTRbKJ0LuWbAnNni1M4JZ1pn+nXY1ZuzZ0Kvt6OMTYCAFMFt0Wv9bncYkUuUSMGM7yGG
	9Z7g7tcdb4TKCqQPYo4gr3Qj/xgC4LESoQs0yAsJtLUiDfO6e4aWHmanpMGyGixYzHriS1pt
	SRzirL1fTgV+kdNs5zBatUHRnQc= )
END


push( @sigrr, Net::DNS::RR->new( <<'END' ) );
example.com	100 IN	RRSIG	DNSKEY 5 2 100 20300101000000 (
	20040601105519 28109 example.com.
	WemQqA+uaeKqCy6sEVBU3LDORG3f+Zmix6qK9j1WL83UMWdd6sxNh0QJ0YL54lh9NBx+Viz7
	gajO+IM4MmayxKY4QVjp+6mHeE5zBVHMpTTur5T0reNtTsa8sHr15fsI49yn5KOvuq+DKG1C
	gI6siM5RdFpDsS3Rmf8fiK1PyTs= )
END


push( @sigrr, Net::DNS::RR->new( <<'END' ) );
example.com	100 IN	RRSIG	DNSKEY 5 2 100 20300101000000 (
	20040601105519 33695 example.com.
	M3yVwTOMw+jAKYY5c6oS4DH7OjOdfMOevpIezdKqWXkehoDg9YOwz8ai17AmfgkjZnsoNu0W
	NMIcaVubR3n02bkVhJb7dEd8bhbegF8T1xkL7rf9EQrPmM5GhHmVC90BGrcEhe//94hdXSVU
	CRBi6KPFWSZDldd1go133bk/b/o= )
END


push( @sigrr, Net::DNS::RR->new( <<'END' ) );
example.com	100 IN	RRSIG	DNSKEY 5 2 100 20300101000000 (
	20040601105519 39800 example.com.
	Mmhn2Ql6ExmyHvZFWgt+CBRw5No8yM0rdH1beU4is5gRbd3I0j5z6PdtpYjAkWiZNdYsRT0o
	P7TQIsADfB0FLIFojoREg8kp+OmbpRTsLTgOQYC95u5WodYGz03O0EbnQ7k4gkje6385G40D
	JVl0xVfujHBMbB+keiSphD3mG4I= )
END


my $ks = Net::DNS::SEC::Keyset->new( [@keyrr], [@sigrr] );

ok( $ks, "Keyset created from two arrays." );


my @ks_sigs = $ks->sigs;
ok( eq_array( [@ks_sigs], [@sigrr] ), "Sigs out equal to sigs in" );

my @ks_keys = $ks->keys;
my @keydiff = key_difference( [@keyrr], [@ks_keys] );

is( scalar(@keydiff), 0, "Keys out equal to keys in" );


$datarrset = [$keyrr1, $keyrr2];

$sigrr1 = Net::DNS::RR::RRSIG->create( $datarrset, $keyfile1, ttl => 3600 );

$sigrr2 = Net::DNS::RR::RRSIG->create( $datarrset, $keyfile2, ttl => 3600 );

ok( $sigrr1, 'RSA signature created' );


$keyset = Net::DNS::SEC::Keyset->new( $datarrset, [$sigrr1] );

my @keytags = $keyset->verify;
is( scalar(@keytags), 1, "Verify method returned the keytags" );

ok( $keyset->verify(15791), "Verification against keytag 15791" );

ok( !$keyset->verify(9734), "Verification against keytag 9734 failed" );
is( $keyset->keyset_err, "No signature made with 9734 found", "Expected error message" );


my $corruptible	 = Net::DNS::RR::RRSIG->create( $datarrset, $keyfile1, ttl => 3600 );
my $unverifiable = Net::DNS::SEC::Keyset->new( $datarrset, [$corruptible] );
my $badsig	 = Net::DNS::RR::RRSIG->create( [$sigrr1], $keyfile1, ttl => 3600 );
$corruptible->sigbin( $badsig->sigbin );

is( scalar( $unverifiable->extract_ds ), 0, 'No DS from unverifiable keyset' );


my $bogus = Net::DNS::RR->new( <<'END' );
bogus.tld.	IN	DNSKEY	257 3 5 (
	AQO1gY5UFltQ4f0ZHnXPFQZfcQQNpXK5r0Rk05rLLmY0XeA1lu8ek7W1VHsBjkge9WU7efdp3U4a
	mxULRMQj7F0ByOK318agap2sIWYN13jV1RLxF5GPyLq+tp2ihEyI8x0P8c9RzgVn1ix4Xcoq+vKm
	WqDT1jHE4oBY/DzI8gyuJw== ; Key ID = 15791
	)
END

my $mixed = Net::DNS::SEC::Keyset->new( [$bogus], [$sigrr1] );

ok( !$mixed, "Mixed keyset not loaded" );
like( Net::DNS::SEC::Keyset->keyset_err, '/No signature.+SEP/', 'Expected error message' );
like( Net::DNS::SEC::Keyset->keyset_err, '/Multiple names/',	'Expected error message' );


eval { $keyset->writekeyset( File::Spec->rel2abs('nonexdir') ) };
my ($exception) = split /\n/, "$@\n";
ok( $exception, "unwritable file\t[$exception]" );


# 0.17 backward compatibility (exercise code for test coverage only)
eval { my $scalar = key_difference( [@keyrr], [@ks_sigs], [] ); };
eval { my @array = key_difference( [@keyrr], [@ks_sigs] ); };


exit;

__END__

