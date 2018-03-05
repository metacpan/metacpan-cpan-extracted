#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Data::Dumper;
use Math::EllipticCurve::Prime;

plan tests => 4;

use_ok( 'Steemit::ECDSA' ) || print "Bail out!\n";

my $curve = Math::EllipticCurve::Prime->from_name('secp256k1');

my $g = $curve->g;

my( $i ) = Steemit::ECDSA::get_recovery_factor( $g->x, $g->y );


my $is_odd = Steemit::ECDSA::recover_y( $g->x, $i );

is( $g->y, $is_odd, "getting y from x with isOdd seems to work");

my $message      = "hello world";
my $key          = Math::BigInt->new(2);
my $pubkey       = Steemit::ECDSA::get_public_key_point( $key );


subtest 'sign and verify' => sub {
   my ( $r, $s,$i ) = Steemit::ECDSA::ecdsa_sign( $message, $key );
   my $recovered_pubkey = Steemit::ECDSA::recoverPubKey($message,$r,$s,$i);

   is( $recovered_pubkey->x, $pubkey->x, "recovered key is the same as the original for x" );
   is( $recovered_pubkey->y, $pubkey->y, "recovered key is the same as the original for y" );


   ok( Steemit::ECDSA::ecdsa_verify( $message, $pubkey, $r, $s ), "signing seems to work with trivial key" );
   ok( Steemit::ECDSA::ecdsa_verify( $message, $recovered_pubkey, $r, $s ), "signing seems to work with recovered key" );
};

subtest 'sign and verify with prerecorded values' => sub {
   my $k = Math::BigInt->from_hex( '1c472b04399ee0add8dc96b49d198b9db259b2eaffbf3f5b43987afca245e969');
   my $r = Math::BigInt->from_hex( '3af55656506144676605bf52742537e72c40d1ae964250fa481a8fc940ec3481');
   my $s = Math::BigInt->from_hex( '67df171b8f4947024a0344fa844eb553709fc9272052c00ae2174c5b43dac864');
   my $i = 1;
   local $::testing_only::inject_k = $k;

   my ( $r2, $s2,$i2 ) = Steemit::ECDSA::ecdsa_sign( $message, $key );

   is( $r2, $r, 'r is the same with injected k' );
   is( $s2, $s, 's is the same with injected k' );
   is( $i2, $i, 'i is the same with injected k' );
   $::testing_only::inject_k = undef;

}
