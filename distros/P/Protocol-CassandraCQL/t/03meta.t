#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Fatal;
use Test::HexString;

use Protocol::CassandraCQL::Frame;
use Protocol::CassandraCQL::ColumnMeta;

# v1
{
   my $meta = Protocol::CassandraCQL::ColumnMeta->from_frame(
      Protocol::CassandraCQL::Frame->new(
         "\0\0\0\1\0\0\0\3\0\4test\0\5table\0\3key\0\x0a\0\1i\0\x09\0\1b\0\x02"
      ),
      1
   );

   is( scalar $meta->columns, 3, '$meta->columns is 3' );

   ok( $meta->has_metadata, '$meta has metadata defined' );

   is_deeply( [ $meta->column_name( 0 ) ],
              [qw( test table key )],
              '$meta->column_name(0) list' );
   is( scalar $meta->column_name( 0 ),
       "test.table.key",
       '$meta->column_name(0) scalar' );
   is_deeply( [ $meta->column_name( 1 ) ],
              [qw( test table i )],
              '$meta->column_name(1) list' );
   is_deeply( [ $meta->column_name( 2 ) ],
              [qw( test table b )],
              '$meta->column_name(2) list' );

   is( $meta->column_shortname( 0 ), "key", '$meta->column_shortname(0)' );
   is( $meta->column_shortname( 1 ), "i",   '$meta->column_shortname(1)' );
   is( $meta->column_shortname( 2 ), "b",   '$meta->column_shortname(2)' );

   is( $meta->column_type(0)->name, "TEXT",   '$meta->column_type(0)->name' );
   is( $meta->column_type(1)->name, "INT",    '$meta->column_type(1)->name' );
   is( $meta->column_type(2)->name, "BIGINT", '$meta->column_type(2)->name' );

   is( $meta->find_column(            "key" ), 0, '$meta->find_column( "key" )' );
   is( $meta->find_column(      "table.key" ), 0, '$meta->find_column( "table.key" )' );
   is( $meta->find_column( "test.table.key" ), 0, '$meta->find_column( "test.table.key" )' );
   is( $meta->find_column( "unknown" ), undef, '$meta->find_column( "unknown" )' );

   my @bytes = $meta->encode_data( "the-key", 123, 456 );
   is_hexstr( $bytes[0], "the-key",              '->encode_data [0]' );
   is_hexstr( $bytes[1], "\0\0\0\x7b",           '->encode_data [1]' );
   is_hexstr( $bytes[2], "\0\0\0\0\0\0\x01\xc8", '->encode_data [2]' );

   is_deeply( [ $meta->decode_data( "another-key", "\0\0\0\x7c", "\0\0\0\0\0\0\x01\xc9" ) ],
              [ "another-key", 124, 457 ],
              '->decode_data' );

   like( exception { $meta->encode_data( "bad-data", "a string", 0 ) },
         qr/Cannot encode i: not a number/,
         '->encode_data validates types' );
}

# v2
{
   my $meta = Protocol::CassandraCQL::ColumnMeta->from_frame(
      Protocol::CassandraCQL::Frame->new(
         "\0\0\0\3\0\0\0\2\0\0\0\5STATE\0\4test\0\5table\0\3key\0\x0a\0\1i\0\x09"
      ),
      2
   );

   is( scalar $meta->columns, 2, '$meta->columns is 2' );

   ok( $meta->has_metadata, '$meta has metadata defined' );

   is( $meta->column_shortname( 0 ), "key", '$meta->column_shortname(0)' );
   is( $meta->column_shortname( 1 ), "i",   '$meta->column_shortname(1)' );
   is( $meta->column_type(0)->name, "TEXT",   '$meta->column_type(0)->name' );
   is( $meta->column_type(1)->name, "INT",    '$meta->column_type(1)->name' );

   is( $meta->paging_state, "STATE", '$meta->paging_state' );
}

# Collections
{
   my $meta = Protocol::CassandraCQL::ColumnMeta->from_frame(
      Protocol::CassandraCQL::Frame->new(
         "\0\0\0\1\0\0\0\3\0\4test\0\x0bcollections" .
            "\0\3set\0\x22\0\x09\0\4list\0\x20\0\x0A\0\3map\0\x21\0\x0A\0\x09"
      )
   );

   is( scalar $meta->columns, 3, '$meta->columns is 3' );

   is( $meta->column_type(0)->name, "SET<INT>", '$meta->column_type(0)' );
   is( $meta->column_type(0)->element_type->name, "INT", '$meta->column_type(0) etype' );
   is( $meta->column_type(1)->name, "LIST<TEXT>", '$meta->column_type(1)' );
   is( $meta->column_type(1)->element_type->name, "TEXT", '$meta->column_type(1) etype' );
   is( $meta->column_type(2)->name, "MAP<TEXT,INT>", '$meta->column_type(2)' );
   is( $meta->column_type(2)->key_type->name,   "TEXT", '$meta->column_type(2) ktype' );
   is( $meta->column_type(2)->value_type->name, "INT",  '$meta->column_type(2) vtype' );

   my @bytes = $meta->encode_data(
      [ 10, 20, 30 ], [qw( A B C )], { name => 100 } );

   is_hexstr( $bytes[0],
      "\0\3\0\4\x00\x00\x00\x0a\0\4\x00\x00\x00\x14\0\4\x00\x00\x00\x1e",
      '->encode_data SET<INT>' );
   is_hexstr( $bytes[1],
      "\0\3\0\1A\0\1B\0\1C",
      '->encode_data LIST<TEXT>' );
   is_hexstr( $bytes[2],
      "\0\1\0\4name\0\4\x00\x00\x00\x64",
      '->encode_data MAP<TEXT,INT>' );

   like( exception { $meta->encode_data( [ 0, 1, "bad" ], [], {} ) },
         qr/Cannot encode set: \[2]: not a number/,
         '->encode_data validates collection types' );
}

# mocking constructor
{
   my $meta = Protocol::CassandraCQL::ColumnMeta->new(
      columns => [
         [ k => t => key   => "VARCHAR" ],
         [ k => t => value => "BIGINT" ],
      ],
   );

   is( scalar $meta->columns, 2, '$meta->columns is 2 for ->new' );

   is_deeply( [ $meta->column_name(0) ], [qw( k t key   )], '$meta->column_name(0) for ->new' );
   is_deeply( [ $meta->column_name(1) ], [qw( k t value )], '$meta->column_name(1) for ->new' );
   is( $meta->column_type(0)->name, "VARCHAR", '$meta->column_type(0) for ->new' );
   is( $meta->column_type(1)->name, "BIGINT",  '$meta->column_type(1) for ->new' );
}

done_testing;
