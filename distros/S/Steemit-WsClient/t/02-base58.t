#!perl
use 5.006;
use strict;
use warnings;
use Test::More;

plan tests => 4;

use_ok( 'Steemit::Base58' ) || print "Bail out!\n";

my $binary = pack "Z*", "Hello Steemit";

diag $binary;

my $base58 = Steemit::Base58::encode_base58($binary);
diag "base58: ".$base58;

my $binary2 = Steemit::Base58::decode_base58( $base58 );

is( $binary, $binary2, "conversion back and forth works");
#https://en.bitcoin.it/wiki/Wallet_import_format

my $wif = '5HueCGU8rMjxEXxiPuD5BDku4MkFqeZyd4dZ1jvhTVqvbTLvyTJ';

my $key = Steemit::Base58::decode_base58( $wif );

is( uc( unpack('H*', $key) ), '800C28FCA386C7A227600B2FE50B7CAE11EC86D3BF1FBE471BE89827E19D72AA1D507A5B8D', "decoding from the bitcoinpage works" );

is( Steemit::Base58::encode_base58( $key), $wif, "encoding binary works too ");

diag(  uc( unpack('H*', $key) ) );


