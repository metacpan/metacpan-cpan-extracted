#!/usr/bin/perl

##
## Tests for Pangloss::Application::CollectionEditor
##

use lib 't/lib';
use blib;
use strict;
use warnings;

use Test::More 'no_plan';

use Pixie;
use Error qw( :try );

use TestApp;
use TestCollection;
use TestCollectionObject;
use CollectionTests;

BEGIN { use_ok('Pangloss::Application::CollectionEditor'); }
BEGIN { use_ok('TestCollectionEditor'); }

my $app = new TestApp()->store( new Pixie()->connect('memory') );
my $ed  = new TestCollectionEditor()->parent( $app );
my $obj = new TestCollectionObject()
  ->id( 'test' )
  ->name( 'test obj' )
  ->creator( 'test user' );


## try adding
CollectionTests->test_add( $ed, $obj );
CollectionTests->test_add_existing( $ed, $obj );


## try listing collections
CollectionTests->test_list( $ed );


## try getting a collection
CollectionTests->test_get( $ed, $obj );
CollectionTests->test_get_non_existent( $ed, $obj );


## try modifying some details
my $new_obj = $obj->clone->id( 'test2' )->name( 'obj renamed' );
my $view    = CollectionTests->test_modify( $ed, $obj, $new_obj );

if ($view && ! $view->{object}->{error}) {
    is( $view->{object}->id, 'test2',         'id changed' );
    is( $view->{object}->name, 'obj renamed', 'name changed' );
}


## try removing a collection
CollectionTests->test_remove( $ed, $new_obj );
CollectionTests->test_remove_non_existent( $ed, $new_obj );

