#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::HexString;

use Protocol::Gearman;

# pack
{
   my ( $type, $body ) = Protocol::Gearman->pack_packet(
      SUBMIT_JOB => "func", "my-job-id", "args\0go\0here"
   );
   is( $type, 7, '$type from pack_packet SUBMIT_JOB' );
   is_hexstr( $body, "func\0my-job-id\0args\0go\0here",
      '$body from pack_packet SUBMIT_JOB' );

   ok( exception { Protocol::Gearman->pack_packet( UNKNOWN_TYPE => 1 ) },
      'unknown type raises an exception' );

   ok( exception { Protocol::Gearman->pack_packet( SUBMIT_JOB => 1, 2 ) },
      'wrong argument count raises exception' );

   ok( exception { Protocoll::Gearman->pack_packet( SUBMIT_JOB => "my-id", "my\0id\0here", "args" ) },
      'embedded NUL in non-final argument raises exception' );
}

# unpack
{
   my ( $name, @args ) = Protocol::Gearman->unpack_packet(
      7, "a-func\0the-id\0some\0more\0args"
   );
   is( $name, "SUBMIT_JOB", '$name from unpack_packet SUBMIT_JOB' );
   is_deeply( \@args, [ "a-func", "the-id", "some\0more\0args" ],
         '@args from unpack_packet TYPE_SUBMIT_JOB' );

   ok( exception { Protocol::Gearman->unpack_packet( 12345, "some body" ) },
       'unknown type raises an exception' );
}

done_testing;
