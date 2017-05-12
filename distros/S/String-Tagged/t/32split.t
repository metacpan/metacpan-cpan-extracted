#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use String::Tagged;

{
   my $str = String::Tagged->new( "A message with\nlinefeeds" );

   my @lines = $str->split( qr/\n/ );

   is( scalar @lines, 2, '->split returns 2 elements' );
   isa_ok( $lines[0], "String::Tagged", '->split returns String::Tagged instances' );

   is_deeply( [ map { $_->str } @lines ], [ "A message with", "linefeeds" ],
      '->split returns correct strings' );
}

# split preserves tags (RT100409)
{
   my $str = String::Tagged->new
      ->append       ( "one " )
      ->append_tagged( "two", tag => 1 )
      ->append       ( " three\nfour" );

   my @lines = $str->split( qr/\n/ );

   my $e = $lines[0]->get_tag_extent( index( $str->str, "two" ), "tag" );
   is( $e->start,  4, '$e->start of copied tag' );
   is( $e->length, 3, '$e->length of copied tag' );
}

# split with limit
{
   my $str = String::Tagged->new( "command with some arguments" );

   my @parts = $str->split( qr/\s+/, 2 );

   is( scalar @parts, 2, '->split with limit returns only that limit' );
   is_deeply( [ map { $_->str } @parts ], [ "command", "with some arguments" ],
      '->split with limit returns correct strings' );
}

# split with captures
{
   my $str = String::Tagged->new( "abc12def345" );

   my @parts = $str->split( qr/(\d+)/ );

   is( scalar @parts, 4, '->split with capture returns captures too' );
   is_deeply( [ map { $_->str } @parts ], [qw( abc 12 def 345 )],
      '->split with capture returns correct strings' );
}

done_testing;
