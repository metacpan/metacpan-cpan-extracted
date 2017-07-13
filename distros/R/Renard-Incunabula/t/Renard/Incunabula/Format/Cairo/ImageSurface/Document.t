#!/usr/bin/env perl

use Test::Most tests => 1;

use lib 't/lib';
use Renard::Incunabula::Devel::TestHelper;

use Renard::Incunabula::Common::Setup;
use Renard::Incunabula::Format::Cairo::ImageSurface::Document;

subtest 'Cairo document model' => sub {
	my $cairo_doc = Renard::Incunabula::Devel::TestHelper->create_cairo_document;

	ok( $cairo_doc, "Cairo document object created successfully" );

	is( $cairo_doc->first_page_number, 1, "First page number is correct" );

	is( $cairo_doc->last_page_number, 4, "Last page number is correct" );

	my $first_page = $cairo_doc->get_rendered_page( page_number => 1 );
	is  $first_page->width, 5000, "Check width of first page";
	is  $first_page->height, 5000, "Check height of first page";

	cmp_deeply(
		$cairo_doc->identity_bounds,
		superbagof({
			dims  =>  { h => 5000, w =>5000 },
			pageno => 1,
			rotate => 0,
			x      => 5000,
			y      => 5000,
		}),
		'Identity bounds contains correct data'
	);
};


done_testing;
