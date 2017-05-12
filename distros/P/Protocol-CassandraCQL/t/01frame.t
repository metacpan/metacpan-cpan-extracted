#!/usr/bin/perl

use strict;
use warnings;
use utf8;

use Test::More;
use Test::HexString;

# perls prior to 5.14 need this
use IO::Handle;

# For 'inet' type
use Socket 1.82 qw( AF_INET  pack_sockaddr_in  unpack_sockaddr_in
                    AF_INET6 pack_sockaddr_in6 unpack_sockaddr_in6
                    inet_pton inet_ntop );

use Protocol::CassandraCQL qw( parse_frame build_frame recv_frame send_frame );
use Protocol::CassandraCQL::Frame;

# Empty
is( Protocol::CassandraCQL::Frame->new->bytes, "", '->bytes empty' );

# byte
{
   my $frame = Protocol::CassandraCQL::Frame->new;
   $frame->pack_byte( 0x55 );
   is_hexstr( $frame->bytes, "\x55", '->pack_byte' );

   $frame = Protocol::CassandraCQL::Frame->new( $frame->bytes );
   is( $frame->unpack_byte, 0x55, '->unpack_byte' );
}

# short
{
   my $frame = Protocol::CassandraCQL::Frame->new;
   $frame->pack_short( 0x1234 );
   is_hexstr( $frame->bytes, "\x12\x34", '->pack_short' );

   $frame = Protocol::CassandraCQL::Frame->new( $frame->bytes );
   is( $frame->unpack_short, 0x1234, '->unpack_short' );
}

# int
{
   my $frame = Protocol::CassandraCQL::Frame->new;
   $frame->pack_int( 0x12345678 );
   $frame->pack_int( -100 );
   is_hexstr( $frame->bytes, "\x12\x34\x56\x78\xff\xff\xff\x9c", '->pack_int and -ve' );

   $frame = Protocol::CassandraCQL::Frame->new( $frame->bytes );
   is( $frame->unpack_int, 0x12345678, '->unpack_int' );
   is( $frame->unpack_int, -100, '->unpack_int -ve' );
}

# string
{
   my $frame = Protocol::CassandraCQL::Frame->new;
   $frame->pack_string( "hello" );
   $frame->pack_string( "sandviĉon" );
   is_hexstr( $frame->bytes, "\x00\x05hello\x00\x0asandvi\xc4\x89on", '->pack_string and UTF-8' );

   $frame = Protocol::CassandraCQL::Frame->new( $frame->bytes );
   is( $frame->unpack_string, "hello", '->unpack_string' );
   is( $frame->unpack_string, "sandviĉon", '->unpack_string UTF-8' );
}

# long string
{
   my $frame = Protocol::CassandraCQL::Frame->new;
   $frame->pack_lstring( "hello" );
   $frame->pack_lstring( "sandviĉon" );
   is_hexstr( $frame->bytes, "\x00\x00\x00\x05hello\x00\x00\x00\x0asandvi\xc4\x89on",
              '->pack_lstring and UTF-8' );

   $frame = Protocol::CassandraCQL::Frame->new( $frame->bytes );
   is( $frame->unpack_lstring, "hello", '->unpack_lstring' );
   is( $frame->unpack_lstring, "sandviĉon", '->unpack_lstring UTF-8' );
}

# UUID
{
   my $frame = Protocol::CassandraCQL::Frame->new;
   $frame->pack_uuid( "X"x16 );
   is_hexstr( $frame->bytes, "X"x16, '->pack_uuid' );

   $frame = Protocol::CassandraCQL::Frame->new( $frame->bytes );
   is( $frame->unpack_uuid, "X"x16, '->unpack_uuid' );
}

# string list
{
   my $frame = Protocol::CassandraCQL::Frame->new;
   $frame->pack_string_list( [qw( one two three )] );
   is_hexstr( $frame->bytes, "\x00\x03\x00\x03one\x00\x03two\x00\x05three", '->pack_string_list' );

   $frame = Protocol::CassandraCQL::Frame->new( $frame->bytes );
   is_deeply( $frame->unpack_string_list, [qw( one two three )], '->unpack_string_list' );
}

# bytes
{
   my $frame = Protocol::CassandraCQL::Frame->new;
   $frame->pack_bytes( "abcd" );
   $frame->pack_bytes( undef );
   is_hexstr( $frame->bytes, "\x00\x00\x00\x04abcd" . "\xff\xff\xff\xff", '->pack_bytes and undef' );

   $frame = Protocol::CassandraCQL::Frame->new( $frame->bytes );
   is( $frame->unpack_bytes, "abcd", '->unpack_bytes' );
   is( $frame->unpack_bytes, undef,  '->unpack_bytes undef' );
}

# short bytes
{
   my $frame = Protocol::CassandraCQL::Frame->new;
   $frame->pack_short_bytes( "efgh" );
   is_hexstr( $frame->bytes, "\x00\x04efgh", '->pack_short_bytes' );

   $frame = Protocol::CassandraCQL::Frame->new( $frame->bytes );
   is( $frame->unpack_short_bytes, "efgh", '->unpack_short_bytes' );
}

