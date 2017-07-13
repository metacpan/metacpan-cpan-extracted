#!/usr/bin/env perl

use Test::Most tests => 1;

use lib 't/lib';
use Renard::Incunabula::Devel::TestHelper;

subtest "Cairo document model" => sub {
	my $cairo_doc = Renard::Incunabula::Devel::TestHelper->create_cairo_document;

	my @valid_pages = qw(1 2 3 4);
	my @invalid_pages = qw(0 -1 aa 5 2.0);

	plan tests => 1 + @valid_pages + @invalid_pages;

	can_ok( $cairo_doc, qw(is_valid_page_number) );


	for (@valid_pages) {
		ok( $cairo_doc->is_valid_page_number($_), "$_ is a valid page" );
	}
	for (@invalid_pages) {
		ok( ! $cairo_doc->is_valid_page_number($_), "$_ is an invalid page" );
	}
};

done_testing;
