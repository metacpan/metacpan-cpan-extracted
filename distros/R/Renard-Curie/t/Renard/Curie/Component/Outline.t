#!/usr/bin/env perl

use Test::Most;

use lib 't/lib';
use CurieTestHelper;

use Renard::Curie::Setup;
use Renard::Curie::App;

my $pdf_ref_path = try {
	CurieTestHelper->test_data_directory->child(qw(PDF Adobe pdf_reference_1-7.pdf));
} catch {
	plan skip_all => "$_";
};

plan tests => 2;

subtest 'Check that the outline model is set for the current document' => sub {
	my $app = Renard::Curie::App->new;
	$app->open_pdf_document( $pdf_ref_path );
	my $doc = $app->page_document_component->document;
	my $outline = $doc->outline;

	is( $app->outline->model, $outline->tree_store,
		"The outline component's model is set to the document's outline model");
};

subtest 'Check that clicking an outline item sets the page number' => sub {
	plan tests => 3;

	my $app = Renard::Curie::App->new;
	$app->open_pdf_document( $pdf_ref_path );
	my $page_comp = $app->page_document_component;
	my $doc = $app->page_document_component->document;
	my $outline = $doc->outline;

	# start on first page
	$app->page_document_component->current_page_number(1);
	is $page_comp->current_page_number, 1, "Start off on the first page";

	my $path_to_second_item = Gtk3::TreePath->new_from_indices(1);
	my $first_column = $app->outline->tree_view->get_column(0);
	$app->outline->tree_view->row_activated( $path_to_second_item, $first_column );

	my $second_outline_item_page = $outline->items->[1]{page};

	is $second_outline_item_page, 9, 'Second outline item page number is 9';
	is $page_comp->current_page_number, $second_outline_item_page,
		"Activating the second outline row sets the correct page number";
};

done_testing;
