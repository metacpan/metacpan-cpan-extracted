#!/usr/bin/env perl
#
# Basic testing that module loads

use Test::More tests => 3;

BEGIN { require_ok('Rose::DBx::Role::QueryCannery'); }

package _Test::Cannery;

use Rose::DBx::CannedQuery;
use Rose::DBx::Role::QueryCannery;
use Moo 2;

Rose::DBx::Role::QueryCannery->apply(
    { query_class => 'Rose::DBx::CannedQuery' } );

package main;

my $obj = new_ok( '_Test::Cannery' => [], 'generic test class works' );
can_ok( $obj, 'build_query' );

