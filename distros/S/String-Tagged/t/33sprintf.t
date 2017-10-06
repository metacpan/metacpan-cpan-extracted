#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use String::Tagged;

# base case
{
   my $str = String::Tagged->from_sprintf( "%s and %d", "strings", 123 );
   is( $str->str, "strings and 123", 'base case' );

   $str = String::Tagged->from_sprintf( "Can print literal %% mark" );
   is( $str->str, "Can print literal % mark", 'literal %' );

   $str = String::Tagged->from_sprintf( "%d and %s", 456, "order" );
   is( $str->str, "456 and order", 'base case preserves order' );
}

# a tagged %s argument
{
   my $str = String::Tagged->from_sprintf( "A %s here",
      String::Tagged->new_tagged( "string", tagged => 1 ) );

   is( $str->str, "A string here", 'tagged argument value' );
   ok( $str->get_tag_extent( 2, "tagged" ),
      'tagged argument has tag in result' );
}

# %s padding
{
   is( String::Tagged->from_sprintf( "%20s", "value" )->str,
      '               value',
      '%s padding right-aligned' );

   is( String::Tagged->from_sprintf( "%-20s", "value" )->str,
      'value               ',
      '%s padding left-aligned' );

   is( String::Tagged->from_sprintf( "%5s", "long value" )->str,
      'long value',
      '%s padding excess' );

   is( String::Tagged->from_sprintf( "%-*s", 10, "value" )->str,
      'value     ',
      '%s padding dynamic size' );
}

# %s truncation
{
   is( String::Tagged->from_sprintf( "%.3s", "value" )->str,
      'val',
      '%s truncation' );

   is( String::Tagged->from_sprintf( "%.*s", 2, "value" )->str,
      'va',
      '%s truncation dynamic size' );
}

# tagged format
{
   my $str = String::Tagged->from_sprintf(
      String::Tagged->new_tagged( "A tagged format", tagged => 1 ) );

   is( $str->str, "A tagged format", 'tagged format value' );
   ok( $str->get_tag_extent( 2, "tagged" ),
      'tagged format has tag in result' );

   $str = String::Tagged->new_tagged( "Single %s here", span => 1 )
      ->sprintf( "tag" );

   is( $str->str, "Single tag here", 'tagged format with conversion' );

   my $e;
   ok( $e = $str->get_tag_extent( 0, "span" ),
      'tagged format with conversion has tag in result' ) and do {
      is( $e->end, length $str, 'tag from format covers the entire result' );
   };
}

done_testing;
