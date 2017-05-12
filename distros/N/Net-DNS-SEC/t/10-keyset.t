# $Id: 10-keyset.t 1494 2016-08-22 09:34:07Z willem $	-*-perl-*-
#

use Test::More;

my %prerequisite = (
	Net::DNS		=> 1.01,
	Net::DNS::SEC::Private	=> 0,
	Net::DNS::SEC::RSA	=> 0,
	);

foreach my $package ( sort keys %prerequisite ) {
	my @revision = grep $_, $prerequisite{$package};
	eval "use $package @revision";
	next unless $@;
	plan skip_all => "missing prerequisite $package @revision";
	exit;
}

plan tests => 30;


use_ok('Net::DNS::SEC');					# test 1
use_ok('Net::DNS::SEC::Keyset');				# test 2


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
my $keyrr1 = new Net::DNS::RR <<'END';
test.tld.	IN	DNSKEY	256 3 5 (
	AQO1gY5UFltQ4f0ZHnXPFQZfcQQNpXK5r0Rk05rLLmY0XeA1lu8ek7W1VHsBjkge9WU7efdp3U4a
	mxULRMQj7F0ByOK318agap2sIWYN13jV1RLxF5GPyLq+tp2ihEyI8x0P8c9RzgVn1ix4Xcoq+vKm
	WqDT1jHE4oBY/DzI8gyuJw== )
	; Key ID = 15791
END

ok( $keyrr1, join ' ', algorithm( $keyrr1->algorithm ), 'public key created' );

my $keyfile1 = $filename{key1} = $keyrr1->privatekeyname;
open( KEY1, ">$keyfile1" ) or die "Could not open $keyfile1";
print KEY1 << 'END';
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
close(KEY1);


#
# RSA keypair 2
#
my $keyrr2 = new Net::DNS::RR <<'END';
test.tld.	IN	DNSKEY	( 256 3 8
	AwEAAZRSF/5NLnExp5n4M6ynF2Yok3N2aG9AWu8/vKQrZGFQcbL+WPGYbWUtMpiNXmvzTr2j86kN
	QU4wBawm589mjzXgVQRfXYDMMFhHMtagzEKOiNy2ojhhFyS7r2O2vUbo4hGbnM54ynSM1al+ygKU
	Gy1TNzHuYMiwh+gsQCsC5hfJ )
	; Key ID = 35418
END

ok( $keyrr2, join ' ', algorithm( $keyrr2->algorithm ), 'public key created' );

my $keyfile2 = $filename{key2} = $keyrr2->privatekeyname;
open( KEY2, ">$keyfile2" ) or die "Could not open $keyfile2";
print KEY2 << 'END';
Private-key-format: v1.2
Algorithm: 8 (RSASHA256)
Modulus: lFIX/k0ucTGnmfgzrKcXZiiTc3Zob0Ba7z+8pCtkYVBxsv5Y8ZhtZS0ymI1ea/NOvaPzqQ1BTjAFrCbnz2aPNeBVBF9dgMwwWEcy1qDMQo6I3LaiOGEXJLuvY7a9RujiEZucznjKdIzVqX7KApQbLVM3Me5gyLCH6CxAKwLmF8k=
PublicExponent: AQAB
PrivateExponent: c74UZyhHo6GCDs73VDYYNmpXlnTCTn7D94ufY+VQsfgaofmF4xJ128yHfTBkjI0T1z1H+ZYUbjVfV9YMc3avLcXAb4YOEuNw0CSZrtTFc/oTvAyM9tKoa7hB9MSlYtmYvaWiEatHzKL0wYvo71jtfoTyDLQTISzrBWsA+K1a3hk=
Prime1: wvw2lVu+kepiu0fasCrA3BlemVJ3XvWdd/y0sB5+egVGIJCn1bgkaSL/IP+683K28tN7hQYzMGiDBPymu3FeAw==
Prime2: wruzE41ctH5D2SLhW4pi/pz+WSyeBUSvsmUe5kr4c9mlIqYUK1k72kmsjjZtD4eJsjq3xb/VGi+pcMuK2t1/Qw==
Exponent1: lgk3AxTWfjcqA8wVpesv/ezzku0W95Xtto9YhhDg54m5XYOR8e1A7znDsaO2OnAyAIXlDQYpS32QG71Bmwhv+w==
Exponent2: KyNVekFYhgtqkFFvxs2TPIAewDZoExayLTzFaZK2E0PllxVfZnLwFV04wpA//K6zzC3BxCbI2HIygPA2JGHo7Q==
Coefficient: R3pSnerhKwfAHrH3iyojUzKzhM+AQ+97CWavx36eyKT3Yr/SIDANeeXGlT9U7RdxbkZzyeWbFNCnT+b89UX1RQ==
END
close(KEY2);


