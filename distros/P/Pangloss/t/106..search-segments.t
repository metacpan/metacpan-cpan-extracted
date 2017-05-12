#!/usr/bin/perl

##
## Tests for Pangloss::Segment::Search*
##

use lib 't/lib';
use blib;
use strict;
use warnings;

use Test::More 'no_plan';
use TestSeg qw( test_seg test_and_get_view );

use OpenFrame::Request;
use Pipeline::Segment::Tester;
use OpenFrame::WebApp::Session::MemCache;

use TestApplication;
use Pangloss::Term::Status;
use Pangloss::Search::Request;

my $tapp = new TestApplication() || die "error loading test application!";
my $req  = new OpenFrame::Request();
my $sreq = Pangloss::Search::Request->new;

if (use_ok( 'Pangloss::Segment::SearchRequest::Update' )) {
    $req->arguments({ 'category_category 1' => 'on',
		      'concept_concept 1'   => 'on',
		      'language_te'         => 'on',
		      'translator_user 1'   => 'on',
		      'proofreader_user A'  => 'on',
		      'status_approved'     => 'on',
		      'date_last_week'      => 'on',
		      date_from             => '01/01/2000',
		      date_to               => '31/12/2000',
		      keyword               => 'blah', });
    $sreq->translator( 'user 1', 'on' )
         ->translator( 'user 2', 'on' );
    my $seg  = Pangloss::Segment::SearchRequest::Update->new;
    my $pt   = test_seg( $seg, $req );
    my $sreq = $pt->pipe->store->get('Pangloss::Search::Request');
    if (ok( $sreq, 'load search request' )) {
	ok( $sreq->filters->{category}->is_set('category 1'),  ' categories->category 1' );
	ok( $sreq->filters->{concept}->is_set('concept 1'),    ' concepts->concept 1' );
	ok( $sreq->filters->{language}->is_set('te'),          ' languages->te' );
	ok( $sreq->filters->{proofreader}->is_set('user A'),   ' proofreaders->user A' );
	ok( $sreq->filters->{translator}->is_set('user 1'),    ' translators->user 1' );
	ok( $sreq->filters->{translator}->not_set('user 2'),   ' ! translators->user 2' );
	ok( $sreq->filters->{status}->is_set(Pangloss::Term::Status->APPROVED), ' statuses->approved' );
	is( $sreq->filters->{keyword}->get, 'blah',            ' keyword is blah' );
      TODO: {
	local $TODO = 'date range searches not implemented!';
	ok( $sreq->filters->{date_range}->is_set('01/01/2000-31/12/2000'), ' date_ranges->from-to' );
	ok( $sreq->filters->{date_range}->is_set('last week'), ' date_ranges->last_week' );
      }
    }
    $req->arguments({});
}


if (use_ok( 'Pangloss::Segment::SearchRequest::SaveInSession' )) {
    my $sreq = new Pangloss::Search::Request;
    my $sess = new OpenFrame::WebApp::Session::MemCache();
    my $seg  = new Pangloss::Segment::SearchRequest::SaveInSession;
    my $pt   = test_seg( $seg, $sess, $sreq );
    ok( $sess->get('search_request'), 'save in session' );
}

if (use_ok( 'Pangloss::Segment::SearchRequest::GetFromSession' )) {
    my $sreq = new Pangloss::Search::Request;
    my $sess = new OpenFrame::WebApp::Session::MemCache()
      ->set( 'search_request', $sreq );
    my $seg  = new Pangloss::Segment::SearchRequest::GetFromSession;
    my $pt   = test_seg( $seg, $sess );
    ok( $pt->pipe->store->get( $sreq->class ), 'get from session' );
}

if (use_ok( 'Pangloss::Segment::Search' )) {
    my $sreq = new Pangloss::Search::Request;
    my $seg  = new Pangloss::Segment::Search;
    # fake a PG::App (either this, or use an ISA store):
    my $app  = bless {%$tapp}, 'Pangloss::Application';
    my $view = test_and_get_view( $seg, $app, $sreq );
    isa_ok( $view->{search_results_pager}, 'Pangloss::Search::Results::Pager',
	    'view->search_results_pager' );
}

if (use_ok( 'Pangloss::Segment::Decline::NoSearchRequest' )) {
    $req->arguments({});
    my $seg = new Pangloss::Segment::Decline::NoSearchRequest();
    my ($pt, $prod) = test_seg( $seg, $req );
    like( $prod, qr/declined/, 'no search request' );
}

if (use_ok( 'Pangloss::Segment::Decline::NoSelectedSearch' )) {
    $req->arguments({});
    my $seg = new Pangloss::Segment::Decline::NoSelectedSearch();
    my ($pt, $prod) = test_seg( $seg, $req );
    like( $prod, qr/declined/, 'no selected search' );
}

if (use_ok( 'Pangloss::Segment::Pager::SaveInSession' )) {
    my $pager = new Pangloss::Search::Results::Pager;
    my $sess  = new OpenFrame::WebApp::Session::MemCache();
    my $seg   = new Pangloss::Segment::Pager::SaveInSession;
    my $pt   = test_seg( $seg, $sess, $pager );
    ok( $sess->get('search_pager'), 'save in session' );
}

if (use_ok( 'Pangloss::Segment::Pager::GetFromSession' )) {
    my $pager = new Pangloss::Search::Results::Pager;
    my $sess  = new OpenFrame::WebApp::Session::MemCache()
      ->set( 'search_pager', $sreq );
    my $seg   = new Pangloss::Segment::Pager::GetFromSession;
    my $pt    = test_seg( $seg, $sess );
    ok( $pt->pipe->store->get( $sreq->class ), 'get from session' );
}

if (use_ok( 'Pangloss::Segment::Pager::SetCurrentPage' )) {
    $req->arguments({ page => 2 });
    my $pager = new Pangloss::Search::Results::Pager;
    my $seg   = new Pangloss::Segment::Pager::SetCurrentPage;
    my $pt    = test_seg( $seg, $req, $pager );
    is( $pager->page, 2, 'sets current page' );
}

if (use_ok( 'Pangloss::Segment::Decline::NoPager' )) {
    $req->arguments({});
    my $seg = new Pangloss::Segment::Decline::NoPager;
    my ($pt, $prod) = test_seg( $seg, $req );
    like( $prod, qr/declined/, 'no pager' );
}
