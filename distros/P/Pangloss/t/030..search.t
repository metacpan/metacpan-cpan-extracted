#!/usr/bin/perl

##
## Tests for Pangloss::Search & Pangloss::Search::Results
##

use lib 't/lib';
use blib;
use strict;
use warnings;

use Test::More 'no_plan';

BEGIN { use_ok( "Pangloss::Search" ); }
BEGIN { use_ok( "Pangloss::Search::Filter" ); }
use SearchTools;

my $search = new Pangloss::Search;
ok( $search, 'new' ) || die "cannot proceed!\n";

is( $search->categories( SearchTools->create_categories() ), $search, 'categories(set)' );
is( $search->concepts( SearchTools->create_concepts() ),     $search, 'concepts(set)' );
is( $search->languages( SearchTools->create_languages() ),   $search, 'languages(set)' );
is( $search->terms( SearchTools->create_terms() ),           $search, 'terms(set)' );
is( $search->users( SearchTools->create_users() ),           $search, 'users(set)' );

is( $search->apply, $search, 'apply' );

is( $search->terms->size, 4,   ' expected num terms' );
is( $search->results->size, 0, ' expected num results' );

is( $search->add_filter( Pangloss::Search::Filter->new ), $search,  'add_filter' );
is( $search->add_filters( Pangloss::Search::Filter->new ), $search, 'add_filters' );

# don't try anything else w/o resetting filters...

