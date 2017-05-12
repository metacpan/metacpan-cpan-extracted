#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Protocol::Matrix qw( encode_json_for_signing encode_base64_unpadded );

# Basics
{
   is( encode_json_for_signing( { a => "string" } ),
       '{"a":"string"}',
       'Single string' );

   is( encode_json_for_signing( { b => 12345 } ),
       '{"b":12345}',
       'Simple integer' );
}

# Non-signed fields are stripped
{
   my %hash = (
      data => "to_sign",
      signatures => { x => "zzz" },
      unsigned => { n => 2 },
   );

   is( encode_json_for_signing( \%hash ), '{"data":"to_sign"}',
      '"signatures" and "unsigned" fields are stripped' );

   ok( exists $hash{signatures} && exists $hash{unsigned},
      '"signatures" and "unsigned" keys are not removed from original hash' );
}

# Ordering
{
   my %hash = ( one => 1, two => 2, three => 3 );

   is( encode_json_for_signing( \%hash ), '{"one":1,"three":3,"two":2}',
      'Hash keys are encoded in sorted order' );

   # Perl 5.18 or above apply per-hash randomization so we can apply a much
   # stronger test for hash key order independence by running this a number of
   # times with new hashes, and seeing if it always gives the right answer
   for ( 1 .. 20 ) {
      is( encode_json_for_signing( { %hash } ), '{"one":1,"three":3,"two":2}',
         'Hash keys still in the right order' );
   }
}

# Base64
{
   is( encode_base64_unpadded( "\0" ), "AA", 'encode_base64_unpadded strips padding' );

   unlike( encode_base64_unpadded( "X" x 100 ), qr/\s/,
      'encode_base64_unpadded does not output whitespace' );
}

done_testing;
