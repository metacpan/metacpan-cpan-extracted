#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Protocol::Matrix qw( sign_json signed_json encode_json_for_signing verify_json_signature );

use Crypt::NaCl::Sodium;
use MIME::Base64 qw( decode_base64 );

my $sign = Crypt::NaCl::Sodium->sign;
my ( $pkey, $skey ) = $sign->keypair;

# Signing
{
   my %h = (
      data => "here",
   );

   sign_json( \%h,
      secret_key => $skey,
      origin     => "localhost",
      key_id     => "ed25591:1",
   );

   ok( exists $h{signatures}{"localhost"}{"ed25591:1"},
      'Hash has signature added to it' );

   ok( $sign->verify(
         decode_base64( $h{signatures}{"localhost"}{"ed25591:1"} ),
         encode_json_for_signing( \%h ),
         $pkey
      ), 'Signature passes verify check' );
}

# signed_json
{
   my %h = (
      data => "here",
   );

   my $signed = signed_json( \%h,
      secret_key => $skey,
      origin     => "localhost",
      key_id     => "ed25591:1",
   );

   ok( exists $signed->{signatures}{"localhost"}{"ed25591:1"},
      'Returned hash has signature added to it' );
   ok( !exists $h{signatures}, 'Original hash is unmodified' );
}

# Existing signatures
{
   my %h = (
      data => "here",
      signatures => {
         "elsewhere" => {
            "rot13:1" => "It's OK",
         }
      }
   );

   sign_json( \%h,
      secret_key => $skey,
      origin     => "localhost",
      key_id     => "ed25591:1",
   );

   ok( exists $h{signatures}{"elsewhere"}{"rot13:1"},
      'Existing signature is undisturbed' );
}

# Verification
{
   my %h = (
      data => "here",
   );

   sign_json( \%h,
      secret_key => $skey,
      origin     => "localhost",
      key_id     => "ed25591:1",
   );

   ok( eval {
         verify_json_signature( \%h,
            public_key => $pkey,
            origin     => "localhost",
            key_id     => "ed25591:1",
         );
         1;
      }, 'Signature verification is OK' ) or
      diag( "Failure is $@" );

   ok( !eval {
         verify_json_signature( \%h,
            public_key => $pkey,
            origin     => "elsewhere",
            key_id     => "rot13:1",
         )
      }, 'Signature verification on missing origin fails' ) and
      like( $@, qr/No signatures from 'elsewhere'/ );  # Ugh :/

   ok( !eval {
         verify_json_signature( \%h,
            public_key => $pkey,
            origin     => "localhost",
            key_id     => "ed25519:2",
         )
      }, 'Signature verification on missing key ID fails' ) and
      like( $@, qr/No signature from 'localhost' using key 'ed25519:2'/ );

   # Break the signature
   $h{signatures}{"localhost"}{"ed25591:1"} .= "XXX";

   ok( !eval {
         verify_json_signature( \%h,
            public_key => $pkey,
            origin     => "localhost",
            key_id     => "ed25591:1",
         )
      }, 'Signature verification on mangled signature fails' ) and
      like( $@, qr/Invalid signature/ );
}

done_testing;