# Create keysets

my $datarrset = [$keyrr1, $keyrr2];

my $sigrr1 = create Net::DNS::RR::RRSIG( $datarrset, $keyfile1, ttl => 3600 );

ok( $sigrr1, join ' ', algorithm( $sigrr1->algorithm ), 'signature created' );

my $sigrr2 = create Net::DNS::RR::RRSIG( $datarrset, $keyfile2, ttl => 3600 );

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

my $expect0 = new Net::DNS::RR('test.tld. IN DS 15791 5 1 C355F0F3F30C69BF2F7EA253ED82FBC280C2496B')->string;
my $expect1 = new Net::DNS::RR('test.tld. IN DS 35418 8 1 6f3dd1c760c2a4971b3d44ce20e3cb8b60d7aff6')->string;

my $alg0 = algorithm( $ds[0]->algorithm );
my $dig0 = digtype( $ds[0]->digtype );
is( $string0, $expect0, "DS ($alg0/$dig0) created from keyset" );

my $alg1 = algorithm( $ds[1]->algorithm );
my $dig1 = digtype( $ds[1]->digtype );
is( $string1, $expect1, "DS ($alg1/$dig1) created from keyset" );


##
#  Corrupted keyset

open( KEYSET, ">$filename{set3}" ) or die "Could not open $filename{set3}";

print KEYSET $keyrr1->string, "\n";
print KEYSET $keyrr2->string, "\n";

my $sigstr = lc $sigrr1->string;				# corrupt the base64 signature
$sigstr =~ s/in.rrsig.dnskey/IN RRSIG DNSKEY/;			# fix collateral damage

print KEYSET $sigstr . "\n";
print KEYSET $sigrr2->string . "\n";

close(KEYSET);

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
my $packet = Net::DNS::Packet->new( \$packetdata );


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

$rr = Net::DNS::RR->new(
	"example.com	100 IN	DNSKEY	256 3 5 (
					AQOxFlzX8vShSG3JG2J/fngkgy64RoWr8ovG
					e7MuvPJqOMHTLM5V8+TJIahSoyUd990ictNv
					hDegUqLtZ8k5oQq44viFCU/H1apdEaJnLnXs
					cVo+08ATlEb90MYznK9K0pm2ixbyspzRrrXp
					nPi9vo9iU2xqWqw/Efha4vfi6QVs4w==
					) "
	);

push( @keyrr, $rr );


$rr = Net::DNS::RR->new(
	"example.com	100 IN	DNSKEY	256 3 5 (
					AQO4jhl6ilWV2mYjwWl7kcxrYyQsnnbV7pxX
					m48p+SgAr+R5SKyihkjg86IjZBQHFJKZ8RsZ
					dhclH2dikM+53uUEhrqVGhsqF8FsNi4nE9aM
					ISiX9Zs61pTYGYboYDvgpD1WwFbD4YVVlfk7
					rCDP/zOE7H/AhkOenK2w7oiO0Jehcw==
					) "
	);

push( @keyrr, $rr );


$rr = Net::DNS::RR->new(
	"example.com	100 IN	DNSKEY	256 3 5 (
					AQO5fWabr7bNxDXT8YrIeclI9nvYYdKni3ef
					gJfU749O3QVX9MON6WK0ed00odQF4cLeN3vP
					SdhasLDI3Z3TzyAPBQS926oodxe78K9zwtPT
					1kzJxvunOdJr6+6a7/+B6rF/cwfWTW50I0+q
					FykldldB44a1uS34u3HgZRQXDmAesw==
					) "
	);

push( @keyrr, $rr );


$rr = Net::DNS::RR->new(
	"example.com	100 IN	DNSKEY	256 3 5 (
					AQO6uGWsox2oH36zusGA0+w3uxkZMdByanSC
					jiaRHtkOA+gIxT8jmFvohxQBpVfYD+xG2pt+
					qUWauWPFPjsIUBoFqHNpqr2/B4CTiZm/rSay
					HDghZBIMceMa6t4NpaOep79QmiE6oGq6yWRB
					swBkPZx9uZE7BqG+WLKEp136iwWyyQ==
					) "
	);

push( @keyrr, $rr );


