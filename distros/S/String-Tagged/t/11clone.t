#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

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
   is_deeply( [ sort $new->tagnames ], [qw( some tags )], '->tagnames of clone' );
}

# instance clone
{
   my $new = $orig->clone;

   is( $new->str, "this string has some tags applied to it", '->str of clone' );
}

# subset clone
{
   my $new = $orig->clone( only_tags => [qw( tags )] );
   is_deeply( [ $new->tagnames ], [qw( tags )], '->tagnames of partial clone' );
}

# clone with converter
{
   my $new = $orig->clone(
      convert_tags => {
         some => sub { $_[0], $_[1] + 1 },
         tags => "different_tag",
      }
   );

   is_deeply( [ sort $new->tagnames ], [qw( different_tag some )], '->tagnames of converted clone' );

   is( $new->get_tag_at( index( $new, "some" ), "some" ), 2, 'value of sub-converted tag' );
}

done_testing;
