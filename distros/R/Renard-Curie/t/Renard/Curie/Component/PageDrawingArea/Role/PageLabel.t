#!/usr/bin/env perl

use Test::Most tests => 1;

use lib 't/lib';
use CurieTestHelper;
use Renard::Incunabula::Format::Cairo::Devel::TestHelper;

use Renard::Incunabula::Common::Setup;
use Renard::Curie::App;

my $cairo_doc = Renard::Incunabula::Format::Cairo::Devel::TestHelper->create_cairo_document;

subtest 'Check the number of pages label' => sub {
	my ($app, $page_comp) = CurieTestHelper->create_app_with_document($cairo_doc);

	my $number_of_pages_label;

	lives_ok {
		$number_of_pages_label = $page_comp->builder->get_object("number-of-pages-label");
	} 'The number of pages label exists';

	is( $number_of_pages_label->get_text() , '4', 'Number of pages should be equal to four.' );
};

done_testing;
