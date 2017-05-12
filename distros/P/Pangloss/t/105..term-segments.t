#!/usr/bin/perl

##
## Tests for Pangloss::Segment::Term*
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
use Pangloss::Term;
use Pangloss::Term::Status;
use Pangloss::Application;

my $req  = new OpenFrame::Request();
my $app  = new Pangloss::Application()->store( new Pixie()->connect('memory') );
my $ed   = $app->term_editor;
my $user = new Pangloss::User()->id('test');
my $sess = new OpenFrame::WebApp::Session::MemCache()->set('user', $user);

my %terms = (test => 'test term', to_remove => 'remove me!');
foreach my $code (keys %terms) {
    my $term = Pangloss::Term->new()
      ->name($code)
      ->notes($terms{$code})
      ->concept(1)
      ->language(1)
      ->creator( $user->id )
      ->date(1);
    $ed->add( $term );
    $terms{$code} = $term->key;
}

## load term from request
if (use_ok("Pangloss::Segment::LoadTerm")) {
    $req->arguments({ new_term_name     => 'a test',
		      new_term_concept  => 'test concept',
		      new_term_language => 'test language',
		      new_term_notes    => 'some notes...' });
    my $seg = new Pangloss::Segment::LoadTerm();
    my $pt  = test_seg( $seg, $req, $sess );
    my $term = $pt->pipe->store->get('Pangloss::Term');
    if (ok( $term, 'load term' )) {
	is( $term->creator, 'test', ' term->creator set' );
    }
    $req->arguments({});
}

## load term status from request
if (use_ok("Pangloss::Segment::LoadTermStatus")) {
    $req->arguments({ new_term_status_code  => 'a test',
		      new_term_status_notes => 'some notes...' });
    my $seg = new Pangloss::Segment::LoadTermStatus();
    my $pt  = test_seg( $seg, $req, $sess );
    my $status = $pt->pipe->store->get('Pangloss::Term::Status');
    if (ok( $status, 'load term status' )) {
	is( $status->creator, 'test', ' status->creator set' );
    }
    $req->arguments({});
}

## list terms
if (use_ok("Pangloss::Segment::ListTerms")) {
    my $seg  = new Pangloss::Segment::ListTerms();
    my $view = test_and_get_view( $seg, $app, $req, $sess );
    is( @{ $view->{terms} }, 2, 'list terms' );
}

test_request_decliner( class => "Pangloss::Segment::Decline::NoListTerms",
		       on    => { list_terms => 1 },
		       off   => {} );

## list term status codes
if (use_ok("Pangloss::Segment::ListStatusCodes")) {
    my $seg  = new Pangloss::Segment::ListStatusCodes();
    my $view = test_and_get_view( $seg, $app, $req, $sess );
    is( keys %{ $view->{status_codes} }, 4, 'list status codes' );
}

test_request_decliner( class => "Pangloss::Segment::Decline::NoListStatusCodes",
		       on    => { list_status_codes => 1 },
		       off   => {} );

## add term
my $term_key;
if (use_ok("Pangloss::Segment::AddTerm")) {
    my $term = new Pangloss::Term()
      ->name( 'te' )
      ->concept( 'test concept' )
      ->language( 'test language' )
      ->creator( 'test' )
      ->notes( 'another test...' );
    $req->arguments({ add_term => 1 });
    my $seg  = new Pangloss::Segment::AddTerm();
    my $view = test_and_get_view( $seg, $app, $req, $sess, $term );
    if (isa_ok( $view->{term}, 'Pangloss::Term', 'add view->term' )) {
	ok( $view->{term}->{added}, ' view->term->added' );
	$term_key = $view->{term}->key;
    }
    $req->arguments({});
}

## get term
if (use_ok("Pangloss::Segment::GetTerm")) {
    $req->arguments({ get_term      => 1,
		      selected_term => $term_key });
    my $seg  = new Pangloss::Segment::GetTerm();
    my $view = test_and_get_view( $seg, $app, $req );
    isa_ok( $view->{term}, 'Pangloss::Term', 'get view->term' );
    $req->arguments({});
}

## modify term status
if (use_ok("Pangloss::Segment::ModifyTermStatus")) {
    my $status = new Pangloss::Term::Status()
      ->code( 'test status' )
      ->creator( 'test' )
      ->notes( 'blah' );
    $req->arguments({ modify_term_status => 1,
		      selected_term      => $term_key });
    my $seg  = new Pangloss::Segment::ModifyTermStatus();
    my $view = test_and_get_view( $seg, $app, $req, $sess, $status );
    if (isa_ok( $view->{term}, 'Pangloss::Term', 'mod status view->term' )) {
	ok( $view->{term}->status->{modified}, ' view->term->status->modified' );
    }
    $req->arguments({});
}

## modify term
if (use_ok("Pangloss::Segment::ModifyTerm")) {
    my $term = new Pangloss::Term()
      ->name( 'tset' )
      ->concept( 'tset concept' )
      ->language( 'tset language' )
      ->notes( 'test backwards...' );
    $req->arguments({ modify_term       => 1,
		      selected_term     => $term_key });
    my $seg  = new Pangloss::Segment::ModifyTerm();
    my $view = test_and_get_view( $seg, $app, $req, $sess, $term );
    if (isa_ok( $view->{term}, 'Pangloss::Term', 'mod view->term' )) {
	ok( $view->{term}->{modified}, ' view->term->modified' );
	$term_key = $view->{term}->key;
    }
    $req->arguments({});
}

## remove term
if (use_ok("Pangloss::Segment::RemoveTerm")) {
    $req->arguments({ remove_term   => 1,
		      selected_term => $terms{to_remove} });
    my $seg  = new Pangloss::Segment::RemoveTerm();
    my $view = test_and_get_view( $seg, $app, $req );
    if (isa_ok( $view->{term}, 'Pangloss::Term', 'rm view->term' )) {
	ok( $view->{term}->{removed}, ' view->term->removed' );
    }
    $req->arguments({});
}

## no selected term
if (use_ok("Pangloss::Segment::Decline::NoSelectedTerm")) {
    $req->arguments({});
    my $seg = new Pangloss::Segment::Decline::NoSelectedTerm();
    my ($pt, $prod) = test_seg( $seg, $req );
    like( $prod, qr/declined/, 'no selected term' );
}

## no term
if (use_ok("Pangloss::Segment::Decline::NoTerm")) {
    $req->arguments({});
    my $seg = new Pangloss::Segment::Decline::NoTerm();
    my ($pt, $prod) = test_seg( $seg, $req );
    like( $prod, qr/declined/, 'no term' );
}

## no term status
if (use_ok("Pangloss::Segment::Decline::NoTermStatus")) {
    $req->arguments({});
    my $seg = new Pangloss::Segment::Decline::NoTermStatus();
    my ($pt, $prod) = test_seg( $seg, $req );
    like( $prod, qr/declined/, 'no term status' );
}

# request - get term
test_request_setter( 'Pangloss::Segment::Request::GetTerm', 'get_term' );

# request - list terms
test_request_setter( 'Pangloss::Segment::Request::ListTerms', 'list_terms' );

# request - list status codes
test_request_setter( 'Pangloss::Segment::Request::ListStatusCodes', 'list_status_codes' );

