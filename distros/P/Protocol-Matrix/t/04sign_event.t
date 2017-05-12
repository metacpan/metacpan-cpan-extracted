#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Protocol::Matrix qw(
   sign_event_json signed_event_json verify_event_json_signature
);

use Crypt::NaCl::Sodium;

my $sign = Crypt::NaCl::Sodium->sign;
my ( $pkey, $skey ) = $sign->keypair;

# Signing
{
   my %ev = (
      type    => "event_type",
      content => { body => "here" },
   );

   sign_event_json( \%ev,
      secret_key => $skey,
      origin     => "localhost",
      key_id     => "ed25519:1",
   );

   ok( exists $ev{hashes}{"sha256"},
      'Event has hash added' );

   ok( exists $ev{signatures}{"localhost"}{"ed25519:1"},
      'Event has signature added' );
}

# signed_event
{
   my %ev = (
      type => "X",
   );

   my $signed = signed_event_json( \%ev,
      secret_key => $skey,
      origin     => "localhost",
      key_id     => "ed25519:1",
   );

   ok( exists $signed->{hashes}{"sha256"},
      'Returned hash has SHA256 added' );
   ok( exists $signed->{signatures}{"localhost"}{"ed25519:1"},
      'Returned hash has signature added' );

   ok( !exists $ev{hashes},
      'Original hash is unmodified by SHA256' );
   ok( !exists $ev{signatures},
      'Original hash is unmodified by signature' );
}

# Verification
{
   my %ev = (
      type => "Y",
   );

   sign_event_json( \%ev,
      secret_key => $skey,
      origin     => "localhost",
      key_id     => "ed25519:1",
   );

   ok( eval {
         verify_event_json_signature( \%ev,
            public_key => $pkey,
            origin     => "localhost",
            key_id     => "ed25519:1",
         );
         1;
      }, 'Signature verification is OK' ) or
      diag( "Failure is $@" );

}

done_testing;
