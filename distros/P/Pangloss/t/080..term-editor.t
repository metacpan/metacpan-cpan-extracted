#!/usr/bin/perl

##
## Tests for Pangloss::Application::TermEditor
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

use Pangloss::Term;
use Pangloss::Term::Error;
BEGIN { use_ok("Pangloss::Application::TermEditor") }

my $app  = new TestApp()->store( new Pixie()->connect('memory') );
my $ed   = new Pangloss::Application::TermEditor()->parent( $app );
my $term = new Pangloss::Term()
  ->name( 'test term' )
  ->concept(1)
  ->language(1)
  ->creator(1)
  ->date(1);

## try adding a term
CollectionTests->test_add( $ed, $term );
CollectionTests->test_add_existing( $ed, $term );


## try listing terms
CollectionTests->test_list( $ed );


## try getting a term
CollectionTests->test_get( $ed, $term );
CollectionTests->test_get_non_existent( $ed, $term );


## try modifying some details
my $new_term = $term->clone->name( 'term renamed' )->date( 2 );
{
    my $view = CollectionTests->test_modify( $ed, $term, $new_term );

    if ($view) {
	is( $view->{term}->name, 'term renamed', ' name changed' );
	isnt( $view->{term}->date, 2,            ' date kept the same' );
    }
}

## try modifying status
{
    my $status = new Pangloss::Term::Status()->rejected()->notes('test');
    my $view = $ed->modify_status( $new_term->key, $status );

    if (isa_ok( $view, 'Pangloss::Application::View', 'modify_status' )) {
	isa_ok( $view->{term}, 'Pangloss::Term',   " view->term" );
	ok    ( $view->{modify}->{term},           " view->modify->term" );
	ok    ( $view->{term}->status->{modified}, " view->term->status->modified" );
    }
}


## try removing a term
CollectionTests->test_remove( $ed, $new_term );
CollectionTests->test_remove_non_existent( $ed, $new_term );

## try listing status codes
{
    my $view = $ed->list_status_codes;
    if (isa_ok( $view, 'Pangloss::Application::View', 'list_status_codes' )) {
	if (isa_ok( $view->{status_codes}, 'HASH', " view->status_codes" )) {
	    ok( $view->{status_codes}->{pending}, ' view->status_codes->pending' );
	} else {
	    diag( Dumper( $view ) );
	}
    }
}
