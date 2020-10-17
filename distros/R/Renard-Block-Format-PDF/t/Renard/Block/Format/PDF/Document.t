#!/usr/bin/env perl

use Test::Most;

use Renard::Incunabula::Common::Setup;
use Renard::Block::Format::PDF::Document;
use Renard::Block::Format::PDF::Devel::TestHelper;

my $pdf_ref_path = try {
	Renard::Block::Format::PDF::Devel::TestHelper->pdf_reference_document_path;
} catch {
	plan skip_all => "$_";
};

plan tests => 2;

subtest pdf_ref => sub {
	my $pdf_doc = Renard::Block::Format::PDF::Devel::TestHelper->pdf_reference_document_object;

	ok( $pdf_doc, "PDF document object created successfully" );

	is( $pdf_doc->first_page_number, 1, "First page number is correct" );

	is( $pdf_doc->last_page_number, 1310, "Last page number is correct" );

	my $first_page = $pdf_doc->get_rendered_page( page_number => 1 );
	is  $first_page->width, 531, "Check width of first page";
	is  $first_page->height, 666, "Check height of first page";
	isa_ok $first_page->cairo_image_surface, 'Cairo::ImageSurface';
};

subtest "Textual information" => sub {
	my $pdf_doc = Renard::Block::Format::PDF::Devel::TestHelper->pdf_reference_document_object;

	my $tagged = $pdf_doc->get_textual_page( 23 );

	my $tagged_line_bbox = "";
	$tagged->iter_substr_nooverlap(
		sub {
			my ( $substring, %tags ) = @_;

			$tagged_line_bbox .=
				$tags{line}
				? "<line bbox='@{[ $tags{line}{bbox} ]}'>$substring</line>"
				: $substring;
		},
		only => [ 'line' ],
	);

	like(
		$tagged_line_bbox,
		qr|\Q<line bbox='261.18 616.16397 269.77766 625.2532'>23</line>\E|,
		"Stores the page number text and its metadata" );
};

done_testing;
