#!perl -T

use Test::More tests => 5;

BEGIN {
	use Net::Random::QRBG;
}

my $obj = Net::Random::QRBG->new(user => "NRQRBG", pass => "NRQRBG");
isa_ok($obj,"Net::Random::QRBG");

my $char = $obj->getChar();
cmp_ok( $char, '<', 256, 'getChar');

my $hex = $obj->getHexChar();
like($hex, '/[0-9A-F]/i' ,'HexChar');

my $short = $obj->getShort();
cmp_ok( $short, '<', 65536, 'getShort' );

my $long = $obj->getLong();
cmp_ok( $long, '<', 4294967296, 'getLong' );


