#!/usr/bin/perl

##
## Tests for Pangloss::Search & Pangloss::Search::Results
##

use lib 't/lib';
use blib;
use strict;
use warnings;

use Test::More 'no_plan';

use Pangloss::Search;
use SearchTools;

BEGIN { use_ok( "Pangloss::Search::Filter" ); }

if (use_ok( "Pangloss::Search::Filter::Keyword" )) {
    my $search = SearchTools->create_search();
    my $filter = new Pangloss::Search::Filter::Keyword()
      ->set( 'blah' );
    ok( $filter->get,       ' get' );
    ok( $filter->not_empty, ' not_empty' );
    $search->add_filter( $filter )->apply;
    is( $search->results->size, 1, ' expected num results' );
}

if (use_ok( "Pangloss::Search::Filter::Document" )) {
    my $search = SearchTools->create_search();
    my $filter = new Pangloss::Search::Filter::Document()
      ->set( "this is a test\nshould match concept 1\n" );
    ok( $filter->get,       ' get' );
    ok( $filter->not_empty, ' not_empty' );
    $search->add_filter( $filter )->apply;
    is( $search->results->size, 2, ' expected num results' );
}

if (use_ok( "Pangloss::Search::Filter::Base" )) {
    my $filter = new Pangloss::Search::Filter::Base;
    ok( $filter,                            ' new filter' );
    ok( $filter->is_empty,                  ' is empty' );
    ok(!$filter->not_empty,                 ' ! not empty' );
    ok( $filter->not_set('foo'),            ' not_set(foo)' );
    is( $filter->set('foo','bar'), $filter, ' set(foo, bar)' );
    ok( $filter->is_set('foo'),             ' is_set(foo)' );
    ok( $filter->not_empty,                 ' not empty' );
    is( $filter->keys, 2,                   ' keys' );
    is( $filter->size, 2,                   ' expected size' );
    is( $filter->unset('foo'), $filter,     ' unset(foo)' );
    ok(!$filter->is_set('foo'),             ' ! is_set(foo)' );
    is( $filter->size, 1,                   ' expected size' );
    is( $filter->toggle('bar'), 0,          ' toggle' );
    is( $filter->size, 0,                   ' expected size' );
    is( $filter->toggle('bar'), 1,          ' toggle' );
}

if (use_ok( "Pangloss::Search::Filter::Category" )) {
    my $search = SearchTools->create_search();
    my $filter = new Pangloss::Search::Filter::Category()
      ->set( 'category 3', 'category 2' );
    $search->add_filter( $filter )->apply;
    is( $search->results->size, 2, ' expected num results' );
}

if (use_ok( "Pangloss::Search::Filter::Concept" )) {
    my $search = SearchTools->create_search();
    my $filter = new Pangloss::Search::Filter::Concept()
      ->set('concept 1');
    $search->add_filter( $filter )->apply;
    is( $search->results->size, 2, ' expected num results' );
}

if (use_ok( "Pangloss::Search::Filter::Language" )) {
    my $search = SearchTools->create_search();
    my $filter = new Pangloss::Search::Filter::Language()
      ->set('te');
    $search->add_filter( $filter )->apply;
    is( $search->results->size, 1, ' expected num results' );
}

if (use_ok( "Pangloss::Search::Filter::Translator" )) {
    my $search = SearchTools->create_search();
    my $filter = new Pangloss::Search::Filter::Translator()
      ->set( 'user 2', 'user 3' );
    $search->add_filter( $filter )->apply;
    is( $search->results->size, 2, ' expected num results' );
}

if (use_ok( "Pangloss::Search::Filter::Proofreader" )) {
    my $search = SearchTools->create_search();
    my $filter = new Pangloss::Search::Filter::Proofreader()
      ->set('user A');
    $search->add_filter( $filter )->apply;
    is( $search->results->size, 2, ' expected num results' );
}

if (use_ok( "Pangloss::Search::Filter::Status" )) {
    my $search = SearchTools->create_search();
    my $filter = new Pangloss::Search::Filter::Status()
      ->set( Pangloss::Term::Status->PENDING,
	     Pangloss::Term::Status->DEPRECATED );
    $search->add_filter( $filter )->apply;
    is( $search->results->size, 2, ' expected num results' );
}

if (use_ok( "Pangloss::Search::Filter::DateRange" )) {
    my $search = SearchTools->create_search();
    my $filter = new Pangloss::Search::Filter::DateRange()
      ->from( 3 )
      ->to( 3 );
    $search->add_filter( $filter )->apply;
    is( $search->results->size, 1, ' expected num results' );
}


