#!/usr/bin/perl

##
## Tests for Pangloss::Segment::Concept*
##

use lib 't/lib';
use blib;
use strict;
use warnings;

use Test::More 'no_plan';
use TestSeg qw( test_and_get_view test_request_setter
	        test_seg test_request_decliner );

use Pixie;
use Error qw( :try );

use OpenFrame::Request;
use Pipeline::Segment::Tester;
use OpenFrame::WebApp::Session::MemCache;

use Pangloss::User;
use Pangloss::Concept;
use Pangloss::Application;

my $req  = new OpenFrame::Request();
my $app  = new Pangloss::Application()->store( new Pixie()->connect('memory') );
my $ed   = $app->concept_editor;
my $user = new Pangloss::User()->id('test');
my $sess = new OpenFrame::WebApp::Session::MemCache()->set('user', $user);

my %cats = (test => 'test cat', to_remove => 'remove me!');
foreach my $code (keys %cats) {
    my $cat = Pangloss::Concept->new()
      ->name($code)
      ->notes($cats{$code})
      ->creator($user->id)
      ->date(1);
    $ed->add( $cat );
}

## load concept from request
if (use_ok("Pangloss::Segment::LoadConcept")) {
    $req->arguments({ new_concept_name     => 'a test',
		      new_concept_category => 'test cat',
		      new_concept_notes    => 'some notes...' });
    my $seg = new Pangloss::Segment::LoadConcept();
    my $pt  = test_seg( $seg, $req, $sess );
    my $concept = $pt->pipe->store->get('Pangloss::Concept');
    if (ok( $concept, 'load concept' )) {
	is( $concept->creator, 'test', ' concept->creator set' );
    }
    $req->arguments({});
}

## list concepts
if (use_ok("Pangloss::Segment::ListConcepts")) {
    my $seg  = new Pangloss::Segment::ListConcepts();
    my $view = test_and_get_view( $seg, $app, $req );
    is( @{ $view->{concepts} }, 2, 'list concepts' );
}

test_request_decliner( class => "Pangloss::Segment::Decline::NoListConcepts",
		       on    => { list_concepts => 1 },
		       off   => {} );

## add concept
if (use_ok("Pangloss::Segment::AddConcept")) {
    my $concept = new Pangloss::Concept()
      ->name( 'te' )
      ->notes( 'another test' )
      ->creator( 'test' )
      ->category( 'test category' );
    $req->arguments({ add_concept => 1 });
    my $seg  = new Pangloss::Segment::AddConcept();
    my $view = test_and_get_view( $seg, $app, $req, $sess, $concept );
    if (isa_ok( $view->{concept}, 'Pangloss::Concept', 'add view->concept' )) {
	ok( $view->{concept}->{added}, 'view->concept->added' );
    }
    $req->arguments({});
}

## get concept
if (use_ok("Pangloss::Segment::GetConcept")) {
    $req->arguments({ get_concept      => 1,
		      selected_concept => 'test' });
    my $seg  = new Pangloss::Segment::GetConcept();
    my $view = test_and_get_view( $seg, $app, $req );
    isa_ok( $view->{concept}, 'Pangloss::Concept', 'get view->concept' );
    $req->arguments({});
}

## modify concept
if (use_ok("Pangloss::Segment::ModifyConcept")) {
    my $concept = new Pangloss::Concept()
      ->name( 'tset' )
      ->notes( 'test backwards' )
      ->category( 'test category' );
    $req->arguments({ modify_concept   => 1,
		      selected_concept => 'test' });
    my $seg  = new Pangloss::Segment::ModifyConcept();
    my $view = test_and_get_view( $seg, $app, $req, $sess, $concept );
    if (isa_ok( $view->{concept}, 'Pangloss::Concept', 'mod view->concept' )) {
	ok( $view->{concept}->{modified}, 'view->concept->modified' );
    }
    $req->arguments({});
}

## remove concept
if (use_ok("Pangloss::Segment::RemoveConcept")) {
    $req->arguments({ remove_concept   => 1,
		      selected_concept => 'to_remove' });
    my $seg  = new Pangloss::Segment::RemoveConcept();
    my $view = test_and_get_view( $seg, $app, $req );
    if (isa_ok( $view->{concept}, 'Pangloss::Concept', 'rm view->concept' )) {
	ok( $view->{concept}->{removed}, 'remove concept' );
    }
    $req->arguments({});
}

## no selected concept
if (use_ok("Pangloss::Segment::Decline::NoSelectedConcept")) {
    $req->arguments({});
    my $seg = new Pangloss::Segment::Decline::NoSelectedConcept();
    my ($pt, $prod) = test_seg( $seg, $req );
    like( $prod, qr/declined/, 'no selected concept' );
}

## no concept
if (use_ok("Pangloss::Segment::Decline::NoConcept")) {
    $req->arguments({});
    my $seg = new Pangloss::Segment::Decline::NoConcept();
    my ($pt, $prod) = test_seg( $seg, $req );
    like( $prod, qr/declined/, 'no concept' );
}

# request - get concept
test_request_setter( 'Pangloss::Segment::Request::GetConcept', 'get_concept' );

# request - list concepts
test_request_setter( 'Pangloss::Segment::Request::ListConcepts', 'list_concepts' );

