#!/usr/bin/perl

##
## Tests for Pangloss::Application::SearchTerms
##

use lib 't/lib';
use blib;
use strict;
use warnings;

use Test::More 'no_plan';

use Pixie;
use Error qw( :try );
use Data::Dumper;

use TestApplication;
use Pangloss::Search::Request;

my $tapp = new TestApplication() || die "error loading test application!";
my $searcher = $tapp->searcher;

ok( $searcher, 'searcher' );

my $sreq = Pangloss::Search::Request->new
  ->toggle_language('en');

my $view = $searcher->search_terms( $sreq );
if (isa_ok( $view, 'Pangloss::Application::View', 'view' )) {
    my $results = $view->{search_results_pager};
    if (ok( $results, ' view->search_results_pager' )) {
	isa_ok( $results, 'Pangloss::Search::Results::Pager', ' view->search_results' );
	ok    ( $results->not_empty, ' results->not_empty' )
	  || diag( Dumper( $results ) );
    }
}


