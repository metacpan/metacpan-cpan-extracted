#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Identity;

use String::Tagged;

my $str = String::Tagged->new( "My message is here" );

$str->apply_tag( -1, -1, message => 1 );

my @tags;
$str->iter_tags_nooverlap( sub { push @tags, [ @_ ] } );
is_deeply( \@tags, 
           [
              [ 0, 18, message => 1 ],
           ],
           'tags list initially' );

identical( $str->delete_tag( 3, 4, 'message' ), $str, '->delete_tag returns $str' );

undef @tags;
$str->iter_tags_nooverlap( sub { push @tags, [ @_ ] } );
is_deeply( \@tags, 
           [
             [ 0, 18 ],
           ],
           'tags list after delete' );

$str->apply_tag( -1, -1, message => 1 );

identical( $str->unapply_tag( 3, 4, 'message' ), $str, '->unapply_tag returns $str' );

undef @tags;
$str->iter_tags_nooverlap( sub { push @tags, [ @_ ] } );
is_deeply( \@tags, 
           [
             [ 0,  3, message => 1 ],
             [ 3,  4, ],
             [ 7, 11, message => 1 ],
           ],
           'tags list after unapply' );

$str->unapply_tag( 3, 7, 'message' );

undef @tags;
$str->iter_tags_nooverlap( sub { push @tags, [ @_ ] } );
is_deeply( \@tags, 
           [
             [  0, 3, message => 1 ],
             [  3, 7, ],
             [ 10, 8, message => 1 ],
           ],
           'tags list after second unapply' );

$str->unapply_tag( 0, 5, 'message' );

undef @tags;
$str->iter_tags_nooverlap( sub { push @tags, [ @_ ] } );
is_deeply( \@tags, 
           [
             [  0, 10, ],
             [ 10,  8, message => 1 ],
           ],
           'tags list after third unapply' );

done_testing;