# inet - IPv4
{
   my $frame = Protocol::CassandraCQL::Frame->new;
   my $INADDR = inet_pton( AF_INET, "192.168.1.1" );
   $frame->pack_inet( pack_sockaddr_in( 8001, $INADDR ) );
   is_hexstr( $frame->bytes, "\4\xc0\xa8\x01\x01\0\0\x1f\x41", '->pack_inet IPv4' );

   $frame = Protocol::CassandraCQL::Frame->new( $frame->bytes );
   is_deeply( [ unpack_sockaddr_in( $frame->unpack_inet ) ],
              [ 8001, $INADDR ], '->unpack_inet IPv4' );
}

# inet - IPv6
{
   my $frame = Protocol::CassandraCQL::Frame->new;
   my $IN6ADDR = inet_pton( AF_INET6, "2001:db8::1:2:3" );
   $frame->pack_inet( pack_sockaddr_in6( 8001, $IN6ADDR ) );
   is_hexstr( $frame->bytes, "\x10\x20\x01\x0d\xb8\x00\x00\x00\x00\x00\x00\x00\x01\00\x02\x00\x03" .
      "\0\0\x1f\x41", '->pack_inet IPv6' );

   $frame = Protocol::CassandraCQL::Frame->new( $frame->bytes );
   is_deeply( [ (unpack_sockaddr_in6( $frame->unpack_inet ))[0,1] ],
              [ 8001, $IN6ADDR ], '->unpack_inet IPv6' );
}

# string map
{
   my $frame = Protocol::CassandraCQL::Frame->new;
   $frame->pack_string_map( { one => "ONE", two => "TWO" } );
   is_hexstr( $frame->bytes, "\x00\x02" . "\x00\x03one\x00\x03ONE" .
                                          "\x00\x03two\x00\x03TWO", '->pack_string_map' );

   $frame = Protocol::CassandraCQL::Frame->new( $frame->bytes );
   is_deeply( $frame->unpack_string_map, { one => "ONE", two => "TWO" }, '->unpack_string_map' );
}

# string multimap
{
   my $frame = Protocol::CassandraCQL::Frame->new;
   $frame->pack_string_multimap( { one => [qw( A )], two => [qw( B C )] } );
   is_hexstr( $frame->bytes, "\x00\x02" . "\x00\x03one\x00\x01\x00\x01A" .
                                          "\x00\x03two\x00\x02\x00\x01B\x00\x01C", '->pack_string_multimap' );

   $frame = Protocol::CassandraCQL::Frame->new( $frame->bytes );
   is_deeply( $frame->unpack_string_multimap, { one => [qw( A )], two => [qw( B C )] }, '->unpack_string_multimap' );
}

# Complete message parsing
{
   my $bytes = "\x81\x00\x01\x05\0\0\0\4\x01\x23\x45\x67Tail";
   my ( $version, $flags, $streamid, $opcode, $body ) = parse_frame( $bytes );

   is( $version, 0x81, '$version from ->parse' );
   is( $flags,   0x00, '$flags from ->parse' );
   is( $streamid,   1, '$streamid from ->parse' );
   is( $opcode,     5, '$opcode from ->parse' );

   my $frame = Protocol::CassandraCQL::Frame->new( $body );

   is( $frame->unpack_int, 0x01234567, '$frame->unpack_int from ->parse' );

   is( $bytes, "Tail", '$bytes still has tail after ->parse' );

   $frame = Protocol::CassandraCQL::Frame->new
      ->pack_int( 0x76543210 );

   is_hexstr( build_frame( 0x01, 0x00, 1, 6, $frame->bytes ),
              "\x01\x00\x01\x06\0\0\0\4\x76\x54\x32\x10",
              '$frame->build' );
}

# send/recv
{
   pipe( my $rd, my $wr ) or die "Cannot pipe() - $!";
   $wr->autoflush(1);

   send_frame( $wr, 0x01, 0x00, 2, 6, "\0\2AB" );
   $rd->sysread( my $bytes, 8192 );
   is_hexstr( $bytes, "\x01\x00\x02\x06\0\0\0\4\0\2AB",
              '$bytes written by send_frame' );

   $wr->syswrite( "\x81\x00\x02\x07\0\0\0\4\0\2Hi" );

   my ( $version, $flags, $streamid, $opcode, $body ) = recv_frame( $rd );

   is( $version, 0x81, '$version from ->recv_frame' );
   is( $flags,   0x00, '$flags from ->recv_frame' );
   is( $streamid,   2, '$streamid from ->recv_frame' );
   is( $opcode,     7, '$opcode from ->recv_frame' );

   my $frame = Protocol::CassandraCQL::Frame->new( $body );

   is( $frame->unpack_string, "Hi", '$frame->unpack_string from ->recv_frame' );
}

done_testing;
