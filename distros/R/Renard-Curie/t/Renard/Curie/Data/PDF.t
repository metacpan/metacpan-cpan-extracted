#!/usr/bin/env perl

use Test::Most;

use lib 't/lib';
use CurieTestHelper;

use Renard::Curie::Setup;
use Renard::Curie::Data::PDF;
use Data::DPath qw(dpathi);
use Function::Parameters;

my $pdf_ref_path = try {
	CurieTestHelper->test_data_directory->child(qw(PDF Adobe pdf_reference_1-7.pdf));
} catch {
	plan skip_all => "$_";
};

plan tests => 4;

subtest 'PDF page to PNG' => fun {
	my $png_data = Renard::Curie::Data::PDF::get_mutool_pdf_page_as_png( $pdf_ref_path, 1 );
	like $png_data, qr/^\x{89}PNG/, 'data has PNG stream magic number';
};

subtest 'Get bounds of PDF page' => fun {
	my $bounds = Renard::Curie::Data::PDF::get_mutool_page_info_xml( $pdf_ref_path );

	my $first_page = $bounds->{page}[0];
	is( $first_page->{pagenum}, 1, 'page number one is the first element of pages key' );
	is_deeply( $first_page->{CropBox}, { b => 0, t => 666, l => 0, r => 531 }, 'has the expected CropBox' );
};

subtest 'Get characters for preface' => fun {
	my $preface_page = 23;

	my $stext = Renard::Curie::Data::PDF::get_mutool_text_stext_xml( $pdf_ref_path, $preface_page );
	my $text_concat = "";

	my $root = dpathi($stext);
	my $char_iterator = $root->isearch( '/page/*/block/*/line/*/span/*/char/*' );
	while( $char_iterator->isnt_exhausted ) {
		$text_concat .= $char_iterator->value->deref->{c};
	}

	like( $text_concat,
		qr/The origins of the Portable Document Format/,
		'Page text contains expected substring' );
};

subtest 'Get outline of PDF document' => fun {
	my $outline_data = Renard::Curie::Data::PDF::get_mutool_outline_simple( $pdf_ref_path );

	cmp_deeply $outline_data,
		superbagof({
			level => 2,
			text => '1.2.6 General Features',
			page => 31 }),
		'has expected outline item';
};

done_testing;
