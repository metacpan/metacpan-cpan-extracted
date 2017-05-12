#!/usr/bin/perl

##
## Tests for Pangloss::Segment::Category*
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
use Pangloss::Category;
use Pangloss::Application;

my $req  = new OpenFrame::Request();
my $app  = new Pangloss::Application()->store( new Pixie()->connect('memory') );
my $ed   = $app->category_editor;
my $user = new Pangloss::User()->id('test');
my $sess = new OpenFrame::WebApp::Session::MemCache()->set('user', $user);

my %cats = (test => 'test cat', to_remove => 'remove me!');
foreach my $code (keys %cats) {
    my $cat = Pangloss::Category->new()
      ->name($code)
      ->notes($cats{$code})
      ->creator($user->id)
      ->date(1);
    $ed->add( $cat );
}

## load category from request
if (use_ok("Pangloss::Segment::LoadCategory")) {
    $req->arguments({ new_category_name  => 'a test',
		      new_category_notes => 'some notes...' });
    my $seg = new Pangloss::Segment::LoadCategory();
    my $pt  = test_seg( $seg, $req, $sess );
    my $category = $pt->pipe->store->get('Pangloss::Category');
    if (ok( $category, 'load category' )) {
	is( $category->creator, 'test', ' category->creator set' );
    }
    $req->arguments({});
}

## list categories
if (use_ok("Pangloss::Segment::ListCategories")) {
    my $seg  = new Pangloss::Segment::ListCategories();
    my $view = test_and_get_view( $seg, $app, $req );
    is( @{ $view->{categories} }, 2, 'list categories' );
}

test_request_decliner( class => "Pangloss::Segment::Decline::NoListCategories",
		       on    => { list_categories => 1 },
		       off   => {} );

## add category
if (use_ok("Pangloss::Segment::AddCategory")) {
    my $category = new Pangloss::Category()
      ->name( 'a test' )
      ->notes( 'another test' )
      ->creator( 'test' );
    $req->arguments({ add_category => 1 });
    my $seg  = new Pangloss::Segment::AddCategory();
    my $view = test_and_get_view( $seg, $app, $req, $sess, $category );
    if (isa_ok( $view->{category}, 'Pangloss::Category', 'add view->category' )) {
	ok( $view->{category}->{added}, 'view->category->added' );
    }
    $req->arguments({});
}

## get category
if (use_ok("Pangloss::Segment::GetCategory")) {
    $req->arguments({ get_category      => 1,
		      selected_category => 'test' });
    my $seg  = new Pangloss::Segment::GetCategory();
    my $view = test_and_get_view( $seg, $app, $req );
    isa_ok( $view->{category}, 'Pangloss::Category', 'get view->category' );
    $req->arguments({});
}

## modify category
if (use_ok("Pangloss::Segment::ModifyCategory")) {
    my $category = new Pangloss::Category()
      ->name( 'tset' )
      ->notes( 'test backwards' );
    $req->arguments({ modify_category     => 1,
		      selected_category   => 'test' });
    my $seg  = new Pangloss::Segment::ModifyCategory();
    my $view = test_and_get_view( $seg, $app, $req, $sess, $category );
    if (isa_ok( $view->{category}, 'Pangloss::Category', 'mod view->category' )) {
	ok( $view->{category}->{modified}, 'view->category->modified' );
    }
    $req->arguments({});
}

## remove category
if (use_ok("Pangloss::Segment::RemoveCategory")) {
    $req->arguments({ remove_category   => 1,
		      selected_category => 'to_remove' });
    my $seg  = new Pangloss::Segment::RemoveCategory();
    my $view = test_and_get_view( $seg, $app, $req );
    if (isa_ok( $view->{category}, 'Pangloss::Category', 'rm view->category' )) {
	ok( $view->{category}->{removed}, 'view->category->removed' );
    }
    $req->arguments({});
}

## no selected category
if (use_ok("Pangloss::Segment::Decline::NoSelectedCategory")) {
    $req->arguments({});
    my $seg = new Pangloss::Segment::Decline::NoSelectedCategory();
    my ($pt, $prod) = test_seg( $seg, $req );
    like( $prod, qr/declined/, 'no selected category' );
}

## no category
if (use_ok("Pangloss::Segment::Decline::NoCategory")) {
    $req->arguments({});
    my $seg = new Pangloss::Segment::Decline::NoCategory();
    my ($pt, $prod) = test_seg( $seg, $req );
    like( $prod, qr/declined/, 'no category' );
}

# request - get category
test_request_setter( 'Pangloss::Segment::Request::GetCategory', 'get_category' );

# request - list categories
test_request_setter( 'Pangloss::Segment::Request::ListCategories', 'list_categories' );

