#!/usr/bin/perl

##
## Tests for Pangloss::Segment::Language*
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
use Pangloss::Language qw(dir_RTL dir_LTR);
use Pangloss::Application;

my $req  = new OpenFrame::Request();
my $app  = new Pangloss::Application()->store( new Pixie()->connect('memory') );
my $ed   = $app->language_editor;
my $user = new Pangloss::User()->id('test');
my $sess = new OpenFrame::WebApp::Session::MemCache()->set('user', $user);

my %langs = (test => 'test lang', to_remove => 'remove me!');
foreach my $code (keys %langs) {
    my $lang = Pangloss::Language->new()
      ->iso_code($code)
      ->name($langs{$code})
      ->direction(dir_RTL)
      ->creator('test')
      ->date(1);
    $ed->add( $lang );
}

## load language from request
if (use_ok("Pangloss::Segment::LoadLanguage")) {
    $req->arguments({ new_language_name      => 'a test',
		      new_language_iso_code  => 'te',
		      new_language_notes     => 'some notes...',
		      new_language_direction => dir_LTR });
    my $seg = new Pangloss::Segment::LoadLanguage();
    my $pt  = test_seg( $seg, $req, $sess );
    my $lang = $pt->pipe->store->get('Pangloss::Language');
    if (ok( $lang, 'load language' )) {
	is( $lang->creator, 'test', ' language->creator set' );
    }
    $req->arguments({});
}

## list languages
if (use_ok("Pangloss::Segment::ListLanguages")) {
    my $seg  = new Pangloss::Segment::ListLanguages();
    my $view = test_and_get_view( $seg, $app, $req );
    is( @{ $view->{languages} }, 2, 'list languages' );
}

test_request_decliner( class => "Pangloss::Segment::Decline::NoListLanguages",
		       on    => { list_languages => 1 },
		       off   => {} );


## add language
if (use_ok("Pangloss::Segment::AddLanguage")) {
    my $language = new Pangloss::Language()
      ->name( 'test' )
      ->notes( 'another test' )
      ->creator( 'test' )
      ->iso_code( 'te' )
      ->direction( dir_LTR );
    $req->arguments({ add_language => 1 });
    my $seg  = new Pangloss::Segment::AddLanguage();
    my $view = test_and_get_view( $seg, $app, $req, $sess, $language );
    if (isa_ok( $view->{language}, 'Pangloss::Language', 'add view->language' )) {
	ok( $view->{language}->{added}, 'view->language->added' );
    }
    $req->arguments({});
}

## get language
if (use_ok("Pangloss::Segment::GetLanguage")) {
    $req->arguments({ get_language      => 1,
		      selected_language => 'test' });
    my $seg  = new Pangloss::Segment::GetLanguage();
    my $view = test_and_get_view( $seg, $app, $req );
    isa_ok( $view->{language}, 'Pangloss::Language', 'get view->language' );
    $req->arguments({});
}

## modify language
if (use_ok("Pangloss::Segment::ModifyLanguage")) {
    my $language = new Pangloss::Language()
      ->name( 'tset' )
      ->notes( 'test backwards' )
      ->iso_code( 'et' )
      ->direction( dir_LTR );
    $req->arguments({ modify_language   => 1,
		      selected_language => 'test' });
    my $seg  = new Pangloss::Segment::ModifyLanguage();
    my $view = test_and_get_view( $seg, $app, $sess, $req, $language );
    if (isa_ok( $view->{language}, 'Pangloss::Language', 'mod view->language' )) {
	ok( $view->{language}->{modified}, 'view->language->modified' );
    }
    $req->arguments({});
}

## remove language
if (use_ok("Pangloss::Segment::RemoveLanguage")) {
    $req->arguments({ remove_language   => 1,
		      selected_language => 'to_remove' });
    my $seg  = new Pangloss::Segment::RemoveLanguage();
    my $view = test_and_get_view( $seg, $app, $req );
    if (isa_ok( $view->{language}, 'Pangloss::Language', 'rm view->language' )) {
	ok( $view->{language}->{removed}, 'view->language->removed' );
    }
    $req->arguments({});
}

## no selected language
if (use_ok("Pangloss::Segment::Decline::NoSelectedLanguage")) {
    $req->arguments({});
    my $seg = new Pangloss::Segment::Decline::NoSelectedLanguage();
    my ($pt, $prod) = test_seg( $seg, $req );
    like( $prod, qr/declined/, 'no selected language' );
}

## no language
if (use_ok("Pangloss::Segment::Decline::NoLanguage")) {
    $req->arguments({});
    my $seg = new Pangloss::Segment::Decline::NoLanguage();
    my ($pt, $prod) = test_seg( $seg, $req );
    like( $prod, qr/declined/, 'no language' );
}

# request - get language
test_request_setter( 'Pangloss::Segment::Request::GetLanguage', 'get_language' );

# request - list languages
test_request_setter( 'Pangloss::Segment::Request::ListLanguages', 'list_languages' );

