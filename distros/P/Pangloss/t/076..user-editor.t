#!/usr/bin/perl

##
## Tests for Pangloss::Application::UserEditor
##

use lib 't/lib';
use blib;
use strict;
use warnings;

use Test::More 'no_plan';

use Pixie;
use Error qw( :try );
use Data::Dumper;

use TestApp;
use CollectionTests;

use Pangloss::User;
use Pangloss::User::Error;
use Pangloss::User::Privileges;
BEGIN { use_ok("Pangloss::Application::UserEditor") }

my $app  = new TestApp()->store( new Pixie()->connect('memory') );
my $ed   = new Pangloss::Application::UserEditor()->parent( $app );
my $user = new Pangloss::User()
  ->id( 'test' )
  ->name( 'test user' )
  ->creator( 'test' )
  ->date( 1 );
$user->privileges
     ->add_translate_languages('test')
     ->add_proofread_languages('test');

## try adding
CollectionTests->test_add( $ed, $user );
CollectionTests->test_add_existing( $ed, $user );


## try listing collections
CollectionTests->test_list( $ed );

## try listing translators
{
    my $view = $ed->list_translators;
    isa_ok( $view->{"users_collection"}, 'Pangloss::Users', " view->users_collection" );
    if (isa_ok( $view, 'Pangloss::Application::View', 'list_translators' )) {
	if (isa_ok( $view->{translators}, 'ARRAY', " view->translators" )) {
	    ok( @{$view->{translators}}, ' contains some users' );
	} else {
	    diag( Dumper( $view ) );
	}
    }
}

## try listing proofreaders
{
    my $view = $ed->list_proofreaders;
    isa_ok( $view->{"users_collection"}, 'Pangloss::Users', " view->users_collection" );
    if (isa_ok( $view, 'Pangloss::Application::View', 'list_proofreaders' )) {
	if (isa_ok( $view->{proofreaders}, 'ARRAY', " view->proofreaders" )) {
	    ok( @{$view->{proofreaders}}, ' contains some users' );
	} else {
	    diag( Dumper( $view ) );
	}
    }
}


## try getting a collection
CollectionTests->test_get( $ed, $user );
CollectionTests->test_get_non_existent( $ed, $user );


## try modifying some details
$user->privileges
        ->admin(1)
        ->add_concepts(1)
        ->add_categories(1)
        ->add_translate_languages('test')
        ->add_proofread_languages('tset');

{
    my $view = CollectionTests->test_modify( $ed, $user, $user );

    if ($view) {
	my $privs = $view->{user}->privileges;
	ok( $privs->admin,          ' view->user->privs->admin' );
	ok( $privs->add_concepts,   ' view->user->privs->add_concepts' );
	ok( $privs->add_categories, ' view->user->privs->add_categories' );
	ok( $privs->can_translate('test'), ' view->user->privs->can_translate' );
	ok( $privs->can_proofread('tset'), ' view->user->privs->can_proofread' );
    }
}

## try modifying some details again
my $new_user = $user->clone->id( 'test2' )->name( 'test user renamed' );

{
    my $view = CollectionTests->test_modify( $ed, $user, $new_user );

    if ($view) {
	is( $view->{user}->id, 'test2', ' name changed' );
    }
}

## try removing a collection
CollectionTests->test_remove( $ed, $new_user );
CollectionTests->test_remove_non_existent( $ed, $new_user );

