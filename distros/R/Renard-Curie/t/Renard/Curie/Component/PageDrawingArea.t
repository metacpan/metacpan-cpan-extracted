#!/usr/bin/env perl

use Test::Most tests => 1;

use lib 't/lib';
use CurieTestHelper;
use Renard::Incunabula::Format::Cairo::Devel::TestHelper;

use Renard::Incunabula::Common::Setup;
use Renard::Curie::App;

my $cairo_doc = Renard::Incunabula::Format::Cairo::Devel::TestHelper->create_cairo_document;

subtest 'Page number bound checking' => sub {
	my ($app, $page_comp) = CurieTestHelper->create_app_with_document($cairo_doc);

	$page_comp->view->set_current_page_to_first;
	$page_comp->view->set_current_page_back;
	is $page_comp->view->page_number, 1, "Can not go to previous page when on first page";

	$page_comp->view->page_number(2);
	$page_comp->view->set_current_page_back;
	is $page_comp->view->page_number, 1, "Can move to previous page when on second page";

	$page_comp->view->page_number(2);
	$page_comp->view->set_current_page_forward;
	is $page_comp->view->page_number, 3, "Can move to next page when on second page";

	$page_comp->view->set_current_page_to_last;
	$page_comp->view->set_current_page_forward;
	is $page_comp->view->page_number, $cairo_doc->last_page_number, "Can not go to next page when on last page";
};

done_testing;
