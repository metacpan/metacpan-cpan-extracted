#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::HexString;
use Test::Fatal qw( dies_ok );

use Protocol::CassandraCQL::Frames qw( :all );
use Protocol::CassandraCQL qw( :results );

use Socket qw( unpack_sockaddr_in );

# startup
{
   my $frame = build_startup_frame( 1,
      options => {
         CQL_VERSION => "3.0.5"
      }
   );

   is_hexstr( $frame->bytes,
      "\x00\x01" . "\x00\x0bCQL_VERSION" . "\x00\x053.0.5",
      'build_startup_frame' );
}

# credentials
{
   my $frame = build_credentials_frame( 1,
      credentials => {
         username => "my-name",
      }
   );

   is_hexstr( $frame->bytes,
      "\x00\x01" . "\x00\x08username" . "\x00\x07my-name",
      'build_credentials_frame' );

   dies_ok { build_credentials_frame( 2, credentials => {} ); }
      'build_credentials_frame v2 fails';
}

# query v1
{
   my $frame = build_query_frame( 1,
      cql         => "SELECT THING",
      consistency => 1
   );

   is_hexstr( $frame->bytes,
      "\x00\x00\x00\x0cSELECT THING" . "\x00\x01",
      'build_query_frame v1' );

   dies_ok { build_query_frame( 1, cql => "", consistency => 1, values => [] ) }
      'build_query_frame v1 with values fails';
}

# query v2 - basic
{
   my $frame = build_query_frame( 2,
      cql         => "THINGS",
      consistency => 1,
   );

   is_hexstr( $frame->bytes,
      "\x00\x00\x00\x06THINGS" . "\x00\x01" . "\x00",
      'build_query_frame v2' );
}

# query v2 - with values
{
   my $frame = build_query_frame( 2,
      cql         => "INSERT ?",
      consistency => 1,
      values      => [ "\x04\x08" ],
   );

   is_hexstr( $frame->bytes,
      "\x00\x00\x00\x08INSERT ?" . "\x00\x01" . "\x01" .
         "\x00\x01" . "\x00\x00\x00\x02\x04\x08",
      'build_query_frame v2 with values' );
}

# query v2 - with skip meta
{
   my $frame = build_query_frame( 2,
      cql           => "SELECT THING",
      consistency   => 4,
      skip_metadata => 1,
   );

   is_hexstr( $frame->bytes,
      "\x00\x00\x00\x0cSELECT THING" . "\x00\x04" . "\x02",
      'build_query_frame v2 with skip_metadata' );
}

# query v2 - with page size
{
   my $frame = build_query_frame( 2,
      cql          => "SELECT BLOBS",
      consistency  => 1,
      page_size    => 1024,
   );

   is_hexstr( $frame->bytes,
      "\x00\x00\x00\x0cSELECT BLOBS" . "\x00\x01" . "\x04" .
         "\x00\x00\x04\x00",
      'build_query_frame v2 with page_size' );
}

# query v2 - with page size + paging state
{
   my $frame = build_query_frame( 2,
      cql          => "SELECT BLOBS",
      consistency  => 1,
      page_size    => 1024,
      paging_state => "i-got-here-so-far",
   );

   is_hexstr( $frame->bytes,
      "\x00\x00\x00\x0cSELECT BLOBS" . "\x00\x01" . "\x0c" .
         "\x00\x00\x04\x00" .
         "\x00\x00\x00\x11i-got-here-so-far",
      'build_query_frame v2 with page_size and paging_state' );
}

# query v2 - with serial consistency
{
   my $frame = build_query_frame( 2,
      cql         => "UPDATE IF WANT",
      consistency => 1,
      serial_consistency => 8,
   );

   is_hexstr( $frame->bytes,
      "\x00\x00\x00\x0eUPDATE IF WANT" . "\x00\x01" . "\x10" .
         "\x00\x08",
      'build_query_frame v2 with serial_consistency' );
}

# prepare
{
   my $frame = build_prepare_frame( 1,
      cql => "SELECT THING"
   );

   is_hexstr( $frame->bytes,
      "\x00\x00\x00\x0cSELECT THING",
      'build_prepare_frame' );
}