$rr = Net::DNS::RR->new(
	"example.com	100 IN	RRSIG	DNSKEY 5 2 100 20300101000000 (
					20040601105519 11354 example.com.
					GTqyJTRbKJ0LuWbAnNni1M4JZ1pn+nXY1Zuz
					Z0Kvt6OMTYCAFMFt0Wv9bncYkUuUSMGM7yGG
					9Z7g7tcdb4TKCqQPYo4gr3Qj/xgC4LESoQs0
					yAsJtLUiDfO6e4aWHmanpMGyGixYzHriS1pt
					SRzirL1fTgV+kdNs5zBatUHRnQc=) "
	);

push( @sigrr, $rr );


$rr = Net::DNS::RR->new(
	"example.com	100 IN	RRSIG	DNSKEY 5 2 100 20300101000000 (
					20040601105519 28109 example.com.
					WemQqA+uaeKqCy6sEVBU3LDORG3f+Zmix6qK
					9j1WL83UMWdd6sxNh0QJ0YL54lh9NBx+Viz7
					gajO+IM4MmayxKY4QVjp+6mHeE5zBVHMpTTu
					r5T0reNtTsa8sHr15fsI49yn5KOvuq+DKG1C
					gI6siM5RdFpDsS3Rmf8fiK1PyTs= )"
	);

push( @sigrr, $rr );


$rr = Net::DNS::RR->new(
	"example.com	100 IN	RRSIG	DNSKEY 5 2 100 20300101000000 (
					20040601105519 33695 example.com.
					M3yVwTOMw+jAKYY5c6oS4DH7OjOdfMOevpIe
					zdKqWXkehoDg9YOwz8ai17AmfgkjZnsoNu0W
					NMIcaVubR3n02bkVhJb7dEd8bhbegF8T1xkL
					7rf9EQrPmM5GhHmVC90BGrcEhe//94hdXSVU
					CRBi6KPFWSZDldd1go133bk/b/o= )"
	);

push( @sigrr, $rr );


$rr = Net::DNS::RR->new(
	"example.com	100 IN	RRSIG	DNSKEY 5 2 100 20300101000000 (
					20040601105519 39800 example.com.
					Mmhn2Ql6ExmyHvZFWgt+CBRw5No8yM0rdH1b
					eU4is5gRbd3I0j5z6PdtpYjAkWiZNdYsRT0o
					P7TQIsADfB0FLIFojoREg8kp+OmbpRTsLTgO
					QYC95u5WodYGz03O0EbnQ7k4gkje6385G40D
					JVl0xVfujHBMbB+keiSphD3mG4I= )"
	);

push( @sigrr, $rr );


my $ks = Net::DNS::SEC::Keyset->new( \@keyrr, \@sigrr );

ok( $ks, "Keyset created from two arrays." );


my @ks_sigs = $ks->sigs;
ok( eq_array( \@ks_sigs, \@sigrr ), "Sigs out equal to sigs in" );

my @ks_keys = $ks->keys;
my @keydiff = key_difference( \@keyrr, \@ks_keys );

is( scalar(@keydiff), 0, "Keys out equal to keys in" );


$datarrset = [$keyrr1, $keyrr2];

$sigrr1 = create Net::DNS::RR::RRSIG( $datarrset, $keyfile1, ttl => 3600 );

$sigrr2 = create Net::DNS::RR::RRSIG( $datarrset, $keyfile2, ttl => 3600 );

ok( $sigrr1, 'RSA signature created' );


$keyset = Net::DNS::SEC::Keyset->new( $datarrset, [$sigrr1] );

my @keytags = $keyset->verify;
is( scalar(@keytags), 1, "Verify method returned the keytags" );

ok( $keyset->verify(15791), "Verification against keytag 15791" );

ok( !$keyset->verify(9734), "Verification against keytag 9734 failed" );
is( $keyset->keyset_err, "No signature made with 9734 found", "Expected error message" );


my $corruptible = create Net::DNS::RR::RRSIG( $datarrset, $keyfile1, ttl => 3600 );
my $unverifiable = Net::DNS::SEC::Keyset->new( $datarrset, [$corruptible] );
my $badsig = create Net::DNS::RR::RRSIG( [$sigrr1], $keyfile1, ttl => 3600 );
$corruptible->sigbin( $badsig->sigbin );

is( scalar( $unverifiable->extract_ds ), 0, 'No DS from unverifiable keyset' );


my $bogus = new Net::DNS::RR <<'END';
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
my $exception = $1 if $@ =~ /^(.+)\n/;
ok( $exception ||= '', "unwritable file\t[$exception]" );


# 0.17 backward compatibility (exercise code for test coverage only)
eval { my $scalar = key_difference( \@keyrr, \@ks_sigs, [] ); };
eval { my @array = key_difference( \@keyrr, \@ks_sigs ); };


exit;

