#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::HexString;

use IO::Async::Test;
use IO::Async::OS;
use IO::Async::Loop;
use IO::Async::Stream;

use Net::Async::CassandraCQL::Connection;
use Protocol::CassandraCQL qw( CONSISTENCY_ANY CONSISTENCY_ONE CONSISTENCY_TWO );

my $loop = IO::Async::Loop->new();
testing_loop( $loop );

my ( $S1, $S2 ) = IO::Async::OS->socketpair() or die "Cannot create socket pair - $!";

my $conn = Net::Async::CassandraCQL::Connection->new(
   handle => $S1,
);

$loop->add( $conn );

# ->startup
{
   my $f = $conn->startup;

   my $stream = "";

   if( Net::Async::CassandraCQL::Connection::HAVE_SNAPPY ) {
      wait_for_stream { length $stream >= 8 + 43 } $S2 => $stream;

      # OPCODE_STARTUP
      # Since this map will contain 2 elements, we'll have to detect the order
      # and supply the appropriate bytestring
      is_hexstr( $stream,
                 "\x01\x00\x01\x01\0\0\0\x2b" .
                    "\x00\x02" . ( $stream =~ m/CQL_VERSION.*COMPRESSION/
                       ? "\x00\x0bCQL_VERSION\x00\x053.0.5\x00\x0bCOMPRESSION\x00\x06Snappy"
                       : "\x00\x0bCOMPRESSION\x00\x06snappy\x00\x0bCQL_VERSION\x00\x053.0.5" ),
                 'stream after ->startup' );
   }
   else {
      wait_for_stream { length $stream >= 8 + 22 } $S2 => $stream;

      # OPCODE_STARTUP
      is_hexstr( $stream,
                 "\x01\x00\x01\x01\0\0\0\x16" .
                    "\x00\x01" .
                       "\x00\x0bCQL_VERSION\x00\x053.0.5",
                 'stream after ->startup' );
   }

   # OPCODE_READY
   $S2->syswrite( "\x81\x00\x01\x02\0\0\0\0" );

   wait_for { $f->is_ready };

   is_deeply( [ $f->get ], [],
              '->startup->get returns nothing' );

   $conn->configure( username => "the-user", password => "the-pass" );

   $f = $conn->startup;

   $stream = "";
   wait_for_stream { length $stream >= 8 + 22 } $S2 => $stream;

   # OPCODE_AUTHENTICATE
   $S2->syswrite( "\x81\x00\x01\x03\0\0\0\x31" .
      "\0\x2forg.apache.cassandra.auth.PasswordAuthenticator" );

   $stream = "";
   wait_for_stream { length $stream >= 8 + 0 } $S2 => $stream;

   # OPCODE_CREDENTIALS
   is_hexstr( $stream,
              "\x01\x00\x01\x04\0\0\0\x2a" .
                 "\0\2\0\x08password\0\x08the-pass" .
                     "\0\x08username\0\x08the-user",
              'stream has credentials after authentication required' );

   # OPCODE_READY
   $S2->syswrite( "\x81\x00\x01\x02\0\0\0\0" );

   wait_for { $f->is_ready };

   is_deeply( [ $f->get ], [],
              '->startup->get returns nothing after authentication' );
}

# ->options
{
   my $f = $conn->options;

   my $stream = "";
   wait_for_stream { length $stream >= 8 } $S2 => $stream;

   # OPCODE_OPTIONS
   is_hexstr( $stream,
              "\x01\x00\x01\x05\0\0\0\0",
              'stream after ->options' );

   # OPCODE_READY
   $S2->syswrite( "\x81\x00\x01\x06\0\0\0\x2f\0\2" .
                  "\x00\x0bCOMPRESSION\0\1\x00\x06snappy" .
                  "\x00\x0bCQL_VERSION\0\1\x00\x053.0.0" );

   wait_for { $f->is_ready };

   is_deeply( scalar $f->get,
              { COMPRESSION => ["snappy"], CQL_VERSION => ["3.0.0"] },
              '->options->get returns HASH of options' );
}

# ->query returning void
{
   my $f = $conn->query( "INSERT INTO things (name) VALUES ('thing')", CONSISTENCY_ANY );

   my $stream = "";
   wait_for_stream { length $stream >= 8 + 48 } $S2 => $stream;

   # OPCODE_QUERY
   is_hexstr( $stream,
              "\x01\x00\x01\x07\0\0\0\x30" .
                 "\0\0\0\x2aINSERT INTO things (name) VALUES ('thing')\0\0",
              'stream after ->query INSERT' );

   # OPCODE_RESULT
   $S2->syswrite( "\x81\x00\x01\x08\0\0\0\4\0\0\0\1" );

   wait_for { $f->is_ready };

   is_deeply( [ $f->get ], [],
              '->query returns nothing' );
}

