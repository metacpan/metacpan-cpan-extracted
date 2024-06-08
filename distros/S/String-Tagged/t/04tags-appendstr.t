#!/usr/bin/perl

use v5.14;
use warnings;

use Test2::V0;

use String::Tagged;

my $str = String::Tagged->new();

is( [ $str->tagnames ], [], 'No tags defined initially' );

ref_is( scalar $str->apply_tag( -1, -1, everywhere => 1 ),
   $str, '->apply_tag returns $str' );

ref_is( scalar $str->append_tagged( "Hello", word => "greeting" ),
   $str, '->append_tagged returns $str' );

is( $str->str, "Hello", 'str after first append' );

is( [ sort $str->tagnames ],
           [qw( everywhere word )], 'tagnames after first append' );

is( $str->get_tags_at( 0 ), 
           { word => "greeting", everywhere => 1 },
           'tags at pos 0' );

is( $str->get_tag_at( 0, "word" ), "greeting", 'word tag at pos 0' );

my @tags;
sub fetch_tags
{
   my ( $start, $len, %tags ) = @_;
   push @tags, [ $start, $len, map { $_ => $tags{$_} } sort keys %tags ]
}
$str->iter_tags_nooverlap( \&fetch_tags );
is( \@tags, 
           [
              [ 0, 5, everywhere => 1, word => "greeting" ],
           ],
           'tags list after first append' );

$str->append_tagged( ", " ); # No tags

is( $str->str, "Hello, ", 'str after second append' );

undef @tags;
$str->iter_tags_nooverlap( \&fetch_tags );
is( \@tags, 
           [
              [ 0, 5, everywhere => 1, word => "greeting" ],
              [ 5, 2, everywhere => 1 ],
           ],
           'tags list after second append' );

$str->append_tagged( "world", word => "target" );

is( $str->str, "Hello, world", 'str after third append' );

undef @tags;
$str->iter_tags_nooverlap( \&fetch_tags );
is( \@tags, 
           [
              [ 0, 5, everywhere => 1, word => "greeting" ],
              [ 5, 2, everywhere => 1 ],
              [ 7, 5, everywhere => 1, word => "target" ],
           ],
           'tags list after third append' );

# Behaviour of edge-anchored tags under append
{
   my $str = String::Tagged->new( "orig" )
      ->apply_tag( 2, -1, tag => 1 );

   $str->append( "plain" );

   undef @tags;
   $str->iter_tags_nooverlap( \&fetch_tags );
   is( \@tags, [
         [ 0, 2 ],
         [ 2, 7, tag => 1 ],
      ],
      'edge-anchored tag extended after append plain string' );

   $str->append( String::Tagged->new( "tagged" ) );

   undef @tags;
   $str->iter_tags_nooverlap( \&fetch_tags );
   is( \@tags, [
         [ 0, 2 ],
         [ 2, 7, tag => 1 ],
         [ 9, 6 ],
      ],
      'edge-anchored tag extended after append String::Tagged' );
}

done_testing;
