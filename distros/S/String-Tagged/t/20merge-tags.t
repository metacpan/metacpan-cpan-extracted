#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use String::Tagged;

my $str = String::Tagged->new( "Hello, world" );

$str->apply_tag( 0, 6, message => 1 );
$str->apply_tag( 6, 6, message => 1 );

my @tags;
$str->iter_tags( sub { push @tags, [ @_ ] } );
is_deeply( \@tags, 
           [
              [ 0, 6, message => 1 ],
              [ 6, 6, message => 1 ],
           ],
           'tags list before merge' );

$str->merge_tags( sub { $_[1] == $_[2] } );

undef @tags;
$str->iter_tags( sub { push @tags, [ @_ ] } );
is_deeply( \@tags, 
           [
              [ 0, 12, message => 1 ],
           ],
           'tags list after merge' );

$str = String::Tagged->new( "Hello, world" );

$str->apply_tag( 0, 6, message => 1 );
$str->apply_tag( 6, 6, message => 2 );

$str->merge_tags( sub { $_[1] == $_[2] } );

undef @tags;
$str->iter_tags( sub { push @tags, [ @_ ] } );
is_deeply( \@tags, 
           [
              [ 0, 6, message => 1 ],
              [ 6, 6, message => 2 ],
           ],
           'tags list after merge differing values' );

$str = String::Tagged->new( "Hello, world" );

$str->apply_tag( 0, 6, message => 1 );
$str->apply_tag( 6, 6, others  => 1 );

$str->merge_tags( sub { $_[1] == $_[2] } );

undef @tags;
$str->iter_tags( sub { push @tags, [ @_ ] } );
is_deeply( \@tags, 
           [
              [ 0, 6, message => 1 ],
              [ 6, 6, others  => 1 ],
           ],
           'tags list after merge differing names' );

$str = String::Tagged->new( "Hello, world" );

$str->apply_tag( 0, 4, message => 1 );
$str->apply_tag( 4, 4, message => 1 );
$str->apply_tag( 8, 4, message => 1 );

$str->merge_tags( sub { $_[1] == $_[2] } );

undef @tags;
$str->iter_tags( sub { push @tags, [ @_ ] } );
is_deeply( \@tags, 
           [
              [ 0, 12, message => 1 ],
           ],
           'tags list after merge 3' );

$str = String::Tagged->new( "Hello, world" );

$str->apply_tag( 0,  4, message => 1 );
$str->apply_tag( 8, 12, message => 1 );

$str->merge_tags( sub { $_[1] == $_[2] } );

undef @tags;
$str->iter_tags( sub { push @tags, [ @_ ] } );
is_deeply( \@tags, 
           [
              [ 0, 4, message => 1 ],
              [ 8, 4, message => 1 ],
           ],
           'tags list after merge non-overlap' );

$str = String::Tagged->new( "Hello, world" );

$str->apply_tag( 0,  8, message => 1 );
$str->apply_tag( 4, 12, message => 1 );

$str->merge_tags( sub { $_[1] == $_[2] } );

undef @tags;
$str->iter_tags( sub { push @tags, [ @_ ] } );
is_deeply( \@tags, 
           [
              [ 0, 12, message => 1 ],
           ],
           'tags list after merge with overlap' );

$str = String::Tagged->new( "Hello, world" );

$str->apply_tag( 0,  5, word => 1 );
$str->apply_tag( 0,  1, message => 1 );
$str->apply_tag( 1, 11, message => 1 );

$str->merge_tags( sub { $_[1] == $_[2] } );

undef @tags;
$str->iter_tags( sub { push @tags, [ @_ ] } );
is_deeply( \@tags, 
           [
              [ 0,  5, word    => 1 ],
              [ 0, 12, message => 1 ],
           ],
           'tags list after merge with overlap' );

done_testing;
