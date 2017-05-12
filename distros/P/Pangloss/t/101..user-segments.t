#!/usr/bin/perl

##
## Tests for Pangloss::Segment::User*
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
use Data::Dumper;

use OpenFrame::Request;
use Pipeline::Segment::Tester;
use OpenFrame::WebApp::Session::MemCache;

use Pangloss::User;
use Pangloss::Application;

my $req  = new OpenFrame::Request();
my $app  = new Pangloss::Application()->store( new Pixie()->connect('memory') );
my $ed   = $app->user_editor;
my $user = new Pangloss::User()->id('test');
my $sess = new OpenFrame::WebApp::Session::MemCache()->set('user', $user);

my %users = (test => 'mr. test', to_remove => 'remove me!');
$ed->add( Pangloss::User->new
	    ->id($_)
	    ->name($users{$_})
	    ->creator('test')
	    ->privileges( Pangloss::User::Privileges->new
			    ->add_translate_languages('test')
			    ->add_proofread_languages('test') )
	    ->date(1) )
  for (keys %users);

## load user from request
if (use_ok("Pangloss::Segment::LoadUser")) {
    $req->arguments({ new_user_name  => 'a test',
		      new_user_id    => 'bob',
		      new_user_notes => 'some notes...' });
    my $seg = new Pangloss::Segment::LoadUser();
    my $pt  = test_seg( $seg, $req, $sess );
    my $new_user = $pt->pipe->store->get('Pangloss::User');
    if (ok( $new_user, 'load user' )) {
	is( $new_user->creator, 'test', ' user->creator set' );
    }
    $req->arguments({});
}

## list users
if (use_ok("Pangloss::Segment::ListUsers")) {
    my $seg  = new Pangloss::Segment::ListUsers();
    my $view = test_and_get_view( $seg, $app );
    is( @{ $view->{users} }, 2, 'list users' );
}

test_request_decliner( class => "Pangloss::Segment::Decline::NoListUsers",
		       on    => { list_users => 1 },
		       off   => {} );

## list translators
if (use_ok("Pangloss::Segment::ListTranslators")) {
    my $seg  = new Pangloss::Segment::ListTranslators();
    my $view = test_and_get_view( $seg, $app, $req );
    is( @{ $view->{translators} }, 2, 'list translators' );
}

test_request_decliner( class => "Pangloss::Segment::Decline::NoListTranslators",
		       on    => { list_translators => 1 },
		       off   => {} );

## list proofreaders
if (use_ok("Pangloss::Segment::ListProofreaders")) {
    my $seg  = new Pangloss::Segment::ListProofreaders();
    my $view = test_and_get_view( $seg, $app, $req );
    is( @{ $view->{proofreaders} }, 2, 'list proofreaders' );
}

test_request_decliner( class => "Pangloss::Segment::Decline::NoListProofreaders",
		       on    => { list_proofreaders => 1 },
		       off   => {} );

## add user
if (use_ok("Pangloss::Segment::AddUser")) {
    my $user = new Pangloss::User()
      ->id( 'bob' )
      ->name( 'Bob The Builder' )
      ->notes( 'test ...' )
      ->creator( 'test' );
    $req->arguments({ add_user => 1 });
    my $seg  = new Pangloss::Segment::AddUser();
    my $view = test_and_get_view( $seg, $app, $req, $sess, $user );
    if (isa_ok( $view->{user}, 'Pangloss::User', 'add view->user' )) {
	ok( $view->{user}->{added}, 'view->user->added' );
    }
    $req->arguments({});
}

## get user
if (use_ok("Pangloss::Segment::GetUser")) {
    $req->arguments({ get_user => 1,
		      selected_user => 'test' });
    my $seg  = new Pangloss::Segment::GetUser();
    my $view = test_and_get_view( $seg, $app, $req );
    isa_ok( $view->{user}, 'Pangloss::User', 'get view->user' );
    $req->arguments({});
}

## load user
if (use_ok("Pangloss::Segment::UserLoader")) {
    $req->arguments({ user_id => 'test' });
    #$ENV{REMOTE_USER} = 'test';
    my $seg = new Pangloss::Segment::UserLoader();
    my $pt  = test_seg( $seg, $app, $req);
    ok( $pt->pipe->store->get( 'Pangloss::User' ), 'load user' );
    $req->arguments({});
    #delete $ENV{REMOTE_USER};
}

## modify user
if (use_ok("Pangloss::Segment::ModifyUser")) {
    my $new_user = new Pangloss::User()
      ->id( 'fred' )
      ->name( 'Fred The Fish' );
    $req->arguments({ modify_user   => 1,
		      selected_user => 'test' });
    my $seg  = new Pangloss::Segment::ModifyUser();
    my $view = test_and_get_view( $seg, $app, $req, $sess, $new_user );
    if (isa_ok( $view->{user}, 'Pangloss::User', 'mod view->user' )) {
	ok( $view->{user}->{modified}, 'view->user->modified' );
    }
    $req->arguments({});
}

## remove user
if (use_ok("Pangloss::Segment::RemoveUser")) {
    $req->arguments({ remove_user   => 1,
		      selected_user => 'to_remove' });
    my $seg  = new Pangloss::Segment::RemoveUser();
    my $view = test_and_get_view( $seg, $app, $req );
    if (isa_ok( $view->{user}, 'Pangloss::User', 'rm view->user' )) {
	ok( $view->{user}->{removed}, 'view->user->removed' );
    }
    $req->arguments({});
}

