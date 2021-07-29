#!perl
use 5.10.0;
use strict;
use warnings;
use utf8;
use Test::More tests => 124;

use QRCode::Base45;

is(encode_base45(undef), '', 'encode undef');
is(encode_base45(''), '', 'encode ""');

is(decode_base45(undef), '', 'decode undef');
is(decode_base45(''), '', 'decode ""');

for my $input ('0', '1', '_', '1234', 'ABCDEFG') {
	eval { decode_base45($input); };
	like($@, qr/invalid input length/, "invalid length detection ($input)");
}

for my $input ('_0', '9(', 'A"', "X'", " \t", "ABCDEF01234a", "ABcDEF") {
	eval { decode_base45($input); };
	like($@, qr/invalid character/, "invalid character detection ($input)");
}

my %testdata = (
	# From the IETF draft
	'BB8' => 'AB',
	'%69 VD92EX0' => 'Hello!!',
	'UJCLQE7W581' => 'base-45',
	'QED8WEX0' => 'ietf!',
	# Basic alphabet
	'00' => "\x00",
	'10' => "\x01",
	'20' => "\x02",
	'30' => "\x03",
	'40' => "\x04",
	'50' => "\x05",
	'60' => "\x06",
	'70' => "\x07",
	'80' => "\x08",
	'90' => "\x09",
	'A0' => "\x0a",
	'B0' => "\x0b",
	'C0' => "\x0c",
	'D0' => "\x0d",
	'E0' => "\x0e",
	'F0' => "\x0f",
	'G0' => "\x10",
	'H0' => "\x11",
	'I0' => "\x12",
	'J0' => "\x13",
	'K0' => "\x14",
	'L0' => "\x15",
	'M0' => "\x16",
	'N0' => "\x17",
	'O0' => "\x18",
	'P0' => "\x19",
	'Q0' => "\x1a",
	'R0' => "\x1b",
	'S0' => "\x1c",
	'T0' => "\x1d",
	'U0' => "\x1e",
	'V0' => "\x1f",
	'W0' => "\x20",
	'X0' => "\x21",
	'Y0' => "\x22",
	'Z0' => "\x23",
	' 0' => "\x24",
	'$0' => "\x25",
	'%0' => "\x26",
	'*0' => "\x27",
	'+0' => "\x28",
	'-0' => "\x29",
	'.0' => "\x2a",
	'/0' => "\x2b",
	':0' => "\x2c",
	'01' => "\x2d",

);

for my $t (sort keys %testdata) {
	is(encode_base45($testdata{$t}), $t, "encode '$testdata{$t}'");
	is(decode_base45($t), $testdata{$t}, "decode '$t'");
}

use Encode;

my %utf8_testdata = (
	'Příliš žluťoučký kůň' => 'M9AXJJQ-LWGDSGK.:O0WDH:O34E7%O2SD-+N4SD.9M13',
	'ようこそ！' => 'CYSXDH%GGBYSEVIGHG$DU*2',
	'🐢' => '*IU CI',
	'→←' => 'USSRPIN0H',
);

for my $t (sort keys %utf8_testdata) {
	my $encoded = encode_base45($t);
	my $bytes = Encode::encode('UTF-8', $t);
	is($encoded, $utf8_testdata{$t}, "encode utf8 '$bytes'");
	is(decode_base45($encoded), $bytes, "decode utf8 encode('$encoded')");
}

done_testing();

diag( "Testing QRCode::Base45 $QRCode::Base45::VERSION, Perl $], $^X" );

