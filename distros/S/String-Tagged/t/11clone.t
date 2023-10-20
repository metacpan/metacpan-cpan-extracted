#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use String::Tagged;

my $orig = String::Tagged->new
   ->append       ( "this string has " )
   ->append_tagged( "some", some => 1 )
   ->append       ( " " )
   ->append_tagged( "tags", tags => 1 )
   ->append       ( " applied to it" );

# full clone
{
   my $new = String::Tagged->clone( $orig );

   is( $new->str, "this string has some tags applied to it", '->str of clone' );
   is( [ sort $new->tagnames ], [qw( some tags )], '->tagnames of clone' );
}

# instance clone
{
   my $new = $orig->clone;

   is( $new->str, "this string has some tags applied to it", '->str of clone' );
}

# subset clone
{
   my $new = $orig->clone( only_tags => [qw( tags )] );
   is( [ $new->tagnames ], [qw( tags )], '->tagnames of partial clone' );
}

# clone with converter
{
   my $new = $orig->clone(
      convert_tags => {
         some => sub { $_[0], $_[1] + 1 },
         tags => "different_tag",
      }
   );

   is( [ sort $new->tagnames ], [qw( different_tag some )], '->tagnames of converted clone' );

   is( $new->get_tag_at( index( $new, "some" ), "some" ), 2, 'value of sub-converted tag' );
}

# substr clone
{
   my $new = String::Tagged->clone( $orig,
      start => 16,
      end   => 33,
   );

   is( $new->str, "some tags applied", '->str of clone with position' );
   ok( my $e = $new->get_tag_extent( 0, "some" ), 'clone with position has "some" tag' );
   is( $e->start, 0, '"some" tag extent start' );
   is( $e->end, 4, '"some" tag extent end' );
   ok( !$e->anchor_before, '"some" tag not anchored before' );

   $new = String::Tagged->clone( $orig,
      start => 16,
      len   => 17,
   );

   is( $new->str, "some tags applied", '->str of clone with position' );

   # edge anchoring

   $new = String::Tagged->clone( $orig,
      start => 16+1,
      end   => 33-1,
   );

   ok( $e = $new->get_tag_extent( 0, "some" ), 'clone with position has "some" tag' );
   ok( $e->anchor_before, '"some" tag anchored before' );
}

done_testing;
