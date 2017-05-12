#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Identity;
use Test::HexString;
use Test::Refcount;

use IO::Async::Test;
use IO::Async::OS;
use IO::Async::Loop;
use IO::Async::Stream;

use Net::Async::CassandraCQL;
use Net::Async::CassandraCQL::Connection;
use Protocol::CassandraCQL qw( CONSISTENCY_ANY CONSISTENCY_ONE CONSISTENCY_TWO );

use constant CQL_STRING => "INSERT INTO t (f) = (?)";

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my ( $S1, $S2 ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";

my $cass = Net::Async::CassandraCQL->new;

# CHEATING
$cass->add_child( my $conn = Net::Async::CassandraCQL::Connection->new(
   handle => $S1,
) );
$cass->{nodes} = { NODEID => {
      conn    => $conn,
      ready_f => Future->new->done( $conn ),
} };
$cass->{primary_ids} = { NODEID => 1 };
# END CHEATING

$loop->add( $cass );

# ->prepare and ->execute
{
   my $f = $cass->prepare( CQL_STRING );

   my $stream = "";
   wait_for_stream { length $stream >= 8 + 27 } $S2 => $stream;

   # OPCODE_PREPARE
   is_hexstr( $stream,
              "\x01\x00\x01\x09\0\0\0\x1b" .
                 "\0\0\0\x17INSERT INTO t (f) = (?)",
              'stream after ->prepare' );

   # OPCODE_RESULT
   $S2->syswrite( "\x81\x00\x01\x08\0\0\0\x2c\0\0\0\4" .
                     "\x00\x100123456789ABCDEF" .
                     "\0\0\0\1\0\0\0\1\0\4test\0\1t\0\1f\x00\x0D" );

   wait_for { $f->is_ready };

   my $query = $f->get;
   undef $f;

   is_oneref( $query, '$query has refcount 1 after ->prepare' );

   is( $query->id, "0123456789ABCDEF", '$query->id after ->prepare->get' );
   is( $query->cql, "INSERT INTO t (f) = (?)", '$query->cql after ->prepare->get' );
   is( $query->params, 1, '$query->params' );
   is( scalar $query->param_name(0), "test.t.f", '$query->param_name(0)' );
   is( $query->param_type(0)->name, "VARCHAR", '$query->param_type(0)->name' );

   {
      my $f2 = $cass->prepare( CQL_STRING );

      ok( $f2->is_ready, 'Duplicate prepare is ready immediately' );

      identical( scalar $f2->get, $query, 'Duplicate prepare yields same object' );
   }

   # ->execute directly
   $f = $cass->execute( $query, [ "more-data" ], CONSISTENCY_ANY );

   $stream = "";
   wait_for_stream { length $stream >= 8 + 35 } $S2 => $stream;

   # OPCODE_EXECUTE
   is_hexstr( $stream,
              "\x01\x00\x01\x0A\0\0\0\x23" .
                 "\x00\x100123456789ABCDEF" .
                 "\x00\x01" . "\0\0\0\x09more-data" .
                 "\x00\x00",
              'stream after ->execute' );

   # OPCODE_RESULT
   $S2->syswrite( "\x81\x00\x01\x08\0\0\0\4\0\0\0\1" );

   wait_for { $f->is_ready };

   is_deeply( [ $f->get ], [],
              '->execute returns nothing' );

   # ->execute via $query from ARRAY
   $f = $query->execute( [ "data-array" ], CONSISTENCY_ANY );

   $stream = "";
   wait_for_stream { length $stream >= 8 + 36 } $S2 => $stream;

   # OPCODE_EXECUTE
   is_hexstr( $stream,
              "\x01\x00\x01\x0A\0\0\0\x24" .
                 "\x00\x100123456789ABCDEF" .
                 "\x00\x01" . "\0\0\0\x0adata-array" .
                 "\x00\x00",
              'stream after $query->execute(ARRAY)' );

   # OPCODE_RESULT
   $S2->syswrite( "\x81\x00\x01\x08\0\0\0\4\0\0\0\1" );

   wait_for { $f->is_ready };

   is_deeply( [ $f->get ], [],
              '->execute returns nothing' );

   # ->execute via $query from HASH
   $f = $query->execute( { f => "data-hash" }, CONSISTENCY_ANY );

   $stream = "";
   wait_for_stream { length $stream >= 8 + 35 } $S2 => $stream;

   # OPCODE_EXECUTE
   is_hexstr( $stream,
              "\x01\x00\x01\x0A\0\0\0\x23" .
                 "\x00\x100123456789ABCDEF" .
                 "\x00\x01" . "\0\0\0\x09data-hash" .
                 "\x00\x00",
              'stream after $query->execute(HASH)' );

   # OPCODE_RESULT
   $S2->syswrite( "\x81\x00\x01\x08\0\0\0\4\0\0\0\1" );

   wait_for { $f->is_ready };

   is_deeply( [ $f->get ], [],
              '->execute returns nothing' );

   is_oneref( $query, '$query has refcount 1 before EOF' );
   undef $query;

   # Should now be weak with a timer
   # CHEATING
   ok( defined $cass->{queries_by_cql}{+CQL_STRING}{pacemaker},
       'Query has expiry timer' );

   # A second ->prepare should re-vivify it
   $f = $cass->prepare( CQL_STRING );

   ok( $f->is_ready, '->prepare again is ready immediately' );
   ok( !defined $cass->{queries_by_cql}{+CQL_STRING}{pacemaker},
       'Expiry timer cancelled after re-vivify' );

   # Now drop it one last time
   undef $f;
   undef $query;

   # Rather than wait for the timer, just fire it now
   $cass->{queries_by_cql}{+CQL_STRING}{ttl} = 0;
   $cass->{queries_by_cql}{+CQL_STRING}{pacemaker}->done;

   ok( !keys %{ $cass->{queries_by_cql} },
       '$cass has no more cached queries after timer expire' );
}

# CQL v2 returns result metadata from PREPARED, so we should use no_metadata on
# execute
{
   $cass->configure( cql_version => 2 );
   $conn->configure( cql_version => 2 );

   my $f = $cass->prepare( "SELECT a, b FROM table WHERE b = ?" );

   my $stream = "";
   wait_for_stream { length $stream >= 8 + 38 } $S2 => $stream; # TODO

   # OPCODE_PREPARE
   is_hexstr( $stream,
              "\x02\x00\x01\x09\0\0\0\x26" .
                 "\0\0\0\x22SELECT a, b FROM table WHERE b = ?",
              'stream after ->prepare v2' );

   # OPCODE_RESULT
   $S2->syswrite( "\x82\x00\x01\x08\0\0\0\x4f\0\0\0\4" .
                     "\x00\x100123456789ABCDFE" .
                     "\0\0\0\1\0\0\0\1\0\4test\0\5table\0\1b\x00\x0D" .
                     "\0\0\0\1\0\0\0\2\0\4test\0\5table\0\1a\x00\x09\0\1b\x00\x0D" );

   wait_for { $f->is_ready };

   my $query = $f->get;

   is( $query->params, 1, '$query->params' );
   ok( defined $query->result_meta, '$query->result_meta defined' );
   is( $query->result_meta->columns, 2, '$query->result_meta->columns' );

   # ->execute
   $f = $query->execute( [ "the-key" ], CONSISTENCY_ANY );

   $stream = "";
   wait_for_stream { length $stream >= 8 + 34 } $S2 => $stream;

   # OPCODE_EXECUTE
   is_hexstr( $stream,
              "\x02\x00\x01\x0A\0\0\0\x22" .
                 "\x00\x100123456789ABCDFE" .
                 "\x00\x00\x03\x00\x01" .
                    "\0\0\0\7the-key",
              'stream after $query->execute(ARRAY) for v2' );

   # OPCODE_RESULT
   $S2->syswrite( "\x82\x00\x01\x08\0\0\0\x23\0\0\0\2" .
                     "\0\0\0\4\0\0\0\2" .
                     "\0\0\0\1" .
                     "\0\0\0\4\x00\x00\x02\x46\0\0\0\7the-key" );

   wait_for { $f->is_ready };

   my ( $type, $result ) = $f->get;

   is( $result->columns, 2, '$result->columns' );
   is( $result->rows,    1, '$result->rows' );

   is( $result->column_shortname( 0 ), "a", '$result->column_shortname' );

   is_deeply( $result->row_array( 0 ),
              [ 0x0246, "the-key" ],
              '$result->row_array' );
}

done_testing;
