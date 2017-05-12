#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Protocol::CassandraCQL::Frame;
use Protocol::CassandraCQL::Result;

# Single column/row v1
{
   my $result = Protocol::CassandraCQL::Result->from_frame(
      Protocol::CassandraCQL::Frame->new(
         "\0\0\0\1\0\0\0\1\0\4test\0\5table\0\6column\0\x0a" . # metadata
         "\0\0\0\1" .   # row count
         "\0\0\0\4data" # row 0
      ), 1
   );

   is( scalar $result->columns, 1, '$result->columns is 1' );

   is( scalar $result->rows, 1, '$result->rows is 1' );

   is_deeply( $result->row_array( 0 ),
              [ "data" ],
              '$result->row_array(0)' );

   is_deeply( $result->row_hash( 0 ),
              { column => "data" },
              '$result->row_hash(0)' );
}

# Multiple columns
{
   my $result = Protocol::CassandraCQL::Result->from_frame(
      Protocol::CassandraCQL::Frame->new(
         "\0\0\0\1\0\0\0\2\0\4test\0\5table\0\3key\0\x0a\0\1i\0\x09" . # metadata
         "\0\0\0\1" .   # row count
         "\0\0\0\4aaaa\0\0\0\4\x00\x00\x00\x64" # row 0
      ), 1
   );

   is( scalar $result->columns, 2, '$result->columns is 2' );

   is_deeply( $result->row_array( 0 ),
              [ "aaaa", 100 ],
              '$result->row_array(0)' );

   is_deeply( $result->row_hash( 0 ),
              { key => "aaaa", i => 100 },
              '$result->row_hash(0)' );
}

# Multiple rows
{
   my $result = Protocol::CassandraCQL::Result->from_frame(
      Protocol::CassandraCQL::Frame->new(
         "\0\0\0\1\0\0\0\2\0\4test\0\7numbers\0\4name\0\x0a\0\1i\0\x09" . # metadata
         "\0\0\0\3" . # row count
         "\0\0\0\4zero\0\0\0\4\x00\x00\x00\x00" . # row 0
         "\0\0\0\3one\0\0\0\4\x00\x00\x00\x01"  . # row 1
         "\0\0\0\3two\0\0\0\4\x00\x00\x00\x02"    # row 2
      ), 1
   );

   is( scalar $result->rows, 3, '$result->rows is 3' );

   is_deeply( [ $result->rows_array ],
              [ [ "zero", 0 ], [ "one", 1 ], [ "two", 2 ] ],
              '$result->rows_array' );

   is_deeply( [ $result->rows_hash ],
              [ { name => "zero", i => 0 }, { name => "one", i => 1 }, { name => "two", i => 2 } ],
              '$result->rows_hash' );

   is_deeply( $result->rowmap_array( 0 ),
              { zero => [ "zero", 0 ],
                one  => [ "one",  1 ],
                two  => [ "two",  2 ] },
              '$result->rowmap_array' );

   is_deeply( $result->rowmap_hash( "name" ),
              { zero => { name => "zero", i => 0 },
                one  => { name => "one",  i => 1 },
                two  => { name => "two",  i => 2 } },
              '$result->rowmap_hash' );
}

# Zero rows
{
   my $result = Protocol::CassandraCQL::Result->from_frame(
      Protocol::CassandraCQL::Frame->new(
         "\0\0\0\1\0\0\0\2\0\4test\0\7numbers\0\4name\0\x0a\0\1i\0\x09" . # metadata
         "\0\0\0\0" # row count
      ), 1
   );

   is( scalar $result->rows, 0, '$result->rows is 0' );
}

# v2 with paging
{
   my $result = Protocol::CassandraCQL::Result->from_frame(
      Protocol::CassandraCQL::Frame->new(
         "\0\0\0\3\0\0\0\2\0\0\0\5STATE\0\4test\0\5table\0\3key\0\x0a\0\1i\0\x09" . # metadata
         "\0\0\0\1" . # row count
         "\0\0\0\3one\0\0\0\4\x00\x00\x00\x01" # row 1
      ), 2
   );

   is( scalar $result->rows, 1, '$result->rows is 1' );

   is_deeply( [ $result->rows_array ],
              [ [ "one", 1 ] ],
              '$result->rows_array for v2 with paging' );

   is( $result->paging_state, "STATE", '$result->paging_state for v2 with paging' );
}

# v2 with no metadata
{
   my $result = Protocol::CassandraCQL::Result->from_frame(
      Protocol::CassandraCQL::Frame->new(
         "\0\0\0\4\0\0\0\2" . # (no) metadata
         "\0\0\0\1" . # row count
         "\0\0\0\3two\0\0\0\4\x00\x00\x00\x02" # row 2
      ), 2
   );

   ok( !$result->has_metadata, '$result has no metadata yet' );

   is( $result->columns, 2, '$result->columns is 2 for v2 with no metadata' );
   is( $result->rows,    1, '$result->rows is 1 for v2 with no metadata' );

   $result->set_metadata( Protocol::CassandraCQL::ColumnMeta->new(
      columns => [
         [ test => table => key => "VARCHAR" ],
         [ test => table => i   => "INT" ],
      ],
   ) );

   ok( $result->has_metadata, '$result has metadata after ->set_metadata' );

   is_deeply( [ $result->rows_array ],
              [ [ "two", 2 ] ],
              '$result->rows_array for v2 with no metadata' );
}

# mocking constructor
{
   my $result = Protocol::CassandraCQL::Result->new(
      columns => [
         [ k => t => key   => "VARCHAR" ],
         [ k => t => value => "BIGINT" ],
      ],
      rows => [
         [ one   => 1 ],
         [ two   => 2 ],
         [ three => 3 ],
      ],
   );

   is( scalar $result->columns, 2, '$result->columns is 2 for ->new' );
   is( scalar $result->rows,    3, '$result->rows is 3 for ->new' );

   is_deeply( [ $result->rows_array ],
              [ [ "one",   1 ],
                [ "two",   2 ],
                [ "three", 3 ] ],
              '$result->rows_array for ->new' );

   is_deeply( $result->rowmap_hash( "key" ),
              { one   => { key => "one",   value => 1 },
                two   => { key => "two",   value => 2 },
                three => { key => "three", value => 3 } },
              '$result->rowmap_hash' );
}

done_testing;
