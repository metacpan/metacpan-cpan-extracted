#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Identity;

use String::Tagged;

my $str = String::Tagged->new();

is_deeply( [ $str->tagnames ], [], 'No tags defined initially' );

identical( scalar $str->apply_tag( -1, -1, everywhere => 1 ),
   $str, '->apply_tag returns $str' );

identical( scalar $str->append_tagged( "Hello", word => "greeting" ),
   $str, '->append_tagged returns $str' );

is( $str->str, "Hello", 'str after first append' );

is_deeply( [ sort $str->tagnames ],
           [qw( everywhere word )], 'tagnames after first append' );

is_deeply( $str->get_tags_at( 0 ), 
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
is_deeply( \@tags, 
           [
              [ 0, 5, everywhere => 1, word => "greeting" ],
           ],
           'tags list after first append' );

$str->append_tagged( ", " ); # No tags

is( $str->str, "Hello, ", 'str after second append' );

undef @tags;
$str->iter_tags_nooverlap( \&fetch_tags );
is_deeply( \@tags, 
           [
              [ 0, 5, everywhere => 1, word => "greeting" ],
              [ 5, 2, everywhere => 1 ],
           ],
           'tags list after second append' );

$str->append_tagged( "world", word => "target" );

is( $str->str, "Hello, world", 'str after third append' );

undef @tags;
$str->iter_tags_nooverlap( \&fetch_tags );
is_deeply( \@tags, 
           [
              [ 0, 5, everywhere => 1, word => "greeting" ],
              [ 5, 2, everywhere => 1 ],
              [ 7, 5, everywhere => 1, word => "target" ],
           ],
           'tags list after third append' );

done_testing;