## no selected user
if (use_ok("Pangloss::Segment::Decline::NoSelectedUser")) {
    $req->arguments({});
    my $seg = new Pangloss::Segment::Decline::NoSelectedUser();
    my ($pt, $prod) = test_seg( $seg, $req );
    like( $prod, qr/declined/, 'no selected user' );
}

## not admin
if (use_ok("Pangloss::Segment::Decline::NotAdmin")) {
    $req->arguments({});
    my $user = Pangloss::User->new()->id('test');
    my $sess = new OpenFrame::WebApp::Session::MemCache()->set( 'user', $user );
    my $seg  = new Pangloss::Segment::Decline::NotAdmin();
    my ($pt, $prod) = test_seg( $seg, $req, $sess );
    like( $prod, qr/declined/, 'not admin user' );
}

## can't add concepts
if (use_ok("Pangloss::Segment::Decline::CantAddConcepts")) {
    $req->arguments({});
    my $seg  = new Pangloss::Segment::Decline::CantAddConcepts();
    my ($pt, $prod) = test_seg( $seg, $req, $sess );
    like( $prod, qr/declined/, 'user cant add concepts' );
}

## can't add categories
if (use_ok("Pangloss::Segment::Decline::CantAddCategories")) {
    $req->arguments({});
    my $seg  = new Pangloss::Segment::Decline::CantAddCategories();
    my ($pt, $prod) = test_seg( $seg, $req, $sess );
    like( $prod, qr/declined/, 'user cant add categories' );
}

## not admin
if (use_ok("Pangloss::Segment::Decline::NotAdmin")) {
    $req->arguments({});
    my $seg  = new Pangloss::Segment::Decline::NotAdmin();
    my ($pt, $prod) = test_seg( $seg, $req, $sess );
    like( $prod, qr/declined/, 'not admin user' );
}

## not translator
if (use_ok("Pangloss::Segment::Decline::NotTranslator")) {
    $req->arguments({});
    my $seg  = new Pangloss::Segment::Decline::NotTranslator();
    my ($pt, $prod) = test_seg( $seg, $req, $sess );
    like( $prod, qr/declined/, 'not translator user' );
}

## can't translate term
if (use_ok("Pangloss::Segment::Decline::CantTranslateTerm")) {
    $req->arguments({});
    my $term = Pangloss::Term->new()->name('foo')->language('test');
    my $seg  = new Pangloss::Segment::Decline::CantTranslateTerm();
    my ($pt, $prod) = test_seg( $seg, $req, $sess, $term );
    like( $prod, qr/declined/, 'cant translate term' );
}

## not proofreader
if (use_ok("Pangloss::Segment::Decline::NotProofreader")) {
    $req->arguments({});
    my $seg  = new Pangloss::Segment::Decline::NotProofreader();
    my ($pt, $prod) = test_seg( $seg, $req, $sess );
    like( $prod, qr/declined/, 'not proofreader user' );
}

## can't proofread term
if (use_ok("Pangloss::Segment::Decline::CantProofreadTerm")) {
    $req->arguments({});
    my $term = Pangloss::Term->new()->name('foo')->language('test');
    my $seg  = new Pangloss::Segment::Decline::CantProofreadTerm();
    my ($pt, $prod) = test_seg( $seg, $req, $sess, $term );
    like( $prod, qr/declined/, 'cant proofread term' );
}

## can't proofread selected term
if (use_ok("Pangloss::Segment::Decline::CantProofreadSelectedTerm")) {
    $ed->add( Pangloss::Term->new
	      ->name('test term')
	      ->concept(1)
	      ->language(1)
	      ->creator( 'test' ) );
    $req->arguments({ selected_term => 'test term' });
    my $seg = new Pangloss::Segment::Decline::CantProofreadSelectedTerm();
    my ($pt, $prod) = test_seg( $seg, $req, $sess );
    like( $prod, qr/declined/, 'cant proofread selected term' );
}

## no user
if (use_ok("Pangloss::Segment::Decline::NoUser")) {
    $req->arguments({});
    my $seg = new Pangloss::Segment::Decline::NoUser();
    my ($pt, $prod) = test_seg( $seg, $req );
    like( $prod, qr/declined/, 'no user' );
}

## no user in session
if (use_ok("Pangloss::Segment::Decline::NoUserInSession")) {
    $req->arguments({});
    my $seg  = new Pangloss::Segment::Decline::NoUserInSession();
    my $sess = new OpenFrame::WebApp::Session::MemCache();
    my ($pt, $prod) = test_seg( $seg, $req );
    like( $prod, qr/declined/, 'no user in session' );
}

# request - get user
test_request_setter( 'Pangloss::Segment::Request::GetUser', 'get_user' );

# request - list users
test_request_setter( 'Pangloss::Segment::Request::ListUsers', 'list_users' );

# request - list translators
test_request_setter( 'Pangloss::Segment::Request::ListTranslators', 'list_translators' );

# request - list proofreaders
test_request_setter( 'Pangloss::Segment::Request::ListProofreaders', 'list_proofreaders' );

