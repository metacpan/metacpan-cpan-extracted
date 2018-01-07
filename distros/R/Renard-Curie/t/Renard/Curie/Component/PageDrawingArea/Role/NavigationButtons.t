#!/usr/bin/env perl

use Test::Most tests => 3;

use lib 't/lib';
use CurieTestHelper;
use Renard::Incunabula::Format::Cairo::Devel::TestHelper;

use Renard::Incunabula::Common::Setup;
use Renard::Curie::App;

my $cairo_doc = Renard::Incunabula::Format::Cairo::Devel::TestHelper->create_cairo_document;

subtest 'Check that moving forward and backward changes the page number' => sub {
	my ($app, $page_comp) = CurieTestHelper->create_app_with_document($cairo_doc);

	my $forward_button = $page_comp->builder->get_object('button-forward');
	my $back_button = $page_comp->builder->get_object('button-back');

	is($page_comp->view->page_number, 1, 'Start on page 1' );

	$forward_button->clicked;
	is($page_comp->view->page_number, 2, 'On page 2 after hitting forward' );

	$forward_button->clicked;
	is($page_comp->view->page_number, 3, 'On page 3 after hitting forward' );

	$back_button->clicked;
	is($page_comp->view->page_number, 2, 'On page 2 after hitting back' );
};

subtest 'Check that the first and last buttons work' => sub {
	my ($app, $page_comp) = CurieTestHelper->create_app_with_document($cairo_doc);

	my $first_button = $page_comp->builder->get_object('button-first');
	my $last_button = $page_comp->builder->get_object('button-last');

	is($page_comp->view->page_number, 1, 'Start on page 1' );

	subtest "Check first button" => sub {
		$page_comp->view->page_number(3);
		is $page_comp->view->page_number, 3, "Setting page to 3";

		$first_button->clicked;
		is($page_comp->view->page_number, 1, 'On page 1 after hitting first' );
	};

	subtest "Check last button" => sub {
		$page_comp->view->page_number(2);
		is $page_comp->view->page_number, 2, "Setting page to 2";

		$last_button->clicked;
		is($page_comp->view->page_number, 4, 'On page 4 after hitting last' );
	};
};

subtest 'Check that the current button sensitivity is set on the first and last page' => sub {
	my ($app, $page_comp) = CurieTestHelper->create_app_with_document($cairo_doc);

	my $first_button = $page_comp->builder->get_object('button-first');
	my $last_button = $page_comp->builder->get_object('button-last');

	my $forward_button = $page_comp->builder->get_object('button-forward');
	my $back_button = $page_comp->builder->get_object('button-back');

	is($page_comp->view->page_number, 1, 'Start on page 1' );

	ok ! $first_button->is_sensitive  , 'button-first is disabled on first page';
	ok ! $back_button->is_sensitive   , 'button-back is disabled on first page';
	ok   $last_button->is_sensitive   , 'button-last is enabled on first page';
	ok   $forward_button->is_sensitive, 'button-forward is enabled on first page';

	$last_button->clicked;
	$page_comp->refresh_drawing_area;

	is $page_comp->view->page_number, 4, 'On page 4 after hitting button-last';

	$page_comp->set_navigation_buttons_sensitivity;

	ok   $first_button->is_sensitive  , 'button-first is enabled on last page';
	ok   $back_button->is_sensitive   , 'button-back is enabled on last page';
	ok ! $last_button->is_sensitive   , 'button-last is disabled on last page';
	ok ! $forward_button->is_sensitive, 'button-forward is disabled on last page';
};

done_testing;
