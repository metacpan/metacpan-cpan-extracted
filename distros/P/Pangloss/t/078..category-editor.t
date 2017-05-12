#!/usr/bin/perl

##
## Tests for Pangloss::Application::CategoryEditor
##

use lib 't/lib';
use blib;
use strict;
use warnings;

use Test::More 'no_plan';

use Pixie;
use Error qw( :try );

use TestApp;
use CollectionTests;

use Pangloss::Category;
use Pangloss::Category::Error;
BEGIN { use_ok("Pangloss::Application::CategoryEditor") }

my $app = new TestApp()->store( new Pixie()->connect('memory') );
my $ed  = new Pangloss::Application::CategoryEditor()->parent( $app );
my $cat = new Pangloss::Category()
  ->name( 'test' )
  ->notes( 'test category' )
  ->creator( 'test user' )
  ->date( 1 );

## try adding a category
CollectionTests->test_add( $ed, $cat );
CollectionTests->test_add_existing( $ed, $cat );


## try listing categorys
CollectionTests->test_list( $ed );


## try getting a category
CollectionTests->test_get( $ed, $cat );
CollectionTests->test_get_non_existent( $ed, $cat );


## try modifying some details
my $new_cat = $cat->clone
  ->name( 'test2' )
  ->notes( 'new notes' )
  ->creator( 'new user' )
  ->date( 2 );

my $view = CollectionTests->test_modify( $ed, $cat, $new_cat );

if ($view) {
    is( $view->{category}->name, 'test2',        'name changed' );
    is( $view->{category}->notes, 'new notes',   'notes changed' );
    isnt( $view->{category}->date, '2',          'date kept the same' );
}


## try removing a category
CollectionTests->test_remove( $ed, $new_cat );
CollectionTests->test_remove_non_existent( $ed, $new_cat );

