#!perl
use 5.006;
use strict;
use warnings;
use Test::More;
use Data::Dumper;

plan tests => 5;

use_ok( 'Steemit::WsClient' ) || print "Bail out!\n";

diag( "Testing Steemit $Steemit::WsClient::VERSION, Perl $], $^X" );

my $wif = '5HueCGU8rMjxEXxiPuD5BDku4MkFqeZyd4dZ1jvhTVqvbTLvyTJ';
my $steem = Steemit::WsClient->new( posting_key => $wif );



my $binary_private_key = $steem->plain_posting_key();
my $hex_key = unpack "H*", $binary_private_key;

is( uc( $hex_key) , '0C28FCA386C7A227600B2FE50B7CAE11EC86D3BF1FBE471BE89827E19D72AA1D', "private key correctly extracted from wif format" );

isa_ok( $steem, 'Steemit::WsClient', 'constructor will return a Steemit object');

$wif = '5HueCGU8rMjxEXxiPuD5BDku4MkFqeZyd4dZ1jvhTVqvbTLvyTG';
$steem = Steemit::WsClient->new( posting_key => $wif );
eval{ $steem->plain_posting_key() };
my $error = $@;
like( $error, qr/invalid checksum/, 'checksum is checked' );


$wif = 'FHueCGU8rMjxEXxiPuD5BDku4MkFqeZyd4dZ1jvhTVqvbTLvyTJ';
$steem = Steemit::WsClient->new( posting_key => $wif );
eval{ $steem->plain_posting_key() };
$error = $@;
like( $error, qr/invalid version/, 'version is checked' );


sub data {
    return {
        wif => '',
        decoded_base58 => '',
        private_key    => '',
    }
}
