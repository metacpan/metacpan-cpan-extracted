#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use String::Tagged;

my $str = String::Tagged->new( "My message is here" );

$str->apply_tag( -1, -1, message => 1 );

my @tags;
$str->iter_tags_nooverlap( sub { push @tags, [ @_ ] } );
is( \@tags, 
           [
              [ 0, 18, message => 1 ],
           ],
           'tags list initially' );

ref_is( $str->delete_tag( 3, 4, 'message' ), $str, '->delete_tag returns $str' );

undef @tags;
$str->iter_tags_nooverlap( sub { push @tags, [ @_ ] } );
is( \@tags, 
           [
             [ 0, 18 ],
           ],
           'tags list after delete' );

$str->apply_tag( -1, -1, message => 1 );

ref_is( $str->unapply_tag( 3, 4, 'message' ), $str, '->unapply_tag returns $str' );

undef @tags;
$str->iter_tags_nooverlap( sub { push @tags, [ @_ ] } );
is( \@tags, 
           [
             [ 0,  3, message => 1 ],
             [ 3,  4, ],
             [ 7, 11, message => 1 ],
           ],
           'tags list after unapply' );

$str->unapply_tag( 3, 7, 'message' );

undef @tags;
$str->iter_tags_nooverlap( sub { push @tags, [ @_ ] } );
is( \@tags, 
           [
             [  0, 3, message => 1 ],
             [  3, 7, ],
             [ 10, 8, message => 1 ],
           ],
           'tags list after second unapply' );

$str->unapply_tag( 0, 5, 'message' );

undef @tags;
$str->iter_tags_nooverlap( sub { push @tags, [ @_ ] } );
is( \@tags, 
           [
             [  0, 10, ],
             [ 10,  8, message => 1 ],
           ],
           'tags list after third unapply' );

# delete all
{
   my $str = String::Tagged->new
      ->append_tagged( 123, A => 1 )
      ->append_tagged( 456, B => 1 )
      ->append_tagged( 789, A => 1 );

   $str->delete_all_tag( "A" );

   is( [ $str->tagnames ], [ "B" ], '->delete_all_tag removes all of a tag' );
}

# Check we can safely delete tags during iteration
{
   my $str = String::Tagged->new
      ->append_tagged( "A", letter => 1 )
      ->append_tagged( "B", letter => 1 )
      ->append_tagged( "C", letter => 1 )
      ->append_tagged( "D", letter => 1 )
      ->append_tagged( "E", letter => 1 );

   $str->iter_extents(
      sub { my ( $e ) = @_; $str->delete_tag( $e, "letter" ) }
   );

   is( [ $str->tagnames ], [], '->delete_tag at iter_tags position clears all' );
}

done_testing;
