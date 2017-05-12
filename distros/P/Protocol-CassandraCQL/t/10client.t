#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

# perls prior to 5.14 need this
use IO::Handle;

use Protocol::CassandraCQL::Client;

use Protocol::CassandraCQL qw(
   OPCODE_STARTUP OPCODE_READY OPCODE_QUERY OPCODE_RESULT
   RESULT_VOID
   recv_frame send_frame
);
use Protocol::CassandraCQL::Frame;

my $test_server = IO::Socket::INET->new(
   LocalHost => "127.0.0.1", # some OSes need this
   LocalPort => 0,
   Listen => 1,
) or die "Cannot listen - $@";

defined( my $kid = fork() ) or die "Cannot fork - $!";
if( $kid == 0 ) {
   my $sock = $test_server->accept;
   while( my ( $v, $f, $id, $op, $body ) = recv_frame( $sock ) ) {
      if( $op == OPCODE_STARTUP ) {
         send_frame( $sock, 0x81, 0, $id, OPCODE_READY, "" );
      }
      elsif( $op == OPCODE_QUERY ) {
         send_frame( $sock, 0x81, 0, $id, OPCODE_RESULT,
            Protocol::CassandraCQL::Frame->new
               ->pack_short( RESULT_VOID )->bytes
         );
      }
      else {
         print STDERR "TODO: opcode=$op\n";
      }
   }

   POSIX::_exit(0);
}

my $client = Protocol::CassandraCQL::Client->new(
   PeerHost    => $test_server->sockhost,
   PeerService => $test_server->sockport,
) or die "Cannot connect to test server - $@";

ok( defined $client, 'defined $client' );

my ( $op, $response ) = $client->send_message( OPCODE_QUERY, Protocol::CassandraCQL::Frame->new
      ->pack_string( "GET THING" )
      ->pack_short( 0 )
);

is( $op, OPCODE_RESULT, '$op is OPCODE_RESULT' );
is( $response->unpack_short, RESULT_VOID, '$response short is RESULT_VOID' );

done_testing;