# ->query returning rows
{
   my $f = $conn->query( "SELECT a,b FROM c", CONSISTENCY_ONE );

   my $stream = "";
   wait_for_stream { length $stream >= 8 + 23 } $S2 => $stream;

   # OPCODE_QUERY
   is_hexstr( $stream,
              "\x01\x00\x01\x07\0\0\0\x17" .
                 "\0\0\0\x11SELECT a,b FROM c\0\1",
              'stream after ->query SELECT' );

   # OPCODE_RESULT
   $S2->syswrite( "\x81\x00\x01\x08\0\0\0\x34\0\0\0\2" .
                     "\0\0\0\1\0\0\0\2\0\4test\0\1c\0\1a\x00\x0D\0\1b\x00\x09" . # metadata
                     "\0\0\0\1" . # row count
                     "\0\0\0\5hello\0\0\0\4\0\0\0\x64" # row 0
                  );

   wait_for { $f->is_ready };

   is( scalar $f->get, "rows", '->query SELECT returns rows' );

   my $result = ( $f->get )[1];
   is( $result->columns, 2, '$result->columns' );
   is( $result->rows, 1, '$result->rows' );
}

# ->query returning set_keyspace
{
   my $f = $conn->query( "USE test", CONSISTENCY_ANY );

   my $stream = "";
   wait_for_stream { length $stream >= 8 + 12 } $S2 => $stream;

   # OPCODE_QUERY
   is_hexstr( $stream,
              "\x01\x00\x01\x07\0\0\0\x0e" .
                 "\0\0\0\x08USE test\0\0",
              'stream after ->query USE' );

   # OPCODE_RESULT
   $S2->syswrite( "\x81\x00\x01\x08\0\0\0\x0a\0\0\0\3\0\4test" );

   wait_for { $f->is_ready };

   is_deeply( [ $f->get ], [ keyspace => "test" ],
              '->query USE returns keyspace' );
}

# ->query returning schema_change
{
   my $f = $conn->query( "DROP TABLE users", CONSISTENCY_ANY );

   my $stream = "";
   wait_for_stream { length $stream >= 8 + 20 } $S2 => $stream;

   # OPCODE_QUERY
   is_hexstr( $stream,
              "\x01\x00\x01\x07\0\0\0\x16" .
                 "\0\0\0\x10DROP TABLE users\0\0",
              'stream after ->query DROP TABLE' );

   # OPCODE_RESULT
   $S2->syswrite( "\x81\x00\x01\x08\0\0\0\x1a\0\0\0\5\0\7DROPPED\0\4test\0\5users" );

   wait_for { $f->is_ready };

   is_deeply( [ $f->get ], [ schema_change => [qw( DROPPED test users )] ],
              '->query DROP TABLE returns schema change' );
}

# ->prepare and ->execute
{
   my $f = $conn->prepare( "INSERT INTO t (f) = (?)" );

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
   is( $query->id, "0123456789ABCDEF", '$query->id after ->prepare->get' );

   # ->execute directly
   $f = $conn->execute( "0123456789ABCDEF", [ "more-data" ], CONSISTENCY_ANY );

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
}

# ->query with some v2 fields
{
   $conn->configure( cql_version => 2 );

   my $f = $conn->query( "SELECT key, v FROM table", CONSISTENCY_ANY,
      page_size => 100,
   );

   my $stream = "";
   wait_for_stream { length $stream >= 8 + 35 } $S2 => $stream;

   # OPCODE_QUERY
   is_hexstr( $stream,
              "\x02\x00\x01\x07\0\0\0\x23" .
                 "\x00\x00\x00\x18SELECT key, v FROM table\x00\x00" . "\x04" .
                    "\x00\x00\x00\x64",
              'stream after ->query v2' );

   # OPCODE_RESULT
   $S2->syswrite( "\x82\x00\x01\x08\0\0\0\x29\0\0\0\2" .
                     "\0\0\0\1\0\0\0\2\0\4test\0\5table\0\3key\x00\x0D\0\1v\x00\x09" . # metadata
                     "\0\0\0\0"
                  );

   wait_for { $f->is_ready };

   my $result = ( $f->get )[1];
   is( $result->columns, 2, '$result->columns' );
   is( $result->rows, 0, '$result->rows' );
}

done_testing;
