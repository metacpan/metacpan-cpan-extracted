#!/usr/bin/perl

##
## Tests for Pangloss::Application::ConceptEditor
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

use Pangloss::Concept;
use Pangloss::Concept::Error;
BEGIN { use_ok("Pangloss::Application::ConceptEditor") }

my $app     = new TestApp()->store( new Pixie()->connect('memory') );
my $ed      = new Pangloss::Application::ConceptEditor()->parent( $app );
my $concept = new Pangloss::Concept()
  ->name( 'test concept' )
  ->creator( 'test user' )
  ->date( 1 );

## try adding a concept
CollectionTests->test_add( $ed, $concept );
CollectionTests->test_add_existing( $ed, $concept );


## try listing concepts
CollectionTests->test_list( $ed );


## try getting a concept
CollectionTests->test_get( $ed, $concept );
CollectionTests->test_get_non_existent( $ed, $concept );


## try modifying some details
my $new_concept = $concept->clone
  ->name( 'concept renamed' )
  ->creator( 'new user' )
  ->date( 2 );

my $view = CollectionTests->test_modify( $ed, $concept, $new_concept );

if ($view) {
    is( $view->{concept}->name, 'concept renamed', 'name changed' );
    isnt( $view->{concept}->date, '2',             'date kept the same' );
}


## try removing a concept
CollectionTests->test_remove( $ed, $new_concept );
CollectionTests->test_remove_non_existent( $ed, $new_concept );

