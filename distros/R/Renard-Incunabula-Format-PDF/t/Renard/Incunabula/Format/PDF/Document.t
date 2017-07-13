#!/usr/bin/env perl

use Test::Most;

use lib 't/lib';
use Renard::Incunabula::Devel::TestHelper;

use Renard::Incunabula::Common::Setup;
use Renard::Incunabula::Format::PDF::Document;

my $pdf_ref_path = try {
	Renard::Incunabula::Devel::TestHelper->test_data_directory->child(qw(PDF Adobe pdf_reference_1-7.pdf));
} catch {
	plan skip_all => "$_";
};

plan tests => 1;

subtest pdf_ref => sub {
	my $pdf_doc = Renard::Incunabula::Format::PDF::Document->new(
		filename => $pdf_ref_path
	);

	ok( $pdf_doc, "PDF document object created successfully" );

	is( $pdf_doc->first_page_number, 1, "First page number is correct" );

	is( $pdf_doc->last_page_number, 1310, "Last page number is correct" );

	my $first_page = $pdf_doc->get_rendered_page( page_number => 1 );
	is  $first_page->width, 531, "Check width of first page";
	is  $first_page->height, 666, "Check height of first page";
	isa_ok $first_page->cairo_image_surface, 'Cairo::ImageSurface';
};


done_testing;