# execute v1
{
   my $frame = build_execute_frame( 1,
      id       =>"1234-ABCDE",
      values   => [ "\x00\x01", "\x23\x45" ],
      consistency => 2,
   );

   is_hexstr( $frame->bytes,
      "\x00\x0a1234-ABCDE" .
         "\x00\x02" . "\x00\x00\x00\x02\x00\x01" . "\x00\x00\x00\x02\x23\x45" .
         "\x00\x02",
      'build_execute_frame v1' );

   dies_ok { build_execute_frame( 1, id => "", values => [], consistency => 1, page_size => 20 ) }
      'build_execute_frame v1 with page_size fails';
}

# execute v2
{
   my $frame = build_execute_frame( 2,
      id       =>"1234-ABCDE",
      values   => [ "\x00\x01", "\x23\x45" ],
      consistency => 2,
   );

   is_hexstr( $frame->bytes,
      "\x00\x0a1234-ABCDE" . "\x00\x02" . "\x01" .
         "\x00\x02" . "\x00\x00\x00\x02\x00\x01" . "\x00\x00\x00\x02\x23\x45",
      'build_execute_frame v2' );
}

# register
{
   my $frame = build_register_frame( 1,
      events => [qw( UP DOWN SIDEWAYS )]
   );

   is_hexstr( $frame->bytes,
      "\x00\x03" . "\x00\x02UP" .
                   "\x00\x04DOWN" .
                   "\x00\x08SIDEWAYS",
      'build_register_frame' );
}

# error
{
   my ( $err, $message ) = parse_error_frame( 1,
      Protocol::CassandraCQL::Frame->new(
         "\x01\x23\x45\x67" . "\x00\x08message."
      )
   );

   is( $err, 0x1234567, '$error from parse_error_frame' );
   is( $message, "message.", '$message from parse_error_frame' );
}

# authenticate
{
   my ( $authenticator ) = parse_authenticate_frame( 1,
      Protocol::CassandraCQL::Frame->new(
         "\x00\x08password"
      )
   );

   is( $authenticator, "password", '$authenticator from parse_authenticate_frame' );
}

# supported
{
   my ( $options ) = parse_supported_frame( 1,
      Protocol::CassandraCQL::Frame->new(
         "\x00\x01" . "\x00\x06things" . "\x00\x02\x00\x03one\x00\x03two"
      )
   );

   is_deeply( $options,
              { things => [qw( one two )] },
              '$options from parse_supported_frame' );
}

# result void
{
   my ( $type, $result ) = parse_result_frame( 1,
      Protocol::CassandraCQL::Frame->new(
         "\x00\x00\x00\x01"
      )
   );

   is( $type, RESULT_VOID, '$type from parse_result_frame void' );
   ok( !defined $result, '$result from parse_result_frame void' );
}

# result rows
{
   my ( $type, $result ) = parse_result_frame( 1,
      Protocol::CassandraCQL::Frame->new(
         "\x00\x00\x00\x02" .
            "\0\0\0\1\0\0\0\1\0\4test\0\5table\0\6column\0\x0a" .
            "\0\0\0\1" .
            "\0\0\0\4data"
      )
   );

   is( $type, RESULT_ROWS, '$type from parse_result_frame rows' );
   isa_ok( $result, "Protocol::CassandraCQL::Result", '$result from parse_result_frame rows' );

   is( $result->columns, 1, '$result->columns' );
   is( $result->rows,    1, '$result->rows' );
   is( $result->column_name( 0 ), "test.table.column", '$result->column_name( 0 )' );

   ok( $result->has_metadata, '$result->has_metadata' );
}

# result rows v2 no_metadata
{
   my ( $type, $result ) = parse_result_frame( 2,
      Protocol::CassandraCQL::Frame->new(
         "\x00\x00\x00\x02" .
            "\0\0\0\4\0\0\0\1" .
            "\0\0\0\1" .
            "\0\0\0\4data"
      )
   );

   is( $type, RESULT_ROWS, '$type from parse_result_frame rows v2 no_metadata' );
   isa_ok( $result, "Protocol::CassandraCQL::Result", '$result from parse_result_frame rows v2 no_metadata' );

   is( $result->columns, 1, '$result->columns' );
   is( $result->rows,    1, '$result->rows' );

   ok( !$result->has_metadata, '$result->has_metadata false' );
}

