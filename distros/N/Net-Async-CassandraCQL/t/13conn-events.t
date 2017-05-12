#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::HexString;

use IO::Async::Test;
use IO::Async::OS;
use IO::Async::Loop;
use IO::Async::Stream;

use Socket qw( pack_sockaddr_in inet_aton );

use Net::Async::CassandraCQL::Connection;
use Protocol::CassandraCQL qw( CONSISTENCY_ANY CONSISTENCY_ONE CONSISTENCY_TWO );

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my ( $S1, $S2 ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";

my $conn = Net::Async::CassandraCQL::Connection->new(
   handle => $S1,
);

$loop->add( $conn );

# ->register
{
   my $f = $conn->register( [qw( STATUS_CHANGE )] );

   my $stream = "";
   wait_for_stream { length $stream >= 8 + 0 } $S2 => $stream;

   # OPCODE_STARTUP
   is_hexstr( $stream,
              "\x01\x00\x01\x0b\0\0\0\x11" .
                 "\x00\x01" . "\x00\x0dSTATUS_CHANGE",
              'stream after ->register' );

   # OPCODE_READY
   $S2->syswrite( "\x81\x00\x01\x02\0\0\0\0" );

   wait_for { $f->is_ready };

   is_deeply( [ $f->get ], [],
              '->register->get returns nothing' );
}

# EVENT handling
{
   my ( $status, $node );
   $conn->configure(
      on_status_change => sub { ( undef, $status, $node ) = @_; },
   );

   # OPCODE_EVENT; streamid == 0xff
   $S2->syswrite( "\x81\x00\xff\x0c\0\0\0\x1c" .
      "\0\x0dSTATUS_CHANGE\0\2UP\x04\xc0\xa8\x00\x01\0\0\x12\x34" );

   wait_for { defined $status };

   is( $status, "UP", '$status after OPCODE_EVENT' );
   is_hexstr( $node, pack_sockaddr_in( 0x1234, inet_aton( "192.168.0.1" ) ),
      '$node after OPCODE_EVENT' );
}

done_testing;
