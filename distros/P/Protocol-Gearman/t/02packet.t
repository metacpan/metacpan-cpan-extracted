#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::HexString;

use IO::Handle; # autoflush

use Protocol::Gearman;

# parse/build string
{
   my $bytes = "\0RES\x00\x00\x00\x01\x00\x00\x00\x06thingsTail";
   my ( $name, @args ) = Protocol::Gearman->parse_packet_from_string( $bytes );

   is( $name, "CAN_DO", '$name from parse_packet' );
   is_deeply( \@args, [ "things" ], '@rgs from parse_packet' );

   is( $bytes, "Tail", '$bytes still has tail after parse_packet' );

   is_hexstr( Protocol::Gearman->build_packet_to_string( GET_STATUS => "jobid" ),
              "\0REQ\x00\x00\x00\x0f\x00\x00\x00\x05jobid",
              'build_packet' );

   ok( exception { Protocol::Gearman->parse_packet_from_string( "No magic here" ) },
       'parse_packet dies with no magic' );
}

# send/recv FH
{
   pipe( my $rd, my $wr ) or die "Cannot pipe() - $!";
   $wr->autoflush(1);

   Protocol::Gearman->send_packet_to_fh( $wr, GET_STATUS => "a-job" );
   $rd->sysread( my $bytes, 8192 );
   is_hexstr( $bytes, "\0REQ\x00\x00\x00\x0f\x00\x00\x00\x05a-job",
      '$bytes written by send_packet' );

   $wr->syswrite( "\0RES\x00\x00\x00\x14\x00\x00\x00\x02OK" );

   my ( $name, @args ) = Protocol::Gearman->recv_packet_from_fh( $rd );

   is( $name, "STATUS_RES", '$name from recv_packet' );
   is_deeply( \@args, [ "OK" ], '@args from recv_packet' );

   $wr->syswrite( "No magic here" );
   ok( exception { Protocol::Gearman->recv_packet_from_fh( $rd ) },
       'recv_packet dies with no magic' );

    # Note to self: can't use $rd any more as it has junk in it
}

done_testing;
