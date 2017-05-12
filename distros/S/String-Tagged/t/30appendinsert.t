#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use String::Tagged;

my $begin = String::Tagged->new( "BEGIN" );
$begin->apply_tag( -1, 5, begin => 1 );

my $middle = String::Tagged->new( " middle " );
$middle->apply_tag( 1, 6, middle => 1 );

my $end = String::Tagged->new( "END" );
$end->apply_tag( 0, -1, end => 1 );

my $str = String::Tagged->new( $begin );
$str->append( $middle );

is( $str->str, "BEGIN middle ", 'str after first append' );

my @tags;
sub fetch_tags
{
   my ( $start, $len, %tags ) = @_;
   push @tags, [ $start, $len, map { $_ => $tags{$_} } sort keys %tags ]
}

$str->iter_tags_nooverlap( \&fetch_tags );
is_deeply( \@tags, 
           [
              [  0, 5, begin  => 1 ],
              [  5, 1, ],
              [  6, 6, middle => 1 ],
              [ 12, 1, ],
           ],
           'tags list after first append' );

$str->append( $end );

is( $str->str, "BEGIN middle END", 'str after second append' );

undef @tags;
$str->iter_tags_nooverlap( \&fetch_tags );
is_deeply( \@tags, 
           [
              [  0, 5, begin  => 1 ],
              [  5, 1, ],
              [  6, 6, middle => 1 ],
              [ 12, 1, ],
              [ 13, 3, end    => 1 ],
           ],
           'tags list after secondappend' );

$str = String::Tagged->new( $begin );
$str->insert( 0, $middle );

is( $str->str, " middle BEGIN", 'str after first prepend' );

undef @tags;
$str->iter_tags_nooverlap( \&fetch_tags );
is_deeply( \@tags, 
           [
              [ 0, 1, begin => 1 ],
              [ 1, 6, begin => 1, middle => 1 ],
              [ 7, 6, begin => 1 ],
           ],
           'tags list after first prepend' );

$str->insert( 0, $end );

is( $str->str, "END middle BEGIN", 'str after second prepend' );

undef @tags;
$str->iter_tags_nooverlap( \&fetch_tags );
is_deeply( \@tags, 
           [
              [  0, 3, begin => 1, end => 1 ],
              [  3, 1, begin => 1 ],
              [  4, 6, begin => 1, middle => 1 ],
              [ 10, 6, begin => 1 ],
           ],
           'tags list after second prepend' );

done_testing;