# result set_keyspace
{
   my ( $type, $result ) = parse_result_frame( 1,
      Protocol::CassandraCQL::Frame->new(
         "\x00\x00\x00\x03" .
            "\x00\x0cnew_keyspace"
      )
   );

   is( $type, RESULT_SET_KEYSPACE, '$type from parse_result_frame set_keyspace' );
   is( $result, "new_keyspace", '$result from parse_result_frame set_keyspace' );
}

# result prepared v1
{
   my ( $type, $result ) = parse_result_frame( 1,
      Protocol::CassandraCQL::Frame->new(
         "\x00\x00\x00\x04" .
            "\x00\x100123456789ABCDEF" .
            "\0\0\0\1\0\0\0\1\0\4test\0\5table\0\6column\0\x0a"
      )
   );

   is( $type, RESULT_PREPARED, '$type from parse_result_frame prepared v1' );
   is( $result->[0], "0123456789ABCDEF", '$result->[0] from parse_result_frame prepared v1' );
   isa_ok( $result->[1], "Protocol::CassandraCQL::ColumnMeta", '$result->[1] from parse_result_frame prepared v1' );
   is( $result->[1]->columns, 1, '$result->[1] has 1 column from parse_result_frame prepared v1' );
}

# result prepared v2
{
   my ( $type, $result ) = parse_result_frame( 2,
      Protocol::CassandraCQL::Frame->new(
         "\x00\x00\x00\x04" .
            "\x00\x1089ABCDEF01234567" .
            "\0\0\0\1\0\0\0\1\0\4test\0\5table\0\6column\0\x0a" .
            "\0\0\0\1\0\0\0\2\0\4test\0\5table\0\3key\0\x0a\0\5value\0\x0a"
      )
   );

   is( $type, RESULT_PREPARED, '$type from parse_result_frame prepared v2' );
   is( $result->[0], "89ABCDEF01234567", '$result->[0] from parse_result_frame prepared v2' );
   isa_ok( $result->[1], "Protocol::CassandraCQL::ColumnMeta", '$result->[1] from parse_result_frame prepared v2' );
   is( $result->[1]->columns, 1, '$result->[1] has 1 column from parse_result_frame prepared v2' );
   isa_ok( $result->[2], "Protocol::CassandraCQL::ColumnMeta", '$result->[2] from parse_result_frame prepared v2' );
   is( $result->[2]->columns, 2, '$result->[2] has 2 columns from parse_result_frame prepared v2' );
}

# result schema_change
{
   my ( $type, $result ) = parse_result_frame( 1,
      Protocol::CassandraCQL::Frame->new(
         "\x00\x00\x00\x05" .
            "\x00\x07CREATED" . "\x00\x08keyspace" . "\x00\x05table"
      )
   );

   is( $type, RESULT_SCHEMA_CHANGE, '$type from parse_result_frame schema_change' );
   is_deeply( $result,
              [ "CREATED", "keyspace", "table" ],
              '$result from parse_result_frame schema_change' );
}

# event TOPOLOGY_CHANGE
#  (STATUS_CHANGE is the same)
{
   my ( $event, @args ) = parse_event_frame( 1,
      Protocol::CassandraCQL::Frame->new(
         "\x00\x0fTOPOLOGY_CHANGE" .
            "\x00\x05ADDED" . "\4\xc0\xa8\x01\x01\0\0\x1f\x41"
      )
   );

   is( $event, "TOPOLOGY_CHANGE", '$event from parse_event_frame TOPOLOGY_CHANGE' );
   is( $args[0], "ADDED", '$args[0] from parse_error_frame TOPOLOGY_CHANGE' );
   is_deeply( [ unpack_sockaddr_in( $args[1] ) ],
              [ 8001, "\xc0\xa8\x01\x01" ],
              '$args[1] from parse_error_frame TOPOLOGY_CHANGE' );
}

# event SCHEMA_CHANGE
{
   my ( $event, @args ) = parse_event_frame( 1,
      Protocol::CassandraCQL::Frame->new(
         "\x00\x0dSCHEMA_CHANGE" .
            "\x00\x06CREATE" . "\x00\x06family" . "\x00\x05table"
      )
   );

   is( $event, "SCHEMA_CHANGE", '$event from parse_event_frame SCHEMA_CHANGE' );
   is_deeply( \@args,
              [qw( CREATE family table )],
              '@args from parse_event_frame SCHEMA_CHANGE' );
}

done_testing;
