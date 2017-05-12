#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use IO::Async::Test;
use IO::Async::OS;
use IO::Async::Loop;
use IO::Async::Stream;

use Protocol::CassandraCQL qw( OPCODE_QUERY OPCODE_RESULT RESULT_VOID CONSISTENCY_ANY );
use Net::Async::CassandraCQL::Connection;

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my ( $S1, $S2 ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";

my $conn = Net::Async::CassandraCQL::Connection->new(
   handle => $S1,
);
$loop->add( $conn );

# A tiny simulated server that responds with a VOID result to every QUERY
$loop->add( IO::Async::Stream->new(
      handle => $S2,
      on_read => sub {
         my $self = shift;
         my ( $buffref, $eof ) = @_;

         return 0 unless length($$buffref) >= 8;
         my ( $ver, $flags, $stream, $opcode, $len ) = unpack( "C C C C N", $$buffref );
         return 0 unless length($$buffref) >= 8 + $len;

         substr( $$buffref, 0, 8 + $len ) = "";

         die "Expected OPCODE_QUERY" unless $opcode == OPCODE_QUERY;

         $self->write(
            pack "C C C C N/a*", 0x81, 0, $stream, OPCODE_RESULT,
               pack "N", RESULT_VOID
         );

         return 1;
      },
) );

# Fire off 127 queries, queue the remainder
my @f = map { $conn->query( "INSERT INTO t (v) = $_", CONSISTENCY_ANY ) } 1 .. 1000;

# Wait on success from all
Future->needs_all( @f )->get;
pass( "Succesfully ran 1000 queries" );

done_testing;
